# PR-0205B-explorer-tab-open-intent-migration

- Proposed title: `refactor(notes-tab): move preview/pinned semantics ownership from explorer to tab model`
- Status: Planned

## Goal

Make preview/pinned semantics a tab-model concern and keep explorer behavior as
pure open-intent emission.

## Background

- `PR-0205` established recursive lazy explorer and open intent callbacks.
- VSCode-like single/double-click semantics should be owned by top tab model
  (single click activate, double click pin/solidify), not hardcoded in explorer.
- `PR-0304` defines long-term preview/pinned model ownership; this PR provides
  a v0.2 transition path to avoid behavior drift.

## Scope (v0.2 transition)

In scope:

- explorer emits one open intent (`open(noteId)`) without semantic branching.
- tab strip / tab state model accepts interaction semantics ownership.
- document ownership boundary: explorer = intent source, tab model = semantic
  decision.
- regression tests for single/double behavior at tab layer.

Out of scope:

- introducing new Rust FFI APIs.
- cross-pane preview/pinned persistence policy expansion (full lane in `PR-0304`).

## Contract Impact

- FFI/API shape delta: none.
- UI contract delta:
  - `PR-0205` no longer claims explorer-level double-click semantics as shipped
    behavior.
  - ownership moved to tab model lane (`PR-0304`).

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_tab_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `docs/releases/v0.2/prs/PR-0205-explorer-recursive-lazy-ui.md`
- [edit] `docs/releases/v0.3/prs/PR-0304-tab-preview-pinned-model.md`
- [edit] `docs/api/ffi-contracts.md`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/notes_controller_tabs_test.dart`
- `cd apps/lazynote_flutter && flutter test test/notes_page_c1_test.dart test/notes_page_c2_test.dart test/notes_page_c3_test.dart test/notes_page_c4_test.dart`

## Acceptance Criteria

- [ ] Explorer no longer carries runtime semantic ownership for preview/pinned.
- [ ] Top tab model owns single/double click semantic decisions.
- [ ] Contract docs explicitly reflect ownership boundary and no longer drift.
