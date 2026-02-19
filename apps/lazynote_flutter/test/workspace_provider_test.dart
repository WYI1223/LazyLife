import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/workspace/workspace_models.dart';
import 'package:lazynote_flutter/features/workspace/workspace_provider.dart';

void main() {
  test('R02-1.1 active draft is derived from buffers map after tab switch', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    provider.openNote(noteId: 'note-1', initialContent: 'persisted one');
    provider.openNote(noteId: 'note-2', initialContent: 'persisted two');
    provider.updateDraft(noteId: 'note-2', content: 'draft two');
    provider.activateNote(noteId: 'note-1');
    expect(provider.activeDraftContent, 'persisted one');

    provider.activateNote(noteId: 'note-2');
    expect(provider.activeDraftContent, 'draft two');
  });

  test('R02-1.2 flush has bounded retries and ends in saveError', () async {
    var saveCalls = 0;
    final provider = WorkspaceProvider(
      flushMaxRetries: 5,
      autosaveDebounce: const Duration(seconds: 30),
      saveInvoker: ({required noteId, required content}) async {
        saveCalls += 1;
        return false;
      },
    );
    addTearDown(provider.dispose);

    provider.openNote(noteId: 'note-1', initialContent: 'v1');
    provider.updateDraft(noteId: 'note-1', content: 'v2');

    final ok = await provider.flushActiveNote();
    expect(ok, isFalse);
    expect(saveCalls, 5);
    expect(provider.saveStateByNoteId['note-1'], WorkspaceSaveState.saveError);
  });

  test('R02-1.2 flush tolerates in-flight typing and still exits', () async {
    var saveCalls = 0;
    late WorkspaceProvider provider;
    provider = WorkspaceProvider(
      flushMaxRetries: 5,
      autosaveDebounce: const Duration(seconds: 30),
      saveInvoker: ({required noteId, required content}) async {
        saveCalls += 1;
        if (saveCalls == 1) {
          provider.updateDraft(noteId: noteId, content: 'v3');
        }
        return false;
      },
    );
    addTearDown(provider.dispose);

    provider.openNote(noteId: 'note-1', initialContent: 'v1');
    provider.updateDraft(noteId: 'note-1', content: 'v2');

    final ok = await provider.flushActiveNote();
    expect(ok, isFalse);
    expect(saveCalls, lessThanOrEqualTo(5));
    expect(provider.saveStateByNoteId['note-1'], WorkspaceSaveState.saveError);
  });

  test('R02-1.3 queued tag mutation skips call after note closes', () async {
    final gate = Completer<void>();
    final firstStarted = Completer<void>();
    var mutationCalls = 0;
    final provider = WorkspaceProvider(
      tagMutationInvoker: ({required noteId, required tags}) async {
        mutationCalls += 1;
        if (mutationCalls == 1) {
          firstStarted.complete();
          await gate.future;
        }
        return true;
      },
    );
    addTearDown(provider.dispose);

    provider.openNote(noteId: 'note-1', initialContent: 'note');

    final first = provider.enqueueTagMutation(noteId: 'note-1', tags: ['a']);
    await firstStarted.future;
    final second = provider.enqueueTagMutation(noteId: 'note-1', tags: ['b']);

    provider.closeNote(noteId: 'note-1');
    gate.complete();

    expect(await first, isFalse);
    expect(await second, isFalse);
    expect(mutationCalls, 1);
  });

  test(
    'flush maps saveInvoker throw to saveError and remains callable',
    () async {
      var calls = 0;
      final provider = WorkspaceProvider(
        flushMaxRetries: 3,
        autosaveDebounce: const Duration(seconds: 30),
        saveInvoker: ({required noteId, required content}) async {
          calls += 1;
          throw StateError('boom');
        },
      );
      addTearDown(provider.dispose);

      provider.openNote(noteId: 'note-1', initialContent: 'v1');
      provider.updateDraft(noteId: 'note-1', content: 'v2');

      final first = await provider.flushActiveNote();
      expect(first, isFalse);
      expect(
        provider.saveStateByNoteId['note-1'],
        WorkspaceSaveState.saveError,
      );

      final second = await provider.flushActiveNote();
      expect(second, isFalse);
      expect(calls, greaterThanOrEqualTo(2));
    },
  );

  test('flush on closed note does not recreate orphan saveState', () async {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    provider.openNote(noteId: 'note-1', initialContent: 'v1');
    provider.updateDraft(noteId: 'note-1', content: 'v2');
    provider.closeNote(noteId: 'note-1');
    expect(provider.saveStateByNoteId.containsKey('note-1'), isFalse);

    final ok = await provider.flushNote('note-1');
    expect(ok, isTrue);
    expect(provider.saveStateByNoteId.containsKey('note-1'), isFalse);
  });
}
