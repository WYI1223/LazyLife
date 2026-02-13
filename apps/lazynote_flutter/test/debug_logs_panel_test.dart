import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/debug/log_reader.dart';
import 'package:lazynote_flutter/features/diagnostics/debug_logs_panel.dart';

void main() {
  setUp(() {
    DebugLogsPanel.autoRefreshEnabled = false;
  });

  tearDown(() {
    DebugLogsPanel.autoRefreshEnabled = true;
  });

  testWidgets('latest refresh result wins when requests overlap', (
    WidgetTester tester,
  ) async {
    final first = Completer<DebugLogSnapshot>();
    final second = Completer<DebugLogSnapshot>();
    var callCount = 0;

    Future<DebugLogSnapshot> loader() {
      callCount += 1;
      if (callCount == 1) {
        return first.future;
      }
      if (callCount == 2) {
        return second.future;
      }
      return Future.value(_snapshot('fallback snapshot'));
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 640,
            child: DebugLogsPanel(snapshotLoader: loader),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Refresh'));
    await tester.pump();

    second.complete(_snapshot('newest snapshot'));
    await tester.pump();
    expect(find.textContaining('newest snapshot'), findsOneWidget);

    first.complete(_snapshot('older snapshot'));
    await tester.pump();
    expect(find.textContaining('newest snapshot'), findsOneWidget);
    expect(find.textContaining('older snapshot'), findsNothing);
  });
}

DebugLogSnapshot _snapshot(String tailText) {
  return DebugLogSnapshot(
    logDir: r'C:\logs',
    files: const [],
    activeFile: null,
    tailText: tailText,
  );
}
