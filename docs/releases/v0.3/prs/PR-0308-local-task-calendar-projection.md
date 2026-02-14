# PR-0308-local-task-calendar-projection

- Proposed title: `feat(calendar-core): local task-calendar projection and sync rules`
- Status: Planned

## Goal

Implement provider-agnostic local task-calendar projection as core capability.

## Scope (v0.3)

In scope:

- projection between task model and local calendar blocks
- status propagation (`todo/in_progress/done/cancelled`) to calendar representation
- local conflict rules and deterministic tie-breakers
- query/update APIs for calendar-focused views

Out of scope:

- external provider auth/pull/push
- multi-provider merge arbitration

## Step-by-Step

1. Finalize projection model and constraints.
2. Implement projection service and repositories.
3. Add FFI APIs for local calendar view workflows.
4. Add tests for projection consistency across task lifecycle events.

## Planned File Changes

- [add/edit] `crates/lazynote_core/src/service/calendar_projection_service.rs`
- [add/edit] `crates/lazynote_core/src/repo/calendar_projection_repo.rs`
- [add/edit] `crates/lazynote_core/src/db/migrations/*calendar_projection*.sql`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [add/edit] `apps/lazynote_flutter/lib/features/calendar/*`

## Dependencies

- `PR-0014-local-task-calendar-projection`
- `PR-0215-provider-spi-and-sync-contract` (for future alignment only)

## Verification

- `cargo test --all`
- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] Task updates are consistently reflected in local calendar projection.
- [ ] Local calendar behavior works without any external provider configured.
- [ ] Projection conflict rules are deterministic and test-covered.

