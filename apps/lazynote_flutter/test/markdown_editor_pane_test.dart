import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/editor/edit_buffer.dart';
import 'package:lazynote_flutter/core/editor/markdown_editor_pane.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Timer _fakeTimer(Duration d, void Function() cb) => _FakeTimer(d, cb);

class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _cancelled = false;
  int _tick = 0;

  @override
  void cancel() => _cancelled = true;

  @override
  bool get isActive => !_cancelled;

  @override
  int get tick => _tick;

  void fire() {
    if (_cancelled) return;
    _tick++;
    _callback();
  }
}

EditBuffer _readyBuffer(String content, {String atomId = 'atom-1'}) {
  final buffer = EditBuffer(
    atomId: atomId,
    persistFn: (id, c) async => true,
    timerFactory: _fakeTimer,
  );
  buffer.initialize(content);
  return buffer;
}

Widget _wrapPane(EditBuffer buffer) {
  return MaterialApp(
    home: Scaffold(body: MarkdownEditorPane(buffer: buffer)),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MarkdownEditorPane', () {
    testWidgets('renders buffer content', (tester) async {
      final buffer = _readyBuffer('hello world');

      await tester.pumpWidget(_wrapPane(buffer));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'hello world');

      buffer.dispose();
    });

    testWidgets('local edit calls buffer.edit()', (tester) async {
      final buffer = _readyBuffer('initial');

      await tester.pumpWidget(_wrapPane(buffer));
      await tester.enterText(find.byType(TextField), 'initial+typed');
      await tester.pump();

      expect(buffer.content, 'initial+typed');
      buffer.dispose();
    });

    testWidgets('remote edit updates controller (string guard)', (
      tester,
    ) async {
      final buffer = _readyBuffer('hello');

      await tester.pumpWidget(_wrapPane(buffer));

      // Simulate remote edit via buffer
      buffer.edit('hello world');
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'hello world');

      buffer.dispose();
    });

    testWidgets('string guard: local edit echo is NO-OP', (tester) async {
      final buffer = _readyBuffer('start');

      await tester.pumpWidget(_wrapPane(buffer));

      // Type into the field — this calls buffer.edit() internally
      await tester.enterText(find.byType(TextField), 'start+local');
      await tester.pump();

      // Buffer listener fires but content == controller.text → NO-OP
      // Cursor should not jump (controller text unchanged by listener)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'start+local');
      expect(buffer.content, 'start+local');

      buffer.dispose();
    });

    testWidgets('didUpdateWidget swaps buffer listener on reference change', (
      tester,
    ) async {
      final buffer1 = _readyBuffer('buffer1');
      final buffer2 = _readyBuffer('buffer2');

      await tester.pumpWidget(_wrapPane(buffer1));

      final tf1 = tester.widget<TextField>(find.byType(TextField));
      expect(tf1.controller!.text, 'buffer1');

      // Switch to buffer2
      await tester.pumpWidget(_wrapPane(buffer2));

      final tf2 = tester.widget<TextField>(find.byType(TextField));
      expect(tf2.controller!.text, 'buffer2');

      // Edit buffer2 — should update widget
      buffer2.edit('buffer2 edited');
      await tester.pump();

      final tf2Updated = tester.widget<TextField>(find.byType(TextField));
      expect(tf2Updated.controller!.text, 'buffer2 edited');

      // Edit buffer1 — should NOT update widget (listener detached)
      buffer1.edit('buffer1 orphan');
      await tester.pump();

      final tf2Still = tester.widget<TextField>(find.byType(TextField));
      expect(tf2Still.controller!.text, 'buffer2 edited');

      buffer1.dispose();
      buffer2.dispose();
    });

    testWidgets('dispose detaches buffer listener', (tester) async {
      final buffer = _readyBuffer('start');

      await tester.pumpWidget(_wrapPane(buffer));

      // Remove the widget (triggers dispose)
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));

      // Editing buffer after dispose should not cause errors
      buffer.edit('after dispose');
      expect(buffer.content, 'after dispose');

      buffer.dispose();
    });
  });
}
