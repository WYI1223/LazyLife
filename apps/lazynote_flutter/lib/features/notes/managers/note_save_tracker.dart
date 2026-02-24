import 'dart:async';

import 'package:flutter/foundation.dart';

/// Save lifecycle for active note draft persistence.
enum NoteSaveState {
  /// Draft content matches persisted content.
  clean,

  /// Draft content has unsaved edits.
  dirty,

  /// Save call is currently in flight.
  saving,

  /// Last save attempt failed.
  error,
}

/// Timer factory for save-state badge scheduling.
typedef NoteSaveTimerFactory =
    Timer Function(Duration duration, void Function() callback);

/// Tracks save-state snapshots for notes editor surface.
///
/// This manager contains only local state transitions and no FFI invokers.
class NoteSaveTracker extends ChangeNotifier {
  NoteSaveTracker({NoteSaveTimerFactory? timerFactory})
    : _timerFactory = timerFactory ?? Timer.new;

  final NoteSaveTimerFactory _timerFactory;

  NoteSaveState _noteSaveState = NoteSaveState.clean;
  String? _saveErrorMessage;
  bool _showSavedBadge = false;
  Timer? _savedBadgeTimer;

  NoteSaveState get noteSaveState => _noteSaveState;

  String? get saveErrorMessage => _saveErrorMessage;

  bool get showSavedBadge => _showSavedBadge;

  void setErrorMessage(String? message, {bool notify = true}) {
    _saveErrorMessage = message;
    if (notify) {
      notifyListeners();
    }
  }

  void setState(
    NoteSaveState nextState, {
    bool preserveError = false,
    bool showSavedBadge = false,
    bool notify = true,
  }) {
    _noteSaveState = nextState;
    if (!preserveError) {
      _saveErrorMessage = null;
    }
    if (showSavedBadge) {
      _showSavedBadge = true;
      _savedBadgeTimer?.cancel();
      _savedBadgeTimer = _timerFactory(const Duration(seconds: 3), () {
        if (_noteSaveState != NoteSaveState.clean) {
          return;
        }
        _showSavedBadge = false;
        notifyListeners();
      });
    } else {
      _savedBadgeTimer?.cancel();
      _showSavedBadge = false;
    }
    if (notify) {
      notifyListeners();
    }
  }

  void reset({bool notify = true}) {
    _savedBadgeTimer?.cancel();
    _noteSaveState = NoteSaveState.clean;
    _saveErrorMessage = null;
    _showSavedBadge = false;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _savedBadgeTimer?.cancel();
    super.dispose();
  }
}
