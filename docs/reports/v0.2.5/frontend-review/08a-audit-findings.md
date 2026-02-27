# 08a — 审计发现（事实基础）

> 技术债 D1–D10 代码实测、Rule E 违规全景、语义模糊地带、文档漂移。
> 本文为 [08-reassessment-and-replanning.md](08-reassessment-and-replanning.md) 的第一部分。

| 字段 | 值 |
|------|-----|
| 日期 | 2026-02-26 |
| 基线 commit | `372bf18`（PR-0252 全部闭合后） |
| 数据来源 | 代码实测 + 01–07 报告交叉验证 + 产品/架构文档审计 |

---

## 1.1 技术债 D1–D10 实测结果

以下为逐项代码实测结果（基于 commit `372bf18`），对照 05-retrospective 中的记录进行验证和补充。

### D1: `notes_style.dart` 跨 feature import

| 属性 | 值 |
|------|-----|
| 严重度 | P2 |
| 状态 | 存续 |

**实测**：`notes_style.dart` 本身（71 行）只导入 `package:flutter/material.dart`，不含跨 feature import。问题在反方向：`tags/tag_filter.dart` L2 导入了 `notes/notes_style.dart`，使用其中的 `kNotesSecondaryText`、`kNotesPrimaryText`、`kNotesItemHoverColor`、`kNotesItemSelectedColor` 等颜色常量。

**耦合结构**：形成 notes↔tags 双向依赖 —— `note_explorer.dart` 导入 `tags/tag_filter.dart`，`tag_filter.dart` 反向导入 `notes/notes_style.dart`。

### D2: `search_results_view.dart` 跨 feature import

| 属性 | 值 |
|------|-----|
| 严重度 | P2 |
| 状态 | 存续 |

**实测**：`search_results_view.dart`（261 行）本身只导入 `flutter/material.dart` 和 `core/bindings/api.dart`，无跨 feature import。违规在消费侧：`entry/single_entry_panel.dart` L6 导入了 `search/search_results_view.dart`。`SearchResultsView` 是纯展示组件，仅被 entry 使用。

### D3: NoteExplorer 仍为大文件

| 属性 | 值 |
|------|-----|
| 严重度 | P1 |
| 状态 | 存续 |

**实测**：`note_explorer.dart` 1,720 行。PR-0252 已提取 8 个卫星文件（合计 1,164 行），explorer 子系统总计 2,884 行分布在 9 个文件中。Report 06 分析结论为 HOLD — 剩余代码是固有的编排逻辑（上下文菜单、拖拽包装、对话框调度），进一步拆分会产生大量 State 参数穿透而无实质解耦。

**行动阈值**：2,200 行触发重评估；v0.3 PR-0302（drag-to-split）如推高则需拆分。

### D4: notes → workspace 跨 feature import

| 属性 | 值 |
|------|-----|
| 严重度 | P1 |
| 状态 | 存续 |

**实测**：4 处直接导入确认存在：

| 文件 | 导入 |
|------|------|
| `notes_coordinator.dart:13` | `features/workspace/workspace_models.dart` |
| `notes_coordinator.dart:14` | `features/workspace/workspace_provider.dart` |
| `notes_page.dart:15` | `features/workspace/workspace_models.dart` |
| `notes_page.dart:16` | `features/workspace/workspace_provider.dart` |

`workspace_port.dart`（28 行）已定义抽象接口，但 coordinator 实现层和 notes_page 仍直接依赖 workspace 内部类型。

### D5: P2 模块未拆分

| 属性 | 值 |
|------|-----|
| 严重度 | P2 |
| 状态 | 存续 |

**实测**：
- `SingleEntryController`: 679 行 — 混合搜索编排和命令执行，尚在可控范围
- `DebugLogsPanel`: 578 行 — 包含完整的日志查看器，尚在可控范围
- `workbench_shell_layout.dart` L2 导入 `diagnostics/debug_logs_panel.dart` — 为 shell 级组件组合调试面板

**行动阈值**：SingleEntryController 1,000 行、DebugLogsPanel 800 行。v0.3 PR-0311（全局热键）会扩展 entry 模块，需监控。

### D6: smoke_test overflow

| 属性 | 值 |
|------|-----|
| 严重度 | — |
| 状态 | **已关闭** |

**实测**：`smoke_test.dart`（153 行）无 overflow 相关代码。已在 2026-02-24 主干修复。

### D7: Tag 语义不一致（note vs note_ref）

| 属性 | 值 |
|------|-----|
| 严重度 | P2 |
| 状态 | 存续 |

**实测**：
- Tag 系统通过 `note_set_tags()` FFI 操作 Atom 实体，tag 挂在 Atom 上
- `NoteTagManager` 管理 tag CRUD，`selectedTag` 参数传给 `notes_list(tag: ...)`
- Workspace tree 的 `WorkspaceTreeChildrenLoader` 遍历树结构，展示所有 note_ref，**无 tag 感知**
- NoteExplorer 同时展示 TagFilter 和 workspace tree，但 tag 过滤只影响扁平笔记列表，不影响树视图

**核心问题**：tag 过滤和 workspace tree 在同一个 explorer 面板中共存，但各自独立工作，用户可能预期「选了 tag 后树也应该过滤」。

### D8: Note 创建入口语义差异

| 属性 | 值 |
|------|-----|
| 严重度 | P2 |
| 状态 | 存续 |

**实测**：两条创建路径：
- **路径 A — 头部/面板创建**：调用 `_coordinator.createNote()` → 创建空 Atom → 自动应用当前 tag filter → 在编辑器 tab 中打开 → **不挂载到 workspace tree**（成为"未分类"笔记）
- **路径 B — 右键菜单"在文件夹中创建笔记"**：调用 `_coordinator.createWorkspaceNoteInFolder(parentNodeId)` → 创建空 Atom → 创建 note_ref 挂载到指定文件夹 → 在编辑器 tab 中打开

**实测判定**：两条路径的差异是**设计意图**（头部创建 = 快捷未分类笔记，右键创建 = 明确归属文件夹），不是 bug。但需要在语义文档中明确声明。

### D9: NotesCoordinator 实现层超出规模目标

| 属性 | 值 |
|------|-----|
| 严重度 | P1 |
| 状态 | 存续 |

**实测**：`notes_coordinator_impl.dart` 1,782 行。包含：
- typedef 声明和默认 invoker 实现（~200 行）
- 构造器和字段接线（~200 行）
- Manager 委托方法
- `createNote()` 含 tag 自动应用逻辑（~80 行）
- **WP bridge 同步代码（~260 行）** — Report 07 已确认应通过删除（非提取）消除
- Workspace tree 委托方法
- Getter 代理层（~260 行一行式委托）

**最大缩减机会**：删除 WP bridge（~260 行）可降至 ~1,520 行；进一步抽取 typedef/default invoker 到独立文件可降至 ~1,320 行。

### D10: calendar/tasks → reminders 跨 feature import

| 属性 | 值 |
|------|-----|
| 严重度 | P2 |
| 状态 | 存续 |

**实测**：
- `tasks/tasks_controller.dart:4` — `import 'package:lazynote_flutter/features/reminders/reminder_scheduler.dart' as reminders;`
- `calendar/calendar_controller.dart:4` — `import 'package:lazynote_flutter/features/reminders/reminder_scheduler.dart' as reminders;`

两处均使用 `ReminderScheduler` 在事件/任务创建/更新时调度本地通知。`as reminders` alias 表明有一定的边界意识。

---

## 1.2 Rule E 违规全景

**总计：10 处跨 feature import。** 从 PR-0252 前的 16 处降至 10 处（移除 6 处 EntryShellPage 导入，新增 2 处 reminders 导入）。

| # | 来源 feature | 来源文件 | 目标 feature | 导入文件 | 关联债务 |
|---|---|---|---|---|---|
| 1 | calendar | `calendar_controller.dart:4` | reminders | `reminders/reminder_scheduler.dart` | D10 |
| 2 | entry | `single_entry_panel.dart:6` | search | `search/search_results_view.dart` | D2 |
| 3 | entry | `workbench_shell_layout.dart:2` | diagnostics | `diagnostics/debug_logs_panel.dart` | D5 |
| 4 | notes | `note_explorer.dart:16` | tags | `tags/tag_filter.dart` | D1 相关 |
| 5 | notes | `notes_coordinator.dart:13` | workspace | `workspace/workspace_models.dart` | D4 |
| 6 | notes | `notes_coordinator.dart:14` | workspace | `workspace/workspace_provider.dart` | D4 |
| 7 | notes | `notes_page.dart:15` | workspace | `workspace/workspace_models.dart` | D4 |
| 8 | notes | `notes_page.dart:16` | workspace | `workspace/workspace_provider.dart` | D4 |
| 9 | tags | `tag_filter.dart:2` | notes | `notes/notes_style.dart` | D1 |
| 10 | tasks | `tasks_controller.dart:4` | reminders | `reminders/reminder_scheduler.dart` | D10 |

**依赖图谱**：

```
notes ──(4)──► workspace       notes ◄──(1)── tags
  │                              │
  └──(1)──► tags ──(1)──► notes  │  (双向循环)
                                 ▼
entry ──(1)──► search       calendar ──(1)──► reminders
entry ──(1)──► diagnostics  tasks ────(1)──► reminders
```

**严重度分层**：
- **HIGH（必须解决）**：notes↔workspace 4 处耦合 + notes↔tags 双向循环（共 6 处）
- **MEDIUM（需设防线）**：calendar/tasks→reminders 2 处
- **LOW（可接受风险）**：entry→search 1 处、entry→diagnostics 1 处

---

## 1.3 语义模糊地带清单

以下为从产品愿景（`vision.md`）、数据模型（`data-model.md`）、FFI 合约（`ffi-contracts.md`）、以及 v0.3 规划（`v0.3/README.md`）交叉审计后发现的语义模糊或未定义区域：

| ID | 议题 | 影响范围 | 当前状态 | 阻塞的 v0.3 PR |
|----|------|---------|---------|----------------|
| **S1** | Atom 投影语义：`type` × time-matrix × `task_status` 的完整行为矩阵未定义 | 所有视图层 | `type` 被描述为「rendering hint only」，但 type 和 time fields 不一致时的渲染规则未指定（如 `type=note` 但设了 `start_at+end_at`）；`task_status` 对所有 type 生效但 UI 处理规则未文档化 | PR-0308（task-calendar 投影） |
| **S2** | Tab/Draft/Save 状态归属：两套重复状态（coordinator managers vs WorkspaceProvider） | notes 核心路径 | Coordinator 的 6 个 manager 是真正的 source of truth，但 UI 仍读 WorkspaceProvider，通过 ~260 行 bridge 同步。Report 07 已给出删除方案 | PR-0301（递归布局）、PR-0303（buffer 同步）、PR-0304（tab 模型） |
| **S3** | Tag × Workspace Tree 交互：tag 过滤是否应影响树视图 | Explorer 面板 | Tag 过滤只影响扁平笔记列表，tree 无感知。两者在同一面板中共存但独立工作 | PR-0304（tab 模型）、PR-0307（launcher） |
| **S4** | Note 创建入口语义：头部创建 vs 右键创建的差异是否需要统一 | 笔记工作流 | 两条路径行为不同（是否挂载到 tree）。可能是设计意图但无正式文档 | 新功能开发全般 |
| **S5** | Extension Kernel → Flutter 命令系统：`command`/`parser` 能力与现有 `CommandParser`/`CommandRouter`/`CommandRegistry` 的关系 | 扩展架构 | Extension kernel 定义了四种能力（command/parser/provider/ui_slot），但 Flutter 现有命令基础设施与这些能力之间无任何文档化桥接 | PR-0310（命令插件化） |
| **S6** | Provider SPI → `external_mappings` 表交互：provider 如何读写映射表 | 同步架构 | `ProviderSpi` trait 和 `external_mappings` 表各自存在，但两者之间的交互方式未指定 | PR-0309（Google Calendar） |
| **S7** | Reminders 模块定位：是 feature 还是 infrastructure | 架构规则 | 当前作为 `features/reminders/` 存在，但被 calendar 和 tasks 跨 feature 导入，行为更像 logging/l10n 等基础设施 | Rule E 执行一致性 |
| **S8** | `NoteItem`/`NotesListResponse` 与 `AtomListItem`/`AtomListResponse` 类型共存 | FFI 层 | `ffi-contracts.md` 记录「两套类型共存直到 v0.2 统一」，但 v0.2 已过，统一是否完成未确认 | FFI 合约一致性 |

---

## 1.4 文档漂移清单

| # | 文档 | 漂移描述 | 严重度 |
|---|------|---------|--------|
| F1 | `architecture/overview.md` | 停留在 v0.1 状态，缺少 workspace、calendar、tasks、reminders、l10n、extension kernel、provider SPI 等全部 v0.2 内容 | HIGH |
| F2 | `api/ffi-contracts.md` | 按 PR 追加式组织，同一 API 域信息散落多处，缺少「当前状态」统一视图；`workspace_delete_folder` vs 实际 `workspace_delete_node` 命名不一致 | HIGH |
| F3 | CLAUDE.md FFI 表 | `entry_search` 缺少 `kind` 参数（PR-0219 已加入）；与 ffi-contracts.md 签名偏差 | MEDIUM |
| F4 | `product/roadmap.md` / `milestones.md` | v0.3 PR 列表缺少 PR-0306A 和 PR-0311 | LOW |
| F5 | `ffi-contracts.md` 类型迁移 | NoteItem/AtomListItem 共存标注为「v0.2 统一」但未确认完成状态 | MEDIUM |
| F6 | Extension Kernel → Flutter 桥接 | `command`/`parser` 能力声明存在但与 Flutter `CommandParser`/`CommandRouter`/`CommandRegistry` 无文档化映射 | MEDIUM |
| F7 | Provider SPI → external_mappings | trait 和表各自有文档但交互路径无描述 | MEDIUM |
| F8 | frontend-review/README.md | Planned Outputs 仅列到 04，缺少 05–08 | LOW |
