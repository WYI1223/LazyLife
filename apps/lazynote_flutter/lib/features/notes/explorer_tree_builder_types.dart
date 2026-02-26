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
