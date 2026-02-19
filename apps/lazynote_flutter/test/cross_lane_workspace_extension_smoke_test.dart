import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_models.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_registry.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_controller.dart';
import 'package:lazynote_flutter/features/notes/notes_page.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets(
    'cross-lane smoke: slot capability gate enables workspace folder op',
    (WidgetTester tester) async {
      final deleteCalls = <String>[];
      final controller = NotesController(
        prepare: () async {},
        notesListInvoker: ({tag, limit, offset}) async {
          return const rust_api.NotesListResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            appliedLimit: 50,
            items: <rust_api.NoteItem>[],
          );
        },
        noteGetInvoker: ({required atomId}) async {
          return const rust_api.NoteResponse(
            ok: false,
            errorCode: 'note_not_found',
            message: 'missing',
            note: null,
          );
        },
        workspaceDeleteFolderInvoker: ({required nodeId, required mode}) async {
          deleteCalls.add('$nodeId::$mode');
          return const rust_api.WorkspaceActionResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
          );
        },
      );
      addTearDown(controller.dispose);

      final registry = UiSlotRegistry(
        contributions: <UiSlotContribution>[
          UiSlotContribution(
            contributionId: 'test.cross_lane.workspace.delete',
            slotId: UiSlotIds.notesSidePanel,
            layer: UiSlotLayer.sidePanel,
            priority: 999,
            enabledWhen: (slotContext) {
              final runtimeCaps =
                  slotContext.read<List<String>>(
                    UiSlotContextKeys.runtimeCapabilities,
                  ) ??
                  const <String>[];
              return runtimeCaps.contains('file');
            },
            builder: (context, slotContext) {
              final onDeleteFolder = slotContext
                  .require<
                    Future<rust_api.WorkspaceActionResponse> Function(
                      String folderId,
                      String mode,
                    )
                  >(UiSlotContextKeys.notesOnDeleteFolderRequested);
              return ElevatedButton(
                key: const Key('cross_lane_workspace_delete_button'),
                onPressed: () {
                  onDeleteFolder(
                    '11111111-1111-4111-8111-111111111111',
                    'dissolve',
                  );
                },
                child: const Text('Cross Lane Delete'),
              );
            },
          ),
        ],
      );

      // Capability not granted: slot contribution is hidden.
      await tester.pumpWidget(
        _wrap(
          NotesPage(
            controller: controller,
            uiSlotRegistry: registry,
            runtimeCapabilities: const <String>[],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const Key('cross_lane_workspace_delete_button')),
        findsNothing,
      );

      // Capability granted: slot contribution is visible and can call workspace op.
      await tester.pumpWidget(
        _wrap(
          NotesPage(
            controller: controller,
            uiSlotRegistry: registry,
            runtimeCapabilities: const <String>['file'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final buttonFinder = find.byKey(
        const Key('cross_lane_workspace_delete_button'),
      );
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(deleteCalls, <String>[
        '11111111-1111-4111-8111-111111111111::dissolve',
      ]);
    },
  );
}
