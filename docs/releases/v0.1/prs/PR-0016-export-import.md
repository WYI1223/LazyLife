# PR-0016-export-import

- Proposed title: `feat(export): export/import Markdown + JSON + ICS`
- Status: Draft

## Goal
Ensure data portability and backup/restore.

## Deliverables
- export Markdown/JSON/ICS
- import and index rebuild

## Planned File Changes
- [add] `crates/lazynote_core/src/export/mod.rs`
- [add] `crates/lazynote_core/src/export/markdown.rs`
- [add] `crates/lazynote_core/src/export/json.rs`
- [add] `crates/lazynote_core/src/export/ics.rs`
- [add] `crates/lazynote_core/src/import/mod.rs`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [add] `apps/lazynote_flutter/lib/features/settings/backup_restore_page.dart`
- [edit] `docs/product/mvp-scope.md`

## Dependencies
- PR0006, PR0007, PR0010, PR0011, PR0012

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
