import 'package:flutter/foundation.dart';

/// Lifecycle callback interface for reminder scheduling.
///
/// Feature controllers inject this to trigger reminder schedule/cancel
/// without directly importing [ReminderScheduler] or [ReminderService].
/// This satisfies the S7 ruling (Atom lifecycle triggers) and DI-7 Gate A
/// (Tasks/Calendar zero references to ReminderScheduler).
///
/// Initialized in `main.dart` via [initialize]; controllers default to
/// [instance] when no explicit lifecycle is injected.
class ReminderLifecycle {
  /// Called after atom creation or time-field mutation.
  /// Implementation fetches the full atom via FFI and schedules a reminder.
  final Future<void> Function(String atomId) onSchedule;

  /// Called when an atom is completed, cancelled, or soft-deleted.
  /// Implementation cancels any pending reminder for the atom.
  final Future<void> Function(String atomId) onCancel;

  const ReminderLifecycle({required this.onSchedule, required this.onCancel});

  /// No-op instance for testing or when reminders are disabled.
  static final noop = ReminderLifecycle(
    onSchedule: (_) async {},
    onCancel: (_) async {},
  );

  /// Process-level instance, initialized once in `main.dart`.
  /// Defaults to [noop] until [initialize] is called.
  static ReminderLifecycle _instance = noop;

  /// The active lifecycle instance for production controllers.
  static ReminderLifecycle get instance => _instance;

  /// Sets the process-level lifecycle instance. Call once in `main.dart`.
  static void initialize(ReminderLifecycle lifecycle) {
    _instance = lifecycle;
  }

  /// Resets to [noop] for testing.
  @visibleForTesting
  static void resetForTesting() {
    _instance = noop;
  }
}
