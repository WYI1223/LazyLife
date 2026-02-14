# PR-0010C4-tag-filter-integration-closure

- Proposed title: `feat(notes-ui): single-tag filter and integration closure`
- Status: Planned

## Goal

Complete the v0.1 Notes UI flow by landing single-tag filtering and full integration-level regression coverage.

## Scope (v0.1)

In scope:

- single-select tag filter UI with clear action
- `tags_list` and `notes_list(tag)` wiring
- list/detail coherence across filter transitions
- regression tests for primary and failure paths
- doc closure for PR-0010C implementation behavior

Out of scope:

- multi-tag boolean filter builder
- tag hierarchy and advanced scoring behaviors

## UI Requirements

1. Filter is single-select in v0.1.
2. Clear action restores unfiltered note list.
3. Active filter state is visible.
4. Filter failures are explicit and recoverable.

## Step-by-Step

1. Add reusable `tag_filter.dart` component.
2. Load available tags via `tags_list`.
3. Apply and clear `notes_list(tag)` filtering.
4. Preserve selected note behavior when filter changes:
   - keep if still present
   - fallback deterministically if removed by filter
5. Add end-to-end widget tests for filter + create/edit/save interactions.
6. Sync PR docs with implemented behavior and known non-goals.

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/tags/tag_filter.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [add] `apps/lazynote_flutter/test/notes_page_c4_test.dart`
- [edit] `docs/releases/v0.1/prs/PR-0010C-notes-tags-ui.md`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/notes_page_c4_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Single-tag filter apply and clear work correctly.
- [ ] Filter transitions keep list/detail state coherent.
- [ ] Regression tests cover filter success/error and recovery.
- [ ] PR-0010C docs are synchronized with shipped behavior.

