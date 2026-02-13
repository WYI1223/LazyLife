# PR-0015-gcal-two-way-incremental

- Proposed title: `feat(gcal): two-way incremental sync with stable mapping`
- Status: Planned (optimized)

## Goal

Complete two-way calendar synchronization with incremental state tracking.

## Scope (v0.1)

In scope:

- `syncToken` incremental pull
- local->Google push for changed events
- `extendedProperties` + local mapping table
- minimal conflict policy (v0.1 deterministic baseline)

Out of scope:

- multi-calendar merge policy
- advanced conflict resolution UI
- webhook-driven near-realtime updates

## Optimized Phases

Phase A (State + Mapping):

- add sync-state table and external mapping repository
- add deterministic key mapping and lookup APIs
- add state/mapping tests

Phase B (Two-Way Engine):

- implement pull incremental + push changed local events
- implement conflict policy and summary reporting
- expose FFI summary and settings UI trigger

## Step-by-Step

1. Define two-way sync contract and conflict semantics.
2. Add migration `0006_gcal_sync_state.sql`.
3. Implement mapping repository and sync-state repository.
4. Add tests for mapping uniqueness and state persistence.
5. Implement incremental pull with `syncToken`.
6. Implement outbound push for local dirty events.
7. Add conflict policy (v0.1 deterministic rule) and tests.
8. Expose FFI APIs and regenerate bindings.
9. Add/update Flutter sync settings page.
10. Update compliance + error-code docs.
11. Run full quality gates.

## Planned File Changes

- [add] `crates/lazynote_core/src/integrations/google_calendar/sync.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/mapping.rs`
- [add] `crates/lazynote_core/src/repo/external_mapping_repo.rs`
- [edit] `crates/lazynote_core/src/service/gcal_sync_service.rs`
- [add] `crates/lazynote_core/src/db/migrations/0006_gcal_sync_state.sql`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [edit] `docs/compliance/google-calendar.md`
- [add] `apps/lazynote_flutter/lib/features/settings/calendar_sync_page.dart`

## Dependencies

- PR0014

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] Incremental pull uses persisted `syncToken`
- [ ] Local changes can sync back to Google Calendar
- [ ] Stable mapping between remote event and local atom is maintained
- [ ] Conflict behavior and sync summary are test-covered and documented
