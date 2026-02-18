# API Lifecycle Policy

## Purpose

Define one canonical lifecycle policy for compatibility-sensitive API surfaces
so changes are explicit, reviewable, and reversible.

## Applies To

- Rust FFI exports in `crates/lazynote_ffi/src/api.rs`
- Dart-visible FFI bindings and response envelopes
- extension/provider contract docs (`docs/architecture/extension-kernel.md`,
  `docs/architecture/provider-spi.md`)
- behavior contracts in `docs/api/*.md`

## Stability Classes

### `experimental`

- default class for new extension/provider contracts in v0.x
- may change quickly, but changes must be documented in the same PR
- no silent drift is allowed

### `stable`

- backward compatibility is expected
- additive changes are preferred
- breaking changes require deprecation-first flow

### `deprecated`

- still available, but replacement path is mandatory
- must include deprecation notice and planned removal target

## Lifecycle Transitions

1. `experimental -> stable`
   - contract behavior is test-covered
   - docs are complete and linked from canonical index
2. `stable -> deprecated`
   - announce replacement API
   - document deprecation start version
   - include migration guidance and release note
3. `deprecated -> removed`
   - only after minimum deprecation window
   - release note must mention final removal

## Deprecation Window

For v0.x baseline:

- minimum one minor release cycle between deprecation and removal
- minimum 30 days notice when release cadence allows

For v1.0+:

- default minimum two minor release cycles
- longer windows are preferred for widely used endpoints

## Version Negotiation Guidance

Extension/provider contracts should evolve using:

- additive fields and additive enum variants first
- explicit contract version bumps for incompatible changes
- feature/capability discovery over implicit behavior switches

## v0.2 Baseline Classification

- extension kernel contracts: `experimental`
- provider SPI contracts: `experimental`
- documented FFI envelopes and machine-branchable error codes: `stable`

## PR Checklist (API-Affecting Changes)

Every API-affecting PR must include:

1. lifecycle class impact (`experimental|stable|deprecated`)
2. contract delta in docs (`docs/api/*` and/or architecture contracts)
3. compatibility notes in release docs
4. deprecation plan (if breaking or replacement is introduced)
