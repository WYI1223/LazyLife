# Logging Strategy (v0.2)

This document defines LazyNote logging behavior for local diagnostics in v0.2.

## 1. Goals

- Keep diagnostics stable and readable for local debugging.
- Preserve startup safety: logging failures must not block app launch.
- Keep privacy-first policy (metadata logging by default).

## 2. Non-goals

- Remote telemetry or analytics.
- Cross-device log transport.
- Structured JSON log backend (plain text remains baseline in v0.2).

## 3. Ownership and Path Contract

- Flutter resolves the platform log directory and passes it to Rust via
  `init_logging(level, log_dir)`.
- Rust never hardcodes platform paths.
- Example Windows path: `%APPDATA%/LazyLife/logs`.

## 4. Session File Policy (PR-0210C)

- One process startup writes to one session log file.
- Filename includes startup timestamp and PID for traceability.
- Current shape:
  - `lazynote_pid<PID>_<YYYY-MM-DD_HH-MM-SS>.log`
- No append to previous session files.

## 5. Reader Policy (Diagnostics Viewer)

- Default diagnostics path reads tail content from a single active file.
- No cross-file concatenation in default viewer flow.
- Historical files are inspected through "open log folder".

## 6. Retention Policy

Retention cleanup is best-effort and runs during logging initialization only.
Cleanup failures do not block logging startup.

Thresholds:

- `max_age_days = 7`
- `max_files = 20`
- `max_total_bytes = 50MB`

Cleanup applies to managed log files (`lazynote*.log`) and keeps newest files
first while enforcing age/count/size limits.

## 7. FFI Contract

### `init_logging(level, log_dir)`

- Called during startup before core DB operations.
- Idempotent only when `level + log_dir` are unchanged.
- Reconfiguration to a different level or directory in the same process is
  rejected.
- Signature remains unchanged in v0.2 (compatibility requirement).

## 8. Privacy and Redaction

Never log:

- note/task content
- event descriptions
- tokens, secrets, credentials

Log metadata only:

- IDs, status codes, counts, durations, lifecycle events

User-provided strings must be sanitized/truncated before logging.

## 9. Failure Policy

- Logging setup failure returns an error string to caller.
- App launch must continue even if logging bootstrap fails.
- Retention cleanup failures are warning-level and non-fatal.

## 10. Current Implementation Notes

- Rust logger uses `flexi_logger::detailed_format`.
- Panic hook logs sanitized panic summaries and flushes logger handle.
- Diagnostics viewer reads file tail for large files and drops incomplete
  trailing lines to avoid half-written row artifacts.

## 11. Related Specs

- `docs/releases/v0.2/prs/PR-0210-debug-viewer-readability-upgrade.md`
- `docs/releases/v0.2/prs/PR-0210C-diagnostics-session-single-file-log-policy.md`
- `docs/releases/v0.2/prs/PR-0210A-diagnostics-log-dart-event-ffi-contract.md`
- `docs/releases/v0.2/prs/PR-0210B-diagnostics-log-dart-event-integration.md`
