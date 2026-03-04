import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/shared/tag_results_panel.dart';

void main() {
  group('TagResultsPanel', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagResultsPanel(
              tag: 'flutter',
              items: const [],
              loading: true,
              breadcrumbs: const {},
              onTapItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('tag_results_header')), findsOneWidget);
      expect(find.text('Tag "flutter"'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagResultsPanel(
              tag: 'flutter',
              items: const [],
              loading: false,
              breadcrumbs: const {},
              onTapItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No matching atoms'), findsOneWidget);
    });

    testWidgets('shows error message when errorMessage is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagResultsPanel(
              tag: 'flutter',
              items: const [],
              loading: false,
              breadcrumbs: const {},
              onTapItem: (_) {},
              errorMessage: 'Failed to load results',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('tag_results_error')), findsOneWidget);
      expect(find.text('Failed to load results'), findsOneWidget);
      expect(find.text('No matching atoms'), findsNothing);
    });

    testWidgets('renders result rows with titles', (tester) async {
      final items = [
        const TagResultItem(
          atomId: 'atom-1',
          viewHint: 'note',
          title: 'First Note',
        ),
        const TagResultItem(
          atomId: 'atom-2',
          viewHint: 'task',
          title: 'My Task',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagResultsPanel(
              tag: 'work',
              items: items,
              loading: false,
              breadcrumbs: const {
                'atom-1': ['Projects', 'Docs'],
                'atom-2': [],
              },
              onTapItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('First Note'), findsOneWidget);
      expect(find.text('My Task'), findsOneWidget);
      expect(find.byKey(const Key('tag_result_atom-1')), findsOneWidget);
      expect(find.byKey(const Key('tag_result_atom-2')), findsOneWidget);
    });

    testWidgets('tapping row invokes onTapItem with atomId', (tester) async {
      String? tappedId;
      final items = [
        const TagResultItem(
          atomId: 'atom-1',
          viewHint: 'note',
          title: 'Tap Me',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagResultsPanel(
              tag: 'test',
              items: items,
              loading: false,
              breadcrumbs: const {
                'atom-1': ['Root'],
              },
              onTapItem: (id) => tappedId = id,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('tag_result_atom-1')));
      expect(tappedId, 'atom-1');
    });

    testWidgets('view hint icons map correctly', (tester) async {
      final items = [
        const TagResultItem(atomId: 'a1', viewHint: 'note', title: 'Note Item'),
        const TagResultItem(atomId: 'a2', viewHint: 'task', title: 'Task Item'),
        const TagResultItem(
          atomId: 'a3',
          viewHint: 'event',
          title: 'Event Item',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagResultsPanel(
              tag: 'icons',
              items: items,
              loading: false,
              breadcrumbs: const {},
              onTapItem: (_) {},
            ),
          ),
        ),
      );

      // 📝 note, ✅ task, 📅 event
      expect(find.text('\u{1F4DD}'), findsOneWidget);
      expect(find.text('\u2705'), findsOneWidget);
      expect(find.text('\u{1F4C5}'), findsOneWidget);
    });
  });
}
