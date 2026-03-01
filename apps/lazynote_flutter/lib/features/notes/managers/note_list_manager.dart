import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

typedef NoteListNotesListInvoker =
    Future<rust_api.AtomListResponse> Function({
      String? tag,
      int? limit,
      int? offset,
    });

typedef NoteListNoteGetInvoker =
    Future<rust_api.AtomItemResponse> Function({required String atomId});

typedef NoteListPrepare = Future<void> Function();

typedef NoteListEnvelopeError =
    String Function({
      required String? errorCode,
      required String message,
      required String fallback,
    });

typedef NoteListSelectedTagReader = String? Function();

typedef NoteListShouldIncludeInVisibleList =
    bool Function(rust_api.AtomListItem note);

typedef NoteListIsDirty = bool Function(String atomId);

typedef NoteListSyncPersistedSnapshot =
    void Function({
      required String atomId,
      required String content,
      required bool wasDirty,
    });

enum NotesListPhase { idle, loading, success, empty, error }

class NoteListManager extends ChangeNotifier {
  NoteListManager({
    required NoteListNotesListInvoker notesListInvoker,
    required NoteListNoteGetInvoker noteGetInvoker,
    required NoteListPrepare prepare,
    required NoteListEnvelopeError envelopeError,
    required NoteListSelectedTagReader selectedTag,
    required NoteListShouldIncludeInVisibleList shouldIncludeInVisibleList,
    required NoteListIsDirty isDirty,
    required NoteListSyncPersistedSnapshot syncPersistedSnapshot,
  }) : _notesListInvoker = notesListInvoker,
       _noteGetInvoker = noteGetInvoker,
       _prepare = prepare,
       _envelopeError = envelopeError,
       _selectedTag = selectedTag,
       _shouldIncludeInVisibleList = shouldIncludeInVisibleList,
       _isDirty = isDirty,
       _syncPersistedSnapshot = syncPersistedSnapshot;

  final NoteListNotesListInvoker _notesListInvoker;
  final NoteListNoteGetInvoker _noteGetInvoker;
  final NoteListPrepare _prepare;
  final NoteListEnvelopeError _envelopeError;
  final NoteListSelectedTagReader _selectedTag;
  final NoteListShouldIncludeInVisibleList _shouldIncludeInVisibleList;
  final NoteListIsDirty _isDirty;
  final NoteListSyncPersistedSnapshot _syncPersistedSnapshot;

  NotesListPhase _listPhase = NotesListPhase.idle;
  List<rust_api.AtomListItem> _items = const [];
  String? _listErrorMessage;
  int _listRequestId = 0;
  final Map<String, rust_api.AtomListItem> _noteCache =
      <String, rust_api.AtomListItem>{};

  NotesListPhase get listPhase => _listPhase;
  List<rust_api.AtomListItem> get items => List.unmodifiable(_items);
  String? get listErrorMessage => _listErrorMessage;

  rust_api.AtomListItem? noteById(String atomId) {
    return _noteCache[atomId] ?? findListItem(atomId);
  }

  rust_api.AtomListItem? cachedNoteById(String atomId) => _noteCache[atomId];

  rust_api.AtomListItem? findListItem(String atomId) {
    for (final item in _items) {
      if (item.atomId == atomId) {
        return item;
      }
    }
    return null;
  }

  rust_api.AtomListItem? findLoadedItem(
    List<rust_api.AtomListItem> items,
    String atomId,
  ) {
    for (final item in items) {
      if (item.atomId == atomId) {
        return item;
      }
    }
    return null;
  }

  void markListSuccess({bool notify = false}) {
    _listPhase = _items.isEmpty ? NotesListPhase.empty : NotesListPhase.success;
    if (notify) {
      notifyListeners();
    }
  }

  void resetSessionState({bool notify = false}) {
    _listRequestId += 1;
    _listPhase = NotesListPhase.idle;
    _items = const [];
    _listErrorMessage = null;
    _noteCache.clear();
    if (notify) {
      notifyListeners();
    }
  }

  void evictNoteState(String atomId) {
    _noteCache.remove(atomId);
  }

  void upsertNote(
    rust_api.AtomListItem note, {
    bool insertFront = false,
    bool updatePersisted = false,
    bool syncVisibleList = true,
  }) {
    final wasDirty = _isDirty(note.atomId);
    _noteCache[note.atomId] = note;
    if (updatePersisted) {
      _syncPersistedSnapshot(
        atomId: note.atomId,
        content: note.content,
        wasDirty: wasDirty,
      );
    }
    if (!syncVisibleList) {
      return;
    }

    final includeInVisibleList = _shouldIncludeInVisibleList(note);
    final mutable = List<rust_api.AtomListItem>.from(_items);
    final existingIndex = mutable.indexWhere(
      (item) => item.atomId == note.atomId,
    );
    if (includeInVisibleList) {
      if (existingIndex >= 0) {
        mutable[existingIndex] = note;
      } else if (insertFront) {
        mutable.insert(0, note);
      } else {
        mutable.add(note);
      }
    } else if (existingIndex >= 0) {
      mutable.removeAt(existingIndex);
    }
    _items = List<rust_api.AtomListItem>.unmodifiable(mutable);
  }

  Future<List<rust_api.AtomListItem>?> loadNotes({
    required int limit,
    int offset = 0,
  }) async {
    final requestId = ++_listRequestId;
    _listPhase = NotesListPhase.loading;
    _items = const [];
    _listErrorMessage = null;
    notifyListeners();

    try {
      await _prepare();
      if (requestId != _listRequestId) {
        return null;
      }

      final response = await _notesListInvoker(
        tag: _selectedTag(),
        limit: limit,
        offset: offset,
      );
      if (requestId != _listRequestId) {
        return null;
      }

      if (!response.ok) {
        _listPhase = NotesListPhase.error;
        _listErrorMessage = _envelopeError(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to load notes.',
        );
        notifyListeners();
        return null;
      }

      final loadedItems = List<rust_api.AtomListItem>.unmodifiable(
        response.items,
      );
      _items = loadedItems;
      for (final item in loadedItems) {
        // Keep visible list as returned by backend filter; only refresh cache.
        upsertNote(item, updatePersisted: true, syncVisibleList: false);
      }
      _listPhase = loadedItems.isEmpty
          ? NotesListPhase.empty
          : NotesListPhase.success;
      _listErrorMessage = null;
      notifyListeners();
      return loadedItems;
    } catch (error) {
      if (requestId != _listRequestId) {
        return null;
      }
      _listPhase = NotesListPhase.error;
      _listErrorMessage = 'Notes load failed unexpectedly: $error';
      notifyListeners();
      return null;
    }
  }

  Future<rust_api.AtomItemResponse> loadNoteDetail({
    required String atomId,
  }) async {
    return _noteGetInvoker(atomId: atomId);
  }
}
