# PR-0210-debug-viewer-readability-upgrade

- Proposed title: `feat(diagnostics): debug viewer readability phase-2 (semantic normalization + dense rendering)`
- Status: Completed

## Goal

Build phase-2 diagnostics readability on top of the v0.1 baseline, focused on semantic normalization and high-volume scanning quality.

## Scope (v0.2)

In scope:

- normalize mixed timestamp/level raw formats into a stable semantic row model
- tighten severity visual hierarchy in high-density log lists
- preserve existing refresh/coalescing safety behavior
- improve multi-line wrapping and copy workflows for long log rows

Out of scope:

- `log_dart_event` FFI bridge (deferred to `PR-0210A` + `PR-0210B`)
- remote log upload
- full structured JSON log inspector

## Contract Freeze (M1)

This section is the source of truth for implementation.

1. Parse contract
   - line parsing must be best-effort and never throw on unknown formats
   - known patterns map into stable fields (`timestamp`, `level`, `message`, `raw`)
   - unknown patterns keep `raw` intact and degrade to fallback row rendering
2. Rendering contract
   - semantic columns stay stable under mixed input formats
   - severity emphasis remains readable for dense rows (`error` > `warn` > others)
   - fallback rows must still render copyable raw text without truncating source content
3. Copy contract
   - "copy visible logs" keeps original visible raw line text fidelity
4. Refresh safety contract
   - keep current periodic refresh/coalescing/trailing-request logic unchanged
   - readability upgrades must not change current in-flight refresh safety behavior

## Execution Split (DOC -> DEV -> CLOSE)

1. DOC (`PR-0210`, completed)
   - scope/contract/verification frozen and FFI explicitly deferred
2. DEV (`PR-0210`, completed)
   - parser + rendering readability upgrades and regressions landed
3. CLOSE (`PR-0210`, completed)
   - verification replay complete, status/docs index synchronized

## Step-by-Step

1. lock parse matrix and rendering fallback rules from the M1 contract
2. implement parser/rendering upgrades in diagnostics panel path
3. keep refresh/tail pipeline unchanged
4. add regressions for mixed-format parsing + dense rendering fallback behavior
5. run analyze/tests and finalize closure docs

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/diagnostics/debug_logs_panel.dart`
- [edit] `apps/lazynote_flutter/lib/features/diagnostics/log_line_meta.dart`
- [edit] `apps/lazynote_flutter/test/debug_logs_panel_test.dart`
- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0210-debug-viewer-readability-upgrade.md`

## Dependencies

- `PR-0017A-debug-viewer-readability-baseline`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/debug_logs_panel_test.dart`
- `cd apps/lazynote_flutter && flutter test`

Replay result:

- `flutter analyze`: passed
- `flutter test test/debug_logs_panel_test.dart`: passed
- `flutter test`: passed

## Acceptance Criteria

- [x] Parser normalization handles mixed timestamp/level raw formats.
- [x] Dense rows preserve readability and raw copy fidelity.
- [x] Existing refresh stability behavior is preserved.
- [x] PR status/docs index are synchronized in closure commit.
