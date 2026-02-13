# Bug Archive

## BUG-2026-001: Workbench Freezes After Long Background

- Date: 2026-02-13
- Scope: `apps/lazynote_flutter` (Workbench debug logs panel)
- Status: Fixed

### Symptom

- App window stays in background for a long time, then regains focus.
- Within around 1-2 seconds after returning to foreground, UI may become unresponsive.
- In some runs, logs panel also showed scrollbar-related warnings during heavy refresh windows.

### Root Cause

- Debug logs panel continued periodic refresh while app was not active.
- Refresh requests could overlap; pending refresh work accumulated and created a backlog.
- Log reading used full-file `readAsString()` on every refresh; large rolling log files amplified UI pressure.

### Fix

1. Lifecycle-aware refresh pause/resume:
   - stop periodic timer when app is inactive/paused/hidden/detached
   - restart timer and run one refresh when app resumes
2. Refresh coalescing:
   - allow only one in-flight refresh
   - merge overlapping requests into one trailing refresh
3. Large file tail-window read:
   - for large logs, read only a fixed tail byte window, then tail lines
   - avoid decoding entire file repeatedly
4. Scrollbar stability hardening (related diagnostics UX):
   - explicit single scrollbar ownership with one `ScrollController`
   - disable local auto-scrollbar wrapping in results subtree

### Verification

- `flutter analyze` passes.
- `flutter test` passes (including:
  - refresh overlap/coalescing tests
  - large-log tail-reader selection test).
- Manual run (`flutter run -d windows`) no longer reproduces the foreground-return freeze under the same scenario.

### Files

- `apps/lazynote_flutter/lib/features/diagnostics/debug_logs_panel.dart`
- `apps/lazynote_flutter/lib/core/debug/log_reader.dart`
- `apps/lazynote_flutter/test/debug_logs_panel_test.dart`
- `apps/lazynote_flutter/test/log_reader_test.dart`
