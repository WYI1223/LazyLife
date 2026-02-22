# PR-0210A-diagnostics-log-dart-event-ffi-contract

- Proposed title: `feat(ffi): add log_dart_event bridge contract for unified Dart/Rust timeline`
- Status: Completed

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
   - limits frozen:
     - `event_name <= 64`
     - `module <= 64`
     - `message <= 512`
3. Failure semantics
   - invalid input maps to stable validation error codes:
     - `invalid_level`
     - `invalid_event_name`
     - `invalid_module`
     - `invalid_message`
   - runtime unavailability maps to:
     - `logging_not_initialized`
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

- [x] FFI API is callable from Flutter bindings.
- [x] Invalid input/runtime failures map to documented stable codes.
- [x] Contract docs and generated bindings are in sync.

## Closure Notes

- Added sync FFI API:
  - `log_dart_event(level, event_name, module, message) -> LogDartEventResponse`
- Added core logging bridge:
  - `lazynote_core::log_dart_event(...)` with runtime `logging_not_initialized` guard
- Regenerated FRB bindings:
  - `crates/lazynote_ffi/src/frb_generated.rs`
  - `apps/lazynote_flutter/lib/core/bindings/api.dart`
  - `apps/lazynote_flutter/lib/core/bindings/frb_generated.dart`
  - `apps/lazynote_flutter/lib/core/bindings/frb_generated.io.dart`
- Added contract smoke:
  - `apps/lazynote_flutter/test/log_dart_event_contract_smoke_test.dart`
- Synced contract/error docs:
  - `docs/api/ffi-contracts.md`
  - `docs/api/error-codes.md`
- Verification replay:
  - `cd crates && cargo test -p lazynote_ffi`
  - `cd apps/lazynote_flutter && flutter analyze`
  - `cd apps/lazynote_flutter && flutter test test/entry_search_contract_smoke_test.dart test/workspace_contract_smoke_test.dart test/log_dart_event_contract_smoke_test.dart`
