# PR-0017-workbench-debug-logs

- Proposed title: `ui(debug): show local rolling logs in workbench`
- Status: Completed

## Goal
Show local rolling logs directly in Workbench so developers can inspect runtime logs while validating flows.

## Deliverables
- shared right-side inline logs panel in Workbench and placeholder pages
- fixed split-shell behavior: left pane switches content in-place while right logs pane stays mounted
- logs panel reads local rolling log files from app support `logs/` directory
- show latest file tail (for example last 200 lines) with `Refresh`
- auto refresh logs every 3 seconds during local run
- draggable vertical splitter to resize left/right panes (double-click resets width)
- refresh race hardening: overlapping refresh requests only apply the newest result
- quick actions:
  - copy visible logs to clipboard
  - open log folder in OS file explorer with explicit failure detection

## Planned File Changes
- [edit] `apps/lazynote_flutter/lib/app/app.dart`
- [edit] `apps/lazynote_flutter/lib/features/diagnostics/rust_diagnostics_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [add] `apps/lazynote_flutter/lib/features/entry/workbench_shell_layout.dart`
- [add] `apps/lazynote_flutter/lib/features/diagnostics/debug_logs_panel.dart`
- [add] `apps/lazynote_flutter/lib/core/debug/log_reader.dart`
- [add] `apps/lazynote_flutter/test/debug_logs_panel_test.dart`
- [add] `apps/lazynote_flutter/test/log_reader_test.dart`
- [edit] `apps/lazynote_flutter/test/smoke_test.dart`
- [edit] `apps/lazynote_flutter/test/widget_test.dart`
- [edit] `docs/development/windows-quickstart.md`

## Dependencies
- PR0008 (Workbench shell and placeholder routes)
- logging foundation merged in `lazynote_core` + FFI + Flutter bootstrap

## Acceptance Criteria
- [x] Scope implemented
- [x] Basic verification/tests added
- [x] Documentation updated if behavior changes

## Notes
- This PR is for local diagnostics only, not telemetry and not remote upload.
- Workbench panel shows existing local files as-is; privacy controls remain enforced at log production points in Rust core.
- Windows-specific behavior: `explorer.exe` may return non-zero even when folder opens; implementation now treats explicit `stderr` or missing target directory as failure, and keeps non-fatal compatibility for the non-zero/no-stderr case.
- Overflow hardening: logs panel uses bounded/expanded layout and message truncation to avoid vertical RenderFlex overflow.
- Concurrency hardening: logs refresh is request-versioned to prevent stale async completions from overwriting newer snapshots.
- Post-completion stability hardening (2026-02-13):
  - lifecycle-aware refresh pause/resume for background/foreground transitions
  - refresh coalescing to avoid queue buildup when overlap happens
  - large-file tail-window reads to avoid repeated full-file decoding
- Follow-up in v0.1 planning:
  - `PR-0017A` adds readability baseline (timestamp normalization + severity color) without changing refresh pipeline.
- Added tests:
  - concurrent refresh ordering (`debug_logs_panel_test.dart`)
  - overlapping refresh coalescing (`debug_logs_panel_test.dart`)
  - open-log-folder failure/success heuristics (`log_reader_test.dart`)
  - large-log tail-reader selection (`log_reader_test.dart`)
- Out of scope:
  - in-app log filtering/search syntax
  - zip export workflow
  - cloud upload
- Suggested verification:
  - `cd apps/lazynote_flutter && flutter analyze`
  - `cd apps/lazynote_flutter && flutter test`
  - `flutter run -d windows` then verify logs update after app actions
- Verification status: passed locally.
- Incident archive: `docs/development/bug-archive.md` (`BUG-2026-001`).
