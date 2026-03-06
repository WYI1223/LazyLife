# DI-17: Flutter 薄客户端与 Feature 消费适配

| 项目 | 值 |
|------|-----|
| **状态** | RESOLVED |
| **关联决策点** | DI-14 Q0-Q2（概念母题）、DI-16（Rust API） |
| **影响范围** | `lib/core/workspace/`、`features/notes/`、`features/tasks/`、`features/calendar/` |
| **前置依赖** | DI-16（Rust Service + FFI 契约裁决） |
| **目标版本** | v0.4 |
| **输出物** | Flutter 实现方案（core wrapper 设计 + feature 适配清单） |

---

## 背景

DI-14 Q0 裁决 workspace tree 提升为 Flutter core 层一等公民。DI-15/16 确定了 Rust Core 的数据模型和 API 表面。本 DI 设计 Flutter 层的消费架构：薄客户端包装、状态管理、变更通知、以及各 feature 的适配方案。

**边界原则**：本 DI 只讨论 Flutter 层（"怎么消费 Rust API"），不讨论 Rust 数据模型（DI-15）或 Rust API（DI-16）。

### 输入约束

| 来源 | 约束 |
|------|------|
| DI-14 Q0 | Workspace tree 是 `lib/core/workspace/` 基础设施 |
| DI-14 Q1 | Core 能力：子树查询、CRUD、系统节点解析、创建路由、变更通知 |
| DI-14 Q1 | Feature 自有：展开/折叠状态、过滤/分组/排序、渲染方式 |
| DI-14 Q2 | 双方法接口：listChildren（浏览）+ listSubtreeAtomRefs（收集） |
| DI-16 | FFI 函数签名与响应类型（待 DI-16 裁决后填入） |
| 代码库惯例 | ChangeNotifier + AnimatedBuilder 响应式模式 |
| 代码库惯例 | 请求去重（sequence ID 防止 stale response overwrite） |

---

## 讨论边界

### In Scope

1. `WorkspaceTreeService`（`lib/core/workspace/`）的具体设计。
2. 变更通知策略（ChangeNotifier / Scoped / Revision）。
3. 缓存策略（core 层缓存 vs feature 层缓存）。
4. 请求去重与并发控制。
5. 树 UI 组件共享层级（`lib/shared/` vs feature 各自实现）。
6. Tasks/Calendar controller 适配方案。
7. Synthetic uncategorized 移除。

### Out of Scope

1. Rust 数据模型与 migration → DI-15。
2. Rust API 与 FFI 函数设计 → DI-16。
3. PR 拆分与执行顺序 → DI-18。
4. 具体 UI 视觉设计。

---

## 待裁决问题（Q1-Q6）

### Q1. WorkspaceTreeService 的设计形态？

Core 层的 `WorkspaceTreeService` 承担 FFI 薄包装 + 状态中枢。

- A. **纯 FFI 转发**：无状态，每次调用直接透传 FFI，feature 自管缓存
  - 优点：最简，zero-state
  - 缺点：feature 间缓存不共享，同一数据多次 FFI 往返

- B. **FFI 转发 + ChangeNotifier**：无缓存，但提供 mutation 后的全局通知
  - 优点：简单；feature 可选择性监听刷新
  - 缺点：无缓存意味着通知后每个 feature 都要重查

- C. **FFI 转发 + ChangeNotifier + 最小缓存**：缓存 listChildren 结果，mutation 后 invalidate
  - 优点：减少重复 FFI 调用；通知后 feature 重查命中缓存
  - 缺点：缓存一致性需要维护

**分析重点**：

- 当前 `ExplorerTreeState` 已有 `_childrenByParent` 缓存。提升到 core 后是否保留？
- 多 feature 同时访问同一子树时（如 Explorer 和"添加已有项" picker），缓存共享的收益如何？

#### Q1 裁决：B+（FFI 薄包装 + ChangeNotifier + revision，不含缓存）

**选择**：B 变体（B+）。WorkspaceTreeService 负责 FFI 薄封装 + mutation 通知，**不持有 children 读缓存**。

**WorkspaceTreeService 职责边界**：

| 负责 | 不负责 |
|------|--------|
| FFI 调用封装（list_children / create / move / rename / delete） | children 数据缓存（`_childrenByParent`） |
| Mutation 后 `notifyListeners()` + revision bump | 读请求 in-flight 去重（留给消费者） |
| 响应 envelope 解包 + 错误映射 | 排序逻辑（feature 视图关注点） |
| CallerContext.scope_workspace_id 注入（DI-16 Q5） | 展开/折叠等视图状态 |

**排除 A 的理由**：
- 当前代码已有 ChangeNotifier + revision（退回纯转发是倒退）。
- 多 feature 监听 mutation 事件（Explorer、未来 picker）需要统一通知源。

**排除 C/C+ 的理由**：
- 树拓扑的实际多消费者只有 Explorer + picker（Tasks/Calendar 走 `query_atoms`，不消费 `list_children`）。
- `list_children` 底层是本地 SQLite 查询（<1ms），重复 FFI 调用的成本可忽略。
- 缓存提升到 core 扩大故障面：所有 mutation 路径必须正确 invalidate，而 v0.4 阶段消费者少，收益不抵复杂度。
- "可预测失效"在边缘场景（深嵌套跨子树 move）下需要全量失效兜底，缓存保证不稳定。

**Feature 侧缓存规则**：
- `ExplorerTreeState` 保留 `_childrenByParent` 数据缓存 + `_requestVersionByParent` in-flight 去重 + `_expandedFolders` 视图状态。
- 未来 picker 按需持有自己的短生命周期缓存。
- 各消费者监听 `WorkspaceTreeService` 的 ChangeNotifier，收到通知后按需重查 FFI。

**升级口**：当出现"多长期消费者 + 高频并发读"场景时，可升级为 C（将 children 缓存提升到 core），届时删除 feature 侧数据缓存以禁止双缓存。

**与后续问题的关联**：
- Q2：B+ 自然搭配 ChangeNotifier 全局通知，mutation 频率低无需 scoped。
- Q4：系统节点解析为 Service 内部方法（`getSystemNodeId(role)`），这是唯一的"缓存"——启动时一次性加载，生命周期不变。
- Q5：Tasks/Calendar 通过 `query_atoms` 获取 atom 数据，不依赖 WorkspaceTreeService 的 list_children。
- Q6：synthetic `__uncategorized__` 移除与 B/C 选择无关，按 DI-12/DI-16 执行。

---

### Q2. 变更通知策略？（继承自 DI-14 Q3）

- A. **ChangeNotifier 全局通知**：Service 本身是 ChangeNotifier，任何树变更后 `notifyListeners()`
- B. **Scoped 通知**：支持按子树根订阅，只通知受影响的 feature
- C. **Revision 轮询**：Service 维护全局 revision 计数器，feature 自行比对

**分析重点**：

- 与代码库现有模式的一致性（coordinator/manager 均使用 ChangeNotifier）。
- 跨子树移动（Tasks → Calendar）时，scoped 通知需同时通知两方。
- Mutation 频率低（用户手动操作），全局广播的性能开销可忽略。

#### Q2 裁决：A+delta（全局 ChangeNotifier + TreeMutationDelta 变更提示）

**选择**：A 增强版。保留全局 `notifyListeners()` 广播，额外暴露 `lastMutation` delta 供消费者定向刷新。

**排除 C（Revision 轮询）的理由**：
- 轮询是 pull 模型，代码库全部使用 push 模型（ChangeNotifier + `addListener`），引入 pull 增加异构复杂度。
- 现有 `_workspaceTreeRevision` 作为 ChangeNotifier 的补充信息保留，但不作为独立通知机制。

**排除 B（Scoped 通知）的理由**：
- 需要维护订阅注册表（哪个 listener 关心哪棵子树），实现复杂度高。
- 跨子树 move 需同时通知两棵子树的订阅者，要求 mutation 识别影响范围并逐一路由——本质上是在实现事件总线。
- 当前只有 Explorer 一个长期消费者监听树变更，scoped 的收益接近零。

**选 A 但补 delta 的理由**：
- 纯 A 的缺点：`notifyListeners()` 不携带变更信息。消费者不知道"什么变了"，只能全量 reload 所有已展开 folder。当 Explorer 展开 5 个 folder 时，一次 rename 会触发 5 次 FFI 调用（其中 4 次无意义）。
- A+delta 解决：mutation 后写入 `lastMutation`（含 affectedParentIds），消费者按 `expandedFolders ∩ affectedParentIds` 定向刷新。

**TreeMutationDelta 结构**：

```dart
class TreeMutationDelta {
  final int revision;
  final TreeMutationType type;
  final Set<String?> affectedParentIds; // null 代表 root，Set 语义自动去重

  const TreeMutationDelta({
    required this.revision,
    required this.type,
    required this.affectedParentIds,
  });
}

enum TreeMutationType { create, rename, move, delete }
```

**各 mutation 的 affectedParentIds**：

| Mutation | affectedParentIds | 说明 |
|----------|-------------------|------|
| `create_folder(parent)` | `{parent}` | 新节点出现在 parent 的 children |
| `create_atom_ref(parent)` | `{parent}` | 同上 |
| `rename_node(node)` | `{node.parent}` | parent 的 children 中 display_name 变了 |
| `move_node(node, newParent)` | `{oldParent, newParent}` | Set 去重：oldParent == newParent 时只刷一次 |
| `delete_folder(dissolve)` | `{folder.parent}` | 子节点 re-parent 到 folder.parent（DI-15 定义），与 folder 自身删除影响同一个 parent，Set 去重后单条目 |
| `delete_folder(delete_all)` | `{folder.parent}` | folder 连同子树消失，只影响 parent |

**线程安全**：Flutter 单线程事件循环，`notifyListeners()` 同步执行所有 listener。delta 在 `notifyListeners()` 前写入，listener 读到的一定是当前 mutation 的 delta。

**消费侧模式**：

```dart
void _onTreeChanged() {
  final delta = _treeService.lastMutation;
  if (delta == null) {
    _reloadAllExpanded(); // 无 delta 时 fallback 全量刷新
    return;
  }
  // root 总是"展开"的
  if (delta.affectedParentIds.contains(null)) {
    _reloadRoot();
  }
  final toReload = _expandedFolders
      .where((id) => delta.affectedParentIds.contains(id))
      .toList();
  for (final parentId in toReload) {
    _reloadChildren(parentId);
  }
}
```

**delta 定位**：hint 而非硬保证。消费者可忽略 delta 退化为纯 A 行为（全量 reload），不影响正确性。

---

### Q3. 树 UI 组件的共享层级？（继承自 DI-14 Q4）

- A. **不共享**：Core 只管数据/状态，各 feature 各自渲染
- B. **共享基础组件**：`TreeItemWidget`、`TreeBuilder` 放入 `lib/shared/`
- C. **共享完整 ExplorerTree widget**

**分析重点**：

- Tasks 用列表/分组视图，Calendar 用日历格。渲染差异大。
- 未来"添加已有项" picker 需要树形浏览，与 Explorer 相似。
- 共享粒度应匹配实际复用场景，避免过度抽象。

#### Q3 裁决：A+/B-（不提取，但内部分层 + 量化触发条件）

**选择**：v0.4 不将树 UI 组件提取到 `lib/shared/`，但在重构 Explorer 时主动分离通用逻辑与特化逻辑，为未来提取降低成本。

**排除 C（共享完整 ExplorerTree）的理由**：
- `ExplorerTreeBuilder` 与 12 个 Explorer 回调（drag wrapper、context menu、synthetic root）深度耦合，直接共享引入不必要的复杂度。

**排除 B（现在提取到 `lib/shared/`）的理由**：
- 树渲染消费者只有 Explorer + 未来 picker。Tasks/Calendar 不渲染树（走 `query_atoms`）。
- Picker 尚不存在，提前抽象是针对假想需求设计，违反 YAGNI。
- `ExplorerTreeItem` 要变通用需大幅参数化，结果要么太薄（~30 行，重写更快）要么等量复杂。

**排除纯 A（完全不关心共享）的理由**：
- Rule E 约束：`features/<name>` 不可互相 import。未来 picker 若在 `lib/shared/`，无法引用 `features/notes/` 的组件。
- 如果不做内部分层准备，未来提取时要从耦合代码中拆解，成本高。

**v0.4 执行规则**：

1. **内部分层**：重构 Explorer 组件时（移除 synthetic、适配新 FFI），将通用逻辑与 Explorer 特化逻辑分成两层：
   - 基础层：缩进行布局 + 图标/文本渲染 + 递归遍历 + loading/error/empty 状态
   - 特化层：create/delete 按钮、drag wrapper、context menu、synthetic root 判断
2. **反向耦合禁止**：基础层不得引用 Explorer 的 action/context menu 类型。特化行为通过回调/slot 注入，确保基础层可独立移动。
3. **提取触发条件**：实际重复代码 >100 行 **且** 跨 2 个消费者上线时，将基础层提取到 `lib/shared/tree/`。未达标前不提取。

**Rule E 兼容**：picker 开发时，若触发提取条件，基础层移到 `lib/shared/tree/`，Explorer 和 picker 共同引用；若未触发，picker 自建精简树组件（无 drag/context menu，预计 ~100 行）。

---

### Q4. 系统节点解析的 Flutter 侧归属？（继承自 DI-14 Q5）

- A. **WorkspaceTreeService 内部解析**：启动时通过 FFI 加载 role → uuid 映射，提供 `getSystemNodeId(role)` 方法
- B. **Feature 自行调 FFI 解析**
- C. **App 启动时注入常量**

**分析重点**：

- 系统节点 UUID 是稳定值（DB 生命周期不变），单次加载即可。
- 应有单一归属点。WorkspaceTreeService 是自然归属。

#### Q4 裁决：A（WorkspaceTreeService 内部解析，同步 getter）

**选择**：A。WorkspaceTreeService 启动时通过 FFI 加载 role→uuid 映射，提供 `getSystemNodeId(role)` 同步 getter。

**排除 B（Feature 自行调 FFI）的理由**：
- 违反 DRY：每个 feature 重复实现解析 + 异步加载 + 错误处理。
- Feature 不应关心"怎么拿到 UUID"，只需要"给我 tasks folder 的 ID"。

**排除 C（App 启动注入常量）的理由**：
- 注入链过长（bootstrap → Service constructor → feature constructors），bootstrap 需了解 workspace 内部概念，破坏封装。
- `reassign_designated` 后常量失效，需要额外的刷新机制。A 方案 Service 自身持有映射，刷新内聚。

**选 A 的核心理由**：
- 系统节点 UUID 是 DB 级不可变量（除非 `reassign_designated`），是 DI-17 唯一合理的"缓存"——不会自然失效。
- 单一归属点：Tasks/Calendar/Explorer 统一通过 `getSystemNodeId(role)` 获取，不重复查、不硬编码。
- 与 DI-16 一致：Rust/FFI 已有 designated 解析接口，Flutter 只做薄缓存与分发。

**落地约束**：

1. **缓存键 = `workspace_id + role`**：即使 v0.4 为单 workspace，接口形态先预留复合键，避免未来多 workspace 时 breaking change。
2. **`reassign_designated` 后必须刷新映射**：`reassign_designated` 是 WorkspaceTreeService 的 mutation，成功后更新本地 `_systemNodeIds` 对应条目。
3. **失败返回明确错误**：`getSystemNodeId(role)` 返回非空 `String`，role 不存在时抛 `DesignatedRoleNotFoundException`，不静默返回 null。调用方必须显式处理错误。

**具体设计**：

```dart
class WorkspaceTreeService extends ChangeNotifier {
  // workspace_id + role → node_uuid（init 后基本不变，reassign 时更新）
  final Map<(String, String), String> _systemNodeIds = {};
  final Set<String> _loadedWorkspaceIds = {};  // 按 workspace 粒度追踪

  /// 已知的 designated role 列表（v0.4 固定集合）
  static const List<String> _knownRoles = ['inbox', 'tasks', 'calendar'];

  /// 加载指定 workspace 的系统节点映射（app bootstrap 阶段调用）
  /// 逐 role 调用 DI-16 的 workspace_resolve_designated FFI。
  Future<void> loadSystemNodes(String workspaceId) async {
    if (_loadedWorkspaceIds.contains(workspaceId)) return;
    for (final role in _knownRoles) {
      final resp = await _resolveDesignated(
        workspaceId: workspaceId, role: role,
      );
      if (!resp.ok) throw WorkspaceInitException(resp.errorCode, resp.message);
      _systemNodeIds[(workspaceId, role)] = resp.nodeId;
    }
    _loadedWorkspaceIds.add(workspaceId);
  }

  /// 同步 getter：返回指定 role 的系统节点 UUID，不存在时抛异常
  String getSystemNodeId(String workspaceId, String role) {
    final id = _systemNodeIds[(workspaceId, role)];
    if (id == null) {
      throw DesignatedRoleNotFoundException(workspaceId: workspaceId, role: role);
    }
    return id;
  }
}
```

**加载时机**：`loadSystemNodes()` 在 app bootstrap 阶段调用（WorkspaceTreeService 初始化之后、feature controller 初始化之前）。失败时阻止 feature 初始化并展示错误。

**消费侧**：Controller 持有 `WorkspaceTreeService` 引用，每次查询前通过 `getSystemNodeId()` 取当前值（同步 getter，无异步开销）。不将 folder_id 固定为构造参数，避免 `reassign_designated` 后陈旧。

```dart
// TasksController._loadInbox()
final tasksFolderId = _treeService.getSystemNodeId(workspaceId, 'tasks');
final resp = await _queryAtoms(folderId: tasksFolderId, ...);
```

---

### Q5. Tasks/Calendar controller 适配？

当前 Tasks/Calendar 完全绕过 workspace tree：

```
TasksController → FFI tasks_list_inbox/today/upcoming → 直查 atoms
CalendarController → FFI calendar_list_by_range → 直查 atoms
```

适配后需通过统一 `query_atoms` FFI（DI-16 Q1 ScopedAtomQuery）获取 atom 数据，以 designated folder 的 `folder_id` 作为子树根。树拓扑操作（list_children）不涉及。

**需要裁决**：

1. **适配粒度**：
   - A. Controller 内部替换数据源（最小改动）
   - B. 重构为 Manager 模式（与 NotesCoordinator 对齐）

2. **过渡期兼容**：
   - DI-16 Q6 的裁决（旧 FFI 不保留，一次性迁移）决定 Flutter 侧须同步适配。

3. **分组逻辑位置**：
   - Tasks 的 inbox/today/upcoming 分组、Calendar 的时间分组，确认在 controller/manager 层完成。

#### Q5 裁决：A+（Controller 内部替换数据源 + 共享 query helper）

**选择**：A 变体（A+）。保留 `TasksController` / `CalendarController` 结构，只替换数据源到统一 `query_atoms` FFI。

**排除 B（Manager 模式重构）的理由**：
- TasksController（~390 行）和 CalendarController（~252 行）职责清晰、规模合理，不存在 NotesCoordinator 重构前的膨胀问题。
- 3 个 section（inbox/today/upcoming）是同一职责的不同时间切面，不是不同职责。拆成 3 个 Manager 增加文件和间接层，无收益。
- 强行对齐 NotesCoordinator 模式是形式主义。

**A+ 四条执行规则**：

1. **保留 Controller 结构，只替换数据源**：`TasksController` / `CalendarController` 的 public API（`loadAll()`、`reload()`、`toggleStatus()` 等）不变，UI 层不受影响。将 3 个 section invoker（`TasksListInboxInvoker` / `TodayInvoker` / `UpcomingInvoker`）统一为 1 个 `QueryAtomsInvoker`，controller 内部构造不同的 ScopedAtomQuery 参数。

2. **ScopedAtomQuery 参数模板放共享 helper**：避免 Tasks 和 Calendar 重复拼 query descriptor。Helper 提供预配置的查询模板（如 `TasksQueryTemplates.inbox(folderId)`、`CalendarQueryTemplates.weekRange(folderId, start, end)`），controller 调用时只需传入动态参数。

3. **Controller 持有 `WorkspaceTreeService` 引用，每次查询前取 folder_id**：Tasks/Calendar 通过 Q4 裁决的 `getSystemNodeId(workspaceId, 'tasks'/'calendar')` 同步获取 designated folder UUID。不将 folder_id 固定为构造参数（避免 reassign 后陈旧）。不监听 WorkspaceTreeService 的 ChangeNotifier，不调用树拓扑操作。

4. **一次性迁移，不维护旧 FFI 双轨**：与 DI-16 Q6 兼容策略一致。同一 PR 中删除旧 invoker 类型 + 旧默认 invoker 函数，替换为新 `query_atoms` 调用。

**Invoker 改造明细**：

| 当前（TasksController） | 适配后 | 说明 |
|------------------------|--------|------|
| `TasksListInboxInvoker` | 删除 | 统一为 `QueryAtomsInvoker` |
| `TasksListTodayInvoker` | 删除 | 统一为 `QueryAtomsInvoker` |
| `TasksListUpcomingInvoker` | 删除 | 统一为 `QueryAtomsInvoker` |
| `AtomUpdateStatusInvoker` | 保留 | 适配 `atom_update_status`（DI-16 Q6.3 保留项） |
| `InboxCreateInvoker` | 保留 | 适配 `atom_create`（DI-16 Q6.2） |

| 当前（CalendarController） | 适配后 | 说明 |
|---------------------------|--------|------|
| `CalendarListByRangeInvoker` | 删除 | 统一为 `QueryAtomsInvoker` |
| `CalendarScheduleInvoker` | 保留 | 适配 `atom_create`（DI-16 Q6.2） |
| `CalendarUpdateEventInvoker` | 保留（重命名） | 适配 `atom_update_time`（DI-16 Q6.3 补充，重命名自 `calendar_update_event`） |

**folder_id 获取方式**：Controller 持有 `WorkspaceTreeService` 引用，每次查询前通过 `getSystemNodeId()` 同步取当前值。不将 folder_id 固定为构造参数，避免 `reassign_designated` 后陈旧（与 Q4 落地约束 2 一致）。

```dart
class TasksController extends ChangeNotifier {
  TasksController({
    required WorkspaceTreeService treeService,
    required String workspaceId,
    required QueryAtomsInvoker queryAtoms,
    required AtomUpdateStatusInvoker statusInvoker,
    required InboxCreateInvoker createInvoker,
    // ...
  }) : _treeService = treeService,
       _workspaceId = workspaceId;

  Future<void> _loadInbox() async {
    final folderId = _treeService.getSystemNodeId(_workspaceId, 'tasks');
    final resp = await _queryAtoms(folderId: folderId, ...);
    // ...
  }
}
```

**分组逻辑位置确认**：inbox/today/upcoming 的分类由 Rust ScopedQueryRepository 的 SQL 完成（不同 time_filter + status_filter 参数）。Flutter controller 只负责"知道问什么问题"（构造 ScopedAtomQuery），Rust "负责回答"。Calendar 同理：时间范围由 controller 确定，Rust 按范围返回。

---

### Q6. Synthetic uncategorized 移除？

DI-12 Q2 裁决用真实 Inbox 节点替代 synthetic `__uncategorized__`。

**需要裁决**：

1. `workspace_tree_children_loader.dart` 中约 200 行 synthetic 逻辑直接删除。
2. `ExplorerTreeState` 中 `__uncategorized__` 相关判断删除。
3. 是否需要数据迁移提示（UI 告知用户"未分类 → Inbox"变更）？

#### Q6 裁决：全量删除 synthetic 逻辑，无运行时迁移提示

**Q6.1 workspace_tree_children_loader.dart → 删除整个文件**

该文件（378 行）的绝大部分代码是 synthetic 逻辑，v0.4 后全部多余：

| 方法 | 行数 | 删除理由 |
|------|------|---------|
| `_listProjectedUncategorizedChildren()` | ~120 | BFS 遍历全树收集未引用 atom → DI-15 Rust migration 自动挂到 Inbox |
| `_legacySyntheticUncategorizedChildren()` | ~30 | FFI 不可用时降级 → v0.4 bootstrap 保证 FFI 可用 |
| `_decorateWorkspaceChildren()` | ~35 | root 列表注入 synthetic folder + 过滤 root atom_ref → 真实 Inbox 由 Rust 返回 |
| `_fallbackWorkspaceChildren()` | ~75 | 硬编码 projects/notes/personal 降级 → v0.4 树结构由 Rust 定义 |
| `_shouldUseWorkspaceTreeSyntheticFallback()` | ~15 | FFI 初始化失败检测 → v0.4 不需要降级路径 |

删除后 `WorkspaceTreeService` 直接调 FFI `list_children`，不再经过 loader 中间层。

**Q6.2 其他文件清理**

| 文件 | 动作 |
|------|------|
| `explorer_tree_state.dart` | 删除 `_uncategorizedNodeId` 常量、`_compareExplorerRows` 和 `_kindRank` 中的 uncategorized 特殊分支 |
| `workspace_tree_service.dart` | 删除 `_uncategorizedFolderNodeId` 常量、parent 验证中的 `== _uncategorizedFolderNodeId` 特殊路由 |
| `note_explorer.dart` | 删除 `_defaultUncategorizedFolderId` 常量 |
| 4 个测试文件（27 处引用） | 删除 synthetic node 相关 mock 数据和 assert，补充真实 Inbox folder 的测试用例 |

**影响统计**：8 个文件、48 处引用，预计净减 ~300 行。

**Q6.3 数据迁移提示 → 不需要运行时 UI**

- DI-15 Rust migration 自动将 root 级无 parent 的 atom_ref 挂到 Inbox designated folder。
- 用户感知：之前在"未分类"里的 note → 现在在"Inbox"里。行为等价，只是名称变化。
- v0.4 是架构大版本，用户预期有变化。在 Changelog / Release Notes 中说明即可。

**测试策略**：删除 fallback/降级路径后，所有测试通过注入 mock invoker 验证正常路径和错误路径，不依赖 runtime fallback。原有 4 个测试文件中的 synthetic mock 数据替换为真实 Inbox folder 结构的 mock 数据。

---

## 关联

- ← DI-14 Q0-Q2（概念母题：提升到 core、核心能力、接口设计）
- ← DI-14 Q3-Q5（未裁决议题迁移至本 DI Q2-Q4）
- ← DI-16（Rust API：FFI 契约）
- → DI-18（执行方案：Flutter 侧代码迁移策略）

---

*前序议题：[DI-16 Rust Service 层与 FFI 契约](DI-16-rust-service-ffi-contract.md)*
