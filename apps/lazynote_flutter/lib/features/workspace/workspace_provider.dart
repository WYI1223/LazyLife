import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/features/workspace/workspace_models.dart';

/// Async saver used by workspace buffers.
typedef WorkspaceSaveInvoker =
    Future<bool> Function({required String noteId, required String content});

/// Async tag mutation used by workspace queue.
typedef WorkspaceTagMutationInvoker =
    Future<bool> Function({required String noteId, required List<String> tags});

/// Timer factory for autosave debounce.
typedef WorkspaceDebounceTimerFactory =
    Timer Function(Duration duration, void Function() callback);

/// Workspace runtime owner for pane/tab/buffer/save state.
class WorkspaceProvider extends ChangeNotifier {
  /// Hard cap for v0.2 non-recursive split baseline.
  static const int maxPaneCount = 4;

  /// Minimum pixel size for each pane after split.
  static const double minPaneExtent = 200;

  /// Creates a workspace state owner with injectable persistence hooks.
  ///
  /// The injected callbacks are used by tests and diagnostics to simulate
  /// save/tag behavior without touching the real bridge implementation.
  WorkspaceProvider({
    WorkspaceSaveInvoker? saveInvoker,
    WorkspaceTagMutationInvoker? tagMutationInvoker,
    WorkspaceDebounceTimerFactory? debounceTimerFactory,
    this.autosaveDebounce = const Duration(milliseconds: 800),
    this.flushMaxRetries = 5,
    this.autosaveEnabled = true,
  }) : _saveInvoker = saveInvoker ?? _defaultSaveInvoker,
       _tagMutationInvoker = tagMutationInvoker ?? _defaultTagMutationInvoker,
       _debounceTimerFactory = debounceTimerFactory ?? Timer.new {
    final paneId = _layoutState.primaryPaneId;
    _activePaneId = paneId;
    _openTabsByPane[paneId] = <String>[];
    _activeTabByPane[paneId] = null;
  }

  final WorkspaceSaveInvoker _saveInvoker;
  final WorkspaceTagMutationInvoker _tagMutationInvoker;
  final WorkspaceDebounceTimerFactory _debounceTimerFactory;

  /// Debounce delay before autosave starts.
  final Duration autosaveDebounce;

  /// Maximum flush retry attempts for one request.
  final int flushMaxRetries;

  /// Whether draft updates should schedule internal autosave.
  final bool autosaveEnabled;

  WorkspaceLayoutState _layoutState = WorkspaceLayoutState.singlePane();
  String _activePaneId = '';
  int _nextPaneSequence = 1;

  final Map<String, List<String>> _openTabsByPane = <String, List<String>>{};
  final Map<String, String?> _activeTabByPane = <String, String?>{};
  final Map<String, WorkspaceNoteBuffer> _buffersByNoteId =
      <String, WorkspaceNoteBuffer>{};
  final Map<String, WorkspaceSaveState> _saveStateByNoteId =
      <String, WorkspaceSaveState>{};
  final Map<String, Timer> _saveDebounceByNoteId = <String, Timer>{};
  final Map<String, Future<bool>> _saveInFlightByNoteId =
      <String, Future<bool>>{};
  final Map<String, Future<void>> _tagMutationQueueByNoteId =
      <String, Future<void>>{};
  int _syncBatchDepth = 0;
  bool _pendingNotify = false;

  /// Current workspace layout snapshot.
  WorkspaceLayoutState get layoutState => _layoutState;

  /// Active pane identifier.
  String get activePaneId => _activePaneId;

  /// Active note id in current pane, if any.
  String? get activeNoteId => _activeTabByPane[_activePaneId];

  /// Active editor draft is always derived from note buffer map.
  String get activeDraftContent {
    final active = activeNoteId;
    if (active == null) {
      return '';
    }
    return _buffersByNoteId[active]?.draftContent ?? '';
  }

  /// Read-only open tab ids grouped by pane id.
  Map<String, List<String>> get openTabsByPane => UnmodifiableMapView(
    _openTabsByPane.map(
      (key, value) =>
          MapEntry<String, List<String>>(key, List.unmodifiable(value)),
    ),
  );

  /// Read-only active tab id by pane id.
  Map<String, String?> get activeTabByPane =>
      UnmodifiableMapView(_activeTabByPane);

  /// Read-only note buffers by note id.
  Map<String, WorkspaceNoteBuffer> get buffersByNoteId =>
      UnmodifiableMapView(_buffersByNoteId);

  /// Read-only save states by note id.
  Map<String, WorkspaceSaveState> get saveStateByNoteId =>
      UnmodifiableMapView(_saveStateByNoteId);

  @override
  void dispose() {
    for (final timer in _saveDebounceByNoteId.values) {
      timer.cancel();
    }
    _saveDebounceByNoteId.clear();
    super.dispose();
  }

  /// Batches multiple state mutations into one final notification.
  void beginBatchSync() {
    _syncBatchDepth += 1;
  }

  /// Ends one batch scope and emits one notification when needed.
  void endBatchSync() {
    if (_syncBatchDepth == 0) {
      return;
    }
    _syncBatchDepth -= 1;
    if (_syncBatchDepth == 0 && _pendingNotify) {
      _pendingNotify = false;
      notifyListeners();
    }
  }

  void _markChanged() {
    if (_syncBatchDepth > 0) {
      _pendingNotify = true;
      return;
    }
    notifyListeners();
  }

  /// Switches the active pane pointer and lazily initializes pane maps.
  void switchActivePane(String paneId) {
    if (_activePaneId == paneId) {
      return;
    }
    if (!_layoutState.paneOrder.contains(paneId)) {
      return;
    }
    _openTabsByPane.putIfAbsent(paneId, () => <String>[]);
    _activeTabByPane.putIfAbsent(paneId, () => null);
    _activePaneId = paneId;
    _markChanged();
  }

  /// Splits the active pane in root layout (v0.2 non-recursive baseline).
  ///
  /// The caller should pass the available size in the split axis:
  /// - horizontal: content width
  /// - vertical: content height
  WorkspaceSplitResult splitActivePane({
    required WorkspaceSplitDirection direction,
    required double containerExtent,
  }) {
    final paneOrder = _layoutState.paneOrder;
    final paneCount = paneOrder.length;
    if (paneCount >= maxPaneCount) {
      return WorkspaceSplitResult.maxPanesReached;
    }
    final activeIndex = paneOrder.indexOf(_activePaneId);
    if (activeIndex < 0) {
      return WorkspaceSplitResult.paneNotFound;
    }
    if (paneCount > 1 && _layoutState.splitDirection != direction) {
      return WorkspaceSplitResult.directionLocked;
    }
    if (!_hasMinExtentForPaneCount(
      paneCount: paneCount + 1,
      containerExtent: containerExtent,
    )) {
      return WorkspaceSplitResult.minSizeBlocked;
    }

    final nextOrder = List<String>.from(_layoutState.paneOrder);
    final nextFractions = List<double>.from(_layoutState.paneFractions);
    final activeFraction = nextFractions[activeIndex];
    final splitFraction = activeFraction / 2;
    final newPaneId = _newPaneId();
    nextOrder.insert(activeIndex + 1, newPaneId);
    nextFractions[activeIndex] = splitFraction;
    nextFractions.insert(activeIndex + 1, splitFraction);

    if (!_hasMinExtentForFractions(
      paneFractions: nextFractions,
      containerExtent: containerExtent,
    )) {
      return WorkspaceSplitResult.minSizeBlocked;
    }

    _layoutState = _layoutState.copyWith(
      paneOrder: nextOrder,
      paneFractions: _normalizeFractions(nextFractions),
      splitDirection: direction,
    );
    _openTabsByPane[newPaneId] = <String>[];
    _activeTabByPane[newPaneId] = null;
    _activePaneId = newPaneId;
    _markChanged();
    return WorkspaceSplitResult.ok;
  }

  /// Closes current active pane and merges its tabs into adjacent pane.
  ///
  /// Merge target policy:
  /// - prefer previous pane in layout order
  /// - when closing first pane, use next pane
  WorkspaceMergeResult closeActivePane() {
    final paneOrder = _layoutState.paneOrder;
    if (paneOrder.length <= 1) {
      return WorkspaceMergeResult.singlePaneBlocked;
    }

    final closingPaneId = _activePaneId;
    final closingIndex = paneOrder.indexOf(closingPaneId);
    if (closingIndex < 0) {
      return WorkspaceMergeResult.paneNotFound;
    }

    final targetIndex = closingIndex > 0 ? closingIndex - 1 : 1;
    final targetPaneId = paneOrder[targetIndex];
    final targetTabs = _openTabsByPane.putIfAbsent(
      targetPaneId,
      () => <String>[],
    );
    final closingTabs = List<String>.from(
      _openTabsByPane[closingPaneId] ?? const <String>[],
    );
    final closingActive = _activeTabByPane[closingPaneId];

    for (final noteId in closingTabs) {
      if (!targetTabs.contains(noteId)) {
        targetTabs.add(noteId);
      }
    }

    final currentTargetActive = _activeTabByPane[targetPaneId];
    final nextTargetActive = () {
      if (closingActive != null && targetTabs.contains(closingActive)) {
        return closingActive;
      }
      if (currentTargetActive != null &&
          targetTabs.contains(currentTargetActive)) {
        return currentTargetActive;
      }
      if (targetTabs.isNotEmpty) {
        return targetTabs.last;
      }
      return null;
    }();

    _openTabsByPane.remove(closingPaneId);
    _activeTabByPane.remove(closingPaneId);
    _activeTabByPane[targetPaneId] = nextTargetActive;
    _activePaneId = targetPaneId;

    final nextOrder = List<String>.from(paneOrder)..removeAt(closingIndex);
    final nextFractions = List<double>.from(_layoutState.paneFractions)
      ..removeAt(closingIndex);
    _layoutState = _layoutState.copyWith(
      paneOrder: nextOrder,
      paneFractions: _normalizeFractions(nextFractions),
    );
    _markChanged();
    return WorkspaceMergeResult.ok;
  }

  /// Opens one note tab in the target pane and initializes its buffer.
  void openNote({
    required String noteId,
    required String initialContent,
    String? paneId,
  }) {
    final targetPaneId = _resolveTargetPaneId(paneId);
    final tabs = _openTabsByPane.putIfAbsent(targetPaneId, () => <String>[]);
    if (!tabs.contains(noteId)) {
      tabs.add(noteId);
    }
    _activeTabByPane[targetPaneId] = noteId;
    _activePaneId = targetPaneId;

    _buffersByNoteId.putIfAbsent(
      noteId,
      () => WorkspaceNoteBuffer(
        noteId: noteId,
        persistedContent: initialContent,
        draftContent: initialContent,
        version: 0,
      ),
    );
    _saveStateByNoteId.putIfAbsent(noteId, () => WorkspaceSaveState.clean);
    _markChanged();
  }

  /// Activates an already-open note tab in the target pane.
  void activateNote({required String noteId, String? paneId}) {
    final targetPaneId = _resolveTargetPaneId(paneId);
    final tabs = _openTabsByPane.putIfAbsent(targetPaneId, () => <String>[]);
    if (!tabs.contains(noteId)) {
      return;
    }
    _activeTabByPane[targetPaneId] = noteId;
    _activePaneId = targetPaneId;
    _markChanged();
  }

  /// Closes one note tab from the target pane.
  ///
  /// When the note is no longer opened in any pane, related runtime state
  /// (buffer/save state/debounce/in-flight marker) is cleaned up.
  void closeNote({required String noteId, String? paneId}) {
    final targetPaneId = _resolveTargetPaneId(paneId);
    final tabs = _openTabsByPane[targetPaneId];
    if (tabs == null || !tabs.remove(noteId)) {
      return;
    }
    final active = _activeTabByPane[targetPaneId];
    if (active == noteId) {
      _activeTabByPane[targetPaneId] = tabs.isEmpty ? null : tabs.last;
    }

    if (!_isNoteOpen(noteId)) {
      _saveDebounceByNoteId.remove(noteId)?.cancel();
      _saveInFlightByNoteId.remove(noteId);
      _saveStateByNoteId.remove(noteId);
      _buffersByNoteId.remove(noteId);
    }
    _markChanged();
  }

  /// Updates one note draft and schedules autosave when enabled.
  void updateDraft({required String noteId, required String content}) {
    final current = _buffersByNoteId[noteId];
    if (current == null) {
      return;
    }
    if (current.draftContent == content) {
      return;
    }
    _buffersByNoteId[noteId] = current.copyWith(
      draftContent: content,
      version: current.version + 1,
    );
    _saveStateByNoteId[noteId] = WorkspaceSaveState.dirty;
    if (autosaveEnabled) {
      _scheduleAutosave(noteId);
    }
    _markChanged();
  }

  /// Sync one note snapshot from external owner (e.g. NotesController).
  void syncExternalNote({
    required String noteId,
    required String persistedContent,
    required String draftContent,
    WorkspaceSaveState? saveState,
    bool activate = false,
    String? paneId,
  }) {
    final targetPaneId = _resolveTargetPaneId(paneId);
    final tabs = _openTabsByPane.putIfAbsent(targetPaneId, () => <String>[]);
    if (!tabs.contains(noteId)) {
      tabs.add(noteId);
    }
    if (activate) {
      _activePaneId = targetPaneId;
      _activeTabByPane[targetPaneId] = noteId;
    } else {
      final currentActive = _activeTabByPane[targetPaneId];
      if (currentActive == null || !tabs.contains(currentActive)) {
        _activeTabByPane[targetPaneId] = noteId;
      }
    }

    final previous = _buffersByNoteId[noteId];
    _buffersByNoteId[noteId] = WorkspaceNoteBuffer(
      noteId: noteId,
      persistedContent: persistedContent,
      draftContent: draftContent,
      version: previous?.version ?? 0,
    );
    _saveStateByNoteId[noteId] =
        saveState ??
        (draftContent == persistedContent
            ? WorkspaceSaveState.clean
            : WorkspaceSaveState.dirty);
    _markChanged();
  }

  /// Sync save-state only for existing note buffer.
  void syncSaveState({
    required String noteId,
    required WorkspaceSaveState saveState,
  }) {
    if (!_buffersByNoteId.containsKey(noteId)) {
      return;
    }
    _saveStateByNoteId[noteId] = saveState;
    _markChanged();
  }

  /// Clears pane/tab/buffer/save state.
  void resetAll() {
    for (final timer in _saveDebounceByNoteId.values) {
      timer.cancel();
    }
    _saveDebounceByNoteId.clear();
    _saveInFlightByNoteId.clear();
    _tagMutationQueueByNoteId.clear();
    _openTabsByPane.clear();
    _activeTabByPane.clear();
    for (final paneId in _layoutState.paneOrder) {
      _openTabsByPane[paneId] = <String>[];
      _activeTabByPane[paneId] = null;
    }
    _buffersByNoteId.clear();
    _saveStateByNoteId.clear();
    if (!_layoutState.paneOrder.contains(_activePaneId)) {
      _activePaneId = _layoutState.primaryPaneId;
    }
    _markChanged();
  }

  /// Flushes the currently active note if one exists.
  Future<bool> flushActiveNote() async {
    final noteId = activeNoteId;
    if (noteId == null) {
      return true;
    }
    return flushNote(noteId);
  }

  /// Flushes one note draft to persistence with bounded retry.
  ///
  /// Returns `true` when the latest visible draft is persisted or already clean.
  /// Returns `false` when retries are exhausted or save keeps failing.
  Future<bool> flushNote(String noteId) async {
    _saveDebounceByNoteId.remove(noteId)?.cancel();
    for (var attempt = 0; attempt < flushMaxRetries; attempt += 1) {
      final buffer = _buffersByNoteId[noteId];
      if (buffer == null) {
        if (_saveStateByNoteId.remove(noteId) != null) {
          _markChanged();
        }
        return true;
      }
      if (!buffer.isDirty) {
        _saveStateByNoteId[noteId] = WorkspaceSaveState.clean;
        _markChanged();
        return true;
      }
      final expectedVersion = buffer.version;
      final saved = await _saveDraftVersion(
        noteId: noteId,
        expectedVersion: expectedVersion,
      );
      final latest = _buffersByNoteId[noteId];
      if (saved && latest != null && !latest.isDirty) {
        return true;
      }
      if (latest != null && latest.version != expectedVersion) {
        continue;
      }
    }
    if (_buffersByNoteId.containsKey(noteId)) {
      _saveStateByNoteId[noteId] = WorkspaceSaveState.saveError;
      _markChanged();
    }
    return false;
  }

  /// Enqueues one tag mutation request per note with in-order execution.
  ///
  /// Calls for the same note are serialized to avoid out-of-order tag writes.
  Future<bool> enqueueTagMutation({
    required String noteId,
    required List<String> tags,
  }) {
    if (!_isNoteOpen(noteId)) {
      return Future<bool>.value(false);
    }

    final previous = _tagMutationQueueByNoteId[noteId] ?? Future<void>.value();
    final completer = Completer<bool>();
    late final Future<void> queued;
    queued = previous
        .catchError((_) {})
        .then((_) async {
          if (!_isNoteOpen(noteId)) {
            completer.complete(false);
            return;
          }
          final ok = await _tagMutationInvoker(noteId: noteId, tags: tags);
          if (!_isNoteOpen(noteId)) {
            completer.complete(false);
            return;
          }
          completer.complete(ok);
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        })
        .whenComplete(() {
          if (identical(_tagMutationQueueByNoteId[noteId], queued)) {
            _tagMutationQueueByNoteId.remove(noteId);
          }
        });
    _tagMutationQueueByNoteId[noteId] = queued;
    return completer.future;
  }

  void _scheduleAutosave(String noteId) {
    _saveDebounceByNoteId.remove(noteId)?.cancel();
    _saveDebounceByNoteId[noteId] = _debounceTimerFactory(autosaveDebounce, () {
      unawaited(flushNote(noteId).catchError((_) => false));
    });
  }

  Future<bool> _saveDraftVersion({
    required String noteId,
    required int expectedVersion,
  }) async {
    final current = _buffersByNoteId[noteId];
    if (current == null) {
      return false;
    }

    if (_saveInFlightByNoteId[noteId] case final inflight?) {
      try {
        await inflight;
      } catch (_) {}
      return false;
    }

    _saveStateByNoteId[noteId] = WorkspaceSaveState.saving;
    _markChanged();

    final future = _saveInvoker(noteId: noteId, content: current.draftContent);
    _saveInFlightByNoteId[noteId] = future;
    bool ok;
    try {
      ok = await future;
    } catch (_) {
      if (_buffersByNoteId.containsKey(noteId)) {
        _saveStateByNoteId[noteId] = WorkspaceSaveState.saveError;
        _markChanged();
      }
      return false;
    } finally {
      _saveInFlightByNoteId.remove(noteId);
    }

    final latest = _buffersByNoteId[noteId];
    if (latest == null) {
      return false;
    }
    if (!ok) {
      _saveStateByNoteId[noteId] = WorkspaceSaveState.saveError;
      _markChanged();
      return false;
    }
    if (latest.version != expectedVersion) {
      _saveStateByNoteId[noteId] = WorkspaceSaveState.dirty;
      _markChanged();
      return false;
    }

    _buffersByNoteId[noteId] = latest.copyWith(
      persistedContent: latest.draftContent,
    );
    _saveStateByNoteId[noteId] = WorkspaceSaveState.clean;
    _markChanged();
    return true;
  }

  bool _isNoteOpen(String noteId) {
    for (final tabs in _openTabsByPane.values) {
      if (tabs.contains(noteId)) {
        return true;
      }
    }
    return false;
  }

  String _resolveTargetPaneId(String? paneId) {
    if (paneId != null && _layoutState.paneOrder.contains(paneId)) {
      return paneId;
    }
    return _activePaneId;
  }

  String _newPaneId() {
    while (true) {
      final paneId = 'pane.split.$_nextPaneSequence';
      _nextPaneSequence += 1;
      if (!_layoutState.paneOrder.contains(paneId)) {
        return paneId;
      }
    }
  }

  static bool _hasMinExtentForPaneCount({
    required int paneCount,
    required double containerExtent,
  }) {
    if (!containerExtent.isFinite || containerExtent <= 0) {
      return false;
    }
    return containerExtent >= (paneCount * minPaneExtent);
  }

  static bool _hasMinExtentForFractions({
    required List<double> paneFractions,
    required double containerExtent,
  }) {
    for (final fraction in paneFractions) {
      if ((fraction * containerExtent) < minPaneExtent) {
        return false;
      }
    }
    return true;
  }

  static List<double> _normalizeFractions(List<double> paneFractions) {
    final sum = paneFractions.fold<double>(0, (total, item) => total + item);
    if (sum == 0) {
      return paneFractions;
    }
    return paneFractions.map((item) => item / sum).toList(growable: false);
  }
}

Future<bool> _defaultSaveInvoker({
  required String noteId,
  required String content,
}) async {
  return true;
}

Future<bool> _defaultTagMutationInvoker({
  required String noteId,
  required List<String> tags,
}) async {
  return true;
}
