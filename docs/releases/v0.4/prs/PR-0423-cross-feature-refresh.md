# PR-0423: Cross-Feature Data Refresh on Section Switch

- Proposed title: `fix(app): cross-feature data refresh on section switch`
- Status: Draft

## Goal

修复 Issue #45：各 feature controller（`NotesCoordinator`、`TasksController`、`CalendarController`）独立缓存数据，跨 feature 数据变更后切换 section 不触发刷新，导致视图停留于陈旧状态。引入轻量级 `DataChangeNotifier` 单例（位于 `lib/core/`），所有 atom CRUD/mutation 操作完成后触发通知；各 feature controller 订阅通知并将缓存标记为 stale；section 切换时（即 page 首次挂载的 `initState` 后帧）若 cache 为 stale 则重载。

前置条件：无（独立修复，可在 PR-0412/0413 之前或之后合入）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Issue | Issue #45 | 本 PR 直接修复的 bug 报告 |
| 现有实现 | `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart` | 需订阅 DataChangeNotifier，mutation 后触发通知 |
| 现有实现 | `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart` | 需订阅 DataChangeNotifier，mutation 后触发通知 |
| 现有实现 | `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` | 需订阅 DataChangeNotifier，mutation 后触发通知 |
| 现有实现 | `apps/lazynote_flutter/lib/features/tasks/tasks_page.dart` | 需在 section 可见时若 stale 则 reload |
| 现有实现 | `apps/lazynote_flutter/lib/features/calendar/calendar_page.dart` | 需在 section 可见时若 stale 则 reload |
| 现有实现 | `apps/lazynote_flutter/lib/features/notes/notes_page.dart` | 需在 section 可见时若 stale 则 reload |
| 架构规则 | `docs/architecture/engineering-standards.md` Rule E | 跨 feature 基础设施置于 `lib/core/` |

## Scope

In scope:
- 新增 `DataChangeNotifier`（`lib/core/data_change_notifier.dart`）：轻量级 `ChangeNotifier` 单例，提供 `notifyDataChanged()` 方法
- `TasksController` 订阅 `DataChangeNotifier`：mutation 操作（`toggleStatus`、`createInboxItem`）完成后调用 `notifyDataChanged()`；订阅通知后将 `_isStale` 置为 `true`
- `CalendarController` 订阅 `DataChangeNotifier`：mutation 操作（`createEvent`、`updateEvent`）完成后调用 `notifyDataChanged()`；订阅通知后将 `_isStale` 置为 `true`
- `NotesCoordinator`（via `_NotesCoordinatorImpl`）：note create/update 操作后调用 `notifyDataChanged()`；订阅通知后将 list cache 标记为 stale
- `TasksPage`：在 `initState` postframe 回调中检测 stale 并条件重载（替代无条件 `loadAll()`）
- `CalendarPage`：同上，在 `initState` postframe 回调中条件重载
- `NotesPage`：同上，在 `initState` postframe 回调中条件重载
- `DataChangeNotifier` 以构造函数参数注入各 controller，支持测试替换
- 单元测试：DataChangeNotifier 订阅/通知机制，stale 标志翻转，conditional reload 行为

Out of scope:
- Entry Panel（`SingleEntryController`）的跨 feature 刷新 — entry 创建结果不影响同 session 内已加载的 section 视图，优先级较低
- Workspace tree 节点变更的跨 feature 通知 — 已由 `WorkspaceTreeService` 的 `TreeMutationDelta` 机制处理（PR-0412）
- 分页加载的增量更新 — stale reload 为全量重载，增量 patch 留待后续优化
- PR-0413 中 `QueryAtomsInvoker` 迁移完成后的接口对齐 — 本 PR 在现有 invoker 基础上操作；PR-0413 合入后 invoker 更换不影响 stale/reload 机制

## Design

### 核心思路

不使用 event bus（过度工程化）或无条件 section 切换 reload（每次切换都有 FFI 开销），而是采用三步轻量方案：

1. **`DataChangeNotifier` 单例** — app 级 `ChangeNotifier`，任意 atom mutation 后调用 `notifyDataChanged()`
2. **Stale flag** — 各 controller 订阅通知，收到通知后仅设置 `_isStale = true`（不立即重载）
3. **Lazy reload on section mount** — page `initState` postframe 回调读取 stale flag，若为 true 则执行重载

这样 stale 检查在数据变更时同步完成，IO 开销（FFI 查询）仅在用户实际切换到该 section 时发生。

### DataChangeNotifier

```dart
/// 跨 feature atom 数据变更通知器。
///
/// 任何 atom CRUD/mutation 操作完成后，执行方调用 [notifyDataChanged()]。
/// 其他 feature controller 通过构造函数注入此实例并订阅，
/// 收到通知时将本地缓存标记为 stale；section 切换时若 stale 则重载。
///
/// 置于 lib/core/，满足 Rule E（跨 feature 基础设施不得放在 features/ 目录）。
class DataChangeNotifier extends ChangeNotifier {
  DataChangeNotifier._();

  static final DataChangeNotifier instance = DataChangeNotifier._();

  /// 通知所有订阅方：atom 数据已变更。
  ///
  /// 由执行 mutation 的 controller 在操作成功后调用。
  void notifyDataChanged() => notifyListeners();
}
```

**为何不用全局事件总线**：`ChangeNotifier` 订阅/取消订阅生命周期由 Flutter framework 管理，与 controller `dispose()` 自然对齐，无内存泄漏风险。

**为何不无条件切换刷新**：section 切换频繁时（notes → tasks → notes → ...），若无 mutation 则不必要发起 FFI 查询；stale flag 保证只在有变更时重载。

### TasksController 改造

```dart
class TasksController extends ChangeNotifier {
  TasksController({
    // ... 现有 invoker 参数 ...
    DataChangeNotifier? dataChangeNotifier,
  }) : _dataChangeNotifier = dataChangeNotifier ?? DataChangeNotifier.instance {
    // 订阅跨 feature 数据变更
    _dataChangeNotifier.addListener(_onExternalDataChanged);
  }

  final DataChangeNotifier _dataChangeNotifier;
  bool _isStale = false;

  bool get isStale => _isStale;

  void _onExternalDataChanged() {
    _isStale = true;
    // 不调用 notifyListeners() — stale 是内部标志，不需要重建 UI
  }

  /// 标记 stale 并重载（section 可见时由 page 调用）。
  Future<void> reloadIfStale() async {
    if (!_isStale) return;
    _isStale = false;
    await loadAll();
  }

  @override
  void dispose() {
    _dataChangeNotifier.removeListener(_onExternalDataChanged);
    super.dispose();
  }

  Future<bool> toggleStatus(String atomId, String? currentStatus) async {
    // ... 现有逻辑 ...
    if (/* 成功 */) {
      _dataChangeNotifier.notifyDataChanged(); // 通知其他 feature
    }
    return result;
  }

  Future<bool> createInboxItem(String content) async {
    // ... 现有逻辑 ...
    if (/* 成功 */) {
      _dataChangeNotifier.notifyDataChanged();
    }
    return result;
  }
}
```

`CalendarController` 和 `NotesCoordinator` 采用相同模式（`isStale` flag + `reloadIfStale()` + `dispose()` 中取消订阅 + mutation 后 `notifyDataChanged()`）。

### Page 层 Conditional Reload

以 `TasksPage` 为例（`CalendarPage`、`NotesPage` 同理）：

```dart
@override
void initState() {
  super.initState();
  _controller = widget.controller ?? TasksController();
  _ownsController = widget.controller == null;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // 替代原来的无条件 loadAll()：
    // 首次挂载时 _isStale 为 false，但 idle 状态需要初始加载
    if (_controller.isStale) {
      _controller.reloadIfStale();
    } else {
      _controller.loadAll(); // 首次进入 section 执行初始加载
    }
  });
}
```

**注意**：`TasksController` 首次创建时 `_isStale = false`，`loadAll()` 仍用于首次加载。若 controller 在 section 切换间保持存活（当前 `TasksPage` 每次 section 激活时重新 build，controller 随 page 创建），则 stale 路径在跨 feature 场景下生效。

### Rule E 合规性

`DataChangeNotifier` 置于 `lib/core/data_change_notifier.dart`。按 Rule E，`lib/core/` 基础设施免于 feature 间 import 限制，各 feature page/controller 直接 import `lib/core/data_change_notifier.dart` 合法。

### 开放决策

| 决策点 | 当前选择 | 备选 | 选择理由 |
|--------|---------|------|---------|
| stale 时不立即重载 | 是 | 收到通知即 reload | 避免后台 section 发起无效 FFI 查询 |
| `DataChangeNotifier` 为单例 | 是 | 通过 Provider/InheritedWidget 注入 | 当前无 DI 框架；单例 + 构造函数注入满足测试需求 |
| page 重建时重用 controller | 否（当前每次重建） | 提升 controller 到 app 级 | 提升属于更大范围重构，本 PR 保持最小变更 |

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Dart | 新增 `DataChangeNotifier` 类 | `apps/lazynote_flutter/lib/core/data_change_notifier.dart` | S | — |
| T2 | Dart | `TasksController` 订阅 DataChangeNotifier，添加 `_isStale` / `reloadIfStale()` / `dispose()` 取消订阅，mutation 后触发通知 | `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart` | S | T1 |
| T3 | Dart | `CalendarController` 同上改造 | `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart` | S | T1 |
| T4 | Dart | `NotesCoordinator`（`_NotesCoordinatorImpl`）同上改造 | `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` | S | T1 |
| T5 | Dart | `TasksPage` conditional reload（`initState` postframe 改为 `reloadIfStale` + 首次 `loadAll` 兼容） | `apps/lazynote_flutter/lib/features/tasks/tasks_page.dart` | XS | T2 |
| T6 | Dart | `CalendarPage` conditional reload | `apps/lazynote_flutter/lib/features/calendar/calendar_page.dart` | XS | T3 |
| T7 | Dart | `NotesPage` conditional reload | `apps/lazynote_flutter/lib/features/notes/notes_page.dart` | XS | T4 |
| T8 | Dart | `DataChangeNotifier` 单元测试：订阅/通知/取消订阅生命周期 | `apps/lazynote_flutter/test/core/data_change_notifier_test.dart` | S | T1 |
| T9 | Dart | `TasksController` 测试：stale flag 翻转、reloadIfStale 触发 reload、dispose 取消订阅、mutation 后通知 | `apps/lazynote_flutter/test/tasks_controller_stale_test.dart` | M | T2 |
| T10 | Dart | `CalendarController` 测试：stale / reloadIfStale / 通知 | `apps/lazynote_flutter/test/calendar_controller_stale_test.dart` | S | T3 |
| T11 | Dart | `NotesCoordinator` 测试：note create/update 后发出通知，外部通知导致 stale | `apps/lazynote_flutter/test/notes_coordinator_stale_test.dart` | S | T4 |

## Planned File Changes

- `[add]` apps/lazynote_flutter/lib/core/data_change_notifier.dart (DataChangeNotifier 单例定义)
- `[edit]` apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart (添加 DataChangeNotifier 订阅、_isStale、reloadIfStale、dispose、mutation 通知)
- `[edit]` apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart (同上)
- `[edit]` apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart (同上，note create/update 后 notifyDataChanged)
- `[edit]` apps/lazynote_flutter/lib/features/tasks/tasks_page.dart (initState postframe：首次 loadAll / stale reloadIfStale 兼容)
- `[edit]` apps/lazynote_flutter/lib/features/calendar/calendar_page.dart (同上)
- `[edit]` apps/lazynote_flutter/lib/features/notes/notes_page.dart (同上)
- `[add]` apps/lazynote_flutter/test/core/data_change_notifier_test.dart
- `[add]` apps/lazynote_flutter/test/tasks_controller_stale_test.dart
- `[add]` apps/lazynote_flutter/test/calendar_controller_stale_test.dart
- `[add]` apps/lazynote_flutter/test/notes_coordinator_stale_test.dart

## Verification

### CI gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# 验证 DataChangeNotifier 定义位于 lib/core/（Rule E 合规）
grep -rn "^class DataChangeNotifier" apps/lazynote_flutter/lib/ --include="*.dart"
# 预期：1 匹配，路径为 lib/core/data_change_notifier.dart

# 验证 DataChangeNotifier 未定义在 features/ 下
grep -rn "^class DataChangeNotifier" apps/lazynote_flutter/lib/features/ --include="*.dart"
# 预期：零匹配

# 验证三个 controller 均订阅 DataChangeNotifier
grep -rn "DataChangeNotifier" apps/lazynote_flutter/lib/features/ --include="*.dart"
# 预期：在 tasks_controller.dart、calendar_controller.dart、notes_coordinator_impl.dart 中各有匹配

# 验证 stale flag 和 reloadIfStale 方法定义
grep -rn "_isStale\|reloadIfStale" apps/lazynote_flutter/lib/features/ --include="*.dart"
# 预期：三个 controller 文件各有匹配

# 验证 dispose() 中取消订阅（防内存泄漏）
grep -rn "removeListener.*_onExternalDataChanged" apps/lazynote_flutter/lib/features/ --include="*.dart"
# 预期：至少 3 匹配

# 验证 mutation 操作后调用 notifyDataChanged
grep -rn "notifyDataChanged" apps/lazynote_flutter/lib/features/ --include="*.dart"
# 预期：至少 5 匹配（toggleStatus、createInboxItem、createEvent、updateEvent、note create/update 各一）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| dispose() 未取消订阅导致内存泄漏 | MEDIUM | 各 controller `dispose()` 调用 `removeListener`；测试覆盖 dispose 后不再收到通知 |
| stale flag 竞争：section 加载中收到新通知，reload 完成后 stale 被清除，导致丢通知 | LOW | `reloadIfStale()` 在 reload 前清除 flag（先清再请求），保证下次 mount 时若有新变更仍会 reload；此时序在 PR-0413 迁移后不变 |
| PR-0413 迁移后 `QueryAtomsInvoker` 替换分立 invoker，本 PR 的 stale 机制失效 | LOW | stale/reloadIfStale 机制不依赖具体 invoker；PR-0413 合入时只需确保 reload 入口函数签名不变（`loadAll()`/`loadWeek()`/`reloadNotes()`） |
| 首次 section 进入路径（idle 状态）与 stale reload 路径混淆 | LOW | `isStale` 初始为 false，`initState` 检测到 idle 状态时执行 `loadAll()`（首次）；stale 路径仅在收到 DataChangeNotifier 通知后触发 |

## Acceptance Criteria

- [ ] `DataChangeNotifier` 类定义于 `apps/lazynote_flutter/lib/core/data_change_notifier.dart`，不位于 `lib/features/` 下
- [ ] `TasksController` 在 `toggleStatus` 成功后调用 `notifyDataChanged()`
- [ ] `TasksController` 在 `createInboxItem` 成功后调用 `notifyDataChanged()`
- [ ] `CalendarController` 在 `createEvent` 成功后调用 `notifyDataChanged()`
- [ ] `CalendarController` 在 `updateEvent` 成功后调用 `notifyDataChanged()`
- [ ] `NotesCoordinator` 在 note create 成功后调用 `notifyDataChanged()`
- [ ] `NotesCoordinator` 在 note update 成功后调用 `notifyDataChanged()`
- [ ] `TasksController`、`CalendarController`、`NotesCoordinator` 收到 DataChangeNotifier 通知后 `isStale` 变为 `true`
- [ ] `TasksController.reloadIfStale()` 在 `isStale = true` 时触发 `loadAll()`，调用后 `isStale` 重置为 `false`
- [ ] `TasksController.reloadIfStale()` 在 `isStale = false` 时不触发 FFI 查询
- [ ] `CalendarController.reloadIfStale()` 行为与 `TasksController` 对称（stale → reload → reset）
- [ ] `NotesCoordinator` stale 行为与上述对称
- [ ] 各 controller `dispose()` 后不再响应 DataChangeNotifier 通知（测试验证无内存泄漏路径）
- [ ] `flutter analyze` 零 warning
- [ ] `flutter test` 全绿（包含 stale 相关新增测试）
- [ ] `dart run ../../tools/ci/architecture_check.dart` 通过
- [ ] PR spec Status updated to Merged
