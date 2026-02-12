import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/main.dart';

void main() {
  testWidgets('shows rust health check result', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        loadRustHealth: () async =>
            const RustHealthSnapshot(ping: 'pong', coreVersion: '0.1.0'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rust bridge connected'), findsOneWidget);
    expect(find.text('ping: pong'), findsOneWidget);
    expect(find.text('coreVersion: 0.1.0'), findsOneWidget);
  });
}
