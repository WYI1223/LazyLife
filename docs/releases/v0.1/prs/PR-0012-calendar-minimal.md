# PR-0012-calendar-minimal

- Proposed title: `ui(calendar): day/week view (minimal) + schedule task`
- Status: Draft

## Goal
Deliver minimal calendar scheduling.

## Deliverables
- day/week minimal view
- task scheduling via event_start/event_end

## Planned File Changes
- [add] `apps/lazynote_flutter/lib/features/calendar/calendar_page.dart`
- [add] `apps/lazynote_flutter/lib/features/calendar/day_view.dart`
- [add] `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart`
- [add] `crates/lazynote_core/src/service/calendar_service.rs`
- [add] `crates/lazynote_core/src/repo/event_repo.rs`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [add] `apps/lazynote_flutter/test/calendar_flow_test.dart`

## Dependencies
- PR0006, PR0008, PR0009, PR0011

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
