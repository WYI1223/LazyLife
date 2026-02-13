# PR-0014-gcal-auth-one-way

- Proposed title: `feat(gcal): OAuth + one-way bootstrap pull`
- Status: Planned (optimized)

## Goal

Deliver the first production-safe Google Calendar integration step:

- OAuth authorization
- one-way pull from Google Calendar to local store

## Scope (v0.1)

In scope:

- desktop OAuth login flow
- token persistence/refresh baseline
- initial and manual-trigger pull sync

Out of scope:

- local-to-remote push
- webhooks/realtime callbacks
- multi-account management

## Optimized Phases

Phase A (Auth + Token Store):

- implement OAuth client flow
- add secure token storage schema/path
- FFI APIs for connect/disconnect/status

Phase B (One-Way Pull):

- implement pull-only calendar event import
- map required fields into atom/event model
- add sync summary result DTOs

## Step-by-Step

1. Define OAuth/sync contract and errors in API docs.
2. Add token migration and persistence model.
3. Implement auth module and refresh path.
4. Add auth service + tests (success/failure/expired token).
5. Implement pull-only client and mapping path.
6. Add service method returning summary (`fetched/imported/failed`).
7. Expose FFI APIs and regenerate bindings.
8. Add Flutter settings integration for auth + manual pull trigger.
9. Add tests for auth state and one-way pull behavior.
10. Update compliance doc (`google-calendar.md`).
11. Run quality gates.

## Planned File Changes

- [edit] `apps/lazynote_flutter/pubspec.yaml`
- [add] `crates/lazynote_core/src/integrations/google_calendar/mod.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/auth.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/client.rs`
- [add] `crates/lazynote_core/src/service/gcal_sync_service.rs`
- [add] `crates/lazynote_core/src/db/migrations/0005_gcal_tokens.sql`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [edit] `docs/compliance/google-calendar.md`

## Dependencies

- PR0005, PR0006, PR0012

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] OAuth connect/disconnect and token refresh baseline works
- [ ] Manual one-way pull imports events to local model
- [ ] Sync summary is visible to caller/UI
- [ ] Compliance and API docs updated
