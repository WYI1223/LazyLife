# PR-0303-cross-pane-live-buffer-sync

- Proposed title: `feat(workspace): cross-pane live note buffer synchronization`
- Status: Planned

## Goal

Ensure one note opened in multiple panes remains text-coherent in near real-time.

## Scope (v0.3)

In scope:

- shared buffer model per note id
- multi-editor subscription to same buffer state
- unified dirty/saving indicator consistency across panes
- save coordinator update ordering safeguards

Out of scope:

- collaborative multi-user OT/CRDT sync

## Design Notes

Preferred model:

- share `BufferState` by note id
- allow per-pane editor instances/controllers subscribed to buffer
- avoid single `TextEditingController` instance shared across widget trees

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart`
- [add] `apps/lazynote_flutter/lib/features/workspace/buffer_store.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_content_area.dart`
- [add] `apps/lazynote_flutter/test/buffer_sync_multi_pane_test.dart`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/buffer_sync_multi_pane_test.dart`

## Acceptance Criteria

- [ ] Editing note in pane A updates pane B view for same note.
- [ ] Dirty/saving indicators are consistent across panes.
- [ ] Stale async save completion cannot overwrite newer buffer content.

