# PR-0010-notes-tags

- Proposed title: `ui(notes+tags): markdown editor + tag filter`
- Status: Draft

## Goal
Deliver v0.1 notes editing and tag filtering.

## Deliverables
- notes list + detail editor
- tag filter baseline

## Planned File Changes
- [add] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/note_editor.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [add] `apps/lazynote_flutter/lib/features/tags/tag_filter.dart`
- [add] `crates/lazynote_core/src/repo/tag_repo.rs`
- [add] `crates/lazynote_core/src/service/note_service.rs`
- [edit] `crates/lazynote_ffi/src/lib.rs`
- [add] `apps/lazynote_flutter/test/notes_flow_test.dart`

## Dependencies
- PR0006, PR0007, PR0008, PR0009

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
