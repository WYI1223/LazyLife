# PR-0009-single-entry-router

- Proposed title: `ui(entry): single entry (search + command router)`
- Status: Draft

## Goal
One input for both search and commands.

## Deliverables
- > new note / > task / > schedule (minimal)
- default input routes to search_all

## Planned File Changes
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [add] `apps/lazynote_flutter/lib/features/entry/command_router.dart`
- [add] `apps/lazynote_flutter/lib/features/entry/command_parser.dart`
- [add] `apps/lazynote_flutter/lib/features/entry/entry_state.dart`
- [add] `apps/lazynote_flutter/lib/features/search/search_results_view.dart`
- [edit] `crates/lazynote_ffi/src/lib.rs`

## Dependencies
- PR0007, PR0008

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
