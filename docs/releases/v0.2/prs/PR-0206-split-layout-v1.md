# PR-0206-split-layout-v1

- Proposed title: `feat(workspace-ui): limited split layout v1 with min-size guard`
- Status: Planned

## Goal

Introduce pane splitting baseline while keeping implementation risk controlled.

## Scope (v0.2)

In scope:

- horizontal/vertical split commands
- limited pane count (for example up to 4 panes)
- active pane focus and tab routing
- strict min-size guard (`200px`) for pane geometry safety

Out of scope:

- fully recursive split tree
- drag tab to edge split zones

## Layout Constraints

1. Any pane width/height must remain `>= 200px`.
2. Split command is rejected when constraint would be violated.
3. Rejection must provide visible feedback to user.

## Step-by-Step

1. Add split-capable layout model in workspace state.
2. Add split actions (menu/button/shortcut).
3. Add min-size validation before applying split.
4. Ensure notes open in active pane only.
5. Add widget tests for split success/failure and active-pane behavior.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/entry/workbench_shell_layout.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_models.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/test/workspace_split_v1_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/workspace_split_v1_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Users can split panes via explicit commands.
- [ ] Active pane is clearly represented and used for open actions.
- [ ] Min-size guard blocks invalid splits with UI feedback.

