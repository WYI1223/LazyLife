# v0.3 Flutter UI 线程阻塞风险扫描报告（Hitlist）

---

## 0. 文档信息

| 项目 | 内容 |
|------|------|
| 报告日期 | 2026-03-04 |
| 扫描范围 | `apps/lazynote_flutter/lib/**`、`crates/lazynote_ffi/src/api.rs` |
| 目标 | 揪出不该出现在 UI 线程的逻辑：Sync FFI、主线程重计算、State-View 重耦合 |
| 扫描方式 | 静态扫描（`rg`）+ 热点源码复核（行号级） |

---

## 1. 扫描结论（先给结论）

1. **Sync FFI 导出共 5 个**，目前未发现“同步直连 SQLite / DAG 全量遍历 / 全量读取”的硬违规。  
2. **Flutter 侧存在明确的 UI 线程重计算热点**，其中 5 处达到高风险（可直接造成卡顿或帧抖动）。  
3. **State-View 耦合在部分 Widget `build()` 路径中偏重**，已出现 `build()` 内副作用触发和运行时数据组装。
4. **`compute()/Isolate` 使用次数为 0**（全仓库无命中），重计算尚未隔离到 worker isolate。

---

## 2. 证据汇总（全局指标）

- Sync FFI 导出：5 处（`#[flutter_rust_bridge::frb(sync)]`）
- Async FFI 导出：24 处（`#[flutter_rust_bridge::frb]`）
- `.sort()`：6 处
- `.where()`：10 处
- `jsonDecode()`：4 处
- `compute()/Isolate`：0 处

---

## 3. 重构 Hitlist（按“致命程度/阻塞风险”排序）

### P0-1. `build()` 内触发副作用刷新（最高优先级）
- 文件：`apps/lazynote_flutter/lib/features/notes/note_explorer.dart:469`
- 证据：`build()` 的 `NotesListPhase.success` 分支内直接 `unawaited(_reloadRootTree(force: false));`
- 风险：
  - `build()` 触发副作用，容易形成“重建 -> 异步刷新 -> 状态变更 -> 再重建”抖动链。
  - 数据量增大或树状态频繁变化时，UI 帧稳定性明显下降。
- 处置：
  - 移出 `build()`；仅在 `initState()/didUpdateWidget()` 或 controller 的显式事件流中触发。

### P0-2. 日历周视图在 `build()` 路径做事件布局计算
- 文件：`apps/lazynote_flutter/lib/features/calendar/week_grid_view.dart:191`, `:210-277`
- 证据：`..._buildEventBlocks(...)` 在构建栈里执行；内部双层循环 `events * 7` + 大量 `DateTime` 计算/裁剪。
- 风险：
  - 事件量增长时，build 开销线性放大，滚动/切周容易掉帧。
- 处置：
  - 下沉到 controller（预计算 `EventBlockVM/RecordMap`），或下沉 Rust Core。
  - 若暂不下沉 Rust，至少改为 `compute()` 异步投影。

### P0-3. Workspace 子树投影在 Dart 主线程做全量 BFS + 排序
- 文件：`apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart:98-209`, `:227`
- 证据：
  - `Queue` BFS 拉取整棵子树（`while (pendingParentIds.isNotEmpty)`）。
  - 生成 `projectedRows` 并排序（`:189`），legacy 路径再次排序（`:227`）。
- 风险：
  - 子树规模大时，主 isolate 承担遍历 + 组装 + 排序，属于典型 UI 线程重计算。
- 处置：
  - 直接下沉 Rust：新增“已投影 children”查询 API，Flutter 只接收 `RecordMap`。
  - 过渡方案：在 Dart 用 `compute()` 做投影与排序。

### P1-4. Move Target 选项加载在 Widget 层做 BFS 组装
- 文件：`apps/lazynote_flutter/lib/features/notes/note_explorer.dart:1653-1700`
- 证据：在 Widget 私有方法中循环请求 `listWorkspaceChildren`，并组装/去重/过滤。
- 风险：
  - 虽为异步 I/O，但树深时 UI 交互等待明显；且逻辑位置错误（View 层承担查询编排）。
- 处置：
  - 上移到 core/workspace service 或 Rust use-case，一次性返回可用目标列表。

### P1-5. 日志面板在 build 路径做大文本切分 + 每行 regex 解析
- 文件：
  - `apps/lazynote_flutter/lib/features/diagnostics/debug_logs_panel.dart:325`, `:334-335`, `:470`
  - `apps/lazynote_flutter/lib/features/diagnostics/log_line_meta.dart:41-141`
- 证据：
  - `LineSplitter().convert(snapshot.tailText)` 在 UI 构建路径。
  - 每行 `_LogLineRow.build()` 都调用 `LogLineMeta.parse`（多正则分支匹配）。
- 风险：
  - tail 行数大时会造成明显构建抖动。
- 处置：
  - 日志读取后即完成 parse/cache；UI 仅渲染已解析行。
  - 必要时把 parse 放 `compute()`。

### P2-6. ExplorerTreeState 在主线程对 children 排序
- 文件：`apps/lazynote_flutter/lib/features/notes/explorer_tree_state.dart:134-141`
- 风险：中等。大树分支时排序仍可能抖动。
- 处置：Rust 侧按稳定规则返回有序列表，Flutter 不再排序。

### P2-7. 启动关键阶段的 JSON decode 在主 isolate
- 文件：
  - `apps/lazynote_flutter/lib/core/settings/local_settings_store.dart:91`, `:198`, `:283`
  - `apps/lazynote_flutter/lib/core/editor/layout_persistence.dart:118`
  - 调用链：`apps/lazynote_flutter/lib/main.dart:23`, `:56-79`
- 风险：中等。当前文件通常较小，但属于首帧前关键路径，规模失控会拖慢启动。
- 处置：
  - 限制配置文件上限；超限降级为异步后台恢复。
  - 预留 `compute()`/分段解析策略。

### P2-8. Sync FFI 现状（当前未踩“死罪”，但有演进风险）
- 文件：`crates/lazynote_ffi/src/api.rs:43`, `:54`, `:70`, `:84`, `:144`
- 当前 sync 导出：`ping/core_version/init_logging/configure_entry_db_path/log_dart_event`
- 调用点：
  - `apps/lazynote_flutter/lib/core/rust_bridge.dart:402`, `:310`, `:454-455`
  - `apps/lazynote_flutter/lib/core/diagnostics/dart_event_logger.dart:34`, `:68`
- 判定：
  - 目前未见 sync 直连 DB 重查询或 DAG 全量遍历。
  - 但 `init_logging/log_dart_event` 若后续扩展为重 I/O，需立刻异步化。

---

## 4. 三类违规的标准化重构模板

### 模板 A：Sync FFI -> 非阻塞异步 FFI（Rust Runtime 承载）

适用：任何可能触发 DB/I/O/大遍历的 FFI 调用。

```rust
// crates/lazynote_ffi/src/api.rs
#[flutter_rust_bridge::frb]
pub async fn workspace_list_children_scoped(req: WorkspaceChildrenRequest) -> WorkspaceChildrenResponse {
    match tokio::task::spawn_blocking(move || {
        let conn = open_db(resolve_entry_db_path())?;
        let repo = SqliteTreeRepository::new(&conn);
        let svc = TreeService::new(repo);
        svc.list_children_scoped(req)
    }).await {
        Ok(Ok(data)) => WorkspaceChildrenResponse::ok(data),
        Ok(Err(e)) => WorkspaceChildrenResponse::err("workspace_query_failed", e.to_string()),
        Err(e) => WorkspaceChildrenResponse::err("runtime_join_failed", e.to_string()),
    }
}
```

```dart
// Flutter controller/service
final resp = await rustApi.workspaceListChildrenScoped(req: req);
if (!resp.ok) {
  // 错误处理
}
state = state.copyWith(children: resp.data ?? const []);
```

落地规则：
- Flutter 侧不再触碰同步重调用。
- Rust FFI 仅做 envelope 和 runtime 编排，业务逻辑在 Core service/repo。

### 模板 B：主线程重计算 -> 下沉 Rust 或 `compute()`

适用：数组排序/过滤、事件布局投影、日志大文本解析。

```dart
// 1) 顶层纯函数（compute 需要）
List<EventBlockVm> projectEventBlocks(ProjectInput input) {
  final out = <EventBlockVm>[];
  for (final e in input.events) {
    // 纯计算：裁剪、分段、坐标投影
  }
  return out;
}

// 2) Controller 中异步计算
Future<void> rebuildWeekBlocks(ProjectInput input) async {
  final blocks = await compute(projectEventBlocks, input);
  _weekBlocks = blocks; // 归一化 RecordMap/VM
  notifyListeners();
}

// 3) Widget build 仅渲染
Widget build(BuildContext context) => WeekGrid(blocks: controller.weekBlocks);
```

优先级建议：
- 数据查询/投影能 Rust 化就优先 Rust。
- 纯 Dart UI 计算先 `compute()` 过渡。

### 模板 C：State-View 解耦（build 零副作用）

适用：在 `build()` 内做请求触发、数据拼装、复杂条件分支。

```dart
class ExplorerController extends ChangeNotifier {
  RecordMap _vm = const RecordMap.empty();
  bool _bootstrapped = false;

  Future<void> bootstrapIfNeeded() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    _vm = await _service.loadExplorerVm();
    notifyListeners();
  }

  RecordMap get vm => _vm;
}

class NoteExplorer extends StatefulWidget { /* ... */ }

class _NoteExplorerState extends State<NoteExplorer> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.bootstrapIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.controller.vm;
    return ExplorerTree(vm: vm); // 仅渲染，无副作用
  }
}
```

---

## 5. 附录 A：`.sort/.where/jsonDecode` 全量命中与分级

### 高风险（应优先改）
- `apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart:189` (`sort`)
- `apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart:227` (`sort`)
- `apps/lazynote_flutter/lib/features/notes/explorer_tree_state.dart:135` (`sort`)
- `apps/lazynote_flutter/lib/features/diagnostics/debug_logs_panel.dart:325`（行切分）
- `apps/lazynote_flutter/lib/features/diagnostics/debug_logs_panel.dart:470`（每行 parse）

### 中风险（关键路径/规模可增长）
- `apps/lazynote_flutter/lib/core/editor/layout_persistence.dart:118` (`jsonDecode`)
- `apps/lazynote_flutter/lib/core/settings/local_settings_store.dart:91` (`jsonDecode`)
- `apps/lazynote_flutter/lib/core/settings/local_settings_store.dart:198` (`jsonDecode`)
- `apps/lazynote_flutter/lib/core/settings/local_settings_store.dart:283` (`jsonDecode`)

### 低风险（局部集合，当前规模小）
- `apps/lazynote_flutter/lib/features/entry/command_parser.dart:119`
- `apps/lazynote_flutter/lib/app/ui_slots/ui_slot_registry.dart:60`, `:80`
- `apps/lazynote_flutter/lib/core/debug/log_reader.dart:136`
- `apps/lazynote_flutter/lib/core/editor/editor_group_model.dart:187`
- `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart:322`
- `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart:324`, `:327`, `:330`
- `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart:344`
- `apps/lazynote_flutter/lib/features/notes/managers/note_tag_manager.dart:204`
- `apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart:71`
- `apps/lazynote_flutter/lib/core/editor/layout_persistence.dart:173`

---

## 6. 附录 B：Sync FFI 全量清单

- `crates/lazynote_ffi/src/api.rs:44` `ping()`
- `crates/lazynote_ffi/src/api.rs:55` `core_version()`
- `crates/lazynote_ffi/src/api.rs:71` `init_logging(...)`
- `crates/lazynote_ffi/src/api.rs:85` `configure_entry_db_path(...)`
- `crates/lazynote_ffi/src/api.rs:145` `log_dart_event(...)`

补充：DB/业务查询接口均为 async 导出（`#[flutter_rust_bridge::frb]`），例如：
- `workspace_list_children` `api.rs:887`
- `notes_list` `api.rs:788`
- `tasks_list_today` `api.rs:1605`
- `calendar_list_by_range` `api.rs:1799`

---

## 7. 建议执行顺序（两周内可落地）

1. 先修 P0-1（`build()` 副作用）+ P0-2（日历事件投影）。
2. 再修 P0-3（workspace 子树投影下沉 Rust）。
3. 之后处理 P1-5（日志解析缓存/compute）与 P1-4（move-target 查询上移 service）。
4. 最后收尾 P2 项：启动 JSON 路径限流与 Sync FFI 守门（禁止引入重逻辑）。

