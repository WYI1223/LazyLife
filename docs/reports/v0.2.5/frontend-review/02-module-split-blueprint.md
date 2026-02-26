# 模块拆分方案（边界图 + 优先级）

---

## 0. 文档信息与输入依据

| 项目 | 值 |
|------|-----|
| **项目名称** | LazyNote — Flutter 前端模块拆分方案 |
| **方案负责人** | AI Agent（Claude） |
| **审核人** | 前端 TL（WYI1223，已签字） |
| **日期** | 2026-02-22 |
| **报告版本** | M3 完成（M1 当前边界映射 ✓ · M2 目标边界设计 ✓ · M3 优先级排序 ✓ · TL 审核签字 ✓） |
| **代码基线** | branch: `main`, commit: `4144598` （与体检报告一致） |
| **运行环境** | Flutter 3.41.0 · Dart 3.11.0 · FRB 2.11.1 · Windows 11 |

### 关联输入

| 输入 | 路径 | 状态 |
|------|------|------|
| 代码体检报告（PR-0255A） | `docs/reports/v0.2.5/frontend-review/01-code-health-report.md` | M4 完成，TL 已签（WYI1223） |
| Lakos 依赖图 | `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.svg` | 已确认 |
| 架构规则 | `docs/architecture/engineering-standards.md` Rule A–F | 基线约束 |

### 当前约束

| 类别 | 约束 |
|------|------|
| **交付约束** | v0.3 高级布局、拖拽分屏功能计划中；拆分不得阻塞后续需求叠加 |
| **技术约束** | 不换状态管理框架（保持 ChangeNotifier + AnimatedBuilder）；不升级 FRB 大版本；保持 Rule A–F 合规 |
| **人员约束** | 前端 Owner 空缺，由 AI Agent 主导方案设计；TL 审核带宽有限 |
| **发布约束** | 非公开发布窗口期，重构可执行，但需控制单次变更范围 |

---

## 1. 方案摘要

### 总体策略

**"先拆职责域止血，再按边界分层治理；优先拆解笔记核心链路的上帝对象，不做全量重写。"**

### 拆分范围

本轮直接拆分 P0 × 2 + P1 × 1 = **3 个主拆分对象**。其余 P1 × 3 模块（NotesPage、NoteContentArea、WorkspaceProvider）作为主拆分的**伴随受益模块**——NotesController 拆分完成后，这三个模块的耦合度和可测试性会自然改善，无需独立拆分动作。

**0255A 风险清单与本轮覆盖关系：**

| 0255A 等级 | 模块 | 本轮定位 |
|-----------|------|---------|
| P0 | NotesController | **主拆分对象 #1** |
| P0 | NoteExplorer | **主拆分对象 #2** |
| P1 | EntryShellPage | **主拆分对象 #3** |
| P1 | NotesPage | 伴随受益（NotesController 拆分后 controller 耦合点自然解耦） |
| P1 | NoteContentArea | 伴随受益（NotesController 拆分后 mock 成本降低） |
| P1 | WorkspaceProvider | 伴随受益（NotesController 工作区域提取后行为层同步简化） |

**主拆分对象 Top 3：**

| 优先级 | 模块 | 原因（风险/收益/依赖） | 拆分策略 |
|--------|------|----------------------|---------|
| 1 | NotesController（P0, 3160 行） | 核心链路上帝对象，9 域耦合，62 处广播式 notifyListeners，改任何一域牵动全部消费者（0255A P0-1） | 按职责域拆分为 5–6 个 focused controller/manager |
| 2 | NoteExplorer（P0, 2280 行） | 笔记组织链路巨型 Widget，14 个长方法 + 549 行内联对话框无法独立测试（0255A P0-2） | 提取对话框为独立 widget，提取拖拽/渲染为 mixin |
| 3 | EntryShellPage（P1, 362 行） | Rule E 违规最大源头，6 处跨 feature import，每新增 feature 必须修改此文件（0255A P1-1） | 引入 section builder 注册机制，消除跨 feature 直接 import |

### 预计收益

- **回归风险降低**：单一文件修改不再影响 9 个职责域的全部消费者
- **可维护性提升**：每个拆分后模块 <500 行，职责单一，新人可独立理解
- **并行开发解锁**：不同职责域的修改不再产生同文件冲突
- **`notifyListeners()` 精准化**：从 62 处广播降为按域通知，减少不必要 UI 重建

### 本轮不做项

- P2 模块拆分（SingleEntryController, WorkbenchShellLayout, TagFilter 等）
- 状态管理框架迁移（不从 ChangeNotifier 切换到 BLoC/Riverpod）
- 跨 feature 共享层设计（`lib/shared/` 建设推迟到拆分完成后评估）
- 具体周计划和 PR 节奏（排期在 PR-0255C）

---

## 2. 设计原则与约束

### 2.1 拆分设计原则

| # | 原则 | 说明 |
|---|------|------|
| 1 | **职责单一** | 每个 controller/manager 只管理一个职责域（如列表、Tab、草稿、标签、工作区树），不跨域持有状态 |
| 2 | **依赖单向** | UI Widget → Controller/Manager → FFI Invoker。禁止 controller 直接操作 Widget 状态 |
| 3 | **先稳定接口，再重构内部** | 每个拆分步骤先定义 manager 的 public API，再迁移内部实现。消费者通过接口访问 |
| 4 | **最小行为变化** | 拆分阶段保持用户可见行为不变。自动保存时序、Tab 切换语义、工作区树操作结果均不改变 |
| 5 | **可测试性优先** | 拆出的 manager 必须可独立实例化和单元测试，不依赖 Widget 树或 BuildContext |
| 6 | **小步可回退** | 每个职责域独立提取为一个 PR。每个 PR 可独立 revert，不阻塞其他域的拆分 |

### 2.2 当前约束

| 约束类型 | 具体内容 |
|---------|---------|
| **框架约束** | 保持 `ChangeNotifier` + `AnimatedBuilder`。新 manager 继续使用 ChangeNotifier；后续如需迁移，每个 manager 是独立替换单元 |
| **FFI 约束** | invoker 注入模式保留。拆分后 invoker 从 NotesController 下沉到对应 manager |
| **Rule E 约束** | 拆分后 `features/<name>` 之间仍禁止互相 import 内部。workspace 模块的引用需通过定义良好的接口 |
| **测试约束** | 现有测试套件（312 pass / 1 known-fail）是拆分的验收门槛。已知失败项：`smoke_test.dart` 的 "calendar route is reachable from workbench"（`CalendarPage` L67 Row 溢出，属布局约束问题而非逻辑错误，不阻塞本轮拆分）。每个拆分 PR 必须不引入新的测试失败 |

---

## 3. 当前结构（As-is）与目标结构（To-be）对照

### 3.1 重构前基线（As-is）简图

> **状态：历史快照。** 以下为 PR-0252 重构前的代码结构（commit `4144598`），保留作为基线对照。重构后实际结构见 Section 3.2。

```
┌──────────────────────────────────────────────────────────────┐
│                   EntryShellPage (P1)                         │
│  ┌──────────────┐  直接 import 5 个 feature 模块             │
│  │ SingleEntry   │  owns: SingleEntryController               │
│  │ Controller    │  owns: NotesController ──────────────────┐ │
│  └──────────────┘                                           │ │
│  section switch → [NotesPage|TasksPage|CalendarPage|...]    │ │
└──────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────▼────────────────────┐
          │         NotesController (P0)            │
          │         3,160 行 · 73 方法              │
          │         9 个职责域全部耦合               │
          │                                        │
          │  ┌─────────┐ ┌─────────┐ ┌──────────┐ │
          │  │笔记列表  │ │Tab 管理  │ │草稿/自保 │ │
          │  │管理      │ │         │ │存        │ │
          │  └────┬─────┘ └────┬────┘ └────┬─────┘ │
          │  ┌────┴─────┐ ┌───┴─────┐ ┌───┴──────┐│
          │  │保存状态   │ │标签管理  │ │笔记创建  ││
          │  │追踪      │ │         │ │          ││
          │  └────┬─────┘ └────┬────┘ └────┬─────┘│
          │  ┌────┴─────┐ ┌───┴─────┐ ┌───┴──────┐│
          │  │工作区树   │ │分屏管理  │ │工作区    ││
          │  │CRUD      │ │         │ │状态同步  ││
          │  └──────────┘ └─────────┘ └──────────┘│
          │                                        │
          │  60 个状态字段 · 62 处 notifyListeners  │
          │  12 个 FFI invoker · 15 个 >50 行方法   │
          └────────────────────────────────────────┘
                    │                    │
     ┌──────────────▼──────┐  ┌──────────▼──────────┐
     │ NoteExplorer (P0)   │  │ NotesPage (P1)       │
     │ 2,280 行 · 38 方法  │  │ 856 行               │
     │ 8 个职责域全部耦合   │  │ 30+ controller 耦合点│
     │                     │  │ WindowListener       │
     │ ┌──────────────────┐│  │ Fan-out = 17         │
     │ │树渲染 + 遗留模式  ││  └─────────────────────┘
     │ │对话框 ×4 (549行)  ││
     │ │拖拽生命周期        ││
     │ │上下文菜单          ││
     │ │树状态管理          ││
     │ └──────────────────┘│
     │ Fan-out = 12        │
     └─────────────────────┘
```

**核心痛点：**

1. **NotesController 9 域耦合**（0255A P0-1）：任何一个域的修改都可能触发 62 处 `notifyListeners()` 广播，影响所有 6 个消费者 Widget 重建。9 个域共享 60 个状态字段，跨域读写无隔离。
2. **NoteExplorer 巨型 State**（0255A P0-2）：4 个对话框内联于 State（549 行），树渲染与拖拽混合，14 个 >50 行方法。任何树交互变更都在同一个 2,088 行的 State 类中修改。
3. **EntryShellPage 直接 import**（0255A P1-1）：6 处跨 feature import，每新增 feature 必须修改此文件。违反 Rule E。
4. **notes→workspace 单向深度依赖**（0255A 附录 7.2）：NotesController 和 NotesPage 合计 4 处 import workspace 模块。NotesController 行为层双向状态同步（push L2596 / pull L2553）。

**职责域交叉分析（NotesController 内部）：**

| 域 | 缝隙质量 | 跨域耦合描述 |
|----|---------|-------------|
| 工作区树 CRUD | **清洁** | 自包含，仅在 folder delete 时触发 Tab 对账（`_reconcileOpenTabsAfterWorkspaceMutation`） |
| 草稿/自动保存 | **清洁** | 窄聚焦，主要泄漏点是保存状态通知和缓存同步 |
| 分屏管理 | **清洁** | 大部分委托给 WorkspaceProvider，controller 仅做同步桥接 |
| 标签管理 | **中等** | 变更操作已队列化；但 filter 应用会触发列表重载 |
| Tab 管理 | **中等** | 切换时需 flush 保存守卫；preview→pin 提升耦合到编辑状态 |
| 保存状态追踪 | **中等** | flush 守卫耦合到草稿版本追踪 |
| 笔记列表管理 | **多孔** | 与 Tab、草稿、筛选器双向耦合 |
| 工作区状态同步 | **中等** | 跨域编排层，读写 Tab + 草稿 + 保存状态 |
| 笔记创建 | **多孔** | 高基数操作，触达 8 个域（列表、Tab、草稿、保存、标签、工作区、焦点） |

> **拆分策略指导**：从"清洁缝隙"开始拆分（工作区树 → 草稿 → 标签），最后处理"多孔"域（列表 → 创建编排）。

---

### 3.2 实际结构（Post-refactor Actual）边界图

> **状态：PR-0252 重构完成后实际代码结构（2026-02-26）。** 原 To-be 设计已全部落地，以下为实际行数和文件清单。

#### 3.2.1 NotesController → NotesCoordinator + Managers（已完成）

原 3,160 行上帝对象已删除，替换为 **1 个 coordinator facade** + **6 个 focused manager** + **5 个辅助类型文件**：

```
┌──────────────────────────────────────────────────────────────────┐
│         NotesCoordinator（已完成，接口 53 行 + 实现 1,782 行）     │
│  职责：组装各 manager，提供统一 public API 给 Widget 层           │
│  持有：各 manager 实例引用（非继承）                              │
│  结构：notes_coordinator.dart（接口导出）                         │
│        notes_coordinator_impl.dart（实现 + 跨域编排）             │
│                                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ NoteListManager  │  │ NoteTabManager   │  │ NoteDraftManager │  │
│  │ 227 行           │  │ 363 行           │  │ 263 行           │  │
│  │                  │  │                  │  │                  │  │
│  │ 列表加载/筛选    │  │ open/close/switch│  │ 草稿缓存/自保存  │  │
│  │ 详情加载/缓存    │  │ preview→pin      │  │ 版本追踪/排队    │  │
│  │                  │  │ pane 切换/分屏   │  │                  │  │
│  │ invoker:         │  │                  │  │ invoker:         │  │
│  │  notesList       │  │                  │  │  noteUpdate      │  │
│  │  noteGet         │  │                  │  │                  │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │            ┌───────▼────────┐  ┌────────▼─────────┐ │
│  ┌────────▼────────┐   │ NoteTagManager  │  │ NoteSaveTracker   │ │
│  │ WorkspaceTree   │   │ 330 行          │  │ 95 行             │ │
│  │ Manager         │   │                 │  │                   │ │
│  │ 533 行          │   │ 标签 CRUD/筛选  │  │ 保存状态枚举      │ │
│  │                 │   │ 变更排队/归一化  │  │ flush 守卫        │ │
│  │ folder CRUD     │   │                 │  │                   │ │
│  │ 树渲染辅助      │   │ invoker:        │  └───────────────────┘ │
│  │ 工作区状态同步  │   │  noteSetTags    │                        │
│  │                 │   │  tagsList       │                        │
│  │ invoker:        │   │                 │                        │
│  │  workspace*6    │   └─────────────────┘                        │
│  └─────────────────┘                                              │
└──────────────────────────────────────────────────────────────────┘

辅助文件：
  workspace_tree_children_loader.dart  (379 行) — 异步树节点加载器
  workspace_tree_types.dart            (54 行)  — 工作区树类型定义
  workspace_tree_error_utils.dart      (33 行)  — 错误处理工具
  note_tag_manager_types.dart          (52 行)  — 标签变更类型定义
  note_tag_mutation_queue.dart         (85 行)  — 标签变更排队

各 manager 均为独立 ChangeNotifier，可独立实例化和测试。
NotesCoordinator 作为 facade 对外暴露合并 API，Widget 层不直接持有 manager。
notes_controller.dart 已删除。
```

**manager 间通信规则（实际落地）：**

| 调用方 | 被调用方 | 通信方式 | 说明 |
|--------|---------|---------|------|
| NoteTabManager | NoteDraftManager | 方法调用 | Tab 切换前 flush 当前草稿 |
| NoteTabManager | NoteSaveTracker | 方法调用 | 切换后刷新保存状态 |
| NoteDraftManager | NoteSaveTracker | 方法调用 | 保存完成后更新状态枚举 |
| NoteTagManager | NoteListManager | 回调/事件 | 筛选变更触发列表重载 |
| WorkspaceTreeManager | NoteTabManager | 回调/事件 | folder delete 后对账 open tabs |
| NotesCoordinator | 所有 manager | 直接持有 | 组装 + 编排跨域操作（如 createNote） |

> 笔记创建等高基数跨域操作保留在 NotesCoordinator 实现层统一编排，不拆入任何单一 manager。

**规模对照（计划 vs 实际）：**

| 组件 | 计划目标 | 实际行数 | 达标 |
|------|---------|---------|------|
| NotesCoordinator | <300 行 | 53 行（接口）+ 1,782 行（实现） | 接口达标；实现层承担了全部跨域编排，超出原设想 |
| NoteListManager | <400 行 | 227 行 | ✓ |
| NoteTabManager | <400 行 | 363 行 | ✓ |
| NoteDraftManager | <300 行 | 263 行 | ✓ |
| NoteTagManager | <350 行 | 330 行 | ✓ |
| NoteSaveTracker | <250 行 | 95 行 | ✓ |
| WorkspaceTreeManager | <500 行 | 533 行 | 略超 33 行（含 children loader 分离后仍 533 行，因增加了 delete 策略） |

#### 3.2.2 NoteExplorer 瘦化（已完成）

原 2,280 行巨型 State 拆分为 **1 个瘦化 State + 4 个独立对话框 Widget + 1 个树构建器（含类型定义）**：

```
┌─────────────────────────────────────────────────┐
│             NoteExplorer（已瘦化）                 │
│  职责：组装树 + 接收用户交互                      │
│  实际行数：1,720 行                               │
│                                                  │
│  ┌──────────────────┐  ┌──────────────────┐      │
│  │ ExplorerTree     │  │ ExplorerDrag     │      │
│  │ Builder          │  │ Controller       │      │
│  │ 357 行           │  │ 103 行           │      │
│  │                  │  │                  │      │
│  │ workspace rows   │  │ 拖拽生命周期     │      │
│  │ legacy rows      │  │ 拖拽反馈构建     │      │
│  │ 递归子节点       │  │                  │      │
│  └──────────────────┘  └──────────────────┘      │
│                                                  │
│  ExplorerTreeBuilderTypes  127 行 — 类型定义      │
│  ExplorerTreeItem          230 行 — 树节点组件    │
│  ExplorerTreeState         229 行 — 树展开状态    │
│  ExplorerContextMenu        65 行 — 右键菜单      │
└──────────────────────────────────────────────────┘
         │
         │ showDialog() 调用
         ▼
┌──────────────────────────────────────────────────┐
│          独立对话框 Widgets（已提取）               │
│                                                  │
│  ┌─────────────┐  ┌─────────────┐                │
│  │CreateFolder  │  │DeleteFolder  │                │
│  │Dialog        │  │Dialog        │                │
│  │ 85 行        │  │ 127 行       │                │
│  └─────────────┘  └─────────────┘                │
│  ┌─────────────┐  ┌─────────────┐                │
│  │RenameNode   │  │MoveNode     │                │
│  │Dialog        │  │Dialog        │                │
│  │ 93 行        │  │ 105 行       │                │
│  └─────────────┘  └─────────────┘                │
│                                                  │
│  每个对话框接收回调参数，不持有 controller        │
│  D6 检查通过：零 coordinator/manager import       │
└──────────────────────────────────────────────────┘
```

**NoteExplorer 规模偏差说明：** 原计划瘦化到 <500 行，实际 1,720 行。对话框和树构建器已成功提取，但 NoteExplorer 本身承担了较多上下文菜单、拖拽包装、workspace 行交互等逻辑，这些属于 explorer 的固有职责。03 报告 Section 6.3 已将进一步拆分列为 D3 技术债，触发条件为 NotesPage 超过 1000 行或 v0.3 分屏增强。

#### 3.2.3 EntryShellPage 解耦（已完成）

6 处跨 feature import 已全部消除，通过 SectionRegistry builder 模式实现：

```
重构前:                                重构后:
┌────────────────────┐                ┌────────────────────┐
│ EntryShellPage     │                │ EntryShellPage     │
│ 362 行             │                │ 278 行             │
│                    │                │                    │
│ import calendar    │                │ import section     │
│ import diagnostics │    ──────►     │   _registry (app/) │
│ import notes ×2    │                │                    │
│ import settings    │                │ registry.builder() │
│ import tasks       │                │ registry.title()   │
│                    │                │                    │
│ 6 跨 feature import│                │ 0 跨 feature import│
│ owns: Coordinator  │                │ sectionRegistry?   │
└────────────────────┘                └────────────────────┘

注册点 (app.dart — composition root)：
  SectionRegistry(listenable: coordinator.workspaceProvider)
  registry.register(SectionRegistration(
    id: WorkbenchSectionIds.notes,
    builder: (ctx, onBack) => NotesPage(controller: coordinator, ...),
    titleBuilder: (ctx) => l10n.workbenchSectionNotes,
  ));
  // tasks, calendar, settings, rustDiagnostics 同理

app/section_registry.dart (51 行)：
  SectionWidgetBuilder typedef
  SectionTitleBuilder typedef
  SectionRegistration class
  SectionRegistry class (含 optional Listenable)
```

**关键设计决策：**
- NotesCoordinator 生命周期从 EntryShellPage state 移到 `_LazyNoteAppState`
- UiSlotRegistry 创建同样移到 app state，通过 section builder 闭包捕获传入 NotesPage
- `WorkbenchSection` enum 已删除，统一使用 `WorkbenchSectionIds` string 常量
- 未知 sectionId 在 `_openSection` 和 `initState` 中归一化为 `home`

#### 3.2.4 拆分后实际目录结构

```
lib/app/
├── app.dart                           (201 行)  — Composition root：注册 section、创建 coordinator
├── section_registry.dart              (51 行)   — SectionRegistry + SectionRegistration 类型定义
├── app_locale_controller.dart                   — 语言切换 ChangeNotifier
├── routes.dart                                  — AppRoutes 命名常量
└── ui_slots/                                    — UI 扩展槽系统

lib/features/entry/
├── entry_shell_page.dart              (278 行)  — Workbench shell，零跨 feature import
├── single_entry_controller.dart                 — 搜索/命令输入控制器
├── single_entry_panel.dart                      — 搜索输入 UI
├── workbench_shell_layout.dart                  — Workbench 布局管理
├── command_parser.dart                          — 命令解析
├── command_registry.dart                        — 命令注册
├── command_router.dart                          — 命令路由
└── entry_state.dart                             — 入口状态模型

lib/features/notes/
├── workspace_port.dart                (28 行)   — 抽象端口：notes 所需的工作区操作接口
├── notes_coordinator.dart             (53 行)   — 接口导出（barrel file）
├── notes_coordinator_impl.dart        (1,782 行)— Facade 实现 + 跨域编排
├── note_tab_manager.dart              (431 行)  — Widget 层 Tab UI 管理（原有文件，已整合）
├── managers/
│   ├── note_list_manager.dart         (227 行)  — 列表加载/筛选/详情缓存
│   ├── note_tab_manager.dart          (363 行)  — Tab open/close/switch/pane 状态
│   ├── note_draft_manager.dart        (263 行)  — 草稿缓存/自动保存/版本
│   ├── note_tag_manager.dart          (330 行)  — 标签 CRUD/筛选/归一化
│   ├── note_tag_manager_types.dart    (52 行)   — 标签变更类型定义
│   ├── note_tag_mutation_queue.dart   (85 行)   — 标签变更排队
│   ├── note_save_tracker.dart         (95 行)   — 保存状态枚举/flush
│   ├── workspace_tree_manager.dart    (533 行)  — 工作区树 CRUD + 状态同步
│   ├── workspace_tree_children_loader.dart (379 行) — 异步树节点加载
│   ├── workspace_tree_types.dart      (54 行)   — 工作区树类型定义
│   └── workspace_tree_error_utils.dart (33 行)  — 错误处理工具
├── dialogs/
│   ├── create_folder_dialog.dart      (85 行)   — 创建文件夹对话框
│   ├── delete_folder_dialog.dart      (127 行)  — 删除文件夹对话框
│   ├── rename_node_dialog.dart        (93 行)   — 重命名节点对话框
│   └── move_node_dialog.dart          (105 行)  — 移动节点对话框
├── explorer_tree_builder.dart         (357 行)  — 树行构建逻辑
├── explorer_tree_builder_types.dart   (127 行)  — 树构建器类型定义（P2-5 提取）
├── note_explorer.dart                 (1,720 行)— 树组装 + 用户交互
├── note_content_area.dart             (879 行)  — 编辑器区域（伴随受益）
├── notes_page.dart                    (856 行)  — 笔记页面 shell（伴随受益）
├── note_editor.dart                   (110 行)  — 编辑器 widget
├── explorer_tree_item.dart            (230 行)  — 树节点 widget
├── explorer_tree_state.dart           (229 行)  — 树展开状态
├── explorer_drag_controller.dart      (103 行)  — 拖拽控制器
├── explorer_context_menu.dart         (65 行)   — 右键菜单
└── notes_style.dart                   (71 行)   — 共享样式常量
```

### 3.3 依赖方向规则

以下规则适用于拆分后的代码结构，是后续 code review 的判定依据。

#### 3.3.1 层级依赖方向（单向，禁止反向）

```
Widget 层 (Page/Explorer/Dialog)
    │  可依赖 ↓
    ▼
Coordinator 层 (NotesCoordinator)
    │  可依赖 ↓
    ▼
Manager 层 (NoteListManager, NoteTabManager, ...)
    │  可依赖 ↓
    ▼
Invoker / FFI 层 (rust_api.*, RustBridge)
```

#### 3.3.2 具体依赖规则

| # | 规则 | 说明 | 违规示例 |
|---|------|------|---------|
| D1 | **Widget → Coordinator：允许** | Page/Explorer 通过 NotesCoordinator public API 访问数据和触发操作 | — |
| D2 | **Widget → Manager：禁止** | Widget 不直接持有或调用 manager 实例。通过 coordinator 中转 | `NotesPage` 直接 import `NoteListManager` |
| D3 | **Manager → Manager：受限允许** | 仅限 coordinator 在构造时注入的显式引用。禁止 manager 自行查找其他 manager | `NoteTagManager` 内部自行构造 `NoteListManager` |
| D4 | **Manager → Invoker：允许** | 每个 manager 持有自己职责域的 invoker，通过构造函数注入 | — |
| D5 | **Manager → Widget：禁止** | manager 不 import 任何 Widget 文件，不访问 BuildContext | `NoteListManager` import `notes_page.dart` |
| D6 | **Dialog → Coordinator/Manager：禁止** | 对话框通过回调参数（`onConfirm`, `onCancel`）通信，不持有 controller 引用 | `CreateFolderDialog` import `NotesCoordinator` |
| D7 | **跨 feature：禁止直接 import** | `features/notes/` 不 import `features/workspace/` 内部文件。workspace 交互通过 **抽象端口 + app 层适配**：notes 模块内定义 `WorkspacePort`（抽象类/接口，声明 notes 所需的工作区操作签名），`WorkspaceTreeManager` 仅依赖 `WorkspacePort`。app 层（`EntryShellPage` 或 `main.dart`）负责构造 `WorkspacePortAdapter implements WorkspacePort`（内部持有 `WorkspaceProvider`），并注入 `NotesCoordinator` 构造函数。这样 notes 模块代码中 **零 workspace import**（`WorkspacePort` 定义在 notes 内部），Dart import 链路完全闭合 | `note_list_manager.dart` import `workspace_provider.dart` |
| D8 | **共享样式：M2 临时豁免** | `notes_style.dart` 可被 `tags/tag_filter.dart` 引用（纯样式常量，无业务逻辑）。**此条为 D7 的显式临时豁免，不计入 D7 违规统计**。豁免条件：仅限纯样式常量文件（无 import 业务模型/controller）。退出条件：tags 模块超过 500 行或被第 3 个 feature 引用时，提取到 `lib/shared/styles/` 并撤销此豁免 | — |

#### 3.3.3 已废弃依赖清单（拆分后必须消除）

| 当前依赖 | 位置 | 废弃原因 | 替代方案 |
|---------|------|---------|---------|
| `notes_controller.dart` → `workspace_models.dart` | L9 | 跨 feature import（Rule E 违规） | notes 内定义 `WorkspacePort` 抽象接口；`WorkspaceTreeManager` 仅依赖 `WorkspacePort`；app 层构造 `WorkspacePortAdapter`（implements WorkspacePort，内部持有 WorkspaceProvider）并注入 coordinator。notes 模块内零 workspace import |
| `notes_controller.dart` → `workspace_provider.dart` | L10 | 跨 feature import（Rule E 违规） | 同上 |
| `notes_page.dart` → `workspace_models.dart` | L15 | 跨 feature import | `NotesPage` 通过 `NotesCoordinator` public API 获取工作区数据，不直接 import workspace 文件 |
| `notes_page.dart` → `workspace_provider.dart` | L16 | 跨 feature import | 同上 |
| `note_explorer.dart` → `tag_filter.dart` | L12 | 跨 feature import | **本轮保留为已知偏差**（P2 风险）。`TagFilter` 仅 243 行纯 UI 组件，本轮不建设 `lib/shared/`。当 tags 模块增长超过 500 行或被第 3 个 feature 引用时，触发提取到 `lib/shared/widgets/` |
| `entry_shell_page.dart` → 5 个 feature | L7–15 | 跨 feature import（Rule E 最大违规源） | SectionRegistry builder 模式 |

---

## 4. 模块拆分清单

### 4.1 拆分对象清单

以下清单将 Section 3.2 的 To-be 架构图落到实际模块级动作。每行一个拆分单元，为 PR-0255C 排期提供输入。

#### 主拆分对象 #1：NotesController → Coordinator + 6 Managers

| 拆分单元 | 当前位置 | 当前问题（引用 0255A） | 目标边界 | 接口变化 | 实施风险 | 依赖项 | 预期收益 | 本轮纳入 |
|---------|---------|----------------------|---------|---------|---------|--------|---------|---------|
| WorkspaceTreeManager | `notes_controller.dart` L708–1185, L2699–2714, L2735–2933 | 工作区树 CRUD 混入笔记控制器（P0-1） | 独立 ChangeNotifier，持有 workspace ×6 invoker + WorkspacePort | 无（coordinator 转发） | **低** | 先创建 `WorkspacePort` 抽象接口 | 工作区树操作独立测试、独立通知 | **是** |
| NoteDraftManager | `notes_controller.dart` L1885–1921, L2348–2464 | 草稿/自保存与 9 个域共享状态（P0-1） | 独立 ChangeNotifier，持有 noteUpdate invoker | 无 | **低** | 无前置 | 自保存逻辑独立测试、定时器隔离 | **是** |
| NoteTagManager | `notes_controller.dart` L1372–1467, L1588–1664, L2716–2733 | 标签管理与列表/创建耦合（P0-1） | 独立 ChangeNotifier，持有 noteSetTags + tagsList invoker | 无 | **低–中** | 无前置（但 filter→list 回调需 coordinator 桥接） | 标签操作队列独立、筛选逻辑清晰 | **是** |
| NoteTabManager | `notes_controller.dart` L597–667, L1676–1879 + 现有 `note_tab_manager.dart` | Tab 管理与保存守卫/草稿耦合（P0-1） | 独立 ChangeNotifier，整合现有 TabManager widget | 无（coordinator 转发） | **中** | 需 NoteDraftManager + NoteSaveTracker 先提取 | Tab 切换独立、preview→pin 语义清晰 | **是** |
| NoteSaveTracker | `notes_controller.dart` L436–465, L1187–1268, L2480–2531 | 保存状态追踪与草稿/标签耦合（P0-1） | 独立 ChangeNotifier，无 invoker（纯状态枚举） | 无 | **低** | 无前置 | badge/flush 逻辑独立、通知精准 | **是** |
| NoteListManager | `notes_controller.dart` L1923–2148, L521–543 | 列表管理与 Tab/草稿/筛选双向耦合（P0-1） | 独立 ChangeNotifier，持有 notesList + noteGet invoker | 无 | **中–高** | 需 NoteTagManager 先提取（filter 依赖） | 列表加载/缓存独立、详情加载隔离 | **是** |
| NotesCoordinator | `notes_controller.dart`（全文替换） | 9 域耦合无编排层（P0-1） | Facade ChangeNotifier，持有所有 manager 引用 | **有**：消费者从 `NotesController` 切换到 `NotesCoordinator` | **中** | 所有 manager 提取完成后 | 统一 API 入口、跨域操作编排 | **是** |

#### 主拆分对象 #2：NoteExplorer → 瘦 State + 对话框 + Builder

| 拆分单元 | 当前位置 | 当前问题（引用 0255A） | 目标边界 | 接口变化 | 实施风险 | 依赖项 | 预期收益 | 本轮纳入 |
|---------|---------|----------------------|---------|---------|---------|--------|---------|---------|
| CreateFolderDialog | `note_explorer.dart` L1573–1696 | 124 行对话框内联于 State（P0-2） | 独立 StatefulWidget，接收回调参数 | 无（内部提取） | **低** | 无前置 | 可独立 widget test | **是** |
| DeleteFolderDialog | `note_explorer.dart` L1698–1841 | 144 行对话框内联于 State（P0-2） | 独立 StatefulWidget，接收回调参数 | 无 | **低** | 无前置 | 可独立 widget test | **是** |
| RenameNodeDialog | `note_explorer.dart` L1898–2019 | 122 行对话框内联于 State（P0-2） | 独立 StatefulWidget，接收回调参数 | 无 | **低** | 无前置 | 可独立 widget test | **是** |
| MoveNodeDialog | `note_explorer.dart` L2021–2179 | 159 行对话框内联于 State（P0-2） | 独立 StatefulWidget，接收回调参数 | 无 | **低** | 无前置 | 可独立 widget test | **是** |
| ExplorerTreeBuilder | `note_explorer.dart` L1193–1567 | 树渲染 338 行混入 State（P0-2） | 独立辅助类/函数，纯输入→输出 | 无 | **低–中** | 对话框先提取（减少 State 噪声） | 树构建可单元测试 | **是** |

#### 主拆分对象 #3：EntryShellPage → SectionRegistry

| 拆分单元 | 当前位置 | 当前问题（引用 0255A） | 目标边界 | 接口变化 | 实施风险 | 依赖项 | 预期收益 | 本轮纳入 |
|---------|---------|----------------------|---------|---------|---------|--------|---------|---------|
| SectionRegistry | `entry_shell_page.dart` L7–15 | 6 处跨 feature import（P1-1） | `app/` 层 registry + builder 模式 | **有**：注册点从 import 改为 registry 回调 | **中** | NotesCoordinator 完成（notes 入口变化） | 消除 Rule E 最大违规源、新 feature 零改动 | **是** |

---

## 5. 边界定义细则

### 5.1 页面层边界（Page / Screen）

适用于：`NotesPage`, `TasksPage`, `CalendarPage`, `EntryShellPage` 等。

**负责：**
- 路由参数接收与解析
- 页面布局与子组件组装（三栏布局、侧边栏、内容区）
- 用户交互事件的委派（调用 coordinator 方法）
- 展示状态切换（loading / error / empty / success）
- 平台生命周期响应（如 `WindowListener` 的 `onWindowClose`）

**不负责：**
- 业务规则计算（如标签归一化、草稿版本比较）
- FFI 调用细节（不直接引用 invoker 或 `rust_api.*`）
- 跨域状态编排（如"创建笔记并自动应用筛选标签"）
- 数据缓存管理（不持有 `_noteCache`, `_draftContentByAtomId` 等 Map）

**主拆分对象验收标准（NotesController → Coordinator + Managers）：**
- 原 `notes_controller.dart` 拆分后删除，功能分布在 coordinator + 6 个 manager 中
- 每个 manager 文件 <500 行
- coordinator 文件 <300 行

**伴随受益验收标准（NotesPage / NoteContentArea）：**
- `NotesPage` 的 `_controller.xxx` 调用全部替换为 `_coordinator.xxx`（接口切换，非结构拆分）
- `NotesPage` 无直接 import `workspace_*` 文件
- NotesPage 和 NoteContentArea 本轮不设行数目标（它们不是主拆分对象）

### 5.2 状态层边界（Controller / Manager）

适用于：拆分后的 6 个 manager + 1 个 coordinator。

**每个 Manager 负责：**
- 单一职责域的状态数据持有与更新
- 该域的异步操作执行（通过注入的 invoker）
- 该域的错误处理与状态枚举管理
- 发出 `notifyListeners()` 仅限自身状态变更时

**每个 Manager 不负责：**
- 跨域状态协调（由 coordinator 编排）
- UI 展示逻辑（不访问 `BuildContext`）
- 直接读写其他 manager 的私有字段

**NotesCoordinator 负责：**
- 构造并持有所有 manager 实例
- 对外暴露统一 public API（Widget 层唯一访问点）
- 编排跨域操作（如 `createNote`：涉及列表 + Tab + 草稿 + 标签 + 工作区）
- 转发单域操作到对应 manager

**NotesCoordinator 不负责：**
- 持有大量状态字段（状态下沉到 manager）
- 复杂业务逻辑（逻辑在 manager 内）

**可测试性要求：**
- 每个 manager 可通过构造函数注入 mock invoker 进行单元测试
- Coordinator 可注入 mock manager 进行集成测试
- 测试不依赖 Widget 树或 `BuildContext`

### 5.3 服务层边界（Invoker / FFI Adapter）

适用于：当前 12 个 invoker typedef + `RustBridge`。

**当前状态（保持不变）：**
- FFI 调用通过 typedef 定义的 invoker 函数注入，已有良好的可测试性设计
- `RustBridge` 封装 FRB 初始化 + DB 路径 + 日志
- DTO 类型由 `core/bindings/api.dart`（自动生成）定义

**拆分后变化：**
- invoker 从 NotesController 构造函数下沉到对应 manager 构造函数
- 每个 manager 仅接收自己职责域的 invoker（如 `NoteListManager` 仅接收 `notesListInvoker` + `noteGetInvoker`）
- invoker 默认实现仍指向同一组 FFI 函数，测试时替换为 mock

**DTO 转换位置：**
- Rust FFI 返回的 `NoteItem`, `AtomListItem`, `WorkspaceNodeItem` 等 DTO 由 manager 直接使用
- 如果未来需要 ViewModel 转换，统一在 manager 内完成，不散落到 Widget 层
- 当前阶段不引入额外 ViewModel 层（避免过度设计）

### 5.4 共享组件边界（Shared Components）

**当前状态：** 项目无 `lib/shared/` 目录。跨 feature 共享通过直接 import 实现（违反 Rule E）。

**本轮策略：不建设 `lib/shared/`，通过消除跨 feature import 替代。**

理由：
- 跨 feature import 总计 16 处（0255A 附录 7.2），但其中属于"UI 组件复用"性质的仅 2 处：`notes_style.dart`（被 `tag_filter.dart` 引用）和 `search_results_view.dart`（被 `single_entry_panel.dart` 引用）。其余 14 处属于路由组装（entry→各 feature）或数据依赖（notes→workspace），由 SectionRegistry 和 WorkspacePort 方案各自覆盖
- 仅 2 处 UI 复用不足以证明引入 `lib/shared/` 抽象层的 ROI

**进入 shared 的门槛（后续评估用）：**
- 至少被 **2 个以上 feature** 稳定复用
- 不依赖具体业务模型或 controller
- 提供清晰的输入/输出（props），无业务副作用
- 经过至少 1 轮拆分稳定后，再评估是否提取

**当前 notes_style 的临时处理：**
- `tags/tag_filter.dart` → `notes/notes_style.dart` 的反向依赖暂时保留
- 标注为已知 Rule E 偏差（P2 风险，不阻塞本轮拆分）
- 后续如 tags 模块增长，再提取样式到 `lib/shared/styles/`

---

## 6. 优先级策略与排序结果

### 6.1 优先级判定维度

| 维度 | 定义 | 权重 |
|------|------|------|
| **体检风险等级** | 0255A P0/P1/P2 | 高 |
| **缝隙质量** | M1 职责域交叉分析（清洁/中等/多孔） | 高 |
| **实施可行性** | 是否能小步落地、依赖链是否短 | 高 |
| **拆分收益** | 拆完后可独立测试/通知精准化/冲突减少 | 中 |
| **依赖阻塞** | 是否卡住后续拆分单元 | 中 |
| **业务影响** | 核心链路 vs 辅助功能 | 低（本轮全在核心链路） |

### 6.2 排序结果

#### Phase A：清洁缝隙提取（低风险，无前置依赖）

| 顺序 | 拆分单元 | 原因 | 前置条件 | 策略 |
|------|---------|------|---------|------|
| A1 | WorkspacePort 接口定义 | D7 规则基础设施，后续 WorkspaceTreeManager 依赖 | 无 | 创建 `workspace_port.dart` <30 行 |
| A2 | WorkspaceTreeManager | 缝隙最清洁，自包含 CRUD，6 个 workspace invoker 完整迁移 | A1 | 整块提取 L708–1185 + L2699–2714 + L2735–2933（排除 L2716–2733 tag 归一化，归 NoteTagManager） |
| A3 | NoteSaveTracker | 缝隙清洁，纯状态枚举无 invoker | 无 | 整块提取 L436–465 + L2480–2531 |
| A4 | NoteDraftManager | 缝隙清洁，窄聚焦自保存 | A3（保存完成需更新 tracker） | 整块提取 L1885–1921 + L2348–2464 |

#### Phase B：中等缝隙提取（需协调回调）

| 顺序 | 拆分单元 | 原因 | 前置条件 | 策略 |
|------|---------|------|---------|------|
| B1 | NoteTagManager | 变更已队列化（中等缝隙），filter→list 回调需桥接 | 无（但 coordinator 需后续连接） | 提取标签 CRUD + filter 逻辑 |
| B2 | NoteTabManager | 切换需 flush 守卫（中等缝隙） | A3 + A4（依赖 DraftManager flush + SaveTracker 状态） | 整合现有 tab_manager widget + controller Tab 逻辑 |

#### Phase C：多孔域 + 编排层（最高风险）

| 顺序 | 拆分单元 | 原因 | 前置条件 | 策略 |
|------|---------|------|---------|------|
| C1 | NoteListManager | 与 Tab/草稿/筛选双向耦合（多孔），需所有下游 manager 就位 | B1 + B2 | 提取列表加载 + 详情缓存 |
| C2 | NotesCoordinator | 替换原 NotesController 的 facade 角色 | A1–A4 + B1–B2 + C1 全部完成 | 汇总所有 manager，实现 createNote 编排 |

#### Phase D：NoteExplorer 瘦化（可与 Phase A–C 并行）

| 顺序 | 拆分单元 | 原因 | 前置条件 | 策略 |
|------|---------|------|---------|------|
| D1 | 4 个对话框提取 | 无前置依赖，最低风险 | 无 | 每个对话框独立 PR |
| D2 | ExplorerTreeBuilder | 对话框提取后 State 噪声降低 | D1 | 提取树渲染逻辑 |

#### Phase E：EntryShellPage 解耦

| 顺序 | 拆分单元 | 原因 | 前置条件 | 策略 |
|------|---------|------|---------|------|
| E1 | SectionRegistry | Notes 入口变更后（coordinator 替换 controller）再统一处理注册 | C2（NotesCoordinator 完成） | 引入 registry + 迁移全部 section |

### 6.3 次优先级候选（本轮不拆，但评估纳入）

| 模块 | 原因 | 触发条件 |
|------|------|---------|
| NoteContentArea（P1） | NotesController 拆分后 controller 耦合点自然从 30+ 降为 coordinator API，mock 成本降低 | 若拆分后文件仍 >700 行，评估提取标签 UI 为独立 widget |
| NotesPage（P1） | `_controller.xxx` 切换为 `_coordinator.xxx` 后耦合度自然下降 | 若 v0.3 分屏增强使文件超过 1000 行，触发拆分 |
| WorkspaceProvider（P1） | 行为层双向同步在 WorkspaceTreeManager + WorkspacePort 提取后大幅简化 | 若新增第 2 个 consumer（非 notes），触发接口稳定化 |

---

## 7. 本轮不拆项与冻结策略

### 7.1 明确不拆清单

| 模块 | 0255A 等级 | 不拆原因 | 冻结规则 |
|------|-----------|---------|---------|
| SingleEntryController | P2 | 内部耦合清洁，不跨 feature，当前无交付阻塞 | 仅允许 bugfix + 新命令注册，禁止结构性改动 |
| WorkbenchShellLayout | P2 | 154 行，跨 feature import 仅 1 处，收益不足 | 不动 |
| SingleEntryPanel | P2 | 301 行，跨 feature import 仅 1 处 | 不动 |
| TagFilter | P2 | 243 行纯 UI 组件，D8 临时豁免已覆盖 | 不动；tags 模块超 500 行时重评估 |
| DebugLogsPanel | P2 | 578 行但职责单一，非核心流程 | 不动 |
| `lib/core/` 全部 | — | 工程基线干净（`flutter analyze` 零警告），RustBridge/Settings 结构合理 | 不动；仅允许 `TODO(v0.2)` 的按计划实现 |
| `lib/app/ui_slots/` | — | UI slot 系统已独立可测，不在本轮范围 | 不动 |

### 7.2 冻结规则

- **结构冻结**：不拆清单中的文件禁止结构性改动（提取类、拆分文件、改变继承关系）
- **功能允许**：可新增方法/字段（如新命令注册），但不改变现有 public API 签名
- **bugfix 允许**：修复 bug 不受限，但修复后不得追加"顺便重构"
- **重评估触发**：任何不拆模块的源码行数增长超过 50% 时，重新评估是否纳入下轮拆分

---

## 8. 风险与兼容性说明

### 8.1 拆分实施风险

| 风险 | 影响 | 概率 | 严重度 |
|------|------|------|--------|
| **R1：异步时序变化** | manager 拆分后 `notifyListeners()` 触发顺序可能改变，影响 UI 更新时序 | 中 | 高 |
| **R2：createNote 编排遗漏** | 高基数跨域操作迁移到 coordinator 时可能遗漏某个域的副作用 | 中 | 高 |
| **R3：测试 mock 断裂** | 现有 313 个测试中引用 `NotesController` 的用例需全部适配 `NotesCoordinator` | 高 | 中 |
| **R4：workspace 端口抽象不足** | `WorkspacePort` 接口可能需要多次迭代才能覆盖所有 WorkspaceTreeManager 需求 | 低 | 中 |
| **R5：并行冲突** | Phase A–C 与功能开发并行时，修改同一区域产生冲突 | 中 | 低 |

### 8.2 风险控制策略

| 策略 | 对应风险 | 说明 |
|------|---------|------|
| **S1：每个 PR 只提取一个 manager** | R1, R2 | 单一职责变更，便于 review 和 revert。每个 PR 必须不引入新的测试失败（基线：312 pass / 1 known-fail，见约束表） |
| **S2：先提取清洁缝隙** | R1, R2 | Phase A（工作区树、保存、草稿）风险最低，积累经验后再处理多孔域 |
| **S3：coordinator 最后落地** | R2, R3 | 所有 manager 就位后才创建 coordinator，避免中间态接口反复变动 |
| **S4：测试分两阶段迁移** | R3 | 阶段一：manager 提取期间 NotesController 保留 facade 转发（测试不变）；阶段二：coordinator 替换时批量迁移测试 |
| **S5：WorkspacePort 最小化设计** | R4 | 首版 port 仅声明 WorkspaceTreeManager 实际调用的方法签名（约 8–10 个），不预设未来需求 |
| **S6：重构 PR 不混入新功能** | R5 | 拆分期间功能开发单独分支，merge 后拆分 PR rebase |
| **S7：每个 Phase 完成后 checkpoint** | 全部 | Phase A/B/C/D/E 完成后各做一次 `flutter analyze`（须零警告）+ `flutter test`（须不引入新失败）+ 人工主流程走查 |

### 8.3 回退方案

- **单 PR 粒度**：每个拆分单元（manager/dialog/builder）是独立 PR，可单独 revert
- **facade 过渡期**：Phase A–B 期间 NotesController 保留为 facade，转发到新 manager。如果某个 manager 出问题，controller 回退到直接实现，零用户影响
- **coordinator 切换是唯一的 breaking point**：Phase C2 是全量切换点。该 PR 需要更严格的 review 和回归覆盖

---

## 9. 方案输出物清单

以下产物由本方案交付，直接作为 PR-0255C（分阶段重构计划）的输入：

| # | 产物 | 位置 | 状态 |
|---|------|------|------|
| 1 | **目标结构边界图（To-be）** | Section 3.2（3.2.1–3.2.4） | ✓ 含 ASCII 架构图 + 目录结构 |
| 2 | **拆分对象清单（带优先级）** | Section 4.1（13 个拆分单元） | ✓ 含接口变化、实施风险、依赖项 |
| 3 | **拆分执行顺序** | Section 6.2（Phase A→B→C→D→E） | ✓ 含依赖链和前置条件 |
| 4 | **依赖方向规则** | Section 3.3（D1–D8） | ✓ 含已废弃依赖清单 |
| 5 | **本轮不拆项清单** | Section 7.1 | ✓ 含冻结规则和重评估触发条件 |
| 6 | **风险控制策略清单** | Section 8.2（S1–S7） | ✓ 含回退方案 |
| 7 | **WorkspacePort 接口规格** | Section 3.2.4 + D7 规则 | ✓ 抽象端口 + app 层适配模式 |

---

> **注意：** 本方案基于 PR-0255A 体检报告输出，解决"怎么拆、先拆哪里、为什么这么拆"。不展开具体排期与任务（排期在 PR-0255C）。
