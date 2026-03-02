import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Axis;
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/editor/edit_buffer.dart';
import 'package:lazynote_flutter/core/editor/editor_group_model.dart';
import 'package:lazynote_flutter/core/editor/editor_shell_service.dart';
import 'package:lazynote_flutter/core/editor/group_layout.dart';
import 'package:lazynote_flutter/core/reminders/reminder_lifecycle.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/core/workspace/workspace_tree_service.dart';
import 'package:lazynote_flutter/features/notes/managers/note_list_manager.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tag_manager.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tag_manager_types.dart';
import 'package:lazynote_flutter/features/notes/notes_coordinator_types.dart';

export 'package:lazynote_flutter/core/editor/editor_shell_service.dart'
    show EditorShellService;

export 'package:lazynote_flutter/core/editor/group_layout.dart'
    show maxPaneCount, minPaneExtent;

export 'package:lazynote_flutter/core/workspace/workspace_tree_service.dart'
    show
        WorkspaceCreateFolderInvoker,
        WorkspaceDeleteFolderInvoker,
        WorkspaceListChildrenInvoker,
        WorkspaceMoveNodeInvoker,
        WorkspaceRenameNodeInvoker,
        WorkspaceTreeService;

export 'managers/note_list_manager.dart' show NoteListManager, NotesListPhase;
export 'managers/note_tag_manager.dart' show NoteTagManager;
export 'managers/note_tag_manager_types.dart' show NoteSaveState;
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
    super.debounceTimerFactory,
    super.prepare,
    super.listLimit = 50,
    super.reminderLifecycle,
    super.autosaveDebounce,
  });
}
