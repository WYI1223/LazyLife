import 'package:flutter/material.dart';
import 'package:lazynote_flutter/features/notes/note_editor.dart';
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
      decoration: const BoxDecoration(color: kNotesCanvasBackground),
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
        if (controller.detailErrorMessage case final error?) {
          return _detailErrorState(context, error: error);
        }
        final note = controller.selectedNote;
        if (note == null && controller.detailLoading) {
          return const Center(
            child: SizedBox(
              key: Key('notes_detail_loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        }
        if (note == null) {
          return _statusPlaceholder(
            context,
            text: 'Detail data is not available yet.',
          );
        }

        final saveError = controller.saveErrorMessage;
        return Center(
          child: ConstrainedBox(
            // Why: keep readable document line length on wide desktop windows.
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 28),
              child: Column(
                key: const Key('notes_detail_editor'),
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
                                _SaveStatusWidget(controller: controller),
                                const SizedBox(width: 6),
                                IconButton(
                                  key: const Key('notes_detail_refresh_button'),
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
                  if (controller.switchBlockErrorMessage
                      case final guardError?) ...[
                    const SizedBox(height: 10),
                    Container(
                      key: const Key('notes_switch_block_error_banner'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      color: kNotesErrorBackground,
                      child: Text(
                        guardError,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (controller.noteSaveState == NoteSaveState.error &&
                      saveError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      key: const Key('notes_save_error_banner'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      color: kNotesErrorBackground,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              saveError,
                              softWrap: true,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  Text(
                    controller.titleForTab(note.atomId),
                    key: const Key('notes_detail_title'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: kNotesPrimaryText,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Updated ${_formatAbsoluteTime(note.updatedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: kNotesSecondaryText),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: NoteEditor(
                      key: ValueKey<String>('note_editor_$atomId'),
                      content: controller.activeDraftContent,
                      focusRequestId: controller.editorFocusRequestId,
                      onChanged: controller.updateActiveDraft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _detailErrorState(BuildContext context, {required String error}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            key: const Key('notes_detail_error_center'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                key: const Key('notes_detail_error'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: kNotesPrimaryText),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: const Key('notes_detail_retry_button'),
                onPressed: controller.refreshSelectedDetail,
                child: const Text('Retry detail'),
              ),
            ],
          ),
        ),
      ),
    );
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

class _SaveStatusWidget extends StatelessWidget {
  const _SaveStatusWidget({required this.controller});

  final NotesController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.noteSaveState) {
      case NoteSaveState.clean:
        if (!controller.showSavedBadge) {
          return const SizedBox(
            key: Key('notes_save_status_idle'),
            width: 1,
            height: 1,
          );
        }
        return Row(
          key: const Key('notes_save_status_saved'),
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check, size: 14, color: Color(0xFF2E7D32)),
            SizedBox(width: 4),
            Text('Saved'),
          ],
        );
      case NoteSaveState.dirty:
        return Row(
          key: const Key('notes_save_status_dirty'),
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.circle, size: 7, color: kNotesSecondaryText),
            SizedBox(width: 5),
            Text('Unsaved'),
          ],
        );
      case NoteSaveState.saving:
        return Row(
          key: const Key('notes_save_status_saving'),
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            ),
            SizedBox(width: 6),
            Text('Saving...'),
          ],
        );
      case NoteSaveState.error:
        final fullError = controller.saveErrorMessage ?? 'Save failed';
        return Row(
          key: const Key('notes_save_status_error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: fullError,
              child: const Icon(
                Icons.error_outline,
                size: 14,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              // Why: keep top-right action row stable; long backend error text
              // is rendered by the dedicated save-error banner below.
              'Save failed',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(width: 6),
            TextButton(
              key: const Key('notes_save_retry_button'),
              onPressed: () {
                controller.retrySaveCurrentDraft();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              child: const Text('Retry'),
            ),
          ],
        );
    }
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

String _formatAbsoluteTime(int epochMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}
