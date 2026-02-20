import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_controller.dart';
import 'package:lazynote_flutter/features/workspace/workspace_models.dart';

rust_api.NoteItem _note({
  required String atomId,
  required String content,
  required int updatedAt,
}) {
  return rust_api.NoteItem(
    atomId: atomId,
    content: content,
    previewText: content,
    previewImage: null,
    updatedAt: updatedAt,
    tags: const [],
  );
}

NotesController _buildController({
  required Map<String, rust_api.NoteItem> store,
  Future<rust_api.NoteResponse> Function({required String atomId})?
  noteGetInvoker,
  Future<rust_api.NoteResponse> Function({
    required String atomId,
    required String content,
  })?
  noteUpdateInvoker,
}) {
  return NotesController(
    prepare: () async {},
    autosaveDebounce: const Duration(seconds: 30),
    notesListInvoker: ({tag, limit, offset}) async {
      final items = <rust_api.NoteItem>[];
      final orderedIds = store.keys.toList()..sort();
      for (final id in orderedIds) {
        if (store[id] case final item?) {
          items.add(item);
        }
      }
      return rust_api.NotesListResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
        appliedLimit: 50,
        items: items,
      );
    },
    noteGetInvoker:
        noteGetInvoker ??
        ({required atomId}) async {
          final found = store[atomId];
          return rust_api.NoteResponse(
            ok: found != null,
            errorCode: found == null ? 'note_not_found' : null,
            message: found == null ? 'missing' : 'ok',
            note: found,
          );
        },
    noteUpdateInvoker:
        noteUpdateInvoker ??
        ({required atomId, required content}) async {
          final current = store[atomId];
          if (current == null) {
            return const rust_api.NoteResponse(
              ok: false,
              errorCode: 'note_not_found',
              message: 'missing',
              note: null,
            );
          }
          final updated = _note(
            atomId: atomId,
            content: content,
            updatedAt: current.updatedAt + 1,
          );
          store[atomId] = updated;
          return rust_api.NoteResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            note: updated,
          );
        },
  );
}

List<String> _workspaceTabs(NotesController controller) {
  return controller.workspaceProvider.openTabsByPane[controller
          .workspaceProvider
          .activePaneId] ??
      const <String>[];
}

void main() {
  test('M2 bridge keeps workspace tabs and active note aligned', () async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 2),
      'note-2': _note(atomId: 'note-2', content: '# second', updatedAt: 1),
    };
    final controller = _buildController(store: store);
    addTearDown(controller.dispose);

    await controller.loadNotes();
    await controller.openNoteFromExplorer('note-2');

    expect(_workspaceTabs(controller), ['note-1', 'note-2']);
    expect(controller.workspaceProvider.activeNoteId, 'note-2');
  });

  test(
    'M2 bridge syncs active draft and save lifecycle to workspace',
    () async {
      final store = <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 2),
      };
      final controller = _buildController(store: store);
      addTearDown(controller.dispose);

      await controller.loadNotes();
      controller.updateActiveDraft('# first updated');

      expect(
        controller.workspaceProvider.activeDraftContent,
        '# first updated',
      );
      expect(
        controller.workspaceProvider.saveStateByNoteId['note-1'],
        WorkspaceSaveState.dirty,
      );

      final flushed = await controller.flushPendingSave();
      expect(flushed, isTrue);
      expect(
        controller.workspaceProvider.saveStateByNoteId['note-1'],
        WorkspaceSaveState.clean,
      );
    },
  );

  test(
    'M2 bridge removes workspace tab snapshot when note tab closes',
    () async {
      final store = <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 2),
        'note-2': _note(atomId: 'note-2', content: '# second', updatedAt: 1),
      };
      final controller = _buildController(store: store);
      addTearDown(controller.dispose);

      await controller.loadNotes();
      await controller.openNoteFromExplorer('note-2');
      expect(_workspaceTabs(controller), ['note-1', 'note-2']);

      final closed = await controller.closeOpenNote('note-2');
      expect(closed, isTrue);
      expect(_workspaceTabs(controller), ['note-1']);
      expect(controller.workspaceProvider.activeNoteId, 'note-1');
    },
  );

  test('M3 split keeps pane-local tab routing across pane switches', () async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 2),
      'note-2': _note(atomId: 'note-2', content: '# second', updatedAt: 1),
    };
    final controller = _buildController(store: store);
    addTearDown(controller.dispose);

    await controller.loadNotes();
    final primaryPane = controller.workspaceProvider.activePaneId;
    expect(controller.openNoteIds, ['note-1']);

    final splitResult = controller.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );
    expect(splitResult, WorkspaceSplitResult.ok);
    final splitPane = controller.workspaceProvider.activePaneId;
    expect(splitPane == primaryPane, isFalse);
    expect(controller.openNoteIds, isEmpty);

    await controller.openNoteFromExplorer('note-2');

    expect(controller.workspaceProvider.openTabsByPane[primaryPane], [
      'note-1',
    ]);
    expect(controller.workspaceProvider.openTabsByPane[splitPane], ['note-2']);
    expect(controller.activeNoteId, 'note-2');
    expect(controller.openNoteIds, ['note-2']);

    final switched = controller.switchActivePane(primaryPane);
    expect(switched, isTrue);
    expect(controller.activeNoteId, 'note-1');
    expect(controller.openNoteIds, ['note-1']);
  });

  test('M3 activateNextPane cycles active pane and active note', () async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 2),
      'note-2': _note(atomId: 'note-2', content: '# second', updatedAt: 1),
    };
    final controller = _buildController(store: store);
    addTearDown(controller.dispose);

    await controller.loadNotes();
    final primaryPane = controller.workspaceProvider.activePaneId;
    expect(
      controller.splitActivePane(
        direction: WorkspaceSplitDirection.horizontal,
        containerExtent: 1200,
      ),
      WorkspaceSplitResult.ok,
    );
    final splitPane = controller.workspaceProvider.activePaneId;
    await controller.openNoteFromExplorer('note-2');
    expect(controller.activeNoteId, 'note-2');
    expect(controller.workspaceProvider.activePaneId, splitPane);

    controller.activateNextPane();
    await Future<void>.delayed(Duration.zero);

    expect(controller.workspaceProvider.activePaneId, primaryPane);
    expect(controller.activeNoteId, 'note-1');
  });

  test(
    'R1 split select keeps workspace active aligned when detail load fails',
    () async {
      final store = <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 2),
        'note-2': _note(atomId: 'note-2', content: '# second', updatedAt: 1),
      };
      var note1Loads = 0;
      final controller = _buildController(
        store: store,
        noteGetInvoker: ({required atomId}) async {
          if (atomId == 'note-1') {
            note1Loads += 1;
            if (note1Loads >= 2) {
              return const rust_api.NoteResponse(
                ok: false,
                errorCode: 'db_error',
                message: 'detail failed',
                note: null,
              );
            }
          }
          final found = store[atomId];
          return rust_api.NoteResponse(
            ok: found != null,
            errorCode: found == null ? 'note_not_found' : null,
            message: found == null ? 'missing' : 'ok',
            note: found,
          );
        },
      );
      addTearDown(controller.dispose);

      await controller.loadNotes();
      final primaryPane = controller.workspaceProvider.activePaneId;
      expect(
        controller.splitActivePane(
          direction: WorkspaceSplitDirection.horizontal,
          containerExtent: 1200,
        ),
        WorkspaceSplitResult.ok,
      );
      final splitPane = controller.workspaceProvider.activePaneId;
      expect(splitPane, isNot(primaryPane));

      await controller.openNoteFromExplorer('note-2');
      expect(controller.activeNoteId, 'note-2');
      expect(controller.workspaceProvider.activeNoteId, 'note-2');

      final switched = await controller.openNoteFromExplorer('note-1');
      expect(switched, isTrue);
      expect(controller.activeNoteId, 'note-1');
      expect(controller.workspaceProvider.activePaneId, splitPane);
      expect(controller.workspaceProvider.activeNoteId, 'note-1');
      expect(controller.detailErrorMessage, contains('detail failed'));
    },
  );

  test('R2 Ctrl+Tab cycle is active-pane scoped in split mode', () async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 3),
      'note-2': _note(atomId: 'note-2', content: '# second', updatedAt: 2),
      'note-3': _note(atomId: 'note-3', content: '# third', updatedAt: 1),
    };
    final controller = _buildController(store: store);
    addTearDown(controller.dispose);

    await controller.loadNotes();
    final primaryPane = controller.workspaceProvider.activePaneId;
    expect(
      controller.splitActivePane(
        direction: WorkspaceSplitDirection.horizontal,
        containerExtent: 1200,
      ),
      WorkspaceSplitResult.ok,
    );
    final splitPane = controller.workspaceProvider.activePaneId;
    await controller.openNoteFromExplorer('note-2');
    controller.pinPreviewTab('note-2');

    final switched = controller.switchActivePane(primaryPane);
    expect(switched, isTrue);
    await controller.openNoteFromExplorer('note-3');
    expect(controller.workspaceProvider.activePaneId, primaryPane);
    expect(controller.activeNoteId, 'note-3');
    expect(controller.workspaceProvider.openTabsByPane[primaryPane], [
      'note-1',
      'note-3',
    ]);
    expect(controller.workspaceProvider.openTabsByPane[splitPane], ['note-2']);

    await controller.activateNextOpenNote();
    expect(controller.workspaceProvider.activePaneId, primaryPane);
    expect(controller.activeNoteId, 'note-1');
    expect(controller.workspaceProvider.openTabsByPane[splitPane], ['note-2']);

    await controller.activatePreviousOpenNote();
    expect(controller.workspaceProvider.activePaneId, primaryPane);
    expect(controller.activeNoteId, 'note-3');
  });

  test('M1 closeActivePane merges split tabs and keeps active note', () async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 3),
      'note-2': _note(atomId: 'note-2', content: '# second', updatedAt: 2),
      'note-3': _note(atomId: 'note-3', content: '# third', updatedAt: 1),
    };
    final controller = _buildController(store: store);
    addTearDown(controller.dispose);

    await controller.loadNotes();
    final primaryPane = controller.workspaceProvider.activePaneId;
    expect(
      controller.splitActivePane(
        direction: WorkspaceSplitDirection.horizontal,
        containerExtent: 1200,
      ),
      WorkspaceSplitResult.ok,
    );
    final splitPane = controller.workspaceProvider.activePaneId;
    await controller.openNoteFromExplorer('note-2');
    controller.pinPreviewTab('note-2');
    await controller.openNoteFromExplorer('note-3');
    expect(controller.workspaceProvider.activePaneId, splitPane);
    expect(controller.activeNoteId, 'note-3');

    final merged = controller.closeActivePane();

    expect(merged, WorkspaceMergeResult.ok);
    expect(controller.workspaceProvider.layoutState.paneOrder, [primaryPane]);
    expect(controller.workspaceProvider.activePaneId, primaryPane);
    expect(controller.activeNoteId, 'note-3');
    expect(controller.openNoteIds, ['note-1', 'note-2', 'note-3']);
    expect(
      controller.workspaceProvider.openTabsByPane.containsKey(splitPane),
      isFalse,
    );
  });

  test('M1 closeActivePane is blocked on single-pane layout', () async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# first', updatedAt: 2),
    };
    final controller = _buildController(store: store);
    addTearDown(controller.dispose);

    await controller.loadNotes();
    final merged = controller.closeActivePane();

    expect(merged, WorkspaceMergeResult.singlePaneBlocked);
    expect(controller.workspaceProvider.layoutState.paneOrder.length, 1);
    expect(controller.activeNoteId, 'note-1');
  });
}
