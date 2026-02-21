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
    required this.targetOrder,
    required this.sourceParentNodeId,
    required this.targetParentNodeId,
  });

  final String? newParentNodeId;
  final int? targetOrder;
  final String? sourceParentNodeId;
  final String? targetParentNodeId;

  bool get isReorder => targetOrder != null;
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
    required List<rust_api.WorkspaceNodeItem> siblings,
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

    final sourceParent = payload.sourceParentNodeId;
    final targetParent = normalizeParent(targetNode.parentNodeId);
    final sameParent = sourceParent == targetParent;

    // Same-parent reorder is only allowed inside the same kind group.
    if (sameParent) {
      if (payload.kind != targetNode.kind) {
        return null;
      }
      final targetOrder = _sameParentTargetOrder(
        payload: payload,
        targetNode: targetNode,
        siblings: siblings,
        isStableNodeId: isStableNodeId,
      );
      if (targetOrder == null) {
        return null;
      }
      return ExplorerDropPlan(
        newParentNodeId: targetParent,
        targetOrder: targetOrder,
        sourceParentNodeId: sourceParent,
        targetParentNodeId: targetParent,
      );
    }

    // Cross-parent move is allowed only when dropping onto a folder row.
    if (targetNode.kind != 'folder') {
      return null;
    }

    return ExplorerDropPlan(
      newParentNodeId: targetNodeId,
      targetOrder: null,
      sourceParentNodeId: sourceParent,
      targetParentNodeId: targetNodeId,
    );
  }

  /// Resolves drop-to-root lane to one move plan.
  ExplorerDropPlan? planForRootDrop({required ExplorerDragPayload payload}) {
    if (payload.sourceParentNodeId == null) {
      return null;
    }
    return ExplorerDropPlan(
      newParentNodeId: null,
      targetOrder: null,
      sourceParentNodeId: payload.sourceParentNodeId,
      targetParentNodeId: null,
    );
  }

  int? _sameParentTargetOrder({
    required ExplorerDragPayload payload,
    required rust_api.WorkspaceNodeItem targetNode,
    required List<rust_api.WorkspaceNodeItem> siblings,
    required bool Function(String nodeId) isStableNodeId,
  }) {
    final group = siblings
        .where((entry) => entry.kind == payload.kind)
        .where((entry) => isStableNodeId(entry.nodeId.trim()))
        .toList(growable: false);
    final sourceIndex = group.indexWhere(
      (entry) => entry.nodeId == payload.nodeId,
    );
    final targetIndex = group.indexWhere(
      (entry) => entry.nodeId == targetNode.nodeId,
    );
    if (sourceIndex < 0 || targetIndex < 0 || sourceIndex == targetIndex) {
      return null;
    }
    return targetIndex;
  }
}
