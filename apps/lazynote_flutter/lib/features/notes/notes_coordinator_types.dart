import 'dart:async';

import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

/// Async list loader for Notes v0.1 UI flow.
typedef NotesListInvoker =
    Future<rust_api.AtomListResponse> Function({
      String? tag,
      int? limit,
      int? offset,
    });

/// Async detail loader for one selected note.
typedef NoteGetInvoker =
    Future<rust_api.AtomItemResponse> Function({required String atomId});

/// Async creator for one new note atom.
typedef NoteCreateInvoker =
    Future<rust_api.AtomItemResponse> Function({
      required String content,
      String? parentNodeId,
    });

/// Async updater for persisted note content.
typedef NoteUpdateInvoker =
    Future<rust_api.AtomItemResponse> Function({
      required String atomId,
      required String content,
    });

/// Timer factory for autosave debounce scheduling.
typedef DebounceTimerFactory =
    Timer Function(Duration duration, void Function() callback);

/// Pre-load hook used to ensure bridge/db prerequisites.
typedef NotesPrepare = Future<void> Function();

/// Result codes for pane split operations (PR-RB-06).
///
/// Replaces `WorkspaceSplitResult` from deleted `workspace_models.dart`.
enum PaneSplitResult { ok, maxPanesReached, minSizeBlocked }
