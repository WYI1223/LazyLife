import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/note_tab_manager.dart';
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

NotesController _buildController(Map<String, rust_api.NoteItem> store) {
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
  );
}

void main() {
  testWidgets('single tap on preview tab keeps preview state', (
    WidgetTester tester,
  ) async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 2),
      'note-2': _note(atomId: 'note-2', content: '# two', updatedAt: 1),
    };
    final controller = _buildController(store);
    addTearDown(controller.dispose);
    await controller.loadNotes();
    await controller.openNoteFromExplorer('note-2');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => NoteTabManager(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('note_tab_preview_indicator_note-2')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('note_tab_note-2')));
    await tester.pumpAndSettle();

    expect(controller.previewTabId, 'note-2');
    expect(
      find.byKey(const Key('note_tab_preview_indicator_note-2')),
      findsOneWidget,
    );
  });

  testWidgets('double tap on preview tab pins tab and removes preview marker', (
    WidgetTester tester,
  ) async {
    final store = <String, rust_api.NoteItem>{
      'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 2),
      'note-2': _note(atomId: 'note-2', content: '# two', updatedAt: 1),
    };
    final controller = _buildController(store);
    addTearDown(controller.dispose);
    await controller.loadNotes();
    await controller.openNoteFromExplorer('note-2');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => NoteTabManager(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.previewTabId, 'note-2');
    final tabFinder = find.byKey(const Key('note_tab_note-2'));
    await tester.tap(tabFinder);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();

    expect(controller.previewTabId, isNull);
    expect(
      find.byKey(const Key('note_tab_preview_indicator_note-2')),
      findsNothing,
    );
  });
}
