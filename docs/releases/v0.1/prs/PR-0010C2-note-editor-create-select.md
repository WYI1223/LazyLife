# PR-0010C2-note-editor-create-select

- Proposed title: `feat(notes-ui): note editor and create/select lifecycle`
- Status: Implemented

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

## Product Decisions (Locked)

1. New note entry point is only in Explorer header (no create button in top tab strip).
2. New note default content is empty string; fallback title rendering (`Untitled`) is UI-only.
3. Editor is writable in-memory in C2 (`TextEditingController` draft), persistence deferred to C3.
4. Frontend uses one shared first-line plain-text title projection for list/tab labels.
5. Detail load failure is rendered in ContentArea center with retry action (no modal popup).

## Landed Notes

1. Added `note_editor.dart` as reusable editable markdown surface.
2. `NotesController` now supports:
   - `createNote()` (`note_create` with empty content)
   - local draft updates (`updateActiveDraft`)
   - editor focus request token (`editorFocusRequestId`)
3. Explorer header now exposes `Create note` action and create-in-flight disabled state.
4. Create success path now enforces:
   - created note inserted to list/cache
   - created note activated as current tab/selection
   - editor focus requested via post-frame token
5. Content area now binds to writable editor draft and renders centered detail error + retry state.

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
- `cd apps/lazynote_flutter && flutter test test/notes_page_c1_test.dart`
- `cd apps/lazynote_flutter && flutter test test/notes_controller_tabs_test.dart`
- `cd apps/lazynote_flutter && flutter test test/notes_page_c2_test.dart`

## Acceptance Criteria

- [x] User can create a note from Notes page.
- [x] Created note is auto-selected and editor is focused.
- [x] Selecting list item updates editor content correctly.
- [x] Detail error state is explicit and recoverable.
