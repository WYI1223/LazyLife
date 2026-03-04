import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/editor/edit_buffer.dart';
import 'package:lazynote_flutter/core/editor/editor_resolver.dart';

// Test builders — top-level functions to satisfy prefer_function_declarations.
Widget _mdBuilder(
  BuildContext ctx,
  EditBuffer buf, {
  bool requestInitialFocus = false,
}) => const SizedBox(key: Key('md'));
Widget _v1Builder(
  BuildContext ctx,
  EditBuffer buf, {
  bool requestInitialFocus = false,
}) => const SizedBox(key: Key('v1'));
Widget _v2Builder(
  BuildContext ctx,
  EditBuffer buf, {
  bool requestInitialFocus = false,
}) => const SizedBox(key: Key('v2'));
Widget _canvasBuilder(
  BuildContext ctx,
  EditBuffer buf, {
  bool requestInitialFocus = false,
}) => const SizedBox(key: Key('canvas'));

void main() {
  group('EditorResolver', () {
    late EditorResolver resolver;

    setUp(() {
      resolver = EditorResolver();
    });

    test('resolve returns registered builder', () {
      resolver.register('markdown', _mdBuilder);

      expect(resolver.resolve('markdown'), same(_mdBuilder));
    });

    test('resolve returns error placeholder for unknown content type', () {
      final builder = resolver.resolve('canvas');

      // Placeholder builder should not be null.
      expect(builder, isNotNull);
      // It should NOT be any registered builder.
      resolver.register('markdown', _mdBuilder);
      expect(builder, isNot(same(_mdBuilder)));
    });

    test('register override: last registration wins', () {
      resolver.register('markdown', _v1Builder);
      resolver.register('markdown', _v2Builder);

      expect(resolver.resolve('markdown'), same(_v2Builder));
    });

    test('different content types resolve independently', () {
      resolver.register('markdown', _mdBuilder);
      resolver.register('canvas', _canvasBuilder);

      expect(resolver.resolve('markdown'), same(_mdBuilder));
      expect(resolver.resolve('canvas'), same(_canvasBuilder));
    });

    testWidgets('unknown type placeholder renders error text', (tester) async {
      final paneBuilder = resolver.resolve('nonexistent');
      final buffer = EditBuffer(
        atomId: 'test',
        persistFn: (id, c) async => true,
      );
      buffer.initialize('');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (context) => paneBuilder(context, buffer)),
        ),
      );

      expect(find.text('Unsupported content type'), findsOneWidget);
      buffer.dispose();
    });
  });
}
