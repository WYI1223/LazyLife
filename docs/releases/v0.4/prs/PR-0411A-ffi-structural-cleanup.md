# PR-0411A: FFI Structural Cleanup

- Proposed title: `refactor(ffi): split guarded FFI surface into focused modules`
- Status: Draft

## Goal

After `PR-0411` merges, split `crates/lazynote_ffi/src/api.rs` into a focused
module tree without changing the public FFI contract, runtime behavior, or
guard semantics.

## Why This Is A Separate PR

`PR-0411` is a behavioral landing PR: it introduces guarded FFI contracts,
compatibility wrappers, and error-surface changes. The large `api.rs` split is
useful, but it would add review noise and make behavioral regressions harder to
isolate if it were mixed into the same review stream.

This PR exists to hold that structural responsibility explicitly as a follow-on
cleanup sub-PR.

## Preconditions

- `PR-0411` is merged.
- No unresolved review findings remain on the guarded FFI behavior.
- If downstream work is still actively editing `crates/lazynote_ffi/src/api.rs`,
  prefer waiting until that churn settles before opening this PR.

## Scope

### In Scope

- Split `crates/lazynote_ffi/src/api.rs` into `crates/lazynote_ffi/src/api/`
  modules.
- Keep public FRB function names, signatures, sync/async attributes, and
  response envelopes unchanged.
- Move internal helpers into focused modules:
  - `*_impl`
  - `with_*_service`
  - `map_*_error`
  - DTO/response mapping helpers
- Reorganize FFI tests to match the new module structure.
- Regenerate bindings if the module move requires it.

### Out Of Scope

- New FFI endpoints
- Error-code redesign
- Guard rule changes
- Rust Core behavior changes
- Flutter consumer migration beyond any required compile-validation work

## Target Structure

- `crates/lazynote_ffi/src/api/mod.rs`
- `crates/lazynote_ffi/src/api/entry.rs`
- `crates/lazynote_ffi/src/api/notes.rs`
- `crates/lazynote_ffi/src/api/workspace.rs`
- `crates/lazynote_ffi/src/api/tasks.rs`
- `crates/lazynote_ffi/src/api/calendar.rs`
- `crates/lazynote_ffi/src/api/errors.rs`
- `crates/lazynote_ffi/src/api/mappers.rs`
- `crates/lazynote_ffi/src/api/support.rs`

## Planned File Changes

- `[delete/replace]` `crates/lazynote_ffi/src/api.rs`
- `[add]` `crates/lazynote_ffi/src/api/mod.rs`
- `[add]` `crates/lazynote_ffi/src/api/entry.rs`
- `[add]` `crates/lazynote_ffi/src/api/notes.rs`
- `[add]` `crates/lazynote_ffi/src/api/workspace.rs`
- `[add]` `crates/lazynote_ffi/src/api/tasks.rs`
- `[add]` `crates/lazynote_ffi/src/api/calendar.rs`
- `[add]` `crates/lazynote_ffi/src/api/errors.rs`
- `[add]` `crates/lazynote_ffi/src/api/mappers.rs`
- `[add]` `crates/lazynote_ffi/src/api/support.rs`
- `[conditional regen]` `crates/lazynote_ffi/src/frb_generated.rs`
- `[conditional regen]` `apps/lazynote_flutter/lib/core/bindings/`

## Verification

```bash
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1
cd apps/lazynote_flutter
flutter analyze
flutter test
cd ../..
dart run tools/ci/architecture_check.dart
```

## Acceptance Criteria

- `api.rs` is decomposed into the target module tree.
- Public FFI contract is unchanged.
- Generated bindings remain valid.
- Rust and Flutter verification gates pass.
- No ADR, ruling, topic-map, or workspace carrier-promotion surfaces are updated
  by this cleanup PR.
