import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/reminders/reminder_service.dart';

/// Process-level singleton that manages reminders for timed atoms.
///
/// Follows the same static-singleton pattern as [RustBridge].
/// Both TasksController and CalendarController share this instance so that
/// reminders are not mutually overwritten.
///
/// Reminder timing is derived from atom time-matrix fields:
/// - `[NULL, Value]` DDL task: remind before `end_at` (default: 15 min)
/// - `[Value, NULL]` Ongoing task: remind at `start_at`
/// - `[Value, Value]` Event: remind before `start_at` (default: 15 min)
/// - `[NULL, NULL]` Timeless atom: no reminder
class ReminderScheduler {
  ReminderScheduler._();

  static ReminderService _service = PlatformReminderService();
  static bool _initialized = false;
  static Future<void>? _initFuture;

  /// Tracks scheduled notification int IDs per atom, so we can cancel
  /// previous reminders for an atom before re-scheduling.
  static final Map<String, int> _atomNotificationIds = {};

  /// Default reminder lead time (minutes before trigger time).
  static const defaultLeadTimeMinutes = 15;

  /// Initialize the underlying notification service. Safe to call concurrently.
  static Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    final inFlight = _initFuture;
    if (inFlight != null) return inFlight;
    final future = _initInternal();
    _initFuture = future;
    return future;
  }

  static Future<void> _initInternal() async {
    try {
      await _service.initialize();
      _initialized = true;
    } catch (e) {
      // Clear future so next call can retry instead of re-throwing cached error
      _initFuture = null;
      rethrow;
    }
  }

  /// Schedule reminders for a list of atoms.
  ///
  /// Each atom's previous reminder (if any) is cancelled before scheduling
  /// the new one. This avoids the cancelAll problem where two controllers
  /// would wipe each other's reminders.
  static Future<void> scheduleRemindersForAtoms(
    List<rust_api.AtomListItem> atoms,
  ) async {
    if (!_initialized) {
      await ensureInitialized();
    }

    for (final atom in atoms) {
      final reminderTime = _computeReminderTime(atom);
      if (reminderTime == null) {
        continue;
      }

      // Cancel previous reminder for this atom if exists
      await cancelReminderForAtom(atom.atomId);

      final notificationId = _stableNotificationId(atom.atomId, reminderTime);
      _atomNotificationIds[atom.atomId] = notificationId;

      final title = _reminderTitle(atom);
      final body = _reminderBody(atom);

      await _service.scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: reminderTime,
      );
    }
  }

  /// Cancel the reminder for a specific atom.
  static Future<void> cancelReminderForAtom(String atomId) async {
    if (!_initialized) await ensureInitialized();
    final existingId = _atomNotificationIds.remove(atomId);
    if (existingId != null) {
      await _service.cancelNotification(existingId);
    }
  }

  /// Cancel all scheduled reminders.
  static Future<void> cancelAllReminders() async {
    if (!_initialized) await ensureInitialized();
    await _service.cancelAllNotifications();
    _atomNotificationIds.clear();
  }

  /// Generate a deterministic int32 notification ID from atom ID + time.
  static int _stableNotificationId(String atomId, DateTime reminderTime) {
    // Combine atom ID and time into a deterministic hash.
    // Using a simple but stable algorithm (FNV-1a inspired).
    var hash = 0x811c9dc5;
    for (var i = 0; i < atomId.length; i++) {
      hash ^= atomId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    hash ^= reminderTime.millisecondsSinceEpoch;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
    return hash;
  }

  /// Compute the reminder time for an atom, or null if not applicable.
  static DateTime? _computeReminderTime(rust_api.AtomListItem atom) {
    final startAt = atom.startAt;
    final endAt = atom.endAt;

    if (startAt == null && endAt == null) return null;

    // [NULL, Value] DDL task: remind before end_at
    if (startAt == null && endAt != null) {
      final deadline = DateTime.fromMillisecondsSinceEpoch(endAt.toInt());
      return deadline.subtract(const Duration(minutes: defaultLeadTimeMinutes));
    }

    // [Value, NULL] Ongoing task: remind at start_at
    if (startAt != null && endAt == null) {
      return DateTime.fromMillisecondsSinceEpoch(startAt.toInt());
    }

    // [Value, Value] Event: remind before start_at
    final eventStart = DateTime.fromMillisecondsSinceEpoch(startAt!.toInt());
    return eventStart.subtract(const Duration(minutes: defaultLeadTimeMinutes));
  }

  /// Generate reminder title from atom content (first line, max 50 chars).
  static String _reminderTitle(rust_api.AtomListItem atom) {
    final firstLine = atom.content.split('\n').first;
    return firstLine.length > 50
        ? '${firstLine.substring(0, 50)}...'
        : firstLine;
  }

  /// Generate reminder body with the actual target time (not reminder time).
  static String _reminderBody(rust_api.AtomListItem atom) {
    final startAt = atom.startAt;
    final endAt = atom.endAt;

    if (startAt == null && endAt != null) {
      final deadline = DateTime.fromMillisecondsSinceEpoch(endAt.toInt());
      return 'Deadline: ${_formatTime(deadline)}';
    } else if (startAt != null && endAt == null) {
      final start = DateTime.fromMillisecondsSinceEpoch(startAt.toInt());
      return 'Task starting: ${_formatTime(start)}';
    } else {
      final start = DateTime.fromMillisecondsSinceEpoch(startAt!.toInt());
      return 'Event starting: ${_formatTime(start)}';
    }
  }

  /// Format time for display in notification body.
  static String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Fire an immediate test notification (for diagnostics).
  /// Returns true if the notification was delivered to the OS.
  static Future<bool> showTestNotification() async {
    if (!_initialized) await ensureInitialized();
    return _service.showNotificationNow(
      id: 999999,
      title: 'LazyNote Test',
      body: 'If you see this, notifications work!',
    );
  }

  /// Replace the service implementation (for testing).
  @visibleForTesting
  static void setServiceForTesting(ReminderService service) {
    _service = service;
    _initialized = false;
    _initFuture = null;
    _atomNotificationIds.clear();
  }

  /// Reset all state (for testing).
  @visibleForTesting
  static void resetForTesting() {
    _service = PlatformReminderService();
    _initialized = false;
    _initFuture = null;
    _atomNotificationIds.clear();
  }
}
