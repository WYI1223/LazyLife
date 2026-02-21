import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/note_explorer.dart';
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

rust_api.WorkspaceNodeItem _node({
  required String nodeId,
  required String kind,
  required String displayName,
  String? parentNodeId,
  String? atomId,
  int sortOrder = 0,
}) {
  return rust_api.WorkspaceNodeItem(
    nodeId: nodeId,
    kind: kind,
    parentNodeId: parentNodeId,
    atomId: atomId,
    displayName: displayName,
    sortOrder: sortOrder,
  );
}

rust_api.WorkspaceListChildrenResponse _ok(
  List<rust_api.WorkspaceNodeItem> items,
) {
  return rust_api.WorkspaceListChildrenResponse(
    ok: true,
    errorCode: null,
    message: 'ok',
    items: items,
  );
}

NotesController _controller({
  required Map<String, rust_api.NoteItem> store,
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
    workspaceListChildrenInvoker: workspaceListChildrenInvoker,
  );
}

Widget _harness({
  required NotesController controller,
  ExplorerFolderCreateInvoker? onCreateFolderRequested,
  ExplorerNoteCreateInFolderInvoker? onCreateNoteInFolderRequested,
  ExplorerNodeRenameInvoker? onRenameNodeRequested,
  ExplorerNodeMoveInvoker? onMoveNodeRequested,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return NoteExplorer(
            controller: controller,
            onOpenNoteRequested: (_) {},
            onCreateNoteRequested: () async {},
            onCreateFolderRequested: onCreateFolderRequested,
            onCreateNoteInFolderRequested: onCreateNoteInFolderRequested,
            onRenameNodeRequested: onRenameNodeRequested,
            onMoveNodeRequested: onMoveNodeRequested,
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets(
    'synthetic uncategorized context menu exposes create-only actions',
    (tester) async {
      final controller = _controller(
        store: <String, rust_api.NoteItem>{
          'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
        },
        workspaceListChildrenInvoker: ({parentNodeId}) async {
          return _ok(const <rust_api.WorkspaceNodeItem>[]);
        },
      );
      addTearDown(controller.dispose);
      await controller.loadNotes();

      await tester.pumpWidget(
        _harness(
          controller: controller,
          onCreateFolderRequested: (name, parentNodeId) async {
            return const rust_api.WorkspaceNodeResponse(
              ok: true,
              errorCode: null,
              message: 'ok',
              node: null,
            );
          },
          onCreateNoteInFolderRequested: (parentNodeId) async {
            return const rust_api.WorkspaceActionResponse(
              ok: true,
              errorCode: null,
              message: 'ok',
            );
          },
          onRenameNodeRequested: (nodeId, newName) async {
            return const rust_api.WorkspaceActionResponse(
              ok: true,
              errorCode: null,
              message: 'ok',
            );
          },
          onMoveNodeRequested: (nodeId, parentNodeId, {targetOrder}) async {
            return const rust_api.WorkspaceActionResponse(
              ok: true,
              errorCode: null,
              message: 'ok',
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('notes_tree_folder___uncategorized__')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('notes_context_action_newNote')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('notes_context_action_newFolder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('notes_context_action_rename')),
        findsNothing,
      );
      expect(find.byKey(const Key('notes_context_action_move')), findsNothing);
      expect(
        find.byKey(const Key('notes_context_action_deleteFolder')),
        findsNothing,
      );
    },
  );

  testWidgets('create folder from uncategorized context maps parent to root', (
    tester,
  ) async {
    final createdParents = <String?>[];
    final controller = _controller(
      store: <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
      },
      workspaceListChildrenInvoker: ({parentNodeId}) async {
        return _ok(const <rust_api.WorkspaceNodeItem>[]);
      },
    );
    addTearDown(controller.dispose);
    await controller.loadNotes();

    await tester.pumpWidget(
      _harness(
        controller: controller,
        onCreateFolderRequested: (name, parentNodeId) async {
          createdParents.add(parentNodeId);
          return const rust_api.WorkspaceNodeResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            node: null,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('notes_tree_folder___uncategorized__')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes_context_action_newFolder')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('notes_create_folder_name_input')),
      'Inbox',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('notes_create_folder_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(createdParents, const <String?>[null]);
  });

  testWidgets('note row context hides rename under v0.2 policy freeze', (
    tester,
  ) async {
    final controller = _controller(
      store: <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
      },
      workspaceListChildrenInvoker: ({parentNodeId}) async {
        if (parentNodeId != null) {
          return _ok(const <rust_api.WorkspaceNodeItem>[]);
        }
        return _ok(<rust_api.WorkspaceNodeItem>[
          _node(
            nodeId: '11111111-1111-4111-8111-111111111111',
            kind: 'note_ref',
            atomId: 'note-1',
            displayName: 'Note One',
          ),
        ]);
      },
    );
    addTearDown(controller.dispose);
    await controller.loadNotes();

    await tester.pumpWidget(
      _harness(
        controller: controller,
        onRenameNodeRequested: (nodeId, newName) async {
          return const rust_api.WorkspaceActionResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const Key('notes_tree_note_row_11111111-1111-4111-8111-111111111111'),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notes_context_action_rename')), findsNothing);
  });

  testWidgets('folder context move forwards selected target parent', (
    tester,
  ) async {
    final moveCalls = <String>[];
    final controller = _controller(
      store: <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
      },
      workspaceListChildrenInvoker: ({parentNodeId}) async {
        if (parentNodeId != null) {
          return _ok(const <rust_api.WorkspaceNodeItem>[]);
        }
        return _ok(<rust_api.WorkspaceNodeItem>[
          _node(
            nodeId: '11111111-1111-4111-8111-111111111111',
            kind: 'folder',
            displayName: 'Folder A',
          ),
          _node(
            nodeId: '22222222-2222-4222-8222-222222222222',
            kind: 'folder',
            displayName: 'Folder B',
          ),
        ]);
      },
    );
    addTearDown(controller.dispose);
    await controller.loadNotes();

    await tester.pumpWidget(
      _harness(
        controller: controller,
        onMoveNodeRequested: (nodeId, parentNodeId, {targetOrder}) async {
          moveCalls.add('$nodeId::$parentNodeId::$targetOrder');
          return const rust_api.WorkspaceActionResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const Key('notes_tree_folder_11111111-1111-4111-8111-111111111111'),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes_context_action_move')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes_move_node_target_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folder B').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notes_move_node_confirm_button')));
    await tester.pumpAndSettle();

    expect(moveCalls, const <String>[
      '11111111-1111-4111-8111-111111111111::22222222-2222-4222-8222-222222222222::null',
    ]);
  });

  testWidgets('folder context menu responds on toggle-icon secondary click', (
    tester,
  ) async {
    const folderId = '11111111-1111-4111-8111-111111111111';
    final controller = _controller(
      store: <String, rust_api.NoteItem>{
        'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 1),
      },
      workspaceListChildrenInvoker: ({parentNodeId}) async {
        if (parentNodeId != null) {
          return _ok(const <rust_api.WorkspaceNodeItem>[]);
        }
        return _ok(<rust_api.WorkspaceNodeItem>[
          _node(nodeId: folderId, kind: 'folder', displayName: 'Folder A'),
        ]);
      },
    );
    addTearDown(controller.dispose);
    await controller.loadNotes();

    await tester.pumpWidget(
      _harness(
        controller: controller,
        onCreateNoteInFolderRequested: (parentNodeId) async {
          return const rust_api.WorkspaceActionResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('notes_tree_toggle_$folderId')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('notes_context_action_newNote')),
      findsOneWidget,
    );
  });
}
