# PR-0213-extension-kernel-contracts

- Proposed title: `feat(platform): extension kernel contracts baseline`
- Status: Planned

## Goal

Define stable extension kernel contracts so command palette, parser, provider integration, and UI extension can evolve without core rewrites.

## Scope (v0.2)

In scope:

- extension manifest baseline (id/version/capabilities/entrypoints)
- extension interface contracts:
  - command action registration
  - input parser registration
  - provider SPI hooks
  - UI slot declaration metadata
- lifecycle surface (`init`, `dispose`, `health`)

Out of scope:

- third-party runtime loading/sandbox execution
- external marketplace/distribution

## Step-by-Step

1. Define extension kernel interfaces and manifest schema.
2. Add contract docs and error taxonomy.
3. Add first-party adapter for internal modules.
4. Add tests for registry integrity and manifest validation.

## Planned File Changes

- [add] `crates/lazynote_core/src/extension/kernel.rs`
- [add] `crates/lazynote_core/src/extension/manifest.rs`
- [add] `docs/architecture/extension-kernel.md`
- [edit] `docs/governance/API_COMPATIBILITY.md`

## Verification

- `cargo test --all`
- `flutter analyze`

## Acceptance Criteria

- [ ] Extension kernel contracts are documented and implemented.
- [ ] First-party modules can register through contract adapters.
- [ ] Contract tests prevent invalid manifest/entrypoint wiring.

