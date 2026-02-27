import 'dart:async';

import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

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

/// Async creator for one new note atom.
typedef NoteCreateInvoker =
    Future<rust_api.NoteResponse> Function({required String content});

/// Async updater for persisted note content.
typedef NoteUpdateInvoker =
    Future<rust_api.NoteResponse> Function({
      required String atomId,
      required String content,
    });

/// Timer factory for autosave debounce scheduling.
typedef DebounceTimerFactory =
    Timer Function(Duration duration, void Function() callback);

/// Pre-load hook used to ensure bridge/db prerequisites.
typedef NotesPrepare = Future<void> Function();
