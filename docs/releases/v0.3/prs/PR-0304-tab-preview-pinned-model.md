# PR-0304-tab-preview-pinned-model

- Proposed title: `feat(notes-ui): preview tab and pinned tab interaction model`
- Status: Planned

## Goal

Implement deterministic preview/pinned tab behavior similar to modern IDE editors.

## Scope (v0.3)

In scope:

- single-click open as preview tab (replaceable)
- double-click open as pinned tab (persistent)
- visual distinction between preview and pinned tabs
- context actions for convert preview -> pinned

Out of scope:

- advanced tab grouping rules

## Interaction Rules

1. Preview tab is ephemeral and can be replaced by next preview open in same pane.
2. Pinned tabs are not auto-replaced by preview opens.
3. Double-click always pins current preview/open tab.

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

