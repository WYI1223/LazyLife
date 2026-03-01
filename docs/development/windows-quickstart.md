# Windows Quickstart (New Clone)

Goal: run LazyNote on Windows with the minimum command set.

## Commands

Run these in repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1 -SkipFlutterDoctor
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1
cd apps/lazynote_flutter; flutter pub get
flutter run -d windows
```

## Expected Result

After app startup:

- Workbench home loads.
- `Rust Diagnostics` page is reachable.
- Workbench right panel `Debug Logs (Live)` shows rolling logs and refreshes.
- Logs are written under `%APPDATA%\\LazyLife\\logs\\`.
- When opening `Notes/Tasks/Settings/Rust Diagnostics`, the left pane switches while the right logs panel stays mounted.
- The center splitter can be dragged to resize left/right panes (double-click resets width).

If you see `Failed to load dynamic library`, build Rust FFI first:

```powershell
cd crates
cargo build -p lazynote_ffi --release
cd ..
```

Then run again:

```powershell
cd apps/lazynote_flutter
flutter clean
flutter pub get
flutter run -d windows
```

## Build Windows Release Bundle (Distributable)

From repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_windows_release_bundle.ps1
```

Expected outputs:

- `apps/lazynote_flutter/build/windows/x64/runner/Release/lazynote_flutter.exe`
- `apps/lazynote_flutter/build/windows/x64/runner/Release/lazynote_ffi.dll`
- `apps/lazynote_flutter/build/artifacts/lazynote_flutter-windows-x64.zip`
- `apps/lazynote_flutter/build/artifacts/lazynote_flutter-windows-x64.zip.sha256.txt`

## Toolchain Versions

- Flutter: `3.41.0`
- Rust: `1.93.0`
- FRB codegen: `2.11.1`

## Diagnostics Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/format.ps1 -Check
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1
scripts\run_windows_smoke.bat
```

## FRB Codegen Notes

- FRB codegen command name may be either `frb_codegen` or `flutter_rust_bridge_codegen`
- `scripts/gen_bindings.ps1` will auto-detect either command
- Default config at repo root: `.flutter_rust_bridge.yaml`

## Runtime Paths

- Logs: `%APPDATA%\LazyLife\logs\`
- Settings: `%APPDATA%\LazyLife\settings.json`
- Entry DB: `%APPDATA%\LazyLife\data\lazynote_entry.sqlite3`

## Reminders / Notifications

- Notifications use Windows Toast Notifications via `flutter_local_notifications`
- No special permissions required for local notifications
- `zonedSchedule()` may silently fail on unpackaged debug apps (Windows platform limitation)
- Current workaround: in-process `Timer` + `show()` for scheduled reminders
- App must be running for timer-based reminders to fire (no delivery after app exit/reboot)

## Troubleshooting

- **Foreground-return freeze**: After long background, returning to foreground may freeze. Fixed via lifecycle-aware pause/resume, in-flight refresh coalescing, and tail-window log reads. See `docs/development/bug-archive.md` (`BUG-2026-001`).
- **`Open Log Folder`**: `explorer.exe` may return non-zero even when folder opens successfully. Non-zero without `stderr` is accepted as success.
- **Console warning** `[ERROR:flutter/lib/ui/window/platform_configuration.cc] Reported frame time is older...`: Flutter Windows engine timing warning during resize/drag, non-fatal.
