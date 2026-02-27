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
    required String initialPaneId,
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
  }) : _activePaneId = initialPaneId,
       _openNoteIdsByPane = {initialPaneId: <String>[]},
       _canReuseSelection = canReuseSelection,
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

  // ── Pane-scoped state ──────────────────────────────────────────────

  String _activePaneId;
  final Map<String, List<String>> _openNoteIdsByPane;
  String? _previewTabId;

  /// Returns the active pane's open note IDs (mutable internal reference).
  List<String> get _activeOpenNoteIds => _openNoteIdsByPane[_activePaneId]!;

  // ── Pane-scoped public API ─────────────────────────────────────────

  /// Current active pane identifier.
  String get activePaneId => _activePaneId;

  /// Returns an unmodifiable snapshot of open note IDs for [paneId].
  List<String> openNoteIdsForPane(String paneId) =>
      List.unmodifiable(_openNoteIdsByPane[paneId] ?? const <String>[]);

  /// Registers a new pane with an empty tab list.
  void addPane(String paneId) {
    _openNoteIdsByPane.putIfAbsent(paneId, () => <String>[]);
  }

  /// Removes [paneId] and merges its tabs into [mergeToPaneId].
  void removePane(String paneId, {required String mergeToPaneId}) {
    final removedTabs = _openNoteIdsByPane.remove(paneId) ?? <String>[];
    final targetTabs = _openNoteIdsByPane[mergeToPaneId];
    if (targetTabs != null) {
      for (final atomId in removedTabs) {
        if (!targetTabs.contains(atomId)) {
          targetTabs.add(atomId);
        }
      }
    }
    if (_activePaneId == paneId) {
      _activePaneId = mergeToPaneId;
    }
  }

  /// Switches active pane pointer (does not notify — caller is responsible).
  void switchPane(String paneId) {
    if (_openNoteIdsByPane.containsKey(paneId)) {
      _activePaneId = paneId;
    }
  }

  /// Adds a note to a specific pane's tab list.
  void addNoteToPane(String paneId, String atomId) {
    final tabs = _openNoteIdsByPane[paneId];
    if (tabs != null && !tabs.contains(atomId)) {
      tabs.add(atomId);
    }
  }

  /// Removes a note from a specific pane's tab list.
  void removeNoteFromPane(String paneId, String atomId) {
    _openNoteIdsByPane[paneId]?.remove(atomId);
  }

  // ── Active-pane tab accessors (backwards-compatible) ───────────────

  List<String> get openNoteIds => List.unmodifiable(_activeOpenNoteIds);
  String? get previewTabId => _previewTabId;
  bool isPreviewTab(String atomId) => _previewTabId == atomId;

  /// Checks whether [atomId] is open in ANY pane (cross-pane lookup).
  bool containsOpenNote(String atomId) =>
      _openNoteIdsByPane.values.any((ids) => ids.contains(atomId));

  /// Returns all unique open note IDs across ALL panes (deduplicated).
  List<String> get allOpenNoteIds {
    final seen = <String>{};
    final result = <String>[];
    for (final ids in _openNoteIdsByPane.values) {
      for (final id in ids) {
        if (seen.add(id)) {
          result.add(id);
        }
      }
    }
    return result;
  }

  /// Removes notes matching [test] from ALL panes.
  void removeOpenNotesWhereAllPanes(
    bool Function(String atomId) test, {
    bool notify = false,
  }) {
    for (final ids in _openNoteIdsByPane.values) {
      ids.removeWhere(test);
    }
    if (notify) {
      notifyListeners();
    }
  }

  int get openNoteCount => _activeOpenNoteIds.length;

  String openNoteIdAt(int index) => _activeOpenNoteIds[index];

  List<String> snapshotOpenNoteIds() => List<String>.from(_activeOpenNoteIds);

  void addOpenNoteIfAbsent(String atomId, {bool notify = false}) {
    if (_activeOpenNoteIds.contains(atomId)) {
      return;
    }
    _activeOpenNoteIds.add(atomId);
    if (notify) {
      notifyListeners();
    }
  }

  void removeOpenNotesWhere(
    bool Function(String atomId) test, {
    bool notify = false,
  }) {
    _activeOpenNoteIds.removeWhere(test);
    if (notify) {
      notifyListeners();
    }
  }

  void clearOpenNotes({bool notify = false}) {
    _activeOpenNoteIds.clear();
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
    if (_activeOpenNoteIds.contains(previewId)) {
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
    final alreadyOpened = _activeOpenNoteIds.contains(atomId);
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
    if (_activeOpenNoteIds.contains(atomId)) {
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

    if (!_activeOpenNoteIds.contains(atomId)) {
      _activeOpenNoteIds.add(atomId);
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
    final closedIndex = _activeOpenNoteIds.indexOf(atomId);
    if (closedIndex < 0) {
      return false;
    }
    if (_activeNoteId() == atomId) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }

    _activeOpenNoteIds.removeAt(closedIndex);
    reconcilePreviewTabState();
    if (_activeNoteId() != atomId) {
      _syncWorkspaceState();
      notifyListeners();
      return true;
    }

    if (_activeOpenNoteIds.isEmpty) {
      _clearSelection();
      _syncWorkspaceState();
      notifyListeners();
      return true;
    }

    final fallbackIndex = (closedIndex - 1).clamp(
      0,
      _activeOpenNoteIds.length - 1,
    );
    final fallbackId = _activeOpenNoteIds[fallbackIndex];
    _activateSelection(fallbackId);
    _syncWorkspaceState();
    notifyListeners();
    await _loadSelectedDetail(fallbackId);
    return true;
  }

  Future<bool> closeOtherOpenNotes(String atomId) async {
    if (!_activeOpenNoteIds.contains(atomId)) {
      return false;
    }
    final switched = await activateOpenNote(atomId);
    if (!switched) {
      return false;
    }
    _activeOpenNoteIds
      ..clear()
      ..add(atomId);
    reconcilePreviewTabState();
    _syncWorkspaceState();
    notifyListeners();
    return true;
  }

  Future<bool> closeOpenNotesToRight(String atomId) async {
    final index = _activeOpenNoteIds.indexOf(atomId);
    if (index < 0) {
      return false;
    }
    if (index == _activeOpenNoteIds.length - 1) {
      return true;
    }

    final activeId = _activeNoteId();
    final willPruneActive =
        activeId != null && _activeOpenNoteIds.indexOf(activeId) > index;
    if (willPruneActive) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }
    _activeOpenNoteIds.removeRange(index + 1, _activeOpenNoteIds.length);
    reconcilePreviewTabState();
    if (!_activeOpenNoteIds.contains(_activeNoteId())) {
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
    final previewIndex = _activeOpenNoteIds.indexOf(previewId);
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

    _activeOpenNoteIds[previewIndex] = atomId;
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
