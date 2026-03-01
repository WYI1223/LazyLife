# Sync Protocol

## Purpose

This document describes the synchronization protocol baseline and planned evolution.

Current status:

- v0.2 sync protocol is prepared at schema level + provider SPI contracts (declaration-only).
- Full provider sync engine is not implemented yet.
- First concrete implementation (Google Calendar) is v0.3 scope (PR-0309).
- Architecture follows S6 three-layer separation: Provider → Orchestrator → Mapping.

## Design Goals

- keep local data authoritative (local-first)
- support deterministic provider mapping
- support incremental sync and conflict visibility
- keep sync logic inside Rust core

## Scope by Version

### v0.1–v0.2 (completed)

- `external_mappings` table as canonical provider link registry (Migration 3)
- stable atom IDs + soft-delete semantics
- `ProviderSpi` trait defined (auth/pull/push/conflict_map) — declaration-only
- `ProviderRegistry` defined — declaration-only
- provider SPI contract baseline with capability-aware invocation guardrails
- API lifecycle/deprecation baseline for sync/provider surfaces

### v0.3 (planned)

- **SyncOrchestratorService**: sync flow coordination, mapping management, S1 creation semantics (S6 ruling)
- **ExternalMappingRepository**: `external_mappings` table CRUD
- **Google Calendar Provider**: first concrete `ProviderSpi` implementation (PR-0309)
- S1 R5 alignment: sync pull creates Atom + atom_ref (mandatory accompaniment)
- S1 R4 alignment: pull Atom with `start_at`/`end_at` auto-derives `view_hint = event`

### v0.4+

- broader provider support and reliability hardening
- better conflict UX and replay tooling
- cursor-based incremental sync strategy

## Three-Layer Responsibility Separation (S6 Ruling)

See [S6: Provider SPI → external_mappings 交互](rulings/S6-provider-spi-interaction.md) for full ruling.

| Layer | Component | Responsibility | Touches external_mappings? |
|-------|-----------|----------------|---------------------------|
| Provider adapter | `ProviderSpi` implementation | Remote API interaction: auth, pull, push, conflict strategy | **No** |
| Sync orchestrator | `SyncOrchestratorService` (v0.3) | Orchestrate sync flow, manage mappings, enforce creation semantics | **Yes** — sole reader/writer |
| Mapping persistence | `ExternalMappingRepository` (v0.3) | `external_mappings` table CRUD | **Yes** — called by orchestrator |

### Sync Flow

```
1. provider.auth()           → confirm auth status
2. provider.pull(cursor)     → get remote changes
3. mapping_repo.find(...)    → look up existing mappings
   - has mapping → update local Atom
   - no mapping → create Atom + atom_ref + create mapping (S1 R5)
4. collect local changes
5. mapping_repo.get(...)     → get external_id
6. provider.push(changes)    → push to remote
7. mapping_repo.update(...)  → update version/last_synced_at
8. if conflicts → provider.conflict_map() → execute per strategy
```

### S1 Ruling Impact on Sync

| S1 Rule | Requirement for sync orchestrator |
|---------|----------------------------------|
| R5 atom_ref mandatory | Pull creating new Atom must also create atom_ref |
| R6 designated default path | Google Calendar pull → atom_ref routes to Calendar designated folder |
| R3 view_hint auto-derivation | Pull Atom with `start_at`/`end_at` → Core auto-derives `view_hint = event` |

## Core Concepts

### Sync Unit

- Unit of sync is Atom-projected event/task data.
- `atom_uuid` is the canonical internal identity.

### Mapping Registry

- Mapping lives in `external_mappings` (Rust core owned)
- Mapping is **Atom-level** (not atom_ref-level) — atom_ref multi-references are orthogonal (S6 ruling)
- UI must not manage provider ID mapping logic
- Uniqueness: `UNIQUE(provider, external_id)` + `UNIQUE(provider, atom_uuid)`

### Deletion Semantics

- local delete = tombstone (`is_deleted = 1`)
- provider-side delete policy will be explicit per provider adapter

## Planned Protocol States (Provider Adapter)

1. `bootstrap`: initial full pull
2. `steady`: incremental pull using provider delta token
3. `reconcile`: apply local changes and resolve conflicts
4. `checkpoint`: persist sync token and sync timestamp

## Conflict Baseline

Minimal rule set:

- deterministic last-writer strategy for low-risk fields
- preserve mapping consistency first
- expose conflict count and status in logs/diagnostics

Detailed conflict UI is an open design item (see S6).

## Error Handling Principles

- sync failures must not block local CRUD operations
- token/auth failures are surfaced as actionable errors
- partial failures should retain previous stable checkpoint

## Logging and Observability

Sync-related events should emit metadata only:

- `sync_start`
- `sync_done`
- `sync_error`

Recommended fields:

- `pulled_count`
- `written_count`
- `conflict_count`
- `token_updated`
- `duration_ms`

See: `docs/architecture/logging.md`.

## Security and Compliance Boundaries

- OAuth credentials and refresh tokens are secret data
- no sensitive payload content in logs
- provider API scope must follow minimum required permissions

See: `docs/compliance/google-calendar.md` and `docs/compliance/privacy.md`.

## Non-goals (current state)

- CRDT-level multi-master merge implementation
- remote telemetry upload
- production sandboxed third-party provider runtime in v0.3

## References

- [S6: Provider SPI → external_mappings 交互](rulings/S6-provider-spi-interaction.md)
- [S1: Atom 投影语义](rulings/S1-atom-projection.md)
- `docs/releases/v0.1/prs/PR-0014-local-task-calendar-projection.md`
- `docs/releases/v0.1/prs/PR-0015-google-calendar-provider-plugin.md`
- `docs/releases/v0.2/prs/PR-0215-provider-spi-and-sync-contract.md`
- `docs/releases/v0.3/prs/PR-0309-google-calendar-provider-plugin.md`
- `docs/architecture/data-model.md`
- `docs/architecture/logging.md`
- `docs/architecture/provider-spi.md`
