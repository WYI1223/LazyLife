import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_controller.dart';

rust_api.NoteItem _note({
  required String atomId,
  required String content,
  required int updatedAt,
}) {
  return rust_api.NoteItem(
    atomId: atomId,
    content: content,
    previewText: null,
    previewImage: null,
    updatedAt: updatedAt,
    tags: const [],
  );
}

NotesController _buildController({
  required Map<String, rust_api.NoteItem> store,
  WorkspaceCreateFolderInvoker? workspaceCreateFolderInvoker,
  WorkspaceListChildrenInvoker? workspaceListChildrenInvoker,
}) {
  return NotesController(
    prepare: () async {},
    notesListInvoker: ({tag, limit, offset}) async {
      return rust_api.NotesListResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
        appliedLimit: 50,
        items: store.values.toList(growable: false),
      );
    },
    noteGetInvoker: ({required atomId}) async {
      return rust_api.NoteResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
        note: store[atomId],
      );
    },
    workspaceCreateFolderInvoker: workspaceCreateFolderInvoker,
    workspaceListChildrenInvoker: workspaceListChildrenInvoker,
  );
}

void main() {
  test(
    'createWorkspaceFolder returns busy while previous create is in flight',
    () async {
      final completer = Completer<rust_api.WorkspaceNodeResponse>();
      var createCalls = 0;
      final controller = _buildController(
        store: <String, rust_api.NoteItem>{
          'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
        },
        workspaceCreateFolderInvoker: ({parentNodeId, required name}) {
          createCalls += 1;
          return completer.future;
        },
      );
      addTearDown(controller.dispose);

      final first = controller.createWorkspaceFolder(name: 'Inbox');
      final second = await controller.createWorkspaceFolder(name: 'Team');

      expect(second.ok, isFalse);
      expect(second.errorCode, 'busy');
      expect(createCalls, 1);

      completer.complete(
        const rust_api.WorkspaceNodeResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          node: null,
        ),
      );
      final firstResponse = await first;
      expect(firstResponse.ok, isTrue);
    },
  );

  test(
    'createWorkspaceFolder rejects non-UUID parent id before FFI call',
    () async {
      var createCalls = 0;
      final controller = _buildController(
        store: <String, rust_api.NoteItem>{
          'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
        },
        workspaceCreateFolderInvoker: ({parentNodeId, required name}) async {
          createCalls += 1;
          return const rust_api.WorkspaceNodeResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            node: null,
          );
        },
      );
      addTearDown(controller.dispose);

      final response = await controller.createWorkspaceFolder(
        name: 'Team',
        parentNodeId: 'not-a-uuid',
      );

      expect(response.ok, isFalse);
      expect(response.errorCode, 'invalid_parent_node_id');
      expect(createCalls, 0);
    },
  );

  test('listWorkspaceChildren intercepts __uncategorized__ locally', () async {
    var listCalls = 0;
    final controller = _buildController(
      store: <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
      },
      workspaceListChildrenInvoker: ({parentNodeId}) async {
        listCalls += 1;
        throw StateError('should not be called for __uncategorized__');
      },
    );
    addTearDown(controller.dispose);
    await controller.loadNotes();

    final response = await controller.listWorkspaceChildren(
      parentNodeId: '__uncategorized__',
    );

    expect(response.ok, isTrue);
    expect(response.errorCode, isNull);
    expect(listCalls, 0);
    expect(response.items, isNotEmpty);
    expect(response.items.first.parentNodeId, '__uncategorized__');
  });

  test(
    'listWorkspaceChildren returns explicit error envelope on bridge exception',
    () async {
      final controller = _buildController(
        store: <String, rust_api.NoteItem>{
          'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
        },
        workspaceListChildrenInvoker: ({parentNodeId}) async {
          throw StateError('bridge boom');
        },
      );
      addTearDown(controller.dispose);

      final response = await controller.listWorkspaceChildren(
        parentNodeId: null,
      );

      expect(response.ok, isFalse);
      expect(response.errorCode, 'internal_error');
      expect(response.message, contains('bridge boom'));
      expect(response.items, isEmpty);
    },
  );
}
