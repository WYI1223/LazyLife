# PR-0210C-diagnostics-session-single-file-log-policy

- Proposed title: `feat(logging): session-scoped single-file log policy for diagnostics`
- Status: Planned

## Goal

Adopt a session-first logging policy so each app startup writes to its own single log file, and diagnostics viewer reads only the current-session file by default.

## Scope (v0.2)

In scope:

- generate one unique session log filename per process startup
- write all runtime logs of that process into the same session file (no cross-file merge in viewer path)
- keep diagnostics viewer default path as single active file tail read
- add best-effort log retention cleanup policy for historical session files
- keep existing diagnostics parser/rendering behavior unchanged

Out of scope:

- remote log upload
- structured JSON log backend
- `log_dart_event` FFI bridge (tracked by `PR-0210A` / `PR-0210B`)

## Contract Freeze (M1)

This section is the source of truth for implementation.

1. Session file policy
   - one process startup => one log file
   - file naming includes startup timestamp + PID for traceability
   - no append to a previous session file
2. Reader policy
   - diagnostics viewer reads a single file tail (no cross-file concatenation)
   - historical files are accessed via "open log folder" workflow
3. Retention policy
   - best-effort cleanup at init time only
   - cleanup never blocks logging startup on failure
   - cleanup thresholds are explicit and test-covered (`max_age_days`, `max_files`, `max_total_bytes`)
4. Compatibility policy
   - no FFI function signature changes
   - existing `init_logging(level, log_dir)` contract remains unchanged

## Execution Split (DOC -> DEV -> CLOSE)

1. DOC (`PR-0210C`, current)
   - freeze session-file/reader/retention boundaries and non-goals
2. DEV (`PR-0210C`, next commit group)
   - implement session naming + retention cleanup + single-file read expectations
3. CLOSE (`PR-0210C`, final commit group)
   - replay verification and sync release/docs status

## Step-by-Step

1. freeze session filename shape and cleanup thresholds
2. update Rust logging bootstrap from rolling policy to session single-file policy
3. add retention cleanup helper and regression tests
4. verify Flutter diagnostics reader remains single-file tail path
5. replay verification bundle and close docs status

## Planned File Changes

- [edit] `crates/lazynote_core/src/logging.rs`
- [edit] `docs/architecture/logging.md`
- [edit] `apps/lazynote_flutter/lib/core/debug/log_reader.dart` (only if active-file resolution needs explicit session hint)
- [edit] `apps/lazynote_flutter/test/log_reader_test.dart` (if reader assertion changes)
- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0210C-diagnostics-session-single-file-log-policy.md`

## Dependencies

- `PR-0017A-debug-viewer-readability-baseline`
- `PR-0210-debug-viewer-readability-upgrade` (completed; parser/rendering baseline)

## Verification

- `cd crates && cargo test -p lazynote_core logging::tests`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/log_reader_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] One startup produces one session-scoped log file with timestamp+PID identity.
- [ ] Diagnostics default read path remains single-file tail (no cross-file merge).
- [ ] Retention cleanup runs best-effort and is covered by regression tests.
- [ ] Release/docs status is synchronized in closure commit.
