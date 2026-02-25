import 'package:flutter/material.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

typedef CreateFolderDialogConfirm = void Function(String folderName);
typedef CreateFolderDialogCancel = void Function();

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final CreateFolderDialogConfirm onConfirm;
  final CreateFolderDialogCancel onCancel;

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  String _draftName = '';

  bool get _canSubmit => _draftName.trim().isNotEmpty;

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
      key: const Key('notes_create_folder_dialog'),
      title: Text(
        _l10nText(
          fallback: 'Create folder',
          pick: (l10n) => l10n.notesCreateFolderDialogTitle,
        ),
      ),
      content: TextField(
        key: const Key('notes_create_folder_name_input'),
        autofocus: true,
        decoration: InputDecoration(
          hintText: _l10nText(
            fallback: 'Folder name',
            pick: (l10n) => l10n.notesFolderNameHint,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _draftName = value;
          });
        },
        onSubmitted: (_) {
          if (_canSubmit) {
            widget.onConfirm(_draftName.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            _l10nText(fallback: 'Cancel', pick: (l10n) => l10n.commonCancel),
          ),
        ),
        FilledButton.tonal(
          key: const Key('notes_create_folder_confirm_button'),
          onPressed: _canSubmit
              ? () {
                  widget.onConfirm(_draftName.trim());
                }
              : null,
          child: Text(
            _l10nText(fallback: 'Create', pick: (l10n) => l10n.commonCreate),
          ),
        ),
      ],
    );
  }
}
