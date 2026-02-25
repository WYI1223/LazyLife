import 'package:flutter/material.dart';
import 'package:lazynote_flutter/features/notes/notes_style.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

enum FolderDeleteMode { dissolve, deleteAll }

extension FolderDeleteModeX on FolderDeleteMode {
  String get wireValue => switch (this) {
    FolderDeleteMode.dissolve => 'dissolve',
    FolderDeleteMode.deleteAll => 'delete_all',
  };

  String label(BuildContext context) => switch (this) {
    FolderDeleteMode.dissolve =>
      AppLocalizations.of(context)?.notesDeleteModeDissolve ?? 'Dissolve',
    FolderDeleteMode.deleteAll =>
      AppLocalizations.of(context)?.notesDeleteModeDeleteAll ?? 'Delete all',
  };

  String description(BuildContext context) => switch (this) {
    FolderDeleteMode.dissolve =>
      AppLocalizations.of(context)?.notesDeleteModeDissolveDescription ??
          'Keep notes, move direct children to root.',
    FolderDeleteMode.deleteAll =>
      AppLocalizations.of(context)?.notesDeleteModeDeleteAllDescription ??
          'Delete folder subtree references and scoped notes.',
  };
}

typedef DeleteFolderDialogConfirm = void Function(FolderDeleteMode mode);
typedef DeleteFolderDialogCancel = void Function();

class DeleteFolderDialog extends StatefulWidget {
  const DeleteFolderDialog({
    super.key,
    required this.folderLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final String folderLabel;
  final DeleteFolderDialogConfirm onConfirm;
  final DeleteFolderDialogCancel onCancel;

  @override
  State<DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<DeleteFolderDialog> {
  FolderDeleteMode _mode = FolderDeleteMode.dissolve;

  String _l10nText({
    required String fallback,
    required String Function(AppLocalizations l10n) pick,
  }) {
    final l10n = AppLocalizations.of(context);
    return l10n == null ? fallback : pick(l10n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('notes_delete_folder_dialog'),
      title: Text(
        _l10nText(
          fallback: 'Delete folder',
          pick: (l10n) => l10n.notesDeleteFolderDialogTitle,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.folderLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FolderDeleteMode.values
                .map(
                  (entry) => ChoiceChip(
                    key: Key('notes_folder_delete_mode_${entry.wireValue}'),
                    label: Text(entry.label(context)),
                    selected: _mode == entry,
                    onSelected: (_) {
                      setState(() {
                        _mode = entry;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          Text(
            _mode.description(context),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: kNotesSecondaryText),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            _l10nText(fallback: 'Cancel', pick: (l10n) => l10n.commonCancel),
          ),
        ),
        FilledButton.tonal(
          key: const Key('notes_folder_delete_confirm_button'),
          onPressed: () {
            widget.onConfirm(_mode);
          },
          child: Text(
            _l10nText(fallback: 'Confirm', pick: (l10n) => l10n.commonConfirm),
          ),
        ),
      ],
    );
  }
}
