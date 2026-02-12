# PR-0000-scaffold-monorepo

- Proposed title: `chore(repo): scaffold monorepo skeleton`
- Status: Draft

## Goal
Build the monorepo skeleton defined in README.

## Deliverables
- apps/lazynote_flutter (Windows target runnable)
- crates workspace (core/ffi/cli)
- docs and workflow skeleton

## Planned File Changes
- [add] `apps/lazynote_flutter/pubspec.yaml`
- [add] `apps/lazynote_flutter/lib/main.dart`
- [add] `apps/lazynote_flutter/windows/runner/main.cpp`
- [add] `crates/Cargo.toml`
- [add] `crates/lazynote_core/Cargo.toml`
- [add] `crates/lazynote_core/src/lib.rs`
- [add] `crates/lazynote_ffi/Cargo.toml`
- [add] `crates/lazynote_ffi/src/lib.rs`
- [add] `crates/lazynote_cli/Cargo.toml`
- [add] `crates/lazynote_cli/src/main.rs`
- [edit] `.github/workflows/ci.yml`

## Dependencies
- None

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
