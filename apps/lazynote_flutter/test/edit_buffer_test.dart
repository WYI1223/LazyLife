import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/editor/edit_buffer.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Fake persistFn that always succeeds after a microtask.
Future<bool> _successPersist(String atomId, String content) async => true;

/// Fake persistFn that always fails.
Future<bool> _failPersist(String atomId, String content) async =>
    throw Exception('persist failed');

/// Creates a timer factory that captures created timers for manual control.
({Timer Function(Duration, void Function()) factory, List<_FakeTimer> timers})
_fakeTimerFactory() {
  final timers = <_FakeTimer>[];
  Timer factory(Duration d, void Function() cb) {
    final t = _FakeTimer(d, cb);
    timers.add(t);
    return t;
  }

  return (factory: factory, timers: timers);
}

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

// ---------------------------------------------------------------------------
// T8: Cross-pane sync (DI-4 D10 — buffer listener pattern)
// ---------------------------------------------------------------------------

void main() {
  group('T8: Cross-pane buffer sync', () {
    test('edit() notifies all listeners', () {
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: _successPersist,
        timerFactory: _fakeTimerFactory().factory,
      );
      buffer.initialize('initial');

      var notifyCount = 0;
      buffer.addListener(() => notifyCount++);

      buffer.edit('updated');
      expect(notifyCount, 1);
      expect(buffer.content, 'updated');

      buffer.dispose();
    });

    test('two listeners both see edit from one source', () {
      final tf = _fakeTimerFactory();
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: _successPersist,
        timerFactory: tf.factory,
      );
      buffer.initialize('start');

      // Simulate two panes subscribing
      String paneAContent = '';
      String paneBContent = '';
      buffer.addListener(() => paneAContent = buffer.content);
      buffer.addListener(() => paneBContent = buffer.content);

      // Pane A edits
      buffer.edit('from pane A');

      expect(paneAContent, 'from pane A');
      expect(paneBContent, 'from pane A');
      expect(buffer.rev, 1);

      // Pane B edits
      buffer.edit('from pane B');

      expect(paneAContent, 'from pane B');
      expect(paneBContent, 'from pane B');
      expect(buffer.rev, 2);

      buffer.dispose();
    });

    test('edit with same content is no-op (string guard Level 1)', () {
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: _successPersist,
        timerFactory: _fakeTimerFactory().factory,
      );
      buffer.initialize('hello');

      var notifyCount = 0;
      buffer.addListener(() => notifyCount++);

      buffer.edit('hello'); // same content
      expect(notifyCount, 0);
      expect(buffer.rev, 0);

      buffer.dispose();
    });

    test('phase transitions: loading → ready → editing', () {
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: _successPersist,
        timerFactory: _fakeTimerFactory().factory,
      );

      expect(buffer.phase, BufferPhase.loading);

      // edit in loading phase is no-op
      buffer.edit('ignored');
      expect(buffer.content, '');
      expect(buffer.rev, 0);

      buffer.initialize('loaded');
      expect(buffer.phase, BufferPhase.ready);
      expect(buffer.content, 'loaded');

      buffer.edit('edited');
      expect(buffer.content, 'edited');
      expect(buffer.rev, 1);

      buffer.dispose();
    });

    test('phase transitions: loading → error → retry → loading', () {
      final buffer = EditBuffer(atomId: 'atom-1', persistFn: _successPersist);

      expect(buffer.phase, BufferPhase.loading);

      buffer.markError('load failed');
      expect(buffer.phase, BufferPhase.error);
      expect(buffer.errorMessage, 'load failed');

      buffer.retry();
      expect(buffer.phase, BufferPhase.loading);
      expect(buffer.errorMessage, isNull);

      buffer.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // T9: Save semantics (DI-4 D11)
  // ---------------------------------------------------------------------------

  group('T9: Save semantics', () {
    test('1.5s debounce auto-save', () async {
      final tf = _fakeTimerFactory();
      final saves = <String>[];
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: (id, content) async {
          saves.add(content);
          return true;
        },
        timerFactory: tf.factory,
        autosaveDebounce: const Duration(milliseconds: 1500),
      );
      buffer.initialize('');

      buffer.edit('a');
      expect(saves, isEmpty); // not saved yet

      // Debounce timer fires
      final debounceTimer = tf.timers.firstWhere(
        (t) => t.duration == const Duration(milliseconds: 1500),
      );
      debounceTimer.fire();
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(saves, ['a']);
      buffer.dispose();
    });

    test('_rev stale guard: rapid edits during save', () async {
      final tf = _fakeTimerFactory();
      final saves = <String>[];
      final completer1 = Completer<bool>();

      var callCount = 0;
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: (id, content) {
          callCount++;
          saves.add(content);
          if (callCount == 1) return completer1.future;
          return Future.value(true);
        },
        timerFactory: tf.factory,
      );
      buffer.initialize('');

      // First edit
      buffer.edit('v1');
      final debounce1 = tf.timers.last;
      debounce1.fire();
      await Future.microtask(() {});

      expect(saves, ['v1']);
      expect(buffer.saveState, SaveState.saving);

      // Edit during save → triggers queue
      buffer.edit('v2');
      final debounce2 = tf.timers.last;
      debounce2.fire();
      await Future.microtask(() {});

      // Complete first save
      completer1.complete(true);
      await Future.microtask(() {});
      await Future.microtask(() {});
      await Future.microtask(() {});

      // Queued save executes
      expect(saves, ['v1', 'v2']);
      buffer.dispose();
    });

    test('force save after 30s of continuous editing', () async {
      final tf = _fakeTimerFactory();
      final saves = <String>[];
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: (id, content) async {
          saves.add(content);
          return true;
        },
        timerFactory: tf.factory,
        forceSaveInterval: const Duration(seconds: 30),
      );
      buffer.initialize('');

      buffer.edit('typing...');

      // Force timer fires (simulating 30s elapsed)
      final forceTimer = tf.timers.firstWhere(
        (t) => t.duration == const Duration(seconds: 30),
      );
      forceTimer.fire();
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(saves, ['typing...']);
      buffer.dispose();
    });

    test('save success updates lastSavedContent and clears isDirty', () async {
      final tf = _fakeTimerFactory();
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: _successPersist,
        timerFactory: tf.factory,
      );
      buffer.initialize('original');

      buffer.edit('modified');
      expect(buffer.isDirty, isTrue);

      // Trigger save
      await buffer.flush();

      expect(buffer.isDirty, isFalse);
      expect(buffer.lastSavedContent, 'modified');
      buffer.dispose();
    });

    test('save failure sets error state', () async {
      final tf = _fakeTimerFactory();
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: _failPersist,
        timerFactory: tf.factory,
      );
      buffer.initialize('');

      buffer.edit('data');
      await buffer.flush();

      expect(buffer.saveState, SaveState.error);
      expect(buffer.errorMessage, contains('persist failed'));
      buffer.dispose();
    });

    test('flush waits for in-flight save', () async {
      final tf = _fakeTimerFactory();
      final completer = Completer<bool>();
      var flushCompleted = false;

      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: (id, content) => completer.future,
        timerFactory: tf.factory,
      );
      buffer.initialize('');

      buffer.edit('data');
      // Start save via debounce
      tf.timers.last.fire();

      // flush should wait
      final flushFuture = buffer.flush().then((_) => flushCompleted = true);
      await Future.microtask(() {});
      expect(flushCompleted, isFalse);

      completer.complete(true);
      await flushFuture;
      expect(flushCompleted, isTrue);

      buffer.dispose();
    });

    test('onSaved callback fires after successful save', () async {
      final tf = _fakeTimerFactory();
      final savedContents = <String>[];
      final buffer = EditBuffer(
        atomId: 'atom-1',
        persistFn: _successPersist,
        onSaved: (id, content) => savedContents.add(content),
        timerFactory: tf.factory,
      );
      buffer.initialize('');

      buffer.edit('saved content');
      await buffer.flush();

      expect(savedContents, ['saved content']);
      buffer.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // T11: Performance regression guard (DI-7 Q2-SLA)
  // ---------------------------------------------------------------------------

  group('T11: Performance guard', () {
    test('100KB buffer sync completes under 40ms (CI guard)', () {
      final tf = _fakeTimerFactory();
      final buffer = EditBuffer(
        atomId: 'atom-perf',
        persistFn: _successPersist,
        timerFactory: tf.factory,
      );
      buffer.initialize('');

      // 100KB content
      final largeContent = 'x' * (100 * 1024);

      var listenerFired = false;
      buffer.addListener(() => listenerFired = true);

      final sw = Stopwatch()..start();
      buffer.edit(largeContent);
      sw.stop();

      expect(listenerFired, isTrue);
      expect(buffer.content.length, 100 * 1024);
      expect(
        sw.elapsedMilliseconds,
        lessThan(40),
        reason: 'Buffer sync for 100KB must complete under 40ms (CI 5x SLA)',
      );

      buffer.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // AtomNotFoundException
  // ---------------------------------------------------------------------------

  group('AtomNotFoundException', () {
    test('toString includes atomId', () {
      const ex = AtomNotFoundException('uuid-123');
      expect(ex.toString(), contains('uuid-123'));
      expect(ex.atomId, 'uuid-123');
    });
  });
}
