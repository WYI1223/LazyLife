# PR-0214-command-registry-and-parser-chain

- Proposed title: `feat(entry): command registry and parser chain baseline`
- Status: Planned

## Goal

Refactor Single Entry into an extension-driven registry so commands and input parsers are pluggable.

## Scope (v0.2)

In scope:

- command registry with namespaced command ids
- parser chain with priority and deterministic short-circuit behavior
- conflict handling for duplicate command ids/parser overlaps
- first-party command migration to registry

Out of scope:

- third-party downloadable parser plugins
- cloud command execution

## Step-by-Step

1. Add command registry interfaces and adapters.
2. Add parser chain with priority and timeout budget.
3. Migrate first-party entry commands to registry registration.
4. Add tests for parser precedence and conflict behavior.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/entry/*`
- [add] `crates/lazynote_core/src/entry/command_registry.rs`
- [add] `crates/lazynote_core/src/entry/parser_chain.rs`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [add] `apps/lazynote_flutter/test/entry_registry_parser_chain_test.dart`

## Dependencies

- `PR-0213-extension-kernel-contracts`

## Verification

- `cargo test --all`
- `flutter test`

## Acceptance Criteria

- [ ] First-party commands are loaded via registry, not hardcoded switch flow.
- [ ] Parser chain ordering and timeout behavior are deterministic and tested.
- [ ] Duplicate registration conflicts return explicit errors.

