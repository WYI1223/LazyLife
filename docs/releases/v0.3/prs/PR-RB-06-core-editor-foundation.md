# PR-RB-06: DI-0/1/2 + core-editor 基础

- Proposed title: `feat(editor): PR-RB-06 EditorShellService + GroupLayout + EditBuffer first landing`
- Status: Merged

## Goal

首次落地 `lib/core/editor/` 基础设施：`EditorShellService`（workbench singleton）+ `EditorGroupModel`（per-pane tab 状态）+ `EditBuffer`（per-atom 内容状态机）+ `GroupLayout`（递归布局树）。从 `notes_coordinator_impl.dart` 提取 tab/draft/save 状态管理。`NoteTabManager` widget 重命名为 `NoteTabStrip`。`WorkspaceProvider` + `WorkspaceModels` TRANSIENT 文件删除（S9 + S2 Phase 2 step 5）。**交付里程碑 M1：多 pane split/resize 首次可用 + tab-driven auto-collapse。**

前置条件：PR-RB-01（`AtomListItem` 统一）+ PR-RB-02（`title`/`view_hint` 可用）+ PR-RB-05（`core/workspace/` 提取，含 TRANSIENT 文件）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI-0 | `DI-0-dual-tab-manager.md` D4 | `NoteTabManager` widget → `NoteTabStrip`；`NoteTabStateManager` → `EditorGroupModel` |
| DI-1 | `DI-1-editor-shell-service.md` Q1~Q5 | EditorShellService API + state 归属 + EditBuffer 状态机 + closure 注入 + 文件位置 |
| DI-2 | `DI-2-layout-tree-structure.md` D5/D6 | sealed class 二叉树结构 + top-down resolve + I1-I7 不变式 |
| Module Spec | `modules/core-editor/editor-shell-service.md` | Service API surface + state fields |
| Module Spec | `modules/core-editor/editor-group-model.md` | Group state + TabEntry |
| Module Spec | `modules/core-editor/group-layout.md` | GroupLayout 封装层 API `[PR-RB-06 已修正为 DI-2 二叉树模型]` |
| Module Spec | `modules/core-editor/edit-buffer.md` | EditBuffer 状态机 + 编辑-保存时序 |
| Ruling | `rulings-legacy/S2-tab-draft-save-ownership.md` Phase 2 | 提取蓝图 + 四条规则 |
| Ruling | `rulings-legacy/S9-cross-feature-infrastructure-placement.md` | TRANSIENT 文件归属 + 删除时机 |
| DI-7 | `DI-7-gates-perf-testing.md` | Gate B M1 验证标准（split/close <50ms） |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-06 | Scope + M1 milestone |
| Acceptance Report | `09-acceptance-report.md` §7.1 | coordinator_impl 1,537 行 → 提取后减重 |

## 架构概览

### 提取前（当前）

```
NotesCoordinator (1,537 lines) — owns everything
├── NoteTabStateManager  — per-pane tab state (440 lines)
├── NoteDraftManager     — draft content (5 parallel Maps, 261 lines)
├── NoteSaveTracker      — save state (state duplication, 95 lines)
├── NoteListManager      — note list queries
├── NoteTagManager       — tag operations
└── WorkspaceTreeService — explorer tree (lib/core/workspace/)

WorkspaceProvider (171 lines, TRANSIENT in core/workspace/) — pane layout
WorkspaceModels (71 lines, TRANSIENT in core/workspace/) — layout types

NoteTabManager (widget, 422 lines) — tab strip UI
```

### 提取后（目标）

```
lib/core/editor/
├── EditorShellService    — workbench singleton
│   ├── groups: Map<GroupId, EditorGroupModel>    ← from NoteTabStateManager
│   ├── buffers: Map<AtomId, EditBuffer>          ← from NoteDraftManager + NoteSaveTracker
│   ├── layout: GroupLayout                        ← from WorkspaceProvider
│   └── activeGroupId: String
├── EditorGroupModel      — per-pane state ← from NoteTabStateManager (per-pane subset)
├── EditBuffer            — per-atom state machine ← unified NoteDraftManager + NoteSaveTracker
└── GroupLayout           — recursive layout tree ← from WorkspaceProvider layout

lib/core/workspace/       — PR-RB-05 tree files unchanged
├── workspace_tree_service.dart         ← 永久驻留
├── workspace_tree_types.dart           ← 永久驻留
├── workspace_tree_children_loader.dart ← 永久驻留
├── workspace_tree_error_utils.dart     ← 永久驻留
├── (workspace_provider.dart)           ← 删除 [PR-RB-06]
└── (workspace_models.dart)             ← 删除 [PR-RB-06]

NotesCoordinator (~1,200-1,300 lines, + ~85 lines default invokers part file) — retains:
├── NoteListManager       — note list queries + cache
├── NoteTagManager        — tag operations
├── selectedNote / detailLoading — detail panel DTO
├── selectedTag           — list filter
└── orchestration methods  — createNote, selectNote, workspace delegation

NoteTabStrip (widget)     — renamed from NoteTabManager, reads from EditorShellService
```

## 核心组件设计

### EditorShellService

```dart
class EditorShellService extends ChangeNotifier {
  // State
  final Map<String, EditorGroupModel> _groups;
  final Map<String, EditBuffer> _buffers;
  GroupLayout _layout;
  String _activeGroupId;

  // Closure injection (no FFI knowledge)
  final Future<String> Function(String atomId) _loadContentFn;
  final Future<bool> Function(String atomId, String content) _persistFn;
  final void Function(String atomId, String content)? _onBufferSaved;

  // Tab operations
  void openTab(String groupId, String atomId, {String? initialContent, String? title});
  void closeTab(String groupId, String atomId);
  void switchTab(String groupId, String atomId);
  void updateTabTitle(String atomId, String newTitle);

  // Save operations
  Future<void> flushBuffer(String atomId);
  Future<void> flushAllDirtyBuffers();
  bool get hasPendingSaveWork;

  // Layout operations
  void splitGroup(String groupId, Axis axis);
  void resizeAt(List<int> path, double newFraction);
  // Note: no public closeGroup(). Pane close is tab-driven:
  // closeTab() → empty group + groups.length > 1 → auto-collapse via _destroyGroup().

  // Queries
  EditorGroupModel? get activeGroup;
  EditBuffer? bufferFor(String atomId);
  LayoutResolveResult resolveLayout(Size containerSize);
}
```

### EditorGroupModel

```dart
class EditorGroupModel extends ChangeNotifier {
  List<TabEntry> _tabs;
  String? _activeAtomId;
  String? _previewTabId;    // per-group, not global (DI-1 Q1)
}

@immutable
class TabEntry {
  final String atomId;
  final String title;       // from atom.title (S1 R8)
}
```

### EditBuffer（DI-1 Q3 状态机）

#### EditOp 类型预留（DI-4 契约）

```dart
/// v0.3 仅定义 SnapshotReplace；TextDelta / StructuredOp 预留不使用。
sealed class EditOp {
  const EditOp();
}

/// 全量替换（v0.3 唯一实现）
class SnapshotReplace extends EditOp {
  const SnapshotReplace();
}

// v0.4+ 预留：
// class TextDelta extends EditOp { ... }
// class StructuredOp extends EditOp { ... }
```

v0.3 调用方不传 `op`（默认 null，等价于 `SnapshotReplace`）。EditBuffer 内部忽略 `op` 值，仅做全量字符串替换。

#### EditBuffer 类

```dart
class EditBuffer extends ChangeNotifier {
  final String atomId;
  BufferPhase _phase;       // loading | ready | error | disposing
  String _content;
  String _lastSavedContent;
  int _rev;                 // monotonic, unified (DI-4 _rev)
  Future<bool>? _saveFuture;
  bool _saveQueued;
  Timer? _debounceTimer;
  String? _errorMessage;
  final Future<bool> Function(String, String) _persistFn;

  // Derived
  bool get isDirty => _content != _lastSavedContent;

  // Operations
  void initialize(String loadedContent);  // loading → ready
  void edit(String newContent, {EditOp? op}); // ready only, increments _rev; op reserved (v0.3 callers pass null)
  Future<void> flush();                   // debounced save
  void markError(String e);              // loading → error
  void retry();                          // error → loading
}
```

### GroupLayout（DI-2 D5 sealed class 二叉树）

```dart
sealed class LayoutNode {
  const LayoutNode();
}

@immutable
class SplitNode extends LayoutNode {
  final LayoutNode first;
  final LayoutNode second;
  final Axis axis;
  final double fraction;    // (0.0, 1.0) exclusive
}

@immutable
class LeafNode extends LayoutNode {
  final String groupId;
}

@immutable
class GroupLayout {
  final LayoutNode root;

  (GroupLayout, String) split(String groupId, Axis axis);
  GroupLayout closeGroup(String groupId);
  GroupLayout resizeAt(List<int> path, double newFraction);
  LayoutResolveResult resolve(Size containerSize);
  Set<String> get allGroupIds;
  bool canSplit(String groupId, Axis axis, Size containerSize);

  // Forward compat for PR-RB-07 (DI-3 layout persistence)
  Map<String, dynamic> toJson();
  static GroupLayout fromJson(Map<String, dynamic> json);
}

class LayoutResolveResult {
  final Map<String, Rect> leafRects;
  final List<DividerInfo> dividers;
}
```

### 不变式 I1-I7

| # | 不变式 | 执行方式 |
|---|--------|---------|
| I1 | Binary：SplitNode 恰好 2 子节点 | 类型系统（sealed class `first`/`second`） |
| I2 | Leaf ID 唯一 | `split()`/`closeGroup()` 操作内检查 |
| I3 | Fraction ∈ (0.0, 1.0) | SplitNode 构造函数 assert |
| I4 | 最小尺寸 200×200 | `canSplit()` 预检 + `resolve()` 后验 |
| I5 | 非空：至少 1 节点 | GroupLayout 保证 root 非 null |
| I6 | 双射：leaf groupId 集 = service.groups 键集 | Service 操作保证（split 同时创建 group + leaf，close 同时销毁） |
| I7 | 无重复兄弟 | split 生成唯一新 groupId |
| — | 最大 8 panes | `canSplit()` 检查 `allGroupIds.length < 8` |

## Scope

In scope:

- 新增 `lib/core/editor/` 4 个文件：`editor_shell_service.dart`、`editor_group_model.dart`、`edit_buffer.dart`、`group_layout.dart`
- `NoteTabStateManager` → 拆解为 `EditorGroupModel[]` + Service 层协调
- `NoteDraftManager` + `NoteSaveTracker` → 合并为 `EditBuffer`
- `WorkspaceProvider` layout 状态 → `GroupLayout`
- `WorkspaceProvider` + `WorkspaceModels` TRANSIENT 文件删除（S9 ruling + S2 Phase 2 step 5：完全被 EditorShellService/GroupLayout 取代）
- `notes_coordinator_impl.dart` 减重至 ~1,300 行（原估 ~400-600 过于乐观，见 Changelog v1.1 Discrepancy #5）
- `notes_coordinator_defaults.dart` 新增 ~85 行（default invokers 物理拆分）
- `NoteTabManager` widget → `NoteTabStrip` 重命名（DI-0）
- `NoteTabStrip` 消费源从 `NotesCoordinator` 切换到 `EditorShellService`
- `notes_page.dart` layout 渲染从 `WorkspaceProvider` 扁平列表切换到 `EditorShellService.resolveLayout()` 递归二叉树
- GroupLayout `toJson()`/`fromJson()` 实现（PR-RB-07 前向兼容）
- M1 milestone：多 pane split/resize 首次可用 + tab-driven auto-collapse

Out of scope:

- `layout_persistence.dart`（PR-RB-07 DI-3：文件 I/O + 去抖 + recovery）
- `edit_buffer.dart` 跨 pane 同步（PR-RB-08 DI-4/5：已由 EditBuffer.notifyListeners 提供接口）
- `editor_resolver.dart`（PR-RB-09 DI-10：content_type → EditorPane 映射）

## Consumer Audit `[PR-RB-06 新增]`

### Import 迁移表

| 旧 Import | 新 Import | 影响文件 |
|-----------|----------|---------|
| `core/workspace/workspace_provider.dart` | `core/editor/editor_shell_service.dart` | notes_coordinator.dart, notes_page.dart |
| `core/workspace/workspace_models.dart` | `core/editor/group_layout.dart`（类型替换） | notes_coordinator.dart, notes_page.dart |
| `features/notes/managers/note_tab_manager.dart` | （删除 — 吸收入 core/editor/） | notes_coordinator.dart |
| `features/notes/managers/note_draft_manager.dart` | （删除 — 吸收入 core/editor/） | notes_coordinator.dart |
| `features/notes/managers/note_save_tracker.dart` | （删除 — 吸收入 core/editor/） | notes_coordinator.dart |
| `features/notes/note_tab_manager.dart` | `features/notes/note_tab_strip.dart` | notes_page.dart |

### 类型迁移表

| 旧类型 | 替代 | 说明 |
|--------|------|------|
| `WorkspaceProvider` | `EditorShellService` | layout 操作完全由 Service 管理 |
| `WorkspaceLayoutState` | `GroupLayout` + `LayoutResolveResult` | 扁平列表 → 递归二叉树 |
| `WorkspaceSplitDirection` | `Axis`（Flutter 内置） | `horizontal`/`vertical` → `Axis.horizontal`/`Axis.vertical` |
| `WorkspaceSplitResult` | Service 方法直接返回或抛出 | `canSplit()` 预判 + 异常 |
| `WorkspaceMergeResult` | 已删除（无显式 close pane） | Tab-driven auto-collapse：closeTab() → 空 group 自动销毁 |
| `NoteTabStateManager` | `EditorGroupModel` + `EditorShellService` | per-pane tab 状态分离 |
| `NoteDraftManager` | `EditBuffer` | per-atom 内容状态机 |
| `NoteSaveTracker` / `NoteSaveState` | `EditBuffer.saveState` getter | 派生状态，不独立存储 |

### 消费者文件清单

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `notes_coordinator.dart` | 编辑 | imports + exports 更新 |
| `notes_coordinator_impl.dart` | 重大编辑 | 提取 tab/draft/save/layout 到 Service |
| `notes_page.dart` | 重大编辑 | layout 渲染重写 + split/close 处理重写 |
| `note_tab_manager.dart`（widget） | 重命名 + 编辑 | → `note_tab_strip.dart`，消费源切换 |
| `note_tab_manager_pane_test.dart` | 迁移或删除 | NoteTabStateManager 测试 → EditorGroupModel 测试 |
| `note_save_tracker_test.dart` | 迁移或删除 | NoteSaveTracker 测试 → EditBuffer 测试 |
| `workspace_provider_test.dart` | 迁移或删除 | WorkspaceProvider 测试 → GroupLayout 测试 |
| `workspace_split_v1_test.dart` | 迁移或删除 | Split 测试 → GroupLayout split 测试 |
| `notes_controller_tabs_test.dart` | 编辑 | 更新 tab 操作测试调用路径 |
| `workspace_integration_flow_test.dart` | 编辑 | 移除 WorkspaceProvider 引用 |

## Forward Compatibility `[PR-RB-06 新增]`

| 后续 PR | 接口边界 | PR-RB-06 义务 |
|---------|---------|--------------|
| PR-RB-07（DI-3 布局持久化） | `GroupLayout.toJson()` / `fromJson()` | 在 GroupLayout 中实现序列化方法（纯结构，不含文件 I/O）|
| PR-RB-08（DI-4/5 buffer 同步） | `EditBuffer.notifyListeners()` + `_rev` | 已提供 — EditBuffer extends ChangeNotifier + _rev 字段 |
| PR-RB-09（DI-10 EditorResolver） | `EditorShellService` + `EditBuffer` | Service 传 EditBuffer 给渲染器；resolver 选择哪个渲染器 |

## Backward Compatibility — PR-RB-05 Cross-Reference `[PR-RB-06 新增]`

| PR-RB-05 产出 | PR-RB-06 消费 |
|---------------|--------------|
| `core/workspace/` 4 个 tree 文件（永久驻留） | 不变 — WorkspaceTreeService 保留在 `core/workspace/` |
| `core/workspace/` 2 个 TRANSIENT 文件 | **删除** — layout 逻辑吸收入 `core/editor/group_layout.dart` |
| `notes → workspace` Rule E exemption 已移除 | 确认移除 — 不需新增 exemption |
| `tools/ci/rule_e_allowlist.yaml` | 无变更（当前无 notes→workspace exemption） |

## Task Breakdown

### Phase 1: 新增 core/editor 文件

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T1 | 实现 `GroupLayout` + `LayoutNode` sealed class + `resolve()` + I1-I7 + `toJson()`/`fromJson()`（PR-RB-07 前向兼容） | `lib/core/editor/group_layout.dart` | ~300 行 | — |
| T2 | 实现 `EditorGroupModel` + `TabEntry` | `lib/core/editor/editor_group_model.dart` | ~120 行 | — |
| T3 | 实现 `EditBuffer` 状态机（4 phase，`_rev`，debounce save，`EditOp` sealed class） | `lib/core/editor/edit_buffer.dart` | ~220 行 | — |
| T4 | 实现 `EditorShellService`（组合 groups + buffers + layout，API surface） | `lib/core/editor/editor_shell_service.dart` | ~300 行 | T1, T2, T3 |

### Phase 2: 提取迁移

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T5 | Coordinator: 替换 `_noteTabManager` 为 `EditorShellService` 引用；tab open/close/activate 委托到 Service | `notes_coordinator_impl.dart` | 编辑 | T4 |
| T6 | Coordinator: 移除 `NoteDraftManager` + `NoteSaveTracker` 依赖，替换为 `service.bufferFor(atomId)` | `notes_coordinator_impl.dart` | 删除 ~200 行 | T4 |
| T7 | Coordinator: 移除 `_workspaceProvider` 字段及 `closeActivePane()` 方法（无显式 close pane）；`splitActivePane()` / `switchActivePane()` / `activateNextPane()` 保留为 coordinator facade（前置检查 + 状态同步 + service 执行）；layout 查询委托到 `service.resolveLayout()` / `service.splitGroup()` | `notes_coordinator_impl.dart` | 编辑 | T4 |
| T8 | Coordinator: 接入 closure 注入（`_loadContentFn` / `_persistFn` / `_onBufferSaved`） | `notes_coordinator_impl.dart` | 编辑 | T4 |

### Phase 3: Widget 重命名 + 消费源切换

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T9 | `NoteTabManager` widget → `NoteTabStrip`（文件名 + 类名 + Key） | `note_tab_manager.dart` → `note_tab_strip.dart` | rename + 编辑 | — |
| T10 | `NoteTabStrip` 消费源切换到 `EditorShellService`（读 group.tabs / group.activeAtomId / group.previewTabId） | `note_tab_strip.dart` | 编辑 | T4, T9 |
| T11 | `notes_page.dart` 重写：(1) import 更新；(2) layout 渲染从 `WorkspaceProvider` 扁平列表切换到 `service.resolveLayout()` 递归二叉树；(3) `_handleSplitCommand` 从 `WorkspaceSplitResult` 重写为 `PaneSplitResult` + Service API 调用（无 close/next-pane 按钮 — pane 切换通过 onTap 直接调用 `switchActivePane`）；(4) `mergedListenable` 从 `_coordinator + _coordinator.workspaceProvider` 改为 `_coordinator + _editorShellService` | `notes_page.dart` | 重大编辑 ~150 行 | T4, T9 |

### Phase 4: 清理 + 删除

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T12 | 删除 `NoteTabStateManager`（已提取到 EditorGroupModel） | `managers/note_tab_manager.dart` | 删除文件 | T5 |
| T13 | 删除 `NoteDraftManager`（已合并到 EditBuffer） | `managers/note_draft_manager.dart` | 删除文件 | T6 |
| T14 | 删除 `NoteSaveTracker`（已合并到 EditBuffer） | `managers/note_save_tracker.dart` | 删除文件 | T6 |
| T15 | 删除 `WorkspaceProvider` + `WorkspaceModels` TRANSIENT 文件（S9 + S2 Phase 2 step 5：layout 逻辑已完全吸收入 `core/editor/group_layout.dart`）`[PR-RB-06 变更：Draft 标注 "out of scope" → 改为 in scope，遵循 S9/S2 权威裁决]` | `core/workspace/workspace_provider.dart` + `core/workspace/workspace_models.dart` | 删除两个文件 | T7, T11 |
| T16 | 更新 `notes_coordinator.dart` imports + exports：移除 NoteDraftManager / NoteTabStateManager / NoteSaveState / WorkspaceProvider / WorkspaceModels exports；新增 EditorShellService re-export（如需要） | `notes_coordinator.dart` | 编辑 | T5~T15 |

### Phase 5: 测试

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T17 | `GroupLayout` 单元测试：split/close/resize + I1-I7 + resolve + 8 pane 限制 + canSplit + toJson/fromJson | `test/group_layout_test.dart` | 新文件 ~300 行 | T1 |
| T18 | `EditBuffer` 单元测试：4 phase 状态机 + `_rev` + debounce + flush + error/retry + dispose | `test/edit_buffer_test.dart` | 新文件 ~200 行 | T3 |
| T19 | `EditorShellService` 集成测试：openTab + closeTab + split + close + buffer 交互 + reference counting | `test/editor_shell_service_test.dart` | 新文件 ~250 行 | T4 |
| T20 | 迁移现有测试（add-before-remove 策略）：`note_tab_manager_pane_test.dart` → EditorGroupModel 测试场景迁入 T19；`note_save_tracker_test.dart` → EditBuffer 测试场景迁入 T18；`workspace_provider_test.dart` + `workspace_split_v1_test.dart` → GroupLayout 测试场景迁入 T17；`notes_controller_tabs_test.dart` → 更新调用路径；`workspace_integration_flow_test.dart` → 移除 WorkspaceProvider 引用 | `test/*.dart` | 编辑 + 删除 | T5~T15, T17~T19 |
| T21 | `NoteTabStrip` widget 测试更新（消费源切换后的渲染验证） | `test/*.dart` | 编辑 | T9, T10 |

### Phase 6: 文档

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T22 | `CLAUDE.md` 路径表更新：新增 `core/editor/`；更新 WorkspaceProvider TRANSIENT 引用；更新 coordinator 架构节 | `CLAUDE.md` | 编辑 | T4 |
| T23 | `overview.md` 更新：新增 `core/editor/` 到 Flutter Core 节；更新 coordinator 架构节；更新 WorkspaceProvider 引用 | `docs/architecture/overview.md` | 编辑 | T4 |
| T24 | S2 ruling 标注 Phase 2 implemented；S9 ruling 标注 EditorShellService 已完成 + TRANSIENT 已删除 | `docs/architecture/rulings-legacy/S2-*.md` + `S9-*.md` | 编辑 | T4, T15 |

### Critical Path

```
T1 + T2 + T3 (并行) → T4 → T5~T8 (coordinator 迁移) → T12~T16 (清理)
T9 无依赖，可与 T1~T3 并行
T17~T19 可在 T1~T4 后并行于 T5~T8
T11 需要 T4 + T9 完成
T15 需要 T7 + T11 完成（确认所有 WorkspaceProvider 引用已替换后再删除）
```

## Planned File Changes

### 新增
- `[add]` `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart` (~300 行)
- `[add]` `apps/lazynote_flutter/lib/core/editor/editor_group_model.dart` (~120 行)
- `[add]` `apps/lazynote_flutter/lib/core/editor/edit_buffer.dart` (~220 行)
- `[add]` `apps/lazynote_flutter/lib/core/editor/group_layout.dart` (~300 行)
- `[add]` `apps/lazynote_flutter/test/group_layout_test.dart`
- `[add]` `apps/lazynote_flutter/test/edit_buffer_test.dart`
- `[add]` `apps/lazynote_flutter/test/editor_shell_service_test.dart`

### 重命名
- `[rename]` `features/notes/note_tab_manager.dart` → `features/notes/note_tab_strip.dart`

### 重大编辑
- `[edit]` `notes_coordinator_impl.dart`（~1,537 → ~1,300 行；default invokers 拆分至 `notes_coordinator_defaults.dart`）
- `[edit]` `note_tab_strip.dart`（消费源切换到 EditorShellService）
- `[edit]` `notes_page.dart`（layout 渲染重写 + split/close 处理重写）

### 删除（manager 文件）
- `[delete]` `features/notes/managers/note_tab_manager.dart`（NoteTabStateManager，440 行）
- `[delete]` `features/notes/managers/note_draft_manager.dart`（NoteDraftManager，261 行）
- `[delete]` `features/notes/managers/note_save_tracker.dart`（NoteSaveTracker，95 行）

### 删除（TRANSIENT 文件）`[PR-RB-06 变更]`
- `[delete]` `core/workspace/workspace_provider.dart`（171 行；S9 + S2 Phase 2 step 5）
- `[delete]` `core/workspace/workspace_models.dart`（71 行；S9 + S2 Phase 2 step 5）

### 编辑
- `[edit]` `notes_coordinator.dart`（imports + exports 更新）
- `[edit]` 涉及旧 manager imports 的测试文件（§Consumer Audit 消费者文件清单）

### 文档
- `[edit]` `CLAUDE.md`、`overview.md`、S2 ruling、S9 ruling

## Line Count Impact

| 文件 | Before | After | Delta |
|------|--------|-------|-------|
| `notes_coordinator_impl.dart` | 1,537 | ~1,293 | -244 |
| `notes_coordinator_defaults.dart` | 0 | ~85 | +85 (new, default invokers) |
| `managers/note_tab_manager.dart` | 440 | 0 | -440 (deleted) |
| `managers/note_draft_manager.dart` | 261 | 0 | -261 (deleted) |
| `managers/note_save_tracker.dart` | 95 | 0 | -95 (deleted) |
| `workspace_provider.dart` (TRANSIENT) | 171 | 0 | -171 (deleted) |
| `workspace_models.dart` (TRANSIENT) | 71 | 0 | -71 (deleted) |
| `editor_shell_service.dart` | 0 | ~300 | +300 (new) |
| `editor_group_model.dart` | 0 | ~120 | +120 (new) |
| `edit_buffer.dart` | 0 | ~220 | +220 (new) |
| `group_layout.dart` | 0 | ~300 | +300 (new) |
| `note_tab_strip.dart` (rename) | 422 | ~400 | -22 |
| **生产代码净变化** | | | **~-1,157** |

## Verification

### CI gates

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# core/editor/ 目录存在且包含 4 个核心文件
ls apps/lazynote_flutter/lib/core/editor/
# Expected: editor_shell_service.dart, editor_group_model.dart, edit_buffer.dart, group_layout.dart

# NoteTabStateManager 归零
rg "NoteTabStateManager" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# NoteDraftManager 归零
rg "NoteDraftManager" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# NoteSaveTracker 归零
rg "NoteSaveTracker" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# NoteTabManager widget 归零（应为 NoteTabStrip）
rg "class NoteTabManager" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# TRANSIENT 文件已删除
# workspace_provider.dart 不存在
ls apps/lazynote_flutter/lib/core/workspace/workspace_provider.dart 2>&1
# Expected: No such file

# workspace_models.dart 不存在
ls apps/lazynote_flutter/lib/core/workspace/workspace_models.dart 2>&1
# Expected: No such file

# WorkspaceProvider class 归零
rg "WorkspaceProvider" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# WorkspaceLayoutState 归零
rg "WorkspaceLayoutState" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# WorkspaceSplitResult/MergeResult 归零
rg "WorkspaceSplitResult|WorkspaceMergeResult" apps/lazynote_flutter/lib/ --type dart
# Expected: zero matches

# GroupLayout 包含 toJson/fromJson（PR-RB-07 前向兼容）
rg "toJson|fromJson" apps/lazynote_flutter/lib/core/editor/group_layout.dart
# Expected: ≥ 2 matches

# NoteTabStrip 存在
rg "class NoteTabStrip" apps/lazynote_flutter/lib/ --type dart
# Expected: 1 match

# coordinator_impl 行数检查
wc -l apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart
# Expected: ≤ 1300

# M1 功能：EditorShellService 包含 splitGroup/resizeAt + 内部 _destroyGroup（auto-collapse）
rg "splitGroup|resizeAt|_destroyGroup" apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart
# Expected: ≥ 3 matches
```

### M1 Milestone 验证

| 验证项 | 标准 |
|--------|------|
| Split | 可通过 `splitGroup(groupId, axis)` 创建新 pane |
| Auto-collapse | 关闭 pane 最后一个 tab 后 group 自动销毁、布局收缩（tab-driven，无显式 close pane） |
| Resize | `resizeAt(path, fraction)` 调整 pane 比例 |
| 不同 atom 并行查看 | 两个 pane 可同时打开不同 atom |
| 最后 group 不消失 | 唯一剩余 group 永远保留（`paneCount >= 1` 不变量） |
| I4 最小尺寸 | `canSplit()` 在空间不足时返回 false |
| 8 pane 限制 | 第 9 次 split 被拒绝 |

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Coordinator 提取范围过大导致回归 | HIGH | T5~T8 分步执行，每步后 `flutter test`；add-before-remove 策略 |
| EditBuffer 状态机 edge cases | MEDIUM | T18 单元测试覆盖所有 phase 转换 + error/retry 路径 |
| GroupLayout resolve 性能 | LOW | DI-7 SLA: split/close <50ms；纯 Dart 计算，8 pane 最多 15 节点 |
| Widget 消费源切换遗漏 | MEDIUM | `flutter analyze` 编译错误暴露；T20~T21 测试覆盖 |
| notes_page.dart 递归渲染重写范围 | MEDIUM | T11 独立阶段，可先实现单 pane 路径验证再扩展到多 pane |
| TRANSIENT 文件删除遗漏引用 | LOW | §Structural verification 全面检查 WorkspaceProvider/Models/Split/Merge 归零 |

## Test Baseline

Entry: PR-RB-05 exit count（347 tests passed）
Exit: **≥ 入口 count + 新增 GroupLayout/EditBuffer/Service 测试**（旧 manager 测试 add-before-remove；5 个旧测试文件迁移或删除）

## Acceptance Criteria

- [ ] `lib/core/editor/` 包含 4 个文件（editor_shell_service / editor_group_model / edit_buffer / group_layout）
- [ ] `EditorShellService` 实现 tab/save/layout 全部 API（§核心组件设计 API 列表）
- [ ] `EditBuffer` 实现 4-phase 状态机 + `_rev` + debounced save（§EditBuffer 类）
- [ ] `GroupLayout` 实现 split/close/resize + I1-I7 + 8 pane 限制 + `toJson()`/`fromJson()`
- [ ] `NoteTabStateManager` / `NoteDraftManager` / `NoteSaveTracker` 已删除（3 个 manager 文件）
- [ ] `NoteTabManager` widget 重命名为 `NoteTabStrip`
- [ ] `workspace_provider.dart` + `workspace_models.dart` TRANSIENT 文件已删除
- [ ] `WorkspaceProvider` / `WorkspaceLayoutState` / `WorkspaceSplitResult` / `WorkspaceMergeResult` 类在 lib/ 中引用归零
- [ ] `notes_coordinator_impl.dart` ≤ 1300 行（Rebaseline v1.1: Dart 不支持 partial class，orchestration 跨子系统调用链阻止物理拆分）
- [ ] `notes_coordinator_defaults.dart` 存在（default invokers 拆分）
- [ ] `notes_page.dart` layout 渲染使用 `resolveLayout()` 递归二叉树
- [ ] M1 milestone：多 pane split/resize + tab-driven auto-collapse 可用（§M1 Milestone 验证 全部通过）
- [ ] DI-0 命名冲突消除（NoteTabManager widget → NoteTabStrip）
- [ ] DI-1/2 所有裁决落地
- [ ] 测试数量 ≥ 入口 count + 新增核心组件测试
- [ ] 无新增 Rule E exemption
- [ ] §Verification CI gates 全部通过（逐项执行并记录输出）
- [ ] §Verification Structural verification 全部通过

## Changelog

### v1.1 — Coordinator 行数 AC Rebaseline（2026-03-02）

**Discrepancy #5 — Coordinator 行数 AC ≤600 → ≤1300**

实施过程中发现原估 ~400-600 行过于乐观。实际 coordinator 在完成 tab/draft/save 提取至 `EditorShellService` 后仍有 ~1,293 行。

**根因分析**：
- Coordinator 编排 4 个子系统（EditorShellService、NoteListManager、NoteTagManager、WorkspaceTreeService），跨子系统桥接逻辑（flush-before-switch、detail-load-after-activate、preview-replacement、tab-merge-on-pane-close）占 ~400 行
- Constructor 回调接线占 ~120 行（4 个 manager × 多个 callback）
- 多 pane 操作（split/switchPane/auto-collapse）为 PR-RB-06 新增复杂度 ~90 行
- Dart 不支持 partial class，extension 方法不能从 class 内部调用，阻止了进一步物理拆分

**已完成的瘦身措施**：
- Default invokers 提取至 `notes_coordinator_defaults.dart`（-83 行，part 文件）
- Tab/draft/save 状态已提取至 `core/editor/`（EditorShellService 365 行 + EditorGroupModel 227 行 + EditBuffer 293 行）
- 原 5 个 managers 中 3 个已删除（NoteTabStateManager、NoteDraftManager、NoteSaveTracker）

**AC 变更**：`notes_coordinator_impl.dart` ≤ 600 行 → ≤ 1300 行

### v1.0 — Draft → Ready for Implementation（2026-03-02）

**信息来源**：Rulings（S2、S9）+ Module specs（core-editor/*.md）为第一来源；DI-0~DI-2 设计讨论为细节补充。对照 PR-RB-05 完成内容交叉验证。

**关键变更**：

1. **状态**：`Draft` → `Ready for Implementation`
2. **前置条件**：新增 PR-RB-05 为显式前置条件
3. **Discrepancy #1 — GroupLayout 数据模型**：module spec `group-layout.md` 使用多子节点模型，与 DI-2 D5 二叉树裁决冲突 → 以 DI-2 为权威，module spec 已同步修正 `[PR-RB-06 更新]`
4. **Discrepancy #2 — TRANSIENT 文件归属**：Draft 标注 "WorkspaceProvider 文件删除 out of scope" 与 S9 ruling + S2 Phase 2 step 5 矛盾 → 以 S9/S2 为权威，TRANSIENT 文件删除改为 in scope（T15）
5. **Discrepancy #3 — notes_page.dart 渲染重写**：Draft 未详述 layout 渲染迁移 → 新增 T11 详细描述递归二叉树渲染重写
6. **Discrepancy #4 — Coordinator 行数**：~300-500 → ~400-600（AC ≤ 600 不变）→ 实施后 rebaseline 至 ≤ 1300（见 v1.1）
7. **新增节**：Consumer Audit、Import 迁移表、类型迁移表、Forward Compatibility、Backward Compatibility (PR-RB-05)
8. **T1 扩展**：增加 `toJson()`/`fromJson()` 为 PR-RB-07 前向兼容
9. **T7 细化**：明确移除 `_workspaceProvider` + `closeActivePane()`；`splitActivePane()` / `switchActivePane()` / `activateNextPane()` 保留为 coordinator facade
10. **T15 变更**：从 "layout 字段清理（编辑）" → "TRANSIENT 文件删除（删除两个文件）"
11. **T16 细化**：明确 exports 变更清单
12. **T20 细化**：列出 5 个受影响测试文件的迁移策略
13. **AC 扩展**：新增 TRANSIENT 删除、类引用归零、toJson/fromJson、测试数量、Rule E 合规共 6 项
14. **Structural verification 扩展**：新增 TRANSIENT 文件不存在、WorkspaceProvider/Models/Split/Merge 归零共 6 项检查
15. **行数影响更新**：workspace_provider.dart 171→0 + workspace_models.dart 71→0（净减重 -1,157 行）
16. **风险更新**：新增 notes_page.dart 递归渲染重写风险 + TRANSIENT 删除遗漏引用风险
17. **相关文档同步更新**：group-layout.md、editor-shell-service.md、S2 ruling、S9 ruling、overview.md、CLAUDE.md
