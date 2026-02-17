# Windows Development Setup

## Goal

Document reproducible local setup and diagnostics for Windows contributors.

先用最短路径跑通：`docs/development/windows-quickstart.md`

## Toolchain (to confirm)

- Flutter: `3.41.0`
- Rust: `1.93.0`
- FRB codegen: `2.11.1`

## Quick Check

- `scripts/doctor.ps1`
- `scripts/format.ps1 -Check`

## 常用命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/format.ps1 -Check
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1
scripts\run_windows_smoke.bat
```

## FRB (PR-A) Quick Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1

cd crates
cargo test -p lazynote_ffi

cd ..\apps\lazynote_flutter
flutter pub get
flutter analyze
```

## PR-B Quick Commands

```powershell
cd crates
cargo build -p lazynote_ffi --release

cd ..\apps\lazynote_flutter
flutter test
flutter run -d windows
```

Expected output for PR-A:

- Rust tests pass for `lazynote_ffi`.
- Flutter analyze passes.
- FRB generated files are updated in:
  - `crates/lazynote_ffi/src/frb_generated.rs`
  - `apps/lazynote_flutter/lib/core/bindings/`
  - `apps/lazynote_flutter/lib/core/bindings/api.dart`
  - `apps/lazynote_flutter/windows/runner/generated_frb.h`

## Notes

Windows 构建/运行：必须在 Windows 本机执行

Docker：仅用于 Rust 工具链/CI（可选）

- FRB codegen command name may be either:
  - `frb_codegen`
  - `flutter_rust_bridge_codegen`
- `scripts/gen_bindings.ps1` will auto-detect either command.
- 默认配置在仓库根目录 `.flutter_rust_bridge.yaml`，脚本优先使用该配置。
- Flutter 启动时会优先探测 workspace 动态库路径：
  - `../../crates/target/release/`
  - `../../crates/lazynote_ffi/target/release/` (backward compatible)
- 本地运行时文件统一落到 `%APPDATA%\\LazyLife\\`：
  - logs: `%APPDATA%\\LazyLife\\logs\\`
  - settings: `%APPDATA%\\LazyLife\\settings.json`
  - entry db: `%APPDATA%\\LazyLife\\data\\lazynote_entry.sqlite3`

## Reminders / Notifications (PR-0013)

### Dependencies

- `flutter_local_notifications: ^20.1.0` - Cross-platform local notifications
- `flutter_local_notifications_windows: ^2.0.1` - Windows implementation

### Windows Runtime Notes

- Notifications use Windows Toast Notifications via `flutter_local_notifications`
- No special permissions required for local notifications (unlike push notifications)
- `zonedSchedule()` may silently fail on unpackaged debug apps (Windows platform limitation)
- Current workaround: in-process `Timer` + `show()` for scheduled reminders
- v0.1 reminder policy is single-fire per atom (event reminders are start-side only; no end-time reminder)
- App must be running for timer-based reminders to fire (no delivery after app exit/reboot)
- Notification ID: Derived from atom ID + timestamp hash (int32 range)

### Testing

```powershell
cd apps\lazynote_flutter
flutter run -d windows
```

Create a task with a deadline (e.g., "Submit report" with end_at = today + 1 hour) to test notification scheduling.
Keep the app running until the reminder time to verify timer-based delivery.

## Troubleshooting (Known)

- Foreground-return freeze after long background:
  - Symptom: after window stays out of focus for a long time, returning to foreground may freeze within 1-2s.
  - Root cause (fixed): logs panel periodic refresh backlog + full-file log reads on large files.
  - Fix:
    - lifecycle-aware pause/resume for periodic refresh
    - in-flight refresh coalescing (drop overlap backlog)
    - large-file tail-window reads instead of full-file reads
  - Archive: `docs/development/bug-archive.md` (`BUG-2026-001`)

- `Open Log Folder` on Windows:
  - `explorer.exe` may return non-zero even when folder opens successfully.
  - Current implementation treats `stderr` output or a missing target directory as failure.
  - For compatibility, non-zero without `stderr` is still accepted as success.

- Console warning:
  - `[ERROR:flutter/lib/ui/window/platform_configuration.cc] Reported frame time is older than the last one; clamping`
  - Usually appears during resize/drag/rapid repaint.
  - This is a Flutter Windows engine timing warning and is typically non-fatal.
