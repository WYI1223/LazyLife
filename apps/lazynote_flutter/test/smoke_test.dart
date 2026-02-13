import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/app/app.dart';
import 'package:lazynote_flutter/features/diagnostics/debug_logs_panel.dart';

void main() {
  setUp(() {
    DebugLogsPanel.autoRefreshEnabled = false;
  });

  tearDown(() {
    DebugLogsPanel.autoRefreshEnabled = true;
  });

  Future<void> tapWorkbenchButton(
    WidgetTester tester,
    String buttonText,
  ) async {
    final buttonFinder = find.text(buttonText);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('workbench home shows single-entry-focused controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LazyNoteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Workbench Home'), findsOneWidget);
    expect(find.text('Single Entry'), findsWidgets);
    expect(find.text('Open Single Entry'), findsOneWidget);
  });

  testWidgets('notes placeholder route is reachable from workbench', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LazyNoteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tapWorkbenchButton(tester, 'Notes (Placeholder)');

    expect(find.text('Notes'), findsWidgets);
    expect(find.text('Notes is under construction'), findsOneWidget);
    expect(find.text('Back to Workbench'), findsOneWidget);
  });

  testWidgets('tasks placeholder route is reachable from workbench', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LazyNoteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tapWorkbenchButton(tester, 'Tasks (Placeholder)');

    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Tasks is under construction'), findsOneWidget);
    expect(find.text('Back to Workbench'), findsOneWidget);
  });

  testWidgets('settings placeholder route is reachable from workbench', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LazyNoteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tapWorkbenchButton(tester, 'Settings (Placeholder)');

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Settings is under construction'), findsOneWidget);
    expect(find.text('Back to Workbench'), findsOneWidget);
  });

  testWidgets('rust diagnostics route is reachable from workbench', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LazyNoteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tapWorkbenchButton(tester, 'Rust Diagnostics');

    expect(find.text('Rust Diagnostics'), findsWidgets);
  });

  testWidgets('workbench shows inline debug logs panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LazyNoteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Debug Logs (Live)'), findsOneWidget);
    expect(find.text('Copy Visible Logs'), findsOneWidget);
    expect(find.text('Open Log Folder'), findsOneWidget);
  });

  testWidgets('single entry launcher is reachable from workbench', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LazyNoteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tapWorkbenchButton(tester, 'Open Single Entry');

    expect(find.byKey(const Key('single_entry_input')), findsOneWidget);
    expect(find.byKey(const Key('single_entry_send_button')), findsOneWidget);
  });
}
