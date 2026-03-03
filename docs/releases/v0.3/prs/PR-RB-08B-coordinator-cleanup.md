# PR-RB-08B: Coordinator 结构清理

- Proposed title: `refactor(notes): PR-RB-08B coordinator structural cleanup — derived selectedNote, activation convergence, notification consolidation`
- Status: Implemented
- Parent: PR-RB-08（追加 PR，解决 PR-RB-08 code review 识别的结构性债务）

## Goal

收敛 `NotesCoordinator` 内部实现，消除 PR-RB-06/07/08 累积的结构性债务：

1. **`selectedNote` 派生化** — 消除 9 处手工赋值点，从 `activeNoteId + NoteListManager.cachedNoteById()` 派生
2. **激活路径收敛** — 提取 `_syncActiveNoteState()` 统一 6 个重复的激活后状态同步模式
3. **通知收敛** — `_loadSelectedDetail()` 从 5 次 `notifyListeners()` 收敛至 2 次
4. **死代码清理** — 内联单次调用的 `_canReuseSelection()`，消除空分支，移除冗余调用

不改变公共 API（方法签名不变）。代码变更仅限 `notes_coordinator_impl.dart`。Spec 文档 `editor-shell-service.md` 有同步更新。

> **提交边界**：本分支同时包含 PR-RB-08 和 PR-RB-08B 的变更。`lib/core/editor/editor_shell_service.dart` 的代码改动（P2 lazy loading in `openTab` else-branch、`loadActiveBuffers()`、`_loadBufferContent` failure handling）属于 PR-RB-08 范围，应在 PR-RB-08 提交中包含。PR-RB-08B 的代码变更范围严格限于 `lib/features/notes/notes_coordinator_impl.dart`。

## Execution Contract

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| PR-RB-08 Review | code review findings | 识别 4 项结构性债务 |
| Module Spec | `modules/core-editor/editor-shell-service.md` | Coordinator 提取后结构描述需同步更新 |

## 核心变更

### 1. `selectedNote` 派生化

**问题**：`_selectedNote` 字段在 9 处手工赋值（`_loadNotes` 4 处、`_loadSelectedDetail` 2 处、`createNote`、`closeOpenNote`、`switchActivePane` 各 1 处），容易出现"显示 A、编辑 B"的不一致。

**方案**：删除 `_selectedNote` 字段，替换为从 `activeNoteId + NoteListManager._noteCache` 派生的 getter：

```dart
// Before: stored field with 9 manual assignment points
rust_api.AtomListItem? _selectedNote;
rust_api.AtomListItem? get selectedNote => _selectedNote;

// After: derived getter, zero assignments
rust_api.AtomListItem? get selectedNote {
  final atomId = activeNoteId;
  if (atomId == null) return null;
  return _noteListManager.cachedNoteById(atomId);
}
```

**安全性分析**：

`NoteListManager._noteCache` 具备以下特性，保证派生安全：

| 特性 | 说明 |
|------|------|
| Filter-independent | `upsertNote()` 始终更新 `_noteCache`，不受 tag filter 影响 |
| List-load 同步 | `loadNotes()` 对所有返回项调用 `upsertNote(syncVisibleList: false)` |
| Detail-load 同步 | `_loadSelectedDetail()` 成功后调用 `upsertNote(updatePersisted: true)` |
| Reset 语义一致 | `resetSessionState()` 清空 cache → getter 返回 null → 与原 `_selectedNote = null` 行为一致 |

**`_detailLoadedAtomId` 补偿字段**：

派生 getter 移除后，`selectNote()` 的重用检查丧失了"该 note 的 detail 是否已加载"的语义（原 `_selectedNote` 仅在 detail 加载成功后赋值，隐式充当 marker）。`_noteCache` 在 `loadNotes()` 时即被填充（所有 list item 均入 cache），导致 `selectedNote != null` 过于宽松。

解决方案：新增 `_detailLoadedAtomId` 追踪字段：

```dart
String? _detailLoadedAtomId;

// selectNote 重用检查：
if (activeNoteId == atomId &&
    _detailLoadedAtomId == atomId &&  // 替代原 selectedNote != null
    !_detailLoading &&
    _detailErrorMessage == null) {
  return true;
}
```

- `_loadSelectedDetail()` 成功 → `_detailLoadedAtomId = note.atomId`
- `_clearSelection()` / `_resetSessionForReload()` → `_detailLoadedAtomId = null`

**移除的 13 个赋值点**：

| 位置 | 原代码 | 替代 |
|------|--------|------|
| `onActiveNoteUpdated` callback | `_selectedNote = note` | 删除（`upsertNote` 已更新 cache） |
| `closeOpenNote()` adopt 路径 | `_selectedNote = noteById(newActiveId)` | 删除（getter 自动派生） |
| `switchActivePane()` | `_selectedNote = noteById(activeNoteId!)` | 删除 |
| `updateActiveDraft()` | `_selectedNote = updated` | 删除 |
| `createNote()` | `_selectedNote = createdNote` | 删除（`upsertNote` 已入 cache） |
| `_clearSelection()` | `_selectedNote = null` | 删除（仅保留 detail 状态清理） |
| `_selectFromExplorerByReplacingPreview()` | `_selectedNote = noteById(atomId)` | 删除 |
| `_handleBufferSaved()` | `_selectedNote = cachedNoteById(...) ?? _selectedNote` | 删除 |
| `_loadNotes()` restored path ×3 | `_selectedNote = findLoadedItem/cachedNoteById/first` | 删除 |
| `_loadNotes()` normal path ×2 | `_selectedNote = first/activeItem/fallback` | 删除 |
| `_resetSessionForReload()` | `_selectedNote = null` | 删除（`resetSessionState()` 清 cache 即可） |
| `_loadSelectedDetail()` ×2 | `_selectedNote = findListItem/note` | 删除（`upsertNote` 已入 cache） |

### 2. 激活路径收敛

**问题**：6 个路径在激活 note 后重复 3 行相同代码：`_updateSaveStateFromBuffer()` + `_requestEditorFocus()` + `_switchBlockErrorMessage = null`。

**方案**：提取 `_syncActiveNoteState()` 统一激活后状态同步：

```dart
void _syncActiveNoteState() {
  _updateSaveStateFromBuffer();
  _requestEditorFocus();
  _switchBlockErrorMessage = null;
}
```

**收敛效果**：

| 调用点 | 之前 | 之后 |
|--------|------|------|
| `_openAndActivateTab()` | 3 行 | `_syncActiveNoteState()` |
| `closeOpenNote()` adopt-new-tab 路径 | 2 行 | `_syncActiveNoteState()` |
| `switchActivePane()` | 2 行 | `_syncActiveNoteState()` |
| `_selectFromExplorerByReplacingPreview()` | 3 行 | `_syncActiveNoteState()` |
| `_loadNotes()` restored-tabs 路径 | 2 行 | `_syncActiveNoteState()` |
| close-and-adopt internal 路径 | 2 行 | `_syncActiveNoteState()` |

**`_canReuseSelection()` 内联**：

单一调用点（`selectNote`），内联后删除方法体：

```dart
// Before: method call
if (_canReuseSelection(atomId)) return true;

// After: inlined with _detailLoadedAtomId
if (activeNoteId == atomId &&
    _detailLoadedAtomId == atomId &&
    !_detailLoading &&
    _detailErrorMessage == null) {
  return true;
}
```

### 3. `notifyListeners()` 收敛

**问题**：`_loadSelectedDetail()` 有 5 个 `notifyListeners()` 调用（loading 1 + error 1 + success 1 + empty 1 + catch 1），单次 tab 切换触发 ~5 次全页面 rebuild。

**方案**：合并为 2 次通知（loading + result）：

```dart
Future<void> _loadSelectedDetail({required String atomId}) async {
  if (_disposed) return;
  final requestId = ++_detailRequestId;
  _detailLoading = true;
  _detailErrorMessage = null;
  if (!_disposed) notifyListeners(); // ① Loading state

  try {
    await _prepare();
    if (_staleDetailRequest(requestId, atomId)) return;

    final response = await _noteListManager.loadNoteDetail(atomId: atomId);
    if (_staleDetailRequest(requestId, atomId)) return;

    if (!response.ok) {
      _detailLoading = false;
      _detailErrorMessage = _envelopeError(...);
    } else if (response.item case final note?) {
      _noteListManager.upsertNote(note, updatePersisted: true);
      // buffer.initialize() if still loading...
      _detailLoading = false;
      _detailLoadedAtomId = note.atomId;
      _updateSaveStateFromBuffer();
    } else {
      _detailLoading = false;
      _detailErrorMessage = 'Note detail is empty.';
    }
  } catch (error) {
    if (_staleDetailRequest(requestId, atomId)) return;
    _detailLoading = false;
    _detailErrorMessage = '...';
  }

  if (!_disposed) notifyListeners(); // ② Result state (single call)
}
```

**辅助提取**：`_staleDetailRequest()` 消除 3 处重复的过期检查：

```dart
bool _staleDetailRequest(int requestId, String atomId) =>
    _disposed || requestId != _detailRequestId || atomId != activeNoteId;
```

### 4. 清理

| 项目 | 变更 |
|------|------|
| `_canReuseSelection()` 方法 | 删除（内联到 `selectNote`） |
| `_loadNotes()` 空分支 | 重构为 `!activeInList && !preserveActive` guard |
| `createNote()` 冗余 `_requestEditorFocus()` | 删除（`_openAndActivateTab` → `_syncActiveNoteState` 已包含） |
| `_loadNotes()` fallback 路径冗余 `_updateSaveStateFromBuffer` + `_requestEditorFocus` | 删除（`_openAndActivateTab` 内部已调用） |

## Coordinator 状态字段变更

### 删除

| 字段 | 类型 | 说明 |
|------|------|------|
| `_selectedNote` | `rust_api.AtomListItem?` | 改为 derived getter |

### 新增

| 字段 | 类型 | 说明 |
|------|------|------|
| `_detailLoadedAtomId` | `String?` | 最后一次 detail 加载成功的 atomId，用于 `selectNote()` 重用检查 |

### 新增方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `_syncActiveNoteState()` | `void` | 统一激活后状态同步（save state + focus + clear error） |
| `_staleDetailRequest()` | `bool (int requestId, String atomId)` | 过期 detail 请求检查 |

### 删除方法

| 方法 | 说明 |
|------|------|
| `_canReuseSelection()` | 内联到 `selectNote()` |

## File Changes

| # | 文件 | 变更 |
|---|------|------|
| 1 | `lib/features/notes/notes_coordinator_impl.dart` | Steps 1-4 全部变更 |
| 2 | `docs/architecture/modules/core-editor/editor-shell-service.md` | 更新 Coordinator 结构描述 |
| 3 | `docs/releases/v0.3/prs/PR-RB-08B-coordinator-cleanup.md` | 本文档 |

**不变的文件**：

- 公共 API（`notes_coordinator.dart`）— 无签名变更
- `EditorShellService` / `EditBuffer` / `GroupLayout` — 不改
- `NoteListManager` — 不改（`cachedNoteById()` 已满足需求）
- 测试文件 — 364 测试全绿，无需修改

## Review Fixes

Code review 后追加修复：

### Fix 1（HIGH）：`AtomNotFoundException` 映射过宽

**问题**：`_loadNoteContentFromFFI` 中 `response.item == null` 即抛 `AtomNotFoundException`，会把 `db_error` / `internal_error` 等非 not-found 失败也当成 atom 不存在，触发 `EditorShellService._removeAtomFromAllGroups()` 误删 tab。

**修复**：仅在 `response.errorCode == 'note_not_found'` 时抛 `AtomNotFoundException`；其他错误抛通用 `Exception`，由 `EditorShellService._loadBufferContent()` 的 generic catch 走 `buffer.markError()` 路径。

```dart
if (response.item == null) {
  if (response.errorCode == 'note_not_found') {
    throw AtomNotFoundException(atomId);
  }
  throw Exception(
    'Failed to load note $atomId: '
    '${response.errorCode ?? "unknown"} — ${response.message}',
  );
}
```

### Fix 2（MEDIUM）：restored-tabs 路径 fallback 漏 detail load

**问题**：restored 分支中 `activeId` 在 fallback 打开 first note 之前就固定了，后续即使 fallback 打开了 first note，也不会触发 `_loadSelectedDetail`。在 `activeTab` 恢复为 null 的边界场景下，详情面板不会加载。

**修复**：将 `activeId` 改为 `detailTargetId`，fallback 路径中赋值 `detailTargetId = first.atomId`，与 normal path 行为一致。

### Fix 3（LOW）：文档范围描述不准确

**问题**：Goal 段落声称"不涉及 `lib/core/editor/` 模块"，但 `editor-shell-service.md` spec 文档实际有更新。

**修复**：改为"代码变更仅限 `notes_coordinator_impl.dart`；`lib/core/editor/` 代码不变（该目录下的变更属于 PR-RB-08）。Spec 文档有同步更新。"

---

## Verification

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

| 验证项 | 结果 |
|--------|------|
| `dart format` | 0 changed |
| `flutter analyze` | No issues found |
| `flutter test` | 364/364 passed |
| `architecture_check` | 0 violations |

## Acceptance Criteria

- [x] `_selectedNote` 字段已删除，`selectedNote` getter 从 `cachedNoteById(activeNoteId)` 派生
- [x] `_syncActiveNoteState()` 统一 6 个激活路径的状态同步
- [x] `_loadSelectedDetail()` 通知从 5 次减至 2 次
- [x] `_staleDetailRequest()` 消除过期检查重复
- [x] `_canReuseSelection()` 已内联并删除
- [x] `_detailLoadedAtomId` 正确追踪 detail 加载完成状态
- [x] 公共 API 无变更
- [x] `AtomNotFoundException` 仅在 `note_not_found` error code 时抛出
- [x] Restored-tabs fallback 路径正确触发 `_loadSelectedDetail`
- [x] 364 测试全绿
- [x] §Verification CI gates 全部通过
