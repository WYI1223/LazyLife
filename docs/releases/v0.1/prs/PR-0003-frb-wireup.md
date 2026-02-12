# PR-0003-frb-wireup

- Proposed title: `chore(frb): wire lazynote_core <-> lazynote_flutter`
- Status: Draft

## Goal
Enable Flutter calling Rust through FRB.

## Deliverables
- FRB bridge and generated bindings
- scripts/gen_bindings.ps1
- core.ping()/core.version()

## Planned File Changes
- [edit] `crates/lazynote_ffi/Cargo.toml`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [edit] `crates/lazynote_core/src/lib.rs`
- [edit] `scripts/gen_bindings.ps1`
- [add] `apps/lazynote_flutter/lib/core/rust_bridge.dart`
- [gen] `apps/lazynote_flutter/lib/core/bindings/lazynote_api.dart`
- [edit] `apps/lazynote_flutter/pubspec.yaml`

## Dependencies
- PR0000, PR0001, PR0002

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
