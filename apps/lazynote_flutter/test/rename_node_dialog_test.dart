import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/notes/dialogs/rename_node_dialog.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required RenameNodeDialogConfirm onConfirm,
    required RenameNodeDialogCancel onCancel,
  }) async {
    await tester.pumpWidget(
      wrapWithMaterial(
        Builder(
          builder: (context) => FilledButton(
            key: const Key('open_rename_node_dialog'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return RenameNodeDialog(
                    initialName: 'Inbox',
                    onConfirm: (value) {
                      onConfirm(value);
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
    await tester.tap(find.byKey(const Key('open_rename_node_dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('confirm is disabled when value is unchanged', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, onConfirm: (_) {}, onCancel: () {});

    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('notes_rename_node_confirm_button')),
    );
    expect(confirmButton.onPressed, isNull);
  });

  testWidgets('confirm submits trimmed renamed value', (
    WidgetTester tester,
  ) async {
    String? renamedValue;
    await openDialog(
      tester,
      onConfirm: (value) {
        renamedValue = value;
      },
      onCancel: () {},
    );

    await tester.enterText(
      find.byKey(const Key('notes_rename_node_input')),
      '  Inbox Renamed  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('notes_rename_node_confirm_button')));
    await tester.pumpAndSettle();

    expect(renamedValue, 'Inbox Renamed');
    expect(find.byKey(const Key('notes_rename_node_dialog')), findsNothing);
  });

  testWidgets('cancel and enter-submit both trigger callbacks', (
    WidgetTester tester,
  ) async {
    var cancelCount = 0;
    String? submittedValue;
    await openDialog(
      tester,
      onConfirm: (value) {
        submittedValue = value;
      },
      onCancel: () {
        cancelCount += 1;
      },
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cancelCount, 1);

    await openDialog(
      tester,
      onConfirm: (value) {
        submittedValue = value;
      },
      onCancel: () {},
    );
    await tester.enterText(
      find.byKey(const Key('notes_rename_node_input')),
      '  Renamed by Enter  ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submittedValue, 'Renamed by Enter');
    expect(find.byKey(const Key('notes_rename_node_dialog')), findsNothing);
  });
}
