# PR-0006-core-crud

- Proposed title: `core(repo): Atom CRUD + basic queries`
- Status: Draft

## Goal
Provide stable core CRUD operations.

## Deliverables
- create/update/get/list/soft_delete
- repository interface and tests

## Planned File Changes
- [add] `crates/lazynote_core/src/repo/mod.rs`
- [add] `crates/lazynote_core/src/repo/atom_repo.rs`
- [add] `crates/lazynote_core/src/service/atom_service.rs`
- [edit] `crates/lazynote_core/src/lib.rs`
- [add] `crates/lazynote_core/tests/atom_crud.rs`
- [edit] `crates/lazynote_ffi/src/lib.rs`

## Dependencies
- PR0005

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
