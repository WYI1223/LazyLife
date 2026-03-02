# PR-RB-05: S9 core-workspace 抽取

- Proposed title: `refactor(frontend): PR-RB-05 extract workspace tree and layout to lib/core/workspace/`
- Status: **Ready for Implementation**
- Branch: `feat/pr-rb-05-s9-core-workspace`

## Goal

按 S9 ruling 将 workspace 相关模块从 `features/notes/managers/` 和 `features/workspace/` 迁移到 `lib/core/workspace/`，建立组织结构基础设施的独立模块。具体目标：

1. **Rule E 合规**：消除 `notes → workspace` 跨 feature 依赖（S9 规则 1）
2. **多消费者就绪**：workspace tree 将被 Notes、Tasks、Calendar 消费（S9 裁决实例表）；提前归入 `core/` 避免后续 Rule E 违规
3. **承前**：落实 S9 裁决 + DI-1 Q4.3 的具体决策，完成 v0.3 Gate A 语义契约闭合的最后一环
4. **启后**：为 PR-RB-06（core/editor 提取）提供 pane layout 文件的过渡位置；为 DI-12（v0.4 单根树）和 DI-14（v0.4 workspace tree 提升）预留扩展空间

`WorkspaceTreeManager` 重命名为 `WorkspaceTreeService`，反映其从 feature-internal manager 到 core infrastructure service 的语义升级。

前置条件：PR-RB-03（`atom_ref` 升级完成，workspace 模型稳定）

---

## Execution Contract (Canonical Inputs)

### 第一信息来源（Rulings + Modules）

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| **Ruling** | [`S9-cross-feature-infrastructure-placement.md`](../../../architecture/rulings/S9-cross-feature-infrastructure-placement.md) | 定义 `core/workspace/` 目标结构；规则 1（被 2+ feature 消费 → core/）、裁决实例表（WorkspaceTreeService 条目） |
| **Module Spec** | [`core-workspace/workspace-tree-service.md`](../../../architecture/modules/core-workspace/workspace-tree-service.md) | 定义职责范围、提取范围、语义依据（S1 R5/R6、S3、DI-12）、约束条件 |
| **Ruling** | Rule E ([`engineering-standards.md`](../../../architecture/engineering-standards.md)) | 跨 feature import 禁止规则，本 PR 消除 `notes → workspace` 违规 |

### 细节补充来源（08b + DI 讨论）

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| **DI-1** | [`DI-1-editor-shell-service.md`](../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) Q4.3, Q5 | workspace tree 作为 core 基础设施的定位裁决；Q4.3 确认 WorkspaceTreeManager 独立提取；Q5 确认 `lib/core/` 放置 |
| **08b** | [`08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md) S3 | Tag × Workspace 正交性确认 workspace tree 是独立维度，不从属于 notes feature |
| **DI-6** | [`DI-6-cross-track-dependencies.md`](../../reports/v0.3/design-discussions/DI-6-cross-track-dependencies.md) | PR 重排依据：Stage 1（语义/契约 RB-00~RB-05）→ Stage 2（编辑器基础设施 RB-06~RB-09） |
| **Rebaseline** | [`v0.3-pr-spec-rebaseline-2026-03-01.md`](../v0.3-pr-spec-rebaseline-2026-03-01.md) §4 PR-RB-05 | Scope + 依赖确认；§5 Gate A 边界（PR-RB-05 后闭合） |
| **Acceptance Report** | [`09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md) §7.1 | `coordinator_impl` 1,514 行减重背景 |

### 前向参照（v0.4 + 后续 PR）

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| **DI-12** | [`DI-12-workspace-tree-single-root.md`](../../reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md) | v0.4 单根树 + 系统节点；本 PR 建立的 core/workspace/ 是 DI-12 E1 执行位置 |
| **DI-14** | [`DI-14-workspace-tree-core-promotion.md`](../../reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md) | v0.4 workspace tree 提升为 core first-class citizen；本 PR 的 CRUD 层迁移是 DI-14 Q0 Option B 的先决条件 |
| **PR-RB-06** | [`PR-RB-06-core-editor-foundation.md`](PR-RB-06-core-editor-foundation.md) T15, Out-of-scope | PR-RB-06 预期 `workspace_provider.dart` 已在 `core/workspace/`，T15 从该位置提取 layout 逻辑到 `core/editor/group_layout.dart` |

---

## 当前文件分布

### A. Workspace Tree 文件（`features/notes/managers/`，4 文件）

| 文件 | 行数 | 内容 | 迁移性质 |
|------|------|------|---------|
| `workspace_tree_manager.dart` | 529 | `WorkspaceTreeManager extends ChangeNotifier` — tree CRUD、状态跟踪（`_workspaceTreeRevision`）、FFI 调用委托、DartEventLogger 日志 | **move + rename** |
| `workspace_tree_types.dart` | 55 | 12 个 typedef（injectable FFI invokers: Delete/Create/Rename/Move/ListChildren + hooks: Prepare/CreateNote/FlushSave/DeleteSuccess/NoteById/ListItems + result record） | move |
| `workspace_tree_children_loader.dart` | 380 | 子节点加载 + `__uncategorized__` 伪文件夹投影 + 三级 fallback（real API → synthetic projection → hardcoded tree） | move |
| `workspace_tree_error_utils.dart` | 34 | 错误格式化工具（`workspaceActionErrorMessage`），`db_busy`/`db_error` 特殊处理 | move |

### B. Pane Layout 文件（`features/workspace/`，2 文件）`[TRANSIENT]`

| 文件 | 行数 | 内容 | 迁移性质 |
|------|------|------|---------|
| `workspace_provider.dart` | 167 | `WorkspaceProvider extends ChangeNotifier` — pane split/merge/activate，最多 4 pane，最小 200px | move + TRANSIENT 标记 |
| `workspace_models.dart` | 67 | `WorkspaceLayoutState`（不可变快照）、`WorkspaceSplitDirection`、split/merge result 枚举 | move + TRANSIENT 标记 |

> **TRANSIENT 说明**：pane layout 文件按 DI-1 Q5 + S2 Phase 2 的最终归宿是 `lib/core/editor/group_layout.dart`（PR-RB-06 执行转换）。本 PR 将其移至 `core/workspace/` 作为过渡位置，目的是一次性清空 `features/workspace/` 目录并消除 Rule E exemption。PR-RB-06 T15 明确以 `core/workspace/workspace_provider.dart` 为输入源。

---

## 完整消费者审计 `[NEW]`

### Import 图谱

#### `features/workspace/` 的直接消费者

| 消费者文件 | import 行 | 导入内容 |
|-----------|----------|---------|
| `lib/features/notes/notes_coordinator.dart` | L14-15 | `workspace_models.dart` + `workspace_provider.dart` |
| `lib/features/notes/notes_page.dart` | L15-16 | `workspace_models.dart` + `workspace_provider.dart` |
| `test/workspace_provider_test.dart` | L2-3 | `workspace_models.dart` + `workspace_provider.dart` |
| `test/workspace_split_v1_test.dart` | L7 | `workspace_provider.dart` |
| `test/workspace_integration_flow_test.dart` | L6 | `workspace_models.dart` |

#### `workspace_tree_manager` 的直接消费者

| 消费者文件 | import 行 | 导入内容 |
|-----------|----------|---------|
| `lib/features/notes/notes_coordinator.dart` | L12 | `workspace_tree_manager.dart`（import + re-export） |
| `lib/features/notes/notes_coordinator_impl.dart` | — | 隐式可用（`part of 'notes_coordinator.dart'`） |

#### 内部依赖（workspace_tree_manager.dart 内部）

```
workspace_tree_manager.dart
  ├── import workspace_tree_children_loader.dart  (L4)
  ├── import workspace_tree_error_utils.dart      (L5)
  ├── import workspace_tree_types.dart            (L6)
  └── export workspace_tree_types.dart            (L7, re-export all types)
```

### Re-export 链

当前链路：
```
notes_coordinator.dart
  └── export 'managers/workspace_tree_manager.dart'
        show WorkspaceCreateFolderInvoker,
             WorkspaceDeleteFolderInvoker,
             WorkspaceListChildrenInvoker,
             WorkspaceMoveNodeInvoker,
             WorkspaceRenameNodeInvoker,
             WorkspaceTreeManager
```

其中 5 个 Invoker typedef 定义在 `workspace_tree_types.dart`，由 `workspace_tree_manager.dart` 的 `export` 语句传递到 coordinator。

迁移后链路：
```
notes_coordinator.dart
  └── export 'package:lazynote_flutter/core/workspace/workspace_tree_service.dart'
        show WorkspaceCreateFolderInvoker,
             WorkspaceDeleteFolderInvoker,
             WorkspaceListChildrenInvoker,
             WorkspaceMoveNodeInvoker,
             WorkspaceRenameNodeInvoker,
             WorkspaceTreeService         ← 类名变更
```

### 测试文件清单

| 测试文件 | 导入的 workspace 路径 | 需更新 |
|---------|---------------------|--------|
| `workspace_provider_test.dart` | `features/workspace/workspace_models.dart` + `workspace_provider.dart` | YES |
| `workspace_split_v1_test.dart` | `features/workspace/workspace_provider.dart` | YES |
| `workspace_integration_flow_test.dart` | `features/workspace/workspace_models.dart` | YES |
| `workspace_contract_smoke_test.dart` | workspace 相关导入 | YES |
| `cross_lane_workspace_extension_smoke_test.dart` | workspace 相关导入 | YES |
| `note_explorer_workspace_delete_test.dart` | workspace 相关导入 | YES |
| `notes_controller_workspace_tree_guards_test.dart` | workspace 相关导入 | YES |

> 执行时使用 `rg "features/workspace\|managers/workspace_tree" test/ --type dart` 扫描确认完整列表。

---

## 迁移方案

### 目标结构

```
lib/core/workspace/
├── workspace_tree_service.dart          ← managers/workspace_tree_manager.dart (move + rename)
├── workspace_tree_types.dart            ← managers/workspace_tree_types.dart (move)
├── workspace_tree_children_loader.dart  ← managers/workspace_tree_children_loader.dart (move)
├── workspace_tree_error_utils.dart      ← managers/workspace_tree_error_utils.dart (move)
├── workspace_provider.dart              ← features/workspace/workspace_provider.dart (move) [TRANSIENT]
└── workspace_models.dart                ← features/workspace/workspace_models.dart (move) [TRANSIENT]
```

迁移后：
- `features/workspace/` 目录**删除**
- `features/notes/managers/` 中 4 个 workspace 文件**删除**
- Rule E allowlist `notes → workspace` 条目**移除**

### 文件分类 `[NEW]`

| 分类 | 文件 | 生命周期 | 后续归宿 |
|------|------|---------|---------|
| **Core Tree**（永久） | `workspace_tree_service.dart`, `_types.dart`, `_children_loader.dart`, `_error_utils.dart` | 永久驻留 `core/workspace/` | DI-12 扩展系统节点方法；DI-14 添加状态管理 |
| **Transient Layout**（过渡） | `workspace_provider.dart`, `workspace_models.dart` | PR-RB-06 吸收到 `core/editor/` | PR-RB-06 T15：layout 逻辑 → `group_layout.dart` |

### Notes-specific 回调保持不变

`WorkspaceTreeService`（原 Manager）的构造函数接受 12 个 injectable callbacks（定义在 `workspace_tree_types.dart`）：

| 类别 | typedef | 说明 |
|------|---------|------|
| FFI Invokers | `WorkspaceDeleteFolderInvoker`, `CreateFolderInvoker`, `RenameNodeInvoker`, `MoveNodeInvoker`, `ListChildrenInvoker` | 异步 FFI 调用封装 |
| Lifecycle Hooks | `WorkspacePrepare`, `FlushPendingSave`, `DeleteSuccessHook` | 操作前后钩子 |
| Note Integration | `CreateNoteAndGetAtomId`, `NoteById`, `ListItemsReader` | notes feature 注入的回调 |
| Type | `WorkspaceCreateNoteResult` | `(atomId, errorCode, errorMessage)` record |

这些回调由 `NotesCoordinator` 注入，是 coordinator 层的编排逻辑，不是 workspace 的内部依赖。DI-1 Q4.3 确认保持此 injectable 模式，不做接口重构。

### Import 路径变更明细 `[NEW]`

#### `notes_coordinator.dart`

```dart
// BEFORE
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_manager.dart';
import 'package:lazynote_flutter/features/workspace/workspace_models.dart';
import 'package:lazynote_flutter/features/workspace/workspace_provider.dart';

export 'managers/workspace_tree_manager.dart'
    show WorkspaceCreateFolderInvoker, ..., WorkspaceTreeManager;

// AFTER
import 'package:lazynote_flutter/core/workspace/workspace_tree_service.dart';
import 'package:lazynote_flutter/core/workspace/workspace_models.dart';
import 'package:lazynote_flutter/core/workspace/workspace_provider.dart';

export 'package:lazynote_flutter/core/workspace/workspace_tree_service.dart'
    show WorkspaceCreateFolderInvoker, ..., WorkspaceTreeService;
```

#### `notes_coordinator_impl.dart`（part file）

```dart
// BEFORE
late final WorkspaceTreeManager _workspaceTreeManager;
_workspaceTreeManager = WorkspaceTreeManager(...);
_workspaceTreeManager.addListener(_handleWorkspaceTreeManagerChanged);

// AFTER
late final WorkspaceTreeService _workspaceTreeService;
_workspaceTreeService = WorkspaceTreeService(...);
_workspaceTreeService.addListener(_handleWorkspaceTreeServiceChanged);
```

> 所有 `_workspaceTreeManager` 引用全局替换为 `_workspaceTreeService`。
> 所有 `WorkspaceTreeManager` 类型引用全局替换为 `WorkspaceTreeService`。
> handler 方法名 `_handleWorkspaceTreeManagerChanged` → `_handleWorkspaceTreeServiceChanged`。

#### `notes_page.dart`

```dart
// BEFORE
import 'package:lazynote_flutter/features/workspace/workspace_models.dart';
import 'package:lazynote_flutter/features/workspace/workspace_provider.dart';

// AFTER
import 'package:lazynote_flutter/core/workspace/workspace_models.dart';
import 'package:lazynote_flutter/core/workspace/workspace_provider.dart';
```

#### `core/workspace/` 内部文件互引

```dart
// workspace_tree_service.dart BEFORE (as workspace_tree_manager.dart)
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_children_loader.dart';
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_error_utils.dart';
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_types.dart';
export 'workspace_tree_types.dart';

// workspace_tree_service.dart AFTER
import 'package:lazynote_flutter/core/workspace/workspace_tree_children_loader.dart';
import 'package:lazynote_flutter/core/workspace/workspace_tree_error_utils.dart';
import 'package:lazynote_flutter/core/workspace/workspace_tree_types.dart';
export 'workspace_tree_types.dart';
```

### DartEventLogger Module 字符串更新

```dart
// BEFORE
DartEventLogger.log(module: 'notes.workspace_tree_manager', ...);

// AFTER
DartEventLogger.log(module: 'core.workspace_tree_service', ...);
```

### Transient 文件头注释 `[NEW]`

`workspace_provider.dart` 和 `workspace_models.dart` 移入后添加文件头注释：

```dart
// TRANSIENT: This file is temporarily in lib/core/workspace/.
// PR-RB-06 will absorb its layout logic into lib/core/editor/group_layout.dart.
// See: DI-1 Q5, S2 Phase 2, PR-RB-06 T15.
```

---

## Scope

### In scope

- 移动 6 个文件到 `lib/core/workspace/`（4 永久 + 2 TRANSIENT）
- `WorkspaceTreeManager` → `WorkspaceTreeService` 重命名（类名 + 文件名 + 所有消费者引用）
- `_workspaceTreeManager` → `_workspaceTreeService` 私有字段重命名（coordinator_impl）
- `_handleWorkspaceTreeManagerChanged` → `_handleWorkspaceTreeServiceChanged` handler 重命名
- 更新全部消费者导入路径（lib/ + test/）
- `notes_coordinator.dart` re-export 路径 + show 类名更新
- DartEventLogger module 字符串更新
- TRANSIENT 文件头注释添加
- 删除空的 `features/workspace/` 目录
- 删除 `features/notes/managers/` 中的 4 个 workspace 文件
- `rule_e_allowlist.yaml` 移除 `notes → workspace` 条目
- 文档更新：`CLAUDE.md`、`overview.md`、S9 ruling、module spec

### Out of scope

- `WorkspaceTreeService` 内部逻辑变更（仅移动 + 重命名，不改行为）
- `WorkspaceProvider` / `WorkspaceLayoutState` 逻辑变更（仅移动 + TRANSIENT 标记）
- Notes-specific callback 接口重构（保持 injectable 模式，DI-1 Q4.3 确认）
- Workspace tree 数据模型变更（DI-12 scope：单根树 + 系统节点）
- Workspace tree 状态管理提升（DI-14 scope：ExplorerTreeState 等）
- `core/editor/` 创建或 GroupLayout 实现（PR-RB-06 scope）
- Rust Core / FFI 层变更（不涉及）

---

## Task Breakdown

### Phase 1: 创建目录 + 移动文件

| Task | 内容 | 变更 | 依赖 |
|------|------|------|------|
| T1 | 创建 `lib/core/workspace/` 目录 | 新目录 | — |
| T2 | 移动 `workspace_models.dart` → `core/workspace/` + 添加 TRANSIENT 文件头注释 | move + edit | T1 |
| T3 | 移动 `workspace_provider.dart` → `core/workspace/` + 添加 TRANSIENT 文件头注释 | move + edit | T1 |
| T4 | 移动 `workspace_tree_manager.dart` → `core/workspace/workspace_tree_service.dart` | move + rename file | T1 |
| T5 | 移动 `workspace_tree_types.dart` → `core/workspace/` | move | T1 |
| T6 | 移动 `workspace_tree_children_loader.dart` → `core/workspace/` | move | T1 |
| T7 | 移动 `workspace_tree_error_utils.dart` → `core/workspace/` | move | T1 |

### Phase 2: 内部引用 + 重命名

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T8 | `core/workspace/*.dart` 文件之间的相互引用更新（`features/notes/managers/` → `core/workspace/`） | 4 tree files | 编辑 import 路径 | T4~T7 |
| T9 | `WorkspaceTreeManager` → `WorkspaceTreeService` 类名全局替换 | `workspace_tree_service.dart` | 编辑 class name + all references | T4 |
| T10 | DartEventLogger module 字符串：`'notes.workspace_tree_manager'` → `'core.workspace_tree_service'` | `workspace_tree_service.dart` | 编辑 string literal | T4 |

### Phase 3: 消费者导入更新

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T11 | `notes_coordinator.dart`：import 路径（3 处）+ export 路径 + show 类名（`WorkspaceTreeManager` → `WorkspaceTreeService`） | `notes_coordinator.dart` | 编辑 L12, L14, L15, L22-29 | T8, T9 |
| T12 | `notes_coordinator_impl.dart`：字段类型 + 变量名 + handler 名全局替换 | `notes_coordinator_impl.dart` | 全局替换 `WorkspaceTreeManager` → `WorkspaceTreeService`、`_workspaceTreeManager` → `_workspaceTreeService`、handler 名 | T9 |
| T13 | `notes_page.dart`：import 路径更新（2 处） | `notes_page.dart` | 编辑 L15-16 | T8 |
| T14 | 其他 lib/ 文件中 `features/workspace/` 或 `managers/workspace_tree` 引用扫描并更新 | `rg` 扫描结果 | 编辑 | T8 |

### Phase 4: 测试 + 清理

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T15 | 7 个测试文件 import 路径 + 类名更新（使用 `rg "features/workspace\|managers/workspace_tree\|WorkspaceTreeManager" test/ --type dart` 确认完整列表） | `test/*.dart` | 编辑 | T8, T9 |
| T16 | 删除空 `lib/features/workspace/` 目录 | 目录删除 | — | T2, T3 |
| T17 | 确认 `features/notes/managers/` 中 4 个 workspace 文件已移走（由 T4-T7 move 操作完成） | 验证 | — | T4~T7 |
| T18 | `rule_e_allowlist.yaml`：移除 `notes → workspace` 条目 | `tools/ci/rule_e_allowlist.yaml` | 编辑 | T16 |

### Phase 5: 文档

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T19 | 更新 `CLAUDE.md` 路径表：`features/workspace/` → `core/workspace/`；`WorkspaceTreeManager` → `WorkspaceTreeService`；添加 `core/workspace/` 条目 | `CLAUDE.md` | 编辑 | T16 |
| T20 | 更新 `overview.md`：§Runtime flow 中 WorkspaceTreeManager → WorkspaceTreeService；§Module map 中路径更新；§v0.3 infrastructure 标注已完成 | `docs/architecture/overview.md` | 编辑 | T16 |
| T21 | S9 ruling 实施状态表：`WorkspaceTreeService → core/workspace/` 标注 **已完成** | `docs/architecture/rulings/S9-cross-feature-infrastructure-placement.md` | 编辑 | T16 |
| T22 | Module spec：标注 PR-RB-05 执行状态；更新目标文件结构为 6 文件（含 TRANSIENT 标记） | `docs/architecture/modules/core-workspace/workspace-tree-service.md` | 编辑 | T16 |

### Critical Path

```
T1 → T2~T7 (并行移动) → T8/T9/T10 → T11~T14 (并行) → T15 → T16/T17 → T18~T22 (并行)
```

---

## Planned File Changes

### 移动（6 files）

| 操作 | 来源 | 目标 | 附加 |
|------|------|------|------|
| `[move]` | `lib/features/workspace/workspace_models.dart` | `lib/core/workspace/workspace_models.dart` | + TRANSIENT 注释 |
| `[move]` | `lib/features/workspace/workspace_provider.dart` | `lib/core/workspace/workspace_provider.dart` | + TRANSIENT 注释 |
| `[move+rename]` | `lib/features/notes/managers/workspace_tree_manager.dart` | `lib/core/workspace/workspace_tree_service.dart` | + class rename |
| `[move]` | `lib/features/notes/managers/workspace_tree_types.dart` | `lib/core/workspace/workspace_tree_types.dart` | — |
| `[move]` | `lib/features/notes/managers/workspace_tree_children_loader.dart` | `lib/core/workspace/workspace_tree_children_loader.dart` | — |
| `[move]` | `lib/features/notes/managers/workspace_tree_error_utils.dart` | `lib/core/workspace/workspace_tree_error_utils.dart` | — |

### 编辑（消费者 — 精确清单）

| 操作 | 文件 | 变更内容 |
|------|------|---------|
| `[edit]` | `lib/features/notes/notes_coordinator.dart` | 3 import + 1 export path + show clause class name |
| `[edit]` | `lib/features/notes/notes_coordinator_impl.dart` | field type/name/handler 全局替换 |
| `[edit]` | `lib/features/notes/notes_page.dart` | 2 import path |
| `[edit]` | T14 扫描出的其他 lib/ 文件 | import path |

### 删除

| 操作 | 目标 |
|------|------|
| `[delete-dir]` | `lib/features/workspace/` |

### CI / Docs

| 操作 | 文件 | 变更内容 |
|------|------|---------|
| `[edit]` | `tools/ci/rule_e_allowlist.yaml` | 移除 `notes → workspace` 条目 |
| `[edit]` | `CLAUDE.md` | 路径表 + 控制器表更新 |
| `[edit]` | `docs/architecture/overview.md` | 路径引用 + 模块描述更新 |
| `[edit]` | `docs/architecture/rulings/S9-cross-feature-infrastructure-placement.md` | 实施状态 |
| `[edit]` | `docs/architecture/modules/core-workspace/workspace-tree-service.md` | 执行状态 + 文件结构 |

---

## Forward Compatibility（承前启后） `[NEW]`

### 承前：v0.3 Gate A 闭合

PR-RB-05 是 Gate A（语义与契约）的最后一个 PR（Rebaseline §5）。完成后：
- S8（DTO 统一）、S1（核心字段）、S4（atom_ref 统一）、S7（提醒生命周期）、S9（模块归属）全部闭合
- `notes → workspace` Rule E exemption 消除，features 模块边界完全合规
- workspace tree CRUD 层归入 core/，为多消费者做好准备

### 启后：PR-RB-06 衔接

| 衔接点 | PR-RB-05 产出 | PR-RB-06 消费方式 |
|--------|-------------|-----------------|
| `core/workspace/workspace_provider.dart` | TRANSIENT 驻留 | T15：提取 layout 逻辑 → `core/editor/group_layout.dart` |
| `core/workspace/workspace_models.dart` | TRANSIENT 驻留 | `WorkspaceLayoutState` 被 `GroupLayout` sealed class 替代 |
| `core/workspace/workspace_tree_service.dart` | 永久驻留 | NotesCoordinator 持续消费；未来 TasksController / CalendarController 消费 |

PR-RB-06 完成后，`core/workspace/` 仅保留 4 个 tree 文件，pane layout 完全吸收进 `core/editor/`。

### 启后：DI-12（v0.4 单根树 + 系统节点）

| DI-12 执行项 | core/workspace/ 就绪状态 |
|-------------|------------------------|
| E1：单根树 + 系统节点实现 | `workspace_tree_service.dart` 是扩展入口；添加 `ensure_system_folders()`、系统节点保护等方法 |
| E2：FFI 兼容收敛 | 不影响 Flutter 层 `core/workspace/` 结构 |
| E3：Explorer/Tasks/Calendar 统一 | `workspace_tree_children_loader.dart` 的 subtree 投影逻辑是天然基础 |

### 启后：DI-14（v0.4 workspace tree 提升为 core first-class citizen）

| DI-14 设计问题 | core/workspace/ 就绪状态 |
|--------------|------------------------|
| Q0（core 定位） | CRUD 层已在 core/；如选 Option B，状态管理文件直接加入同目录 |
| Q1（core 能力） | injectable 模式天然支持 parameterized subtree root |
| Q2（subtree 查询） | `workspace_tree_children_loader.dart` 已有 BFS tree walk + subtree projection |
| Q3（变更通知） | `WorkspaceTreeService` 已是 `ChangeNotifier`，可扩展为 scoped notification |

> **不做提前实现**：DI-14 的 5 个设计问题尚未收敛（Q0 gate 问题 open）。本 PR 仅确保目录和模式就绪，不引入 v0.4 功能。

---

## Verification

### CI gates（必须全部通过并记录输出）

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# 1. features/workspace/ 目录不存在
test ! -d apps/lazynote_flutter/lib/features/workspace
echo "PASS: features/workspace/ deleted"

# 2. features/notes/managers/ 中无 workspace 文件
ls apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_* 2>/dev/null
# Expected: ls error (no match)

# 3. core/workspace/ 目录存在且包含 6 文件
ls apps/lazynote_flutter/lib/core/workspace/*.dart | wc -l
# Expected: 6

# 4. 无 features/workspace import 残留（lib/ + test/）
rg "features/workspace" apps/lazynote_flutter/lib/ apps/lazynote_flutter/test/ --type dart
# Expected: zero matches

# 5. 无 managers/workspace_tree import 残留（lib/ + test/）
rg "managers/workspace_tree" apps/lazynote_flutter/lib/ apps/lazynote_flutter/test/ --type dart
# Expected: zero matches

# 6. WorkspaceTreeManager 类名归零（lib/ + test/）
rg "WorkspaceTreeManager" apps/lazynote_flutter/lib/ apps/lazynote_flutter/test/ --type dart
# Expected: zero matches

# 7. _workspaceTreeManager 变量名归零
rg "_workspaceTreeManager" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# 8. Rule E allowlist 不再包含 notes → workspace
rg "notes.*workspace" tools/ci/rule_e_allowlist.yaml
# Expected: zero matches

# 9. TRANSIENT 注释存在于 pane layout 文件
rg "TRANSIENT" apps/lazynote_flutter/lib/core/workspace/workspace_provider.dart
rg "TRANSIENT" apps/lazynote_flutter/lib/core/workspace/workspace_models.dart
# Expected: one match each

# 10. DartEventLogger module 字符串已更新
rg "notes\.workspace_tree_manager" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches
rg "core\.workspace_tree_service" apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart
# Expected: at least one match

# 11. architecture_check 通过
cd apps/lazynote_flutter && dart run ../../tools/ci/architecture_check.dart
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Import 路径遗漏 | MEDIUM | `flutter analyze` 编译错误自动暴露；`rg "features/workspace"` + `rg "managers/workspace_tree"` 双重扫描 |
| Re-export 链断裂导致外部 API 变化 | LOW | notes_coordinator.dart export 更新为新路径 + 新类名；链路完整性由 `flutter analyze` 保证 |
| 测试 import 遗漏 | LOW | `flutter test` 编译失败暴露；T15 使用 `rg` 扫描确认 |
| Pane layout TRANSIENT 语义混淆 | LOW | TRANSIENT 注释明确指向 PR-RB-06；module spec 文档化过渡状态 |
| architecture_check 误判（features/workspace/ 删除后 Rule E 检测路径变化） | LOW | 移除 allowlist 条目后显式运行 architecture_check 验证 |
| 变量名替换不完整（_workspaceTreeManager 遗留） | LOW | `rg "_workspaceTreeManager"` 扫描 + `flutter analyze` 类型检查 |

---

## Test Baseline

Entry: PR-RB-03 exit count（或 PR-RB-04 exit count，取决于执行顺序）
Exit: **= 入口 count**（纯移动 + 重命名，无测试删减或新增）

---

## Acceptance Criteria

- [ ] `lib/core/workspace/` 包含 6 个 `.dart` 文件
- [ ] `lib/features/workspace/` 目录已删除
- [ ] `features/notes/managers/` 中无 `workspace_tree_*` 文件
- [ ] `WorkspaceTreeManager` 类名已全局替换为 `WorkspaceTreeService`（lib/ + test/ 零匹配）
- [ ] `_workspaceTreeManager` 变量名已全局替换为 `_workspaceTreeService`
- [ ] `workspace_provider.dart` 和 `workspace_models.dart` 包含 TRANSIENT 文件头注释
- [ ] `rule_e_allowlist.yaml` 不含 `notes → workspace` 条目
- [ ] DartEventLogger module 字符串更新为 `'core.workspace_tree_service'`
- [ ] Re-export 链完整：`notes_coordinator.dart` 从 `core/workspace/workspace_tree_service.dart` 导出 `WorkspaceTreeService` + 5 个 Invoker typedef
- [ ] §Verification CI gates 全部通过（逐项执行并记录输出）
- [ ] §Verification Structural verification 11 项检查全部通过
- [ ] S9 ruling 实施状态标注为 **已完成**
- [ ] Module spec 更新标注 PR-RB-05 执行状态

---

## Appendix: S3 正交性语义背景 `[NEW]`

本 PR 的模块提取进一步固化了 S3 裁决（08b）的正交性原则：

| 维度 | Tag | Explorer（Workspace Tree） |
|------|-----|--------------------------|
| 本质 | 语义分类（查询驱动） | 结构归档（用户组织） |
| 数据源 | `atom_tags` 表 | `workspace_nodes` 表 |
| 操作 | 过滤、排序 | 拖拽、移动、嵌套 |
| Flutter 归属 | `NoteTagManager`（features/notes/） | `WorkspaceTreeService`（**core/workspace/**） |

两个维度的代码位置现在完全独立：Tag 管理保留在 notes feature 内部（仅 notes 消费），Workspace tree 提升到 core/（多 feature 消费）。PR-RB-10（S3 Phase A）将在此基础上实现 tag 结果面板 + atom_ref 面包屑路径。

---

## Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| Draft | — | 初始草稿 |
| **v1.0** | **2026-03-02** | **升级为可执行版本**：添加完整消费者审计、re-export 链分析、import 路径变更明细、TRANSIENT 标记方案、Forward Compatibility 承前启后分析（DI-12/DI-14/PR-RB-06）、S3 正交性语义背景、精确 Structural Verification（11 项检查）、Changelog |
