# PR-0205-explorer-recursive-lazy-ui

- Proposed title: `feat(notes-ui): recursive explorer with lazy folder loading`
- Status: Planned

## Goal

Replace flat explorer behavior with a recursive tree UI driven by core hierarchy APIs.

## Scope (v0.2)

In scope:

- recursive folder rendering
- lazy load children on expand
- single-click preview open in active pane
- double-click pinned open in active pane
- hover-first minimalist explorer actions

Out of scope:

- full drag edge split behavior
- advanced tree virtualization

## Interaction Rules

1. Expand folder:
   - request children only when expanded first time
2. Single click note:
   - open as preview tab in active pane
3. Double click note:
   - convert/open as pinned tab

## Step-by-Step

1. Build recursive tree item components.
2. Integrate lazy children query with loading/error states.
3. Wire preview/pinned open semantics to workspace provider.
4. Add widget tests for expand/collapse and open behavior.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_tree_state.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/test/note_explorer_tree_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/note_explorer_tree_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Explorer renders nested folders recursively.
- [ ] Child nodes load lazily on expansion.
- [ ] Single-click preview and double-click pinned semantics work in active pane.
- [ ] Error/empty/loading states are visible and recoverable.

