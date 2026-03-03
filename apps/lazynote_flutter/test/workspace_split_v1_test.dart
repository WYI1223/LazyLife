import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_coordinator.dart';
import 'package:lazynote_flutter/features/notes/notes_page.dart';

rust_api.AtomListItem _note({
  required String atomId,
  required String content,
  required int updatedAt,
}) {
  return rust_api.AtomListItem(
    viewHint: 'note',
    title: '',
    contentType: 'markdown',
    atomId: atomId,
    content: content,
    previewText: content,
    previewImage: null,
    updatedAt: updatedAt,
    tags: const [],
  );
}

NotesCoordinator _buildController() {
  final store = <String, rust_api.AtomListItem>{
    'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 2),
    'note-2': _note(atomId: 'note-2', content: '# two', updatedAt: 1),
    'note-3': _note(atomId: 'note-3', content: '# three', updatedAt: 0),
  };
  return NotesCoordinator(
    prepare: () async {},
    notesListInvoker: ({tag, limit, offset}) async {
      return rust_api.AtomListResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
        appliedLimit: 50,
        items: [store['note-1']!, store['note-2']!, store['note-3']!],
      );
    },
    noteGetInvoker: ({required atomId}) async {
      return rust_api.AtomItemResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
        item: store[atomId],
      );
    },
  );
}

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('split commands are wired and show success feedback', (
    WidgetTester tester,
  ) async {
    final controller = _buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('notes_split_horizontal_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('notes_split_vertical_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();

    expect(controller.editorShellService.paneCount, 2);
    expect(find.text('Split created. 2 panes ready.'), findsOneWidget);
  });

  testWidgets('split rejects when min-size would be violated', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(620, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = _buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();

    expect(controller.editorShellService.paneCount, 1);
    expect(
      find.text('Cannot split: each pane must stay at least 200px.'),
      findsOneWidget,
    );
  });

  testWidgets('next pane command switches visible tab routing', (
    WidgetTester tester,
  ) async {
    final controller = _buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-2')), findsNothing);

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_list_item_note-2')));
    await tester.pump();
    await tester.pump();

    // Multi-pane: both panes' tabs are visible simultaneously.
    // Primary pane has note-1, secondary pane has note-2.
    expect(find.byKey(const Key('note_tab_note-2')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(controller.activeNoteId, 'note-2');

    controller.activateNextPane();
    await tester.pump();
    await tester.pump();

    // After switching: active pane is now primary with note-1.
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-2')), findsOneWidget);
    expect(controller.activeNoteId, 'note-1');
  });

  testWidgets('Ctrl+Tab stays pane-local in split mode', (
    WidgetTester tester,
  ) async {
    final controller = _buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    final initialGroupId = controller.editorShellService.activeGroupId;

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_list_item_note-2')));
    await tester.pump();
    await tester.pump();
    // Multi-pane: both panes' tabs visible simultaneously.
    expect(find.byKey(const Key('note_tab_note-2')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(controller.activeNoteId, 'note-2');

    controller.activateNextPane();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-2')), findsOneWidget);
    expect(controller.activeNoteId, 'note-1');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();

    // Why: Ctrl+Tab cycles within active pane only. Initial pane has only
    // note-1, so activeNoteId stays note-1. The other pane's note-2 is
    // unaffected.
    expect(controller.activeNoteId, 'note-1');
    expect(controller.editorShellService.activeGroupId, initialGroupId);
  });

  testWidgets('Ctrl+Shift+Tab stays pane-local in split mode', (
    WidgetTester tester,
  ) async {
    final controller = _buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    final editor = controller.editorShellService;
    final initialGroupId = editor.activeGroupId;

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_list_item_note-2')));
    await tester.pump();
    await tester.pump();
    expect(controller.activeNoteId, 'note-2');
    expect(editor.activeGroupId, isNot(initialGroupId));

    controller.activateNextPane();
    await tester.pump();
    await tester.pump();
    expect(editor.activeGroupId, initialGroupId);
    expect(controller.activeNoteId, 'note-1');

    await tester.tap(find.byKey(const Key('notes_list_item_note-3')));
    await tester.pump();
    await tester.pump();
    expect(controller.activeNoteId, 'note-3');
    expect(editor.activeGroupId, initialGroupId);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();

    // Why: reverse tab cycle stays within initial pane (note-1, note-3).
    // note-2 is in the other pane — Ctrl+Shift+Tab must not switch to it.
    expect(editor.activeGroupId, initialGroupId);
    expect(controller.activeNoteId, 'note-1');
    // note-2 tab is still visible in the other pane.
    expect(find.byKey(const Key('note_tab_note-2')), findsOneWidget);
  });
}
