import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_controller.dart';
import 'package:lazynote_flutter/features/notes/notes_page.dart';
import 'package:lazynote_flutter/features/workspace/workspace_provider.dart';

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
  required WorkspaceProvider workspaceProvider,
}) {
  final store = <String, rust_api.NoteItem>{
    'note-1': _note(atomId: 'note-1', content: '# one', updatedAt: 2),
    'note-2': _note(atomId: 'note-2', content: '# two', updatedAt: 1),
  };
  return NotesController(
    workspaceProvider: workspaceProvider,
    prepare: () async {},
    notesListInvoker: ({tag, limit, offset}) async {
      return rust_api.NotesListResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
        appliedLimit: 50,
        items: [store['note-1']!, store['note-2']!],
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

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('split commands are wired and show success feedback', (
    WidgetTester tester,
  ) async {
    final workspaceProvider = WorkspaceProvider();
    final controller = _buildController(workspaceProvider: workspaceProvider);
    addTearDown(controller.dispose);
    addTearDown(workspaceProvider.dispose);

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

    expect(workspaceProvider.layoutState.paneOrder.length, 2);
    expect(find.text('Split created. 2 panes ready.'), findsOneWidget);
  });

  testWidgets('split rejects mixed direction with explicit feedback', (
    WidgetTester tester,
  ) async {
    final workspaceProvider = WorkspaceProvider();
    final controller = _buildController(workspaceProvider: workspaceProvider);
    addTearDown(controller.dispose);
    addTearDown(workspaceProvider.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();
    expect(workspaceProvider.layoutState.paneOrder.length, 2);

    await tester.tap(find.byKey(const Key('notes_split_vertical_button')));
    await tester.pump();

    expect(workspaceProvider.layoutState.paneOrder.length, 2);
    expect(
      find.text('Cannot split: v0.2 keeps one split direction per workspace.'),
      findsOneWidget,
    );
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

    final workspaceProvider = WorkspaceProvider();
    final controller = _buildController(workspaceProvider: workspaceProvider);
    addTearDown(controller.dispose);
    addTearDown(workspaceProvider.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();

    expect(workspaceProvider.layoutState.paneOrder.length, 1);
    expect(
      find.text('Cannot split: each pane must stay at least 200px.'),
      findsOneWidget,
    );
  });

  testWidgets('next pane command switches visible tab routing', (
    WidgetTester tester,
  ) async {
    final workspaceProvider = WorkspaceProvider();
    final controller = _buildController(workspaceProvider: workspaceProvider);
    addTearDown(controller.dispose);
    addTearDown(workspaceProvider.dispose);

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

    expect(find.byKey(const Key('note_tab_note-2')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-1')), findsNothing);

    await tester.tap(find.byKey(const Key('notes_next_pane_button')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-2')), findsNothing);
  });

  testWidgets('next pane command on single-pane shows no-op feedback', (
    WidgetTester tester,
  ) async {
    final workspaceProvider = WorkspaceProvider();
    final controller = _buildController(workspaceProvider: workspaceProvider);
    addTearDown(controller.dispose);
    addTearDown(workspaceProvider.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    expect(workspaceProvider.layoutState.paneOrder.length, 1);
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notes_next_pane_button')));
    await tester.pump();

    expect(find.text('Only one pane is available.'), findsOneWidget);
    expect(workspaceProvider.layoutState.paneOrder.length, 1);
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
  });

  testWidgets('Ctrl+Tab stays pane-local in split mode', (
    WidgetTester tester,
  ) async {
    final workspaceProvider = WorkspaceProvider();
    final controller = _buildController(workspaceProvider: workspaceProvider);
    addTearDown(controller.dispose);
    addTearDown(workspaceProvider.dispose);

    await tester.pumpWidget(
      _wrapWithMaterial(NotesPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_split_horizontal_button')));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('notes_list_item_note-2')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('note_tab_note-2')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-1')), findsNothing);

    await tester.tap(find.byKey(const Key('notes_next_pane_button')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-2')), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();

    // Why: split mode tab strip is active-pane scoped; Ctrl+Tab must not pull
    // tabs from non-active panes.
    expect(find.byKey(const Key('note_tab_note-1')), findsOneWidget);
    expect(find.byKey(const Key('note_tab_note-2')), findsNothing);
  });
}
