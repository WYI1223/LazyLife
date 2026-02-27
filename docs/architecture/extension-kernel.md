# Extension Kernel Contracts (v0.2 Baseline)

## Purpose

Define a stable extension contract layer so command, parser, provider, and UI
slot integrations can evolve without rewriting core business services.

## Scope (v0.2)

In scope:

- manifest declaration model (`id`, `version`, `capabilities`, `entrypoints`)
- runtime capability declaration model (`runtime_capabilities`)
- declaration-time manifest validation
- in-process extension registry contract
- first-party adapter registration path
- lifecycle surface declaration (`init`, `dispose`, `health`)

Out of scope:

- dynamic loading/sandbox runtime
- third-party package discovery/distribution
- executable entrypoint invocation engine

## Capability Model

v0.2 uses **string capability enums**:

- `command`
- `parser`
- `provider`
- `ui_slot`

Bitflags/structured capability model is intentionally deferred to later PRs.

Runtime security capabilities (invocation guard):

- `network`
- `file`
- `notification`
- `calendar`

## Manifest Contract

`ExtensionManifest` fields:

- `id`: stable extension id (lowercase alnum with `.`/`_`/`-` separators)
- `version`: semantic triplet (`major.minor.patch`)
- `capabilities`: non-empty set of supported capability strings
- `runtime_capabilities`: optional runtime permission declarations
- `entrypoints`: declaration-only string identifiers

Validation rules:

- id/version format must be valid
- capabilities must be supported and deduplicated
- runtime capabilities must be supported and deduplicated
- capability-specific entrypoint declaration must exist
- lifecycle declarations `init/dispose/health` are required

## Registry Contract

`ExtensionRegistry`:

- validates manifest before registration
- rejects duplicate extension ids
- maintains capability index for lookup
- supports first-party adapter baseline registration
- exposes deny-by-default runtime capability guard for invocation boundaries
  - `assert_runtime_capability(extension_id, capability)`
  - `assert_invocation_allowed(extension_id, invocation)`

This registry is declaration-only in v0.2 and does not execute entrypoints.

## Error Taxonomy (Internal)

- `ManifestValidationError`
  - id/version/capability/entrypoint declaration errors
- `ExtensionKernelError`
  - invalid manifest wrapper
  - duplicate extension id

These are internal core enums; no FFI contract exposure in PR-0213.

## First-Party vs Third-Party Boundary (S5 Ruling, v0.2.5)

**First-party commands are NOT registered through ExtensionManifest/ExtensionRegistry.**

The Extension Kernel is positioned as a **third-party contract layer**. First-party features
(SingleEntry CommandParser/CommandRouter/CommandRegistry) use direct in-process registration
and do not go through manifest validation or capability guards.

Rationale:

- First-party and third-party differ fundamentally in trust, registration, and security models.
- v0.2.5 has no third-party plugins; forcing first-party through Extension Kernel would sacrifice
  iteration speed for architectural purity that has no current consumer.
- The Extension Kernel's declaration-only state is correct — manifest validation and capability
  guards are tested (see `crates/lazynote_core/tests/extension_*` test modules) and ready for third-party activation.

Activation timeline:

- **v0.2.5**: Extension Kernel remains declaration-only. First-party commands use direct registration.
- **v0.3 (PR-0310)**: Evaluate first-party migration to Extension Kernel if third-party demand materializes.

See: `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md` §S5.
