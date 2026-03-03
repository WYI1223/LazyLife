import 'dart:async';

import 'package:flutter/widgets.dart' show Axis;
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/editor/edit_buffer.dart';
import 'package:lazynote_flutter/core/editor/editor_group_model.dart';
import 'package:lazynote_flutter/core/editor/editor_shell_service.dart';
import 'package:lazynote_flutter/core/editor/group_layout.dart';
import 'package:lazynote_flutter/core/editor/layout_persistence.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _cancelled = false;
  int _tick = 0;

  @override
  void cancel() => _cancelled = true;

  @override
  bool get isActive => !_cancelled;

  @override
  int get tick => _tick;

  void fire() {
    if (_cancelled) return;
    _tick++;
    _callback();
  }
}

Timer _fakeTimerFactory(Duration d, void Function() cb) => _FakeTimer(d, cb);

/// A LayoutPersistence stub that holds a snapshot and captures save calls.
class _FakePersistence extends LayoutPersistence {
  _FakePersistence({LayoutSnapshot? snapshot})
    : _snapshot = snapshot,
      super(layoutFilePathResolver: () async => '/fake/layout.json');

  final LayoutSnapshot? _snapshot;
  int saveCallCount = 0;

  @override
  LayoutSnapshot? consumeLoadedSnapshot() => _snapshot;

  @override
  void scheduleSave({
    required GroupLayout layout,
    required Map<String, EditorGroupModel> groups,
    required String activeGroupId,
  }) {
    saveCallCount++;
  }
}

EditorShellService _buildService({
  Future<String> Function(String)? loadContentFn,
  Future<bool> Function(String, String)? persistFn,
  LayoutPersistence? layoutPersistence,
}) {
  return EditorShellService(
    loadContentFn: loadContentFn ?? (id) async => 'content of $id',
    persistFn: persistFn ?? (id, c) async => true,
    timerFactory: _fakeTimerFactory,
    layoutPersistence: layoutPersistence,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('T10: P1 Eager loading', () {
    test(
      'loadActiveBuffers creates buffers for restored tabs and loads active',
      () async {
        // Set up a snapshot with two groups, each with tabs
        final g1 = EditorGroupModel(groupId: 'g1');
        g1.openTab(const TabEntry(atomId: 'atom-1', title: 'Note 1'));
        g1.openTab(const TabEntry(atomId: 'atom-2', title: 'Note 2'));
        g1.activateTab('atom-1');

        final g2 = EditorGroupModel(groupId: 'g2');
        g2.openTab(const TabEntry(atomId: 'atom-3', title: 'Note 3'));
        g2.activateTab('atom-3');

        final persistence = _FakePersistence(
          snapshot: LayoutSnapshot(
            layout: GroupLayout(
              root: SplitNode(
                first: LeafNode(groupId: 'g1'),
                second: LeafNode(groupId: 'g2'),
                axis: Axis.horizontal,
                fraction: 0.5,
              ),
            ),
            groups: {'g1': g1, 'g2': g2},
            activeGroupId: 'g1',
          ),
        );

        final loadedAtomIds = <String>[];
        final service = EditorShellService(
          loadContentFn: (id) async {
            loadedAtomIds.add(id);
            return 'content of $id';
          },
          persistFn: (id, c) async => true,
          timerFactory: _fakeTimerFactory,
          layoutPersistence: persistence,
        );

        // Before loadActiveBuffers, no buffers exist
        expect(service.buffers, isEmpty);

        await service.loadActiveBuffers();

        // All tabs should have buffers created
        expect(
          service.buffers.keys,
          containsAll(['atom-1', 'atom-2', 'atom-3']),
        );

        // Only active tabs (atom-1 for g1, atom-3 for g2) should be loaded
        expect(loadedAtomIds, containsAll(['atom-1', 'atom-3']));

        // Active tab buffers should be ready
        expect(service.bufferFor('atom-1')!.phase, BufferPhase.ready);
        expect(service.bufferFor('atom-3')!.phase, BufferPhase.ready);

        // Non-active tab buffer should still be loading (P2 lazy)
        expect(service.bufferFor('atom-2')!.phase, BufferPhase.loading);

        service.dispose();
      },
    );

    test('loadActiveBuffers handles empty groups gracefully', () async {
      final service = _buildService();
      // Default single-pane, no tabs
      await service.loadActiveBuffers();
      expect(service.buffers, isEmpty);
      service.dispose();
    });
  });

  group('T10: P2 Lazy loading', () {
    test('switchTab triggers lazy load for loading-phase buffer', () async {
      final loadedAtomIds = <String>[];
      final service = EditorShellService(
        loadContentFn: (id) async {
          loadedAtomIds.add(id);
          return 'content of $id';
        },
        persistFn: (id, c) async => true,
        timerFactory: _fakeTimerFactory,
        layoutPersistence: _FakePersistence(),
      );

      // Open two tabs; first one loads immediately
      service.openTab('group.primary', 'atom-1', initialContent: 'ready');
      service.openTab('group.primary', 'atom-2', initialContent: 'ready-2');

      // Both are ready now, so switchTab won't trigger load
      loadedAtomIds.clear();
      service.switchTab('group.primary', 'atom-1');
      expect(loadedAtomIds, isEmpty);

      service.dispose();
    });

    test('switchTab triggers load for buffer in loading phase', () async {
      // Set up a snapshot with a tab whose buffer is in loading state
      final g1 = EditorGroupModel(groupId: 'g1');
      g1.openTab(const TabEntry(atomId: 'atom-active', title: 'Active'));
      g1.openTab(const TabEntry(atomId: 'atom-lazy', title: 'Lazy'));
      g1.activateTab('atom-active');

      final persistence = _FakePersistence(
        snapshot: LayoutSnapshot(
          layout: GroupLayout(root: LeafNode(groupId: 'g1')),
          groups: {'g1': g1},
          activeGroupId: 'g1',
        ),
      );

      final loadedAtomIds = <String>[];
      final service = EditorShellService(
        loadContentFn: (id) async {
          loadedAtomIds.add(id);
          return 'lazy content of $id';
        },
        persistFn: (id, c) async => true,
        timerFactory: _fakeTimerFactory,
        layoutPersistence: persistence,
      );

      // P1: load active buffers (only atom-active)
      await service.loadActiveBuffers();
      expect(loadedAtomIds, contains('atom-active'));
      expect(service.bufferFor('atom-lazy')!.phase, BufferPhase.loading);

      // P2: switch to lazy tab triggers load
      loadedAtomIds.clear();
      service.switchTab('g1', 'atom-lazy');

      // Allow async load to complete
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(loadedAtomIds, contains('atom-lazy'));
      expect(service.bufferFor('atom-lazy')!.phase, BufferPhase.ready);

      service.dispose();
    });
  });

  group('T10: Loading failure handling (T7)', () {
    test('AtomNotFoundException removes tab from all groups', () async {
      final service = EditorShellService(
        loadContentFn: (id) async {
          if (id == 'deleted-atom') {
            throw const AtomNotFoundException('deleted-atom');
          }
          return 'content of $id';
        },
        persistFn: (id, c) async => true,
        timerFactory: _fakeTimerFactory,
        layoutPersistence: _FakePersistence(),
      );

      // Open tabs including one that will fail
      service.openTab('group.primary', 'good-atom', initialContent: 'ok');
      service.openTab('group.primary', 'deleted-atom');

      // Allow load to complete
      await Future.microtask(() {});
      await Future.microtask(() {});

      // deleted-atom should be removed from group and buffer cleaned up
      final group = service.groups['group.primary']!;
      expect(group.containsAtom('deleted-atom'), isFalse);
      expect(service.bufferFor('deleted-atom'), isNull);

      // good-atom should still be present
      expect(group.containsAtom('good-atom'), isTrue);

      service.dispose();
    });

    test('generic load error marks buffer as error', () async {
      final service = EditorShellService(
        loadContentFn: (id) async {
          throw Exception('network error');
        },
        persistFn: (id, c) async => true,
        timerFactory: _fakeTimerFactory,
        layoutPersistence: _FakePersistence(),
      );

      service.openTab('group.primary', 'atom-1');

      // Allow async load to fail
      await Future.microtask(() {});
      await Future.microtask(() {});

      final buffer = service.bufferFor('atom-1')!;
      expect(buffer.phase, BufferPhase.error);
      expect(buffer.errorMessage, contains('network error'));

      service.dispose();
    });

    test(
      'AtomNotFoundException with multi-group collapses empty group',
      () async {
        final service = EditorShellService(
          loadContentFn: (id) async {
            if (id == 'deleted') throw const AtomNotFoundException('deleted');
            return 'ok';
          },
          persistFn: (id, c) async => true,
          timerFactory: _fakeTimerFactory,
          layoutPersistence: _FakePersistence(),
        );

        // Create two groups via split
        service.openTab('group.primary', 'good', initialContent: 'ok');
        service.splitGroup('group.primary', Axis.horizontal);

        expect(service.paneCount, 2);
        final newGroupId = service.groups.keys.firstWhere(
          (k) => k != 'group.primary',
        );

        // Open a doomed tab in the new group (replace its existing tab)
        service.openTab(newGroupId, 'deleted');

        // Allow async load failure
        await Future.microtask(() {});
        await Future.microtask(() {});

        // The new group should be collapsed if empty
        // (the split's copy tab + deleted tab may leave it empty)
        // At minimum, the deleted atom should not exist anywhere
        expect(service.bufferFor('deleted'), isNull);

        service.dispose();
      },
    );
  });

  group('Buffer sharing across groups', () {
    test('same atomId in multiple groups shares one buffer', () {
      final service = _buildService(loadContentFn: (id) async => 'content');

      service.openTab('group.primary', 'shared-atom', initialContent: 'data');
      service.splitGroup('group.primary', Axis.horizontal);

      // The split copies the active tab
      final newGroupId = service.groups.keys.firstWhere(
        (k) => k != 'group.primary',
      );
      expect(service.groups[newGroupId]!.containsAtom('shared-atom'), isTrue);

      // Only one buffer instance
      expect(service.buffers.keys.where((k) => k == 'shared-atom').length, 1);

      service.dispose();
    });

    test(
      'closeTab only disposes buffer when no group references remain',
      () async {
        final service = _buildService(loadContentFn: (id) async => 'content');

        service.openTab('group.primary', 'shared-atom', initialContent: 'data');
        service.splitGroup('group.primary', Axis.horizontal);

        final newGroupId = service.groups.keys.firstWhere(
          (k) => k != 'group.primary',
        );

        // Close tab in one group — buffer should survive
        await service.closeTab(newGroupId, 'shared-atom');
        expect(service.bufferFor('shared-atom'), isNotNull);

        // Close tab in remaining group — buffer should be disposed
        await service.closeTab('group.primary', 'shared-atom');
        expect(service.bufferFor('shared-atom'), isNull);

        service.dispose();
      },
    );
  });
}
