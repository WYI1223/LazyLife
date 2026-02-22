import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

/// One drag payload emitted by explorer tree rows.
@immutable
class ExplorerDragPayload {
  const ExplorerDragPayload({
    required this.nodeId,
    required this.kind,
    required this.sourceParentNodeId,
  });

  final String nodeId;
  final String kind;
  final String? sourceParentNodeId;
}

/// One resolved drag drop plan mapped to workspace move API input.
@immutable
class ExplorerDropPlan {
  const ExplorerDropPlan({
    required this.newParentNodeId,
    required this.sourceParentNodeId,
    required this.targetParentNodeId,
  });

  final String? newParentNodeId;
  final String? sourceParentNodeId;
  final String? targetParentNodeId;
}

/// Stateless decision helper for explorer drag/drop baseline.
class ExplorerDragController {
  const ExplorerDragController();

  /// Returns whether one tree node can start dragging in v0.2 M2.
  bool canDragNode({
    required rust_api.WorkspaceNodeItem node,
    required bool isSyntheticRootNodeId,
    required bool isStableNodeId,
  }) {
    if (isSyntheticRootNodeId) {
      return false;
    }
    if (!isStableNodeId) {
      return false;
    }
    return node.kind == 'folder' || node.kind == 'note_ref';
  }

  /// Resolves row-drop to one move plan (or null when invalid by policy).
  ExplorerDropPlan? planForRowDrop({
    required ExplorerDragPayload payload,
    required rust_api.WorkspaceNodeItem targetNode,
    required String? Function(String? parentNodeId) normalizeParent,
    required bool Function(String nodeId) isStableNodeId,
    required bool Function(String nodeId) isSyntheticRootNodeId,
  }) {
    if (payload.nodeId == targetNode.nodeId) {
      return null;
    }

    final targetNodeId = targetNode.nodeId.trim();
    if (targetNodeId.isEmpty || !isStableNodeId(targetNodeId)) {
      return null;
    }
    if (isSyntheticRootNodeId(targetNodeId)) {
      return null;
    }

    // v0.2 transition freeze: row-drop only supports "move into folder".
    // Same-parent reorder remains unsupported.
    if (targetNode.kind != 'folder') {
      return null;
    }

    final sourceParent = payload.sourceParentNodeId;
    final targetFolderId = targetNodeId;

    // No-op: source already belongs to this folder.
    if (sourceParent == targetFolderId) {
      return null;
    }

    return ExplorerDropPlan(
      newParentNodeId: targetFolderId,
      sourceParentNodeId: sourceParent,
      targetParentNodeId: targetFolderId,
    );
  }

  /// Resolves drop-to-root lane to one move plan.
  ExplorerDropPlan? planForRootDrop({required ExplorerDragPayload payload}) {
    if (payload.sourceParentNodeId == null) {
      return null;
    }
    return ExplorerDropPlan(
      newParentNodeId: null,
      sourceParentNodeId: payload.sourceParentNodeId,
      targetParentNodeId: null,
    );
  }
}
