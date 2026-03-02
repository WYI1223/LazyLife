part of 'notes_coordinator.dart';

/// Stateful controller for Notes page list/detail baseline.
///
/// Contract:
/// - Owns list + detail lifecycle state for Notes shell.
/// - Handles tab-open/activate/close operations in-memory.
/// - Calls [notifyListeners] after every externally visible state transition.
class _NotesCoordinatorImpl extends ChangeNotifier {
  /// Creates controller with injectable bridge hooks for testability.
  ///
  /// Input semantics:
  /// - [notesListInvoker]: loads list snapshot (`notes_list` contract).
  /// - [noteGetInvoker]: loads one note detail (`note_get` contract).
  /// - [noteCreateInvoker]: creates one new note (`note_create` contract).
  /// - [noteUpdateInvoker]: persists full content replacement (`note_update`).
  /// - [debounceTimerFactory]: timer scheduler used by autosave debounce.
  /// - [prepare]: prerequisite hook before each bridge request.
  /// - [listLimit]: requested list page size for C1 baseline.
  /// - [autosaveDebounce]: quiet window before autosave starts.
  _NotesCoordinatorImpl({
    NotesListInvoker? notesListInvoker,
    NoteGetInvoker? noteGetInvoker,
    NoteCreateInvoker? noteCreateInvoker,
    NoteUpdateInvoker? noteUpdateInvoker,
    TagsListInvoker? tagsListInvoker,
    NoteSetTagsInvoker? noteSetTagsInvoker,
    WorkspaceDeleteFolderInvoker? workspaceDeleteFolderInvoker,
    WorkspaceCreateFolderInvoker? workspaceCreateFolderInvoker,
    WorkspaceRenameNodeInvoker? workspaceRenameNodeInvoker,
    WorkspaceMoveNodeInvoker? workspaceMoveNodeInvoker,
    WorkspaceListChildrenInvoker? workspaceListChildrenInvoker,
    WorkspaceProvider? workspaceProvider,
    DebounceTimerFactory? debounceTimerFactory,
    NotesPrepare? prepare,
    this.listLimit = 50,
    this.autosaveDebounce = const Duration(milliseconds: 1500),
    ReminderLifecycle? reminderLifecycle,
  }) : _noteCreateInvoker = noteCreateInvoker ?? _defaultNoteCreateInvoker,
       _noteUpdateInvoker = noteUpdateInvoker ?? _defaultNoteUpdateInvoker,
       _noteSetTagsInvoker = noteSetTagsInvoker ?? _defaultNoteSetTagsInvoker,
       _debounceTimerFactory = debounceTimerFactory ?? Timer.new,
       _reminderLifecycle = reminderLifecycle ?? ReminderLifecycle.instance,
       _prepare = prepare ?? _defaultPrepare {
    final resolvedNotesListInvoker =
        notesListInvoker ?? _defaultNotesListInvoker;
    final resolvedNoteGetInvoker = noteGetInvoker ?? _defaultNoteGetInvoker;
    final resolvedTagsListInvoker = tagsListInvoker ?? _defaultTagsListInvoker;
    final resolvedNoteSetTagsInvoker = _noteSetTagsInvoker;
    final resolvedWorkspaceDeleteFolderInvoker =
        workspaceDeleteFolderInvoker ?? _defaultWorkspaceDeleteFolderInvoker;
    final resolvedWorkspaceCreateFolderInvoker =
        workspaceCreateFolderInvoker ?? _defaultWorkspaceCreateFolderInvoker;
    final resolvedWorkspaceRenameNodeInvoker =
        workspaceRenameNodeInvoker ?? _defaultWorkspaceRenameNodeInvoker;
    final resolvedWorkspaceMoveNodeInvoker =
        workspaceMoveNodeInvoker ?? _defaultWorkspaceMoveNodeInvoker;
    final resolvedWorkspaceListChildrenInvoker =
        workspaceListChildrenInvoker ?? _defaultWorkspaceListChildrenInvoker;

    _workspaceProvider = workspaceProvider ?? WorkspaceProvider();
    _ownsWorkspaceProvider = workspaceProvider == null;
    _noteSaveTracker = NoteSaveTracker(timerFactory: _debounceTimerFactory);
    _noteSaveTracker.addListener(_handleNoteSaveTrackerChanged);
    _noteListManager = NoteListManager(
      notesListInvoker: resolvedNotesListInvoker,
      noteGetInvoker: resolvedNoteGetInvoker,
      prepare: _prepare,
      envelopeError: _envelopeError,
      selectedTag: () => selectedTag,
      shouldIncludeInVisibleList: _shouldIncludeInVisibleList,
      isDirty: _isDirty,
      syncPersistedSnapshot: _syncPersistedSnapshot,
    );
    _noteListManager.addListener(_handleNoteListManagerChanged);
    _noteDraftManager = NoteDraftManager(
      noteUpdateInvoker: _noteUpdateInvoker,
      prepare: _prepare,
      activeNoteId: () => _activeNoteId,
      noteById: _noteListManager.cachedNoteById,
      withContent: _withContent,
      upsertNote: _noteListManager.upsertNote,
      envelopeError: _envelopeError,
      applySaveState: _setSaveState,
      setSaveError: (message) =>
          _noteSaveTracker.setErrorMessage(message, notify: false),
      onActiveSaveSuccess: (atomId) {
        _selectedNote = _noteListManager.cachedNoteById(atomId);
        _switchBlockErrorMessage = null;
      },
      timerFactory: _debounceTimerFactory,
      autosaveDebounce: autosaveDebounce,
    );
    _noteDraftManager.addListener(_handleNoteDraftManagerChanged);
    _noteTabManager = NoteTabStateManager(
      initialPaneId: _workspaceProvider.activePaneId,
      canReuseSelection: _canReuseSelection,
      activeNoteId: () => _activeNoteId,
      activateSelection: _activateSelection,
      clearSelection: _clearSelection,
      loadSelectedDetail: (atomId) => _loadSelectedDetail(atomId: atomId),
      flushPendingSave: flushPendingSave,
      hasPendingSaveFor: _hasPendingSaveFor,
      evictNoteState: _evictNoteState,
      scopedOpenNoteIds: () => openNoteIds,
      scopedActiveNoteId: () => activeNoteId,
    );
    _noteTabManager.addListener(_handleNoteTabManagerChanged);
    _noteTagManager = NoteTagManager(
      tagsListInvoker: resolvedTagsListInvoker,
      noteSetTagsInvoker: resolvedNoteSetTagsInvoker,
      prepare: _prepare,
      envelopeError: _envelopeError,
      flushPendingSave: flushPendingSave,
      reloadNotesForFilter:
          ({required bool preserveActiveWhenFilteredOut}) async {
            await _loadNotes(
              resetSession: false,
              preserveActiveWhenFilteredOut: preserveActiveWhenFilteredOut,
              refreshTags: false,
            );
            return _noteListManager.listPhase != NotesListPhase.error;
          },
      activeNoteId: () => _activeNoteId,
      noteById: (atomId) => _noteListManager.noteById(atomId) ?? _selectedNote,
      upsertNote: _noteListManager.upsertNote,
      isDirty: _isDirty,
      setSaveState: _setSaveState,
      setSaveError: (message) =>
          _noteSaveTracker.setErrorMessage(message, notify: false),
      onActiveNoteUpdated: ({required atomId, required note}) {
        _selectedNote = note;
        _activeDraftContent = _draftContentByAtomId[atomId] ?? note.content;
        _switchBlockErrorMessage = null;
      },
    );
    _noteTagManager.addListener(_handleNoteTagManagerChanged);
    _workspaceTreeManager = WorkspaceTreeManager(
      workspaceDeleteFolderInvoker: resolvedWorkspaceDeleteFolderInvoker,
      workspaceCreateFolderInvoker: resolvedWorkspaceCreateFolderInvoker,
      workspaceRenameNodeInvoker: resolvedWorkspaceRenameNodeInvoker,
      workspaceMoveNodeInvoker: resolvedWorkspaceMoveNodeInvoker,
      workspaceListChildrenInvoker: resolvedWorkspaceListChildrenInvoker,
      prepare: _prepare,
      createNoteAndGetAtomId: _createNoteAndGetAtomId,
      flushPendingSave: flushPendingSave,
      onDeleteSuccess: _handleWorkspaceDeleteSuccess,
      noteById: noteById,
      listItems: () => _noteListManager.items,
    );
    _workspaceTreeManager.addListener(_handleWorkspaceTreeManagerChanged);
  }

  final NoteCreateInvoker _noteCreateInvoker;
  final NoteUpdateInvoker _noteUpdateInvoker;
  final NoteSetTagsInvoker _noteSetTagsInvoker;
  final DebounceTimerFactory _debounceTimerFactory;
  final ReminderLifecycle _reminderLifecycle;
  final NotesPrepare _prepare;
  late final WorkspaceProvider _workspaceProvider;
  late final bool _ownsWorkspaceProvider;
  late final NoteSaveTracker _noteSaveTracker;
  late final NoteListManager _noteListManager;
  late final NoteDraftManager _noteDraftManager;
  late final NoteTabStateManager _noteTabManager;
  late final NoteTagManager _noteTagManager;
  late final WorkspaceTreeManager _workspaceTreeManager;

  /// Requested list limit for C1 list baseline.
  final int listLimit;

  /// Debounce window used by autosave pipeline.
  final Duration autosaveDebounce;

  rust_api.AtomListItem? _selectedNote;
  bool _detailLoading = false;
  String? _detailErrorMessage;
  bool _creatingNote = false;
  String? _createErrorCode;
  String? _createErrorMessage;
  String? _createWarningMessage;
  Future<void>? _createTagApplyFuture;

  String? _activeNoteId;
  final Map<String, String?> _activeNoteIdByPane = <String, String?>{};
  int _editorFocusRequestId = 0;
  String? _switchBlockErrorMessage;

  int _detailRequestId = 0;
  bool _disposed = false;

  /// Current list phase.
  NotesListPhase get listPhase => _noteListManager.listPhase;

  /// Current list items from `notes_list`.
  List<rust_api.AtomListItem> get items => _noteListManager.items;

  /// Current list-level error message.
  String? get listErrorMessage => _noteListManager.listErrorMessage;

  /// Whether tag catalog request is currently in flight.
  bool get tagsLoading => _noteTagManager.tagsLoading;

  /// Normalized tags sorted alphabetically for filter UI.
  List<String> get availableTags => _noteTagManager.availableTags;

  /// Current tag catalog failure message.
  String? get tagsErrorMessage => _noteTagManager.tagsErrorMessage;

  /// Currently selected single-tag filter (`null` means unfiltered).
  String? get selectedTag => _noteTagManager.selectedTag;

  /// Currently selected note atom id.
  String? get selectedAtomId => _activeNoteId;

  /// Currently active tab note id.
  String? get activeNoteId => _activeNoteId;

  /// Current preview tab id (replaced by next explorer-open unless pinned).
  String? get previewTabId => _noteTabManager.previewTabId;

  /// Currently opened tab ids in order (reads from NoteTabStateManager).
  List<String> get openNoteIds {
    return _noteTabManager.openNoteIdsForPane(_workspaceProvider.activePaneId);
  }

  /// Whether one tab is currently marked as preview.
  bool isPreviewTab(String atomId) => _noteTabManager.isPreviewTab(atomId);

  /// Selected note detail payload used by right pane.
  rust_api.AtomListItem? get selectedNote => _selectedNote;

  /// Whether selected-note detail load is in flight.
  bool get detailLoading => _detailLoading;

  /// Current selected-note detail load error.
  String? get detailErrorMessage => _detailErrorMessage;

  /// Whether a create-note request is currently in flight.
  bool get creatingNote => _creatingNote;

  /// Current create-note failure message.
  String? get createErrorMessage => _createErrorMessage;

  /// Non-fatal create warning (e.g. contextual tag apply failed).
  String? get createWarningMessage => _createWarningMessage;

  /// Whether contextual create-tag apply is currently in flight.
  bool get createTagApplyInFlight => _createTagApplyFuture != null;

  /// Whether workspace folder delete request is currently in flight.
  bool get workspaceDeleteInFlight =>
      _workspaceTreeManager.workspaceDeleteInFlight;

  /// Last workspace folder delete failure message.
  String? get workspaceDeleteErrorMessage =>
      _workspaceTreeManager.workspaceDeleteErrorMessage;

  /// Whether workspace folder create request is currently in flight.
  bool get workspaceCreateFolderInFlight =>
      _workspaceTreeManager.workspaceCreateFolderInFlight;

  /// Last workspace folder create failure message.
  String? get workspaceCreateFolderErrorMessage =>
      _workspaceTreeManager.workspaceCreateFolderErrorMessage;

  /// Whether workspace node mutation request is currently in flight.
  bool get workspaceNodeMutationInFlight =>
      _workspaceTreeManager.workspaceNodeMutationInFlight;

  /// Last workspace node mutation failure message.
  String? get workspaceNodeMutationErrorMessage =>
      _workspaceTreeManager.workspaceNodeMutationErrorMessage;

  /// Monotonic revision bump for explorer tree refresh triggers.
  int get workspaceTreeRevision => _workspaceTreeManager.workspaceTreeRevision;

  /// Workspace state owner used by Notes bridge (M2).
  WorkspaceProvider get workspaceProvider => _workspaceProvider;

  /// Splits current active pane and keeps controller/editor routing aligned.
  WorkspaceSplitResult splitActivePane({
    required WorkspaceSplitDirection direction,
    required double containerExtent,
  }) {
    _activeNoteIdByPane[_workspaceProvider.activePaneId] = _activeNoteId;
    final result = _workspaceProvider.splitActivePane(
      direction: direction,
      containerExtent: containerExtent,
    );
    if (result != WorkspaceSplitResult.ok) {
      return result;
    }
    final newPaneId = _workspaceProvider.activePaneId;
    _noteTabManager.addPane(newPaneId);
    _noteTabManager.switchPane(newPaneId);
    _adoptWorkspaceActivePaneState(loadDetail: false);
    notifyListeners();
    return result;
  }

  /// Closes active pane and merges it into adjacent pane.
  WorkspaceMergeResult closeActivePane() {
    final closingPaneId = _workspaceProvider.activePaneId;
    final closingActiveId = _activeNoteId;
    final result = _workspaceProvider.closeActivePane();
    if (result != WorkspaceMergeResult.ok) {
      return result;
    }
    final targetPaneId = _workspaceProvider.activePaneId;
    _activeNoteIdByPane.remove(closingPaneId);
    // Carry closing pane's active note into target pane so it stays active
    // after merge (matches old WP merge behavior).
    if (closingActiveId != null) {
      _activeNoteIdByPane[targetPaneId] = closingActiveId;
    }
    _noteTabManager.removePane(closingPaneId, mergeToPaneId: targetPaneId);
    _noteTabManager.switchPane(targetPaneId);
    _adoptWorkspaceActivePaneState(loadDetail: false);
    notifyListeners();
    return result;
  }

  /// Switches active pane pointer and refreshes active editor target.
  bool switchActivePane(String paneId) {
    if (!_workspaceProvider.layoutState.paneOrder.contains(paneId)) {
      return false;
    }
    _activeNoteIdByPane[_workspaceProvider.activePaneId] = _activeNoteId;
    _workspaceProvider.switchActivePane(paneId);
    _noteTabManager.switchPane(paneId);
    _adoptWorkspaceActivePaneState();
    return true;
  }

  /// Cycles active pane focus in layout order.
  void activateNextPane() {
    final order = _workspaceProvider.layoutState.paneOrder;
    if (order.length <= 1) {
      return;
    }
    final currentIndex = order.indexOf(_workspaceProvider.activePaneId);
    if (currentIndex < 0) {
      return;
    }
    final nextPaneId = order[(currentIndex + 1) % order.length];
    switchActivePane(nextPaneId);
  }

  /// Returns and clears the latest non-fatal create warning.
  String? takeCreateWarningMessage() {
    final warning = _createWarningMessage;
    _createWarningMessage = null;
    return warning;
  }

  /// Save lifecycle state for active note.
  NoteSaveState get noteSaveState => _noteSaveTracker.noteSaveState;

  /// Last save error message for active note.
  String? get saveErrorMessage => _noteSaveTracker.saveErrorMessage;

  /// Whether success badge should be visible for active note.
  bool get showSavedBadge => _noteSaveTracker.showSavedBadge;

  /// Banner message shown when note switch is blocked by flush failure.
  String? get switchBlockErrorMessage => _switchBlockErrorMessage;

  /// Whether active note has pending save work before app close.
  ///
  /// Includes dirty drafts and in-flight save requests for all open tabs.
  bool get hasPendingSaveWork {
    if (_createTagApplyFuture != null) {
      return true;
    }
    if (_activeNoteId case final active?) {
      if (_hasPendingSaveFor(active)) {
        return true;
      }
    }
    for (final atomId in _noteTabManager.allOpenNoteIds) {
      if (_hasPendingSaveFor(atomId)) {
        return true;
      }
    }
    return false;
  }

  /// Monotonic token used by UI to request editor focus.
  int get editorFocusRequestId => _editorFocusRequestId;

  /// In-memory draft content for active editor instance.
  String get activeDraftContent {
    if (_activeNoteId == null) {
      return '';
    }
    final atomId = _activeNoteId!;
    if (_draftContentByAtomId[atomId] case final draft?) {
      return draft;
    }
    if (_activeDraftAtomId == atomId) {
      return _activeDraftContent;
    }
    return _selectedNote?.content ?? '';
  }

  /// Returns one cached/list note by id when available.
  rust_api.AtomListItem? noteById(String atomId) {
    return _noteListManager.noteById(atomId);
  }

  Map<String, String> get _draftContentByAtomId =>
      _noteDraftManager.draftContentByAtomId;

  Map<String, String> get _persistedContentByAtomId =>
      _noteDraftManager.persistedContentByAtomId;

  Map<String, int> get _draftVersionByAtomId =>
      _noteDraftManager.draftVersionByAtomId;

  Map<String, Future<bool>> get _saveFutureByAtomId =>
      _noteDraftManager.saveFutureByAtomId;

  Map<String, bool> get _saveQueuedByAtomId =>
      _noteDraftManager.saveQueuedByAtomId;

  String? get _activeDraftAtomId => _noteDraftManager.activeDraftAtomId;
  set _activeDraftAtomId(String? value) {
    _noteDraftManager.activeDraftAtomId = value;
  }

  String get _activeDraftContent => _noteDraftManager.activeDraftContent;
  set _activeDraftContent(String value) {
    _noteDraftManager.activeDraftContent = value;
  }

  Timer? get _autosaveTimer => _noteDraftManager.autosaveTimer;

  void _handleNoteSaveTrackerChanged() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  void _handleNoteListManagerChanged() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  void _handleNoteDraftManagerChanged() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  void _handleNoteTabManagerChanged() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  void _handleNoteTagManagerChanged() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  void _handleWorkspaceTreeManagerChanged() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _noteListManager.removeListener(_handleNoteListManagerChanged);
    _noteDraftManager.removeListener(_handleNoteDraftManagerChanged);
    _noteTabManager.removeListener(_handleNoteTabManagerChanged);
    _noteTagManager.removeListener(_handleNoteTagManagerChanged);
    _noteSaveTracker.removeListener(_handleNoteSaveTrackerChanged);
    _workspaceTreeManager.removeListener(_handleWorkspaceTreeManagerChanged);
    _noteListManager.dispose();
    _noteDraftManager.dispose();
    _noteTabManager.dispose();
    _noteTagManager.dispose();
    _workspaceTreeManager.dispose();
    _noteSaveTracker.dispose();
    if (_ownsWorkspaceProvider) {
      _workspaceProvider.dispose();
    }
    super.dispose();
  }

  /// Tab title projection used by tab manager.
  String titleForTab(String atomId) {
    final item = noteById(atomId);
    if (item == null) {
      return 'Untitled';
    }
    return item.title.isNotEmpty ? item.title : 'Untitled';
  }

  /// Loads notes baseline and tag catalog on initial page entry.
  ///
  /// Side effects:
  /// - Resets existing tab/detail state before reloading.
  /// - Opens first loaded note as active tab when available.
  Future<void> loadNotes() async {
    await _awaitCreateTagApply();
    await _noteTagManager.awaitPendingTagMutations();
    await _loadNotes(
      resetSession: true,
      preserveActiveWhenFilteredOut: false,
      refreshTags: true,
    );
  }

  /// Retries notes list for current filter without resetting opened tabs.
  Future<void> retryLoad() async {
    await _awaitCreateTagApply();
    await _noteTagManager.awaitPendingTagMutations();
    await _loadNotes(
      resetSession: false,
      preserveActiveWhenFilteredOut: false,
      refreshTags: false,
    );
  }

  /// Retries tag catalog request for filter UI.
  Future<void> retryTagLoad() => _noteTagManager.refreshAvailableTags();

  /// Applies one normalized single-tag filter.
  ///
  /// Returns `false` when input is invalid or flush guard blocks transition.
  Future<bool> applyTagFilter(String rawTag) {
    return _noteTagManager.applyTagFilter(rawTag);
  }

  /// Clears active single-tag filter and returns to full list.
  ///
  /// Returns `false` when flush guard blocks transition.
  Future<bool> clearTagFilter() {
    return _noteTagManager.clearTagFilter();
  }

  bool _canReuseSelection(String atomId) {
    return _activeNoteId == atomId &&
        _selectedNote != null &&
        !_detailLoading &&
        _detailErrorMessage == null;
  }

  void _activateSelection(String atomId) {
    _activeNoteId = atomId;
    _selectedNote = noteById(atomId);
    _activeDraftAtomId = atomId;
    _activeDraftContent =
        _draftContentByAtomId[atomId] ?? _selectedNote?.content ?? '';
    _refreshSaveStateForActive();
    _requestEditorFocus();
    _switchBlockErrorMessage = null;
  }

  void _clearSelection() {
    _activeNoteId = null;
    _selectedNote = null;
    _detailLoading = false;
    _detailErrorMessage = null;
    _activeDraftAtomId = null;
    _activeDraftContent = '';
    _autosaveTimer?.cancel();
    _setSaveState(NoteSaveState.clean);
  }

  /// Handles open-note request from explorer shell.
  ///
  /// Explorer emits open intent only. Preview/pinned semantics are owned by
  /// tab model: explorer-open marks target as preview and may replace previous
  /// clean preview tab.
  Future<bool> openNoteFromExplorer(String atomId) async {
    return _noteTabManager.openNoteFromExplorer(atomId);
  }

  /// Handles explicit pinned-open request from explorer double-click.
  Future<bool> openNoteFromExplorerPinned(String atomId) async {
    return _noteTabManager.openNoteFromExplorerPinned(atomId);
  }

  /// Pins one preview tab so it is not replaced by next explorer-open.
  void pinPreviewTab(String atomId) {
    _noteTabManager.pinPreviewTab(atomId);
  }

  /// Creates one workspace folder under root or one parent folder.
  Future<rust_api.WorkspaceNodeResponse> createWorkspaceFolder({
    required String name,
    String? parentNodeId,
  }) async {
    return _workspaceTreeManager.createWorkspaceFolder(
      name: name,
      parentNodeId: parentNodeId,
    );
  }

  /// Creates one note and links it into workspace tree under optional parent.
  ///
  /// Contract:
  /// - Parent id must be `null` or UUID (`__uncategorized__` is mapped to root).
  /// - Uses single-call `note_create(content, parent_node_id)` — atom + atom_ref
  ///   are created atomically by `CreationService`.
  /// - On success, created note is active and tree revision is bumped.
  Future<rust_api.WorkspaceActionResponse> createWorkspaceNoteInFolder({
    String? parentNodeId,
  }) async {
    return _workspaceTreeManager.createWorkspaceNoteInFolder(
      parentNodeId: parentNodeId,
    );
  }

  /// Renames one workspace node.
  Future<rust_api.WorkspaceActionResponse> renameWorkspaceNode({
    required String nodeId,
    required String newName,
  }) async {
    return _workspaceTreeManager.renameWorkspaceNode(
      nodeId: nodeId,
      newName: newName,
    );
  }

  /// Moves one workspace node under optional target parent.
  Future<rust_api.WorkspaceActionResponse> moveWorkspaceNode({
    required String nodeId,
    String? newParentNodeId,
    int? targetOrder,
  }) async {
    return _workspaceTreeManager.moveWorkspaceNode(
      nodeId: nodeId,
      newParentNodeId: newParentNodeId,
      targetOrder: targetOrder,
    );
  }

  /// Lists workspace tree children for explorer lazy rendering.
  ///
  /// Contract:
  /// - Returns core FFI response when call succeeds.
  /// - Synthetic `Uncategorized` children are projected as:
  ///   - root-level `atom_ref` rows from workspace tree
  ///   - legacy notes with no workspace `atom_ref` anywhere in tree
  /// - Uses synthetic fallback only when bridge is unavailable (e.g. Rust bridge
  ///   not initialized in test host).
  /// - Returns explicit error envelope when bridge call throws so UI can render
  ///   actionable error + retry state.
  Future<rust_api.WorkspaceListChildrenResponse> listWorkspaceChildren({
    String? parentNodeId,
  }) async {
    return _workspaceTreeManager.listWorkspaceChildren(
      parentNodeId: parentNodeId,
    );
  }

  /// Deletes one workspace folder by explicit mode, then refreshes UI state.
  ///
  /// Contract:
  /// - `mode` must be `dissolve` or `delete_all`.
  /// - Flushes active draft before mutation to avoid local data loss.
  /// - Refreshes list and reconciles open tabs after successful delete.
  Future<rust_api.WorkspaceActionResponse> deleteWorkspaceFolder({
    required String folderId,
    required String mode,
  }) async {
    return _workspaceTreeManager.deleteWorkspaceFolder(
      folderId: folderId,
      mode: mode,
    );
  }

  Future<WorkspaceCreateNoteResult> _createNoteAndGetAtomId({
    String? parentNodeId,
  }) async {
    final created = await createNote(parentNodeId: parentNodeId);
    if (!created) {
      return (
        atomId: null,
        errorCode: _createErrorCode,
        errorMessage: _createErrorMessage,
      );
    }
    final atomId = _activeNoteId?.trim();
    if (atomId == null || atomId.isEmpty) {
      return (
        atomId: null,
        errorCode: 'internal_error',
        errorMessage: 'Created note is missing atom id.',
      );
    }
    return (atomId: atomId, errorCode: null, errorMessage: null);
  }

  Future<void> _handleWorkspaceDeleteSuccess() async {
    await _loadNotes(
      resetSession: false,
      preserveActiveWhenFilteredOut: true,
      refreshTags: false,
    );
    await _reconcileOpenTabsAfterWorkspaceMutation();
  }

  /// Flushes pending save work for the currently active note.
  ///
  /// Contract:
  /// - Returns `true` when no pending write exists or persistence succeeds.
  /// - Returns `false` when latest draft cannot be persisted.
  /// - Keeps in-memory draft unchanged on failure.
  Future<bool> flushPendingSave() async {
    await _awaitCreateTagApply(timeout: const Duration(milliseconds: 800));
    final atomId = _activeNoteId;
    if (atomId == null) {
      return true;
    }
    _autosaveTimer?.cancel();

    while (true) {
      await _noteTagManager.waitForAtomTagMutations(atomId);

      final inflight = _saveFutureByAtomId[atomId];
      if (inflight != null) {
        await inflight;
        if (!_isDirty(atomId)) {
          _switchBlockErrorMessage = null;
          return true;
        }
        continue;
      }

      if (!_isDirty(atomId)) {
        _switchBlockErrorMessage = null;
        return true;
      }

      final version = _draftVersionByAtomId[atomId] ?? 0;
      final saved = await _saveDraft(atomId: atomId, version: version);
      if (saved && !_isDirty(atomId)) {
        _switchBlockErrorMessage = null;
        return true;
      }

      if ((_draftVersionByAtomId[atomId] ?? 0) != version) {
        continue;
      }

      _switchBlockErrorMessage = 'Save failed. Retry or back up content.';
      notifyListeners();
      return false;
    }
  }

  /// Retries saving current active draft immediately.
  ///
  /// Contract:
  /// - Saves the latest in-memory draft (not stale snapshot).
  /// - Returns `true` when active draft becomes persisted.
  /// - Returns `false` when save still fails.
  Future<bool> retrySaveCurrentDraft() async {
    final atomId = _activeNoteId;
    if (atomId == null) {
      return false;
    }
    _autosaveTimer?.cancel();
    final version = _draftVersionByAtomId[atomId] ?? 0;
    final saved = await _saveDraft(atomId: atomId, version: version);
    if (saved && !_isDirty(atomId)) {
      _switchBlockErrorMessage = null;
      notifyListeners();
      return true;
    }
    if ((_draftVersionByAtomId[atomId] ?? 0) != version) {
      return false;
    }
    return false;
  }

  /// Creates one new empty note and activates editor on success.
  ///
  /// Side effects:
  /// - Calls `note_create` with empty content in v0.1 C2.
  /// - Inserts created note into list/cache without reloading full list.
  /// - Sets created note as active tab and requests editor focus.
  Future<bool> createNote({String? parentNodeId}) async {
    if (_creatingNote) {
      return false;
    }
    _creatingNote = true;
    _createErrorCode = null;
    _createErrorMessage = null;
    _createWarningMessage = null;
    notifyListeners();

    try {
      await _prepare();
      final response = await _noteCreateInvoker(
        content: '',
        parentNodeId: parentNodeId,
      );
      if (!response.ok) {
        _creatingNote = false;
        _createErrorCode = response.errorCode;
        _createErrorMessage = _envelopeError(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to create note.',
        );
        notifyListeners();
        return false;
      }

      final created = response.item;
      if (created == null) {
        _creatingNote = false;
        _createErrorCode = 'internal_error';
        _createErrorMessage =
            'Create note succeeded but returned empty payload.';
        notifyListeners();
        return false;
      }
      var createdNote = created;
      if (selectedTag case final activeTag?) {
        final taggedFuture = _noteSetTagsInvoker(
          atomId: created.atomId,
          tags: <String>[activeTag],
        );
        final pendingMarker = taggedFuture.then(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {},
        );
        _createTagApplyFuture = pendingMarker;
        notifyListeners();
        try {
          final tagged = await taggedFuture;
          if (tagged.ok && tagged.item != null) {
            createdNote = tagged.item!;
          } else {
            _createWarningMessage =
                'Note created, but applying active filter tag failed. Check All Notes.';
          }
        } finally {
          if (identical(_createTagApplyFuture, pendingMarker)) {
            _createTagApplyFuture = null;
            notifyListeners();
          }
        }
      }

      _noteListManager.upsertNote(
        createdNote,
        insertFront: true,
        updatePersisted: true,
      );
      _noteListManager.markListSuccess();
      _activeNoteId = createdNote.atomId;
      _selectedNote = createdNote;
      _activeDraftAtomId = createdNote.atomId;
      _activeDraftContent = _draftContentByAtomId[createdNote.atomId] ?? '';
      _detailErrorMessage = null;
      _noteTabManager.addOpenNoteIfAbsent(createdNote.atomId);
      _creatingNote = false;
      _autosaveTimer?.cancel();
      _setSaveState(NoteSaveState.clean);
      _requestEditorFocus();
      notifyListeners();

      // Lifecycle hook: schedule reminder if atom has time fields
      if (createdNote.startAt != null || createdNote.endAt != null) {
        try {
          await _reminderLifecycle.onSchedule(createdNote.atomId);
        } catch (_) {
          // Reminder delivery must not break note creation flow.
        }
      }

      await _noteTagManager.refreshAvailableTags(showLoading: false);
      await _loadSelectedDetail(atomId: createdNote.atomId);
      _requestEditorFocus();
      notifyListeners();
      return true;
    } catch (error) {
      _creatingNote = false;
      _createErrorCode = 'internal_error';
      _createErrorMessage = 'Create note failed unexpectedly: $error';
      notifyListeners();
      return false;
    }
  }

  /// Replaces the active note tag set using immediate-save semantics.
  ///
  /// Returns `false` when active note is missing or mutation fails.
  Future<bool> setActiveNoteTags(List<String> rawTags) {
    return _noteTagManager.setActiveNoteTags(rawTags);
  }

  /// Adds one tag to active note with normalization and de-duplication.
  Future<bool> addTagToActiveNote(String tag) {
    return _noteTagManager.addTagToActiveNote(tag);
  }

  /// Removes one tag from active note with normalization.
  Future<bool> removeTagFromActiveNote(String tag) {
    return _noteTagManager.removeTagFromActiveNote(tag);
  }

  Future<void> _reconcileOpenTabsAfterWorkspaceMutation() async {
    final allOpenIds = _noteTabManager.allOpenNoteIds;
    if (allOpenIds.isEmpty) {
      return;
    }

    final activePaneSnapshot = _noteTabManager.snapshotOpenNoteIds();
    final removedAtomIds = <String>[];
    for (final atomId in allOpenIds) {
      try {
        final response = await _noteListManager.loadNoteDetail(atomId: atomId);
        if (!response.ok) {
          if (response.errorCode == 'note_not_found') {
            removedAtomIds.add(atomId);
          }
          continue;
        }
        if (response.item case final note?) {
          _noteListManager.upsertNote(note, updatePersisted: true);
        }
      } catch (_) {
        // Keep tab state unchanged when detail check fails unexpectedly.
      }
    }

    if (removedAtomIds.isEmpty) {
      return;
    }

    final previousActiveId = _activeNoteId;
    final previousActiveIndex = previousActiveId == null
        ? -1
        : activePaneSnapshot.indexOf(previousActiveId);
    final activeRemoved =
        previousActiveId != null && removedAtomIds.contains(previousActiveId);

    _noteTabManager.removeOpenNotesWhereAllPanes(removedAtomIds.contains);
    for (final atomId in removedAtomIds) {
      _evictNoteState(atomId);
    }
    _noteTabManager.reconcilePreviewTabState();

    if (_noteTabManager.openNoteIds.isEmpty) {
      _activeNoteId = null;
      _selectedNote = null;
      _detailLoading = false;
      _detailErrorMessage = null;
      _activeDraftAtomId = null;
      _activeDraftContent = '';
      _autosaveTimer?.cancel();
      _setSaveState(NoteSaveState.clean);
      notifyListeners();
      return;
    }

    if (!activeRemoved) {
      notifyListeners();
      return;
    }

    final fallbackIndex = previousActiveIndex <= 0
        ? 0
        : (previousActiveIndex - 1).clamp(0, _noteTabManager.openNoteCount - 1);
    final fallbackId = _noteTabManager.openNoteIdAt(fallbackIndex);
    _activeNoteId = fallbackId;
    _selectedNote = noteById(fallbackId);
    _activeDraftAtomId = fallbackId;
    _activeDraftContent =
        _draftContentByAtomId[fallbackId] ?? _selectedNote?.content ?? '';
    _refreshSaveStateForActive();
    _requestEditorFocus();
    notifyListeners();
    await _loadSelectedDetail(atomId: fallbackId);
  }

  void _evictNoteState(String atomId) {
    _noteTabManager.clearPreviewForDeletedAtom(atomId);
    _noteListManager.evictNoteState(atomId);
    _draftContentByAtomId.remove(atomId);
    _persistedContentByAtomId.remove(atomId);
    _draftVersionByAtomId.remove(atomId);
    _saveFutureByAtomId.remove(atomId);
    _saveQueuedByAtomId.remove(atomId);
    _noteTagManager.clearStateForDeletedAtom(atomId);
  }

  Future<void> _awaitCreateTagApply({Duration? timeout}) async {
    final pending = _createTagApplyFuture;
    if (pending == null) {
      return;
    }
    try {
      if (timeout == null) {
        await pending;
      } else {
        await pending.timeout(timeout, onTimeout: () {});
      }
    } catch (_) {}
  }

  /// Selects one note and refreshes detail snapshot.
  ///
  /// Side effects:
  /// - Flushes pending save for current active note before switching.
  /// - Opens a new tab when [atomId] is not already opened.
  /// - Keeps existing tabs unchanged when [atomId] is already opened.
  ///
  /// Returns:
  /// - `true` when switch succeeds.
  /// - `false` when switch is blocked by flush failure.
  Future<bool> selectNote(String atomId) async {
    return _noteTabManager.selectNote(atomId);
  }

  /// Activates an already opened note tab and refreshes its detail.
  ///
  /// Returns `false` when switch guard blocks the activation.
  Future<bool> activateOpenNote(String atomId) async {
    return _noteTabManager.activateOpenNote(atomId);
  }

  /// Moves active tab forward (Ctrl+Tab behavior).
  ///
  /// Split mode cycles inside active-pane tabs only.
  Future<void> activateNextOpenNote() async {
    await _noteTabManager.activateNextOpenNote();
  }

  /// Moves active tab backward (Ctrl+Shift+Tab behavior).
  ///
  /// Split mode cycles inside active-pane tabs only.
  Future<void> activatePreviousOpenNote() async {
    await _noteTabManager.activatePreviousOpenNote();
  }

  /// Closes one opened tab.
  ///
  /// Side effects:
  /// - When closing active tab, selects deterministic fallback tab.
  /// - Flushes active draft before close to avoid data loss.
  /// - Clears selected detail state when the last tab is closed.
  ///
  /// Returns `false` when close is blocked by flush failure.
  Future<bool> closeOpenNote(String atomId) async {
    return _noteTabManager.closeOpenNote(atomId);
  }

  /// Closes all tabs except [atomId], then activates [atomId].
  ///
  /// Returns `false` when switch/close is blocked by flush failure.
  Future<bool> closeOtherOpenNotes(String atomId) async {
    return _noteTabManager.closeOtherOpenNotes(atomId);
  }

  /// Closes tabs to the right of [atomId].
  ///
  /// Side effects:
  /// - Flushes active draft when active tab would be removed.
  /// - Re-activates [atomId] if active tab was pruned by this operation.
  ///
  /// Returns `false` when close is blocked by flush failure.
  Future<bool> closeOpenNotesToRight(String atomId) async {
    return _noteTabManager.closeOpenNotesToRight(atomId);
  }

  /// Updates active note draft content in-memory.
  ///
  /// Side effects:
  /// - Updates selected note cache and list snapshot title projection.
  /// - Schedules debounced persistence through `note_update`.
  void updateActiveDraft(String content) {
    final atomId = _activeNoteId;
    if (atomId == null) {
      return;
    }
    final previous = _draftContentByAtomId[atomId] ?? _activeDraftContent;
    if (previous == content) {
      return;
    }

    _activeDraftAtomId = atomId;
    _activeDraftContent = content;
    _draftContentByAtomId[atomId] = content;
    final version = (_draftVersionByAtomId[atomId] ?? 0) + 1;
    _draftVersionByAtomId[atomId] = version;
    final current = _noteListManager.cachedNoteById(atomId) ?? _selectedNote;
    if (current != null) {
      final updated = _withContent(current, content);
      _selectedNote = updated;
      _noteListManager.upsertNote(updated);
    }
    // Why: once user edits preview content, replacing that tab on next open
    // is surprising and risks hidden draft loss. Promote to pinned.
    _noteTabManager.onDraftEdited(atomId);

    if (_isDirty(atomId)) {
      _setSaveState(NoteSaveState.dirty);
      _scheduleAutosave(atomId: atomId, version: version);
    } else {
      _autosaveTimer?.cancel();
      _setSaveState(NoteSaveState.clean);
    }
    notifyListeners();
  }

  Future<void> _loadNotes({
    required bool resetSession,
    required bool preserveActiveWhenFilteredOut,
    required bool refreshTags,
  }) async {
    if (refreshTags) {
      unawaited(_noteTagManager.refreshAvailableTags());
    }

    if (resetSession) {
      _resetSessionForReload();
    }

    _switchBlockErrorMessage = null;
    final loadedItems = await _noteListManager.loadNotes(limit: listLimit);
    if (loadedItems == null) {
      return;
    }

    String? detailTargetId;
    final activeId = _activeNoteId;
    final activeInList =
        activeId != null &&
        _noteListManager.findLoadedItem(loadedItems, activeId) != null;
    if (activeId == null) {
      if (loadedItems.isNotEmpty) {
        final first = loadedItems.first;
        _activeNoteId = first.atomId;
        _selectedNote = first;
        _activeDraftAtomId = first.atomId;
        _activeDraftContent =
            _draftContentByAtomId[first.atomId] ?? first.content;
        _noteTabManager.addOpenNoteIfAbsent(first.atomId);
        _setSaveState(NoteSaveState.clean);
        detailTargetId = first.atomId;
      } else {
        _selectedNote = null;
        _detailLoading = false;
        _detailErrorMessage = null;
        _activeDraftAtomId = null;
        _activeDraftContent = '';
        _setSaveState(NoteSaveState.clean);
      }
    } else if (activeInList) {
      _selectedNote =
          _noteListManager.findLoadedItem(loadedItems, activeId) ??
          _selectedNote;
      _activeDraftAtomId = activeId;
      _activeDraftContent =
          _draftContentByAtomId[activeId] ?? _selectedNote?.content ?? '';
      _refreshSaveStateForActive();
    } else if (preserveActiveWhenFilteredOut) {
      _selectedNote =
          _noteListManager.cachedNoteById(activeId) ?? _selectedNote;
      _activeDraftAtomId = activeId;
      _activeDraftContent =
          _draftContentByAtomId[activeId] ?? _selectedNote?.content ?? '';
      _refreshSaveStateForActive();
    } else if (loadedItems.isNotEmpty) {
      final fallback = loadedItems.first;
      _activeNoteId = fallback.atomId;
      _selectedNote = fallback;
      _activeDraftAtomId = fallback.atomId;
      _activeDraftContent =
          _draftContentByAtomId[fallback.atomId] ?? fallback.content;
      _noteTabManager.addOpenNoteIfAbsent(fallback.atomId);
      _refreshSaveStateForActive();
      _requestEditorFocus();
      detailTargetId = fallback.atomId;
    } else {
      _activeNoteId = null;
      _selectedNote = null;
      _detailLoading = false;
      _detailErrorMessage = null;
      _activeDraftAtomId = null;
      _activeDraftContent = '';
      _setSaveState(NoteSaveState.clean);
    }
    _noteTabManager.reconcilePreviewTabState();
    notifyListeners();

    if (detailTargetId != null) {
      await _loadSelectedDetail(atomId: detailTargetId);
    }
  }

  void _resetSessionForReload() {
    _selectedNote = null;
    _detailLoading = false;
    _detailErrorMessage = null;
    _noteTabManager.clearOpenNotes();
    _noteTabManager.reconcilePreviewTabState();
    _noteListManager.resetSessionState();
    _draftContentByAtomId.clear();
    _persistedContentByAtomId.clear();
    _draftVersionByAtomId.clear();
    _saveFutureByAtomId.clear();
    _saveQueuedByAtomId.clear();
    _noteTagManager.resetMutationState();
    _activeNoteId = null;
    _activeDraftAtomId = null;
    _activeDraftContent = '';
    _creatingNote = false;
    _createErrorCode = null;
    _createErrorMessage = null;
    _createWarningMessage = null;
    _createTagApplyFuture = null;
    _autosaveTimer?.cancel();
    _noteSaveTracker.reset(notify: false);
  }

  /// Retries loading current selected note detail.
  Future<void> refreshSelectedDetail() async {
    final atomId = _activeNoteId;
    if (atomId == null) {
      return;
    }
    await _loadSelectedDetail(atomId: atomId);
  }

  Future<void> _loadSelectedDetail({required String atomId}) async {
    if (_disposed) {
      return;
    }
    final requestId = ++_detailRequestId;
    _detailLoading = true;
    _detailErrorMessage = null;
    _selectedNote = _noteListManager.findListItem(atomId) ?? _selectedNote;
    if (_disposed) {
      return;
    }
    notifyListeners();

    try {
      await _prepare();
      if (_disposed ||
          requestId != _detailRequestId ||
          atomId != _activeNoteId) {
        return;
      }

      final response = await _noteListManager.loadNoteDetail(atomId: atomId);
      if (_disposed ||
          requestId != _detailRequestId ||
          atomId != _activeNoteId) {
        return;
      }

      if (!response.ok) {
        _detailLoading = false;
        _detailErrorMessage = _envelopeError(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to load note detail.',
        );
        if (_disposed) {
          return;
        }
        notifyListeners();
        return;
      }

      if (response.item case final note?) {
        _selectedNote = note;
        _noteListManager.upsertNote(note, updatePersisted: true);
        _activeDraftAtomId = note.atomId;
        _activeDraftContent =
            _draftContentByAtomId[note.atomId] ?? note.content;
        _detailLoading = false;
        _detailErrorMessage = null;
        _refreshSaveStateForActive();
        if (_disposed) {
          return;
        }
        notifyListeners();
        return;
      }

      _detailLoading = false;
      _detailErrorMessage = 'Note detail is empty.';
      if (_disposed) {
        return;
      }
      notifyListeners();
    } catch (error) {
      if (_disposed ||
          requestId != _detailRequestId ||
          atomId != _activeNoteId) {
        return;
      }
      _detailLoading = false;
      _detailErrorMessage = 'Note detail load failed unexpectedly: $error';
      if (_disposed) {
        return;
      }
      notifyListeners();
    }
  }

  void _syncPersistedSnapshot({
    required String atomId,
    required String content,
    required bool wasDirty,
  }) {
    _persistedContentByAtomId[atomId] = content;
    _draftVersionByAtomId.putIfAbsent(atomId, () => 0);
    if (!_draftContentByAtomId.containsKey(atomId) || !wasDirty) {
      _draftContentByAtomId[atomId] = content;
    }
  }

  rust_api.AtomListItem _withContent(
    rust_api.AtomListItem current,
    String content,
  ) {
    // Derive title for draft projection (display-derived state per Rule A).
    final firstLine = content
        .split('\n')
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
    final draftTitle = firstLine
        .trim()
        .replaceFirst(RegExp(r'^#+\s*'), '')
        .trim();

    return rust_api.AtomListItem(
      atomId: current.atomId,
      viewHint: current.viewHint,
      title: draftTitle.isNotEmpty ? draftTitle : current.title,
      contentType: current.contentType,
      content: content,
      previewText: current.previewText,
      previewImage: current.previewImage,
      tags: current.tags,
      startAt: current.startAt,
      endAt: current.endAt,
      taskStatus: current.taskStatus,
      updatedAt: current.updatedAt,
    );
  }

  void _requestEditorFocus() {
    _editorFocusRequestId += 1;
  }

  bool _isDirty(String atomId) {
    return _noteDraftManager.isDirty(atomId);
  }

  bool _hasPendingSaveFor(String atomId) {
    return _isDirty(atomId) ||
        _saveFutureByAtomId.containsKey(atomId) ||
        _noteTagManager.hasPendingTagWorkFor(atomId);
  }

  bool _shouldIncludeInVisibleList(rust_api.AtomListItem note) {
    return _noteTagManager.shouldIncludeInVisibleList(note);
  }

  void _scheduleAutosave({required String atomId, required int version}) {
    _noteDraftManager.scheduleAutosave(atomId: atomId, version: version);
  }

  Future<bool> _saveDraft({required String atomId, required int version}) {
    return _noteDraftManager.saveDraft(atomId: atomId, version: version);
  }

  void _refreshSaveStateForActive() {
    _noteDraftManager.refreshSaveStateForActive(activeNoteId: _activeNoteId);
  }

  void _setSaveState(
    NoteSaveState nextState, {
    bool preserveError = false,
    bool showSavedBadge = false,
  }) {
    _noteSaveTracker.setState(
      nextState,
      preserveError: preserveError,
      showSavedBadge: showSavedBadge,
      notify: false,
    );
  }

  void _adoptWorkspaceActivePaneState({bool loadDetail = true}) {
    final paneId = _workspaceProvider.activePaneId;
    final paneActiveId = _activeNoteIdByPane[paneId];
    _activeNoteId = paneActiveId;
    if (paneActiveId == null) {
      _selectedNote = null;
      _activeDraftAtomId = null;
      _activeDraftContent = '';
      _detailLoading = false;
      _detailErrorMessage = null;
      _setSaveState(NoteSaveState.clean);
      return;
    }

    final selected = _selectedNote?.atomId == paneActiveId
        ? _selectedNote
        : null;
    final local =
        _noteListManager.cachedNoteById(paneActiveId) ??
        selected ??
        _noteListManager.findListItem(paneActiveId);
    _selectedNote = local;
    _activeDraftAtomId = paneActiveId;
    _activeDraftContent =
        _draftContentByAtomId[paneActiveId] ?? local?.content ?? '';
    _refreshSaveStateForActive();
    _switchBlockErrorMessage = null;
    _requestEditorFocus();
    if (loadDetail) {
      unawaited(_loadSelectedDetail(atomId: paneActiveId));
    }
  }

  String _envelopeError({
    required String? errorCode,
    required String message,
    required String fallback,
  }) {
    final normalized = message.trim();
    if (errorCode == null || errorCode.trim().isEmpty) {
      return normalized.isEmpty ? fallback : normalized;
    }
    if (normalized.isEmpty) {
      return '[$errorCode] $fallback';
    }
    return '[$errorCode] $normalized';
  }
}

Future<rust_api.AtomListResponse> _defaultNotesListInvoker({
  String? tag,
  int? limit,
  int? offset,
}) {
  return rust_api.notesList(tag: tag, limit: limit, offset: offset);
}

Future<rust_api.AtomItemResponse> _defaultNoteGetInvoker({
  required String atomId,
}) {
  return rust_api.noteGet(atomId: atomId);
}

Future<rust_api.AtomItemResponse> _defaultNoteCreateInvoker({
  required String content,
  String? parentNodeId,
}) {
  return rust_api.noteCreate(content: content, parentNodeId: parentNodeId);
}

Future<rust_api.AtomItemResponse> _defaultNoteUpdateInvoker({
  required String atomId,
  required String content,
}) {
  return rust_api.noteUpdate(atomId: atomId, content: content);
}

Future<rust_api.TagsListResponse> _defaultTagsListInvoker() {
  return rust_api.tagsList();
}

Future<rust_api.AtomItemResponse> _defaultNoteSetTagsInvoker({
  required String atomId,
  required List<String> tags,
}) {
  return rust_api.noteSetTags(atomId: atomId, tags: tags);
}

Future<rust_api.WorkspaceActionResponse> _defaultWorkspaceDeleteFolderInvoker({
  required String nodeId,
  required String mode,
}) {
  return rust_api.workspaceDeleteFolder(nodeId: nodeId, mode: mode);
}

Future<rust_api.WorkspaceNodeResponse> _defaultWorkspaceCreateFolderInvoker({
  String? parentNodeId,
  required String name,
}) {
  return rust_api.workspaceCreateFolder(parentNodeId: parentNodeId, name: name);
}

Future<rust_api.WorkspaceActionResponse> _defaultWorkspaceRenameNodeInvoker({
  required String nodeId,
  required String newName,
}) {
  return rust_api.workspaceRenameNode(nodeId: nodeId, newName: newName);
}

Future<rust_api.WorkspaceActionResponse> _defaultWorkspaceMoveNodeInvoker({
  required String nodeId,
  String? newParentId,
  int? targetOrder,
}) {
  return rust_api.workspaceMoveNode(
    nodeId: nodeId,
    newParentId: newParentId,
    targetOrder: targetOrder,
  );
}

Future<rust_api.WorkspaceListChildrenResponse>
_defaultWorkspaceListChildrenInvoker({String? parentNodeId}) {
  return rust_api.workspaceListChildren(parentNodeId: parentNodeId);
}

Future<void> _defaultPrepare() async {
  await RustBridge.ensureEntryDbPathConfigured();
}
