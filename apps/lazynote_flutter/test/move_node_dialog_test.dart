import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/notes/dialogs/move_node_dialog.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required MoveNodeDialogConfirm onConfirm,
    required MoveNodeDialogCancel onCancel,
  }) async {
    await tester.pumpWidget(
      wrapWithMaterial(
        Builder(
          builder: (context) => FilledButton(
            key: const Key('open_move_node_dialog'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return MoveNodeDialog(
                    options: const <MoveNodeDialogOption>[
                      MoveNodeDialogOption(nodeId: '__root__', label: 'Root'),
                      MoveNodeDialogOption(
                        nodeId: 'folder-a',
                        label: 'Folder A',
                      ),
                      MoveNodeDialogOption(
                        nodeId: 'folder-b',
                        label: 'Folder B',
                      ),
                    ],
                    initialTargetId: '__root__',
                    onConfirm: (targetNodeId) {
                      onConfirm(targetNodeId);
                      Navigator.of(dialogContext).pop();
                    },
                    onCancel: () {
                      onCancel();
                      Navigator.of(dialogContext).pop();
                    },
                  );
                },
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('open_move_node_dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('confirm uses initial target by default', (
    WidgetTester tester,
  ) async {
    String? confirmedTarget;
    await openDialog(
      tester,
      onConfirm: (targetNodeId) {
        confirmedTarget = targetNodeId;
      },
      onCancel: () {},
    );

    await tester.tap(find.byKey(const Key('notes_move_node_confirm_button')));
    await tester.pumpAndSettle();

    expect(confirmedTarget, '__root__');
    expect(find.byKey(const Key('notes_move_node_dialog')), findsNothing);
  });

  testWidgets('confirm returns selected dropdown target', (
    WidgetTester tester,
  ) async {
    String? confirmedTarget;
    await openDialog(
      tester,
      onConfirm: (targetNodeId) {
        confirmedTarget = targetNodeId;
      },
      onCancel: () {},
    );

    await tester.tap(find.byKey(const Key('notes_move_node_target_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folder B').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notes_move_node_confirm_button')));
    await tester.pumpAndSettle();

    expect(confirmedTarget, 'folder-b');
  });

  testWidgets('cancel closes dialog and fires callback', (
    WidgetTester tester,
  ) async {
    var cancelCount = 0;
    await openDialog(
      tester,
      onConfirm: (_) {},
      onCancel: () {
        cancelCount += 1;
      },
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(cancelCount, 1);
    expect(find.byKey(const Key('notes_move_node_dialog')), findsNothing);
  });
}
