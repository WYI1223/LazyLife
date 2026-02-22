# PR-0210B-diagnostics-log-dart-event-integration

- Proposed title: `feat(diagnostics): integrate log_dart_event call sites and safety policy`
- Status: Completed

## Goal

Integrate the `log_dart_event` bridge into selected Dart runtime flows so diagnostics can display a unified Dart/Rust event timeline.

## Scope (v0.2)

In scope:

- define first-party Dart call-site allowlist for structured event logging
- integrate calls at selected lifecycle/diagnostics paths
- add safety guardrails (no-throw call path, basic dedupe/rate guard where needed)
- add integration regressions for non-blocking behavior and log write success
- sync PR/release docs with final rollout boundary

Out of scope:

- broad instrumentation of every UI interaction
- remote telemetry/export pipeline
- dynamic runtime log policy editor

## Contract Freeze (M1)

1. Integration boundary
   - only approved first-party call sites can emit `log_dart_event`
   - no plugin/third-party emit path in v0.2
2. Runtime safety
   - FFI logging failures must not block user actions
   - call sites must preserve existing UX and performance behavior
3. Event quality
   - event names/modules follow a stable naming convention
   - payload excludes user-sensitive content by default

### Call-Site Allowlist (frozen)

- `core.rust_bridge`
  - `rust_bridge.logging_bootstrap.ok`
  - `rust_bridge.logging_bootstrap.error`
  - `rust_bridge.health_check.ok`
  - `rust_bridge.health_check.error`
- `diagnostics.debug_logs_panel`
  - `diagnostics.logs.copy_visible`
  - `diagnostics.logs.open_folder.ok`
  - `diagnostics.logs.open_folder.error`
- `notes.notes_controller`
  - `workspace.node_move.ok`
  - `workspace.node_move.error`
  - `workspace.node_move.exception`

### Runtime Safety Policy (frozen)

- all call sites use centralized `DartEventLogger.tryLog(...)`
- `DartEventLogger` is no-throw by contract
- duplicate bursts are suppressed with dedupe window (`2s` default)
- FFI rejection/failure is treated as diagnostics degradation only

## Execution Split (DOC -> DEV -> CLOSE)

1. DOC: freeze call-site boundary and safety policy
2. DEV: wire call sites + tests
3. CLOSE: replay verification and docs/status closure

## Landed File Changes

- [add] `apps/lazynote_flutter/lib/core/diagnostics/dart_event_logger.dart`
- [edit] `apps/lazynote_flutter/lib/core/rust_bridge.dart`
- [edit] `apps/lazynote_flutter/lib/features/diagnostics/debug_logs_panel.dart`
- [add] `apps/lazynote_flutter/test/dart_event_logger_test.dart`
- [edit] `apps/lazynote_flutter/test/rust_bridge_test.dart`
- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0210B-diagnostics-log-dart-event-integration.md`

## Dependencies

- `PR-0210C-diagnostics-session-single-file-log-policy`
- `PR-0210A-diagnostics-log-dart-event-ffi-contract`

## Verification Replay

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/dart_event_logger_test.dart test/rust_bridge_test.dart test/debug_logs_panel_test.dart`

## Acceptance Criteria

- [x] Selected call sites emit structured Dart events through FFI.
- [x] Failures in logging path do not break user-facing flows.
- [x] Docs status and rollout boundary are synchronized.

## Closure Notes

- Added centralized wrapper `DartEventLogger` for no-throw FFI event logging.
- Integrated lifecycle and diagnostics call-site allowlist from this PR.
- Locked non-blocking behavior with dedicated logger tests and RustBridge regression.
