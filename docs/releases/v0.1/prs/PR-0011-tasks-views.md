# PR-0011-tasks-views

- Proposed title: `feat(tasks): Inbox/Today/Upcoming + complete/reopen`
- Status: Planned (optimized)

## Goal

Deliver minimal but reliable task workflow for v0.1.

## Scope (v0.1)

In scope:

- task list sections: `Inbox`, `Today`, `Upcoming`
- complete/reopen toggle
- ordering by due/start time then updated time

Out of scope:

- recurrence rule UI
- drag reorder persistence
- complex smart filters

## Optimized Phases

Phase A (Core + FFI):

- add task query use-cases for three sections
- add complete/reopen use-case
- add FFI APIs and tests

Phase B (Flutter UI):

- build tasks page with three sections
- wire actions and optimistic loading states
- add widget/smoke tests

## Step-by-Step

1. Define task section query contract in API docs.
2. Implement task service methods for `Inbox/Today/Upcoming`.
3. Implement complete/reopen use-case with idempotent behavior.
4. Add Rust tests for section classification and status transitions.
5. Expose task APIs via FFI.
6. Regenerate FRB bindings and update Flutter API wrappers.
7. Implement tasks controller state and actions.
8. Implement sectioned task UI.
9. Add complete/reopen interactions.
10. Add Flutter tests for section rendering and toggle behavior.
11. Run full quality gates.
12. Update release progress docs.

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/tasks/tasks_page.dart`
- [add] `apps/lazynote_flutter/lib/features/tasks/task_list_section.dart`
- [add] `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart`
- [add] `crates/lazynote_core/src/service/task_service.rs`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [add] `apps/lazynote_flutter/test/tasks_flow_test.dart`

## Dependencies

- PR0006, PR0008, PR0009

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] Tasks are correctly split into Inbox/Today/Upcoming
- [ ] Complete/reopen behavior is idempotent and reflected in UI
- [ ] API docs and compatibility docs are updated if contract changed
- [ ] Rust + Flutter tests cover primary flow
