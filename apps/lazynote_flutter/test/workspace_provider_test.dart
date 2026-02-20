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

  test('WorkspaceLayoutState snapshots are defensively immutable', () {
    final paneOrder = <String>['pane.primary'];
    final paneFractions = <double>[1.0];
    final state = WorkspaceLayoutState(
      paneOrder: paneOrder,
      paneFractions: paneFractions,
      splitDirection: WorkspaceSplitDirection.horizontal,
      primaryPaneId: 'pane.primary',
    );

    paneOrder.add('pane.mutated');
    paneFractions[0] = 0.25;

    expect(state.paneOrder, ['pane.primary']);
    expect(state.paneFractions, [1.0]);
    expect(() => state.paneOrder.add('pane.extra'), throwsUnsupportedError);
    expect(() => state.paneFractions.add(0.5), throwsUnsupportedError);

    final copied = state.copyWith();
    expect(copied.paneOrder, ['pane.primary']);
    expect(copied.paneFractions, [1.0]);
    expect(() => copied.paneOrder.add('pane.copy'), throwsUnsupportedError);
  });

  test('splitActivePane creates a second pane and focuses the new pane', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final result = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );

    expect(result, WorkspaceSplitResult.ok);
    expect(provider.layoutState.paneOrder.length, 2);
    expect(provider.layoutState.paneFractions, const [0.5, 0.5]);
    expect(
      provider.layoutState.splitDirection,
      WorkspaceSplitDirection.horizontal,
    );
    expect(provider.activePaneId, provider.layoutState.paneOrder.last);
  });

  test('splitActivePane blocks when min-size guard would be violated', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final result = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 360,
    );

    expect(result, WorkspaceSplitResult.minSizeBlocked);
    expect(provider.layoutState.paneOrder.length, 1);
  });

  test('splitActivePane keeps root direction locked after first split', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final first = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );
    expect(first, WorkspaceSplitResult.ok);

    final second = provider.splitActivePane(
      direction: WorkspaceSplitDirection.vertical,
      containerExtent: 900,
    );
    expect(second, WorkspaceSplitResult.directionLocked);
  });

  test('splitActivePane enforces max pane count', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    String paneWithLargestFraction() {
      var maxIndex = 0;
      var maxFraction = provider.layoutState.paneFractions.first;
      for (
        var index = 1;
        index < provider.layoutState.paneFractions.length;
        index += 1
      ) {
        final candidate = provider.layoutState.paneFractions[index];
        if (candidate > maxFraction) {
          maxFraction = candidate;
          maxIndex = index;
        }
      }
      return provider.layoutState.paneOrder[maxIndex];
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      provider.switchActivePane(paneWithLargestFraction());
      expect(
        provider.splitActivePane(
          direction: WorkspaceSplitDirection.horizontal,
          containerExtent: 1200,
        ),
        WorkspaceSplitResult.ok,
      );
    }
    expect(provider.layoutState.paneOrder.length, 4);

    final blocked = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );
    expect(blocked, WorkspaceSplitResult.maxPanesReached);
    expect(provider.layoutState.paneOrder.length, 4);
  });

  test('openNote routes to active split pane', () {
    final provider = WorkspaceProvider();
    addTearDown(provider.dispose);

    final split = provider.splitActivePane(
      direction: WorkspaceSplitDirection.horizontal,
      containerExtent: 1200,
    );
    expect(split, WorkspaceSplitResult.ok);
    final primaryPane = provider.layoutState.primaryPaneId;
    final activeSplitPane = provider.activePaneId;

    provider.openNote(noteId: 'note-2', initialContent: 'split note');

    expect(provider.openTabsByPane[activeSplitPane], const ['note-2']);
    expect(provider.openTabsByPane[primaryPane], isEmpty);
  });
}
