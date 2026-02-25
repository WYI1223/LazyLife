import 'package:flutter/material.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

typedef RenameNodeDialogConfirm = void Function(String newName);
typedef RenameNodeDialogCancel = void Function();

class RenameNodeDialog extends StatefulWidget {
  const RenameNodeDialog({
    super.key,
    required this.initialName,
    required this.onConfirm,
    required this.onCancel,
  });

  final String initialName;
  final RenameNodeDialogConfirm onConfirm;
  final RenameNodeDialogCancel onCancel;

  @override
  State<RenameNodeDialog> createState() => _RenameNodeDialogState();
}

class _RenameNodeDialogState extends State<RenameNodeDialog> {
  late String _draftName;

  bool get _canSubmit =>
      _draftName.trim().isNotEmpty &&
      _draftName.trim() != widget.initialName.trim();

  String _l10nText({
    required String fallback,
    required String Function(AppLocalizations l10n) pick,
  }) {
    final l10n = AppLocalizations.of(context);
    return l10n == null ? fallback : pick(l10n);
  }

  @override
  void initState() {
    super.initState();
    _draftName = widget.initialName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('notes_rename_node_dialog'),
      title: Text(
        _l10nText(
          fallback: 'Rename',
          pick: (l10n) => l10n.notesRenameDialogTitle,
        ),
      ),
      content: TextFormField(
        key: const Key('notes_rename_node_input'),
        autofocus: true,
        initialValue: widget.initialName,
        onChanged: (value) {
          setState(() {
            _draftName = value;
          });
        },
        onFieldSubmitted: (_) {
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
          key: const Key('notes_rename_node_confirm_button'),
          onPressed: _canSubmit
              ? () {
                  widget.onConfirm(_draftName.trim());
                }
              : null,
          child: Text(
            _l10nText(
              fallback: 'Rename',
              pick: (l10n) => l10n.notesRenameAction,
            ),
          ),
        ),
      ],
    );
  }
}
