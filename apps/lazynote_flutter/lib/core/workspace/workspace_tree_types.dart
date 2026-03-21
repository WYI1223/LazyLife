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

typedef WorkspaceResolveDesignatedInvoker =
    Future<rust_api.DesignatedFolderResponse> Function({
      required rust_api.FfiCallerContext caller,
      required String workspaceId,
      required String role,
    });

typedef WorkspaceReassignDesignatedInvoker =
    Future<rust_api.WorkspaceActionResponse> Function({
      required rust_api.FfiCallerContext caller,
      required String workspaceId,
      required String role,
      required String newNodeUuid,
    });

typedef WorkspaceGetAncestorPathInvoker =
    Future<rust_api.AncestorPathResponse> Function({
      required rust_api.FfiCallerContext caller,
      required String nodeUuid,
    });

typedef WorkspaceGetDefaultInvoker =
    Future<rust_api.WorkspaceInfoResponse> Function({
      required rust_api.FfiCallerContext caller,
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

rust_api.FfiCallerContext buildWorkspaceCaller(String workspaceId) {
  return rust_api.FfiCallerContext(
    identity: rust_api.FfiCallerIdentity.app,
    scopeWorkspaceId: workspaceId,
  );
}

class WorkspaceInitException implements Exception {
  WorkspaceInitException(this.message);

  final String message;

  @override
  String toString() => 'WorkspaceInitException: $message';
}

class DesignatedRoleNotFoundException extends WorkspaceInitException {
  DesignatedRoleNotFoundException({
    required this.workspaceId,
    required this.role,
    String? message,
  }) : super(
         message ??
             'Designated role $role was not found for workspace $workspaceId.',
       );

  final String workspaceId;
  final String role;
}

enum TreeMutationType { create, rename, move, delete, reassign }

class TreeMutationDelta {
  TreeMutationDelta({
    required this.revision,
    required this.type,
    required Iterable<String?> affectedParentIds,
  }) : affectedParentIds = Set<String?>.unmodifiable(affectedParentIds.toSet());

  final int revision;
  final TreeMutationType type;
  final Set<String?> affectedParentIds;
}
