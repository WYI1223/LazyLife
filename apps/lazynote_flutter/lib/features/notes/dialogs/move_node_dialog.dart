import 'package:flutter/material.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

class MoveNodeDialogOption {
  const MoveNodeDialogOption({required this.nodeId, required this.label});

  final String nodeId;
  final String label;
}

typedef MoveNodeDialogConfirm = void Function(String targetNodeId);
typedef MoveNodeDialogCancel = void Function();

class MoveNodeDialog extends StatefulWidget {
  const MoveNodeDialog({
    super.key,
    required this.options,
    required this.initialTargetId,
    required this.onConfirm,
    required this.onCancel,
  });

  final List<MoveNodeDialogOption> options;
  final String initialTargetId;
  final MoveNodeDialogConfirm onConfirm;
  final MoveNodeDialogCancel onCancel;

  @override
  State<MoveNodeDialog> createState() => _MoveNodeDialogState();
}

class _MoveNodeDialogState extends State<MoveNodeDialog> {
  late String _selectedTargetId;

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
    _selectedTargetId = widget.initialTargetId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('notes_move_node_dialog'),
      title: Text(
        _l10nText(
          fallback: 'Move node',
          pick: (l10n) => l10n.notesMoveNodeDialogTitle,
        ),
      ),
      content: DropdownButtonFormField<String>(
        key: const Key('notes_move_node_target_dropdown'),
        initialValue: _selectedTargetId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: _l10nText(
            fallback: 'Target folder',
            pick: (l10n) => l10n.notesMoveTargetFolderLabel,
          ),
        ),
        items: widget.options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.nodeId,
                child: Text(option.label),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _selectedTargetId = value;
          });
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
          key: const Key('notes_move_node_confirm_button'),
          onPressed: () {
            widget.onConfirm(_selectedTargetId);
          },
          child: Text(
            _l10nText(fallback: 'Move', pick: (l10n) => l10n.notesMoveAction),
          ),
        ),
      ],
    );
  }
}
