# PR-0005-sqlite-schema-migrations

- Proposed title: `core(db): sqlite schema + migrations + open_db()`
- Status: Draft

## Goal
Make SQLite the canonical local storage with migrations.

## Deliverables
- atoms/tags/atom_tags/external_mappings
- migration versioning
- open_db() bootstrap

## Planned File Changes
- [add] `crates/lazynote_core/src/db/mod.rs`
- [add] `crates/lazynote_core/src/db/open.rs`
- [add] `crates/lazynote_core/src/db/migrations/mod.rs`
- [add] `crates/lazynote_core/src/db/migrations/0001_init.sql`
- [add] `crates/lazynote_core/src/db/migrations/0002_tags.sql`
- [add] `crates/lazynote_core/src/db/migrations/0003_external_mappings.sql`
- [edit] `crates/lazynote_core/Cargo.toml`

## Dependencies
- PR0004

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
