import 'dart:async';

import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

typedef WorkspaceDeleteFolderInvoker =
    Future<rust_api.WorkspaceActionResponse> Function({
      required String nodeId,
      required String mode,
    });

typedef WorkspaceCreateFolderInvoker =
    Future<rust_api.WorkspaceNodeResponse> Function({
      String? parentNodeId,
      required String name,
    });

typedef WorkspaceRenameNodeInvoker =
    Future<rust_api.WorkspaceActionResponse> Function({
      required String nodeId,
      required String newName,
    });

typedef WorkspaceMoveNodeInvoker =
    Future<rust_api.WorkspaceActionResponse> Function({
      required String nodeId,
      String? newParentId,
      int? targetOrder,
    });

typedef WorkspaceListChildrenInvoker =
    Future<rust_api.WorkspaceListChildrenResponse> Function({
      String? parentNodeId,
    });

typedef WorkspaceAncestorPathInvoker =
    Future<rust_api.WorkspaceAncestorPathResponse> Function({
      required String atomId,
    });

typedef WorkspacePrepare = Future<void> Function();

/// Result from workspace note creation, carrying error details for transparency.
typedef WorkspaceCreateNoteResult = ({
  String? atomId,
  String? errorCode,
  String? errorMessage,
});

typedef WorkspaceCreateNoteAndGetAtomId =
    Future<WorkspaceCreateNoteResult> Function({String? parentNodeId});

typedef WorkspaceFlushPendingSave = Future<bool> Function();

typedef WorkspaceDeleteSuccessHook = Future<void> Function();

typedef WorkspaceNoteById = rust_api.AtomListItem? Function(String atomId);

typedef WorkspaceListItemsReader = List<rust_api.AtomListItem> Function();
