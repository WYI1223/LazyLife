import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

/// Save lifecycle for active note draft persistence.
///
/// Moved from note_save_tracker.dart (PR-RB-06) — the tracker class was
/// absorbed into EditBuffer, but this enum is still used by NoteTagManager
/// and NoteContentArea.
enum NoteSaveState {
  /// Draft content matches persisted content.
  clean,

  /// Draft content has unsaved edits.
  dirty,

  /// Save call is currently in flight.
  saving,

  /// Last save attempt failed.
  error,
}

typedef TagsListInvoker = Future<rust_api.TagsListResponse> Function();

typedef NoteSetTagsInvoker =
    Future<rust_api.AtomItemResponse> Function({
      required String atomId,
      required List<String> tags,
    });

typedef TagPrepare = Future<void> Function();

typedef TagEnvelopeError =
    String Function({
      required String? errorCode,
      required String message,
      required String fallback,
    });

typedef TagFlushPendingSave = Future<bool> Function();

typedef TagReloadNotesForFilter =
    Future<bool> Function({required bool preserveActiveWhenFilteredOut});

typedef TagActiveNoteIdReader = String? Function();

typedef TagNoteLookup = rust_api.AtomListItem? Function(String atomId);

typedef TagUpsertNote =
    void Function(
      rust_api.AtomListItem note, {
      bool insertFront,
      bool updatePersisted,
      bool syncVisibleList,
    });

typedef TagIsDirtyReader = bool Function(String atomId);

typedef TagSetSaveState =
    void Function(
      NoteSaveState nextState, {
      bool preserveError,
      bool showSavedBadge,
    });

typedef TagSetSaveError = void Function(String? message);

typedef TagOnActiveNoteUpdated =
    void Function({
      required String atomId,
      required rust_api.AtomListItem note,
    });
