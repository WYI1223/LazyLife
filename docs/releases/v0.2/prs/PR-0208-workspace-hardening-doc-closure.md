# PR-0208-workspace-hardening-doc-closure

- Proposed title: `chore(workspace): hardening, regression coverage, and doc closure`
- Status: Completed

## Goal

Close v0.2 with explicit hardening regression proof, race-safe workspace behavior, and synchronized docs/contracts.

## Scope (v0.2)

In scope:

- race-condition hardening around pane/tab/buffer transitions
- recovery behavior for FFI `db_error` and stale async responses
- integration tests for explorer + split + editor interaction
- closure docs for release/API/architecture consistency

Out of scope:

- recursive split UX (v0.3)
- long-document performance gates (v0.3)

## Regression Matrix (Bridge PR Replay)

PR-0208 re-verifies findings from PR-0204 / PR-0219 / PR-0220A / PR-0220B after full v0.2 integration.

| Source | Target | Existing Coverage | PR-0208 Action |
|--------|--------|-------------------|----------------|
| PR-0204 R02-1.1 | Draft source must be `buffersByNoteId` | `apps/lazynote_flutter/test/workspace_provider_test.dart` | keep green in replay bundle |
| PR-0204 R02-1.2 | save retry bounded and non-hanging | `apps/lazynote_flutter/test/workspace_provider_test.dart` | add integration race case in `workspace_integration_flow_test.dart` |
| PR-0204 R02-1.3 | closed-tab tag queue must not dispatch FFI | `apps/lazynote_flutter/test/workspace_provider_test.dart` | keep green in replay bundle |
| PR-0219 R01-4 | `journal_mode=WAL` after migrations | migration tests exist, WAL assertion missing | add migration replay WAL assertion in `crates/lazynote_core/tests/db_migrations.rs` |
| PR-0219 R01-5 | `entry_search` stable error codes only | `crates/lazynote_ffi/src/api.rs` tests exist | replay + add explicit regression assertion if needed |
| PR-0220A R02-3.3 | no double `dlopen` after init failure | `apps/lazynote_flutter/test/rust_bridge_test.dart` | keep green in replay bundle |
| PR-0220B R02-2.1 | `loggingLevelOverride` applies at startup bootstrap | `apps/lazynote_flutter/test/rust_bridge_test.dart` | keep green in replay bundle |

## Milestones

### M1 - Regression Codification (now)

1. Add missing replay assertions:
   - WAL mode survives migration chain replay.
   - workspace integration race test (save + pane switching + explorer mutation path baseline).
2. Build one deterministic replay command bundle and record expected outputs.
3. Update PR-0208 checklist to reflect covered/remaining items.

M1 progress:

- [x] WAL replay assertion added: `crates/lazynote_core/tests/db_migrations.rs`
- [x] workspace integration race bundle added: `apps/lazynote_flutter/test/workspace_integration_flow_test.dart`
- [x] bridge regression suites replayed (`cargo test -p lazynote_ffi`, targeted flutter suites)
- [x] consolidate replay evidence in this PR note

### M2 - Runtime Hardening Pass

1. Audit stale async response handling in `NotesController`:
   - list/detail/tag request-id guards
   - save in-flight vs pane switch/close
2. Tighten user-visible recovery:
   - keep existing `SnackBar + Retry` behavior explicit on workspace operations
   - ensure no destructive fallback when FFI returns `db_error`/`db_busy`
3. Add regression tests for any bugfix introduced in this pass.

M2 progress:

- [x] workspace mutation failures now carry actionable retry guidance for `db_busy` / `db_error`
- [x] non-destructive failure regressions added (failed move/delete does not mutate active note/tree revision)
- [x] stale detail-response regression added (late response cannot override newer active note)
- [x] complete remaining audit sweep for notes/workspace core async branches (list/detail/tag/save/workspace mutation paths)

### M3 - Doc Closure and Release Gate

1. Sync docs:
   - `docs/releases/v0.2/README.md`
   - `docs/api/*` (only if contract behavior changed)
   - architecture note updates if state invariants are clarified
2. Execute full replay bundle and capture pass summary.
3. Mark PR-0208 completed with evidence links/commands.

M3 progress:

- [x] sync release docs (`docs/releases/v0.2/README.md`, this PR document)
- [x] API contract review completed: no FFI signature or stable error-code catalog change in this PR
- [x] replay evidence consolidated (Rust + Flutter targeted + Flutter full gate)
- [x] PR status moved to Completed

### M4 - Release Closure Kit Handoff

1. Publish the release-closure three-package execution entry.
2. Sync release roadmap to closure-ready status.
3. Freeze deferred mapping references for v0.3 carry-over.

M4 progress:

- [x] closure execution entry published: `docs/releases/v0.2/CLOSURE_KIT.md`
- [x] roadmap synced with closure-ready marker: `docs/product/roadmap.md`
- [x] deferred mapping references kept explicit in `docs/releases/v0.2/README.md`

## Detailed Execution Steps

1. Run baseline replay on current branch to detect real gaps before patching.
2. Patch tests first (regression locking), then patch runtime behavior only if tests expose gaps.
3. Re-run targeted suites, then expand to full rust/flutter gates.
4. Close docs only after code/test state is stable.

## Planned File Changes

- [edit] `crates/lazynote_core/tests/db_migrations.rs`
- [add] `apps/lazynote_flutter/test/workspace_integration_flow_test.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/*` (if M2 finds race gaps)
- [edit] `apps/lazynote_flutter/lib/features/notes/*` (if M2 finds race gaps)
- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0208-workspace-hardening-doc-closure.md`
- [edit] `docs/api/*` only if runtime contract actually changes

## Verification Bundle

Rust:

- `cd crates && cargo test -p lazynote_core --test db_migrations`
- `cd crates && cargo test -p lazynote_ffi`

Flutter targeted:

- `cd apps/lazynote_flutter && flutter test test/workspace_provider_test.dart test/notes_controller_workspace_bridge_test.dart test/workspace_integration_flow_test.dart test/rust_bridge_test.dart`

Flutter full gate:

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`

Manual smoke (Windows):

- split pane switch while save is pending
- explorer create/rename/move while active editor has unsaved content
- retry path after simulated workspace mutation failure

## Execution Evidence (M1/M2)

- `cd crates && cargo test -p lazynote_core --test db_migrations` (pass, includes WAL replay assertion)
- `cd crates && cargo test -p lazynote_ffi` (pass)
- `cd apps/lazynote_flutter && flutter test test/workspace_integration_flow_test.dart` (pass)
- `cd apps/lazynote_flutter && flutter test test/workspace_provider_test.dart test/notes_controller_workspace_bridge_test.dart test/rust_bridge_test.dart` (pass)
- `cd apps/lazynote_flutter && flutter test` (pass)
- `cd apps/lazynote_flutter && flutter analyze` (pass)

Pre-release packaging dry run (for closure handoff):

- `cd apps/lazynote_flutter && flutter build windows --release --analyze-size --code-size-directory build/code-size` (pass)
- output binary: `apps/lazynote_flutter/build/windows/x64/runner/Release/lazynote_flutter.exe`
- size-analysis files:
  - `apps/lazynote_flutter/build/code-size/snapshot.windows-x64.json`
  - `apps/lazynote_flutter/build/code-size/trace.windows-x64.json`
- packaged artifact: `apps/lazynote_flutter/build/artifacts/lazynote_flutter-windows-x64.zip`
- artifact SHA256: `AACEBBE38BAB2A2BB323636248B1C2EB170609972C17299B636D770D05021470`

Contract closure note:

- `docs/api/ffi-contracts.md`: no function-shape delta introduced by PR-0208
- `docs/api/error-codes.md`: no new/changed stable error code introduced by PR-0208
- Runtime hardening is UI/controller-side messaging and regression locking only

## Acceptance Criteria

- [x] Core workspace interactions are regression-covered.
- [x] Error handling is actionable and non-destructive.
- [x] Release docs and API docs match shipped behavior.
- [x] Bridge-lane regression matrix (0204/0219/0220A/0220B) has explicit replay evidence.
