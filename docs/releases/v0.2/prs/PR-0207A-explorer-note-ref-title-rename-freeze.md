# PR-0207A-explorer-note-ref-title-rename-freeze

- Proposed title: `fix(notes-ui): freeze note_ref rename and unify explorer title projection`
- Status: Completed

## Goal

Close the v0.2 semantic gap between documentation and runtime behavior for
Explorer note rows:

- freeze `note_ref` rename in UI
- keep folder rename enabled
- unify note row title rendering to Atom/draft projection

## Background

- `PR-0207` M1 landed context actions and refresh stability.
- Follow-up review found policy drift:
  - note rows still exposed rename in some paths
  - non-`Uncategorized` note rows could still prefer `display_name` over
    Atom-projected title

This PR is the focused closure patch for that drift.

## Requirement Freeze (v0.2)

1. `note_ref` rows are not renameable in Explorer.
2. `folder` rows remain renameable.
3. Explorer note labels are title projections from Atom content/draft state.
4. `workspace_nodes.display_name` remains schema-compatible but is not treated
   as independent editable note alias in v0.2.

## Scope

In scope:

- disable note-row rename menu entry
- add runtime guard that rename dialog only executes for folders
- unify note-row label projection logic for all folders (including nested)
- add regression tests for policy freeze

Out of scope:

- Rust schema/FFI shape changes
- new error-code namespaces
- v3 alias model for independent `note_ref` titles

## Implementation

1. `NoteExplorer` context menu:
   - `note_ref` target no longer exposes `Rename`
2. Rename guard:
   - `_showRenameNodeDialog` returns early when node kind is not `folder`
3. Note title projection:
   - note row label uses `controller.titleForTab(atomId)` as primary source
   - fallback to node `display_name` only when projected title is unresolved
4. Tests:
   - note-row context menu does not show rename action
   - folder-contained note rows update title when draft title changes

## Contract Impact

- no Rust FFI API add/remove/rename
- no generated binding shape change
- aligns implementation with:
  - `docs/architecture/data-model.md`
  - `docs/architecture/note-schema.md`
  - `docs/api/ffi-contracts.md`
  - `docs/api/workspace-tree-contract.md`

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [edit] `apps/lazynote_flutter/test/explorer_context_actions_test.dart`
- [edit] `apps/lazynote_flutter/test/note_explorer_tree_test.dart`
- [edit] `docs/architecture/data-model.md`
- [edit] `docs/architecture/note-schema.md`
- [edit] `docs/api/ffi-contracts.md`
- [edit] `docs/api/workspace-tree-contract.md`
- [edit] `docs/releases/v0.2/prs/PR-0207-explorer-context-actions-dnd-baseline.md`
- [edit] `docs/releases/v0.2/prs/PR-0221-workspace-tree-delete-policy-hybrid.md`
- [edit] `docs/releases/v0.2/README.md`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/explorer_context_actions_test.dart test/note_explorer_tree_test.dart test/notes_page_explorer_slot_wiring_test.dart`

## Acceptance Criteria

- [x] Note-row context menu no longer exposes rename.
- [x] Folder-row rename remains available and functional.
- [x] Explorer note labels follow Atom/draft title projection consistently.
- [x] Regression tests cover policy freeze and title projection behavior.
- [x] Docs/contracts and implementation are synchronized.
