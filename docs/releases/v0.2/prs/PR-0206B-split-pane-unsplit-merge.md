# PR-0206B-split-pane-unsplit-merge

- Proposed title: `feat(workspace-ui): split pane unsplit/merge baseline`
- Status: Completed

## Goal

Add explicit unsplit/merge behavior so users can close one active pane and
return to a simpler layout without restarting the session.

## Scope (v0.2 follow-up)

In scope:

- add one explicit `close active pane` command (when pane count > 1)
- merge closed-pane tabs into deterministic target pane
- preserve active note/editor focus with deterministic fallback
- keep pane fractions normalized after merge
- add clear user feedback for blocked/success states

Out of scope:

- recursive split-tree merge behavior
- drag-to-merge gestures
- pane resize handle redesign
- cross-window pane migration

## UX Rules

1. `Close pane` is always available but returns explicit blocked feedback when
   only one pane exists.
2. Merge target is deterministic:
   - prefer previous pane in order
   - if closing first pane, use next pane
3. Tabs from closed pane are appended to target pane in stable order.
4. Active note after merge:
   - keep previous active note if still present
   - otherwise fallback to target pane active tab
5. Show non-destructive feedback for blocked actions.

## Local Contract (Flutter runtime only)

Add one local result enum for merge command handling:

- `WorkspaceMergeResult.ok`
- `WorkspaceMergeResult.singlePaneBlocked`
- `WorkspaceMergeResult.paneNotFound`

No Rust FFI shape change is expected in this PR.

## Step-by-Step

1. Add merge result/state transition logic in `WorkspaceProvider`.
2. Expose controller bridge command in `NotesController`.
3. Add Notes shell command entry (`Close pane`) and SnackBar mapping.
4. Add regressions:
   - provider merge behavior
   - controller active-note routing after merge
   - widget command behavior and blocked feedback
5. Sync release/docs wording for v0.2 split baseline.

## Implementation Notes

- `WorkspaceProvider.closeActivePane()` is added with deterministic merge target
  policy and stable `WorkspaceMergeResult`.
- `NotesController.closeActivePane()` bridges provider merge behavior and
  preserves active-pane editor routing.
- Notes shell adds `notes_close_pane_button` and maps merge outcomes to
  actionable SnackBar feedback.
- regression coverage added/extended in:
  - `test/workspace_provider_test.dart`
  - `test/notes_controller_workspace_bridge_test.dart`
  - `test/workspace_split_v1_test.dart`

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_models.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/test/workspace_provider_test.dart`
- [edit] `apps/lazynote_flutter/test/notes_controller_workspace_bridge_test.dart`
- [edit] `apps/lazynote_flutter/test/workspace_split_v1_test.dart`
- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0206-split-layout-v1.md`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/workspace_provider_test.dart`
- `cd apps/lazynote_flutter && flutter test test/notes_controller_workspace_bridge_test.dart`
- `cd apps/lazynote_flutter && flutter test test/workspace_split_v1_test.dart`
- `cd apps/lazynote_flutter && flutter test`

Verification replay (2026-02-20):

- `flutter analyze` passed.
- `flutter test test/workspace_provider_test.dart test/notes_controller_workspace_bridge_test.dart test/workspace_split_v1_test.dart` passed.

## Acceptance Criteria

- [x] Users can explicitly close active pane when pane count > 1.
- [x] Merge target and tab migration order are deterministic.
- [x] Active note/editor focus remains coherent after merge.
- [x] Single-pane close action is safely blocked with clear feedback.
- [x] No new FFI/API contract drift is introduced.
