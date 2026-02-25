import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/explorer_tree_builder_types.dart';
import 'package:lazynote_flutter/features/notes/explorer_tree_item.dart';
import 'package:lazynote_flutter/features/notes/notes_style.dart';

export 'package:lazynote_flutter/features/notes/explorer_tree_builder_types.dart'
    show ExplorerFolderNode;

class ExplorerTreeBuilder {
  const ExplorerTreeBuilder({
    required this.context,
    required this.retryLabel,
    required this.noItemsLabel,
    required this.newChildFolderTooltip,
    required this.deleteFolderTooltip,
    required this.workspaceCreateFolderInFlight,
    required this.workspaceDeleteInFlight,
    required this.canCreateFolderAction,
    required this.canDeleteFolderAction,
    required this.activeNoteId,
    required this.isExpanded,
    required this.isLoading,
    required this.errorMessageFor,
    required this.hasLoaded,
    required this.childrenFor,
    required this.toggleFolder,
    required this.retryParent,
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

  final BuildContext context;
  final String retryLabel;
  final String noItemsLabel;
  final String newChildFolderTooltip;
  final String deleteFolderTooltip;
  final bool workspaceCreateFolderInFlight;
  final bool workspaceDeleteInFlight;
  final bool canCreateFolderAction;
  final bool canDeleteFolderAction;
  final String? activeNoteId;
  final bool Function(String nodeId) isExpanded;
  final bool Function(String nodeId) isLoading;
  final String? Function(String nodeId) errorMessageFor;
  final bool Function(String nodeId) hasLoaded;
  final List<rust_api.WorkspaceNodeItem>? Function(String nodeId) childrenFor;
  final Future<void> Function(String nodeId) toggleFolder;
  final Future<void> Function(String? parentNodeId) retryParent;
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

  static List<ExplorerFolderNode> buildDefaultFolderTree({
    required List<String> noteIds,
    required String projectsLabel,
    required String notesLabel,
    required String personalLabel,
  }) {
    return <ExplorerFolderNode>[
      ExplorerFolderNode(
        id: 'projects',
        label: projectsLabel,
        deletable: false,
      ),
      ExplorerFolderNode(
        id: 'notes',
        label: notesLabel,
        deletable: false,
        noteIds: noteIds,
      ),
      ExplorerFolderNode(
        id: 'personal',
        label: personalLabel,
        deletable: false,
      ),
    ];
  }

  void appendWorkspaceRows({
    required List<Widget> rows,
    required List<rust_api.WorkspaceNodeItem> items,
    required int depth,
  }) {
    for (final item in items) {
      if (item.kind == 'folder') {
        final expanded = isExpanded(item.nodeId);
        final loading = isLoading(item.nodeId);
        final error = errorMessageFor(item.nodeId);
        final isSyntheticRoot = isSyntheticRootNodeId(item.nodeId);
        final canCreateChild =
            canCreateFolderAction &&
            (looksLikeUuid(item.nodeId) || isSyntheticRoot);
        final canDelete = canDeleteFolderAction && looksLikeUuid(item.nodeId);
        final folderRow = ExplorerTreeItem.folder(
          key: Key('notes_tree_folder_row_${item.nodeId}'),
          node: item,
          depth: depth,
          selected: false,
          expanded: expanded,
          canCreateChild: canCreateChild,
          canDelete: canDelete,
          onTap: () {
            unawaited(toggleFolder(item.nodeId));
          },
          onCreateChildFolder: canCreateChild
              ? workspaceCreateFolderInFlight
                    ? null
                    : () => unawaited(showCreateFolderDialog(item.nodeId))
              : null,
          onDeleteFolder: canDelete
              ? () => unawaited(
                  showDeleteFolderDialog(
                    ExplorerFolderNode(
                      id: item.nodeId,
                      label: item.displayName,
                      parentId: item.parentNodeId,
                      deletable: true,
                    ),
                  ),
                )
              : null,
          onSecondaryTapDown: (details) {
            recordRowContextMenuTrigger(details.globalPosition);
            unawaited(
              showFolderContextMenu(
                context: context,
                folderNode: item,
                globalPosition: details.globalPosition,
              ),
            );
          },
        );
        rows.add(
          wrapWorkspaceRowWithDrag(
            context: context,
            node: item,
            depth: depth,
            child: folderRow,
          ),
        );

        if (!expanded) {
          continue;
        }
        if (loading && !hasLoaded(item.nodeId)) {
          rows.add(
            Padding(
              key: Key('notes_tree_loading_${item.nodeId}'),
              padding: EdgeInsets.fromLTRB(30 + depth * 12, 2, 10, 4),
              child: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
            ),
          );
          continue;
        }
        if (error != null) {
          rows.add(
            Padding(
              key: Key('notes_tree_error_${item.nodeId}'),
              padding: EdgeInsets.fromLTRB(30 + depth * 12, 2, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      error,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    key: Key('notes_tree_retry_${item.nodeId}'),
                    onPressed: () {
                      unawaited(retryParent(item.nodeId));
                    },
                    child: Text(retryLabel),
                  ),
                ],
              ),
            ),
          );
          continue;
        }
        final children =
            childrenFor(item.nodeId) ?? const <rust_api.WorkspaceNodeItem>[];
        if (children.isEmpty) {
          rows.add(
            Padding(
              key: Key('notes_tree_empty_${item.nodeId}'),
              padding: EdgeInsets.fromLTRB(30 + depth * 12, 2, 10, 6),
              child: Text(
                noItemsLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: kNotesSecondaryText),
              ),
            ),
          );
          continue;
        }
        appendWorkspaceRows(rows: rows, items: children, depth: depth + 1);
        continue;
      }

      if (item.kind != 'note_ref') {
        continue;
      }
      final noteId = item.atomId;
      if (noteId == null || noteId.isEmpty) {
        continue;
      }
      final displayName = resolveNoteDisplayName(noteId, item);
      final noteRow = ExplorerTreeItem.note(
        key: Key('notes_tree_note_row_${item.nodeId}'),
        node: rust_api.WorkspaceNodeItem(
          nodeId: item.nodeId,
          kind: item.kind,
          parentNodeId: item.parentNodeId,
          atomId: item.atomId,
          displayName: displayName,
          sortOrder: item.sortOrder,
        ),
        depth: depth + 1,
        selected: noteId == activeNoteId,
        onTap: () => onNoteTap(noteId),
        onSecondaryTapDown: (details) {
          recordRowContextMenuTrigger(details.globalPosition);
          unawaited(
            showNoteContextMenu(
              context: context,
              noteNode: item,
              globalPosition: details.globalPosition,
            ),
          );
        },
      );
      rows.add(
        wrapWorkspaceRowWithDrag(
          context: context,
          node: item,
          depth: depth + 1,
          child: noteRow,
        ),
      );
    }
  }

  void appendLegacyFolderRows({
    required List<Widget> rows,
    required ExplorerFolderNode node,
    required int depth,
  }) {
    final canDelete =
        canDeleteFolderAction && node.deletable && looksLikeUuid(node.id);
    final canCreateChild = canCreateFolderAction && looksLikeUuid(node.id);
    rows.add(
      Padding(
        padding: EdgeInsets.fromLTRB(12 + depth * 12, 8, 10, 2),
        child: Row(
          children: [
            const Icon(
              Icons.chevron_right,
              size: 14,
              color: kNotesSecondaryText,
            ),
            const SizedBox(width: 2),
            Icon(Icons.folder_outlined, size: 16, color: kNotesSecondaryText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                node.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kNotesSecondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (canCreateChild)
              IconButton(
                key: Key('notes_folder_create_button_${node.id}'),
                tooltip: newChildFolderTooltip,
                onPressed: workspaceCreateFolderInFlight
                    ? null
                    : () => unawaited(showCreateFolderDialog(node.id)),
                constraints: const BoxConstraints.tightFor(
                  width: 22,
                  height: 22,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: workspaceCreateFolderInFlight
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          color: kNotesSecondaryText,
                        ),
                      )
                    : const Icon(
                        Icons.create_new_folder_outlined,
                        size: 14,
                        color: kNotesSecondaryText,
                      ),
              ),
            if (canDelete)
              IconButton(
                key: Key('notes_folder_delete_button_${node.id}'),
                tooltip: deleteFolderTooltip,
                onPressed: workspaceDeleteInFlight
                    ? null
                    : () => unawaited(showDeleteFolderDialog(node)),
                constraints: const BoxConstraints.tightFor(
                  width: 22,
                  height: 22,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: workspaceDeleteInFlight
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          color: kNotesSecondaryText,
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: kNotesSecondaryText,
                      ),
              ),
          ],
        ),
      ),
    );

    for (final child in node.children) {
      appendLegacyFolderRows(rows: rows, node: child, depth: depth + 1);
    }

    for (final noteId in node.noteIds) {
      rows.add(
        ExplorerTreeItem.note(
          key: Key('notes_tree_legacy_note_row_$noteId'),
          node: rust_api.WorkspaceNodeItem(
            nodeId: 'legacy_note_$noteId',
            kind: 'note_ref',
            parentNodeId: node.id,
            atomId: noteId,
            displayName: titleForTab(noteId),
            sortOrder: 0,
          ),
          selected: noteId == activeNoteId,
          depth: depth + 1,
          onTap: () => onNoteTap(noteId),
        ),
      );
    }
  }
}
