# PR-0302-drag-to-split-edge-zones

- Proposed title: `feat(workspace-ui): drag tab to edge zones for split creation`
- Status: Planned

## Goal

Deliver IDE-style drag-to-split interaction on top of recursive layout tree.

## Scope (v0.3)

In scope:

- edge sensing zones (`top | bottom | left | right`) for active pane
- drag preview overlay
- drop-to-split behavior
- split rejection feedback when min-size would be violated

Out of scope:

- tear-out external window tabs

## Interaction Rules

1. Dragging tab over pane edges activates directional drop zone hints.
2. Dropping in zone upgrades target leaf to internal split node.
3. If split violates min-size constraints, operation is rejected visibly.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_tab_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [add] `apps/lazynote_flutter/lib/features/workspace/split_drop_overlay.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/test/drag_to_split_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/drag_to_split_test.dart`

## Acceptance Criteria

- [ ] Dragging tab to edge shows clear split zone affordance.
- [ ] Drop creates correct split direction and pane/tab placement.
- [ ] Invalid split drop paths are blocked with visible feedback.

