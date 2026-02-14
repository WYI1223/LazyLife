# PR-0305-markdown-segment-rendering-performance-gate

- Proposed title: `perf(notes-ui): markdown segment rendering and FPS guard`
- Status: Planned

## Goal

Keep long markdown documents responsive in multi-pane workspace scenarios.

## Scope (v0.3)

In scope:

- markdown text segmentation strategy for rendering/editing
- viewport-oriented chunk updates
- profile-mode performance benchmark and gate
- fallback behavior for oversized documents

Out of scope:

- full rich markdown WYSIWYG editor rewrite

## Performance Gate

Baseline target:

- maintain near-60 FPS interaction on representative long-note scenario
- no major frame-jank spikes during split-pane scroll/edit actions

Scenario definition and device baseline must be documented in this PR.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/note_editor.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/markdown_segmenter.dart`
- [add] `apps/lazynote_flutter/test/markdown_segmenter_test.dart`
- [add] `docs/development/performance-notes.md`

## Verification

- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`
- profile-mode benchmark run with documented dataset

## Acceptance Criteria

- [ ] Segment rendering is enabled for long markdown content.
- [ ] Performance benchmark is reproducible and documented.
- [ ] Workspace remains responsive under target scenario.

