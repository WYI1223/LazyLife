import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lazynote_flutter/app/ui_slots/first_party_ui_slots.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_host.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_models.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_registry.dart';
import 'package:lazynote_flutter/features/notes/note_content_area.dart';
import 'package:lazynote_flutter/features/notes/note_explorer.dart';
import 'package:lazynote_flutter/features/notes/note_tab_strip.dart';
import 'package:lazynote_flutter/features/notes/notes_coordinator.dart';
import 'package:lazynote_flutter/features/notes/notes_style.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

/// Notes feature page mounted in Workbench left pane (PR-0010C foundation).
class NotesPage extends StatefulWidget {
  const NotesPage({
    super.key,
    this.controller,
    this.onBackToWorkbench,
    this.uiSlotRegistry,
    this.runtimeCapabilities = const <String>[],
  });

  /// Optional external controller for tests.
  final NotesCoordinator? controller;

  /// Optional callback that returns to Workbench home section.
  final VoidCallback? onBackToWorkbench;
  final UiSlotRegistry? uiSlotRegistry;
  final List<String> runtimeCapabilities;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PreviousTabIntent extends Intent {
  const _PreviousTabIntent();
}

enum _CloseDialogAction { cancel, retry }

class _NotesPageState extends State<NotesPage>
    with WidgetsBindingObserver, WindowListener {
  late final NotesCoordinator _coordinator;
  late final bool _ownsController;
  late final UiSlotRegistry _uiSlotRegistry;
  late final Listenable _mergedListenable;
  bool _windowCloseGuardEnabled = false;
  bool _preventCloseActive = false;
  bool _handlingWindowClose = false;
  bool _forceClosing = false;

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
    WidgetsBinding.instance.addObserver(this);
    _coordinator = widget.controller ?? NotesCoordinator();
    _ownsController = widget.controller == null;
    _uiSlotRegistry = widget.uiSlotRegistry ?? createFirstPartyUiSlotRegistry();
    _mergedListenable = Listenable.merge([
      _coordinator,
      _coordinator.editorShellService,
    ]);
    _coordinator.addListener(_onControllerChanged);
    unawaited(_setupWindowCloseGuard());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_coordinator.listPhase == NotesListPhase.idle) {
        _coordinator.loadNotes();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.removeListener(_onControllerChanged);
    if (_windowCloseGuardEnabled) {
      unawaited(_teardownWindowCloseGuard());
    }
    if (_ownsController) {
      _coordinator.dispose();
    }
    super.dispose();
  }

  bool get _supportsWindowCloseGuard {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (bindingName.contains('TestWidgetsFlutterBinding')) {
      return false;
    }
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => true,
      TargetPlatform.macOS => true,
      TargetPlatform.linux => true,
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      TargetPlatform.fuchsia => false,
    };
  }

  Future<void> _setupWindowCloseGuard() async {
    if (!_supportsWindowCloseGuard) {
      return;
    }
    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);
      _windowCloseGuardEnabled = true;
      await _syncWindowCloseInterception(force: true);
    } catch (_) {
      _windowCloseGuardEnabled = false;
    }
  }

  Future<void> _teardownWindowCloseGuard() async {
    try {
      windowManager.removeListener(this);
      await windowManager.setPreventClose(false);
    } catch (_) {}
    _windowCloseGuardEnabled = false;
    _preventCloseActive = false;
  }

  void _onControllerChanged() {
    if (!_windowCloseGuardEnabled || _forceClosing) {
      return;
    }
    unawaited(_syncWindowCloseInterception());
  }

  Future<void> _syncWindowCloseInterception({bool force = false}) async {
    if (!_windowCloseGuardEnabled) {
      return;
    }
    // Why: always-on close interception adds visible close latency even when
    // nothing is dirty. We only intercept while save work is pending.
    final shouldPrevent = _coordinator.hasPendingSaveWork;
    if (!force && shouldPrevent == _preventCloseActive) {
      return;
    }
    try {
      await windowManager.setPreventClose(shouldPrevent);
      _preventCloseActive = shouldPrevent;
    } catch (_) {}
  }

  Future<void> _closeWindowNow() async {
    _forceClosing = true;
    try {
      if (_windowCloseGuardEnabled && _preventCloseActive) {
        try {
          await windowManager.setPreventClose(false);
          _preventCloseActive = false;
        } catch (_) {}
      }
      try {
        // Why: prefer normal close path first so desktop shell exits quickly.
        await windowManager.close();
      } catch (_) {
        // Fallback: force destroy when close API is unavailable/fails.
        await windowManager.destroy();
      }
    } finally {
      _forceClosing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_coordinator.flushPendingSave());
    }
  }

  @override
  void onWindowClose() {
    if (!_windowCloseGuardEnabled || _handlingWindowClose) {
      return;
    }
    _handlingWindowClose = true;
    unawaited(_handleWindowCloseRequest());
  }

  Future<void> _handleWindowCloseRequest() async {
    try {
      if (!_coordinator.hasPendingSaveWork) {
        await _closeWindowNow();
        return;
      }

      final flushed = await _coordinator.flushPendingSave().timeout(
        // Why: close flow should be best-effort and responsive. Do not block
        // desktop shutdown on long I/O stalls.
        const Duration(milliseconds: 450),
        onTimeout: () => false,
      );
      if (!mounted) {
        return;
      }
      if (flushed) {
        await _closeWindowNow();
        return;
      }

      final action = await showDialog<_CloseDialogAction>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              _l10nText(
                fallback: 'Unsaved content',
                pick: (l10n) => l10n.notesUnsavedContentTitle,
              ),
            ),
            content: Text(
              _l10nText(
                fallback:
                    'Save failed. Retry or back up content before closing.',
                pick: (l10n) => l10n.notesSaveFailedCloseBody,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_CloseDialogAction.cancel);
                },
                child: Text(
                  _l10nText(
                    fallback: 'Keep editing',
                    pick: (l10n) => l10n.notesKeepEditingButton,
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop(_CloseDialogAction.retry);
                },
                child: Text(
                  _l10nText(
                    fallback: 'Retry save',
                    pick: (l10n) => l10n.notesRetrySaveButton,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (action == _CloseDialogAction.retry) {
        final retried = await _coordinator.retrySaveCurrentDraft();
        if (retried && mounted) {
          await _closeWindowNow();
        }
      }
    } finally {
      _handlingWindowClose = false;
    }
  }

  void _showSplitFeedback(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : null,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _handleSplitCommand({
    required Axis direction,
    required double editorWidthExtent,
    required double editorHeightExtent,
  }) {
    final result = _coordinator.splitActivePane(
      direction: direction,
      containerSize: Size(editorWidthExtent, editorHeightExtent),
    );
    if (result == PaneSplitResult.ok) {
      final paneCount = _coordinator.editorShellService.paneCount;
      _showSplitFeedback(
        _l10nText(
          fallback: 'Split created. $paneCount panes ready.',
          pick: (l10n) => l10n.notesSplitCreatedWithCount(paneCount),
        ),
      );
      return;
    }

    final message = switch (result) {
      PaneSplitResult.maxPanesReached => _l10nText(
        fallback: 'Cannot split: maximum pane count ($maxPaneCount) reached.',
        pick: (l10n) => l10n.notesSplitMaxPaneReached(maxPaneCount),
      ),
      PaneSplitResult.minSizeBlocked => _l10nText(
        fallback:
            'Cannot split: each pane must stay at least ${minPaneExtent.toInt()}px.',
        pick: (l10n) => l10n.notesSplitMinSizeBlocked(minPaneExtent.toInt()),
      ),
      PaneSplitResult.ok => _l10nText(
        fallback: 'Split created.',
        pick: (l10n) => l10n.notesSplitCreatedSimple,
      ),
    };
    _showSplitFeedback(message, isError: true);
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
              _coordinator.activateNextOpenNote();
              return null;
            },
          ),
          _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
            onInvoke: (_) {
              _coordinator.activatePreviousOpenNote();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: AnimatedBuilder(
            animation: _mergedListenable,
            builder: (context, _) {
              final editor = _coordinator.editorShellService;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final compactHeader = constraints.maxWidth < 860;
                  final headerTextColor = notesHeaderTextColor(context);
                  final secondaryTextColor = notesSecondaryTextColor(context);
                  final dividerColor = notesDividerColor(context);
                  // Why: keep the two-pane shell visually stable in Workbench
                  // regardless of host window resize jitter.
                  final paneHeight = constraints.maxHeight.isFinite
                      ? (constraints.maxHeight - 72).clamp(300, 640).toDouble()
                      : 640.0;
                  // Why: explorer should keep a stable shell width so note
                  // navigation does not reflow with content pane resizing.
                  const explorerWidth = 276.0;
                  final editorWidthExtent =
                      (constraints.maxWidth - explorerWidth - 1)
                          .clamp(0, constraints.maxWidth)
                          .toDouble();
                  final groupIds = editor.groups.keys.toList();
                  final activePaneIndex = groupIds.indexOf(
                    editor.activeGroupId,
                  );
                  final paneOrdinal = activePaneIndex < 0
                      ? '?'
                      : '${activePaneIndex + 1}';
                  final paneCount = editor.paneCount;

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
                              compactHeader
                                  ? _l10nText(
                                      fallback: 'Back',
                                      pick: (l10n) => l10n.notesBackShort,
                                    )
                                  : _l10nText(
                                      fallback: 'Back to Workbench',
                                      pick: (l10n) =>
                                          l10n.backToWorkbenchButton,
                                    ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: headerTextColor,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _l10nText(
                                fallback: 'Notes Shell',
                                pick: (l10n) => l10n.notesShellTitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: headerTextColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            key: const Key('notes_active_pane_indicator'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: kNotesSidebarBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              compactHeader
                                  ? 'P $paneOrdinal/$paneCount'
                                  : _l10nText(
                                      fallback: 'Pane $paneOrdinal/$paneCount',
                                      pick: (l10n) => l10n.notesPaneIndicator(
                                        paneOrdinal,
                                        paneCount,
                                      ),
                                    ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: secondaryTextColor),
                            ),
                          ),
                          IconButton(
                            key: const Key('notes_split_horizontal_button'),
                            tooltip: _l10nText(
                              fallback: 'Split right',
                              pick: (l10n) => l10n.notesSplitRightTooltip,
                            ),
                            onPressed: () {
                              _handleSplitCommand(
                                direction: Axis.horizontal,
                                editorWidthExtent: editorWidthExtent,
                                editorHeightExtent: paneHeight,
                              );
                            },
                            icon: Icon(
                              Icons.splitscreen_outlined,
                              color: headerTextColor,
                            ),
                          ),
                          IconButton(
                            key: const Key('notes_split_vertical_button'),
                            tooltip: _l10nText(
                              fallback: 'Split down',
                              pick: (l10n) => l10n.notesSplitDownTooltip,
                            ),
                            onPressed: () {
                              _handleSplitCommand(
                                direction: Axis.vertical,
                                editorWidthExtent: editorWidthExtent,
                                editorHeightExtent: paneHeight,
                              );
                            },
                            icon: Icon(
                              Icons.view_agenda_outlined,
                              color: headerTextColor,
                            ),
                          ),
                          IconButton(
                            key: const Key('notes_reload_button'),
                            tooltip: _l10nText(
                              fallback: 'Reload notes',
                              pick: (l10n) => l10n.notesReloadTooltip,
                            ),
                            onPressed:
                                (_coordinator.creatingNote ||
                                    _coordinator.createTagApplyInFlight)
                                ? null
                                : _coordinator.loadNotes,
                            icon: Icon(Icons.refresh, color: headerTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: kNotesShellTopGap),
                      SizedBox(
                        height: paneHeight,
                        child: Container(
                          key: const Key('notes_shell_card'),
                          decoration: BoxDecoration(
                            color: notesShellBackground(context),
                            borderRadius: BorderRadius.circular(
                              kNotesShellRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: kNotesShellShadowOpacity,
                                ),
                                blurRadius: kNotesShellShadowBlur,
                                offset: kNotesShellShadowOffset,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            children: [
                              SizedBox(
                                width: explorerWidth,
                                child: _buildExplorerPane(context),
                              ),
                              VerticalDivider(
                                key: const Key('notes_shell_divider'),
                                width: 1,
                                thickness: 1,
                                indent: kNotesShellDividerIndent,
                                endIndent: kNotesShellDividerIndent,
                                color: dividerColor,
                              ),
                              Expanded(child: _buildEditorPane()),
                            ],
                          ),
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

  Widget _buildExplorerPane(BuildContext context) {
    return UiSlotListHost(
      registry: _uiSlotRegistry,
      slotId: UiSlotIds.notesSidePanel,
      layer: UiSlotLayer.sidePanel,
      slotContext: UiSlotContext({
        UiSlotContextKeys.runtimeCapabilities: widget.runtimeCapabilities,
        UiSlotContextKeys.notesController: _coordinator,
        UiSlotContextKeys.notesOnOpenNoteRequested:
            _coordinator.openNoteFromExplorer,
        UiSlotContextKeys.notesOnOpenNotePinnedRequested:
            _coordinator.openNoteFromExplorerPinned,
        UiSlotContextKeys.notesOnCreateNoteRequested: () async {
          await _coordinator.createNote();
          if (!context.mounted) {
            return;
          }
          final warning = _coordinator.takeCreateWarningMessage();
          if (warning == null) {
            return;
          }
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(warning),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
        },
        UiSlotContextKeys.notesOnDeleteFolderRequested:
            (String folderId, String mode) {
              return _coordinator.deleteWorkspaceFolder(
                folderId: folderId,
                mode: mode,
              );
            },
        UiSlotContextKeys.notesOnCreateFolderRequested:
            (String name, String? parentNodeId) {
              return _coordinator.createWorkspaceFolder(
                name: name,
                parentNodeId: parentNodeId,
              );
            },
        UiSlotContextKeys.notesOnCreateNoteInFolderRequested:
            (String? parentNodeId) {
              return _coordinator.createWorkspaceNoteInFolder(
                parentNodeId: parentNodeId,
              );
            },
        UiSlotContextKeys.notesOnRenameNodeRequested:
            (String nodeId, String newName) {
              return _coordinator.renameWorkspaceNode(
                nodeId: nodeId,
                newName: newName,
              );
            },
        UiSlotContextKeys.notesOnMoveNodeRequested:
            (String nodeId, String? newParentNodeId, {int? targetOrder}) {
              return _coordinator.moveWorkspaceNode(
                nodeId: nodeId,
                newParentNodeId: newParentNodeId,
                targetOrder: targetOrder,
              );
            },
      }),
      listBuilder: (context, children) {
        return children.isEmpty
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children
                    .map((child) => Expanded(child: child))
                    .toList(growable: false),
              );
      },
      fallbackBuilder: (context) {
        return NoteExplorer(
          controller: _coordinator,
          onOpenNoteRequested: _coordinator.openNoteFromExplorer,
          onOpenNotePinnedRequested: _coordinator.openNoteFromExplorerPinned,
          onCreateNoteRequested: () async {
            await _coordinator.createNote();
            if (!context.mounted) {
              return;
            }
            final warning = _coordinator.takeCreateWarningMessage();
            if (warning == null) {
              return;
            }
            ScaffoldMessenger.maybeOf(context)
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(warning),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
          },
          onDeleteFolderRequested: (folderId, mode) {
            return _coordinator.deleteWorkspaceFolder(
              folderId: folderId,
              mode: mode,
            );
          },
          onCreateFolderRequested: (name, parentNodeId) {
            return _coordinator.createWorkspaceFolder(
              name: name,
              parentNodeId: parentNodeId,
            );
          },
          onCreateNoteInFolderRequested: (parentNodeId) {
            return _coordinator.createWorkspaceNoteInFolder(
              parentNodeId: parentNodeId,
            );
          },
          onRenameNodeRequested: (nodeId, newName) {
            return _coordinator.renameWorkspaceNode(
              nodeId: nodeId,
              newName: newName,
            );
          },
          onMoveNodeRequested: (nodeId, newParentNodeId, {targetOrder}) {
            return _coordinator.moveWorkspaceNode(
              nodeId: nodeId,
              newParentNodeId: newParentNodeId,
              targetOrder: targetOrder,
            );
          },
        );
      },
    );
  }

  Widget _buildEditorPane() {
    final editor = _coordinator.editorShellService;
    if (editor.paneCount <= 1) {
      // Single pane — render directly without layout resolve overhead.
      return Column(
        children: [
          NoteTabStrip(controller: _coordinator),
          Expanded(child: NoteContentArea(controller: _coordinator)),
        ],
      );
    }

    // Multi-pane: use resolveLayout() recursive binary tree rendering.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final resolved = editor.resolveLayout(size);
        return Stack(
          children: [
            for (final entry in resolved.leafRects.entries)
              Positioned.fromRect(
                rect: entry.value,
                child: _buildGroupPane(
                  entry.key,
                  isActive: entry.key == editor.activeGroupId,
                ),
              ),
            for (final divider in resolved.dividers)
              Positioned.fromRect(
                rect: divider.rect,
                child: _buildDividerHandle(divider, size),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGroupPane(String groupId, {required bool isActive}) {
    final borderSide = isActive
        ? const BorderSide(color: kNotesDividerColor, width: 2)
        : BorderSide.none;
    return GestureDetector(
      key: Key('editor_group_$groupId'),
      behavior: isActive
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      onTap: isActive ? null : () => _coordinator.switchActivePane(groupId),
      child: Container(
        decoration: BoxDecoration(
          color: kNotesCanvasBackground,
          border: Border(top: borderSide),
        ),
        child: Column(
          children: [
            NoteTabStrip(controller: _coordinator, groupId: groupId),
            Expanded(
              child: isActive
                  ? NoteContentArea(controller: _coordinator)
                  : IgnorePointer(
                      child: NoteContentArea(
                        controller: _coordinator,
                        groupId: groupId,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerHandle(DividerInfo divider, Size containerSize) {
    // Narrow width means vertical divider → horizontal split axis.
    final isVerticalDivider = divider.rect.width < divider.rect.height;
    final splitAxis = isVerticalDivider ? Axis.horizontal : Axis.vertical;
    final totalExtent = splitAxis == Axis.horizontal
        ? containerSize.width
        : containerSize.height;
    final usable = totalExtent - dividerThickness;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        if (usable <= 0) return;
        final delta = splitAxis == Axis.horizontal
            ? details.delta.dx
            : details.delta.dy;
        final currentLayout = _coordinator.editorShellService.layout;
        final currentFraction = _fractionAtPath(
          currentLayout.root,
          divider.path,
        );
        if (currentFraction == null) return;
        // Clamp so each side keeps at least minPaneExtent pixels.
        final minFrac = usable > 0 ? (minPaneExtent / usable) : 0.05;
        final maxFrac = usable > 0 ? (1.0 - minPaneExtent / usable) : 0.95;
        if (minFrac >= maxFrac) return; // container too small to resize
        final newFraction = (currentFraction + delta / usable).clamp(
          minFrac,
          maxFrac,
        );
        _coordinator.editorShellService.resizeAt(divider.path, newFraction);
      },
      child: MouseRegion(
        cursor: isVerticalDivider
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow,
        child: const ColoredBox(color: kNotesDividerColor),
      ),
    );
  }

  /// Walks the layout tree to find the fraction at [path].
  double? _fractionAtPath(LayoutNode node, List<int> path) {
    if (path.isEmpty) {
      return node is SplitNode ? node.fraction : null;
    }
    if (node is! SplitNode) return null;
    final index = path.first;
    final child = index == 0 ? node.first : node.second;
    return _fractionAtPath(child, path.sublist(1));
  }
}
