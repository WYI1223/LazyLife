# PR-0010C2-note-editor-create-select

- Proposed title: `feat(notes-ui): note editor and create/select lifecycle`
- Status: Planned

## Goal

Enable end-to-end note selection, note creation, and editor binding inside the Notes page.

## Scope (v0.1)

In scope:

- editor view for selected note content
- create note action (`note_create`)
- select note -> load detail (`note_get`) -> bind editor content
- create success behavior: auto-select created note + autofocus editor

Out of scope:

- debounced autosave
- switch-flush persistence guarantees
- tag filter

## UI Requirements

1. Continue using C1 shell slots (`NoteExplorer` / `NoteTabManager` / `NoteContentArea`) without collapsing back into a monolithic page widget.
2. Editor region reflects active tab note title/content.
3. New note action is discoverable near explorer or tab controls.
4. After create success:
   - new note becomes active selection and active tab
   - editor input receives focus without extra click
5. Detail load failure is explicit and allows retry.

Interaction constraints:

- Explorer open-request flow remains command/event style; content area only reacts to `activeNoteId`.

## Step-by-Step

1. Add `note_editor.dart` and bind to controller selected-note state.
2. Implement create flow (`note_create`) and post-create selection transition.
3. Implement note selection detail fetch and editor model update.
4. Add focus management for create/select transitions.
5. Add tests for create/select/editor bindings.

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/note_editor.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_tab_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_content_area.dart`
- [add] `apps/lazynote_flutter/test/notes_page_c2_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/notes_page_c2_test.dart`

## Acceptance Criteria

- [ ] User can create a note from Notes page.
- [ ] Created note is auto-selected and editor is focused.
- [ ] Selecting list item updates editor content correctly.
- [ ] Detail error state is explicit and recoverable.
