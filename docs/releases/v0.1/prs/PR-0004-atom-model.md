# PR-0004-atom-model

- Proposed title: `core(model): define Atom model + IDs + soft delete`
- Status: Draft

## Goal
Implement the unified Atom domain model.

## Deliverables
- Atom fields in Rust domain model
- serialization/deserialization baseline
- reserved fields for later CRDT support

## Planned File Changes
- [add] `crates/lazynote_core/src/model/mod.rs`
- [add] `crates/lazynote_core/src/model/atom.rs`
- [edit] `crates/lazynote_core/src/lib.rs`
- [add] `crates/lazynote_core/tests/atom_model.rs`

## Dependencies
- PR0003

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
