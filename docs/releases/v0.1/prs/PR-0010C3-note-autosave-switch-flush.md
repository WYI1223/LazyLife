# PR-0010C3-note-autosave-switch-flush

- Proposed title: `feat(notes-ui): debounced autosave and switch flush consistency`
- Status: Planned

## Goal

Implement non-blocking save behavior with deterministic consistency during note switching.

## Locked Product Decisions

1. Save strategy is `1.5s` debounced auto-save.
2. Switching notes forces pending save flush.
3. No unsaved-changes modal in switch path.

## Scope (v0.1)

In scope:

- debounced `note_update` write path
- dirty/saving/error state signals
- forced flush before note selection switch commits
- stale async write-back guard

Out of scope:

- offline queue / long-term sync semantics
- collaborative editing conflict resolution

## Step-by-Step

1. Add debounce timer path for editor text mutations (`1.5s`).
2. Add explicit persistence states in controller:
   - clean
   - dirty
   - saving
   - save_error
3. Implement `flushPendingSave()` and call it in note-switch workflow.
4. Add request-id or equivalent ordering guard to drop stale save completion callbacks.
5. Add recovery path for save failure with retry.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_editor.dart`
- [add] `apps/lazynote_flutter/test/notes_page_c3_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/notes_page_c3_test.dart`

## Acceptance Criteria

- [ ] Typing pauses trigger one debounced save after `1.5s`.
- [ ] Switching note flushes pending save before switching selected note.
- [ ] Save failure does not lose in-memory edits and provides retry path.
- [ ] Stale save completion cannot overwrite newer editor state.

