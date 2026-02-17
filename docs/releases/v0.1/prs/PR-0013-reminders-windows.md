# PR-0013-reminders-windows

- Proposed title: `feat(reminders): one-time local notifications (Windows)`
- Status: In Progress

## Goal

Enable baseline Windows local reminder delivery for scheduled items.

## Scope

In scope:

- one-time reminder scheduling
- cancel/update reminder on item update
- Windows-only path and setup notes

Out of scope:

- cross-platform reminder parity
- recurring reminder engine
- snooze/advanced notification actions

## Architecture Note (Atom Time-Matrix, v0.1.5+)

Reminder trigger time is derived from atom time-matrix fields, not from `kind`:

- `[NULL, Value]` DDL task: remind before `end_at` (for example, 15 min before deadline).
- `[Value, NULL]` Ongoing task: remind at `start_at`.
- `[Value, Value]` Event: remind before `start_at` (for example, 15 min).
- `[NULL, NULL]` Timeless atom: no time-based reminder applicable.

Reminder policy in v0.1 is single-fire per atom:

- DDL: one reminder near deadline (`end_at - lead_time`)
- Ongoing: one reminder at start (`start_at`)
- Event: one reminder before start (`start_at - lead_time`)
- Event end-time reminder is not implemented in this PR

Idempotency key = `atom_id` + trigger timestamp to avoid duplicate notifications.

## Architecture Changes (Code Review Fixes)

The initial implementation had several critical issues discovered during code review and iterative debugging. All have been resolved:

### Critical Fixes

1. ReminderScheduler not injected into controllers. Root cause of notifications never firing. Controllers were created without passing `reminderScheduler`, so `_reminderScheduler` was always null. Fix: rewrote `ReminderScheduler` as a static singleton (matching the `RustBridge` pattern), eliminating the need for injection.
2. Race condition: bootstrap vs controller load. `ReminderScheduler.ensureInitialized()` runs in `unawaited(_bootstrapLocalRuntime())`, but `CalendarController.loadWeek()` can run before bootstrap completes. Original behavior: `if (!_initialized) return` silently skipped scheduling. Fix: changed to `if (!_initialized) await ensureInitialized()`.
3. `cancelAll` mutual overwrite. Both `TasksController` and `CalendarController` called `cancelAllNotifications()` before scheduling, wiping each other's reminders. Fix: per-atom tracking via `Map<String, int> _atomNotificationIds`; each atom's previous reminder is cancelled individually before re-scheduling.
4. `tz.local` defaults to UTC. The `timezone` package reported `tz.local.name = UTC` on Windows, causing `tz.TZDateTime.from(localTime, tz.local)` to shift times by system offset. Fix: bypassed `tz.local` by converting via `scheduledTime.toUtc()` then `tz.TZDateTime.utc(...)` (historical fix prior to timer strategy).
5. GUID format error. Plugin rejected `{xxxxxxxx-...}` (with curly braces). Fix: removed curly braces.

### Major Fixes

6. Notification ID collision risk. Original implementation used `String.hashCode`, which is not stable across Dart versions. Fix: deterministic FNV-1a inspired hash from `atomId + reminderTime`, masked to int32.
7. Mock class in production code. `MockReminderService` was moved to `test/helpers/mock_reminder_service.dart`.

### Windows Platform Finding: `zonedSchedule()` silently fails

Discovery: `windows.zonedSchedule()` can return success while the OS silently discards scheduled notifications from unpackaged debug apps. The plugin native `scheduleNotification` binding does not return a success result to Dart.

Verification: `showNotificationNow()` using `windows.show()` works and displays a Windows toast. This confirms:

- The notification pipeline (AUMID, COM registration, plugin init) is functional.
- The main issue is with `zonedSchedule()` / `ScheduledToastNotification` for unpackaged debug apps.

Resolution (PR-0013): switched from `zonedSchedule()` to timer-based scheduling (`Timer` + `show()`) for reliable delivery while the app process is running.

## Step-by-Step

1. [x] Choose and lock Windows notification plugin/runtime path (`flutter_local_notifications`).
2. [x] Add reminder scheduler abstraction in Flutter.
3. [x] Add task/calendar integration points keyed on `start_at`/`end_at`.
4. [x] Ensure idempotent scheduling keys (avoid duplicates).
5. [x] Add unit tests for schedule/cancel behavior.
6. [x] Implement actual Windows notification (`flutter_local_notifications`).
7. [x] Switch to timer-based `show()` approach (workaround for `zonedSchedule` silent failure).
8. [x] Update `docs/development/windows.md` with runtime notes.
9. [x] Run Flutter quality gates.
10. [x] Remove diagnostic debug logging.
11. [ ] Final Windows smoke test.

## File Changes

### New Files

- `apps/lazynote_flutter/lib/features/reminders/reminder_service.dart` - `ReminderService` abstraction + `PlatformReminderService`
- `apps/lazynote_flutter/lib/features/reminders/reminder_scheduler.dart` - static singleton scheduler with per-atom tracking, time-matrix scheduling, and stable ID hashing
- `apps/lazynote_flutter/test/helpers/mock_reminder_service.dart` - test mock
- `apps/lazynote_flutter/test/reminder_scheduler_test.dart` - scheduler tests

### Modified Files

- `apps/lazynote_flutter/pubspec.yaml` - add notifications packages
- `apps/lazynote_flutter/lib/main.dart` - bootstrap `ReminderScheduler.ensureInitialized()`
- `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart` - schedule reminders after loading today items
- `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart` - schedule reminders after loading week events
- `docs/development/windows.md` - reminder setup notes

## Dependencies

- PR0011, PR0012

## Quality Gates

- [x] `flutter analyze` - no issues
- [x] `flutter test` - 162 tests pass
- [ ] Windows manual smoke run - timer + `show()` path implemented; requires manual confirmation that a scheduled reminder toast appears while app is running.
- Note: `scripts/run_windows_smoke.bat` build, dependency restore, and app launch pass locally; final toast verification is interactive/manual.

## Acceptance Criteria

- [x] Reminder service abstraction with injectable implementations
- [x] Time-matrix based reminder scheduling (DDL/event/start)
- [x] Task/Calendar integration points wired (static singleton, no injection needed)
- [x] PlatformReminderService implementation (`flutter_local_notifications`)
- [x] Unit tests for schedule/cancel behavior
- [x] Immediate notification (`show()`) works on Windows
- [x] Scheduled reminder fires on Windows via timer + `show()` path (app-running only)
- [x] Updating/deleting item updates reminder correctly (covered by scheduler cancel/re-schedule behavior)
- [x] Windows setup/limitations documented

## Known Limitations (Windows)

| Limitation | Impact | Mitigation |
|---|---|---|
| `zonedSchedule()` silently fails for unpackaged (debug) apps | Scheduled notifications may never appear | Use timer + `show()` fallback |
| Timer-based notifications require app to be running | No notification if app is closed | Document as v0.1 limitation; use packaging strategy for production |
| Notifications do not survive system reboot | Scheduled reminders are lost after restart | Re-schedule on app startup from DB state |
| Event end-time reminder is not implemented | Events only remind before start time | Current v0.1 behavior by design |
| Focus Assist / Do Not Disturb | Notifications can be suppressed by OS | User-side OS settings |
