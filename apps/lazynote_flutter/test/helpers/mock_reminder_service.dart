import 'package:lazynote_flutter/features/reminders/reminder_service.dart';

/// Mock implementation for unit testing.
class MockReminderService implements ReminderService {
  bool _initialized = false;
  final Map<int, ScheduledNotification> _scheduled = {};

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    _scheduled[id] = ScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
    return true;
  }

  @override
  Future<void> cancelNotification(int id) async {
    _scheduled.remove(id);
  }

  @override
  Future<bool> showNotificationNow({
    required int id,
    required String title,
    required String body,
  }) async {
    return true;
  }

  @override
  Future<void> cancelAllNotifications() async {
    _scheduled.clear();
  }

  List<ScheduledNotification> get scheduled => _scheduled.values.toList();
}

/// Scheduled notification record (exposed for testing).
class ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;

  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
  });
}
