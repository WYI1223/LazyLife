import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/notes/dialogs/delete_folder_dialog.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required DeleteFolderDialogConfirm onConfirm,
    required DeleteFolderDialogCancel onCancel,
  }) async {
    await tester.pumpWidget(
      wrapWithMaterial(
        Builder(
          builder: (context) => FilledButton(
            key: const Key('open_delete_folder_dialog'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return DeleteFolderDialog(
                    folderLabel: 'Project A',
                    onConfirm: (mode) {
                      onConfirm(mode);
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
    await tester.tap(find.byKey(const Key('open_delete_folder_dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('confirm uses dissolve mode by default', (
    WidgetTester tester,
  ) async {
    FolderDeleteMode? confirmedMode;
    await openDialog(
      tester,
      onConfirm: (mode) {
        confirmedMode = mode;
      },
      onCancel: () {},
    );

    await tester.tap(
      find.byKey(const Key('notes_folder_delete_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(confirmedMode, FolderDeleteMode.dissolve);
    expect(find.byKey(const Key('notes_delete_folder_dialog')), findsNothing);
  });

  testWidgets('confirm returns delete-all when selected', (
    WidgetTester tester,
  ) async {
    FolderDeleteMode? confirmedMode;
    await openDialog(
      tester,
      onConfirm: (mode) {
        confirmedMode = mode;
      },
      onCancel: () {},
    );

    await tester.tap(
      find.byKey(const Key('notes_folder_delete_mode_delete_all')),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('notes_folder_delete_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(confirmedMode, FolderDeleteMode.deleteAll);
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
    expect(find.byKey(const Key('notes_delete_folder_dialog')), findsNothing);
  });
}
