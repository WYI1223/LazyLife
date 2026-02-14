# PR-0010C1-notes-host-list-baseline

- Proposed title: `feat(notes-ui): replace Notes placeholder with host and list baseline`
- Status: Completed

## Goal

Replace the Notes placeholder route with a functional Notes host page and a stable list state machine.

## Scope (v0.1)

In scope:

- mount Notes page in `WorkbenchSection.notes`
- load and render note list via PR-0010B APIs
- baseline two-pane composition and list interactions
- loading/empty/error/retry states

Out of scope:

- editor write/save behavior
- autosave policy
- tag filter controls

## UI Requirements

1. Keep Workbench shell unchanged.
2. Notes host uses two-pane composition:
   - left: notes list
   - right: detail placeholder until C2 lands
   - layout is fixed left/right in C1 (no vertical fallback)
3. List item baseline fields:
   - title (fallback label when empty)
   - preview text (single/multi-line clamp)
   - updated time hint
4. Current selection state is visually clear and stable.
5. Provide a header-level `Back to Workbench` action for quick return to home section.
6. Visual language must align with Single Entry minimalist style:
   - sidebar/background tone: `#F7F7F5`
   - primary text tone: `#37352F`
   - secondary text tone: `#6B6B6B`
   - subtle divider tone: `#E3E2DE`
   - selected row uses neutral gray highlight, not saturated accent color

## Landed UI Notes

1. Notes page now uses fixed left/right split with a shallow-gray list pane and white document canvas.
2. Detail pane includes breadcrumb row, lightweight page actions, meta chips, large title, and readable body spacing.
3. Styling intentionally avoids heavy borders/strong chroma to keep continuity with Single Entry panel aesthetics.
4. Notes shell was componentized for future Workbench extraction:
   - `NoteExplorer` (left)
   - `NoteTabManager` (top)
   - `NoteContentArea` (center)
5. Controller now tracks multi-tab state (`openNoteIds`, `activeNoteId`) and provides tab open/activate/close helpers.
6. Explorer keeps recursive folder node model (`Folder -> children -> noteIds`) while v0.1 renders one folder level.

## Step-by-Step

1. Add `notes_controller.dart` baseline state and load/retry methods.
2. Wire `notes_list` and minimal `note_get` reads from FFI bindings.
3. Add `notes_page.dart` with list + detail placeholder layout.
4. Replace Notes placeholder wiring in `entry_shell_page.dart`.
5. Add stable widget keys for tests and future C2/C3/C4 reuse.

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/note_tab_manager.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/note_content_area.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/notes_style.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [add] `apps/lazynote_flutter/test/notes_page_c1_test.dart`
- [add] `apps/lazynote_flutter/test/notes_controller_tabs_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/notes_page_c1_test.dart`
- `cd apps/lazynote_flutter && flutter test test/notes_controller_tabs_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [x] Notes section no longer shows placeholder.
- [x] List renders deterministic loading/empty/error/success states.
- [x] Retry path can recover from transient load failure.
- [x] Two-pane host scaffold is in place for C2 editor landing.
