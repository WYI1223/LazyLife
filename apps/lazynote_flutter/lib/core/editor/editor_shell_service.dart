// Workbench-level singleton managing editor infrastructure.
//
// Composes EditorGroupModel (per-pane tabs), EditBuffer (per-atom content),
// and GroupLayout (recursive pane layout tree). Replaces the former split of
// state across NotesCoordinator managers and WorkspaceProvider.
//
// PR-RB-06: First landing of core/editor/ infrastructure.
// Design sources: S2 Phase 2, DI-1, S9, editor-shell-service module spec.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Axis;

import 'package:lazynote_flutter/core/editor/edit_buffer.dart';
import 'package:lazynote_flutter/core/editor/editor_group_model.dart';
import 'package:lazynote_flutter/core/editor/group_layout.dart';

/// Workbench singleton managing groups, buffers, and layout.
///
/// Closure injection pattern: the service does not know about FFI.
/// [_loadContentFn] and [_persistFn] are provided by the coordinator.
class EditorShellService extends ChangeNotifier {
  EditorShellService({
    required Future<String> Function(String atomId) loadContentFn,
    required Future<bool> Function(String atomId, String content) persistFn,
    void Function(String atomId, String content)? onBufferSaved,
    Timer Function(Duration, void Function())? timerFactory,
    Duration? autosaveDebounce,
  }) : _loadContentFn = loadContentFn,
       _persistFn = persistFn,
       _onBufferSaved = onBufferSaved,
       _timerFactory = timerFactory,
       _autosaveDebounce = autosaveDebounce {
    // Create default single-pane layout
    _activeGroupId = _defaultGroupId;
    _groups[_defaultGroupId] = EditorGroupModel(groupId: _defaultGroupId);
    _layout = GroupLayout(root: LeafNode(groupId: _defaultGroupId));
  }

  /// Fixed ID for the initial group created at construction and after reset.
  static const _defaultGroupId = 'group.primary';

  // ── Injected closures ────────────────────────────────────────────────

  final Future<String> Function(String atomId) _loadContentFn;
  final Future<bool> Function(String atomId, String content) _persistFn;
  final void Function(String atomId, String content)? _onBufferSaved;
  final Timer Function(Duration, void Function())? _timerFactory;
  final Duration? _autosaveDebounce;

  // ── State ────────────────────────────────────────────────────────────

  final Map<String, EditorGroupModel> _groups = {};
  final Map<String, EditBuffer> _buffers = {};
  late GroupLayout _layout;
  late String _activeGroupId;

  // ── Public accessors ─────────────────────────────────────────────────

  /// All editor groups keyed by groupId.
  Map<String, EditorGroupModel> get groups => Map.unmodifiable(_groups);

  /// All edit buffers keyed by atomId.
  Map<String, EditBuffer> get buffers => Map.unmodifiable(_buffers);

  /// Current layout tree.
  GroupLayout get layout => _layout;

  /// Active group identifier.
  String get activeGroupId => _activeGroupId;

  /// Active group model, or null if not found.
  EditorGroupModel? get activeGroup => _groups[_activeGroupId];

  /// Looks up the buffer for [atomId], or null.
  EditBuffer? bufferFor(String atomId) => _buffers[atomId];

  /// Whether any buffer has unsaved content.
  bool get hasPendingSaveWork =>
      _buffers.values.any((b) => b.isDirty || b.saveState == SaveState.saving);

  /// Removes and disposes the buffer for [atomId], if it exists.
  ///
  /// Used when a tab is replaced (e.g., preview swap) without going through
  /// [closeTab]. Prevents double-dispose on service teardown.
  void removeBuffer(String atomId) {
    final buffer = _buffers.remove(atomId);
    if (buffer != null) {
      buffer.removeListener(_onBufferChanged);
      buffer.dispose();
    }
  }

  // ── Tab operations ───────────────────────────────────────────────────

  /// Opens a tab in [groupId] for [atomId].
  ///
  /// If no buffer exists for [atomId], creates one in loading phase and
  /// triggers content load via [_loadContentFn].
  void openTab(
    String groupId,
    String atomId, {
    String? initialContent,
    String? title,
  }) {
    final group = _groups[groupId];
    if (group == null) return;

    final entry = TabEntry(atomId: atomId, title: title ?? 'Untitled');
    group.openTab(entry);

    // Ensure buffer exists
    if (!_buffers.containsKey(atomId)) {
      final buffer = EditBuffer(
        atomId: atomId,
        persistFn: _persistFn,
        onSaved: _onBufferSaved,
        autosaveDebounce:
            _autosaveDebounce ?? const Duration(milliseconds: 1500),
        timerFactory: _timerFactory,
      );
      buffer.addListener(_onBufferChanged);
      _buffers[atomId] = buffer;

      if (initialContent != null) {
        buffer.initialize(initialContent);
      } else {
        _loadBufferContent(atomId, buffer);
      }
    }

    notifyListeners();
  }

  /// Closes a tab in [groupId] for [atomId].
  ///
  /// If no other group references [atomId], the buffer is flushed and disposed.
  /// Empty groups are auto-collapsed when at least one other group remains
  /// (DI-1 Q2: group exists iff it has tabs; last pane is never removed).
  Future<void> closeTab(String groupId, String atomId) async {
    final group = _groups[groupId];
    if (group == null) return;

    group.removeTab(atomId);

    // Check if atom is still referenced by any group
    final stillReferenced = _groups.values.any((g) => g.containsAtom(atomId));
    if (!stillReferenced) {
      final buffer = _buffers.remove(atomId);
      if (buffer != null) {
        buffer.removeListener(_onBufferChanged);
        if (buffer.isDirty && buffer.phase == BufferPhase.ready) {
          await buffer.flush();
        }
        buffer.dispose();
      }
    }

    // Auto-collapse: remove empty group if at least one other group remains.
    if (group.isEmpty && _groups.length > 1) {
      _destroyGroup(groupId);
    }

    notifyListeners();
  }

  /// Switches the active tab in [groupId] to [atomId].
  void switchTab(String groupId, String atomId) {
    final group = _groups[groupId];
    if (group == null) return;
    group.activateTab(atomId);
    _activeGroupId = groupId;
    notifyListeners();
  }

  /// Updates the display title for [atomId] across all groups.
  void updateTabTitle(String atomId, String newTitle) {
    for (final group in _groups.values) {
      group.updateTitle(atomId, newTitle);
    }
  }

  // ── Save operations ──────────────────────────────────────────────────

  /// Immediately saves the buffer for [atomId].
  Future<void> flushBuffer(String atomId) async {
    final buffer = _buffers[atomId];
    if (buffer == null) return;
    await buffer.flush();
  }

  /// Flushes all dirty buffers. Called before app exit.
  Future<void> flushAllDirtyBuffers() async {
    final futures = <Future<void>>[];
    for (final buffer in _buffers.values) {
      if (buffer.isDirty && buffer.phase == BufferPhase.ready) {
        futures.add(buffer.flush());
      }
    }
    await Future.wait(futures);
  }

  // ── Layout operations ────────────────────────────────────────────────

  /// Splits [groupId] along [axis], creating a new pane.
  ///
  /// The new group copies the active tab from the source group.
  void splitGroup(String groupId, Axis axis) {
    final sourceGroup = _groups[groupId];
    if (sourceGroup == null) return;

    final (newLayout, newGroupId) = _layout.split(groupId, axis);
    _layout = newLayout;

    // Create new group, copy active tab as preview (so it gets replaced on
    // first explorer-open, keeping the pane single-tab until the user pins).
    final newGroup = EditorGroupModel(groupId: newGroupId);
    final activeAtomId = sourceGroup.activeAtomId;
    if (activeAtomId != null) {
      final sourceTab = sourceGroup.tabs.where((t) => t.atomId == activeAtomId);
      if (sourceTab.isNotEmpty) {
        newGroup.openTab(sourceTab.first);
        newGroup.setPreviewTab(activeAtomId);
      }
    }
    _groups[newGroupId] = newGroup;
    _activeGroupId = newGroupId;

    notifyListeners();
  }

  /// Adjusts the split fraction at [path] in the layout tree.
  void resizeAt(List<int> path, double newFraction) {
    _layout = _layout.resizeAt(path, newFraction);
    notifyListeners();
  }

  /// Resolves all leaf rects and divider positions for [containerSize].
  LayoutResolveResult resolveLayout(Size containerSize) {
    return _layout.resolve(containerSize);
  }

  /// Switches the active group.
  void switchActiveGroup(String groupId) {
    if (!_groups.containsKey(groupId)) return;
    if (_activeGroupId == groupId) return;
    _activeGroupId = groupId;
    notifyListeners();
  }

  // ── Session reset ────────────────────────────────────────────────────

  /// Hard resets all groups and buffers without flushing.
  ///
  /// Disposes everything and recreates a single default pane.
  void resetSession() {
    for (final buffer in _buffers.values) {
      buffer.removeListener(_onBufferChanged);
      buffer.dispose();
    }
    _buffers.clear();

    for (final group in _groups.values) {
      group.dispose();
    }
    _groups.clear();

    _groups[_defaultGroupId] = EditorGroupModel(groupId: _defaultGroupId);
    _layout = GroupLayout(root: LeafNode(groupId: _defaultGroupId));
    _activeGroupId = _defaultGroupId;
    notifyListeners();
  }

  /// Total number of open panes (leaf nodes in layout tree).
  int get paneCount => _groups.length;

  // ── Internal ─────────────────────────────────────────────────────────

  void _destroyGroup(String groupId) {
    _groups.remove(groupId);
    try {
      _layout = _layout.closeGroup(groupId);
    } on StateError {
      // Already removed or last node — ignore
    }
    if (_activeGroupId == groupId && _groups.isNotEmpty) {
      _activeGroupId = _groups.keys.first;
    }
  }

  void _onBufferChanged() => notifyListeners();

  Future<void> _loadBufferContent(String atomId, EditBuffer buffer) async {
    try {
      final content = await _loadContentFn(atomId);
      if (buffer.phase == BufferPhase.loading) {
        buffer.initialize(content);
      }
    } catch (e) {
      if (buffer.phase == BufferPhase.loading) {
        buffer.markError(e.toString());
      }
    }
  }

  @override
  void dispose() {
    for (final buffer in _buffers.values) {
      buffer.removeListener(_onBufferChanged);
      buffer.dispose();
    }
    for (final group in _groups.values) {
      group.dispose();
    }
    _buffers.clear();
    _groups.clear();
    super.dispose();
  }
}
