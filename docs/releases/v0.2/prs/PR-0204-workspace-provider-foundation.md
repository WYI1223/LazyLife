# PR-0204-workspace-provider-foundation

- Proposed title: `feat(notes-ui): workspace provider and state hoisting foundation`
- Status: Planned

## Goal

Introduce a centralized workspace runtime state so notes/tabs/panes share one source of truth.

## Scope (v0.2)

In scope:

- `WorkspaceProvider` as top-level runtime owner
- active pane state (`activePaneId`)
- opened tabs per pane
- shared note buffer registry
- save coordinator hooks (debounce + flush)

Out of scope:

- recursive split layout tree (v0.3)
- drag-to-split interactions (v0.3)

## State Model Baseline

Required state slices:

1. `layoutState` (single pane initially, split-ready shape)
2. `activePaneId`
3. `openTabsByPane`
4. `buffersByNoteId`
5. `saveStateByNoteId` (`clean | dirty | saving | save_error`)

Design rule:

- visual widgets consume provider selectors
- editor components remain layout-agnostic and reusable

## Step-by-Step

1. Add provider and models in `features/workspace/`.
2. Migrate existing `notes_controller` responsibilities into provider-managed state.
3. Keep current Notes UI behavior intact while swapping state ownership.
4. Add tests for buffer/saving state coherence across tab activation.

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/lib/features/workspace/workspace_models.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [add] `apps/lazynote_flutter/test/workspace_provider_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Notes buffers are provider-owned and reusable by future pane layouts.
- [ ] Active pane and tab state are explicit and test-covered.
- [ ] Existing v0.1 note flows still pass.

