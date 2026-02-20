# PR-0207-explorer-context-actions-dnd-baseline

- Proposed title: `feat(notes-ui): explorer context actions and baseline drag reorder`
- Status: In Review (M1 landed)

## Goal

Add practical file-manager interactions to explorer tree for daily notes operations.

## Background

- `PR-0205` delivered recursive lazy tree baseline.
- `PR-0205B` froze explorer/tab open-intent ownership.
- `PR-0206`/`PR-0206B` stabilized pane/layout behavior.
- `PR-0207A` closes v0.2 note-row title/rename semantic alignment after M1.
- `PR-0207` now fills explorer operation baseline (context actions first, drag later).

## Requirement Freeze (confirmed 2026-02-20)

1. Synthetic root `__uncategorized__` is not renameable/movable/deletable.
2. `New note` in folder uses create-note + create-note-ref, then auto-open.
3. `Move` in M1 uses minimal dialog (pick target parent) rather than drag UX.
4. Right-click on blank explorer area exposes create actions.
5. Explorer refresh must preserve expand/collapse state (no forced re-expand/reset).
6. `note_ref` rename is frozen in v0.2; rename entry is folder-only.
7. Explorer note row title uses Atom title projection (including draft-aware projection), not independent `note_ref` alias editing.
8. `dissolve` display mapping follows hybrid policy: note refs return to synthetic `Uncategorized`, while child folders are promoted to root.

## Scope (v0.2)

In scope:

- right-click menu:
  - new note
  - new folder
  - rename (folder-only in v0.2)
  - move
- baseline drag-reorder (same parent first, cross-parent second; post-M1)
- visual hover action affordances

Out of scope:

- multi-select batch operations
- advanced undo/redo stack for tree operations
- recursive split-aware drag orchestration
- advanced move tree-picker UX (search, breadcrumb, keyboard nav)

## M1 Boundary (start implementation against this)

M1 only lands context actions and deterministic refresh behavior:

- context menu action model + action dispatch
- create note / create folder / rename(folder) / move dialogs (minimal UX)
- strict synthetic-root guardrails
- expansion-state preservation during tree reload
- regression tests for action success/failure paths

M1 explicitly does **not** include drag reorder implementation.

## Step-by-Step

1. Freeze action boundary and menu matrix:
   - node row menu (`folder`, `note_ref`, synthetic root)
   - blank-area menu
2. Implement action handlers with guardrails:
   - reject rename/move/delete for synthetic root
   - map synthetic-root create-parent semantics to root (`null`) path
3. Implement M1 dialogs:
   - create folder
   - create note (name optional policy consistent with existing note create flow)
   - rename (folder-only)
   - move (target parent picker, no drag)
4. Wire operations through existing controller/FFI flows:
   - use existing workspace APIs only
   - no new Rust contract shape
5. Preserve visual state:
   - keep expanded folder set and active selection stable after refresh
6. Add M1 regressions:
   - action visibility matrix
   - create/rename/move success + recoverable failure
   - expansion-state preservation assertions

## Contract Impact

- No Rust FFI API add/remove/rename in M1.
- No new stable error-code namespace in M1.
- M1 consumes existing contracts:
  - `workspace_list_children`
  - `workspace_create_folder`
  - `workspace_create_note_ref`
  - `workspace_rename_node` (folder nodes only in v0.2 UI policy)
  - `workspace_move_node`
  - existing note create/open contracts
- UI-local guard policy is documented in `docs/api/ffi-contracts.md` under PR-0207 section.

## Implementation Notes (M1 landed)

- added explorer context menu model in
  `apps/lazynote_flutter/lib/features/notes/explorer_context_menu.dart`
- `NoteExplorer` now supports:
  - right-click blank-area create menu
  - folder/note row context actions (new note/new folder/move/delete; rename kept for folder rows)
  - right-click dispatch dedup (row menu has priority over blank-area menu)
  - synthetic root guardrails (`__uncategorized__` cannot rename/move/delete)
  - root-parent normalization for synthetic root create/move
  - deterministic branch refresh after mutations:
    - child-folder delete refreshes affected parent branch immediately
    - child-folder rename refreshes affected parent branch immediately
    - no stale/ghost child row remains in explorer cache
  - synthetic `Uncategorized` note rows project live title from controller draft
- `NotesController` now exposes M1 workspace mutation APIs:
  - `createWorkspaceNoteInFolder`
  - `renameWorkspaceNode`
  - `moveWorkspaceNode`
- `NotesPage` wires explorer context callbacks to controller actions.
- default first-party slot chain is fully wired (not fallback-only):
  - `notes_on_create_note_in_folder_requested`
  - `notes_on_rename_node_requested`
  - `notes_on_move_node_requested`
- M1 regression tests added:
  - `apps/lazynote_flutter/test/explorer_context_actions_test.dart`
  - `apps/lazynote_flutter/test/notes_controller_workspace_tree_guards_test.dart`
  - `apps/lazynote_flutter/test/notes_page_explorer_slot_wiring_test.dart`
  - `apps/lazynote_flutter/test/note_explorer_tree_test.dart` (rename/delete child branch refresh)

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_context_menu.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/test/explorer_context_actions_test.dart`
- [edit] `docs/api/ffi-contracts.md`
- [edit] `docs/releases/v0.2/README.md`

M2 expected additions:

- [add] `apps/lazynote_flutter/lib/features/notes/explorer_drag_controller.dart`
- [edit] `apps/lazynote_flutter/test/explorer_context_actions_test.dart` (drag cases)

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/explorer_context_actions_test.dart`
- `cd apps/lazynote_flutter && flutter test`

Verification replay (2026-02-20):

- `flutter analyze` passed.
- `flutter test test/explorer_context_actions_test.dart test/notes_controller_workspace_tree_guards_test.dart test/note_explorer_tree_test.dart test/note_explorer_workspace_delete_test.dart` passed.
- `flutter test` passed.

## Acceptance Criteria (M1)

- [x] Context menu supports create/folder-rename/move actions end-to-end.
- [x] Synthetic root guardrails are enforced (`__uncategorized__` non-movable/non-renameable).
- [x] Blank-area menu supports create actions.
- [x] Create/move/rename refresh keeps explorer expand/collapse state stable.
- [x] M1 lands without FFI contract shape drift.
- [x] Failure paths are explicit and recoverable.

## Follow-up (M2+)

- M2: drag reorder baseline (same-parent then cross-parent) with clear drop indicators.
- M3: hardening/docs closure (error/retry UX, edge-case regression expansion).
