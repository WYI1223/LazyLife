import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_controller.dart';

rust_api.NoteItem _note({
  required String atomId,
  required String content,
  required int updatedAt,
  String? previewText,
}) {
  return rust_api.NoteItem(
    atomId: atomId,
    content: content,
    previewText: previewText,
    previewImage: null,
    updatedAt: updatedAt,
    tags: const [],
  );
}

void main() {
  NotesController buildController() {
    return NotesController(
      prepare: () async {},
      notesListInvoker: ({tag, limit, offset}) async {
        return rust_api.NotesListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          appliedLimit: 50,
          items: [
            _note(
              atomId: 'note-1',
              content: '# first',
              previewText: 'first',
              updatedAt: 2,
            ),
            _note(
              atomId: 'note-2',
              content: '# second',
              previewText: 'second',
              updatedAt: 1,
            ),
          ],
        );
      },
      noteGetInvoker: ({required atomId}) async {
        return rust_api.NoteResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          note: _note(
            atomId: atomId,
            content: '# $atomId',
            previewText: atomId,
            updatedAt: 3,
          ),
        );
      },
    );
  }

  test('load initializes first tab as active', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await controller.loadNotes();

    expect(controller.openNoteIds, ['note-1']);
    expect(controller.activeNoteId, 'note-1');
  });

  test('open from explorer appends tab and activates target', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await controller.loadNotes();
    await controller.openNoteFromExplorer('note-2');

    expect(controller.openNoteIds, ['note-1', 'note-2']);
    expect(controller.activeNoteId, 'note-2');
  });

  test('tab close helpers keep deterministic active tab', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await controller.loadNotes();
    await controller.openNoteFromExplorer('note-2');
    await controller.activatePreviousOpenNote();
    expect(controller.activeNoteId, 'note-1');

    await controller.closeOpenNotesToRight('note-1');
    expect(controller.openNoteIds, ['note-1']);
    expect(controller.activeNoteId, 'note-1');

    await controller.closeOpenNote('note-1');
    expect(controller.openNoteIds, isEmpty);
    expect(controller.activeNoteId, isNull);
  });
}
