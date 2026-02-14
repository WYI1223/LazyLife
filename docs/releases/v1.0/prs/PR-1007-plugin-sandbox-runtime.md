# PR-1007-plugin-sandbox-runtime

- Proposed title: `feat(security): plugin sandbox runtime and capability enforcement closure`
- Status: Planned

## Goal

Ship production-grade sandbox boundaries for plugin execution with enforceable capability checks.

## Scope (v1.0)

In scope:

- sandbox execution boundary for plugin modules
- capability enforcement integration with runtime boundary
- failure containment and resource budget guards
- audit logs for plugin permission-denied events

Out of scope:

- open third-party marketplace policy
- advanced multi-tenant plugin hosting

## Step-by-Step

1. Define sandbox boundary model and threat assumptions.
2. Implement runtime boundary hooks and capability bridge.
3. Add resource budget guards (cpu/time/memory thresholds).
4. Add security regression tests and failure-injection scenarios.

## Planned File Changes

- [add/edit] `crates/lazynote_core/src/extension/sandbox/*`
- [edit] `crates/lazynote_core/src/extension/capability.rs`
- [add] `crates/lazynote_core/tests/plugin_sandbox_test.rs`
- [edit] `docs/governance/plugin-capabilities.md`

## Dependencies

- `PR-0217-plugin-capability-model`

## Verification

- `cargo test --all`
- security regression checklist run

## Acceptance Criteria

- [ ] Plugin execution is bounded by sandbox policy.
- [ ] Capability enforcement remains effective inside sandbox path.
- [ ] Security regression tests cover deny/bypass/failure scenarios.

