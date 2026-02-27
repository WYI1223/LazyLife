import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/managers/note_save_tracker.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tag_manager_types.dart';
import 'package:lazynote_flutter/features/notes/managers/note_tag_mutation_queue.dart';

export 'note_tag_manager_types.dart' show NoteSetTagsInvoker, TagsListInvoker;

class NoteTagManager extends ChangeNotifier {
  NoteTagManager({
    required TagsListInvoker tagsListInvoker,
    required NoteSetTagsInvoker noteSetTagsInvoker,
    required TagPrepare prepare,
    required TagEnvelopeError envelopeError,
    required TagFlushPendingSave flushPendingSave,
    required TagReloadNotesForFilter reloadNotesForFilter,
    required TagActiveNoteIdReader activeNoteId,
    required TagNoteLookup noteById,
    required TagUpsertNote upsertNote,
    required TagIsDirtyReader isDirty,
    required TagSetSaveState setSaveState,
    required TagSetSaveError setSaveError,
    required TagOnActiveNoteUpdated onActiveNoteUpdated,
  }) : _tagsListInvoker = tagsListInvoker,
       _noteSetTagsInvoker = noteSetTagsInvoker,
       _prepare = prepare,
       _envelopeError = envelopeError,
       _flushPendingSave = flushPendingSave,
       _reloadNotesForFilter = reloadNotesForFilter,
       _activeNoteId = activeNoteId,
       _noteById = noteById,
       _upsertNote = upsertNote,
       _isDirty = isDirty,
       _setSaveState = setSaveState,
       _setSaveError = setSaveError,
       _onActiveNoteUpdated = onActiveNoteUpdated;

  final TagsListInvoker _tagsListInvoker;
  final NoteSetTagsInvoker _noteSetTagsInvoker;
  final TagPrepare _prepare;
  final TagEnvelopeError _envelopeError;
  final TagFlushPendingSave _flushPendingSave;
  final TagReloadNotesForFilter _reloadNotesForFilter;
  final TagActiveNoteIdReader _activeNoteId;
  final TagNoteLookup _noteById;
  final TagUpsertNote _upsertNote;
  final TagIsDirtyReader _isDirty;
  final TagSetSaveState _setSaveState;
  final TagSetSaveError _setSaveError;
  final TagOnActiveNoteUpdated _onActiveNoteUpdated;

  final NoteTagMutationQueue _mutationQueue = NoteTagMutationQueue();
  bool _tagsLoading = false;
  List<String> _availableTags = const [];
  String? _tagsErrorMessage;
  String? _selectedTag;
  int _tagsRequestId = 0;

  bool get tagsLoading => _tagsLoading;
  List<String> get availableTags => List.unmodifiable(_availableTags);
  String? get tagsErrorMessage => _tagsErrorMessage;
  String? get selectedTag => _selectedTag;

  Future<bool> applyTagFilter(String rawTag) async {
    final normalized = _normalizeTag(rawTag);
    if (normalized == null) {
      return false;
    }
    if (_selectedTag == normalized) {
      return true;
    }
    if (_activeNoteId() != null) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }
    _selectedTag = normalized;
    notifyListeners();
    return _reloadNotesForFilter(preserveActiveWhenFilteredOut: false);
  }

  Future<bool> clearTagFilter() async {
    if (_selectedTag == null) {
      return true;
    }
    if (_activeNoteId() != null) {
      final flushed = await _flushPendingSave();
      if (!flushed) {
        return false;
      }
    }
    _selectedTag = null;
    notifyListeners();
    return _reloadNotesForFilter(preserveActiveWhenFilteredOut: false);
  }

  Future<void> refreshAvailableTags({bool showLoading = true}) async {
    final requestId = ++_tagsRequestId;
    if (showLoading) {
      _tagsLoading = true;
      _tagsErrorMessage = null;
      notifyListeners();
    }
    try {
      await _prepare();
      if (requestId != _tagsRequestId) {
        return;
      }
      final response = await _tagsListInvoker();
      if (requestId != _tagsRequestId) {
        return;
      }
      if (!response.ok) {
        _tagsLoading = false;
        _tagsErrorMessage = _envelopeError(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to load tags.',
        );
        notifyListeners();
        return;
      }

      final normalizedTags = List<String>.unmodifiable(
        _normalizeTags(response.tags),
      );
      _availableTags = normalizedTags;
      _tagsLoading = false;
      _tagsErrorMessage = null;
      notifyListeners();

      final staleSelectedTag = _selectedTag;
      if (staleSelectedTag != null &&
          !normalizedTags.contains(staleSelectedTag)) {
        _selectedTag = null;
        notifyListeners();
        await _reloadNotesForFilter(preserveActiveWhenFilteredOut: false);
      }
    } catch (error) {
      if (requestId != _tagsRequestId) {
        return;
      }
      _tagsLoading = false;
      _tagsErrorMessage = 'Tags load failed unexpectedly: $error';
      notifyListeners();
    }
  }

  Future<bool> setActiveNoteTags(List<String> rawTags) async {
    final atomId = _activeNoteId();
    if (atomId == null) {
      return false;
    }
    final normalized = _normalizeTags(rawTags);
    return _mutationQueue.enqueue(
      atomId: atomId,
      mutation: () => _setNoteTags(atomId: atomId, normalizedTags: normalized),
    );
  }

  Future<bool> addTagToActiveNote(String tag) async {
    final normalized = _normalizeTag(tag);
    if (normalized == null) {
      return false;
    }
    final atomId = _activeNoteId();
    if (atomId == null) {
      return false;
    }
    return _mutationQueue.enqueue(
      atomId: atomId,
      mutation: () async {
        final current = _noteById(atomId);
        if (current == null || current.tags.contains(normalized)) {
          return current != null;
        }
        return _setNoteTags(
          atomId: atomId,
          normalizedTags: _normalizeTags(<String>[...current.tags, normalized]),
        );
      },
    );
  }

  Future<bool> removeTagFromActiveNote(String tag) async {
    final normalized = _normalizeTag(tag);
    if (normalized == null) {
      return false;
    }
    final atomId = _activeNoteId();
    if (atomId == null) {
      return false;
    }
    return _mutationQueue.enqueue(
      atomId: atomId,
      mutation: () async {
        final current = _noteById(atomId);
        if (current == null || !current.tags.contains(normalized)) {
          return current != null;
        }
        final next = current.tags
            .where((entry) => entry != normalized)
            .toList();
        return _setNoteTags(
          atomId: atomId,
          normalizedTags: _normalizeTags(next),
        );
      },
    );
  }

  bool shouldIncludeInVisibleList(rust_api.NoteItem note) {
    final selected = _selectedTag;
    if (selected == null) {
      return true;
    }
    return note.tags.contains(selected);
  }

  bool hasPendingTagWorkFor(String atomId) {
    return _mutationQueue.hasPendingFor(atomId);
  }

  Future<void> waitForAtomTagMutations(String atomId) {
    return _mutationQueue.waitForAtom(atomId);
  }

  Future<void> awaitPendingTagMutations() {
    return _mutationQueue.waitForAll();
  }

  void clearStateForDeletedAtom(String atomId) {
    _mutationQueue.clearForAtom(atomId);
  }

  void resetMutationState() {
    _mutationQueue.reset();
  }

  Future<bool> _setNoteTags({
    required String atomId,
    required List<String> normalizedTags,
  }) async {
    final current = _noteById(atomId);
    if (current == null || listEquals(current.tags, normalizedTags)) {
      return current != null;
    }

    _mutationQueue.beginInFlight(atomId);
    _setSaveState(NoteSaveState.saving);
    notifyListeners();
    try {
      await _prepare();
      final response = await _noteSetTagsInvoker(
        atomId: atomId,
        tags: normalizedTags,
      );
      if (!response.ok) {
        _setSaveError(
          _envelopeError(
            errorCode: response.errorCode,
            message: response.message,
            fallback: 'Failed to update note tags.',
          ),
        );
        _setSaveState(NoteSaveState.error, preserveError: true);
        notifyListeners();
        return false;
      }
      final updated = response.note;
      if (updated == null) {
        _setSaveError('Tag update succeeded without note payload.');
        _setSaveState(NoteSaveState.error, preserveError: true);
        notifyListeners();
        return false;
      }

      _upsertNote(updated, updatePersisted: true);
      if (_activeNoteId() == atomId) {
        _onActiveNoteUpdated(atomId: atomId, note: updated);
        if (_isDirty(atomId)) {
          _setSaveState(NoteSaveState.dirty);
        } else {
          _setSaveState(NoteSaveState.clean, showSavedBadge: true);
        }
      }
      notifyListeners();
      await refreshAvailableTags(showLoading: false);

      final activeTag = _selectedTag;
      if (activeTag != null && !updated.tags.contains(activeTag)) {
        await _reloadNotesForFilter(preserveActiveWhenFilteredOut: true);
      }
      return true;
    } catch (error) {
      _setSaveError('Tag update failed unexpectedly: $error');
      _setSaveState(NoteSaveState.error, preserveError: true);
      notifyListeners();
      return false;
    } finally {
      _mutationQueue.endInFlight(atomId);
    }
  }

  String? _normalizeTag(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  List<String> _normalizeTags(List<String> rawTags) {
    final set = SplayTreeSet<String>();
    for (final tag in rawTags) {
      final normalized = _normalizeTag(tag);
      if (normalized != null) {
        set.add(normalized);
      }
    }
    return List<String>.unmodifiable(set);
  }
}
