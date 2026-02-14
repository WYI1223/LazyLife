# PR-0207-explorer-context-actions-dnd-baseline

- Proposed title: `feat(notes-ui): explorer context actions and baseline drag reorder`
- Status: Planned

## Goal

Add practical file-manager interactions to explorer tree for daily notes operations.

## Scope (v0.2)

In scope:

- right-click menu:
  - new note
  - new folder
  - rename
  - move
- baseline drag-reorder (same parent first, cross-parent second)
- visual hover action affordances

Out of scope:

- multi-select batch operations
- advanced undo/redo stack for tree operations

## Step-by-Step

1. Add context menu action models and handlers.
2. Add create/rename/move dialogs (minimal UX).
3. Add drag target and reorder indicator behavior.
4. Integrate with tree FFI operations.
5. Add widget tests for core context menu and reorder flows.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_context_menu.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_drag_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/test/explorer_context_actions_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/explorer_context_actions_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Context menu supports create/rename/move actions end-to-end.
- [ ] Drag reorder works for baseline scenarios.
- [ ] Failure paths are explicit and recoverable.

