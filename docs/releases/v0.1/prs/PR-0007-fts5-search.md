# PR-0007-fts5-search

- Proposed title: `core(search): FTS5 full-text index + search_all()`
- Status: Draft

## Goal
Deliver type-to-results full-text search.

## Deliverables
- FTS5 index table
- index update strategy
- search(query) summary output

## Planned File Changes
- [add] `crates/lazynote_core/src/search/mod.rs`
- [add] `crates/lazynote_core/src/search/fts.rs`
- [add] `crates/lazynote_core/src/db/migrations/0004_fts.sql`
- [add] `crates/lazynote_core/tests/search_fts.rs`
- [edit] `crates/lazynote_ffi/src/lib.rs`

## Dependencies
- PR0005, PR0006

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
