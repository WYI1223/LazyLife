# PR-0012-calendar-minimal

- Proposed title: `feat(calendar): minimal day/week schedule views`
- Status: Planned (optimized)

## Goal

Deliver a minimal calendar experience that can visualize and create schedules.

## Scope (v0.1)

In scope:

- day and week timeline views (minimal blocks)
- create/update schedule window based on `event_start/event_end`
- read-only relation to task context (if linked)

Out of scope:

- drag-and-drop rescheduling
- overlapping-event conflict resolver UI
- recurrence editor

## Optimized Phases

Phase A (Core + FFI):

- add calendar/event query and schedule mutation APIs
- enforce start/end validation in service boundary
- expose FFI APIs and tests

Phase B (Flutter UI):

- add day/week calendar pages
- wire create/update schedule actions
- add widget/smoke tests

## Step-by-Step

1. Define calendar API contract and validation/error mapping.
2. Add event repository/service methods for range query and schedule mutation.
3. Add validation tests (including reversed range rejection).
4. Expose calendar APIs through FFI.
5. Regenerate FRB bindings.
6. Implement calendar controller state.
7. Build minimal day/week timeline views.
8. Add schedule create/update interactions.
9. Add Flutter tests for loading/rendering and schedule mutation feedback.
10. Run full quality gates.
11. Update release progress docs.

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/calendar/calendar_page.dart`
- [add] `apps/lazynote_flutter/lib/features/calendar/day_view.dart`
- [add] `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart`
- [add] `crates/lazynote_core/src/service/calendar_service.rs`
- [add] `crates/lazynote_core/src/repo/event_repo.rs`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [add] `apps/lazynote_flutter/test/calendar_flow_test.dart`

## Dependencies

- PR0006, PR0008, PR0009, PR0011

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] Day/week views can render schedule blocks
- [ ] Schedule create/update works with validated time ranges
- [ ] API docs and compatibility docs are updated if contract changed
- [ ] Rust + Flutter tests cover baseline behavior
