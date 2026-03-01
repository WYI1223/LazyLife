# PR-RB-06: DI-0/1/2 + core-editor 基础

- Proposed title: `feat(editor): PR-RB-06 EditorShellService + GroupLayout + EditBuffer first landing`
- Status: Draft

## Goal

首次落地 `lib/core/editor/` 基础设施：`EditorShellService`（workbench singleton）+ `EditorGroupModel`（per-pane tab 状态）+ `EditBuffer`（per-atom 内容状态机）+ `GroupLayout`（递归布局树）。从 `notes_coordinator_impl.dart` 提取 tab/draft/save 状态管理。`NoteTabManager` widget 重命名为 `NoteTabStrip`。`WorkspaceProvider` layout 状态迁入 `GroupLayout`。**交付里程碑 M1：多 pane split/close/resize 首次可用。**

前置条件：PR-RB-01（`AtomListItem` 统一）+ PR-RB-02（`title`/`view_hint` 可用）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI-0 | `DI-0-dual-tab-manager.md` D4 | `NoteTabManager` widget → `NoteTabStrip`；`NoteTabStateManager` → `EditorGroupModel` |
| DI-1 | `DI-1-editor-shell-service.md` Q1~Q5 | EditorShellService API + state 归属 + EditBuffer 状态机 + closure 注入 + 文件位置 |
| DI-2 | `DI-2-layout-tree-structure.md` D5/D6 | sealed class 树结构 + top-down resolve + I1-I7 不变式 |
| Module Spec | `modules/core-editor/editor-shell-service.md` | Service API surface + state fields |
| Module Spec | `modules/core-editor/editor-group-model.md` | Group state + TabEntry |
| Module Spec | `modules/core-editor/group-layout.md` | GroupLayout 封装层 API |
| Ruling | `rulings/S2-tab-draft-save-ownership.md` Phase 2 | 提取蓝图 + 四条规则 |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-06 | Scope + M1 milestone |
| DI-7 | `DI-7-gates-perf-testing.md` | Gate B M1 验证标准 |
| Acceptance Report | `09-acceptance-report.md` §7.1 | coordinator_impl 1,514 行 → 提取后减重 |

## 架构概览

### 提取前（当前）

```
NotesCoordinator (1,514 lines) — owns everything
├── NoteTabStateManager  — per-pane tab state (440 lines)
├── NoteDraftManager     — draft content (5 parallel Maps)
├── NoteSaveTracker      — save state (state duplication)
├── NoteListManager      — note list queries
├── NoteTagManager       — tag operations
└── WorkspaceProvider    — pane layout (167 lines, separate file)

NoteTabManager (widget)  — tab strip UI (422 lines)
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

NotesCoordinator (~300-500 lines) — retains:
├── NoteListManager       — note list queries + cache
├── NoteTagManager        — tag operations
├── selectedNote / detailLoading — detail panel DTO
└── orchestration methods  — createNote, selectNote, flushPendingSave

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
  void closeGroup(String groupId);
  void resizeAt(List<int> path, double newFraction);

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

### GroupLayout（DI-2 sealed class）

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
- `notes_coordinator_impl.dart` 减重至 ~300-500 行
- `NoteTabManager` widget → `NoteTabStrip` 重命名（DI-0）
- `NoteTabStrip` 消费源从 `NotesCoordinator` 切换到 `EditorShellService`
- M1 milestone：多 pane split/close/resize 首次可用

Out of scope:

- `layout_persistence.dart`（PR-RB-07 DI-3）
- `edit_buffer.dart` 跨 pane 同步（PR-RB-08 DI-4/5）
- `editor_resolver.dart`（PR-RB-09 DI-10）
- `WorkspaceProvider` 文件删除（PR-RB-05 已迁移到 `core/workspace/`，本 PR 替换 layout 逻辑引用）

## Task Breakdown

### Phase 1: 新增 core/editor 文件

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T1 | 实现 `GroupLayout` + `LayoutNode` sealed class + `resolve()` + I1-I7 | `lib/core/editor/group_layout.dart` | ~250 行 | — |
| T2 | 实现 `EditorGroupModel` + `TabEntry` | `lib/core/editor/editor_group_model.dart` | ~120 行 | — |
| T3 | 实现 `EditBuffer` 状态机（4 phase，`_rev`，debounce save） | `lib/core/editor/edit_buffer.dart` | ~200 行 | — |
| T4 | 实现 `EditorShellService`（组合 groups + buffers + layout，API surface） | `lib/core/editor/editor_shell_service.dart` | ~300 行 | T1, T2, T3 |

### Phase 2: 提取迁移

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T5 | Coordinator: 替换 `_noteTabManager` 为 `EditorShellService` 引用 | `notes_coordinator_impl.dart` | 编辑 | T4 |
| T6 | Coordinator: 移除 `NoteDraftManager` + `NoteSaveTracker` 依赖，替换为 `service.bufferFor(atomId)` | `notes_coordinator_impl.dart` | 删除 ~200 行 | T4 |
| T7 | Coordinator: 移除 `WorkspaceProvider` layout 依赖，layout 查询委托到 `service.resolveLayout()` | `notes_coordinator_impl.dart` | 编辑 | T4 |
| T8 | Coordinator: 接入 closure 注入（`_loadContentFn` / `_persistFn` / `_onBufferSaved`） | `notes_coordinator_impl.dart` | 编辑 | T4 |

### Phase 3: Widget 重命名 + 消费源切换

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T9 | `NoteTabManager` widget → `NoteTabStrip`（文件名 + 类名 + Key） | `note_tab_manager.dart` → `note_tab_strip.dart` | rename + 编辑 | — |
| T10 | `NoteTabStrip` 消费源切换到 `EditorShellService` | `note_tab_strip.dart` | 编辑 | T4, T9 |
| T11 | `notes_page.dart` import 更新 + layout 渲染从 `WorkspaceProvider` 切换到 `EditorShellService.resolveLayout()` | `notes_page.dart` | 编辑 | T4, T9 |

### Phase 4: 清理 + 删除

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T12 | 删除 `NoteTabStateManager`（已提取到 EditorGroupModel） | `managers/note_tab_manager.dart` | 删除文件 | T5 |
| T13 | 删除 `NoteDraftManager`（已合并到 EditBuffer） | `managers/note_draft_manager.dart` | 删除文件 | T6 |
| T14 | 删除 `NoteSaveTracker`（已合并到 EditBuffer） | `managers/note_save_tracker.dart` | 删除文件 | T6 |
| T15 | `WorkspaceProvider` layout 字段清理（layout 状态已迁入 GroupLayout） | `core/workspace/workspace_provider.dart` | 编辑或削减 | T7 |
| T16 | 更新 `notes_coordinator.dart` exports | `notes_coordinator.dart` | 编辑 | T5~T14 |

### Phase 5: 测试

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T17 | `GroupLayout` 单元测试：split/close/resize + I1-I7 + resolve + 8 pane 限制 | `test/group_layout_test.dart` | 新文件 ~300 行 | T1 |
| T18 | `EditBuffer` 单元测试：4 phase 状态机 + `_rev` + debounce + flush | `test/edit_buffer_test.dart` | 新文件 ~200 行 | T3 |
| T19 | `EditorShellService` 集成测试：openTab + closeTab + split + close + buffer 交互 | `test/editor_shell_service_test.dart` | 新文件 ~250 行 | T4 |
| T20 | 迁移现有 coordinator/tab/draft/save 测试 | `test/*.dart` | 编辑（add-before-remove） | T5~T14 |
| T21 | `NoteTabStrip` widget 测试更新 | `test/*.dart` | 编辑 | T9, T10 |

### Phase 6: 文档

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T22 | `CLAUDE.md` 路径表更新：新增 `core/editor/` | `CLAUDE.md` | 编辑 | T4 |
| T23 | `overview.md` 更新 | `docs/architecture/overview.md` | 编辑 | T4 |
| T24 | S2 ruling 标注 Phase 2 implemented | `docs/architecture/rulings/S2-*.md` | 编辑 | T4 |

### Critical Path

```
T1 + T2 + T3 (并行) → T4 → T5~T8 (coordinator 迁移) → T12~T16 (清理)
T9 无依赖，可与 T1~T3 并行
T17~T19 可在 T1~T4 后并行于 T5~T8
```

## Planned File Changes

### 新增
- `[add]` `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart` (~300 行)
- `[add]` `apps/lazynote_flutter/lib/core/editor/editor_group_model.dart` (~120 行)
- `[add]` `apps/lazynote_flutter/lib/core/editor/edit_buffer.dart` (~200 行)
- `[add]` `apps/lazynote_flutter/lib/core/editor/group_layout.dart` (~250 行)
- `[add]` `apps/lazynote_flutter/test/group_layout_test.dart`
- `[add]` `apps/lazynote_flutter/test/edit_buffer_test.dart`
- `[add]` `apps/lazynote_flutter/test/editor_shell_service_test.dart`

### 重命名
- `[rename]` `note_tab_manager.dart` → `note_tab_strip.dart`

### 重大编辑
- `[edit]` `notes_coordinator_impl.dart`（~1,514 → ~300-500 行）
- `[edit]` `note_tab_strip.dart`（消费源切换）
- `[edit]` `notes_page.dart`（layout 渲染切换）

### 删除
- `[delete]` `managers/note_tab_manager.dart`（NoteTabStateManager，440 行）
- `[delete]` `managers/note_draft_manager.dart`
- `[delete]` `managers/note_save_tracker.dart`

### 编辑
- `[edit]` `notes_coordinator.dart`（exports 更新）
- `[edit]` `core/workspace/workspace_provider.dart`（layout 字段削减）
- `[edit]` 涉及旧 manager imports 的文件

### 文档
- `[edit]` `CLAUDE.md`、`overview.md`、S2 ruling

## Line Count Impact

| 文件 | Before | After | Delta |
|------|--------|-------|-------|
| `notes_coordinator_impl.dart` | 1,514 | ~400 | -1,114 |
| `managers/note_tab_manager.dart` | 440 | 0 | -440 (deleted) |
| `managers/note_draft_manager.dart` | ~200 | 0 | -200 (deleted) |
| `managers/note_save_tracker.dart` | ~200 | 0 | -200 (deleted) |
| `workspace_provider.dart` (layout) | 167 | ~50 | -117 |
| `editor_shell_service.dart` | 0 | ~300 | +300 (new) |
| `editor_group_model.dart` | 0 | ~120 | +120 (new) |
| `edit_buffer.dart` | 0 | ~200 | +200 (new) |
| `group_layout.dart` | 0 | ~250 | +250 (new) |
| `note_tab_strip.dart` (rename) | 422 | ~400 | -22 |
| **生产代码净变化** | | | **~-1,223** |

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

# coordinator_impl 行数检查
wc -l apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart
# Expected: < 600

# M1 功能：EditorShellService 包含 splitGroup/closeGroup/resizeAt
rg "splitGroup|closeGroup|resizeAt" apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart
# Expected: ≥ 3 matches
```

### M1 Milestone 验证

| 验证项 | 标准 |
|--------|------|
| Split | 可通过 `splitGroup(groupId, axis)` 创建新 pane |
| Close | 关闭 pane 后布局自动收缩（sibling 扩展） |
| Resize | `resizeAt(path, fraction)` 调整 pane 比例 |
| 不同 atom 并行查看 | 两个 pane 可同时打开不同 atom |
| Primary group 不消失 | 关闭 primary group 最后一个 tab 时显示空状态 |
| I4 最小尺寸 | `canSplit()` 在空间不足时返回 false |
| 8 pane 限制 | 第 9 次 split 被拒绝 |

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Coordinator 提取范围过大导致回归 | HIGH | T5~T8 分步执行，每步后 `flutter test`；add-before-remove 策略 |
| EditBuffer 状态机 edge cases | MEDIUM | T18 单元测试覆盖所有 phase 转换 + error/retry 路径 |
| GroupLayout resolve 性能 | LOW | DI-7 SLA: split/close <50ms；纯 Dart 计算，8 pane 最多 15 节点 |
| Widget 消费源切换遗漏 | MEDIUM | `flutter analyze` 编译错误暴露；T20~T21 测试覆盖 |

## Test Baseline

Entry: PR-RB-02 exit count（PR-RB-04/05 并行或在此之前）
Exit: **≥ 入口 count + 新增 GroupLayout/EditBuffer/Service 测试**（旧 manager 测试 add-before-remove）

## Acceptance Criteria

- [ ] `lib/core/editor/` 包含 4 个文件
- [ ] `EditorShellService` 实现 tab/save/layout 全部 API
- [ ] `EditBuffer` 实现 4-phase 状态机 + `_rev` + debounced save
- [ ] `GroupLayout` 实现 split/close/resize + I1-I7 + 8 pane 限制
- [ ] `NoteTabStateManager`/`NoteDraftManager`/`NoteSaveTracker` 已删除
- [ ] `NoteTabManager` widget 重命名为 `NoteTabStrip`
- [ ] `notes_coordinator_impl.dart` ≤ 600 行
- [ ] M1 milestone：多 pane split/close/resize 可用
- [ ] DI-0 命名冲突消除
- [ ] DI-1/2 所有裁决落地
- [ ] 全部 Flutter tests 通过
- [ ] CI green
