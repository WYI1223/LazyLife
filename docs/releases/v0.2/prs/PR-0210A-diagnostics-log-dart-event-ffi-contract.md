# PR-0210A-diagnostics-log-dart-event-ffi-contract

- Proposed title: `feat(ffi): add log_dart_event bridge contract for unified Dart/Rust timeline`
- Status: Planned

## Goal

Define and land a stable FFI contract so Dart-side structured events can be written into the Rust session log stream.

## Scope (v0.2)

In scope:

- freeze `log_dart_event` FFI signature and error semantics
- implement Rust FFI entry in `api.rs`
- regenerate FRB bindings and expose Dart wrapper API
- add minimal contract smoke tests (Rust + Flutter binding path)
- sync API docs (`ffi-contracts`, `error-codes` if needed)

Out of scope:

- application-wide call-site rollout (deferred to `PR-0210B`)
- event-rate policy tuning and high-volume instrumentation rollout

## Contract Freeze (M1)

1. Function shape
   - `log_dart_event(level, event_name, module, message)`
   - synchronous FFI write path
2. Payload constraints
   - `level`: fixed enum-like string set (`trace|debug|info|warn|error`)
   - `event_name/module/message`: non-empty trimmed strings with length guard
3. Failure semantics
   - invalid input maps to stable validation error code
   - I/O/backend failure maps to stable runtime error code
4. Compatibility
   - function is additive and backward-compatible for existing FFI clients

## Execution Split (DOC -> DEV -> CLOSE)

1. DOC: freeze contract and docs scope
2. DEV: implement FFI + codegen + contract tests
3. CLOSE: replay verification and status/docs closure

## Planned File Changes

- [edit] `crates/lazynote_ffi/src/api.rs`
- [edit] `crates/lazynote_ffi/src/frb_generated.rs` (codegen)
- [edit] `apps/lazynote_flutter/lib/core/bindings/api.dart` (codegen)
- [edit] `docs/api/ffi-contracts.md`
- [edit] `docs/api/error-codes.md` (if new code used)

## Dependencies

- `PR-0210C-diagnostics-session-single-file-log-policy`

## Verification

- `cd crates && cargo test -p lazynote_ffi`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/*contract*`

## Acceptance Criteria

- [ ] FFI API is callable from Flutter bindings.
- [ ] Invalid input/runtime failures map to documented stable codes.
- [ ] Contract docs and generated bindings are in sync.
