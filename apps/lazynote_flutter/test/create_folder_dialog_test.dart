import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/notes/dialogs/create_folder_dialog.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required ValueChanged<String> onConfirm,
    required VoidCallback onCancel,
  }) async {
    await tester.pumpWidget(
      wrapWithMaterial(
        Builder(
          builder: (context) => FilledButton(
            key: const Key('open_create_folder_dialog'),
            onPressed: () {
              showDialog<String>(
                context: context,
                builder: (dialogContext) {
                  return CreateFolderDialog(
                    onConfirm: (value) {
                      onConfirm(value);
                      Navigator.of(dialogContext).pop(value);
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
    await tester.tap(find.byKey(const Key('open_create_folder_dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('confirm button is disabled when input is blank', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, onConfirm: (_) {}, onCancel: () {});

    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('notes_create_folder_confirm_button')),
    );
    expect(confirmButton.onPressed, isNull);
  });

  testWidgets('confirm submits trimmed folder name', (
    WidgetTester tester,
  ) async {
    String? confirmedName;

    await openDialog(
      tester,
      onConfirm: (value) {
        confirmedName = value;
      },
      onCancel: () {},
    );

    await tester.enterText(
      find.byKey(const Key('notes_create_folder_name_input')),
      '  Inbox  ',
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('notes_create_folder_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(confirmedName, 'Inbox');
    expect(find.byKey(const Key('notes_create_folder_dialog')), findsNothing);
  });

  testWidgets('cancel and submit action both trigger callbacks', (
    WidgetTester tester,
  ) async {
    var cancelCount = 0;
    String? submittedName;

    await openDialog(
      tester,
      onConfirm: (value) {
        submittedName = value;
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
        submittedName = value;
      },
      onCancel: () {},
    );
    await tester.enterText(
      find.byKey(const Key('notes_create_folder_name_input')),
      '  Drafts  ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submittedName, 'Drafts');
    expect(find.byKey(const Key('notes_create_folder_dialog')), findsNothing);
  });
}
