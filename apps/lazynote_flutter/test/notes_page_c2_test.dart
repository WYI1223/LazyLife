import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_controller.dart';
import 'package:lazynote_flutter/features/notes/notes_page.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  rust_api.NoteItem note({
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

  testWidgets('C2 create auto-selects note and focuses editor', (
    WidgetTester tester,
  ) async {
    final noteStore = <String, rust_api.NoteItem>{
      'note-1': note(atomId: 'note-1', content: '# Existing', updatedAt: 1000),
    };

    final controller = NotesController(
      prepare: () async {},
      notesListInvoker: ({tag, limit, offset}) async {
        return rust_api.NotesListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          appliedLimit: 50,
          items: [noteStore['note-1']!],
        );
      },
      noteCreateInvoker: ({required content}) async {
        final created = note(
          atomId: 'note-new',
          content: content,
          updatedAt: 2000,
        );
        noteStore[created.atomId] = created;
        return rust_api.NoteResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          note: created,
        );
      },
      noteGetInvoker: ({required atomId}) async {
        final found = noteStore[atomId];
        return rust_api.NoteResponse(
          ok: found != null,
          errorCode: found == null ? 'note_not_found' : null,
          message: found == null ? 'missing' : 'ok',
          note: found,
        );
      },
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_create_button')));
    await tester.pump();
    await tester.pump();

    expect(controller.activeNoteId, 'note-new');
    expect(find.byKey(const Key('note_tab_note-new')), findsOneWidget);
    expect(find.byKey(const Key('note_editor_field')), findsOneWidget);

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, '');
    expect(editable.focusNode.hasFocus, true);
  });

  testWidgets('C2 selecting list item updates editor content', (
    WidgetTester tester,
  ) async {
    final noteStore = <String, rust_api.NoteItem>{
      'note-1': note(atomId: 'note-1', content: '# First', updatedAt: 2000),
      'note-2': note(atomId: 'note-2', content: '# Second', updatedAt: 1000),
    };

    final controller = NotesController(
      prepare: () async {},
      notesListInvoker: ({tag, limit, offset}) async {
        return rust_api.NotesListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          appliedLimit: 50,
          items: [noteStore['note-1']!, noteStore['note-2']!],
        );
      },
      noteGetInvoker: ({required atomId}) async {
        return rust_api.NoteResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          note: noteStore[atomId],
        );
      },
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_list_item_note-2')));
    await tester.pump();
    await tester.pump();

    expect(controller.activeNoteId, 'note-2');
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, '# Second');
  });

  testWidgets('C2 detail error renders centered and retry can recover', (
    WidgetTester tester,
  ) async {
    var detailCallCount = 0;
    final stableNote = note(
      atomId: 'note-1',
      content: '# Recover',
      updatedAt: 1,
    );

    final controller = NotesController(
      prepare: () async {},
      notesListInvoker: ({tag, limit, offset}) async {
        return rust_api.NotesListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          appliedLimit: 50,
          items: [stableNote],
        );
      },
      noteGetInvoker: ({required atomId}) async {
        detailCallCount += 1;
        if (detailCallCount == 1) {
          return const rust_api.NoteResponse(
            ok: false,
            errorCode: 'db_error',
            message: 'detail failed',
            note: null,
          );
        }
        return rust_api.NoteResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          note: stableNote,
        );
      },
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('notes_detail_error_center')), findsOneWidget);
    expect(find.byKey(const Key('notes_detail_retry_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notes_detail_retry_button')));
    await tester.pump();
    await tester.pump();

    expect(detailCallCount, 2);
    expect(find.byKey(const Key('notes_detail_error_center')), findsNothing);
    expect(find.byKey(const Key('note_editor_field')), findsOneWidget);
  });
}
