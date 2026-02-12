# PR-0003-frb-wireup

- Proposed title (PR-A): `chore(frb): wire minimal ffi api (ping/core_version)`
- Proposed title (PR-B): `feat(flutter): call rust ping/core_version on windows`
- Status: In Progress (A)

## Goal
Split FRB wiring into two small PRs, so we can isolate problems:

- PR-A: make codegen/bindings/dylib chain valid
- PR-B: make Flutter Windows call Rust APIs in UI

## Deliverables
- PR-A:
  - Rust FRB API: `ping()` / `core_version()`
  - FRB config file: `.flutter_rust_bridge.yaml`
  - stable binding generation script (`scripts/gen_bindings.ps1`)
  - generated FRB artifacts committed to repo
  - Flutter dependency pin for `flutter_rust_bridge` runtime
- PR-B:
  - Flutter-side bridge wrapper
  - Windows app actually calls `ping()` / `core_version()`
  - UI shows result (DLL load/runtime chain proof)

## Scope Of This PR (A)

In scope:

- `crates/lazynote_ffi` exposes only minimal use-case-level health APIs.
- FRB generation command is reproducible from `scripts/gen_bindings.ps1`.
- Generated files are updated and tracked.

Out of scope:

- Flutter UI integration and lifecycle init calls.
- any domain/business feature beyond connectivity smoke-check.

## Planned File Changes
- [add] `.flutter_rust_bridge.yaml`
- [edit] `crates/lazynote_ffi/Cargo.toml`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [add] `crates/lazynote_ffi/src/api.rs`
- [gen] `crates/lazynote_ffi/src/frb_generated.rs`
- [edit] `scripts/gen_bindings.ps1`
- [edit] `apps/lazynote_flutter/pubspec.yaml`
- [edit] `apps/lazynote_flutter/pubspec.lock`
- [gen] `apps/lazynote_flutter/lib/core/bindings/api.dart`
- [gen] `apps/lazynote_flutter/lib/core/bindings/frb_generated.dart`
- [gen] `apps/lazynote_flutter/lib/core/bindings/frb_generated.io.dart`
- [gen] `apps/lazynote_flutter/windows/runner/generated_frb.h`

## Dependencies
- PR0000, PR0001, PR0002

## Acceptance Criteria
- [ ] PR-A scope implemented
- [ ] `scripts/gen_bindings.ps1` can regenerate bindings from config
- [ ] `cargo test -p lazynote_ffi` passes
- [ ] `flutter analyze` passes after dependency update
- [ ] Documentation updated if behavior changes

## Verification Commands (PR-A)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1

cd crates
cargo test -p lazynote_ffi

cd ..\apps\lazynote_flutter
flutter pub get
flutter analyze
```

## Notes
- Keep FRB versions aligned (`2.11.1`) across Rust and Flutter runtime/codegen.
