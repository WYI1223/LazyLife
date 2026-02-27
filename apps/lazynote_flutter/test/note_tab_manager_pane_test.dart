import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tab_manager.dart';

NoteTabStateManager _buildManager({
  String initialPaneId = 'pane-1',
  String? activeNoteId,
  bool Function(String)? canReuseSelection,
}) {
  String? currentActiveNoteId = activeNoteId;
  return NoteTabStateManager(
    initialPaneId: initialPaneId,
    canReuseSelection: canReuseSelection ?? (_) => false,
    activeNoteId: () => currentActiveNoteId,
    activateSelection: (atomId) => currentActiveNoteId = atomId,
    clearSelection: () => currentActiveNoteId = null,
    loadSelectedDetail: (_) async {},
    flushPendingSave: () async => true,
    hasPendingSaveFor: (_) => false,
    evictNoteState: (_) {},
    scopedOpenNoteIds: () => <String>[],
    scopedActiveNoteId: () => currentActiveNoteId,
  );
}

void main() {
  group('NoteTabStateManager pane-scoped operations', () {
    test('initial state has one pane with empty tab list', () {
      final m = _buildManager();
      expect(m.activePaneId, 'pane-1');
      expect(m.openNoteIds, isEmpty);
      expect(m.openNoteIdsForPane('pane-1'), isEmpty);
    });

    test('addPane creates a new empty pane', () {
      final m = _buildManager();
      m.addPane('pane-2');
      expect(m.openNoteIdsForPane('pane-2'), isEmpty);
      // Active pane unchanged
      expect(m.activePaneId, 'pane-1');
    });

    test('addPane is idempotent for existing pane', () {
      final m = _buildManager();
      m.addOpenNoteIfAbsent('note-a');
      m.addPane('pane-1'); // already exists
      expect(m.openNoteIdsForPane('pane-1'), ['note-a']);
    });

    test('switchPane changes active pane', () {
      final m = _buildManager();
      m.addPane('pane-2');
      m.switchPane('pane-2');
      expect(m.activePaneId, 'pane-2');
    });

    test('switchPane ignores unknown pane id', () {
      final m = _buildManager();
      m.switchPane('unknown');
      expect(m.activePaneId, 'pane-1');
    });

    test('tab operations are pane-scoped', () {
      final m = _buildManager();
      m.addOpenNoteIfAbsent('note-a');
      m.addOpenNoteIfAbsent('note-b');

      m.addPane('pane-2');
      m.switchPane('pane-2');
      m.addOpenNoteIfAbsent('note-c');

      // Pane-1 has note-a, note-b
      expect(m.openNoteIdsForPane('pane-1'), ['note-a', 'note-b']);
      // Pane-2 has note-c
      expect(m.openNoteIdsForPane('pane-2'), ['note-c']);
      // openNoteIds returns active pane (pane-2)
      expect(m.openNoteIds, ['note-c']);
      expect(m.openNoteCount, 1);
    });

    test('containsOpenNote checks all panes', () {
      final m = _buildManager();
      m.addOpenNoteIfAbsent('note-a');
      m.addPane('pane-2');
      m.switchPane('pane-2');
      m.addOpenNoteIfAbsent('note-b');

      // Both should be found regardless of active pane
      expect(m.containsOpenNote('note-a'), isTrue);
      expect(m.containsOpenNote('note-b'), isTrue);
      expect(m.containsOpenNote('note-c'), isFalse);
    });

    test('addNoteToPane adds to specific pane without switching', () {
      final m = _buildManager();
      m.addPane('pane-2');
      m.addNoteToPane('pane-2', 'note-x');

      expect(m.activePaneId, 'pane-1');
      expect(m.openNoteIdsForPane('pane-1'), isEmpty);
      expect(m.openNoteIdsForPane('pane-2'), ['note-x']);
    });

    test('addNoteToPane is idempotent for duplicate', () {
      final m = _buildManager();
      m.addNoteToPane('pane-1', 'note-a');
      m.addNoteToPane('pane-1', 'note-a');
      expect(m.openNoteIdsForPane('pane-1'), ['note-a']);
    });

    test('removeNoteFromPane removes from specific pane', () {
      final m = _buildManager();
      m.addOpenNoteIfAbsent('note-a');
      m.addOpenNoteIfAbsent('note-b');
      m.removeNoteFromPane('pane-1', 'note-a');
      expect(m.openNoteIdsForPane('pane-1'), ['note-b']);
    });

    test('removePane merges tabs to target pane', () {
      final m = _buildManager();
      m.addOpenNoteIfAbsent('note-a');
      m.addPane('pane-2');
      m.switchPane('pane-2');
      m.addOpenNoteIfAbsent('note-b');
      m.addOpenNoteIfAbsent('note-c');

      // Remove pane-2, merge into pane-1
      m.removePane('pane-2', mergeToPaneId: 'pane-1');

      expect(m.openNoteIdsForPane('pane-1'), ['note-a', 'note-b', 'note-c']);
      expect(m.openNoteIdsForPane('pane-2'), isEmpty);
      // Active pane falls back to merge target
      expect(m.activePaneId, 'pane-1');
    });

    test('removePane deduplicates merged tabs', () {
      final m = _buildManager();
      m.addOpenNoteIfAbsent('note-a');
      m.addPane('pane-2');
      m.addNoteToPane('pane-2', 'note-a'); // duplicate
      m.addNoteToPane('pane-2', 'note-b');

      m.removePane('pane-2', mergeToPaneId: 'pane-1');
      expect(m.openNoteIdsForPane('pane-1'), ['note-a', 'note-b']);
    });

    test('removePane preserves active pane when removing non-active', () {
      final m = _buildManager();
      m.addPane('pane-2');
      m.addPane('pane-3');
      m.switchPane('pane-3');

      m.removePane('pane-2', mergeToPaneId: 'pane-1');
      expect(m.activePaneId, 'pane-3');
    });

    test('clearOpenNotes only clears active pane', () {
      final m = _buildManager();
      m.addOpenNoteIfAbsent('note-a');
      m.addPane('pane-2');
      m.addNoteToPane('pane-2', 'note-b');

      m.clearOpenNotes();
      expect(m.openNoteIdsForPane('pane-1'), isEmpty);
      expect(m.openNoteIdsForPane('pane-2'), ['note-b']);
    });

    test(
      'allOpenNoteIds deduplicates across panes preserving first-seen order',
      () {
        final m = _buildManager();
        m.addOpenNoteIfAbsent('note-a');
        m.addOpenNoteIfAbsent('note-b');

        m.addPane('pane-2');
        m.addNoteToPane('pane-2', 'note-b'); // duplicate
        m.addNoteToPane('pane-2', 'note-c');

        final all = m.allOpenNoteIds;
        expect(all, ['note-a', 'note-b', 'note-c']);
        // note-b appears only once, in pane-1 order position
      },
    );

    test(
      'removeOpenNotesWhereAllPanes removes matching notes from every pane',
      () {
        final m = _buildManager();
        m.addOpenNoteIfAbsent('note-a');
        m.addOpenNoteIfAbsent('note-b');

        m.addPane('pane-2');
        m.addNoteToPane('pane-2', 'note-b');
        m.addNoteToPane('pane-2', 'note-c');

        m.removeOpenNotesWhereAllPanes((id) => id == 'note-b');

        expect(m.openNoteIdsForPane('pane-1'), ['note-a']);
        expect(m.openNoteIdsForPane('pane-2'), ['note-c']);
        expect(m.containsOpenNote('note-b'), isFalse);
      },
    );
  });
}
