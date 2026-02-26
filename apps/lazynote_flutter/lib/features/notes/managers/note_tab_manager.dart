import 'package:flutter/foundation.dart';

typedef TabCanReuseSelection = bool Function(String atomId);
typedef TabActiveNoteIdReader = String? Function();
typedef TabActivateSelection = void Function(String atomId);
typedef TabClearSelection = void Function();
typedef TabLoadSelectedDetail = Future<void> Function(String atomId);
typedef TabFlushPendingSave = Future<bool> Function();
typedef TabHasPendingSaveFor = bool Function(String atomId);
typedef TabSyncWorkspaceState = void Function();
typedef TabSyncWorkspaceActiveSnapshot = void Function();
typedef TabEvictNoteState = void Function(String atomId);
typedef TabScopedOpenNoteIdsReader = List<String> Function();
typedef TabScopedActiveNoteIdReader = String? Function();

class NoteTabStateManager extends ChangeNotifier {
  NoteTabStateManager({
    required TabCanReuseSelection canReuseSelection,
    required TabActiveNoteIdReader activeNoteId,
    required TabActivateSelection activateSelection,
    required TabClearSelection clearSelection,
    required TabLoadSelectedDetail loadSelectedDetail,
    required TabFlushPendingSave flushPendingSave,
    required TabHasPendingSaveFor hasPendingSaveFor,
    required TabSyncWorkspaceState syncWorkspaceState,
    required TabSyncWorkspaceActiveSnapshot syncWorkspaceActiveSnapshot,
    required TabEvictNoteState evictNoteState,
    required TabScopedOpenNoteIdsReader scopedOpenNoteIds,
    required TabScopedActiveNoteIdReader scopedActiveNoteId,
  }) : _canReuseSelection = canReuseSelection,
       _activeNoteId = activeNoteId,
       _activateSelection = activateSelection,
       _clearSelection = clearSelection,
       _loadSelectedDetail = loadSelectedDetail,
       _flushPendingSave = flushPendingSave,
       _hasPendingSaveFor = hasPendingSaveFor,
       _syncWorkspaceState = syncWorkspaceState,
       _syncWorkspaceActiveSnapshot = syncWorkspaceActiveSnapshot,
       _evictNoteState = evictNoteState,
       _scopedOpenNoteIds = scopedOpenNoteIds,
       _scopedActiveNoteId = scopedActiveNoteId;

  final TabCanReuseSelection _canReuseSelection;
  final TabActiveNoteIdReader _activeNoteId;
  final TabActivateSelection _activateSelection;
  final TabClearSelection _clearSelection;
  final TabLoadSelectedDetail _loadSelectedDetail;
  final TabFlushPendingSave _flushPendingSave;
  final TabHasPendingSaveFor _hasPendingSaveFor;
  final TabSyncWorkspaceState _syncWorkspaceState;
  final TabSyncWorkspaceActiveSnapshot _syncWorkspaceActiveSnapshot;
  final TabEvictNoteState _evictNoteState;
  final TabScopedOpenNoteIdsReader _scopedOpenNoteIds;
  final TabScopedActiveNoteIdReader _scopedActiveNoteId;

  final List<String> _openNoteIds = <String>[];
  String? _previewTabId;

  List<String> get openNoteIds => List.unmodifiable(_openNoteIds);
  String? get previewTabId => _previewTabId;
  bool isPreviewTab(String atomId) => _previewTabId == atomId;
  bool containsOpenNote(String atomId) => _openNoteIds.contains(atomId);
  int get openNoteCount => _openNoteIds.length;

  String openNoteIdAt(int index) => _openNoteIds[index];

  List<String> snapshotOpenNoteIds() => List<String>.from(_openNoteIds);

  void addOpenNoteIfAbsent(String atomId, {bool notify = false}) {
    if (_openNoteIds.contains(atomId)) {
      return;
    }
    _openNoteIds.add(atomId);
    if (notify) {
      notifyListeners();
    }
  }

  void removeOpenNotesWhere(
    bool Function(String atomId) test, {
    bool notify = false,
  }) {
    _openNoteIds.removeWhere(test);
    if (notify) {
      notifyListeners();
    }
  }

  void clearOpenNotes({bool notify = false}) {
    _openNoteIds.clear();
    if (notify) {
      notifyListeners();
    }
  }

  void clearPreviewForDeletedAtom(String atomId, {bool notify = false}) {
    if (_previewTabId != atomId) {
      return;
    }
    _previewTabId = null;
    if (notify) {
      notifyListeners();
    }
  }

  void reconcilePreviewTabState({bool notify = false}) {
    final previewId = _previewTabId;
    if (previewId == null) {
      return;
    }
    if (_openNoteIds.contains(previewId)) {
      return;
    }
    _previewTabId = null;
    if (notify) {
      notifyListeners();
    }
  }

  void onDraftEdited(String atomId, {bool notify = false}) {
    if (_previewTabId != atomId) {
      return;
    }
    _previewTabId = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> openNoteFromExplorer(String atomId) async {
    final alreadyOpened = _openNoteIds.contains(atomId);
    String? replacePreviewId;
    if (!alreadyOpened) {
      final previousPreviewId = _previewTabId;
      if (previousPreviewId != null && previousPreviewId != atomId) {
        if (_hasPendingSaveFor(previousPreviewId)) {
          _previewTabId = null;
        } else {
          replacePreviewId = previousPreviewId;
        }
      }
    }

    if (replacePreviewId != null) {
      return _selectFromExplorerByReplacingPreview(
        atomId: atomId,
        previewId: replacePreviewId,
      );
    }

    if (!alreadyOpened) {
      _previewTabId = atomId;
    }
    final switched = await selectNote(atomId);
    if (!switched) {
      if (!alreadyOpened && _previewTabId == atomId) {
        _previewTabId = null;
      }
      return false;
    }
    return true;
  }

  Future<bool> openNoteFromExplorerPinned(String atomId) async {
    if (_activeNoteId() == atomId) {
      pinPreviewTab(atomId);
      return true;
    }
    if (_openNoteIds.contains(atomId)) {
      final switched = await selectNote(atomId);
      if (!switched) {
        return false;
      }
      pinPreviewTab(atomId);
      return true;
    }
    final opened = await openNoteFromExplorer(atomId);
    if (!opened) {
      return false;
    }
    pinPreviewTab(atomId);
    return true;
  }

  void pinPreviewTab(String atomId) {
    if (_previewTabId != atomId) {
      return;
    }
    _previewTabId = null;
    notifyListeners();
  }

  Future<bool> selectNote(String atomId) async {
    if (_canReuseSelection(atomId)) {
      return true;
    }

    if (_activeNoteId() case final activeId? when activeId != atomId) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }

    if (!_openNoteIds.contains(atomId)) {
      _openNoteIds.add(atomId);
    }
    _activateSelection(atomId);
    _syncWorkspaceState();
    _syncWorkspaceActiveSnapshot();
    notifyListeners();

    await _loadSelectedDetail(atomId);
    return true;
  }

  Future<bool> activateOpenNote(String atomId) async {
    return selectNote(atomId);
  }

  Future<void> activateNextOpenNote() async {
    final scopedOpenNoteIds = _scopedOpenNoteIds();
    final scopedActiveNoteId = _scopedActiveNoteId();
    if (scopedOpenNoteIds.length <= 1 || scopedActiveNoteId == null) {
      return;
    }
    final currentIndex = scopedOpenNoteIds.indexOf(scopedActiveNoteId);
    if (currentIndex < 0) {
      return;
    }
    final nextIndex = (currentIndex + 1) % scopedOpenNoteIds.length;
    await activateOpenNote(scopedOpenNoteIds[nextIndex]);
  }

  Future<void> activatePreviousOpenNote() async {
    final scopedOpenNoteIds = _scopedOpenNoteIds();
    final scopedActiveNoteId = _scopedActiveNoteId();
    if (scopedOpenNoteIds.length <= 1 || scopedActiveNoteId == null) {
      return;
    }
    final currentIndex = scopedOpenNoteIds.indexOf(scopedActiveNoteId);
    if (currentIndex < 0) {
      return;
    }
    final prevIndex =
        (currentIndex - 1 + scopedOpenNoteIds.length) %
        scopedOpenNoteIds.length;
    await activateOpenNote(scopedOpenNoteIds[prevIndex]);
  }

  Future<bool> closeOpenNote(String atomId) async {
    final closedIndex = _openNoteIds.indexOf(atomId);
    if (closedIndex < 0) {
      return false;
    }
    if (_activeNoteId() == atomId) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }

    _openNoteIds.removeAt(closedIndex);
    reconcilePreviewTabState();
    if (_activeNoteId() != atomId) {
      _syncWorkspaceState();
      notifyListeners();
      return true;
    }

    if (_openNoteIds.isEmpty) {
      _clearSelection();
      _syncWorkspaceState();
      notifyListeners();
      return true;
    }

    final fallbackIndex = (closedIndex - 1).clamp(0, _openNoteIds.length - 1);
    final fallbackId = _openNoteIds[fallbackIndex];
    _activateSelection(fallbackId);
    _syncWorkspaceState();
    notifyListeners();
    await _loadSelectedDetail(fallbackId);
    return true;
  }

  Future<bool> closeOtherOpenNotes(String atomId) async {
    if (!_openNoteIds.contains(atomId)) {
      return false;
    }
    final switched = await activateOpenNote(atomId);
    if (!switched) {
      return false;
    }
    _openNoteIds
      ..clear()
      ..add(atomId);
    reconcilePreviewTabState();
    _syncWorkspaceState();
    notifyListeners();
    return true;
  }

  Future<bool> closeOpenNotesToRight(String atomId) async {
    final index = _openNoteIds.indexOf(atomId);
    if (index < 0) {
      return false;
    }
    if (index == _openNoteIds.length - 1) {
      return true;
    }

    final activeId = _activeNoteId();
    final willPruneActive =
        activeId != null && _openNoteIds.indexOf(activeId) > index;
    if (willPruneActive) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }
    _openNoteIds.removeRange(index + 1, _openNoteIds.length);
    reconcilePreviewTabState();
    if (!_openNoteIds.contains(_activeNoteId())) {
      _activateSelection(atomId);
      _syncWorkspaceState();
      notifyListeners();
      await _loadSelectedDetail(atomId);
      return true;
    }
    _syncWorkspaceState();
    notifyListeners();
    return true;
  }

  Future<bool> _selectFromExplorerByReplacingPreview({
    required String atomId,
    required String previewId,
  }) async {
    final previewIndex = _openNoteIds.indexOf(previewId);
    if (previewIndex < 0) {
      _previewTabId = atomId;
      return selectNote(atomId);
    }
    if (_activeNoteId() case final activeId? when activeId != atomId) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }

    _openNoteIds[previewIndex] = atomId;
    _evictNoteState(previewId);
    _activateSelection(atomId);
    _previewTabId = atomId;
    _syncWorkspaceState();
    _syncWorkspaceActiveSnapshot();
    notifyListeners();

    await _loadSelectedDetail(atomId);
    return true;
  }
}
