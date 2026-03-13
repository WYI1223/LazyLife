# PR-0413: Flutter Features 适配 + 旧 FFI 移除（Contract 阶段）

- Proposed title: `feat(features): tasks calendar migration and legacy FFI removal`
- Status: Draft

## Goal

全部 Flutter 消费方迁移到新接口（Tasks/Calendar/Notes/Tag Panel/Entry Search/Editor），Explorer 内部分层重构（DI-17 Q3），移除 synthetic uncategorized 逻辑，删除 `workspace_tree_children_loader.dart`，移除全部 15 个旧 FFI 函数（expand-contract 的 contract 阶段）。代码库净减。

前置条件：PR-0412（需要 WorkspaceTreeService B+ 已就位）

## Execution Contract (Canonical Inputs)

Shared promotion register:

- `docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md`
- This PR must leave evidence sufficient for `CPR-001`, but may not publish carrier text directly.

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md` Q3/Q5-Q6 | 全部消费方适配、Explorer 内部分层、synthetic 移除 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q6 | 旧 FFI 清理清单 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0413 行）、Q2（A+ R2/R4 contract 规则）、Q4（清理验证 gate） | PR 定位、迁移策略、清理验证要求 |
| 附录 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` 附录 A | 15 个旧 FFI 函数完整清单 + 验证命令 |
| 规范源 | `docs/api/ffi-contracts.md` | 需更新：移除旧函数契约 |
| Handoff workflow | `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` | `DOC-023 / DI-15` + `DOC-024 / DI-16` + `DOC-025 / DI-17` + `DOC-026 / DI-18` 的交接合同；本 PR 负责更新 `flutter-features` ledger，同时更新 `execution-order`、`cutover-cleanup`、`api-doc-ownership`、`verification-gates`、`no-move-ci-enforcement`、以及 `legacy-ffi-removal` rows，并显式消费 `OI-035` / `OI-036` / `OI-038`、`OI-040` / `OI-041` / `OI-042` / `OI-043` / `OI-044`、以及 `OI-045` / `OI-046` / `OI-047` / `OI-048` / `OI-049` / `OI-050` 中的 feature-consumer与contract-stage部分，不得直接发布 ADR / ruling / topic-map carrier |

## Scope

In scope:
- TasksController 迁移：mock WorkspaceTreeService + QueryAtomsInvoker
- CalendarController 迁移：query helper 适配
- **QueryAtomsInvoker** 封装 + **query helper**（`query_atoms` FFI 的 Dart 消费层入口，供全部 feature controller 使用）
- Notes/Tag Panel invoker 迁移（`notes_list` → `query_atoms` via QueryAtomsInvoker）（DI-16 Q6.1）
- Entry Search 迁移（`entry_search` → `query_atoms` via QueryAtomsInvoker）（DI-16 Q6.1）
- Editor/Resolver 迁移（`note_get` → `atom_get`）（DI-16 Q6.3）
- Explorer 内部分层：基础层/特化层拆分，禁止反向耦合（DI-17 Q3）
- synthetic uncategorized 全量删除（8 文件 48 处引用）
- 删除 `workspace_tree_children_loader.dart`
- 移除 15 个旧 FFI 函数（附录 A 完整清单）
- FRB 绑定重生成
- 旧 FFI 引用的测试代码同步迁移或删除
- 更新 `docs/api/ffi-contracts.md`（移除旧函数）
- 清理验证 gate（grep 零匹配、文件删除断言、uncategorized 清零）
- 更新 `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` 中 `flutter-features`、`execution-order`、`cutover-cleanup`、`api-doc-ownership`、`verification-gates`、`no-move-ci-enforcement`、以及 `legacy-ffi-removal` rows，显式对齐 `OI-035` / `OI-036` / `OI-038`、`OI-040` / `OI-041` / `OI-042` / `OI-043` / `OI-044`、以及 `OI-045` / `OI-046` / `OI-047` / `OI-048` / `OI-049` / `OI-050`，写入 landed/partial 状态与证据路径

Out of scope:
- Rust Core 层变更（PR-0408~0410 已完成）
- Guard/FFI 新增（PR-0411 已完成）
- WorkspaceTreeService 基础设施（PR-0412 已完成）
- 直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `docs/architecture/adr/topic-map.md`

## Design

### 总体结构

本 PR 是 expand-contract 的 **contract 阶段**。PR-0411 expand 阶段保留的旧 FFI 薄 wrapper，在本 PR 中全部移除。Flutter 消费方完成迁移后，旧接口不再有调用方，代码库净减 ~300 行。

设计来源：DI-17 Q3/Q5/Q6（消费方适配 + Explorer 分层 + synthetic 移除），DI-16 Q6.1/Q6.2/Q6.3（旧 FFI 清单），DI-18 Q2 A+（contract 完整移除规则 R2/R4）。

### 1. QueryAtomsInvoker — 统一查询 Dart 消费入口

所有 feature controller 的数据查询统一通过一个 typedef 入口：

```dart
/// 统一查询 FFI 消费入口（query_atoms 的 Dart wrapper）。
/// 所有 feature controller 注入此 typedef，不再注入分立查询 invoker。
typedef QueryAtomsInvoker =
    Future<ScopedQueryResponse> Function({
      required FfiCallerContext caller,
      required FfiScopedAtomQuery descriptor,
      required FfiProjectionMode projection,
    });
```

配套 `QueryDescriptors` 工厂类（`lib/core/query_descriptors.dart`），提供各场景的参数模板（DI-16 Q6.0 C3：只做参数填充，不含业务逻辑）：

```dart
class QueryDescriptors {
  static FfiScopedAtomQuery tasksInbox(String folderId) => FfiScopedAtomQuery(
        folderId: folderId,
        timeFilter: FfiTimeFilterKind.timeless,
        statusFilter: FfiStatusFilterKind.activeOnly,
        sort: FfiSortSpec.updatedAtDesc,
        includeOverdueDeadlines: false,
        includePath: false,
      );

  static FfiScopedAtomQuery tasksToday(String folderId, int bodMs, int eodMs) =>
      FfiScopedAtomQuery(
        folderId: folderId,
        timeFilter: FfiTimeFilterKind.range,
        timeStartMs: bodMs,
        timeEndMs: eodMs,
        statusFilter: FfiStatusFilterKind.activeOnly,
        sort: FfiSortSpec.startAtAsc,
        includeOverdueDeadlines: true, // 补偿 overdue T1（DI-16 Q1.4）
        includePath: false,
      );

  static FfiScopedAtomQuery tasksUpcoming(String folderId, int eodMs) => ...;
  static FfiScopedAtomQuery calendarRange(String folderId, int startMs, int endMs) => ...;
  static FfiScopedAtomQuery notesList(String folderId, {String? tag}) => ...;
  static FfiScopedAtomQuery textSearch(String folderId, String text, {String? kind}) => ...;
}
```

### 2. Feature Controller 迁移方案

#### 2.1 迁移对照表

| Controller | 当前 invoker | 迁移后 invoker | 删除的 typedef | 保留的 typedef |
|------------|-------------|---------------|----------------|----------------|
| `TasksController` | `TasksListInboxInvoker` / `TodayInvoker` / `UpcomingInvoker` | `QueryAtomsInvoker` | 3 个分立查询 invoker | `AtomUpdateStatusInvoker`、`InboxCreateInvoker` |
| `CalendarController` | `CalendarListByRangeInvoker` | `QueryAtomsInvoker` | `CalendarListByRangeInvoker` | `CalendarUpdateEventInvoker`（重命名适配 `atom_update_time`） |
| `NoteListManager` | `NoteListNotesListInvoker`、`NoteListNoteGetInvoker` | `QueryAtomsInvoker`（列表）、`AtomGetInvoker`（单条） | `NoteListNotesListInvoker` | `AtomGetInvoker` |
| `SingleEntryController` | `EntrySearchInvoker`、`EntryCreate*Invoker` × 3 | `QueryAtomsInvoker`（搜索）、`AtomCreateInvoker`（创建） | `EntrySearchInvoker`、`EntryCreate*Invoker` × 3 | `AtomCreateInvoker` |
| `EditorShellService` | `loadContentFn`（间接调 `note_get`） | `loadContentFn`（间接调 `atom_get`） | — | — |

#### 2.2 TasksController 迁移

当前构造函数接收 3 个分立 invoker，迁移后统一为 `QueryAtomsInvoker` + `WorkspaceTreeService` 引用（DI-17 Q5）：

```dart
class TasksController extends ChangeNotifier {
  TasksController({
    required WorkspaceTreeService treeService,
    required String workspaceId,
    required QueryAtomsInvoker queryAtoms,
    required AtomUpdateStatusInvoker statusInvoker,
    required InboxCreateInvoker createInvoker,
  });

  Future<void> _loadInbox() async {
    final folderId = _treeService.getSystemNodeId(_workspaceId, 'tasks');
    final resp = await _queryAtoms(
      caller: FfiCallerContext(workspaceId: _workspaceId),
      descriptor: QueryDescriptors.tasksInbox(folderId),
      projection: FfiProjectionMode.atom,
    );
  }
}
```

`folder_id` 每次查询前通过 `getSystemNodeId()` 同步取当前值，避免 `reassign_designated` 后陈旧。

#### 2.3 CalendarController / Notes / Entry / Editor 迁移

- **CalendarController**：`CalendarListByRangeInvoker` → `QueryAtomsInvoker`，`CalendarUpdateEventInvoker` typedef 重命名对齐 `atom_update_time`
- **NoteListManager**：`NoteListNotesListInvoker` → `QueryAtomsInvoker`；`NoteListNoteGetInvoker` → `AtomGetInvoker`
- **SingleEntryController**：`EntrySearchInvoker` → `QueryAtomsInvoker`（`textQuery` 参数）；3 个 `EntryCreate*Invoker` → `AtomCreateInvoker`
- **EditorShellService**：`NotesCoordinator` 注入的 `loadContentFn` 闭包改调 `atom_get`

### 3. Explorer 内部分层（DI-17 Q3）

| 层 | 文件（重构后） | 职责 | 允许引用 |
|----|--------------|------|---------|
| **基础层** | `explorer_tree_item.dart`（重构） | 缩进行布局、图标/文本渲染、loading/error/empty 状态 | 无 Explorer 特有类型 |
| **特化层** | `explorer_tree_builder.dart`、`explorer_tree_builder_types.dart`（重构） | create/delete 按钮、drag wrapper、context menu、回调 slot | 基础层 + Explorer 回调类型 |

**反向耦合禁止**（DI-17 Q3 规则 2）：基础层不得 import `ExplorerTreeCallbacks`、`ExplorerContextMenu` 等特化层类型。特化行为通过回调/slot 注入基础层。

### 4. Synthetic Uncategorized 全量删除（DI-17 Q6）

#### 4.1 删除 `workspace_tree_children_loader.dart`

该文件（378 行）全部为 synthetic 逻辑，整个文件删除：

| 方法 | 删除理由 |
|------|---------|
| `_listProjectedUncategorizedChildren()` | BFS 遍历全树收集未引用 atom → Rust migration 自动挂 Inbox |
| `_decorateWorkspaceChildren()` | root 列表注入 synthetic folder → 真实 Inbox 由 Rust 返回 |
| `_fallbackWorkspaceChildren()` | 硬编码降级 → v0.4 树结构由 Rust 定义 |
| `_shouldUseWorkspaceTreeSyntheticFallback()` | FFI 初始化失败检测 → v0.4 不需要降级路径 |
| `_legacySyntheticUncategorizedChildren()` | FFI 不可用降级 → bootstrap 保证 FFI 可用 |

#### 4.2 8 个受影响文件 — 引用清理清单

| 文件 | 清理内容 | 引用数 |
|------|---------|--------|
| `workspace_tree_children_loader.dart` | **整个文件删除** | — |
| `explorer_tree_state.dart` | 删除 `_uncategorizedNodeId` 常量、`_kindRank` 中 uncategorized 分支 | ~8 |
| `workspace_tree_service.dart` | 删除 `_uncategorizedFolderNodeId` 常量及特殊路由 | ~5 |
| `note_explorer.dart` | 删除 `_defaultUncategorizedFolderId` 常量 | ~4 |
| `explorer_tree_builder.dart` | 删除 synthetic root 注入逻辑 | ~6 |
| 4 个测试文件 | 删除 synthetic mock 数据，补充真实 Inbox folder 用例 | ~27 |

**合计**：8 个文件（含测试），~48 处引用，预计净减 ~300 行（DI-17 Q6.2）。

### 5. 旧 FFI 函数移除（DI-18 附录 A）

| # | 旧函数名 | 类别 | 替代 |
|---|----------|------|------|
| 1 | `tasks_list_inbox` | 查询 | `query_atoms` |
| 2 | `tasks_list_today` | 查询 | `query_atoms` |
| 3 | `tasks_list_upcoming` | 查询 | `query_atoms` |
| 4 | `calendar_list_by_range` | 查询 | `query_atoms` |
| 5 | `notes_list` | 查询 | `query_atoms` |
| 6 | `entry_search` | 查询 | `query_atoms` |
| 7 | `atoms_list_timed` | 查询 | `query_atoms` |
| 8 | `entry_create_note` | 创建 | `atom_create` |
| 9 | `entry_create_task` | 创建 | `atom_create` |
| 10 | `entry_schedule` | 创建 | `atom_create` |
| 11 | `note_create` | 创建 | `atom_create` |
| 12 | `note_update` | 写入 | `atom_update_content` |
| 13 | `note_set_tags` | 写入 | `atom_set_tags` |
| 14 | `calendar_update_event` | 写入 | `atom_update_time` |
| 15 | `note_get` | 读取 | `atom_get` |

移除后运行 `scripts/gen_bindings.ps1` 重生成 FRB 绑定。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Dart | TasksController 迁移到新 invoker | `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart` | TBD | — |
| T2 | Dart | CalendarController 迁移到新 invoker | `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart` | TBD | — |
| T3 | Dart | Notes/Tag Panel invoker 迁移 | `apps/lazynote_flutter/lib/features/notes/managers/note_list_manager.dart` | TBD | — |
| T4 | Dart | Entry Search invoker 迁移 | `apps/lazynote_flutter/lib/features/entry/single_entry_controller.dart` | TBD | — |
| T5 | Dart | Editor/Resolver invoker 迁移 | `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` | TBD | — |
| T6 | Dart | Explorer 内部分层（基础层/特化层） | `apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart`, `explorer_tree_builder.dart` | TBD | — |
| T7 | Dart | synthetic uncategorized 全量删除 | 8 文件（详见 Planned File Changes） | TBD | — |
| T8 | Dart | 删除 workspace_tree_children_loader.dart | `apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart` | TBD | — |
| T9 | FFI | 移除 15 个旧 FFI 函数 | `crates/lazynote_ffi/src/api.rs` | TBD | T1-T5 |
| T10 | FFI | FRB 绑定重生成 | `scripts/gen_bindings.ps1` | TBD | T9 |
| T11 | Dart | 测试更新（controller mock + 负向测试） | 8 test files（详见 Planned File Changes） | TBD | T1-T8 |
| T12 | Dart | 清理验证 gate 执行 | — | TBD | T1-T10 |
| T13 | Docs | 更新 ffi-contracts.md（移除旧函数） | `docs/api/ffi-contracts.md` | TBD | T9 |

## Planned File Changes

- `[edit]` apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart (3 个分立查询 invoker → QueryAtomsInvoker)
- `[edit]` apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart (CalendarListByRangeInvoker → QueryAtomsInvoker)
- `[edit]` apps/lazynote_flutter/lib/features/notes/managers/note_list_manager.dart (NoteListNotesListInvoker → QueryAtomsInvoker)
- `[edit]` apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart (loadContentFn 改调 atom_get)
- `[edit]` apps/lazynote_flutter/lib/features/entry/single_entry_controller.dart (EntrySearchInvoker + EntryCreate*Invoker → QueryAtomsInvoker + AtomCreateInvoker)
- `[add]` apps/lazynote_flutter/lib/core/query_descriptors.dart (QueryDescriptors 工厂类)
- `[edit]` apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart (提取纯渲染基础层)
- `[edit]` apps/lazynote_flutter/lib/features/notes/explorer_tree_builder.dart (保留特化层 + 删除 synthetic 注入)
- `[edit]` apps/lazynote_flutter/lib/features/notes/explorer_tree_builder_types.dart (特化层类型边界)
- `[edit]` apps/lazynote_flutter/lib/features/notes/explorer_tree_state.dart (删除 _uncategorizedNodeId + _kindRank uncategorized 分支)
- `[edit]` apps/lazynote_flutter/lib/features/notes/note_explorer.dart (删除 _defaultUncategorizedFolderId)
- `[edit]` apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart (删除 _uncategorizedFolderNodeId)
- `[delete]` apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart (378 行全删)
- `[edit]` crates/lazynote_ffi/src/api.rs (移除 15 个旧 FFI 函数)
- `[regen]` crates/lazynote_ffi/src/frb_generated.rs (FRB 自动生成)
- `[regen]` apps/lazynote_flutter/lib/core/bindings/ (FRB 自动生成)
- `[edit]` apps/lazynote_flutter/test/tasks_page_test.dart (mock 替换为 QueryAtomsInvoker)
- `[edit]` apps/lazynote_flutter/test/calendar_page_test.dart (mock 替换)
- `[edit]` apps/lazynote_flutter/test/calendar_event_dialog_test.dart (mock 替换)
- `[edit]` apps/lazynote_flutter/test/note_explorer_tree_test.dart (synthetic mock → 真实 Inbox folder)
- `[edit]` apps/lazynote_flutter/test/notes_controller_workspace_tree_guards_test.dart (synthetic mock → 真实 Inbox folder)
- `[edit]` apps/lazynote_flutter/test/note_explorer_workspace_delete_test.dart (synthetic mock → 真实 Inbox folder)
- `[edit]` apps/lazynote_flutter/test/workspace_contract_smoke_test.dart (删除 synthetic assert)
- `[edit]` apps/lazynote_flutter/test/workspace_integration_flow_test.dart (删除 synthetic assert)
- `[edit]` docs/api/ffi-contracts.md (移除 15 个旧函数契约)

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd ../apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification（清理验证 gate）

```bash
# 旧 FFI 函数名零匹配（附录 A 完整清单）
grep -rn "tasks_list_inbox\|tasks_list_today\|tasks_list_upcoming\|calendar_list_by_range\|notes_list\|entry_search\|atoms_list_timed\|entry_create_note\|entry_create_task\|entry_schedule\|note_create\|note_update\|note_set_tags\|calendar_update_event\|note_get" crates/ apps/ --include="*.rs" --include="*.dart"
# 预期：零匹配

# 删除文件验证
test ! -f apps/lazynote_flutter/lib/core/workspace/workspace_tree_children_loader.dart
# 预期：文件不存在

# uncategorized 清零
grep -rn "uncategorized\|synthetic" apps/ --include="*.dart" | grep -v "test" | grep -v "//"
# 预期：零匹配（排除测试文件和注释）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 遗漏旧 FFI 引用导致编译失败 | MEDIUM | 清理验证 gate grep 零匹配 + `flutter analyze` |
| synthetic uncategorized 引用散布在非预期位置 | LOW | grep 全量扫描 + 48 处已在 DI-17 中识别 |
| FRB 重生成后类型不匹配 | MEDIUM | `flutter analyze` + `flutter test` 全覆盖 |

## Acceptance Criteria

- [ ] QueryAtomsInvoker 封装完成，作为 `query_atoms` FFI 的统一 Dart 消费入口
- [ ] TasksController 使用 WorkspaceTreeService + QueryAtomsInvoker 加载 section 数据
- [ ] CalendarController 使用新 query 接口
- [ ] Notes/Tag Panel 已迁移到 `query_atoms`（不再调用 `notes_list`）
- [ ] Entry Search 已迁移到 `query_atoms`（不再调用 `entry_search`）
- [ ] Editor/Resolver 已迁移到 `atom_get`（不再调用 `note_get`）
- [ ] Explorer 已拆分为基础层/特化层，无反向耦合（DI-17 Q3）
- [ ] synthetic uncategorized 逻辑不存在（负向测试：确认无 BFS 合成）
- [ ] `workspace_tree_children_loader.dart` 已删除
- [ ] 15 个旧 FFI 函数已从 `api.rs` 移除
- [ ] 清理验证：旧 FFI 函数名在代码文件（`.rs` + `.dart`）中零匹配
- [ ] 清理验证：uncategorized/synthetic 标识符在代码文件中零匹配
- [ ] FRB 绑定重生成后 `flutter analyze` 零 warning
- [ ] `docs/api/ffi-contracts.md` 已移除旧函数契约
- [ ] `cargo test --all` 全绿
- [ ] `flutter test` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `flutter-features` row 已更新为本 PR 的实际落地状态并附证据路径，且已显式覆盖 `OI-040` / `OI-041` / `OI-042` / `OI-043` / `OI-044`
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `execution-order` row 已更新为本 PR 的实际顺序与依赖落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `cutover-cleanup` row 已写明本 PR 覆盖的 contract 阶段 cleanup 责任并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `api-doc-ownership` row 已写明本 PR 覆盖的 API 文档清理责任并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `verification-gates` row 已写明本 PR 覆盖的 Flutter feature 测试与 cleanup gate 责任并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `no-move-ci-enforcement` row 已写明本 PR 对 no-move 规则与 `DI-21` CI handoff 的实际落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `legacy-ffi-removal` row 已写明本 PR 对 Appendix A 旧 FFI 清单的实际删除状态并附证据路径
- [ ] 本 PR 未直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `topic-map.md`
- [ ] PR spec Status updated to Merged
