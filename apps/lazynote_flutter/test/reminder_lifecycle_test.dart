import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/reminders/reminder_lifecycle.dart';
import 'package:lazynote_flutter/core/reminders/reminder_scheduler.dart';
import 'package:lazynote_flutter/features/calendar/calendar_controller.dart';
import 'package:lazynote_flutter/features/tasks/tasks_controller.dart';

import 'helpers/mock_reminder_service.dart';

/// Tests that verify the S7 lifecycle-driven trigger migration:
/// - View-driven `_scheduleReminders()` is removed from Tasks/Calendar
/// - Lifecycle hooks fire correctly for status toggle, event create/update
/// - `recoverOnStartup` works end-to-end
void main() {
  rust_api.AtomListItem atomItem({
    required String atomId,
    required String content,
    int? startAt,
    int? endAt,
    String? taskStatus,
  }) {
    return rust_api.AtomListItem(
      atomId: atomId,
      viewHint: 'note',
      title: content.split('\n').first,
      contentType: 'markdown',
      content: content,
      previewText: null,
      previewImage: null,
      tags: const [],
      startAt: startAt,
      endAt: endAt,
      taskStatus: taskStatus,
      updatedAt: 1000,
    );
  }

  rust_api.AtomListResponse successResponse(List<rust_api.AtomListItem> items) {
    return rust_api.AtomListResponse(
      ok: true,
      errorCode: null,
      message: 'ok',
      items: items,
      appliedLimit: 50,
    );
  }

  group('TasksController lifecycle hooks', () {
    test('toggleStatus to done calls onCancel', () async {
      final cancelledIds = <String>[];
      final scheduledIds = <String>[];
      final lifecycle = ReminderLifecycle(
        onSchedule: (id) async => scheduledIds.add(id),
        onCancel: (id) async => cancelledIds.add(id),
      );

      final controller = TasksController(
        prepare: () async {},
        inboxInvoker: ({limit, offset}) async => successResponse(const []),
        todayInvoker: ({required bodMs, required eodMs, limit, offset}) async =>
            successResponse([
              atomItem(
                atomId: 'task-1',
                content: 'Review code',
                startAt: DateTime(2026, 3, 1, 9).millisecondsSinceEpoch,
              ),
            ]),
        upcomingInvoker: ({required eodMs, limit, offset}) async =>
            successResponse(const []),
        statusInvoker: ({required atomId, status}) async {
          return rust_api.EntryActionResponse(
            ok: true,
            atomId: atomId,
            message: 'ok',
          );
        },
        reminderLifecycle: lifecycle,
      );
      addTearDown(controller.dispose);

      await controller.loadAll();
      final result = await controller.toggleStatus('task-1', null);

      expect(result, isTrue);
      expect(cancelledIds, ['task-1']);
      expect(scheduledIds, isEmpty);
    });

    test('toggleStatus to clear (un-complete) calls onSchedule', () async {
      final cancelledIds = <String>[];
      final scheduledIds = <String>[];
      final lifecycle = ReminderLifecycle(
        onSchedule: (id) async => scheduledIds.add(id),
        onCancel: (id) async => cancelledIds.add(id),
      );

      final controller = TasksController(
        prepare: () async {},
        inboxInvoker: ({limit, offset}) async => successResponse(const []),
        todayInvoker: ({required bodMs, required eodMs, limit, offset}) async =>
            successResponse([
              atomItem(
                atomId: 'task-2',
                content: 'Done task',
                taskStatus: 'done',
                startAt: DateTime(2026, 3, 1, 9).millisecondsSinceEpoch,
              ),
            ]),
        upcomingInvoker: ({required eodMs, limit, offset}) async =>
            successResponse(const []),
        statusInvoker: ({required atomId, status}) async {
          return rust_api.EntryActionResponse(
            ok: true,
            atomId: atomId,
            message: 'ok',
          );
        },
        reminderLifecycle: lifecycle,
      );
      addTearDown(controller.dispose);

      await controller.loadAll();
      final result = await controller.toggleStatus('task-2', 'done');

      expect(result, isTrue);
      expect(scheduledIds, ['task-2']);
      expect(cancelledIds, isEmpty);
    });

    test('loadAll does not trigger reminder scheduling', () async {
      final scheduledIds = <String>[];
      final cancelledIds = <String>[];
      final lifecycle = ReminderLifecycle(
        onSchedule: (id) async => scheduledIds.add(id),
        onCancel: (id) async => cancelledIds.add(id),
      );

      final controller = TasksController(
        prepare: () async {},
        inboxInvoker: ({limit, offset}) async => successResponse([
          atomItem(atomId: 'inbox-1', content: 'Timeless task'),
        ]),
        todayInvoker: ({required bodMs, required eodMs, limit, offset}) async =>
            successResponse([
              atomItem(
                atomId: 'today-1',
                content: 'Timed task',
                startAt: DateTime(2026, 3, 1, 9).millisecondsSinceEpoch,
              ),
            ]),
        upcomingInvoker: ({required eodMs, limit, offset}) async =>
            successResponse([
              atomItem(
                atomId: 'upcoming-1',
                content: 'Future task',
                endAt: DateTime(2026, 3, 5, 17).millisecondsSinceEpoch,
              ),
            ]),
        reminderLifecycle: lifecycle,
      );
      addTearDown(controller.dispose);

      await controller.loadAll();

      // View-driven scheduling is removed: loadAll must NOT trigger any hooks
      expect(scheduledIds, isEmpty);
      expect(cancelledIds, isEmpty);
    });

    test('lifecycle hook failure does not break toggleStatus', () async {
      final lifecycle = ReminderLifecycle(
        onSchedule: (_) async => throw Exception('Scheduler down'),
        onCancel: (_) async => throw Exception('Scheduler down'),
      );

      final controller = TasksController(
        prepare: () async {},
        inboxInvoker: ({limit, offset}) async => successResponse(const []),
        todayInvoker: ({required bodMs, required eodMs, limit, offset}) async =>
            successResponse([atomItem(atomId: 'task-x', content: 'Test')]),
        upcomingInvoker: ({required eodMs, limit, offset}) async =>
            successResponse(const []),
        statusInvoker: ({required atomId, status}) async {
          return const rust_api.EntryActionResponse(
            ok: true,
            atomId: 'task-x',
            message: 'ok',
          );
        },
        reminderLifecycle: lifecycle,
      );
      addTearDown(controller.dispose);

      await controller.loadAll();
      final result = await controller.toggleStatus('task-x', null);
      expect(result, isTrue);
    });
  });

  group('CalendarController lifecycle hooks', () {
    test('createEvent calls onSchedule with new atomId', () async {
      final scheduledIds = <String>[];
      final lifecycle = ReminderLifecycle(
        onSchedule: (id) async => scheduledIds.add(id),
        onCancel: (id) async {},
      );

      final controller = CalendarController(
        prepare: () async {},
        rangeInvoker:
            ({required startMs, required endMs, limit, offset}) async =>
                successResponse(const []),
        scheduleInvoker:
            ({required title, required startEpochMs, endEpochMs}) async {
              return const rust_api.EntryActionResponse(
                ok: true,
                atomId: 'new-evt-1',
                message: 'ok',
              );
            },
        reminderLifecycle: lifecycle,
      );

      await controller.createEvent(
        'Meeting',
        DateTime(2026, 3, 1, 14).millisecondsSinceEpoch,
        DateTime(2026, 3, 1, 15).millisecondsSinceEpoch,
      );

      expect(scheduledIds, ['new-evt-1']);
    });

    test('updateEvent calls onSchedule with atomId', () async {
      final scheduledIds = <String>[];
      final lifecycle = ReminderLifecycle(
        onSchedule: (id) async => scheduledIds.add(id),
        onCancel: (id) async {},
      );

      final controller = CalendarController(
        prepare: () async {},
        rangeInvoker:
            ({required startMs, required endMs, limit, offset}) async =>
                successResponse(const []),
        updateEventInvoker:
            ({required atomId, required startMs, required endMs}) async {
              return rust_api.EntryActionResponse(
                ok: true,
                atomId: atomId,
                message: 'ok',
              );
            },
        reminderLifecycle: lifecycle,
      );

      await controller.updateEvent(
        'evt-1',
        DateTime(2026, 3, 1, 14).millisecondsSinceEpoch,
        DateTime(2026, 3, 1, 15).millisecondsSinceEpoch,
      );

      expect(scheduledIds, ['evt-1']);
    });

    test('loadWeek does not trigger reminder scheduling', () async {
      final scheduledIds = <String>[];
      final lifecycle = ReminderLifecycle(
        onSchedule: (id) async => scheduledIds.add(id),
        onCancel: (id) async {},
      );

      final controller = CalendarController(
        prepare: () async {},
        rangeInvoker:
            ({required startMs, required endMs, limit, offset}) async =>
                successResponse([
                  atomItem(
                    atomId: 'evt-week',
                    content: 'Event in week',
                    startAt: DateTime(2026, 3, 1, 9).millisecondsSinceEpoch,
                    endAt: DateTime(2026, 3, 1, 10).millisecondsSinceEpoch,
                  ),
                ]),
        reminderLifecycle: lifecycle,
      );

      await controller.loadWeek();

      // View-driven scheduling is removed: loadWeek must NOT trigger any hooks
      expect(scheduledIds, isEmpty);
    });

    test('lifecycle hook failure does not break createEvent', () async {
      final lifecycle = ReminderLifecycle(
        onSchedule: (_) async => throw Exception('Scheduler down'),
        onCancel: (_) async => throw Exception('Scheduler down'),
      );

      final controller = CalendarController(
        prepare: () async {},
        rangeInvoker:
            ({required startMs, required endMs, limit, offset}) async =>
                successResponse(const []),
        scheduleInvoker:
            ({required title, required startEpochMs, endEpochMs}) async {
              return const rust_api.EntryActionResponse(
                ok: true,
                atomId: 'new-evt',
                message: 'ok',
              );
            },
        reminderLifecycle: lifecycle,
      );

      final result = await controller.createEvent(
        'Test',
        DateTime(2026, 3, 1, 14).millisecondsSinceEpoch,
        DateTime(2026, 3, 1, 15).millisecondsSinceEpoch,
      );

      expect(result, isTrue);
    });
  });

  group('ReminderLifecycle static instance', () {
    tearDown(() {
      ReminderLifecycle.resetForTesting();
    });

    test('defaults to noop', () async {
      ReminderLifecycle.resetForTesting();
      // noop should not throw
      await ReminderLifecycle.instance.onSchedule('any-id');
      await ReminderLifecycle.instance.onCancel('any-id');
    });

    test('initialize sets instance', () async {
      final calls = <String>[];
      ReminderLifecycle.initialize(
        ReminderLifecycle(
          onSchedule: (id) async => calls.add('schedule:$id'),
          onCancel: (id) async => calls.add('cancel:$id'),
        ),
      );

      await ReminderLifecycle.instance.onSchedule('atom-1');
      await ReminderLifecycle.instance.onCancel('atom-2');

      expect(calls, ['schedule:atom-1', 'cancel:atom-2']);
    });

    test('resetForTesting reverts to noop', () async {
      final calls = <String>[];
      ReminderLifecycle.initialize(
        ReminderLifecycle(
          onSchedule: (id) async => calls.add('schedule:$id'),
          onCancel: (id) async {},
        ),
      );

      ReminderLifecycle.resetForTesting();
      await ReminderLifecycle.instance.onSchedule('atom-1');

      expect(calls, isEmpty);
    });
  });

  group('ReminderScheduler.recoverOnStartup', () {
    late MockReminderService mockService;

    setUp(() async {
      mockService = MockReminderService();
      ReminderScheduler.setServiceForTesting(mockService);
      await ReminderScheduler.ensureInitialized();
    });

    tearDown(() {
      ReminderScheduler.resetForTesting();
    });

    test('schedules reminders for all returned timed atoms', () async {
      final timedAtoms = [
        atomItem(
          atomId: 'timed-1',
          content: 'DDL task',
          endAt: DateTime(2026, 3, 5, 17).millisecondsSinceEpoch,
        ),
        atomItem(
          atomId: 'timed-2',
          content: 'Event',
          startAt: DateTime(2026, 3, 5, 14).millisecondsSinceEpoch,
          endAt: DateTime(2026, 3, 5, 15).millisecondsSinceEpoch,
        ),
      ];

      await ReminderScheduler.recoverOnStartup(
        timedInvoker: () async => successResponse(timedAtoms),
      );

      expect(mockService.scheduled.length, 2);
    });

    test('skips scheduling when response is not ok', () async {
      await ReminderScheduler.recoverOnStartup(
        timedInvoker: () async => rust_api.AtomListResponse(
          ok: false,
          errorCode: 'db_error',
          message: 'DB not ready',
          items: const [],
          appliedLimit: 0,
        ),
      );

      expect(mockService.scheduled.length, 0);
    });

    test('handles empty timed atom list gracefully', () async {
      await ReminderScheduler.recoverOnStartup(
        timedInvoker: () async => successResponse(const []),
      );

      expect(mockService.scheduled.length, 0);
    });
  });
}
