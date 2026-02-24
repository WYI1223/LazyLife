import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/notes/managers/note_save_tracker.dart';

void main() {
  test('can be instantiated independently with clean initial state', () {
    final tracker = NoteSaveTracker();
    addTearDown(tracker.dispose);

    expect(tracker.noteSaveState, NoteSaveState.clean);
    expect(tracker.saveErrorMessage, isNull);
    expect(tracker.showSavedBadge, isFalse);
  });

  test('preserves and clears error state as requested', () {
    final tracker = NoteSaveTracker();
    addTearDown(tracker.dispose);

    tracker.setErrorMessage('save failed');
    tracker.setState(NoteSaveState.error, preserveError: true);
    expect(tracker.saveErrorMessage, 'save failed');

    tracker.setState(NoteSaveState.clean);
    expect(tracker.saveErrorMessage, isNull);
  });

  test('can schedule and reset saved badge visibility', () {
    final tracker = NoteSaveTracker();
    addTearDown(tracker.dispose);

    tracker.setState(NoteSaveState.clean, showSavedBadge: true);
    expect(tracker.showSavedBadge, isTrue);

    tracker.reset();
    expect(tracker.noteSaveState, NoteSaveState.clean);
    expect(tracker.showSavedBadge, isFalse);
  });
}
