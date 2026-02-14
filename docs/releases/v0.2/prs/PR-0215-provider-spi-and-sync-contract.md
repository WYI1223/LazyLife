# PR-0215-provider-spi-and-sync-contract

- Proposed title: `feat(sync): provider SPI and sync contract baseline`
- Status: Planned

## Goal

Introduce provider abstraction for calendar/tasks sync so core app depends on interfaces, not a specific provider.

## Scope (v0.2)

In scope:

- provider SPI contracts:
  - `auth`
  - `pull`
  - `push`
  - `conflict_map`
- provider status and error envelope model
- sync summary contract and telemetry-safe fields

Out of scope:

- concrete Google provider implementation
- webhook and realtime channel management

## Step-by-Step

1. Define provider SPI interfaces and DTOs.
2. Add provider registry and selection hooks.
3. Add sync summary/diagnostics contract.
4. Add tests for provider adapter compliance.

## Planned File Changes

- [add] `crates/lazynote_core/src/sync/provider_spi.rs`
- [add] `crates/lazynote_core/src/sync/provider_registry.rs`
- [add] `crates/lazynote_core/src/sync/provider_types.rs`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [add] `docs/architecture/provider-spi.md`

## Dependencies

- `PR-0213-extension-kernel-contracts`

## Verification

- `cargo test --all`
- `flutter analyze`

## Acceptance Criteria

- [ ] Provider SPI is complete for auth/pull/push/conflict needs.
- [ ] Core services compile without direct provider-specific dependencies.
- [ ] Contract and error mapping docs are synchronized.

