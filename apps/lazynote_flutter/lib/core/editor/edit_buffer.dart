// Per-atom self-contained content state machine.
//
// Unifies the former NoteDraftManager + NoteSaveTracker into a single
// entity, eliminating state duplication. Manages content, dirty detection,
// and save orchestration with debounced auto-save.
//
// PR-RB-06: First landing of core/editor/ infrastructure.
// Design sources: DI-1 Q3, DI-4 D10/D11/D12, S2 EditBuffer section,
// edit-buffer module spec.
import 'dart:async';

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// AtomNotFoundException — loading failure convention (DI-4 Q4)
// ---------------------------------------------------------------------------

/// Thrown when a buffer load fails because the atom no longer exists in DB.
///
/// Coordinator-injected [loadContentFn] should throw this when `atom_get`
/// returns null. [EditorShellService] handles it by removing the tab from
/// all groups (PR-RB-08 T7).
class AtomNotFoundException implements Exception {
  const AtomNotFoundException(this.atomId);
  final String atomId;

  @override
  String toString() => 'AtomNotFoundException: $atomId';
}

// ---------------------------------------------------------------------------
// BufferPhase — lifecycle gate
// ---------------------------------------------------------------------------

/// Lifecycle phase of an [EditBuffer].
enum BufferPhase {
  /// Content is being loaded from storage.
  loading,

  /// Content loaded and editable.
  ready,

  /// Loading or save failed; supports retry.
  error,

  /// Terminal state — buffer is being cleaned up.
  disposing,
}

// ---------------------------------------------------------------------------
// SaveState — derived display state
// ---------------------------------------------------------------------------

/// Derived save state for UI display. Not stored — computed from fields.
enum SaveState {
  /// Buffer is still loading content.
  loading,

  /// Content matches last saved content.
  clean,

  /// Content has unsaved edits.
  dirty,

  /// Save is in flight.
  saving,

  /// Last save attempt failed.
  error,
}

// ---------------------------------------------------------------------------
// EditOp — operation type hint (DI-4 D11 protocol)
// ---------------------------------------------------------------------------

/// Advisory edit operation hint.
///
/// v0.3: Only [SnapshotReplace] is defined. [TextDelta] and [StructuredOp]
/// are reserved for v0.4+. Callers pass null (equivalent to SnapshotReplace).
sealed class EditOp {
  const EditOp();
}

/// Full content replacement (v0.3 only implementation).
class SnapshotReplace extends EditOp {
  const SnapshotReplace();
}

// v0.4+ reserved:
// class TextDelta extends EditOp { ... }
// class StructuredOp extends EditOp { ... }

// ---------------------------------------------------------------------------
// EditBuffer
// ---------------------------------------------------------------------------

/// Per-atom content state machine with debounced auto-save.
///
/// Four-phase lifecycle: loading → ready | error → disposing.
/// Extends [ChangeNotifier] for real-time cross-pane sync (DI-4 D10).
class EditBuffer extends ChangeNotifier {
  EditBuffer({
    required this.atomId,
    required Future<bool> Function(String atomId, String content) persistFn,
    void Function(String atomId, String content)? onSaved,
    this.autosaveDebounce = const Duration(milliseconds: 1500),
    this.forceSaveInterval = const Duration(seconds: 30),
    Timer Function(Duration, void Function())? timerFactory,
  }) : _persistFn = persistFn,
       _onSaved = onSaved,
       _timerFactory = timerFactory ?? Timer.new;

  /// Identity (immutable).
  final String atomId;

  /// Debounce duration for idle auto-save.
  final Duration autosaveDebounce;

  /// Maximum interval between saves during continuous editing.
  final Duration forceSaveInterval;

  // ── Injected closures ────────────────────────────────────────────────

  final Future<bool> Function(String atomId, String content) _persistFn;
  final void Function(String atomId, String content)? _onSaved;
  final Timer Function(Duration, void Function()) _timerFactory;

  // ── State fields ─────────────────────────────────────────────────────

  BufferPhase _phase = BufferPhase.loading;
  String _content = '';
  String _lastSavedContent = '';
  int _rev = 0;
  String? _errorMessage;

  // ── Save orchestration ───────────────────────────────────────────────

  Timer? _debounceTimer;
  Timer? _forceTimer;
  Future<bool>? _saveFuture;
  bool _saveQueued = false;

  // ── Public accessors ─────────────────────────────────────────────────

  /// Current lifecycle phase.
  BufferPhase get phase => _phase;

  /// Current content.
  String get content => _content;

  /// Content at last successful save.
  String get lastSavedContent => _lastSavedContent;

  /// Monotonic edit revision (incremented on each [edit] call).
  int get rev => _rev;

  /// Error message from loading or save failure.
  String? get errorMessage => _errorMessage;

  /// Whether content differs from last saved content.
  bool get isDirty => _content != _lastSavedContent;

  /// Derived save state for UI display (DI-1: getter, not stored).
  SaveState get saveState {
    if (_phase == BufferPhase.loading) return SaveState.loading;
    if (_phase == BufferPhase.error) return SaveState.error;
    if (_saveFuture != null) return SaveState.saving;
    if (_errorMessage != null) return SaveState.error;
    if (isDirty) return SaveState.dirty;
    return SaveState.clean;
  }

  // ── State transitions ────────────────────────────────────────────────

  /// Transitions from loading → ready with the loaded content.
  void initialize(String loadedContent) {
    if (_phase != BufferPhase.loading) return;
    _content = loadedContent;
    _lastSavedContent = loadedContent;
    _errorMessage = null;
    _phase = BufferPhase.ready;
    notifyListeners();
  }

  /// Transitions from loading → error.
  void markError(String message) {
    if (_phase != BufferPhase.loading) return;
    _errorMessage = message;
    _phase = BufferPhase.error;
    notifyListeners();
  }

  /// Transitions from error → loading for retry.
  void retry() {
    if (_phase != BufferPhase.error) return;
    _errorMessage = null;
    _phase = BufferPhase.loading;
    notifyListeners();
  }

  // ── Edit ─────────────────────────────────────────────────────────────

  /// Applies an edit. Only effective in [BufferPhase.ready].
  ///
  /// Increments [_rev], updates content, and schedules debounced save.
  /// [op] is reserved for v0.4+ — v0.3 callers pass null.
  void edit(String newContent, {EditOp? op}) {
    if (_phase != BufferPhase.ready) return;
    if (_content == newContent) return;

    _content = newContent;
    _rev++;
    _errorMessage = null;
    notifyListeners();
    _scheduleSave();
  }

  // ── Save ─────────────────────────────────────────────────────────────

  /// Immediately flushes pending changes and waits for completion.
  ///
  /// If a save is already in flight (e.g., from debounce timer), waits for
  /// it to complete before attempting another save if still dirty.
  Future<void> flush() async {
    _debounceTimer?.cancel();
    _forceTimer?.cancel();
    // Wait for in-flight save (including recursive queue processing)
    while (_saveFuture != null) {
      try {
        await _saveFuture;
      } catch (_) {
        break;
      }
    }
    if (!isDirty) return;
    await _executeSave();
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = _timerFactory(autosaveDebounce, () {
      _executeSave();
    });

    // Force save timer: ensure saves happen even during continuous typing
    _forceTimer ??= _timerFactory(forceSaveInterval, () {
      _forceTimer = null;
      if (isDirty) {
        _debounceTimer?.cancel();
        _executeSave();
      }
    });
  }

  Future<void> _executeSave() async {
    if (!isDirty || _phase != BufferPhase.ready) return;

    // If a save is already in flight, queue the next one
    if (_saveFuture != null) {
      _saveQueued = true;
      return;
    }

    final contentToSave = _content;

    final future = _persistFn(atomId, contentToSave);
    _saveFuture = future;

    notifyListeners(); // Transition to SaveState.saving

    try {
      final success = await future;
      _saveFuture = null;

      if (success) {
        _lastSavedContent = contentToSave;
        _errorMessage = null;
        _onSaved?.call(atomId, contentToSave);
      } else {
        _errorMessage = 'Save returned false';
      }
    } catch (e) {
      _saveFuture = null;
      _errorMessage = 'Save failed: $e';
    }

    // Cancel force timer — save cycle completed (success or failure)
    _forceTimer?.cancel();
    _forceTimer = null;

    notifyListeners();

    // Process queued save
    if (_saveQueued) {
      _saveQueued = false;
      await _executeSave();
    }
  }

  // ── Dispose ──────────────────────────────────────────────────────────

  @override
  void dispose() {
    _phase = BufferPhase.disposing;
    _debounceTimer?.cancel();
    _forceTimer?.cancel();
    super.dispose();
  }
}
