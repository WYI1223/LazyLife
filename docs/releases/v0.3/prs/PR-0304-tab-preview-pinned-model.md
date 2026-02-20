# PR-0304-tab-preview-pinned-model

- Proposed title: `feat(notes-ui): preview tab and pinned tab interaction model`
- Status: Planned

## Goal

Implement deterministic preview/pinned tab behavior similar to modern IDE editors.

## Semantic Ownership

- Preview/pinned semantics are owned by the top tab model/state machine.
- Explorer/tree and other entry points only emit open intents (`preview` or `pin`).
- No source widget should hardcode replace/persist behavior outside tab model.
- v0.2 transition dependency: `PR-0205B-explorer-tab-open-intent-migration`.
  - v0.2 `PR-0205B M2` already landed baseline tab semantics in Notes tab
    (single tap activate, rapid second tap pin preview) and explorer
    double-click pinned-open shortcut intent.

## Scope (v0.3)

In scope:

- unify preview/pinned model across all open sources (explorer/tab/launcher)
- finalize explicit open-intent types (`preview`/`pin`) in shared tab state
- visual distinction and persistence policy for preview vs pinned tabs
- context actions for convert preview -> pinned (and future reverse if needed)

Out of scope:

- advanced tab grouping rules

## Interaction Rules

1. Preview tab is ephemeral and can be replaced by next preview open in same pane.
2. Pinned tabs are not auto-replaced by preview opens.
3. Double-click always pins current preview/open tab.
4. All open sources (explorer, tab interactions, future launcher flows) must go
   through one shared tab model decision path.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_tab_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_models.dart`
- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/test/tab_preview_pinned_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/tab_preview_pinned_test.dart`

## Acceptance Criteria

- [ ] Preview tabs behave as replaceable ephemeral tabs.
- [ ] Pinned tabs remain persistent.
- [ ] Single vs double click semantics are deterministic and tested.
