# PR-0015-google-calendar-provider-plugin

- Proposed title: `feat(calendar-provider): Google Calendar provider plugin on Provider SPI`
- Status: Deferred (post-v0.1, replanned to v0.3 provider plugin track)

## Goal

Deliver Google Calendar as a provider plugin implementation instead of core-app coupling.

## Deferral Reason

v0.1 has been narrowed to notes-first + diagnostics-readability closure (`PR-0010C2/C3/C4/D`, `PR-0017A`).
This PR is replanned as v0.3 provider plugin implementation (`PR-0309`) on top of provider SPI.

## Scope (post-v0.1 backlog)

In scope:

- provider auth lifecycle (`connect/disconnect/refresh`) for Google
- incremental pull/push via provider SPI
- stable mapping (`extendedProperties` + local mapping repository)
- provider-side conflict mapping into core conflict contract

Out of scope:

- local task-calendar projection core rules (owned by `PR-0014`/`PR-0308`)
- third-party plugin runtime/sandbox mechanics
- multi-provider merge arbitration UI

## Optimized Phases

Phase A (Provider Adapter + Auth):

- implement Google provider adapter on SPI contract
- implement OAuth/token lifecycle inside provider boundary
- add adapter/auth tests (success/failure/token-expired)

Phase B (Incremental Sync + Mapping):

- implement incremental pull/push using provider sync-state
- implement remote-local mapping persistence and summary output
- expose provider status/sync summary through FFI

## Step-by-Step

1. Lock provider SPI contract and provider error mapping.
2. Implement Google provider auth adapter.
3. Implement provider incremental pull/push logic.
4. Add mapping/sync-state storage and tests.
5. Expose provider status/sync APIs via FFI.
6. Add Flutter settings bridge for provider connect/sync actions.
7. Update compliance and API docs.
8. Run full quality gates.

## Planned File Changes

- [add] `crates/lazynote_core/src/integrations/google_calendar/sync.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/mapping.rs`
- [add] `crates/lazynote_core/src/integrations/google_calendar/provider_adapter.rs`
- [add] `crates/lazynote_core/src/repo/external_mapping_repo.rs`
- [add/edit] `crates/lazynote_core/src/service/provider_sync_service.rs`
- [add/edit] `crates/lazynote_core/src/db/migrations/*gcal_provider_sync_state*.sql`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [edit] `docs/compliance/google-calendar.md`
- [add] `apps/lazynote_flutter/lib/features/settings/calendar_sync_page.dart`

## Dependencies

- PR-0014-local-task-calendar-projection
- PR-0215-provider-spi-and-sync-contract

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] Google provider integrates only through provider SPI surface.
- [ ] Incremental pull/push is stable with persisted provider sync state.
- [ ] Stable remote-local mapping is maintained and test-covered.
- [ ] Compliance/API docs reflect provider-plugin architecture.
