import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

class ExplorerFolderNode {
  const ExplorerFolderNode({
    required this.id,
    required this.label,
    this.parentId,
    this.children = const <ExplorerFolderNode>[],
    this.noteIds = const <String>[],
    this.deletable = true,
  });

  final String id;
  final String label;
  final String? parentId;
  final List<ExplorerFolderNode> children;
  final List<String> noteIds;
  final bool deletable;
}

typedef ExplorerWorkspaceFolderContextMenuInvoker =
    Future<void> Function({
      required BuildContext context,
      required rust_api.WorkspaceNodeItem folderNode,
      required Offset globalPosition,
    });

typedef ExplorerWorkspaceNoteContextMenuInvoker =
    Future<void> Function({
      required BuildContext context,
      required rust_api.WorkspaceNodeItem noteNode,
      required Offset globalPosition,
    });

typedef ExplorerWorkspaceDragWrapper =
    Widget Function({
      required BuildContext context,
      required rust_api.WorkspaceNodeItem node,
      required int depth,
      required Widget child,
    });

/// Localized UI labels consumed by [ExplorerTreeBuilder].
class ExplorerTreeLabels {
  const ExplorerTreeLabels({
    required this.retryLabel,
    required this.noItemsLabel,
    required this.newChildFolderTooltip,
    required this.deleteFolderTooltip,
  });

  final String retryLabel;
  final String noItemsLabel;
  final String newChildFolderTooltip;
  final String deleteFolderTooltip;
}

/// Simple state flags consumed by [ExplorerTreeBuilder].
class ExplorerTreeFlags {
  const ExplorerTreeFlags({
    required this.activeNoteId,
    required this.workspaceCreateFolderInFlight,
    required this.workspaceDeleteInFlight,
    required this.canCreateFolderAction,
    required this.canDeleteFolderAction,
  });

  final String? activeNoteId;
  final bool workspaceCreateFolderInFlight;
  final bool workspaceDeleteInFlight;
  final bool canCreateFolderAction;
  final bool canDeleteFolderAction;
}

/// Read-only accessors into the explorer tree expansion / loading state.
class ExplorerTreeStateAccessor {
  const ExplorerTreeStateAccessor({
    required this.isExpanded,
    required this.isLoading,
    required this.errorMessageFor,
    required this.hasLoaded,
    required this.childrenFor,
    required this.toggleFolder,
    required this.retryParent,
  });

  final bool Function(String nodeId) isExpanded;
  final bool Function(String nodeId) isLoading;
  final String? Function(String nodeId) errorMessageFor;
  final bool Function(String nodeId) hasLoaded;
  final List<rust_api.WorkspaceNodeItem>? Function(String nodeId) childrenFor;
  final Future<void> Function(String nodeId) toggleFolder;
  final Future<void> Function(String? parentNodeId) retryParent;
}

/// Interaction callbacks consumed by [ExplorerTreeBuilder].
class ExplorerTreeCallbacks {
  const ExplorerTreeCallbacks({
    required this.isSyntheticRootNodeId,
    required this.looksLikeUuid,
    required this.showCreateFolderDialog,
    required this.showDeleteFolderDialog,
    required this.recordRowContextMenuTrigger,
    required this.showFolderContextMenu,
    required this.showNoteContextMenu,
    required this.wrapWorkspaceRowWithDrag,
    required this.resolveNoteDisplayName,
    required this.titleForTab,
    required this.onNoteTap,
  });

  final bool Function(String nodeId) isSyntheticRootNodeId;
  final bool Function(String value) looksLikeUuid;
  final Future<void> Function(String? parentNodeId) showCreateFolderDialog;
  final Future<void> Function(ExplorerFolderNode node) showDeleteFolderDialog;
  final void Function(Offset globalPosition) recordRowContextMenuTrigger;
  final ExplorerWorkspaceFolderContextMenuInvoker showFolderContextMenu;
  final ExplorerWorkspaceNoteContextMenuInvoker showNoteContextMenu;
  final ExplorerWorkspaceDragWrapper wrapWorkspaceRowWithDrag;
  final String Function(String noteId, rust_api.WorkspaceNodeItem node)
  resolveNoteDisplayName;
  final String Function(String noteId) titleForTab;
  final void Function(String noteId) onNoteTap;
}
