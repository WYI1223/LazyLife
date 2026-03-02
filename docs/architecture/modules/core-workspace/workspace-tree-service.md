# Module Spec: WorkspaceTreeService

> `lib/core/workspace/workspace_tree_service.dart`
>
> 设计来源：[DI-1 Q4.3](../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) · [S9](../../rulings/S9-cross-feature-infrastructure-placement.md) · [S1 R5/R6](../../rulings/S1-atom-projection.md) · [DI-12](../../../reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md)

---

## 职责

组织结构基础设施：workspace tree CRUD 的 FFI 封装。从 `features/notes/managers/workspace_tree_manager.dart` 提取到 `lib/core/workspace/`，因为 workspace tree 将被 Notes、Tasks、Calendar 等多个 feature 消费（S9 规则 1：被 2+ feature 消费的模块归入 `core/`）。

---

## 目标文件结构

```
lib/core/workspace/
├── workspace_tree_service.dart    ← 从 features/notes/managers/ 搬入
└── workspace_models.dart          ← 从 features/workspace/ 迁入（TreeNode 等）
```

---

## 提取范围

| 从 | 提取内容 | 说明 |
|---|---|---|
| `WorkspaceTreeManager` | tree CRUD FFI 调用（create folder, create ref, list children, move, delete） | 核心操作 |
| `WorkspaceModels` | `TreeNode`, `WorkspaceNodeKind` 等数据模型 | 共享数据类型 |

NotesCoordinator 中与 workspace tree 相关的协调逻辑（如 "在指定文件夹创建 note"）保留在 Coordinator 层，调用 `WorkspaceTreeService` 方法。

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

## v0.4 Addendum（DI-12，规划态）

> 本节仅作为 v0.4 规划输入，不覆盖 v0.3 进行中的实现基线。

1. 树结构将收敛到单根（隐藏 `ROOT`），并固化系统节点角色（`Inbox`/`Tasks`/`Calendar`）。
2. `WorkspaceTreeService` 需补充系统节点保护语义：可移动/可重命名，不可删除。
3. “重新指定默认路径”在实现层收敛为移动同一系统节点（role+uuid 不变），不做运行时映射重绑定。
4. Tree/List/Spatial 读取同一结构源，模块层需保证跨视图一致性。
