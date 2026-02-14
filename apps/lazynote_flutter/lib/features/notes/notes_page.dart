import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lazynote_flutter/features/notes/note_content_area.dart';
import 'package:lazynote_flutter/features/notes/note_explorer.dart';
import 'package:lazynote_flutter/features/notes/note_tab_manager.dart';
import 'package:lazynote_flutter/features/notes/notes_controller.dart';
import 'package:lazynote_flutter/features/notes/notes_style.dart';

/// Notes feature page mounted in Workbench left pane (PR-0010C foundation).
class NotesPage extends StatefulWidget {
  const NotesPage({super.key, this.controller, this.onBackToWorkbench});

  /// Optional external controller for tests.
  final NotesController? controller;

  /// Optional callback that returns to Workbench home section.
  final VoidCallback? onBackToWorkbench;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PreviousTabIntent extends Intent {
  const _PreviousTabIntent();
}

class _NotesPageState extends State<NotesPage> {
  late final NotesController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NotesController();
    _ownsController = widget.controller == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadNotes();
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.tab, control: true):
            _NextTabIntent(),
        SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
            _PreviousTabIntent(),
      },
      child: Actions(
        actions: {
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) {
              _controller.activateNextOpenNote();
              return null;
            },
          ),
          _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
            onInvoke: (_) {
              _controller.activatePreviousOpenNote();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final compactHeader = constraints.maxWidth < 860;
                  // Why: keep the two-pane shell visually stable in Workbench
                  // regardless of host window resize jitter.
                  final paneHeight = constraints.maxHeight.isFinite
                      ? (constraints.maxHeight - 72).clamp(300, 640).toDouble()
                      : 640.0;
                  // Why: explorer should keep a stable shell width so note
                  // navigation does not reflow with content pane resizing.
                  const explorerWidth = 276.0;

                  return Column(
                    key: const Key('notes_page_root'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TextButton.icon(
                            key: const Key('notes_back_to_workbench_button'),
                            onPressed: widget.onBackToWorkbench,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: Text(
                              compactHeader ? 'Back' : 'Back to Workbench',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: kNotesPrimaryText,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notes Shell',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: kNotesPrimaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (!compactHeader) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: kNotesSidebarBackground,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Ctrl+Tab switch',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: kNotesSecondaryText),
                              ),
                            ),
                          ],
                          IconButton(
                            key: const Key('notes_reload_button'),
                            tooltip: 'Reload notes',
                            onPressed: _controller.loadNotes,
                            icon: const Icon(
                              Icons.refresh,
                              color: kNotesPrimaryText,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: paneHeight,
                        child: Row(
                          children: [
                            SizedBox(
                              width: explorerWidth,
                              child: NoteExplorer(
                                controller: _controller,
                                onOpenNoteRequested:
                                    _controller.openNoteFromExplorer,
                              ),
                            ),
                            const VerticalDivider(
                              width: 1,
                              thickness: 1,
                              indent: 12,
                              endIndent: 12,
                              color: kNotesDividerColor,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  NoteTabManager(controller: _controller),
                                  Expanded(
                                    child: NoteContentArea(
                                      controller: _controller,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
