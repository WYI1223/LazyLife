# PR-0013-reminders-windows

- Proposed title: `feat(reminders): one-time local notifications (Windows)`
- Status: Planned (optimized)

## Goal

Enable baseline Windows local reminder delivery for scheduled items.

## Scope (v0.1)

In scope:

- one-time reminder scheduling
- cancel/update reminder on item update
- Windows-only path and setup notes

Out of scope:

- cross-platform reminder parity
- recurring reminder engine
- snooze/advanced notification actions

## Step-by-Step

1. Choose and lock Windows notification plugin/runtime path.
2. Add reminder scheduler abstraction in Flutter.
3. Add task/calendar integration points for create/update/delete.
4. Ensure idempotent scheduling keys (avoid duplicates).
5. Add unit tests for schedule/cancel behavior.
6. Add smoke path validation for Windows runtime.
7. Update `docs/development/windows.md` with permission/runtime notes.
8. Run Flutter quality gates.

## Planned File Changes

- [edit] `apps/lazynote_flutter/pubspec.yaml`
- [add] `apps/lazynote_flutter/lib/features/reminders/reminder_service.dart`
- [add] `apps/lazynote_flutter/lib/features/reminders/reminder_scheduler.dart`
- [edit] `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart`
- [edit] `docs/development/windows.md`
- [add] `apps/lazynote_flutter/test/reminders_test.dart`

## Dependencies

- PR0011, PR0012

## Quality Gates

- `flutter analyze`
- `flutter test`
- Windows manual smoke run (`flutter run -d windows`)

## Acceptance Criteria

- [ ] One-time reminder can be scheduled and triggered on Windows
- [ ] Updating/deleting item updates reminder correctly
- [ ] Windows setup/limitations documented
