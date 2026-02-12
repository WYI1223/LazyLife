# PR-0011-tasks-views

- Proposed title: `ui(tasks): Inbox/Today/Upcoming + complete toggle`
- Status: Draft

## Goal
Deliver minimal task workflows.

## Deliverables
- Inbox/Today/Upcoming views
- complete/reopen toggle

## Planned File Changes
- [add] `apps/lazynote_flutter/lib/features/tasks/tasks_page.dart`
- [add] `apps/lazynote_flutter/lib/features/tasks/task_list_section.dart`
- [add] `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart`
- [add] `crates/lazynote_core/src/service/task_service.rs`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [add] `apps/lazynote_flutter/test/tasks_flow_test.dart`

## Dependencies
- PR0006, PR0008, PR0009

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
