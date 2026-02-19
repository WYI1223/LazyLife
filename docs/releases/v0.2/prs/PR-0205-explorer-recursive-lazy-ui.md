# PR-0205-explorer-recursive-lazy-ui

- Proposed title: `feat(notes-explorer): recursive explorer with lazy folder loading`
- Status: In Progress (implementation landed, pending final review)

## Goal

Replace flat explorer behavior with a recursive tree interaction model driven by core hierarchy APIs.

## References

- `docs/product/ui-standards/note-ui-dev-spec.md`
- `docs/product/ui-standards/note-ui.md`
- `docs/product/ui-standards/task-ui-dev-spec.md`
- `docs/product/ui-standards/calendar-ui-dev-spec.md`
- `docs/api/workspace-tree-contract.md`
- `docs/api/ffi-contracts.md`

## Dependency

- `PR-0205A-notes-ui-shell-alignment` should land first (or provide equivalent shell alignment),
  so this PR can focus only on explorer behavior.
- Note explorer visual style must follow the same shell token language used by
  Notes/Task/Calendar surfaces (container, divider, spacing, row state emphasis).

## Scope (v0.2)

In scope:

- recursive folder rendering
- lazy load children on expand
- single-click emits preview-open intent callback
- double-click emits pinned-open intent callback
- folder row action: create child folder (UUID parent only)
- hover-first minimalist explorer actions
- explorer-level loading/error/empty states for lazy children

Out of scope:

- notes page shell visual alignment (handled by `PR-0205A`)
- full drag edge split behavior
- advanced tree virtualization
- workspace provider contract changes

## Contract Impact

- FFI/API shape delta: **none** (consumes existing `workspace_list_children` and
  existing open-note controller bridge).
- Error-code delta: **none**.
- synthetic node rule:
  - `Uncategorized` (`__uncategorized__`) is UI-only and resolved in controller.
  - this id must not be forwarded to Rust `workspace_list_children`, which keeps
    UUID/null parent contract.
- UI callback contract:
  - single click: `onOpenNoteRequested(atomId)`
  - double click: `onOpenNotePinnedRequested(atomId)` when callback is provided;
    otherwise keep single-click behavior unchanged.
  - folder create: `onCreateFolderRequested(name, parentNodeId?)`
    - `parentNodeId = null` for root create
    - non-null parent id must satisfy UUID format
  - semantic ownership: callbacks are **open intents only**; deterministic
    preview/pinned replacement rules are owned by tab model (`PR-0304`).
- References:
  - `docs/api/ffi-contracts.md`
  - `docs/api/workspace-tree-contract.md`

## Interaction Rules

1. Expand folder:
   - request children only when expanded first time
2. Single click note:
   - emit preview-open intent callback
3. Double click note:
   - emit pinned-open intent callback
4. Create child folder:
   - folder row action opens create dialog and passes current folder id as parent

## Step-by-Step

1. Build recursive tree item components.
2. Integrate lazy children query with loading/error states.
3. Wire preview/pinned **intent callbacks** through existing controller/provider contracts (no API shape change).
4. Add widget tests for expand/collapse and open behavior.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_tree_state.dart`
- [add] `apps/lazynote_flutter/test/note_explorer_tree_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/note_explorer_tree_test.dart`
- `cd apps/lazynote_flutter && flutter test test/note_explorer_workspace_delete_test.dart`
- `cd apps/lazynote_flutter && flutter test test/notes_page_c1_test.dart test/notes_page_c2_test.dart test/notes_page_c3_test.dart test/notes_page_c4_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [x] Explorer renders nested folders recursively.
- [x] Child nodes load lazily on expansion.
- [x] Single/double click intent callbacks are deterministic and test-covered.
- [x] Error/empty/loading states are visible and recoverable.
- [x] Explorer states (default/hover/selected/loading/error) remain visually consistent with the shared UI style system.
- [x] Create-folder refresh preserves user expand/collapse state and only refreshes affected parent branch.

## Implemented in current patch

- added recursive/lazy tree rendering path in `note_explorer.dart` with root and
  branch loading states.
- added reusable tree row widget in
  `apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart`.
- added tree state/cache manager in
  `apps/lazynote_flutter/lib/features/notes/explorer_tree_state.dart`.
- added explorer controller bridge for workspace children load and pinned-open
  path in `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`.
- added root-level folder create entry (`New folder`) and refresh-on-create/delete
  behavior in `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`.
- refined refresh semantics to avoid forced `Uncategorized` re-expand on each
  refresh and to reload only the created folder's parent branch.
- injected default root `Uncategorized` folder in tree responses while preserving
  legacy root note visibility for backward compatibility.
- added regression tests in
  `apps/lazynote_flutter/test/note_explorer_tree_test.dart`.
