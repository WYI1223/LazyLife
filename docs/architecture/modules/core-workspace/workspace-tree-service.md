# Module Spec: WorkspaceTreeService

> `lib/core/workspace/workspace_tree_service.dart`
>
> 设计来源：[DI-1 Q4.3](../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) · [S9](../../rulings/S9-cross-feature-infrastructure-placement.md) · [S1 R5/R6](../../rulings/S1-atom-projection.md) · [DI-12](../../../reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md)

---

## 职责

组织结构基础设施：workspace tree CRUD 的 FFI 封装。从 `features/notes/managers/workspace_tree_manager.dart` 提取到 `lib/core/workspace/`，因为 workspace tree 将被 Notes、Tasks、Calendar 等多个 feature 消费（S9 规则 1：被 2+ feature 消费的模块归入 `core/`）。

---

## 目标文件结构

> **PR-RB-05 变更**：实际迁移 6 个文件（原 spec 列 2 个为简化描述）。4 个 tree 文件永久驻留，2 个 pane layout 文件为 TRANSIENT 过渡。

```
lib/core/workspace/
├── workspace_tree_service.dart          ← features/notes/managers/workspace_tree_manager.dart (move + rename)
├── workspace_tree_types.dart            ← features/notes/managers/ (move) — 12 个 injectable typedef
├── workspace_tree_children_loader.dart  ← features/notes/managers/ (move) — 子节点加载 + uncategorized 投影
├── workspace_tree_error_utils.dart      ← features/notes/managers/ (move) — 错误格式化工具
├── workspace_provider.dart              ← features/workspace/ (move) [TRANSIENT → core/editor/ in PR-RB-06]
└── workspace_models.dart                ← features/workspace/ (move) [TRANSIENT → core/editor/ in PR-RB-06]
```

**文件分类**：

| 分类 | 文件 | 生命周期 |
|------|------|---------|
| Core Tree（永久） | `workspace_tree_service.dart`, `_types.dart`, `_children_loader.dart`, `_error_utils.dart` | 永久驻留；DI-12 扩展，DI-14 添加状态管理 |
| Transient Layout（过渡） | `workspace_provider.dart`, `workspace_models.dart` | PR-RB-06 T15 吸收到 `core/editor/group_layout.dart` |

---

## 提取范围

> **PR-RB-05 变更**：扩展提取范围至完整支撑文件，确保模块自包含。

| 从 | 提取内容 | 说明 |
|---|---|---|
| `WorkspaceTreeManager` | tree CRUD FFI 调用（create folder, create ref, list children, move, delete）+ 状态跟踪（revision counter）+ DartEventLogger 日志 | 核心操作；重命名为 `WorkspaceTreeService` |
| `workspace_tree_types.dart` | 12 个 typedef（5 FFI invokers + 3 lifecycle hooks + 3 note integration callbacks + 1 result record） | injectable 依赖类型 |
| `workspace_tree_children_loader.dart` | 子节点加载 + `__uncategorized__` 伪文件夹投影 + 三级 fallback | WorkspaceTreeService 内部依赖 |
| `workspace_tree_error_utils.dart` | 错误格式化工具（`db_busy`/`db_error` 特殊处理） | WorkspaceTreeService 内部依赖 |
| `WorkspaceProvider` | pane split/merge layout 管理 | **TRANSIENT**：一次性清空 features/workspace/ |
| `WorkspaceModels` | `WorkspaceLayoutState`、split/merge 类型 | **TRANSIENT**：同上 |

NotesCoordinator 中与 workspace tree 相关的协调逻辑（如 "在指定文件夹创建 note"）保留在 Coordinator 层，调用 `WorkspaceTreeService` 方法。injectable callback 模式不变（DI-1 Q4.3 确认）。

---

## 语义依据

- **S1 R5**：atom_ref 强制伴随 — 所有 Atom 创建走统一路径，WorkspaceTreeService 作为 atom_ref 创建的基础设施
- **S1 R6**：指定默认路径模型 — Tasks/Calendar 创建时 atom_ref 路由到指定文件夹，需要跨 feature 访问 workspace tree
- **DI-12（v0.4 规划）**：单根树 + 系统节点锚点（`ROOT`/`Inbox`/`Tasks`/`Calendar`）收敛
- **S3**：Tag × Workspace 正交性 — workspace tree 是独立维度，不从属于 notes feature

---

## Tag × Workspace 正交性（S3 裁决 + 08b）

WorkspaceTreeService 提供**结构归档**维度。Tag 提供**语义分类**维度。两者完全正交：

| 维度 | Tag | Explorer（Workspace Tree） |
|---|---|---|
| 本质 | 语义分类（查询驱动） | 结构归档（用户组织） |
| 数据源 | `atom_tags` 表 | `workspace_nodes` 表 |
| 操作 | 过滤、排序 | 拖拽、移动、嵌套 |
| 类比 | Gmail 标签 | macOS Finder 文件夹 |

**Tag 不影响 Explorer tree 的完整性**。Explorer 始终展示用户组织的全部结构，不受 tag 选择影响。

**Explorer 三种视图模式**（08b S3）：

| 模式 | 触发 | 内容 |
|---|---|---|
| Tree（默认） | 无 tag 选中 | 完整 workspace tree |
| List（Tag 查询） | 选中 tag | 扁平 Atom 列表 + 目录面包屑 |
| Spatial（S1 R12） | 用户切换视图 | 文件夹内容空间化布局（v0.4+） |

详见 [S3](../../rulings/S3-tag-workspace-orthogonality.md)。

---

## 约束

- FFI 调用通过注入的 invoker 执行（可测试性）
- 不包含 UI 逻辑（Explorer 树渲染保留在 `features/notes/`）
- 不包含 tag 逻辑（S3 正交性）

---

## 关联模块

- ← `NotesCoordinator` — 消费者（notes 视图）
- ← `TasksController` — 消费者（tasks 视图创建时路由到指定文件夹）
- ← `CalendarController` — 消费者（calendar 视图创建时路由到指定文件夹）
- → [S1 R6 指定文件夹](../../rulings/S1-atom-projection.md) — 创建路径路由表

---

## 实施状态 `[PR-RB-05 新增]`

| 阶段 | 状态 | PR |
|------|------|-----|
| CRUD 层迁移到 `core/workspace/` | **已完成** | PR-RB-05（v0.3） |
| Pane layout TRANSIENT 过渡 | **已完成** | PR-RB-05 移入 → PR-RB-06 吸收到 `core/editor/` |
| 状态管理提升（ExplorerTreeState） | 设计未收敛 | DI-14（v0.4） |
| 单根树 + 系统节点 | 设计已收敛 | DI-12（v0.4） |

---

## v0.4 Addendum（DI-12 + DI-14，规划态）

> 本节仅作为 v0.4 规划输入，不覆盖 v0.3 进行中的实现基线。

### DI-12：单根树 + 系统节点（RESOLVED）

1. 树结构将收敛到单根（隐藏 `ROOT`），并固化系统节点角色（`Inbox`/`Tasks`/`Calendar`）。
2. `WorkspaceTreeService` 需补充系统节点保护语义：可移动/可重命名，不可删除。
3. “重新指定默认路径”在实现层收敛为移动同一系统节点（role+uuid 不变），不做运行时映射重绑定。
4. Tree/List/Spatial 读取同一结构源，模块层需保证跨视图一致性。

### DI-14：Workspace Tree 提升为 Core First-Class Citizen（PENDING）`[PR-RB-05 新增]`

> PR-RB-05 建立的 `core/workspace/` 目录和 injectable 模式是 DI-14 的先决条件。

1. DI-14 Q0（gate 问题）：是否将 workspace tree 状态管理（ExplorerTreeState 等）也提升到 `core/workspace/`。
2. DI-14 Q2：subtree 查询接口设计 — `workspace_tree_children_loader.dart` 的 BFS tree walk + subtree projection 是天然基础。
3. DI-14 Q3：变更通知模型 — `WorkspaceTreeService` 已是 `ChangeNotifier`，可扩展为 scoped notification。
4. 5 个设计问题全部 open，不做提前实现。
