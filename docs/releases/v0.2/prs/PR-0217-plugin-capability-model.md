# PR-0217-plugin-capability-model

- Proposed title: `feat(security): plugin capability model baseline`
- Status: Planned

## Goal

Establish capability-based permission declarations for extensions before sandbox runtime arrives.

## Scope (v0.2)

In scope:

- capability schema:
  - `network`
  - `file`
  - `notification`
  - `calendar`
- manifest-declared capability validation
- runtime gate checks in extension invocation path
- user-visible capability description strings

Out of scope:

- process-level sandbox runtime
- signed plugin distribution policy

## Step-by-Step

1. Define capability schema and validation rules.
2. Add enforcement points in extension invocation path.
3. Add deny-by-default behavior for undeclared capabilities.
4. Add tests for allow/deny matrix.

## Planned File Changes

- [add] `crates/lazynote_core/src/extension/capability.rs`
- [edit] `crates/lazynote_core/src/extension/kernel.rs`
- [edit] `apps/lazynote_flutter/lib/features/settings/*`
- [add] `docs/governance/plugin-capabilities.md`
- [add] `crates/lazynote_core/tests/capability_guard_test.rs`

## Dependencies

- `PR-0213-extension-kernel-contracts`
- `PR-0215-provider-spi-and-sync-contract`

## Verification

- `cargo test --all`
- `flutter test`

## Acceptance Criteria

- [ ] Extension invocations enforce declared capabilities with deny-by-default.
- [ ] Capability declarations are visible and auditable.
- [ ] Guard tests cover network/file/notification/calendar access paths.

