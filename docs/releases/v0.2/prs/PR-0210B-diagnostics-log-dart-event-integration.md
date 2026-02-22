# PR-0210B-diagnostics-log-dart-event-integration

- Proposed title: `feat(diagnostics): integrate log_dart_event call sites and safety policy`
- Status: Planned

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

## Execution Split (DOC -> DEV -> CLOSE)

1. DOC: freeze call-site boundary and safety policy
2. DEV: wire call sites + tests
3. CLOSE: replay verification and docs/status closure

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/app/*` (selected lifecycle call sites)
- [edit] `apps/lazynote_flutter/lib/features/diagnostics/*` (selected diagnostics call sites)
- [edit] `apps/lazynote_flutter/test/*` (integration regressions)
- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0210B-diagnostics-log-dart-event-integration.md`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Selected call sites emit structured Dart events through FFI.
- [ ] Failures in logging path do not break user-facing flows.
- [ ] Docs status and rollout boundary are synchronized.
