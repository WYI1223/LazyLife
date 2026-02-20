import 'package:flutter/material.dart';

/// Explorer context actions for M1 baseline.
enum ExplorerContextAction { newNote, newFolder, rename, move, deleteFolder }

/// Logical target kind used to compose context menu entries.
enum ExplorerContextTargetKind { blankArea, folder, noteRef, syntheticRoot }

/// Context-menu capability descriptor for one explorer target.
class ExplorerContextMenuConfig {
  const ExplorerContextMenuConfig({
    required this.targetKind,
    required this.canCreateNote,
    required this.canCreateFolder,
    required this.canRename,
    required this.canMove,
    required this.canDeleteFolder,
  });

  final ExplorerContextTargetKind targetKind;
  final bool canCreateNote;
  final bool canCreateFolder;
  final bool canRename;
  final bool canMove;
  final bool canDeleteFolder;
}

/// Builds menu entries for one explorer target under M1 policy.
List<PopupMenuEntry<ExplorerContextAction>> buildExplorerContextMenuEntries(
  ExplorerContextMenuConfig config,
) {
  final entries = <PopupMenuEntry<ExplorerContextAction>>[];
  void addAction(ExplorerContextAction action, String label) {
    entries.add(
      PopupMenuItem<ExplorerContextAction>(
        key: Key('notes_context_action_${action.name}'),
        value: action,
        child: Text(label),
      ),
    );
  }

  if (config.canCreateNote) {
    addAction(ExplorerContextAction.newNote, 'New note');
  }
  if (config.canCreateFolder) {
    addAction(ExplorerContextAction.newFolder, 'New folder');
  }

  if (config.canRename || config.canMove || config.canDeleteFolder) {
    if (entries.isNotEmpty) {
      entries.add(const PopupMenuDivider());
    }
    if (config.canRename) {
      addAction(ExplorerContextAction.rename, 'Rename');
    }
    if (config.canMove) {
      addAction(ExplorerContextAction.move, 'Move');
    }
    if (config.canDeleteFolder) {
      addAction(ExplorerContextAction.deleteFolder, 'Delete folder');
    }
  }
  return entries;
}
