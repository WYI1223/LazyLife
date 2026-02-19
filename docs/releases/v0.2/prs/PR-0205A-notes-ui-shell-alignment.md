# PR-0205A-notes-ui-shell-alignment

- Proposed title: `feat(notes-ui): align notes shell with shared v0.2 visual language`
- Status: In Progress

## Goal

Align Notes page shell style with the same visual language used by Task and Calendar UI:
single unified workspace shell, subtle split divider, consistent spacing, and state styling.

## References

- `docs/product/ui-standards/note-ui-dev-spec.md`
- `docs/product/ui-standards/note-ui.md`
- `docs/product/ui-standards/task-ui-dev-spec.md`
- `docs/product/ui-standards/calendar-ui-dev-spec.md`

## Scope (v0.2)

In scope:

- notes page two-pane shell alignment (`Header + Explorer + Divider + Editor`)
- shared style token alignment (container/divider/spacing/hover-selected emphasis)
- right pane composition alignment (`Tab strip + content area`)
- UI-only state rendering alignment (loading/error/empty/success, save states)
- responsive baseline alignment (compact header and stable explorer width)

Out of scope:

- recursive explorer data behavior (handled by `PR-0205`)
- split-layout interactions (handled by `PR-0206`)
- drag-reorder/context actions (handled by `PR-0207`)
- any Rust/FFI/domain contract changes
- floating capsule input integration (deferred; if enabled later, must reuse Single Entry implementation)

## Contract Impact

- FFI/API contract delta: **none** (UI-only change).
- Error-code contract delta: **none**.
- Reference: `docs/api/ffi-contracts.md` ("Notes UI Shell Alignment (Flutter-only)").

## Implemented in current patch

- aligned explorer header (`My Workspace`) height with top tab strip.
- switched note title prefix from hardcoded emoji to placeholder icon.
- restored top metadata actions: `Add icon` / `Add image` / `Add comment`.
- active tab hides outer frame/border to match target visual spec.

## Step-by-Step

1. Align Notes shell layout grammar to `note-ui-dev-spec`.
2. Normalize explorer/editor visual tokens to shared v0.2 style language.
3. Add widget tests for shell composition and core visual states.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [edit] `apps/lazynote_flutter/lib/features/entry/workbench_shell_layout.dart`
- [add] `apps/lazynote_flutter/test/notes_ui_shell_alignment_test.dart`
- [edit] `docs/releases/v0.2/prs/PR-0205-explorer-recursive-lazy-ui.md` (dependency note)

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/notes_ui_shell_alignment_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Notes shell layout matches `note-ui-dev-spec` structure.
- [ ] Notes visual language is consistent with Task/Calendar shell style.
- [ ] Core UI states are distinguishable without business logic changes.
