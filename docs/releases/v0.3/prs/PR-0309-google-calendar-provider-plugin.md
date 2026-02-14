# PR-0309-google-calendar-provider-plugin

- Proposed title: `feat(calendar-provider): Google Calendar plugin on provider SPI`
- Status: Planned

## Goal

Implement Google Calendar integration as provider plugin, strictly through provider SPI contracts.

## Scope (v0.3)

In scope:

- Google provider auth lifecycle (`connect/disconnect/refresh`)
- incremental pull/push via provider SPI
- provider sync-state and mapping persistence
- provider status/sync summary surface to UI

Out of scope:

- core task-calendar projection rules
- plugin runtime sandbox/distribution governance
- multi-provider arbitration policy

## Step-by-Step

1. Implement provider adapter for Google APIs.
2. Implement provider incremental sync state path.
3. Add mapping repository and summary DTO integration.
4. Add settings UI bridge and regression tests.

## Planned File Changes

- [add] `crates/lazynote_core/src/integrations/google_calendar/provider_adapter.rs`
- [add/edit] `crates/lazynote_core/src/integrations/google_calendar/*`
- [add/edit] `crates/lazynote_core/src/service/provider_sync_service.rs`
- [add/edit] `crates/lazynote_core/src/repo/external_mapping_repo.rs`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [edit] `apps/lazynote_flutter/lib/features/settings/calendar_sync_page.dart`

## Dependencies

- `PR-0215-provider-spi-and-sync-contract`
- `PR-0308-local-task-calendar-projection`
- `PR-0015-google-calendar-provider-plugin`

## Verification

- `cargo test --all`
- `flutter test`

## Acceptance Criteria

- [ ] Google integration runs through provider SPI without direct core coupling.
- [ ] Incremental sync and mapping behavior are stable and test-covered.
- [ ] Provider status and error envelopes are visible to UI callers.
