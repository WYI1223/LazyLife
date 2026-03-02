import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/managers/note_tag_manager.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tag_manager_types.dart';

rust_api.AtomListItem _note({
  required String atomId,
  required String content,
  required int updatedAt,
  required List<String> tags,
}) {
  return rust_api.AtomListItem(
    viewHint: 'note',
    title: '',
    contentType: 'markdown',
    atomId: atomId,
    content: content,
    previewText: null,
    previewImage: null,
    updatedAt: updatedAt,
    tags: tags,
  );
}

void main() {
  test(
    'serializes concurrent tag mutations and waitForAtomTagMutations waits completion',
    () async {
      final store = <String, rust_api.AtomListItem>{
        'note-1': _note(
          atomId: 'note-1',
          content: '# Seed',
          updatedAt: 1,
          tags: const ['seed'],
        ),
      };
      final firstGate = Completer<void>();
      final calls = <String>[];

      final manager = NoteTagManager(
        tagsListInvoker: () async {
          return rust_api.TagsListResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            tags: store['note-1']!.tags,
          );
        },
        noteSetTagsInvoker: ({required atomId, required tags}) async {
          if (calls.isEmpty) {
            calls.add('first');
            await firstGate.future;
          } else {
            calls.add('second');
          }
          final updated = _note(
            atomId: atomId,
            content: store[atomId]!.content,
            updatedAt: store[atomId]!.updatedAt + 1,
            tags: tags,
          );
          return rust_api.AtomItemResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            item: updated,
          );
        },
        prepare: () async {},
        envelopeError:
            ({required errorCode, required message, required fallback}) {
              return fallback;
            },
        flushPendingSave: () async => true,
        reloadNotesForFilter: ({required preserveActiveWhenFilteredOut}) async {
          return true;
        },
        activeNoteId: () => 'note-1',
        noteById: (atomId) => store[atomId],
        upsertNote:
            (
              note, {
              insertFront = false,
              updatePersisted = false,
              syncVisibleList = true,
            }) {
              store[note.atomId] = note;
            },
        isDirty: (_) => false,
        setSaveState:
            (nextState, {preserveError = false, showSavedBadge = false}) {},
        setSaveError: (_) {},

        onActiveNoteUpdated: ({required atomId, required note}) {
          store[atomId] = note;
        },
      );
      addTearDown(manager.dispose);

      final first = manager.addTagToActiveNote('work');
      final second = manager.removeTagFromActiveNote('seed');

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, <String>['first']);

      var waitDone = false;
      final waitFuture = manager
          .waitForAtomTagMutations('note-1')
          .then((_) => waitDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(waitDone, isFalse);

      firstGate.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      await waitFuture;

      expect(calls, <String>['first', 'second']);
      expect(store['note-1']!.tags, <String>['work']);
    },
  );

  test(
    'error path returns false and queue can continue with next mutation',
    () async {
      final store = <String, rust_api.AtomListItem>{
        'note-1': _note(
          atomId: 'note-1',
          content: '# Seed',
          updatedAt: 1,
          tags: const ['seed'],
        ),
      };
      var callCount = 0;
      final saveStates = <NoteSaveState>[];
      final saveErrors = <String?>[];

      final manager = NoteTagManager(
        tagsListInvoker: () async {
          return rust_api.TagsListResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            tags: store['note-1']!.tags,
          );
        },
        noteSetTagsInvoker: ({required atomId, required tags}) async {
          callCount += 1;
          if (callCount == 1) {
            throw StateError('boom');
          }
          final updated = _note(
            atomId: atomId,
            content: store[atomId]!.content,
            updatedAt: store[atomId]!.updatedAt + 1,
            tags: tags,
          );
          return rust_api.AtomItemResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
            item: updated,
          );
        },
        prepare: () async {},
        envelopeError:
            ({required errorCode, required message, required fallback}) {
              return fallback;
            },
        flushPendingSave: () async => true,
        reloadNotesForFilter: ({required preserveActiveWhenFilteredOut}) async {
          return true;
        },
        activeNoteId: () => 'note-1',
        noteById: (atomId) => store[atomId],
        upsertNote:
            (
              note, {
              insertFront = false,
              updatePersisted = false,
              syncVisibleList = true,
            }) {
              store[note.atomId] = note;
            },
        isDirty: (_) => false,
        setSaveState:
            (nextState, {preserveError = false, showSavedBadge = false}) {
              saveStates.add(nextState);
            },
        setSaveError: (message) {
          saveErrors.add(message);
        },

        onActiveNoteUpdated: ({required atomId, required note}) {
          store[atomId] = note;
        },
      );
      addTearDown(manager.dispose);

      final first = manager.setActiveNoteTags(const ['urgent']);
      final second = manager.setActiveNoteTags(const ['home']);

      expect(await first, isFalse);
      expect(await second, isTrue);
      expect(callCount, 2);
      expect(saveStates, contains(NoteSaveState.error));
      expect(saveErrors.last, contains('Tag update failed unexpectedly'));
    },
  );
}
