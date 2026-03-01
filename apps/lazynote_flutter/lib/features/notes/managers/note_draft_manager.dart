import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/managers/note_save_tracker.dart';

typedef DraftNoteUpdateInvoker =
    Future<rust_api.AtomItemResponse> Function({
      required String atomId,
      required String content,
    });

typedef DraftPrepare = Future<void> Function();

typedef DraftTimerFactory =
    Timer Function(Duration duration, void Function() callback);

typedef DraftActiveNoteIdReader = String? Function();

typedef DraftNoteLookup = rust_api.AtomListItem? Function(String atomId);

typedef DraftCopyWithContent =
    rust_api.AtomListItem Function(
      rust_api.AtomListItem current,
      String content,
    );

typedef DraftUpsertNote =
    void Function(
      rust_api.AtomListItem note, {
      bool insertFront,
      bool updatePersisted,
      bool syncVisibleList,
    });

typedef DraftEnvelopeError =
    String Function({
      required String? errorCode,
      required String message,
      required String fallback,
    });

typedef DraftApplySaveState =
    void Function(
      NoteSaveState nextState, {
      bool preserveError,
      bool showSavedBadge,
    });

typedef DraftSetSaveError = void Function(String? message);

typedef DraftActiveSaveHook = void Function(String atomId);

class NoteDraftManager extends ChangeNotifier {
  NoteDraftManager({
    required DraftNoteUpdateInvoker noteUpdateInvoker,
    required DraftPrepare prepare,
    required DraftActiveNoteIdReader activeNoteId,
    required DraftNoteLookup noteById,
    required DraftCopyWithContent withContent,
    required DraftUpsertNote upsertNote,
    required DraftEnvelopeError envelopeError,
    required DraftApplySaveState applySaveState,
    required DraftSetSaveError setSaveError,
    DraftActiveSaveHook? onActiveSaveSuccess,
    DraftTimerFactory? timerFactory,
    this.autosaveDebounce = const Duration(milliseconds: 1500),
  }) : _noteUpdateInvoker = noteUpdateInvoker,
       _prepare = prepare,
       _activeNoteId = activeNoteId,
       _noteById = noteById,
       _withContent = withContent,
       _upsertNote = upsertNote,
       _envelopeError = envelopeError,
       _applySaveState = applySaveState,
       _setSaveError = setSaveError,
       _onActiveSaveSuccess = onActiveSaveSuccess,
       _timerFactory = timerFactory ?? Timer.new;

  final DraftNoteUpdateInvoker _noteUpdateInvoker;
  final DraftPrepare _prepare;
  final DraftActiveNoteIdReader _activeNoteId;
  final DraftNoteLookup _noteById;
  final DraftCopyWithContent _withContent;
  final DraftUpsertNote _upsertNote;
  final DraftEnvelopeError _envelopeError;
  final DraftApplySaveState _applySaveState;
  final DraftSetSaveError _setSaveError;
  final DraftActiveSaveHook? _onActiveSaveSuccess;
  final DraftTimerFactory _timerFactory;

  final Map<String, String> _draftContentByAtomId = <String, String>{};
  final Map<String, String> _persistedContentByAtomId = <String, String>{};
  final Map<String, int> _draftVersionByAtomId = <String, int>{};
  final Map<String, Future<bool>> _saveFutureByAtomId =
      <String, Future<bool>>{};
  final Map<String, bool> _saveQueuedByAtomId = <String, bool>{};

  final Duration autosaveDebounce;
  String? activeDraftAtomId;
  String activeDraftContent = '';
  Timer? _autosaveTimer;

  Map<String, String> get draftContentByAtomId => _draftContentByAtomId;
  Map<String, String> get persistedContentByAtomId => _persistedContentByAtomId;
  Map<String, int> get draftVersionByAtomId => _draftVersionByAtomId;
  Map<String, Future<bool>> get saveFutureByAtomId => _saveFutureByAtomId;
  Map<String, bool> get saveQueuedByAtomId => _saveQueuedByAtomId;
  Timer? get autosaveTimer => _autosaveTimer;

  bool isDirty(String atomId) {
    final draft = _draftContentByAtomId[atomId];
    final persisted = _persistedContentByAtomId[atomId];
    if (draft == null || persisted == null) {
      return false;
    }
    return draft != persisted;
  }

  void scheduleAutosave({required String atomId, required int version}) {
    _autosaveTimer?.cancel();
    _autosaveTimer = _timerFactory(autosaveDebounce, () {
      unawaited(saveDraft(atomId: atomId, version: version));
    });
  }

  Future<bool> saveDraft({required String atomId, required int version}) {
    if (_saveFutureByAtomId[atomId] case final inFlight?) {
      _saveQueuedByAtomId[atomId] = true;
      return inFlight;
    }
    final future = _performSaveDraft(atomId: atomId, version: version)
        .whenComplete(() {
          _saveFutureByAtomId.remove(atomId);
          final shouldQueue = _saveQueuedByAtomId.remove(atomId) ?? false;
          if (shouldQueue) {
            final nextVersion = _draftVersionByAtomId[atomId] ?? 0;
            unawaited(saveDraft(atomId: atomId, version: nextVersion));
          }
        });
    _saveFutureByAtomId[atomId] = future;
    return future;
  }

  Future<bool> _performSaveDraft({
    required String atomId,
    required int version,
  }) async {
    final draft = _draftContentByAtomId[atomId];
    if (draft == null) {
      return false;
    }

    final latestVersion = _draftVersionByAtomId[atomId] ?? 0;
    final activeAtomId = _activeNoteId();
    if (version != latestVersion || !isDirty(atomId)) {
      if (activeAtomId == atomId) {
        refreshSaveStateForActive(activeNoteId: activeAtomId);
        notifyListeners();
      }
      return false;
    }

    if (activeAtomId == atomId) {
      _applySaveState(NoteSaveState.saving);
      notifyListeners();
    }

    try {
      await _prepare();
      final response = await _noteUpdateInvoker(atomId: atomId, content: draft);
      final currentVersion = _draftVersionByAtomId[atomId] ?? 0;
      final currentActiveAtomId = _activeNoteId();
      if (version != currentVersion) {
        if (currentActiveAtomId == atomId) {
          refreshSaveStateForActive(activeNoteId: currentActiveAtomId);
          notifyListeners();
        }
        return false;
      }

      if (!response.ok) {
        if (currentActiveAtomId == atomId) {
          _setSaveError(
            _envelopeError(
              errorCode: response.errorCode,
              message: response.message,
              fallback: 'Failed to save note.',
            ),
          );
          _applySaveState(NoteSaveState.error, preserveError: true);
          notifyListeners();
        }
        return false;
      }

      final saved =
          response.item ??
          (switch (_noteById(atomId)) {
            final rust_api.AtomListItem current => _withContent(current, draft),
            _ => null,
          });
      if (saved == null) {
        if (currentActiveAtomId == atomId) {
          _setSaveError('Save succeeded without note payload.');
          _applySaveState(NoteSaveState.error, preserveError: true);
          notifyListeners();
        }
        return false;
      }

      _upsertNote(saved, updatePersisted: true);
      if (currentActiveAtomId == atomId) {
        _onActiveSaveSuccess?.call(atomId);
        activeDraftContent = _draftContentByAtomId[atomId] ?? draft;
        if (isDirty(atomId)) {
          _applySaveState(NoteSaveState.dirty);
        } else {
          _applySaveState(NoteSaveState.clean, showSavedBadge: true);
        }
        notifyListeners();
      }
      return true;
    } catch (error) {
      final currentVersion = _draftVersionByAtomId[atomId] ?? 0;
      final currentActiveAtomId = _activeNoteId();
      if (version != currentVersion) {
        if (currentActiveAtomId == atomId) {
          refreshSaveStateForActive(activeNoteId: currentActiveAtomId);
          notifyListeners();
        }
        return false;
      }
      if (currentActiveAtomId == atomId) {
        _setSaveError('Save failed unexpectedly: $error');
        _applySaveState(NoteSaveState.error, preserveError: true);
        notifyListeners();
      }
      return false;
    }
  }

  void refreshSaveStateForActive({required String? activeNoteId}) {
    if (activeNoteId == null) {
      _autosaveTimer?.cancel();
      _applySaveState(NoteSaveState.clean);
      return;
    }
    if (isDirty(activeNoteId)) {
      _applySaveState(NoteSaveState.dirty);
      return;
    }
    _applySaveState(NoteSaveState.clean);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }
}
