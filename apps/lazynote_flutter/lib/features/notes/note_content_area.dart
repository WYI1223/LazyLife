import 'package:flutter/material.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_controller.dart';
import 'package:lazynote_flutter/features/notes/notes_style.dart';

/// Center editor/content area for active note.
class NoteContentArea extends StatelessWidget {
  const NoteContentArea({super.key, required this.controller});

  /// Shared notes controller used to read list/detail snapshots.
  final NotesController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kNotesCanvasBackground,
        borderRadius: BorderRadius.circular(0),
      ),
      child: _buildContent(context),
    );
  }

  Widget _statusPlaceholder(
    BuildContext context, {
    required String text,
    Key? key,
  }) {
    return Center(
      child: Text(
        text,
        key: key,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: kNotesSecondaryText),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (controller.listPhase) {
      case NotesListPhase.idle:
      case NotesListPhase.loading:
        return _statusPlaceholder(context, text: 'Loading notes...');
      case NotesListPhase.error:
        return _statusPlaceholder(
          context,
          text: 'Cannot load detail while list is unavailable.',
        );
      case NotesListPhase.empty:
        return _statusPlaceholder(
          context,
          text: 'Create your first note in C2.',
        );
      case NotesListPhase.success:
        final atomId = controller.activeNoteId;
        if (atomId == null) {
          return _statusPlaceholder(
            context,
            text: 'Select a note to continue.',
          );
        }
        final note = controller.selectedNote;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              // Why: keep readable document line length on wide desktop windows.
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 28),
                child: Column(
                  key: const Key('notes_detail_placeholder'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Vibe Coding for LazyLife > Private',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: kNotesSecondaryText),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: const Key(
                                      'notes_detail_refresh_button',
                                    ),
                                    tooltip: 'Refresh detail',
                                    onPressed: controller.refreshSelectedDetail,
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: kNotesSecondaryText,
                                    ),
                                    iconSize: 18,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  _TopActionButton(
                                    label: 'Share',
                                    onPressed: () {},
                                  ),
                                  _TopActionButton(
                                    icon: Icons.star_border,
                                    onPressed: () {},
                                  ),
                                  _TopActionButton(
                                    icon: Icons.more_horiz,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (controller.detailLoading)
                          const SizedBox(
                            key: Key('notes_detail_loading'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: 'Add icon', onPressed: () {}),
                        _MetaChip(label: 'Add cover', onPressed: () {}),
                        _MetaChip(label: 'Add comment', onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (controller.detailErrorMessage case final error?) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kNotesErrorBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          error,
                          key: const Key('notes_detail_error'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: kNotesPrimaryText),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        key: const Key('notes_detail_retry_button'),
                        onPressed: controller.refreshSelectedDetail,
                        child: const Text('Retry detail'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (note != null) ...[
                      Text(
                        _titleForNote(note),
                        key: const Key('notes_detail_title'),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: kNotesPrimaryText,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Updated ${_formatAbsoluteTime(note.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kNotesSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _documentBody(note),
                        key: const Key('notes_detail_preview'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: kNotesPrimaryText,
                          height: 1.55,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Detail data is not available yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kNotesSecondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({this.label, this.icon, required this.onPressed});

  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (label case final value?) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: kNotesSecondaryText,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(value),
      );
    }
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: kNotesSecondaryText),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      tooltip: '',
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: kNotesSecondaryText,
        backgroundColor: kNotesItemHoverColor,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

String _titleForNote(rust_api.NoteItem note) {
  final lines = note.content.split(RegExp(r'\r?\n'));
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final withoutHeading = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
    final normalized = withoutHeading.isEmpty ? trimmed : withoutHeading;
    if (normalized.length <= 80) {
      return normalized;
    }
    return '${normalized.substring(0, 80)}...';
  }
  return 'Untitled';
}

String _documentBody(rust_api.NoteItem note) {
  final content = note.content.trim();
  if (content.isNotEmpty) {
    return content;
  }
  return _previewForNote(note);
}

String _previewForNote(rust_api.NoteItem note) {
  final preview = note.previewText?.trim();
  if (preview != null && preview.isNotEmpty) {
    return preview;
  }
  final normalized = note.content.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'No preview available.';
  }
  if (normalized.length <= 120) {
    return normalized;
  }
  return '${normalized.substring(0, 120)}...';
}

String _formatAbsoluteTime(int epochMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}
