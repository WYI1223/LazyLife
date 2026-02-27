import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Platform abstraction for local notifications.
///
/// Allows different implementations (platform, mock) to be injected via DI.
abstract class ReminderService {
  /// Initialize the notification service. Safe to call multiple times.
  Future<void> initialize();

  /// Schedule a notification at [scheduledTime].
  ///
  /// [id] is a unique int identifier for this notification.
  /// Returns true if scheduling succeeded, false if skipped (e.g. past time).
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  });

  /// Cancel a scheduled notification by its int ID.
  Future<void> cancelNotification(int id);

  /// Cancel all scheduled notifications.
  Future<void> cancelAllNotifications();

  /// Show a notification immediately (for diagnostics).
  Future<bool> showNotificationNow({
    required int id,
    required String title,
    required String body,
  });

  /// Whether [initialize] has completed successfully.
  bool get isInitialized;
}

/// Default implementation using flutter_local_notifications (Windows).
///
/// On Windows debug unpackaged apps, `zonedSchedule()` can silently fail.
/// This implementation schedules in-process timers and fires `show()` when due.
class PlatformReminderService implements ReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<int, Timer> _timersById = {};
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    if (Platform.isWindows) {
      final windows = _plugin
          .resolvePlatformSpecificImplementation<
            FlutterLocalNotificationsWindows
          >();
      if (windows != null) {
        const settings = WindowsInitializationSettings(
          appName: 'LazyNote',
          appUserModelId: 'LazyNote.App',
          guid: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        );
        await windows.initialize(settings: settings);
      }
    }

    _initialized = true;
  }

  @override
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) {
      throw StateError(
        'ReminderService not initialized. Call initialize() first.',
      );
    }

    final delay = scheduledTime.difference(DateTime.now());
    if (delay <= Duration.zero) {
      return false;
    }

    _timersById.remove(id)?.cancel();
    _timersById[id] = Timer(delay, () {
      _timersById.remove(id);
      unawaited(showNotificationNow(id: id, title: title, body: body));
    });
    return true;
  }

  @override
  Future<bool> showNotificationNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      throw StateError(
        'ReminderService not initialized. Call initialize() first.',
      );
    }

    if (Platform.isWindows) {
      final windows = _plugin
          .resolvePlatformSpecificImplementation<
            FlutterLocalNotificationsWindows
          >();
      if (windows != null) {
        const details = WindowsNotificationDetails(
          scenario: WindowsNotificationScenario.reminder,
        );
        await windows.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
        );
        return true;
      }
    }

    return false;
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    _timersById.remove(id)?.cancel();

    if (Platform.isWindows) {
      final windows = _plugin
          .resolvePlatformSpecificImplementation<
            FlutterLocalNotificationsWindows
          >();
      await windows?.cancel(id: id);
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;

    for (final timer in _timersById.values) {
      timer.cancel();
    }
    _timersById.clear();

    if (Platform.isWindows) {
      final windows = _plugin
          .resolvePlatformSpecificImplementation<
            FlutterLocalNotificationsWindows
          >();
      await windows?.cancelAll();
    }
  }
}
