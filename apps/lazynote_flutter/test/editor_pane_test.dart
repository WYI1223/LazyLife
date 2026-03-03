import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/editor/edit_buffer.dart';
import 'package:lazynote_flutter/features/notes/note_editor.dart';

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

EditBuffer _readyBuffer(String content) {
  final buffer = EditBuffer(
    atomId: 'atom-1',
    persistFn: (id, c) async => true,
    timerFactory: _fakeTimer,
  );
  buffer.initialize(content);
  return buffer;
}

Widget _wrapEditor({
  required String content,
  EditBuffer? buffer,
  ValueChanged<String>? onChanged,
  int focusRequestId = 0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: NoteEditor(
        content: content,
        buffer: buffer,
        focusRequestId: focusRequestId,
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// T12: NoteEditor manual listener widget tests
// ---------------------------------------------------------------------------

void main() {
  group('T12: NoteEditor manual listener pattern', () {
    testWidgets('initState attaches buffer listener', (tester) async {
      final buffer = _readyBuffer('hello');

      await tester.pumpWidget(_wrapEditor(content: 'hello', buffer: buffer));

      // Simulate remote edit via buffer
      buffer.edit('hello world');
      await tester.pump();

      // The TextField should reflect the buffer's content
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'hello world');

      // Clean up
      buffer.dispose();
    });

    testWidgets('string guard: local edit does not cause cursor jump', (
      tester,
    ) async {
      final buffer = _readyBuffer('initial');
      final edits = <String>[];

      await tester.pumpWidget(
        _wrapEditor(
          content: 'initial',
          buffer: buffer,
          onChanged: (s) {
            buffer.edit(s);
            edits.add(s);
          },
        ),
      );

      // Simulate local typing
      await tester.enterText(find.byType(TextField), 'initial+local');
      await tester.pump();

      // The buffer should have the new content
      expect(buffer.content, 'initial+local');

      // The listener callback fires but string guard (content == controller.text)
      // prevents controller update — cursor should not jump
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'initial+local');

      buffer.dispose();
    });

    testWidgets('dispose detaches buffer listener', (tester) async {
      final buffer = _readyBuffer('start');

      await tester.pumpWidget(_wrapEditor(content: 'start', buffer: buffer));

      // Remove the widget (triggers dispose)
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));

      // Editing buffer after dispose should not cause errors
      // (listener was properly removed)
      buffer.edit('after dispose');
      expect(buffer.content, 'after dispose');

      buffer.dispose();
    });

    testWidgets('didUpdateWidget swaps buffer listener on reference change', (
      tester,
    ) async {
      final buffer1 = _readyBuffer('buffer1');
      final buffer2 = _readyBuffer('buffer2');

      // Start with buffer1
      await tester.pumpWidget(_wrapEditor(content: 'buffer1', buffer: buffer1));

      final textFieldBefore = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldBefore.controller!.text, 'buffer1');

      // Switch to buffer2
      await tester.pumpWidget(_wrapEditor(content: 'buffer2', buffer: buffer2));

      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.controller!.text, 'buffer2');

      // Edit buffer2 — should update widget
      buffer2.edit('buffer2 edited');
      await tester.pump();

      final textFieldUpdated = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldUpdated.controller!.text, 'buffer2 edited');

      // Edit buffer1 — should NOT update widget (listener detached)
      buffer1.edit('buffer1 orphan edit');
      await tester.pump();

      final textFieldStill = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldStill.controller!.text, 'buffer2 edited');

      buffer1.dispose();
      buffer2.dispose();
    });

    testWidgets('works without buffer (legacy path)', (tester) async {
      await tester.pumpWidget(_wrapEditor(content: 'legacy'));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'legacy');

      // Content update via parent rebuild
      await tester.pumpWidget(_wrapEditor(content: 'updated'));

      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.controller!.text, 'updated');
    });
  });
}
