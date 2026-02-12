# PR-0014-gcal-auth-one-way

- Proposed title: `feat(gcal): OAuth + one-way sync bootstrap`
- Status: Draft

## Goal
First step of calendar integration.

## Deliverables
- desktop OAuth flow
- initial one-way event pull

## Planned File Changes
- [edit] `apps/lazynote_flutter/pubspec.yaml`
- [add] `crates/lazynote_core/src/integrations/google_calendar/mod.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/auth.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/client.rs`
- [add] `crates/lazynote_core/src/service/gcal_sync_service.rs`
- [add] `crates/lazynote_core/src/db/migrations/0005_gcal_tokens.sql`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [edit] `docs/compliance/google-calendar.md`

## Dependencies
- PR0005, PR0006, PR0012

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
