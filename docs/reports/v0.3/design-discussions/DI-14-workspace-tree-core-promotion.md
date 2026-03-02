# DI-14: Workspace Tree 提升为 Core 层一等公民

| 项目 | 值 |
|------|-----|
| **状态** | PENDING |
| **关联决策点** | DI-1 Q4 细化3、DI-12 E3 |
| **影响范围** | Flutter `features/notes/` explorer 组件、`lib/core/workspace/`、Tasks/Calendar feature 消费模式 |
| **前置依赖** | DI-12（单根树与系统节点语义） |
| **来源** | DI-12 E3 同源化执行项的设计空白；DI-1 Q4 细化3 仅覆盖 CRUD 层搬迁 |

---

## 背景

当前 explorer tree 的全部实现位于 `features/notes/` 内部：

| 文件 | 职责 |
|------|------|
| `note_explorer.dart` | 主容器 widget（1720 行） |
| `explorer_tree_state.dart` | 懒加载树缓存 + 展开/折叠状态 |
| `explorer_tree_builder.dart` | 树节点 → Flutter widget 构建 |
| `explorer_tree_item.dart` | 单行 widget（文件夹 / atom_ref） |
| `explorer_drag_controller.dart` | 拖拽交互 |
| `explorer_context_menu.dart` | 右键菜单 |
| `managers/workspace_tree_manager.dart` | 树变更操作（CRUD via FFI） |
| `managers/workspace_tree_children_loader.dart` | 异步子节点加载 |

DI-1 Q4 细化3 已裁决将 `WorkspaceTreeManager` 搬迁到 `lib/core/workspace/workspace_tree_service.dart`，但该裁决仅覆盖 CRUD/mutation 层。**从 CRUD service 到 feature 消费端之间的状态管理与接口抽象层，尚未设计。**

DI-12 E3 提出"Explorer/Tasks/Calendar 同源化"执行项，但只列举了执行清单，未讨论 Flutter 侧的架构设计——即 HOW。

### 核心张力

1. **Rule E 冲突**：DI-12 Q7/Q8 裁决 Tasks 和 Calendar 的数据源为系统文件夹子树（与 Explorer 同源）。若树状态仍锁在 `features/notes/`，其他 feature 要么违反 Rule E 引用 notes 内部，要么各自重建树访问逻辑。
2. **语义错位**：单根树 + 系统节点（ROOT/Inbox/Tasks/Calendar）是全局内容组织结构，不是 notes feature 的内部组件。
3. **DI-1 仅覆盖 CRUD 层**：`WorkspaceTreeManager` 搬迁解决了写操作的归属，但 `ExplorerTreeState`（读/缓存/状态）的归属未定。

---

## 讨论边界

### In Scope

1. Workspace tree 在 Flutter 层的架构定位（feature 组件 vs core 基础设施）。
2. 树状态管理的拆分策略（共享数据缓存 vs per-feature UI 状态）。
3. Core 层树服务的接口形态与消费模式。
4. 树 UI 组件的共享层级。
5. 与 DI-12 系统节点的衔接。

### Out of Scope

1. DI-12 的数据层迁移（单根树 SQL migration、系统节点创建）——已由 DI-12 裁决。
2. CRUD 层的搬迁——已由 DI-1 Q4 细化3 裁决。
3. EditorShellService 接口设计——已由 DI-1 Q1-Q3 裁决。
4. 具体 UI 视觉设计（布局、样式、交互细节）。

---

## 待裁决问题（Q0-Q5）

### Q0. Workspace tree 是否应提升为 Core 层一等公民？（RESOLVED）

- A. 维持现状：Explorer tree 保留在 `features/notes/`，其他 feature 通过 FFI 各自独立访问树数据
- B. 提升到 Core：将 workspace tree 的状态管理层提升为 `lib/core/workspace/` 基础设施，各 feature 通过 core 接口消费

**裁决**：选择 **B（提升到 Core）**。

**裁决理由**：

1. **语义事实**：从 S4 裁决（atom_ref 统一）起，workspace tree 就承载所有类型 Atom 的组织结构。DI-12 进一步将 Tasks/Calendar 固化为系统文件夹。这是整个应用的内容组织骨架，不是 notes feature 的内部组件。
2. **Rule E 不可绕过**：DI-12 Q7/Q8 裁决 Tasks 和 Calendar 数据源 = 系统文件夹子树。实现只有三条路径——违反 Rule E 引用 notes 内部、各 feature 重建独立缓存导致不一致、共享 core 层树服务。唯一合规路径是 core。
3. **已有两个先例**：S7 → Reminders（`features/` → `core/reminders/`，理由：平台基础设施）；DI-1 Q5 → EditorShellService（→ `core/editor/`，理由：workbench 骨架）。Workspace tree 的跨 feature 程度比两者都强。
4. **DI-1 Q4 细化3 已走半步**：CRUD 层已定位到 `lib/core/workspace/`。状态层留在 notes 内部是因为当时只有 notes 消费，DI-12 同源化要求打破了这个前提。

**依赖关系**：Q0 是本 DI 的前提裁决。Q1-Q5 在 Q0 = B 的基础上展开设计。

---

### Q1. Core workspace tree service 应提供什么核心能力？

#### 需求端推导

从各 feature 的消费需求自顶向下推导 core 层接口。

**各 feature 需要什么**：

| Feature | 需求 |
|---------|------|
| **Notes Explorer** | 以 ROOT 为根，展示整棵树的文件夹与 atom_ref |
| **Tasks** | 以 Tasks 系统节点为根，获取子树内全部 active atom_ref（DI-12 Q8） |
| **Calendar** | 以 Calendar 系统节点为根，获取子树内全部 active atom_ref（DI-12 Q7） |
| **Entry** | 创建时根据意图上下文确定落点（DI-12 Q6 路由优先级） |

**关键发现：统一子树抽象**。

Notes Explorer 和 Tasks/Calendar 的消费能力本质相同——都是"给我以节点 X 为根的子树数据"。差异仅在于：

- Notes Explorer 选 X = ROOT，展示整棵树
- Tasks 选 X = Tasks 系统节点，展示该子树
- Calendar 选 X = Calendar 系统节点，展示该子树

展示形态（树形 / 列表 / 分组）是 feature 层的渲染选择，不影响 core 的查询语义。

**Core 核心能力（从需求端收敛）**：

| 能力 | 说明 | 消费者 |
|------|------|--------|
| **子树查询** | 以任意节点为根，获取子树数据。唯一的数据读取原语 | 全部 |
| **树结构变更（CRUD）** | 创建文件夹/atom_ref、重命名、移动、删除 | Notes Explorer（直接），Tasks/Calendar（通过创建路由） |
| **系统节点解析** | role → uuid 映射，确定各 feature 的子树根 | 全部 |
| **创建路由** | DI-12 Q6 优先级解析，确定 CRUD 的目标节点 | Entry、Tasks、Calendar、Notes |
| **变更通知** | 结构变化后通知消费者 | 全部 |

**Feature 层自有职责（不属于 core）**：

| 职责 | 性质 | 说明 |
|------|------|------|
| 展开/折叠状态 | per-feature UI 状态 | Notes 展开全树，Tasks 可能只看一层 |
| 过滤/分组/排序 | per-feature 展示逻辑 | DI-12 Q7/Q8 明确"由 UI 视图层承担" |
| 渲染方式 | per-feature UI 组件 | 树形 / 列表 / 分组 / 日历格 |

---

### Q2. 子树查询的接口设计？

Q1 确立了"子树查询"为唯一数据读取原语。具体接口如何设计？

- A. **统一 `querySubtree(rootNodeId, {depth?})` 接口**：单一方法，`depth=1` 为直接子节点（Explorer 逐层展开），`depth=null` 为全量递归（Tasks/Calendar 全量获取）
- B. **双方法接口**：`listChildren(parentNodeId)` + `listSubtreeAtomRefs(rootNodeId)` 分别服务于逐层展开和全量获取两个场景
- C. **纯事件驱动**：Core 持有全树缓存，feature 通过 `getSubtreeSnapshot(rootNodeId)` 获取当前快照，不区分加载粒度

**分析重点**：

- Explorer 逐层展开需要懒加载（用户可能永远不展开某些文件夹），全量预加载浪费。
- Tasks/Calendar 需要子树全量（UI 要做分组/排序），逐层加载增加 feature 端复杂度。
- 是否需要 Rust Core 提供新的子树查询 FFI，还是 Flutter 侧递归组装。

---

### Q3. 变更通知与缓存一致性？

Core service 的变更通知如何设计，使各 feature 保持数据一致？

- A. **ChangeNotifier 全局通知**：Service 本身是 ChangeNotifier，任何树变更后 `notifyListeners()`，所有消费者统一收到通知
- B. **Scoped 通知**：支持按子树根订阅，只通知受影响的 feature（如 Tasks 子树变更不通知 Calendar）
- C. **Revision 轮询**：Service 维护全局 revision 计数器，feature 自行比对 revision 决定是否刷新

**分析重点**：

- 与代码库现有模式的一致性（coordinator/manager 均使用 ChangeNotifier）。
- 树节点可能跨系统文件夹移动（如从 Tasks 移到 Calendar），scoped 通知需要同时通知两方。
- mutation 成功后 core 应直接 invalidate 受影响缓存（内聚），还是只发通知让 feature 重新查询。

---

### Q4. 树 UI 组件的共享层级？

`ExplorerTreeBuilder`、`ExplorerTreeItem` 等渲染组件是否共享？

- A. **不共享**：Core 只管数据/状态，各 feature 各自渲染。Notes 用树形 explorer，Tasks 用列表，Calendar 用分组
- B. **共享基础组件**：将通用的 `TreeItemWidget`、`TreeBuilder` 放入 `lib/shared/`，feature 组合使用
- C. **共享完整 ExplorerTree widget**：将 `NoteExplorer` 泛化为可配置的 `WorkspaceTreeView` 放入 core/shared

**分析重点**：

- Tasks 和 Calendar 当前用列表/分组视图，不用树形展示。是否有场景需要它们也展示树形结构？
- 如果各 feature 渲染方式差异大，共享 UI 组件的收益是否足以抵消抽象成本？

---

### Q5. 系统节点解析归属？

DI-12 定义了系统节点（ROOT/Inbox/Tasks/Calendar）按 `role + uuid` 绑定。"从 role 解析到 uuid"的逻辑放在哪？

- A. **Core service 内部解析**：Service 启动时加载系统角色绑定，提供 `getSystemNode(role)` API，feature 不感知 uuid
- B. **Feature 自行查询**：Feature 通过 FFI 查询系统角色表，自行维护 role → uuid 映射
- C. **注入常量**：系统节点 uuid 在 App 启动时解析一次，作为常量注入各 feature

**分析重点**：

- 系统节点 uuid 是稳定值（迁移时生成，生命周期与 DB 相同），不需要频繁查询。
- 但解析逻辑应该有单一归属点，避免多处硬编码或重复查询。

---

## 讨论顺序建议

1. **先定 Q0**（核心定位）——决定后续讨论是否展开。
2. **再定 Q1**（核心能力）——确定 core 层提供什么、feature 层保留什么。
3. **再定 Q2-Q3**（接口与通知）——确定数据读取原语和一致性模型。
4. **再定 Q4**（UI 共享）——确定 feature 端的渲染组件策略。
5. **最后定 Q5**（系统节点衔接）——与 DI-12 的接口对接。

---

## 关联

- ← DI-1 Q4 细化3（WorkspaceTreeManager → `core/workspace/` 搬迁，CRUD 层已裁决）
- ← DI-1 Q5（文件位置先例：`lib/core/editor/`）
- ← DI-12（单根树 + 系统节点语义，E3 同源化执行项）
- ← S7 裁决（Reminders → `core/` 先例：平台基础设施豁免 Rule E）
- ← S3（Tag × Workspace Tree 正交性：树是独立组织维度）
- → DI-12 E3 落地（本 DI 是 E3 的 Flutter 侧设计补全）

---

*前序议题：[DI-13 Calendar Range 查询默认 Limit 策略](DI-13-calendar-range-limit-policy.md)*
