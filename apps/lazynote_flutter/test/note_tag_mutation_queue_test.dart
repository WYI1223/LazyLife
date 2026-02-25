import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tag_mutation_queue.dart';

void main() {
  test('enqueue serializes mutations by atom id and preserves order', () async {
    final queue = NoteTagMutationQueue();
    final firstGate = Completer<void>();
    final events = <String>[];

    final first = queue.enqueue(
      atomId: 'note-1',
      mutation: () async {
        events.add('first:start');
        await firstGate.future;
        events.add('first:end');
        return true;
      },
    );
    final second = queue.enqueue(
      atomId: 'note-1',
      mutation: () async {
        events.add('second');
        return false;
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(events, <String>['first:start']);

    firstGate.complete();
    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(events, <String>['first:start', 'first:end', 'second']);
  });

  test('waitForAtom blocks until in-flight marker is cleared', () async {
    final queue = NoteTagMutationQueue();
    queue.beginInFlight('note-1');

    var done = false;
    final waiting = queue.waitForAtom('note-1').then((_) => done = true);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(done, isFalse);

    queue.endInFlight('note-1');
    await waiting;
    expect(done, isTrue);
  });

  test(
    'error in one queued mutation does not block subsequent mutation',
    () async {
      final queue = NoteTagMutationQueue();
      var calls = 0;

      final first = queue.enqueue(
        atomId: 'note-1',
        mutation: () async {
          calls += 1;
          throw StateError('boom');
        },
      );
      final second = queue.enqueue(
        atomId: 'note-1',
        mutation: () async {
          calls += 1;
          return true;
        },
      );

      await expectLater(first, throwsA(isA<StateError>()));
      expect(await second, isTrue);
      expect(calls, 2);
      await queue.waitForAll();
    },
  );
}
