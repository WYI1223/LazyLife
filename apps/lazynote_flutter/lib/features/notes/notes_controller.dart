import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/rust_bridge.dart';

/// Async list loader for Notes v0.1 UI flow.
typedef NotesListInvoker =
    Future<rust_api.NotesListResponse> Function({
      String? tag,
      int? limit,
      int? offset,
    });

/// Async detail loader for one selected note.
typedef NoteGetInvoker =
    Future<rust_api.NoteResponse> Function({required String atomId});

/// Pre-load hook used to ensure bridge/db prerequisites.
typedef NotesPrepare = Future<void> Function();

/// Stable phase set for C1 list lifecycle.
enum NotesListPhase {
  /// No load has started yet.
  idle,

  /// List request is currently in flight.
  loading,

  /// List request succeeded with non-empty items.
  success,

  /// List request succeeded with zero items.
  empty,

  /// List request failed and carries an error message.
  error,
}

/// Stateful controller for Notes page list/detail baseline.
///
/// Contract:
/// - Owns list + detail lifecycle state for Notes shell.
/// - Handles tab-open/activate/close operations in-memory.
/// - Calls [notifyListeners] after every externally visible state transition.
class NotesController extends ChangeNotifier {
  /// Creates controller with injectable bridge hooks for testability.
  ///
  /// Input semantics:
  /// - [notesListInvoker]: loads list snapshot (`notes_list` contract).
  /// - [noteGetInvoker]: loads one note detail (`note_get` contract).
  /// - [prepare]: prerequisite hook before each bridge request.
  /// - [listLimit]: requested list page size for C1 baseline.
  NotesController({
    NotesListInvoker? notesListInvoker,
    NoteGetInvoker? noteGetInvoker,
    NotesPrepare? prepare,
    this.listLimit = 50,
  }) : _notesListInvoker = notesListInvoker ?? _defaultNotesListInvoker,
       _noteGetInvoker = noteGetInvoker ?? _defaultNoteGetInvoker,
       _prepare = prepare ?? _defaultPrepare;

  final NotesListInvoker _notesListInvoker;
  final NoteGetInvoker _noteGetInvoker;
  final NotesPrepare _prepare;

  /// Requested list limit for C1 list baseline.
  final int listLimit;

  NotesListPhase _listPhase = NotesListPhase.idle;
  List<rust_api.NoteItem> _items = const [];
  String? _listErrorMessage;

  rust_api.NoteItem? _selectedNote;
  bool _detailLoading = false;
  String? _detailErrorMessage;

  final List<String> _openNoteIds = <String>[];
  final Map<String, rust_api.NoteItem> _noteCache =
      <String, rust_api.NoteItem>{};
  String? _activeNoteId;

  int _listRequestId = 0;
  int _detailRequestId = 0;

  /// Current list phase.
  NotesListPhase get listPhase => _listPhase;

  /// Current list items from `notes_list`.
  List<rust_api.NoteItem> get items => List.unmodifiable(_items);

  /// Current list-level error message.
  String? get listErrorMessage => _listErrorMessage;

  /// Currently selected note atom id.
  String? get selectedAtomId => _activeNoteId;

  /// Currently active tab note id.
  String? get activeNoteId => _activeNoteId;

  /// Currently opened tab ids in order.
  List<String> get openNoteIds => List.unmodifiable(_openNoteIds);

  /// Selected note detail payload used by right pane.
  rust_api.NoteItem? get selectedNote => _selectedNote;

  /// Whether selected-note detail load is in flight.
  bool get detailLoading => _detailLoading;

  /// Current selected-note detail load error.
  String? get detailErrorMessage => _detailErrorMessage;

  /// Returns one cached/list note by id when available.
  rust_api.NoteItem? noteById(String atomId) {
    return _noteCache[atomId] ?? _findListItem(atomId);
  }

  /// Tab title projection used by tab manager.
  String titleForTab(String atomId) {
    final item = noteById(atomId);
    if (item == null) {
      return 'Untitled';
    }
    return _titleFromContent(item.content);
  }

  /// Loads note list and auto-selects first item when available.
  ///
  /// Side effects:
  /// - Resets existing tab/detail state before reloading.
  /// - Opens first loaded note as active tab on success.
  Future<void> loadNotes() async {
    final requestId = ++_listRequestId;
    _listPhase = NotesListPhase.loading;
    _items = const [];
    _listErrorMessage = null;
    _selectedNote = null;
    _detailLoading = false;
    _detailErrorMessage = null;
    _openNoteIds.clear();
    _noteCache.clear();
    _activeNoteId = null;
    notifyListeners();

    try {
      await _prepare();
      if (requestId != _listRequestId) {
        return;
      }

      final response = await _notesListInvoker(
        tag: null,
        limit: listLimit,
        offset: 0,
      );
      if (requestId != _listRequestId) {
        return;
      }

      if (!response.ok) {
        _listPhase = NotesListPhase.error;
        _listErrorMessage = _envelopeError(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to load notes.',
        );
        notifyListeners();
        return;
      }

      final loadedItems = List<rust_api.NoteItem>.unmodifiable(response.items);
      if (loadedItems.isEmpty) {
        _listPhase = NotesListPhase.empty;
        _items = const [];
        notifyListeners();
        return;
      }

      _listPhase = NotesListPhase.success;
      _items = loadedItems;
      for (final item in loadedItems) {
        _noteCache[item.atomId] = item;
      }
      _activeNoteId = loadedItems.first.atomId;
      _selectedNote = loadedItems.first;
      _openNoteIds
        ..clear()
        ..add(loadedItems.first.atomId);
      notifyListeners();

      await _loadSelectedDetail(atomId: loadedItems.first.atomId);
    } catch (error) {
      if (requestId != _listRequestId) {
        return;
      }
      _listPhase = NotesListPhase.error;
      _listErrorMessage = 'Notes load failed unexpectedly: $error';
      notifyListeners();
    }
  }

  /// Retries list loading from scratch.
  Future<void> retryLoad() => loadNotes();

  /// Handles open-note request from explorer shell.
  Future<void> openNoteFromExplorer(String atomId) => selectNote(atomId);

  /// Selects one note and refreshes detail snapshot.
  ///
  /// Side effects:
  /// - Opens a new tab when [atomId] is not already opened.
  /// - Keeps existing tabs unchanged when [atomId] is already opened.
  Future<void> selectNote(String atomId) async {
    if (_activeNoteId == atomId &&
        _selectedNote != null &&
        !_detailLoading &&
        _detailErrorMessage == null) {
      return;
    }

    _activeNoteId = atomId;
    if (!_openNoteIds.contains(atomId)) {
      _openNoteIds.add(atomId);
    }
    _selectedNote = _findListItem(atomId);
    notifyListeners();

    await _loadSelectedDetail(atomId: atomId);
  }

  /// Activates an already opened note tab and refreshes its detail.
  Future<void> activateOpenNote(String atomId) async {
    if (!_openNoteIds.contains(atomId)) {
      await selectNote(atomId);
      return;
    }
    _activeNoteId = atomId;
    _selectedNote = noteById(atomId);
    notifyListeners();
    await _loadSelectedDetail(atomId: atomId);
  }

  /// Moves active tab forward (Ctrl+Tab behavior).
  Future<void> activateNextOpenNote() async {
    if (_openNoteIds.length <= 1 || _activeNoteId == null) {
      return;
    }
    final currentIndex = _openNoteIds.indexOf(_activeNoteId!);
    if (currentIndex < 0) {
      return;
    }
    final nextIndex = (currentIndex + 1) % _openNoteIds.length;
    await activateOpenNote(_openNoteIds[nextIndex]);
  }

  /// Moves active tab backward (Ctrl+Shift+Tab behavior).
  Future<void> activatePreviousOpenNote() async {
    if (_openNoteIds.length <= 1 || _activeNoteId == null) {
      return;
    }
    final currentIndex = _openNoteIds.indexOf(_activeNoteId!);
    if (currentIndex < 0) {
      return;
    }
    final prevIndex =
        (currentIndex - 1 + _openNoteIds.length) % _openNoteIds.length;
    await activateOpenNote(_openNoteIds[prevIndex]);
  }

  /// Closes one opened tab.
  ///
  /// Side effects:
  /// - When closing active tab, selects deterministic fallback tab.
  /// - Clears selected detail state when the last tab is closed.
  Future<void> closeOpenNote(String atomId) async {
    final closedIndex = _openNoteIds.indexOf(atomId);
    if (closedIndex < 0) {
      return;
    }
    _openNoteIds.removeAt(closedIndex);
    if (_activeNoteId != atomId) {
      notifyListeners();
      return;
    }

    if (_openNoteIds.isEmpty) {
      _activeNoteId = null;
      _selectedNote = null;
      _detailLoading = false;
      _detailErrorMessage = null;
      notifyListeners();
      return;
    }

    final fallbackIndex = (closedIndex - 1).clamp(0, _openNoteIds.length - 1);
    final fallbackId = _openNoteIds[fallbackIndex];
    _activeNoteId = fallbackId;
    _selectedNote = noteById(fallbackId);
    notifyListeners();
    await _loadSelectedDetail(atomId: fallbackId);
  }

  /// Closes all tabs except [atomId], then activates [atomId].
  Future<void> closeOtherOpenNotes(String atomId) async {
    if (!_openNoteIds.contains(atomId)) {
      return;
    }
    _openNoteIds
      ..clear()
      ..add(atomId);
    _activeNoteId = atomId;
    _selectedNote = noteById(atomId);
    notifyListeners();
    await _loadSelectedDetail(atomId: atomId);
  }

  /// Closes tabs to the right of [atomId].
  ///
  /// Side effects:
  /// - Re-activates [atomId] if active tab was pruned by this operation.
  Future<void> closeOpenNotesToRight(String atomId) async {
    final index = _openNoteIds.indexOf(atomId);
    if (index < 0) {
      return;
    }
    if (index == _openNoteIds.length - 1) {
      return;
    }
    _openNoteIds.removeRange(index + 1, _openNoteIds.length);
    if (!_openNoteIds.contains(_activeNoteId)) {
      _activeNoteId = atomId;
      _selectedNote = noteById(atomId);
      notifyListeners();
      await _loadSelectedDetail(atomId: atomId);
      return;
    }
    notifyListeners();
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
    final requestId = ++_detailRequestId;
    _detailLoading = true;
    _detailErrorMessage = null;
    _selectedNote = _findListItem(atomId) ?? _selectedNote;
    notifyListeners();

    try {
      await _prepare();
      if (requestId != _detailRequestId || atomId != _activeNoteId) {
        return;
      }

      final response = await _noteGetInvoker(atomId: atomId);
      if (requestId != _detailRequestId || atomId != _activeNoteId) {
        return;
      }

      if (!response.ok) {
        _detailLoading = false;
        _detailErrorMessage = _envelopeError(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to load note detail.',
        );
        notifyListeners();
        return;
      }

      if (response.note case final note?) {
        _selectedNote = note;
        _noteCache[note.atomId] = note;
        _detailLoading = false;
        _detailErrorMessage = null;
        notifyListeners();
        return;
      }

      _detailLoading = false;
      _detailErrorMessage = 'Note detail is empty.';
      notifyListeners();
    } catch (error) {
      if (requestId != _detailRequestId || atomId != _activeNoteId) {
        return;
      }
      _detailLoading = false;
      _detailErrorMessage = 'Note detail load failed unexpectedly: $error';
      notifyListeners();
    }
  }

  rust_api.NoteItem? _findListItem(String atomId) {
    for (final item in _items) {
      if (item.atomId == atomId) {
        return item;
      }
    }
    return null;
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

  String _titleFromContent(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final withoutHeading = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      return withoutHeading.isEmpty ? trimmed : withoutHeading;
    }
    return 'Untitled';
  }
}

Future<rust_api.NotesListResponse> _defaultNotesListInvoker({
  String? tag,
  int? limit,
  int? offset,
}) {
  return rust_api.notesList(tag: tag, limit: limit, offset: offset);
}

Future<rust_api.NoteResponse> _defaultNoteGetInvoker({required String atomId}) {
  return rust_api.noteGet(atomId: atomId);
}

Future<void> _defaultPrepare() async {
  await RustBridge.ensureEntryDbPathConfigured();
}
