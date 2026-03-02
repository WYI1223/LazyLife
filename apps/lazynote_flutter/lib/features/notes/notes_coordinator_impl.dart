part of 'notes_coordinator.dart';

/// Stateful controller for Notes page list/detail baseline.
///
/// PR-RB-06: tab/draft/save state extracted into [EditorShellService].
/// Coordinator retains list, tag, workspace-tree, and detail orchestration.
class _NotesCoordinatorImpl extends ChangeNotifier {
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
    DebounceTimerFactory? debounceTimerFactory,
    NotesPrepare? prepare,
    this.listLimit = 50,
    ReminderLifecycle? reminderLifecycle,
    Duration? autosaveDebounce,
  }) : _noteCreateInvoker = noteCreateInvoker ?? _defaultNoteCreateInvoker,
       _noteUpdateInvoker = noteUpdateInvoker ?? _defaultNoteUpdateInvoker,
       _noteSetTagsInvoker = noteSetTagsInvoker ?? _defaultNoteSetTagsInvoker,
       _noteGetInvoker = noteGetInvoker ?? _defaultNoteGetInvoker,
       _debounceTimerFactory = debounceTimerFactory ?? Timer.new,
       _autosaveDebounce = autosaveDebounce,
       _reminderLifecycle = reminderLifecycle ?? ReminderLifecycle.instance,
       _prepare = prepare ?? _defaultPrepare {
    final resolvedNotesListInvoker =
        notesListInvoker ?? _defaultNotesListInvoker;
    final resolvedTagsListInvoker = tagsListInvoker ?? _defaultTagsListInvoker;
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

    _noteListManager = NoteListManager(
      notesListInvoker: resolvedNotesListInvoker,
      noteGetInvoker: _noteGetInvoker,
      prepare: _prepare,
      envelopeError: _envelopeError,
      selectedTag: () => selectedTag,
      shouldIncludeInVisibleList: (note) =>
          _noteTagManager.shouldIncludeInVisibleList(note),
      isDirty: _isDirty,
      syncPersistedSnapshot:
          ({
            required String atomId,
            required String content,
            required bool wasDirty,
          }) {
            // EditBuffer is the single source of truth for content once opened.
            // No sync needed — buffer initializes with content when tab opens.
          },
    );
    _noteListManager.addListener(_handleNoteListManagerChanged);

    _editorShellService = EditorShellService(
      loadContentFn: _loadNoteContentFromFFI,
      persistFn: _persistNoteContent,
      onBufferSaved: _handleBufferSaved,
      timerFactory: _debounceTimerFactory,
      autosaveDebounce: _autosaveDebounce,
    );
    _editorShellService.addListener(_handleEditorShellChanged);

    _noteTagManager = NoteTagManager(
      tagsListInvoker: resolvedTagsListInvoker,
      noteSetTagsInvoker: _noteSetTagsInvoker,
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
      activeNoteId: () => activeNoteId,
      noteById: (atomId) => _noteListManager.noteById(atomId) ?? _selectedNote,
      upsertNote: _noteListManager.upsertNote,
      isDirty: _isDirty,
      setSaveState: _setSaveState,
      setSaveError: (message) {
        _saveErrorMessage = message;
      },
      onActiveNoteUpdated: ({required atomId, required note}) {
        _selectedNote = note;
        _switchBlockErrorMessage = null;
      },
    );
    _noteTagManager.addListener(_handleNoteTagManagerChanged);

    _workspaceTreeService = WorkspaceTreeService(
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
    _workspaceTreeService.addListener(_handleWorkspaceTreeServiceChanged);
  }

  // ── Injected closures ──────────────────────────────────────────────

  final NoteCreateInvoker _noteCreateInvoker;
  final NoteUpdateInvoker _noteUpdateInvoker;
  final NoteSetTagsInvoker _noteSetTagsInvoker;
  final NoteGetInvoker _noteGetInvoker;
  final DebounceTimerFactory _debounceTimerFactory;
  final Duration? _autosaveDebounce;
  final ReminderLifecycle _reminderLifecycle;
  final NotesPrepare _prepare;

  // ── Composed services ──────────────────────────────────────────────

  late final EditorShellService _editorShellService;
  late final NoteListManager _noteListManager;
  late final NoteTagManager _noteTagManager;
  late final WorkspaceTreeService _workspaceTreeService;

  /// Requested list limit for C1 list baseline.
  final int listLimit;

  // ── Detail state ───────────────────────────────────────────────────

  rust_api.AtomListItem? _selectedNote;
  bool _detailLoading = false;
  String? _detailErrorMessage;

  // ── Create state ───────────────────────────────────────────────────

  bool _creatingNote = false;
  String? _createErrorCode;
  String? _createErrorMessage;
  String? _createWarningMessage;
  Future<void>? _createTagApplyFuture;

  // ── Save state (coordinator-level for badge + tag integration) ─────

  NoteSaveState _noteSaveState = NoteSaveState.clean;
  String? _saveErrorMessage;
  bool _showSavedBadge = false;
  Timer? _savedBadgeTimer;

  // ── Misc state ─────────────────────────────────────────────────────

  int _editorFocusRequestId = 0;
  String? _switchBlockErrorMessage;
  int _detailRequestId = 0;
  bool _disposed = false;

  // ── Public getters: list ───────────────────────────────────────────

  NotesListPhase get listPhase => _noteListManager.listPhase;
  List<rust_api.AtomListItem> get items => _noteListManager.items;
  String? get listErrorMessage => _noteListManager.listErrorMessage;

  // ── Public getters: tags ───────────────────────────────────────────

  bool get tagsLoading => _noteTagManager.tagsLoading;
  List<String> get availableTags => _noteTagManager.availableTags;
  String? get tagsErrorMessage => _noteTagManager.tagsErrorMessage;
  String? get selectedTag => _noteTagManager.selectedTag;

  // ── Public getters: tabs (derived from EditorShellService) ─────────

  String? get activeNoteId => _editorShellService.activeGroup?.activeAtomId;

  String? get selectedAtomId => activeNoteId;

  List<String> get openNoteIds {
    final group = _editorShellService.activeGroup;
    if (group == null) return const [];
    return group.tabs.map((t) => t.atomId).toList();
  }

  String? get previewTabId => _editorShellService.activeGroup?.previewTabId;

  bool isPreviewTab(String atomId) => previewTabId == atomId;

  // ── Public getters: detail ─────────────────────────────────────────

  rust_api.AtomListItem? get selectedNote => _selectedNote;
  bool get detailLoading => _detailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  // ── Public getters: create ─────────────────────────────────────────

  bool get creatingNote => _creatingNote;
  String? get createErrorMessage => _createErrorMessage;
  String? get createWarningMessage => _createWarningMessage;
  bool get createTagApplyInFlight => _createTagApplyFuture != null;

  // ── Public getters: save state ─────────────────────────────────────

  NoteSaveState get noteSaveState => _noteSaveState;
  String? get saveErrorMessage => _saveErrorMessage;
  bool get showSavedBadge => _showSavedBadge;
  String? get switchBlockErrorMessage => _switchBlockErrorMessage;

  // ── Public getters: workspace ──────────────────────────────────────

  bool get workspaceDeleteInFlight =>
      _workspaceTreeService.workspaceDeleteInFlight;
  String? get workspaceDeleteErrorMessage =>
      _workspaceTreeService.workspaceDeleteErrorMessage;
  bool get workspaceCreateFolderInFlight =>
      _workspaceTreeService.workspaceCreateFolderInFlight;
  String? get workspaceCreateFolderErrorMessage =>
      _workspaceTreeService.workspaceCreateFolderErrorMessage;
  bool get workspaceNodeMutationInFlight =>
      _workspaceTreeService.workspaceNodeMutationInFlight;
  String? get workspaceNodeMutationErrorMessage =>
      _workspaceTreeService.workspaceNodeMutationErrorMessage;
  int get workspaceTreeRevision => _workspaceTreeService.workspaceTreeRevision;

  // ── Public getters: editor service ─────────────────────────────────

  EditorShellService get editorShellService => _editorShellService;

  bool get hasPendingSaveWork {
    if (_createTagApplyFuture != null) return true;
    if (_editorShellService.hasPendingSaveWork) return true;
    if (activeNoteId case final active?) {
      if (_noteTagManager.hasPendingTagWorkFor(active)) return true;
    }
    return false;
  }

  int get editorFocusRequestId => _editorFocusRequestId;

  String get activeDraftContent {
    final atomId = activeNoteId;
    if (atomId == null) return '';
    return _editorShellService.bufferFor(atomId)?.content ??
        _selectedNote?.content ??
        '';
  }

  rust_api.AtomListItem? noteById(String atomId) =>
      _noteListManager.noteById(atomId);

  String titleForTab(String atomId) {
    final item = noteById(atomId);
    if (item == null) return 'Untitled';
    return item.title.isNotEmpty ? item.title : 'Untitled';
  }

  // ── Tab operations ─────────────────────────────────────────────────

  Future<bool> selectNote(String atomId) async {
    if (_canReuseSelection(atomId)) return true;
    if (activeNoteId case final currentId? when currentId != atomId) {
      final flushed = await flushPendingSave();
      if (!flushed) return false;
    }
    _openAndActivateTab(atomId);
    notifyListeners();
    await _loadSelectedDetail(atomId: atomId);
    return true;
  }

  Future<bool> activateOpenNote(String atomId) => selectNote(atomId);

  Future<void> activateNextOpenNote() async {
    final ids = openNoteIds;
    final current = activeNoteId;
    if (ids.length <= 1 || current == null) return;
    final index = ids.indexOf(current);
    if (index < 0) return;
    await activateOpenNote(ids[(index + 1) % ids.length]);
  }

  Future<void> activatePreviousOpenNote() async {
    final ids = openNoteIds;
    final current = activeNoteId;
    if (ids.length <= 1 || current == null) return;
    final index = ids.indexOf(current);
    if (index < 0) return;
    await activateOpenNote(ids[(index - 1 + ids.length) % ids.length]);
  }

  Future<bool> closeOpenNote(String atomId) async {
    final group = _editorShellService.activeGroup;
    if (group == null || !group.containsAtom(atomId)) return false;
    if (activeNoteId == atomId) {
      final flushed = await flushPendingSave();
      if (!flushed) return false;
    }

    final groupId = _editorShellService.activeGroupId;
    await _editorShellService.closeTab(groupId, atomId);

    // If we closed the active note, adopt the new active tab
    final newActiveId = _editorShellService.activeGroup?.activeAtomId;
    if (newActiveId != null && newActiveId != atomId) {
      _selectedNote = noteById(newActiveId);
      _updateSaveStateFromBuffer();
      _requestEditorFocus();
      notifyListeners();
      await _loadSelectedDetail(atomId: newActiveId);
    } else if (newActiveId == null) {
      _clearSelection();
      notifyListeners();
    }
    return true;
  }

  Future<bool> closeOtherOpenNotes(String atomId) async {
    final group = _editorShellService.activeGroup;
    if (group == null || !group.containsAtom(atomId)) return false;
    final switched = await activateOpenNote(atomId);
    if (!switched) return false;

    final groupId = _editorShellService.activeGroupId;
    final toClose = group.tabs
        .where((t) => t.atomId != atomId)
        .map((t) => t.atomId)
        .toList();
    for (final id in toClose) {
      await _editorShellService.closeTab(groupId, id);
    }
    notifyListeners();
    return true;
  }

  Future<bool> closeOpenNotesToRight(String atomId) async {
    final group = _editorShellService.activeGroup;
    if (group == null) return false;
    final tabs = group.tabs;
    final index = tabs.indexWhere((t) => t.atomId == atomId);
    if (index < 0 || index == tabs.length - 1) return true;

    final willPruneActive =
        activeNoteId != null &&
        tabs.indexWhere((t) => t.atomId == activeNoteId) > index;
    if (willPruneActive) {
      final flushed = await flushPendingSave();
      if (!flushed) return false;
    }

    final groupId = _editorShellService.activeGroupId;
    final toClose = tabs.sublist(index + 1).map((t) => t.atomId).toList();
    for (final id in toClose) {
      await _editorShellService.closeTab(groupId, id);
    }
    if (willPruneActive) {
      _openAndActivateTab(atomId);
      notifyListeners();
      await _loadSelectedDetail(atomId: atomId);
    } else {
      notifyListeners();
    }
    return true;
  }

  Future<bool> openNoteFromExplorer(String atomId) async {
    final group = _editorShellService.activeGroup;
    if (group == null) return false;
    final alreadyOpened = group.containsAtom(atomId);

    if (!alreadyOpened) {
      final previousPreviewId = group.previewTabId;
      if (previousPreviewId != null && previousPreviewId != atomId) {
        if (!_hasPendingSaveFor(previousPreviewId)) {
          return _selectFromExplorerByReplacingPreview(
            atomId: atomId,
            previewId: previousPreviewId,
          );
        }
        group.pinPreviewTab(previousPreviewId);
      }
    }

    if (!alreadyOpened) {
      // Flush current draft before activating new tab, because
      // _openAndActivateTab changes activeNoteId and selectNote's
      // flush check uses activeNoteId.
      if (activeNoteId case final currentId? when currentId != atomId) {
        final flushed = await flushPendingSave();
        if (!flushed) return false;
      }
      _openAndActivateTab(atomId);
      group.setPreviewTab(atomId);
    }
    final switched = await selectNote(atomId);
    if (!switched && !alreadyOpened) {
      group.pinPreviewTab(atomId);
    }
    return switched;
  }

  Future<bool> openNoteFromExplorerPinned(String atomId) async {
    if (activeNoteId == atomId) {
      _editorShellService.activeGroup?.pinPreviewTab(atomId);
      return true;
    }
    final group = _editorShellService.activeGroup;
    if (group != null && group.containsAtom(atomId)) {
      final switched = await selectNote(atomId);
      if (!switched) return false;
      group.pinPreviewTab(atomId);
      return true;
    }
    final opened = await openNoteFromExplorer(atomId);
    if (!opened) return false;
    _editorShellService.activeGroup?.pinPreviewTab(atomId);
    return true;
  }

  void pinPreviewTab(String atomId) {
    _editorShellService.activeGroup?.pinPreviewTab(atomId);
    notifyListeners();
  }

  // ── Pane operations ────────────────────────────────────────────────

  PaneSplitResult splitActivePane({
    required Axis direction,
    required double containerExtent,
  }) {
    final groupId = _editorShellService.activeGroupId;
    final containerSize = direction == Axis.horizontal
        ? Size(containerExtent, minPaneExtent)
        : Size(minPaneExtent, containerExtent);
    if (!_editorShellService.layout.canSplit(
      groupId,
      direction,
      containerSize,
    )) {
      // Distinguish max-panes from min-size
      if (_editorShellService.layout.allGroupIds.length >= maxPaneCount) {
        return PaneSplitResult.maxPanesReached;
      }
      return PaneSplitResult.minSizeBlocked;
    }
    _editorShellService.splitGroup(groupId, direction);
    notifyListeners();
    return PaneSplitResult.ok;
  }

  PaneCloseResult closeActivePane() {
    if (_editorShellService.paneCount <= 1) {
      return PaneCloseResult.lastPaneBlocked;
    }
    final closingGroupId = _editorShellService.activeGroupId;
    final closingGroup = _editorShellService.activeGroup;
    final activeAtomId = closingGroup?.activeAtomId;

    // Merge unique tabs from the closing group into the primary group so the
    // user's active note survives the pane close.
    final primaryGroup =
        _editorShellService.groups[_editorShellService.primaryGroupId];
    if (closingGroup != null && primaryGroup != null) {
      for (final tab in closingGroup.tabs) {
        if (!primaryGroup.containsAtom(tab.atomId)) {
          primaryGroup.addTab(tab);
        }
      }
    }

    unawaited(_editorShellService.closeGroup(closingGroupId));

    // Activate the previously-active note in the surviving primary group.
    if (activeAtomId != null && primaryGroup != null) {
      if (primaryGroup.containsAtom(activeAtomId)) {
        _editorShellService.switchTab(
          _editorShellService.primaryGroupId,
          activeAtomId,
        );
        _selectedNote = noteById(activeAtomId);
      }
    }
    _updateSaveStateFromBuffer();
    notifyListeners();
    return PaneCloseResult.ok;
  }

  bool switchActivePane(String groupId) {
    if (!_editorShellService.groups.containsKey(groupId)) return false;
    if (_editorShellService.activeGroupId == groupId) return true;
    _editorShellService.switchActiveGroup(groupId);
    _selectedNote = activeNoteId != null ? noteById(activeNoteId!) : null;
    _updateSaveStateFromBuffer();
    _requestEditorFocus();
    notifyListeners();
    return true;
  }

  void activateNextPane() {
    final groupIds = _editorShellService.groups.keys.toList();
    if (groupIds.length <= 1) return;
    final currentIndex = groupIds.indexOf(_editorShellService.activeGroupId);
    if (currentIndex < 0) return;
    switchActivePane(groupIds[(currentIndex + 1) % groupIds.length]);
  }

  // ── Save operations ────────────────────────────────────────────────

  Future<bool> flushPendingSave() async {
    await _awaitCreateTagApply(timeout: const Duration(milliseconds: 800));
    final atomId = activeNoteId;
    if (atomId == null) return true;

    await _noteTagManager.waitForAtomTagMutations(atomId);

    final buffer = _editorShellService.bufferFor(atomId);
    if (buffer == null || !buffer.isDirty) {
      _switchBlockErrorMessage = null;
      return true;
    }

    try {
      await buffer.flush();
      if (!buffer.isDirty) {
        _switchBlockErrorMessage = null;
        return true;
      }
    } catch (_) {}

    _switchBlockErrorMessage = 'Save failed. Retry or back up content.';
    notifyListeners();
    return false;
  }

  Future<bool> retrySaveCurrentDraft() async {
    final atomId = activeNoteId;
    if (atomId == null) return false;
    final buffer = _editorShellService.bufferFor(atomId);
    if (buffer == null) return false;

    try {
      await buffer.flush();
      if (!buffer.isDirty) {
        _switchBlockErrorMessage = null;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void updateActiveDraft(String content) {
    final atomId = activeNoteId;
    if (atomId == null) return;

    final buffer = _editorShellService.bufferFor(atomId);
    if (buffer == null || buffer.phase != BufferPhase.ready) return;
    if (buffer.content == content) return;

    buffer.edit(content);

    // Pin preview tab on edit to prevent surprise replacement
    _editorShellService.activeGroup?.pinPreviewTab(atomId);

    // Update title projection in list
    final current = _noteListManager.cachedNoteById(atomId) ?? _selectedNote;
    if (current != null) {
      final updated = _withContent(current, content);
      _selectedNote = updated;
      _noteListManager.upsertNote(updated);
      _editorShellService.updateTabTitle(
        atomId,
        updated.title.isNotEmpty ? updated.title : 'Untitled',
      );
    }

    _updateSaveStateFromBuffer();
    notifyListeners();
  }

  // ── List operations ────────────────────────────────────────────────

  Future<void> loadNotes() async {
    await _awaitCreateTagApply();
    await _noteTagManager.awaitPendingTagMutations();
    await _loadNotes(
      resetSession: true,
      preserveActiveWhenFilteredOut: false,
      refreshTags: true,
    );
  }

  Future<void> retryLoad() async {
    await _awaitCreateTagApply();
    await _noteTagManager.awaitPendingTagMutations();
    await _loadNotes(
      resetSession: false,
      preserveActiveWhenFilteredOut: false,
      refreshTags: false,
    );
  }

  Future<void> retryTagLoad() => _noteTagManager.refreshAvailableTags();

  Future<bool> applyTagFilter(String rawTag) =>
      _noteTagManager.applyTagFilter(rawTag);

  Future<bool> clearTagFilter() => _noteTagManager.clearTagFilter();

  // ── Tag operations ─────────────────────────────────────────────────

  Future<bool> setActiveNoteTags(List<String> rawTags) =>
      _noteTagManager.setActiveNoteTags(rawTags);

  Future<bool> addTagToActiveNote(String tag) =>
      _noteTagManager.addTagToActiveNote(tag);

  Future<bool> removeTagFromActiveNote(String tag) =>
      _noteTagManager.removeTagFromActiveNote(tag);

  // ── Create operations ──────────────────────────────────────────────

  String? takeCreateWarningMessage() {
    final warning = _createWarningMessage;
    _createWarningMessage = null;
    return warning;
  }

  Future<bool> createNote({String? parentNodeId}) async {
    if (_creatingNote) return false;
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
      _openAndActivateTab(createdNote.atomId, initialContent: '');
      _selectedNote = createdNote;
      _detailErrorMessage = null;
      _creatingNote = false;
      _setSaveState(NoteSaveState.clean);
      _requestEditorFocus();
      notifyListeners();

      if (createdNote.startAt != null || createdNote.endAt != null) {
        try {
          await _reminderLifecycle.onSchedule(createdNote.atomId);
        } catch (_) {}
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

  // ── Workspace delegation ───────────────────────────────────────────

  Future<rust_api.WorkspaceNodeResponse> createWorkspaceFolder({
    required String name,
    String? parentNodeId,
  }) => _workspaceTreeService.createWorkspaceFolder(
    name: name,
    parentNodeId: parentNodeId,
  );

  Future<rust_api.WorkspaceActionResponse> createWorkspaceNoteInFolder({
    String? parentNodeId,
  }) => _workspaceTreeService.createWorkspaceNoteInFolder(
    parentNodeId: parentNodeId,
  );

  Future<rust_api.WorkspaceActionResponse> renameWorkspaceNode({
    required String nodeId,
    required String newName,
  }) => _workspaceTreeService.renameWorkspaceNode(
    nodeId: nodeId,
    newName: newName,
  );

  Future<rust_api.WorkspaceActionResponse> moveWorkspaceNode({
    required String nodeId,
    String? newParentNodeId,
    int? targetOrder,
  }) => _workspaceTreeService.moveWorkspaceNode(
    nodeId: nodeId,
    newParentNodeId: newParentNodeId,
    targetOrder: targetOrder,
  );

  Future<rust_api.WorkspaceListChildrenResponse> listWorkspaceChildren({
    String? parentNodeId,
  }) => _workspaceTreeService.listWorkspaceChildren(parentNodeId: parentNodeId);

  Future<rust_api.WorkspaceActionResponse> deleteWorkspaceFolder({
    required String folderId,
    required String mode,
  }) => _workspaceTreeService.deleteWorkspaceFolder(
    folderId: folderId,
    mode: mode,
  );

  Future<void> refreshSelectedDetail() async {
    final atomId = activeNoteId;
    if (atomId == null) return;
    await _loadSelectedDetail(atomId: atomId);
  }

  // ── Internal: tab helpers ──────────────────────────────────────────

  void _openAndActivateTab(String atomId, {String? initialContent}) {
    final groupId = _editorShellService.activeGroupId;
    final title = titleForTab(atomId);
    final effectiveContent = initialContent ?? noteById(atomId)?.content;
    _editorShellService.openTab(
      groupId,
      atomId,
      initialContent: effectiveContent,
      title: title,
    );
    _updateSaveStateFromBuffer();
    _requestEditorFocus();
    _switchBlockErrorMessage = null;
  }

  bool _canReuseSelection(String atomId) {
    return activeNoteId == atomId &&
        _selectedNote != null &&
        _selectedNote!.atomId == atomId &&
        !_detailLoading &&
        _detailErrorMessage == null;
  }

  void _clearSelection() {
    _selectedNote = null;
    _detailLoading = false;
    _detailErrorMessage = null;
    _setSaveState(NoteSaveState.clean);
  }

  Future<bool> _selectFromExplorerByReplacingPreview({
    required String atomId,
    required String previewId,
  }) async {
    final group = _editorShellService.activeGroup;
    if (group == null) return selectNote(atomId);
    if (activeNoteId case final currentId? when currentId != atomId) {
      final flushed = await flushPendingSave();
      if (!flushed) return false;
    }

    final groupId = _editorShellService.activeGroupId;
    final title = titleForTab(atomId);
    final replaced = group.replacePreviewTab(
      TabEntry(atomId: atomId, title: title),
    );
    if (replaced != null) {
      // Clean up buffer for replaced preview via service (prevents double-dispose)
      final stillReferenced = _editorShellService.groups.values.any(
        (g) => g.containsAtom(replaced),
      );
      if (!stillReferenced) {
        _editorShellService.removeBuffer(replaced);
      }
    }

    // Ensure buffer exists for new tab
    if (_editorShellService.bufferFor(atomId) == null) {
      final cachedContent = noteById(atomId)?.content;
      _editorShellService.openTab(
        groupId,
        atomId,
        initialContent: cachedContent,
        title: title,
      );
    }
    _selectedNote = noteById(atomId);
    _updateSaveStateFromBuffer();
    _requestEditorFocus();
    _switchBlockErrorMessage = null;
    notifyListeners();
    await _loadSelectedDetail(atomId: atomId);
    return true;
  }

  // ── Internal: EditorShellService closures ──────────────────────────

  Future<String> _loadNoteContentFromFFI(String atomId) async {
    await _prepare();
    final response = await _noteGetInvoker(atomId: atomId);
    if (!response.ok || response.item == null) {
      throw Exception(response.message);
    }
    return response.item!.content;
  }

  Future<bool> _persistNoteContent(String atomId, String content) async {
    try {
      await _prepare();
      final response = await _noteUpdateInvoker(
        atomId: atomId,
        content: content,
      );
      if (!response.ok) return false;

      final saved = response.item;
      if (saved != null) {
        _noteListManager.upsertNote(saved, updatePersisted: true);
      } else {
        final current = _noteListManager.cachedNoteById(atomId);
        if (current != null) {
          _noteListManager.upsertNote(
            _withContent(current, content),
            updatePersisted: true,
          );
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _handleBufferSaved(String atomId, String content) {
    if (activeNoteId == atomId) {
      _selectedNote = _noteListManager.cachedNoteById(atomId) ?? _selectedNote;
      _switchBlockErrorMessage = null;
    }
  }

  // ── Internal: list operations ──────────────────────────────────────

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
    if (loadedItems == null) return;

    final currentActiveId = activeNoteId;
    String? detailTargetId;

    if (currentActiveId == null) {
      if (loadedItems.isNotEmpty) {
        final first = loadedItems.first;
        _openAndActivateTab(first.atomId, initialContent: first.content);
        _selectedNote = first;
        _setSaveState(NoteSaveState.clean);
        detailTargetId = first.atomId;
      } else {
        _clearSelection();
      }
    } else {
      final activeItem = _noteListManager.findLoadedItem(
        loadedItems,
        currentActiveId,
      );
      if (activeItem != null) {
        _selectedNote = activeItem;
      } else if (preserveActiveWhenFilteredOut) {
        _selectedNote =
            _noteListManager.cachedNoteById(currentActiveId) ?? _selectedNote;
      } else if (loadedItems.isNotEmpty) {
        final fallback = loadedItems.first;
        _openAndActivateTab(fallback.atomId, initialContent: fallback.content);
        _selectedNote = fallback;
        _updateSaveStateFromBuffer();
        _requestEditorFocus();
        detailTargetId = fallback.atomId;
      } else {
        _clearSelection();
      }
    }
    notifyListeners();

    if (detailTargetId != null) {
      await _loadSelectedDetail(atomId: detailTargetId);
    }
  }

  void _resetSessionForReload() {
    _editorShellService.resetSession();
    _noteListManager.resetSessionState();
    _noteTagManager.resetMutationState();
    _selectedNote = null;
    _detailLoading = false;
    _detailErrorMessage = null;
    _creatingNote = false;
    _createErrorCode = null;
    _createErrorMessage = null;
    _createWarningMessage = null;
    _createTagApplyFuture = null;
    _savedBadgeTimer?.cancel();
    _noteSaveState = NoteSaveState.clean;
    _saveErrorMessage = null;
    _showSavedBadge = false;
  }

  Future<void> _loadSelectedDetail({required String atomId}) async {
    if (_disposed) return;
    final requestId = ++_detailRequestId;
    _detailLoading = true;
    _detailErrorMessage = null;
    _selectedNote = _noteListManager.findListItem(atomId) ?? _selectedNote;
    if (_disposed) return;
    notifyListeners();

    try {
      await _prepare();
      if (_disposed ||
          requestId != _detailRequestId ||
          atomId != activeNoteId) {
        return;
      }

      final response = await _noteListManager.loadNoteDetail(atomId: atomId);
      if (_disposed ||
          requestId != _detailRequestId ||
          atomId != activeNoteId) {
        return;
      }

      if (!response.ok) {
        _detailLoading = false;
        _detailErrorMessage = _envelopeError(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to load note detail.',
        );
        if (!_disposed) notifyListeners();
        return;
      }

      if (response.item case final note?) {
        _selectedNote = note;
        _noteListManager.upsertNote(note, updatePersisted: true);
        // Update buffer if it hasn't been edited yet
        final buffer = _editorShellService.bufferFor(note.atomId);
        if (buffer != null && buffer.phase == BufferPhase.loading) {
          buffer.initialize(note.content);
        }
        _detailLoading = false;
        _detailErrorMessage = null;
        _updateSaveStateFromBuffer();
        if (!_disposed) notifyListeners();
        return;
      }

      _detailLoading = false;
      _detailErrorMessage = 'Note detail is empty.';
      if (!_disposed) notifyListeners();
    } catch (error) {
      if (_disposed ||
          requestId != _detailRequestId ||
          atomId != activeNoteId) {
        return;
      }
      _detailLoading = false;
      _detailErrorMessage = 'Note detail load failed unexpectedly: $error';
      if (!_disposed) notifyListeners();
    }
  }

  // ── Internal: workspace helpers ────────────────────────────────────

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
    final atomId = activeNoteId?.trim();
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

  Future<void> _reconcileOpenTabsAfterWorkspaceMutation() async {
    final group = _editorShellService.activeGroup;
    if (group == null || group.tabs.isEmpty) return;

    final allAtomIds = group.tabs.map((t) => t.atomId).toList();
    final removedAtomIds = <String>[];
    for (final atomId in allAtomIds) {
      try {
        final response = await _noteListManager.loadNoteDetail(atomId: atomId);
        if (!response.ok && response.errorCode == 'note_not_found') {
          removedAtomIds.add(atomId);
        } else if (response.item case final note?) {
          _noteListManager.upsertNote(note, updatePersisted: true);
        }
      } catch (_) {}
    }

    if (removedAtomIds.isEmpty) return;

    final groupId = _editorShellService.activeGroupId;
    for (final atomId in removedAtomIds) {
      await _editorShellService.closeTab(groupId, atomId);
      _noteTagManager.clearStateForDeletedAtom(atomId);
    }

    if (group.tabs.isEmpty) {
      _clearSelection();
      notifyListeners();
      return;
    }

    final newActiveId = group.activeAtomId;
    if (newActiveId != null) {
      _selectedNote = noteById(newActiveId);
      _updateSaveStateFromBuffer();
      _requestEditorFocus();
      notifyListeners();
      await _loadSelectedDetail(atomId: newActiveId);
    }
  }

  // ── Internal: state helpers ────────────────────────────────────────

  void _requestEditorFocus() {
    _editorFocusRequestId += 1;
  }

  bool _isDirty(String atomId) {
    return _editorShellService.bufferFor(atomId)?.isDirty ?? false;
  }

  bool _hasPendingSaveFor(String atomId) {
    final buffer = _editorShellService.bufferFor(atomId);
    final bufferDirty =
        buffer != null &&
        (buffer.isDirty || buffer.saveState == SaveState.saving);
    return bufferDirty || _noteTagManager.hasPendingTagWorkFor(atomId);
  }

  void _setSaveState(
    NoteSaveState nextState, {
    bool preserveError = false,
    bool showSavedBadge = false,
  }) {
    _noteSaveState = nextState;
    if (!preserveError) _saveErrorMessage = null;
    if (showSavedBadge) {
      _showSavedBadge = true;
      _savedBadgeTimer?.cancel();
      _savedBadgeTimer = _debounceTimerFactory(const Duration(seconds: 3), () {
        if (_noteSaveState != NoteSaveState.clean) return;
        _showSavedBadge = false;
        notifyListeners();
      });
    } else {
      _savedBadgeTimer?.cancel();
      _showSavedBadge = false;
    }
  }

  void _updateSaveStateFromBuffer() {
    final atomId = activeNoteId;
    if (atomId == null) {
      _setSaveState(NoteSaveState.clean);
      return;
    }
    final buffer = _editorShellService.bufferFor(atomId);
    if (buffer == null) {
      _setSaveState(NoteSaveState.clean);
      return;
    }
    switch (buffer.saveState) {
      case SaveState.loading:
      case SaveState.clean:
        final wasSaving = _noteSaveState == NoteSaveState.saving;
        _setSaveState(NoteSaveState.clean, showSavedBadge: wasSaving);
      case SaveState.dirty:
        _setSaveState(NoteSaveState.dirty);
      case SaveState.saving:
        _setSaveState(NoteSaveState.saving);
      case SaveState.error:
        _saveErrorMessage = buffer.errorMessage;
        _setSaveState(NoteSaveState.error, preserveError: true);
    }
  }

  rust_api.AtomListItem _withContent(
    rust_api.AtomListItem current,
    String content,
  ) {
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

  String _envelopeError({
    required String? errorCode,
    required String message,
    required String fallback,
  }) {
    final normalized = message.trim();
    if (errorCode == null || errorCode.trim().isEmpty) {
      return normalized.isEmpty ? fallback : normalized;
    }
    if (normalized.isEmpty) return '[$errorCode] $fallback';
    return '[$errorCode] $normalized';
  }

  Future<void> _awaitCreateTagApply({Duration? timeout}) async {
    final pending = _createTagApplyFuture;
    if (pending == null) return;
    try {
      if (timeout == null) {
        await pending;
      } else {
        await pending.timeout(timeout, onTimeout: () {});
      }
    } catch (_) {}
  }

  // ── Listener handlers ──────────────────────────────────────────────

  void _handleEditorShellChanged() {
    if (_disposed) return;
    _updateSaveStateFromBuffer();
    notifyListeners();
  }

  void _handleNoteListManagerChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  void _handleNoteTagManagerChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  void _handleWorkspaceTreeServiceChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  // ── Dispose ────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _savedBadgeTimer?.cancel();
    _noteListManager.removeListener(_handleNoteListManagerChanged);
    _editorShellService.removeListener(_handleEditorShellChanged);
    _noteTagManager.removeListener(_handleNoteTagManagerChanged);
    _workspaceTreeService.removeListener(_handleWorkspaceTreeServiceChanged);
    _noteListManager.dispose();
    _editorShellService.dispose();
    _noteTagManager.dispose();
    _workspaceTreeService.dispose();
    super.dispose();
  }
}

// ── Default invokers ───────────────────────────────────────────────────

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
