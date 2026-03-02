import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/reminders/reminder_lifecycle.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/features/notes/managers/note_draft_manager.dart';
import 'package:lazynote_flutter/features/notes/managers/note_list_manager.dart';
import 'package:lazynote_flutter/features/notes/managers/note_save_tracker.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tab_manager.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tag_manager.dart';
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_manager.dart';
import 'package:lazynote_flutter/features/notes/notes_coordinator_types.dart';
import 'package:lazynote_flutter/features/workspace/workspace_models.dart';
import 'package:lazynote_flutter/features/workspace/workspace_provider.dart';

export 'managers/note_draft_manager.dart' show NoteDraftManager;
export 'managers/note_list_manager.dart' show NoteListManager, NotesListPhase;
export 'managers/note_save_tracker.dart' show NoteSaveState;
export 'managers/note_tab_manager.dart' show NoteTabStateManager;
export 'managers/note_tag_manager.dart' show NoteTagManager;
export 'managers/workspace_tree_manager.dart'
    show
        WorkspaceCreateFolderInvoker,
        WorkspaceDeleteFolderInvoker,
        WorkspaceListChildrenInvoker,
        WorkspaceMoveNodeInvoker,
        WorkspaceRenameNodeInvoker,
        WorkspaceTreeManager;
export 'notes_coordinator_types.dart';

part 'notes_coordinator_impl.dart';

class NotesCoordinator extends _NotesCoordinatorImpl {
  NotesCoordinator({
    super.notesListInvoker,
    super.noteGetInvoker,
    super.noteCreateInvoker,
    super.noteUpdateInvoker,
    super.tagsListInvoker,
    super.noteSetTagsInvoker,
    super.workspaceDeleteFolderInvoker,
    super.workspaceCreateFolderInvoker,
    super.workspaceRenameNodeInvoker,
    super.workspaceMoveNodeInvoker,
    super.workspaceListChildrenInvoker,
    super.workspaceProvider,
    super.debounceTimerFactory,
    super.prepare,
    super.listLimit = 50,
    super.autosaveDebounce = const Duration(milliseconds: 1500),
    super.reminderLifecycle,
  });
}
