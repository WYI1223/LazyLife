# PR-0015-gcal-two-way-incremental

- Proposed title: `feat(gcal): two-way syncToken + extended properties`
- Status: Draft

## Goal
Complete two-way incremental calendar sync.

## Deliverables
- syncToken incremental sync
- extendedProperties internal-id mapping
- minimal conflict handling rules

## Planned File Changes
- [add] `crates/lazynote_core/src/integrations/google_calendar/sync.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/mapping.rs`
- [add] `crates/lazynote_core/src/repo/external_mapping_repo.rs`
- [edit] `crates/lazynote_core/src/service/gcal_sync_service.rs`
- [add] `crates/lazynote_core/src/db/migrations/0006_gcal_sync_state.sql`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [edit] `docs/compliance/google-calendar.md`
- [add] `apps/lazynote_flutter/lib/features/settings/calendar_sync_page.dart`

## Dependencies
- PR0014

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
