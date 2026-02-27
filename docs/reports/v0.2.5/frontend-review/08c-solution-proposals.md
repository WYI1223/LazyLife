# 08c — 解决方案

> 基于 08b 语义裁决推导的结构性解耦、CI 防线、文档同步方案。
> 本文为 [08-reassessment-and-replanning.md](08-reassessment-and-replanning.md) 的第三部分。

| 字段 | 值 |
|------|-----|
| 日期 | 2026-02-27 |
| 前提 | [08b-semantic-decisions.md](08b-semantic-decisions.md) S1-S8 裁决已全部完成 |
| 状态 | **完成** |

---

## 3.1 结构性解耦方案

### 3.1.1 notes↔workspace 解耦（S2 Phase 1）

**目标**：消除双状态系统，coordinator 成为唯一状态源。

**前提**：S2 裁决已确定 — 采用 B（完整目标架构 + 分阶段实施），v0.2.5 执行 Phase 1。

**当前耦合状态**（代码验证结果）：

| 耦合点 | 文件 | 导入 | 类型 |
|---|---|---|---|
| 1 | `notes_coordinator.dart:13-14` | `workspace_models.dart` + `workspace_provider.dart` | 直接 import |
| 2 | `notes_page.dart:15-16` | `workspace_models.dart` + `workspace_provider.dart` | 直接 import |
| 3 | `notes_coordinator_impl.dart:1608-1692` | `_WorkspaceProviderPort` adapter | WP Bridge 代码 |
| 4 | `notes_coordinator_impl.dart:1495-1575` | `_syncWorkspace*` 方法族 | 双状态同步逻辑 |

方向：notes → workspace 单向依赖（workspace 不 import notes）。

**WP tab/save 状态的全部消费者**（代码验证结果）：

删除 WorkspaceProvider 的 tab/save 状态前，以下消费者必须全部迁移：

| 消费者 | 文件:行 | 读取的 WP 字段 | 迁移方案 |
|---|---|---|---|
| app shell 标题 | `app.dart:71-77` | `openTabsByPane`, `activePaneId` | 改为读 coordinator 的 `openNoteIds.length` |
| notes page 覆盖层 | `notes_page.dart:440-451` | `openTabsByPane`, `saveStateByNoteId` | 改为读 coordinator/managers（步骤 1 核心） |
| workspace port snapshot | `workspace_port.dart:4` | `openTabsByPane`（typedef 字段） | 删除 typedef（随步骤 3 WP Bridge 删除） |

**受影响的测试文件**（必须同步迁移或删除）：

| 测试文件 | 受影响测试数 | 读取的 WP 字段 | 迁移方案 |
|---|---|---|---|
| `notes_controller_workspace_bridge_test.dart` | 9 cases（按文件内 `test(` 调用计数） | `openTabsByPane`, `saveStateByNoteId` | **整文件删除** — WP Bridge 不再存在，测试失去测试对象 |
| `workspace_provider_test.dart` | 15 cases 中 7 cases 受影响（按文件内 `test(` 调用计数；tab/save/draft 相关 7，pane 布局 8） | `openTabsByPane`, `saveStateByNoteId` | 保留 pane 布局测试（8 cases），删除 tab/save 状态测试（7 cases，状态已迁移到 coordinator） |
| `workspace_integration_flow_test.dart` | 5 cases | `activePaneId` | 保留 — `activePaneId` 属于 pane 布局，不删除 |
| `workspace_split_v1_test.dart` | 4 cases | `activePaneId` | 保留 — `activePaneId` 属于 pane 布局，不删除 |

**S2 Phase 1 执行步骤**：

| 步骤 | 内容 | 变更量 | 依赖 |
|---|---|---|---|
| 1a | 迁移 `NotesPage` 的 ~5 个消费点从读 WorkspaceProvider 改为读 coordinator/managers | 改 ~30 行 | — |
| 1b | 迁移 `app.dart` titleBuilder 从读 `workspace.openTabsByPane` 改为读 coordinator `openNoteIds` | 改 ~5 行 | — |
| 2 | 删除 `_syncWorkspaceFromControllerState()` (~67 行) + `_syncWorkspaceActiveSnapshot()` (~12 行) | 删 ~80 行 | 步骤 1a/1b |
| 3 | 删除 `_WorkspaceProviderPort` adapter (1608-1692 行) + `workspace_port.dart` typedef | 删 ~90 行 | 步骤 2 |
| 4 | 删除辅助映射方法 (`_mapSaveStateToWorkspace`, `_workspaceSaveStateForNote` 等) | 删 ~20 行 | 步骤 3 |
| 5 | WorkspaceProvider 缩减到仅 pane 布局（`splitActivePane` / `closeActivePane` / `layoutState`） | WP 从 664 行缩至 ~200 行 | 步骤 1-4 |
| 6 | 测试迁移：删除 `notes_controller_workspace_bridge_test.dart`；裁剪 `workspace_provider_test.dart` 中 tab/save 相关 cases | 删 ~300 行测试 | 步骤 5 |

**步骤 5 详细**：WorkspaceProvider 删除以下状态：

| 删除的状态 | 当前位置 | Phase 1 后归属 |
|---|---|---|
| `_openTabsByPane` | WorkspaceProvider | coordinator → NoteTabManager |
| `_activeTabByPane` | WorkspaceProvider | coordinator → NoteTabManager |
| `_buffersByNoteId` | WorkspaceProvider | coordinator → NoteDraftManager |
| `_saveStateByNoteId` | WorkspaceProvider | coordinator → NoteSaveTracker |
| `_saveDebounceByNoteId` | WorkspaceProvider | coordinator → NoteSaveTracker |
| `_saveInFlightByNoteId` | WorkspaceProvider | coordinator → NoteSaveTracker |
| 保留：`_layoutState`, `_activePaneId`, split/close/merge | WorkspaceProvider | WorkspaceProvider（仅 pane 布局） |

**notes→workspace import 处理**：

Phase 1 完成后，notes 仍需要 import workspace 的 pane 布局 API（`splitActivePane` 等）和 models（`WorkspaceSplitDirection` 等）。这些 import 在 Phase 2（v0.3）迁移到 `EditorShellService` 后自然消除。v0.2.5 不强制清零这些 import。

**预期效果**：
- coordinator_impl 从 1,782 行减至 ~1,600 行（WP Bridge + sync 代码删除 ~185 行）
- WorkspaceProvider 从 664 行减至 ~200 行（仅 pane 布局）
- 双状态 bug 风险消除
- 为 Phase 2（提升到 EditorShellService）提供干净的起点

### 3.1.2 notes↔tags 循环依赖打破

**目标**：消除双向依赖（Rule E 违规）。

**当前耦合状态**（代码验证结果）：

| 方向 | 文件 | 导入内容 |
|---|---|---|
| tags → notes | `tag_filter.dart:2` → `notes_style.dart` | 4 个颜色常量：`kNotesPrimaryText`, `kNotesSecondaryText`, `kNotesItemHoverColor`, `kNotesItemSelectedColor` |
| notes → tags | `note_explorer.dart:16` → `tag_filter.dart` | `TagFilter` widget 组件 |

**方案**：

| 步骤 | 内容 | 变更量 |
|---|---|---|
| 1 | 创建 `lib/shared/ui_tokens.dart`（目录 `lib/shared/` 当前不存在，需新建） | 新建 1 文件 |
| 2 | 提取 4 个共享颜色常量从 `notes_style.dart` 到 `shared/ui_tokens.dart` | 移动 4 行 |
| 3 | `tag_filter.dart` 改为从 `shared/ui_tokens.dart` 导入 | 改 1 行 |
| 4 | `notes_style.dart` 的 8 个内部消费者改为从 `shared/ui_tokens.dart` 导入共享常量（或 `notes_style.dart` 重新导出 shared 常量） | 改 8 行或 0 行 |

**决策点**：步骤 4 可选择让 `notes_style.dart` 重新导出 shared 常量（`export 'package:lazynote_flutter/shared/ui_tokens.dart'`），这样 notes 内部 8 个文件不需要改 import。更简洁。

**预期效果**：tags→notes 反向导入消除，依赖变为单向 notes→tags（notes 使用 TagFilter widget，合理的消费方向）。

### 3.1.3 Coordinator 瘦身

**目标**：将 `notes_coordinator_impl.dart` 从 1,782 行进一步降低。

**方案**：

| 步骤 | 内容 | 删减量 | 依赖 |
|---|---|---|---|
| 1 | 3.1.1 的 WP Bridge + sync 代码删除 | ~185 行 | 3.1.1 |
| 2 | 提取 typedef 声明和 default invoker 到 `notes_coordinator_types.dart` | ~150 行 | — |
| 3 | 评估 getter 代理层是否可通过公开 manager 实例简化 | ~50 行（估算） | — |

**预期效果**：~1,400 行。低于 Report 06 的行动阈值（2,200 行），为 v0.3 Phase 2（提取 tab/draft/save 到 EditorShellService）留出膨胀空间。

### 3.1.4 Reminders 迁移（S7）

**目标**：将 reminders 从 `features/` 迁移到 `lib/core/`，消除 Rule E 违规。

**前提**：S7 裁决已确定 — Reminders 是平台基础设施，归属 `lib/core/`。

**当前状态**（代码验证结果）：

| 文件 | 行数 | 依赖方向 |
|---|---|---|
| `features/reminders/reminder_scheduler.dart` | 201 行 | 被 main.dart + tasks + calendar 引用 |
| `features/reminders/reminder_service.dart` | 168 行 | 被 scheduler 引用 |

**方案**：

| 步骤 | 内容 |
|---|---|
| 1 | 创建 `lib/core/reminders/` 目录 |
| 2 | 移动 `reminder_scheduler.dart` → `lib/core/reminders/` |
| 3 | 移动 `reminder_service.dart` → `lib/core/reminders/` |
| 4 | 更新 4 个消费者的 import 路径：`main.dart`, `tasks_controller.dart`, `calendar_controller.dart`, `test/helpers/mock_reminder_service.dart` |
| 5 | 更新 `test/reminder_scheduler_test.dart` 的 import 路径 |
| 6 | 删除空的 `lib/features/reminders/` 目录 |

**预期效果**：
- Rule E 违规（D10）从 2 处降至 0 处
- `core/` 被所有 features 合法引用，无需白名单豁免
- 触发语义变更（从视图驱动改为 Atom 生命周期驱动）留给 v0.3

### 3.1.5 低优先级解耦

| 项 | 方案 | 优先级 | 备注 |
|----|------|--------|------|
| entry→search（D2） | `SearchResultsView` 迁移到 `lib/shared/` 或 entry 内部 | LOW | 可推迟到 v0.3 |
| entry→diagnostics（D5） | 保持现状或迁移 `DebugLogsPanel` 到 shared | LOW | 诊断工具，低影响 |

---

## 3.2 CI 防线方案

**目标**：在 v0.2.5 解耦完成后，通过 CI 自动化防止 v0.3 开发中引入新的架构违规。

**当前 CI 基线**（代码验证结果）：

| 现有 CI Job | 文件位置 | 覆盖范围 |
|---|---|---|
| API Contract Docs Guard | `ci.yml:9-48` | FFI 签名变更 → 强制同步 `docs/api/*` + `API_COMPATIBILITY.md` |
| Flutter (Windows) | `ci.yml:50-77` | `dart format` + `flutter analyze` + `flutter test` + `flutter build` |
| Rust (Ubuntu) | `ci.yml:79-116` | `cargo fmt` + `cargo clippy` + `cargo test` |

**缺失的防线**：当前 CI 不检查 Rule E（跨 feature 导入）、文件膨胀、或结构层次违规。这些全靠人工 review 发现。现有 `tools/analysis/run_frontend_baseline.ps1` 使用 `lakos` 做循环依赖检测，但仅用于报告生成，未集成到 CI 阻塞流程中。

### 3.2.1 Rule E 自动化检查

**新增 CI step**：集成到 `flutter_windows` job，或作为独立 lightweight job（仅需 checkout + bash/dart，无需 Flutter SDK）。

**实现方式**：Dart 脚本 `tools/ci/rule_e_check.dart`（首选）或 bash + grep。

**检查逻辑**：

- 扫描 `lib/features/*/` 下所有 `.dart` 文件
- 检测跨 feature 导入：`import '.*features/(?!<same_feature>/)` 模式
- `lib/core/`、`lib/shared/`、`lib/app/` 的导入不受限制（core 是基础设施，shared 是共享层，app 是 shell 集成层）
- 新增违规时 CI 失败

**白名单机制**：维护 `tools/ci/rule_e_allowlist.yaml` 记录已知豁免。

**3.1 解耦后的白名单预期内容**：

| 豁免项 | 方向 | 原因 | 消除计划 |
|---|---|---|---|
| notes → workspace | `notes/` → `workspace/` pane 布局 API | Phase 1 后仍需 import（`splitActivePane` 等） | v0.3 Phase 2 提升到 EditorShellService |
| entry → search | `entry/` → `search/search_results_view.dart` | SearchResultsView 共享 UI 组件 | v0.3 迁移到 `shared/` |
| entry → diagnostics | `entry/` → `diagnostics/debug_logs_panel.dart` | 诊断面板嵌入 workbench | v0.3 或保持（诊断工具，低影响） |

**3.1 消除的违规**（不再需要白名单）：

- ~~notes ↔ tags 循环~~（3.1.2：共享常量提取到 `shared/ui_tokens.dart`）
- ~~tasks → reminders / calendar → reminders~~（3.1.4：reminders 迁移到 `core/`，Rule E 不约束 core 导入）

### 3.2.2 文件大小监控

| 阈值 | 动作 |
|---|---|
| > 1,500 行 | CI 警告（GitHub annotation `::warning`） |
| > 2,200 行 | CI 阻塞（`exit 1`） |

**扫描范围**：`lib/` 下所有 `.dart` 文件（排除 `lib/core/bindings/` 自动生成文件）。

**当前大文件及 3.1 后预期**：

| 文件 | 当前行数 | 3.1 后预期 | 是否需要豁免 |
|---|---|---|---|
| `notes_coordinator_impl.dart` | 1,782 | ~1,400（3.1.3） | 否（低于警告阈值） |
| `note_explorer.dart` | 1,720 | 1,720 | 是（超过警告阈值 1,500，但 08a D1 分析结论为 HOLD — 已确认为固有编排逻辑） |
| `workspace_provider.dart` | 664 | ~200（3.1.1） | 否 |

3.1 解耦完成后预计无需豁免。如未来出现合理大文件，记录在 `tools/ci/file_size_exemptions.yaml`。

### 3.2.3 结构层次检查

**基于 coordinator 架构规则**（Report 06 D1-D8 + S3 裁决）：

| # | 规则 | 检查方式 | 来源 |
|---|---|---|---|
| 1 | `dialogs/` 内文件不得导入 coordinator 或 manager | import 模式扫描 | D3 |
| 2 | `managers/` 内文件不得导入 Flutter widget（`package:flutter/material.dart`） | import 模式扫描 | D4 |
| 3 | 所有 manager 通过构造器注入 invoker，不允许直接 import FFI bindings | import + 构造器模式检测 | D6 |
| 4 | coordinator 不直接 import FFI bindings，通过 invoker typedef 间接调用 | import 模式扫描 | S3 |

**实现方式**：与 3.2.1 合并为单一 Dart 分析脚本 `tools/ci/architecture_check.dart`，单次扫描完成全部检查（Rule E + 文件大小 + 结构层次），作为一个 CI step 运行。

### 3.2.4 S1-S8 裁决的未来 CI 规则（v0.3 范围）

以下规则由 S1-S8 裁决定义，v0.2.5 仅记录语义约束，v0.3 实现对应功能时同步添加 CI 检查：

| 裁决 | CI 规则 | v0.2.5 状态 | 实现时机 |
|---|---|---|---|
| S1-R3 | `view_hint` 必须自动推导，禁止用户直接设置 | 语义定义 | v0.3（添加 view_hint 字段时） |
| S1-R5 | Atom 创建必须事务性伴随 atom_ref 创建 | 语义定义 | v0.3（atom_ref 强制配对实现时） |
| S1-R8 | `title` 字段自动派生，markdown 类型禁止手动设置 | 语义定义 | v0.3（添加 title 字段时） |
| S2-P2 | Tab/draft/save 状态管理不得存在于 `features/notes/` 内部 | 语义定义 | v0.3（EditorShellService 提取时） |
| S3 | Tag 筛选不得影响 workspace tree 显示；tree 始终展示完整结构 | 当前行为已符合目标语义 | v0.3（Phase A tag 查询面板实现时） |
| S4 | 所有创建路径必须生成 Atom + atom_ref；Path A 当前缺失 atom_ref | 语义定义；Path A 缺陷已知 | v0.3（创建路径统一 + Smart Folder 时） |
| S5 | First-party 命令不通过 ExtensionManifest/ExtensionRegistry 注册 | 语义定义 | v0.3（Extension Kernel 激活时） |
| S6 | ProviderSpi 实现不直接访问 `external_mappings` 表 | 语义定义 | v0.3（Sync Provider 实现时） |
| S7 | Reminder 调度由 Atom 生命周期触发，不由 view controller 触发 | 语义定义 | v0.3（触发语义重构时） |
| S8 | `NoteItem` DTO 完全废弃，所有 note API 返回 `AtomListItem` | 语义定义 | v0.3（FFI 类型统一时） |

v0.2.5 中这些规则以 08b 裁决文档形式存在作为设计约束。S3 当前代码行为已符合目标语义（tag filter 和 explorer tree 独立工作），S4 的 Path A 缺陷（创建 Atom 不伴随 atom_ref）已记录为 v0.3 修正项。v0.3 各 PR 中逐项实现并添加对应 CI 自动化检查。

---

## 3.3 文档同步方案

**目标**：将 v0.2.5 解耦执行和 S1-S8 语义裁决的结果同步到架构文档和治理文档中，消除文档漂移。

**验证方法**：逐项对照当前文档实际内容，确认需要行动的项和已完成的项。

### 需要行动的文档（7 项）

| # | 文档 | 行动 | 优先级 | 关联 |
|---|------|------|--------|------|
| 1 | `architecture/overview.md` | **完整重写**至 v0.2.5 实际状态。当前为 v0.1 基线，缺失 workspace tree、tasks time-matrix、calendar、extension kernel、sync provider SPI、Flutter features 全貌。这是架构文档的入口。 | **HIGH** | F1 |
| 2 | `api/ffi-contracts.md` | 按 API 域重组为「当前状态」文档。~~修正 `workspace_delete_folder` → `workspace_delete_node`~~（验证结果：当前 API 名称 `workspace_delete_folder` 与文档一致，无需修正）。标注 NoteItem → AtomListItem 统一方向（S8 裁决）。 | MEDIUM | F2, F5, S8 |
| 3 | `architecture/extension-kernel.md` | 添加 first-party / third-party 边界定义章节。当前文档定义了 manifest/registry/capability 合约，但未区分 first-party（硬编码在 EntryParserChain + CommandRegistry）与 third-party（通过 ExtensionManifest 注册）的路径分离。 | MEDIUM | S5 |
| 4 | `architecture/provider-spi.md` | 添加三层职责分离章节。当前文档定义了 ProviderSpi trait + registry，但未区分 Provider（同步执行）/ Orchestrator（工作流协调）/ Mapping（external_mappings 所有权）三层。ProviderSpi 实现禁止直接访问 mapping 表。 | MEDIUM | S6 |
| 5 | `architecture/engineering-standards.md` | Rule E 条目补充说明：`lib/core/` 作为基础设施层不受跨 feature 限制，所有 feature 可合法导入。Reminders 迁移到 `core/` 后不再需要 Rule E 豁免。当前措辞隐含但未明确。 | LOW | S7 |
| 6 | `governance/API_COMPATIBILITY.md` | 更新 NoteItem/AtomListItem 统一时间线：当前文档标记为 v0.2 breaking change，S8 裁决将实际执行推迟至 v0.3。需修改对应行的版本号。 | MEDIUM | S8 |
| 7 | `CLAUDE.md` | 3.1 解耦完成后同步更新：`lib/shared/` 目录（3.1.2 新建）、`lib/core/reminders/` 目录（3.1.4 新建）、WorkspaceProvider 缩减后的职责描述、coordinator 架构变更。 | LOW | 3.1 |

### 已验证无需行动的文档（3 项）

| # | 文档 | 验证结果 | 关联 |
|---|------|----------|------|
| 8 | `CLAUDE.md` FFI 表 | `entry_search(text, kind?, limit?)` 签名已正确；全部 FFI 函数与 `ffi-contracts.md` 对齐。 | F3 |
| 9 | `product/roadmap.md` | PR-0306A 和 PR-0311 已在 v0.3 section 中列出（`PR-0301 to PR-0311 (plus PR-0306A)`）。 | F4 |
| 10 | `frontend-review/README.md` | Planned Outputs 列表已包含 01-08 全部条目。 | F8 |
