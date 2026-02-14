# PR-0310-first-party-command-parser-plugins

- Proposed title: `refactor(entry): migrate first-party commands/parsers to plugin form`
- Status: Planned

## Goal

Complete first-party migration to extension-style command/parser modules, validating kernel contracts before third-party openness.

## Scope (v0.3)

In scope:

- migrate built-in commands to registry-driven plugins
- migrate built-in parser flows to parser-chain plugins
- add observability and failure isolation for command/parser plugin execution
- keep user-facing behavior backward compatible

Out of scope:

- third-party downloadable plugin ecosystem
- policy-level plugin signing distribution

## Step-by-Step

1. Convert built-in commands to plugin-style registrations.
2. Convert parser modules and lock precedence behavior.
3. Add plugin execution telemetry (non-content metadata only).
4. Add compatibility tests against pre-migration behavior.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/entry/*`
- [edit] `crates/lazynote_core/src/entry/command_registry.rs`
- [edit] `crates/lazynote_core/src/entry/parser_chain.rs`
- [add] `crates/lazynote_core/tests/entry_plugin_compat_test.rs`
- [add] `apps/lazynote_flutter/test/entry_plugin_compat_test.dart`

## Dependencies

- `PR-0214-command-registry-and-parser-chain`
- `PR-0217-plugin-capability-model`

## Verification

- `cargo test --all`
- `flutter test`

## Acceptance Criteria

- [ ] First-party command/parser paths run through plugin registration flows.
- [ ] Behavior remains backward compatible for existing command use-cases.
- [ ] Failure isolation prevents one plugin module from breaking whole entry flow.

