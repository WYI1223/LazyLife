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
import 'package:lazynote_flutter/core/editor/layout_persistence.dart';

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
    LayoutPersistence? layoutPersistence,
  }) : _loadContentFn = loadContentFn,
       _persistFn = persistFn,
       _onBufferSaved = onBufferSaved,
       _timerFactory = timerFactory,
       _autosaveDebounce = autosaveDebounce,
       _layoutPersistence = layoutPersistence ?? LayoutPersistence.instance {
    // Restore from persisted snapshot or create default single-pane layout.
    // consumeLoadedSnapshot() returns the snapshot exactly once, preventing
    // reuse of mutable EditorGroupModel objects across service lifetimes.
    final snapshot = _layoutPersistence?.consumeLoadedSnapshot();
    if (snapshot != null) {
      _layout = snapshot.layout;
      _groups.addAll(snapshot.groups);
      _activeGroupId = snapshot.activeGroupId;
    } else {
      _activeGroupId = _defaultGroupId;
      _groups[_defaultGroupId] = EditorGroupModel(groupId: _defaultGroupId);
      _layout = GroupLayout(root: LeafNode(groupId: _defaultGroupId));
    }
  }

  /// Fixed ID for the initial group created at construction and after reset.
  static const _defaultGroupId = 'group.primary';

  // ── Injected closures ────────────────────────────────────────────────

  final Future<String> Function(String atomId) _loadContentFn;
  final Future<bool> Function(String atomId, String content) _persistFn;
  final void Function(String atomId, String content)? _onBufferSaved;
  final Timer Function(Duration, void Function())? _timerFactory;
  final Duration? _autosaveDebounce;
  final LayoutPersistence? _layoutPersistence;

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

    _scheduleLayoutSave();

    // Ensure buffer exists and is loaded
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
    } else {
      // Buffer exists (e.g. from Phase 1 restore) — apply P2 lazy loading
      final existing = _buffers[atomId]!;
      if (existing.phase == BufferPhase.loading) {
        if (initialContent != null) {
          existing.initialize(initialContent);
        } else {
          _loadBufferContent(atomId, existing);
        }
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

    _scheduleLayoutSave();
    notifyListeners();
  }

  /// Switches the active tab in [groupId] to [atomId].
  ///
  /// P2 Lazy loading (DI-4 Q4): if the buffer is still in loading phase,
  /// triggers on-demand content load.
  void switchTab(String groupId, String atomId) {
    final group = _groups[groupId];
    if (group == null) return;
    group.activateTab(atomId);
    _activeGroupId = groupId;

    // T6: P2 Lazy — trigger load if buffer still in loading phase
    final buffer = _buffers[atomId];
    if (buffer != null && buffer.phase == BufferPhase.loading) {
      _loadBufferContent(atomId, buffer);
    }

    _scheduleLayoutSave();
    notifyListeners();
  }

  /// Updates the display title for [atomId] across all groups.
  void updateTabTitle(String atomId, String newTitle) {
    for (final group in _groups.values) {
      group.updateTitle(atomId, newTitle);
    }
  }

  // ── Buffer loading ──────────────────────────────────────────────────

  /// P1 Eager: loads all active tab buffers in parallel (DI-4 Q4).
  ///
  /// Called by the coordinator after Background Phase (DB ready). Creates
  /// buffers for restored tabs (from Phase 1 snapshot) and loads content
  /// for each group's active tab via fire-and-forget parallel fetch.
  Future<void> loadActiveBuffers() async {
    _ensureRestoredBuffersExist();

    final futures = <Future<void>>[];
    for (final group in _groups.values) {
      final atomId = group.activeAtomId;
      if (atomId == null) continue;
      final buffer = _buffers[atomId];
      if (buffer != null && buffer.phase == BufferPhase.loading) {
        futures.add(_loadBufferContent(atomId, buffer));
      }
    }
    await Future.wait(futures, eagerError: false);
  }

  /// Creates EditBuffer instances for all tabs restored from the layout
  /// snapshot. Phase 1 restores tab entries only; buffers are created here
  /// in loading phase, ready for P1/P2 content loading.
  void _ensureRestoredBuffersExist() {
    for (final group in _groups.values) {
      for (final tab in group.tabs) {
        if (!_buffers.containsKey(tab.atomId)) {
          final buffer = EditBuffer(
            atomId: tab.atomId,
            persistFn: _persistFn,
            onSaved: _onBufferSaved,
            autosaveDebounce:
                _autosaveDebounce ?? const Duration(milliseconds: 1500),
            timerFactory: _timerFactory,
          );
          buffer.addListener(_onBufferChanged);
          _buffers[tab.atomId] = buffer;
        }
      }
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

    _scheduleLayoutSave();
    notifyListeners();
  }

  /// Adjusts the split fraction at [path] in the layout tree.
  void resizeAt(List<int> path, double newFraction) {
    _layout = _layout.resizeAt(path, newFraction);
    _scheduleLayoutSave();
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
    _scheduleLayoutSave();
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
    _scheduleLayoutSave();
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

  void _scheduleLayoutSave() {
    _layoutPersistence?.scheduleSave(
      layout: _layout,
      groups: _groups,
      activeGroupId: _activeGroupId,
    );
  }

  void _onBufferChanged() => notifyListeners();

  /// Loads content for a single buffer via the injected closure.
  ///
  /// T7 failure handling (DI-4 Q4):
  /// - [AtomNotFoundException] → remove tab from all groups + auto-collapse
  /// - Generic exception → [buffer.markError] → UI shows error + retry
  Future<void> _loadBufferContent(String atomId, EditBuffer buffer) async {
    try {
      final content = await _loadContentFn(atomId);
      if (buffer.phase == BufferPhase.loading) {
        buffer.initialize(content);
      }
    } on AtomNotFoundException {
      // Atom no longer exists in DB — remove from all groups
      _removeAtomFromAllGroups(atomId);
    } catch (e) {
      if (buffer.phase == BufferPhase.loading) {
        buffer.markError(e.toString());
      }
    }
  }

  /// Removes an atom's tab from every group and cleans up the buffer.
  ///
  /// Used when loading reveals the atom no longer exists (T7).
  void _removeAtomFromAllGroups(String atomId) {
    final groupIds = _groups.keys.toList();
    for (final gid in groupIds) {
      final group = _groups[gid];
      if (group == null) continue;
      group.removeTab(atomId);
      if (group.isEmpty && _groups.length > 1) {
        _destroyGroup(gid);
      }
    }
    // Clean up the orphaned buffer
    final buffer = _buffers.remove(atomId);
    if (buffer != null) {
      buffer.removeListener(_onBufferChanged);
      buffer.dispose();
    }
    _scheduleLayoutSave();
    notifyListeners();
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
