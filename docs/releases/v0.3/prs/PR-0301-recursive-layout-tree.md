# PR-0301-recursive-layout-tree

- Proposed title: `feat(workspace-ui): recursive split layout tree engine`
- Status: Planned

## Goal

Replace limited split model with a recursive binary layout tree.

## Scope (v0.3)

In scope:

- `WorkspaceNode` recursive model:
  - internal split node (`horizontal | vertical`)
  - leaf node (`EditorGroup`)
- pane serialization/restoration shape
- geometry validation with min-size constraints

Out of scope:

- drag gesture split triggers (PR-0302)

## Invariants

1. Every visible pane is represented by one leaf node.
2. Any split operation must preserve `>= 200px` width/height constraints.
3. Invalid operations must be rejected with deterministic error feedback.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_models.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/lib/features/workspace/layout_tree_engine.dart`
- [add] `apps/lazynote_flutter/test/layout_tree_engine_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/layout_tree_engine_test.dart`

## Acceptance Criteria

- [ ] Recursive split tree can represent nested layouts.
- [ ] Min-size guard is enforced for all split operations.
- [ ] Invalid split attempts return stable failure semantics.

