# ADR-0010: Layout Tree Structure And Resolve

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-11 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S10-layout-tree-structure-and-resolve.md`](../rulings/S10-layout-tree-structure-and-resolve.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should pane layout be modeled as an immutable recursive binary tree with top-down resolve, so that split, close, resize, and validation all operate on one coherent structural contract?
- Coverage Scope: Covers `DI-2 / D5`, node shape, wrapper API, `D6`, invariants, and the `EditorGroupModel -> Leaf` mapping, plus `DI-3` persistence, one-shot replacement, pane-cap, the `DI-3 -> DI-4` staged restore boundary, `DI-4` stage-2 loading detail, `DI-6` failed-track diagnosis plus rebased Gate A/B/Release framing for the editor-infrastructure line, and the `DI-7` line-specific precision layer for Gate B, benchmark dimensions, the v0.3 SLA table, two-layer verification, and the explicit no-benchmark-CI decision, together with the current-effective ruling published in `PR-0403`. Stops before the broader repo-wide Gate A / Release Gate / test-migration policy bundle that `DOC-015` keeps parked.
- Current Normative Source: [`../rulings/S10-layout-tree-structure-and-resolve.md`](../rulings/S10-layout-tree-structure-and-resolve.md)
- Source Corpus Summary: `DI-2` supplied the first complete layout-tree contract for recursive pane structure, public layout APIs, top-down resolve, invariant enforcement, and group-leaf lifecycle mapping. `DI-3` then fixed how the same line persists, migrates, caps pane growth, and stages restore before buffer content is loaded. `DI-4` then fixed when and how stage-2 loading populates those restored shells. `DI-6` then reframed the failed three-track rollout into a rebased dependency model whose Gate B editor-infrastructure checkpoint depends on this same line being structurally coherent first. `DI-7` then made that same checkpoint precise by fixing benchmark dimensions, the v0.3 SLA table, the two-layer verification method, and the explicit no-benchmark-CI decision without creating a second benchmark-only line. No separate legacy ruling carrier existed for this line, so `PR-0403` first-publishes the ADR/ruling pair directly from the resolved DIs and then appends the later execution framing.

## Source Corpus

- Trigger Source: no standalone upstream trigger document; `DI-2` carries the layout-model gap and audit reference directly inside the design discussion
- Decision Sources:
  [`../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md`](../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md),
  [`../../reports/v0.3/design-discussions/DI-3-layout-persistence.md`](../../reports/v0.3/design-discussions/DI-3-layout-persistence.md),
  [`../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md`](../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md)
- Execution / Closure Sources:
  [`../../reports/v0.3/design-discussions/DI-6-cross-track-dependencies.md`](../../reports/v0.3/design-discussions/DI-6-cross-track-dependencies.md),
  [`../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md`](../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md)
- Historical Normative Snapshot: none; this line had no separate legacy ruling snapshot before `PR-0403`

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | embedded in `DOC-010 / DI-2` | `embedded` | `DI-2` carries its own structure gap and audit reference directly |
| Decision Source | `DOC-010 / D5-D6 + invariants + mapping`; `DOC-011 / D7-D9 + DI-3 -> DI-4 boundary`; `DOC-012 / Q4 stage-2 loading` | `present` | The line now includes the structural contract, the persistence / staged-restore contract, and the later stage-2 loading rules replayed from the resolved DIs |
| Normative Source | rebuilt `S10` only | `present` | This run first-publishes the current ruling without an older snapshot |
| Execution / Closure Source | `DOC-014 / DI-6`; `DOC-015 / DI-7` | `present` | DI-6 adds failed-track diagnosis plus Gate A/B/Release dependency framing; DI-7 then appends the line-specific Gate B precision, benchmark-definition, SLA/verification semantics, and no-benchmark-CI decision while leaving broader repo-wide policy explicit and parked |
| Superseded / Redirected Source | none | `not_applicable` | This line is first-published, not redirected from another active theme |

## Journey Timeline / Phases

1. `DI-2` identified that the flat `WorkspaceLayoutState` model could not support recursive nested pane layout as the editor foundation evolved.
2. `D5` chose an immutable recursive binary tree with sealed node types and whole-tree rebuild semantics over a mutable listener-driven tree.
3. `DI-2` fixed the node shape at `LayoutNode`, `SplitNode(first, second, axis, fraction)`, and `LeafNode(groupId)`.
4. `DI-2` wrapped the raw node tree in `GroupLayout`, fixing the public layout API at `split`, `closeGroup`, `resizeAt`, `resolve`, `allGroupIds`, and `canSplit`.
5. `D6` chose top-down `resolve` as the data-layer authority for pane rect assignment and divider metadata, explicitly rejecting bottom-up constraint solving and Flutter `LayoutDelegate`.
6. `DI-2` completed the line with invariant and lifecycle-mapping clauses that tie `EditorGroupModel` creation/destruction to leaf-level tree operations.
7. `DI-3` chose standalone `workspace_layout.json`, one-second debounced atomic writes, and a serialization scope that keeps structure and tab shells together while leaving draft content out of the file.
8. `DI-3` resolved migration as a one-shot replacement because no prior persisted layout file existed that required on-disk backward conversion.
9. `DI-3` fixed layout growth at a hard eight-pane cap with no explicit depth cap, combining a pre-resolve pane-count check with post-resolve minimum-size validation.
10. `DI-3` closed the staged restore boundary by assigning phase-1 structure restore to layout persistence and leaving phase-2 buffer loading to later `DI-4`.
11. `DI-4` then fixed stage-2 loading as a shell-owned continuation of the same line: active buffers may load eagerly, non-active buffers may load lazily, both preserve restored shells, and failures stay at the buffer/state layer rather than invalidating layout restore.
12. `DI-6` then reframed the failed three-track rollout into a rebased dependency sequence, placing Gate B on top of the already-formed editor-infrastructure line and keeping exact gate precision, SLA, and testing details for later `DI-7`.
13. `DI-7` then closed that later edge for the same line by fixing Gate B precision, benchmark dimensions, the v0.3 SLA table, the two-layer verification model, and the explicit no-benchmark-CI decision, while leaving broader Gate A / Release Gate / migration policy outside the line.
14. `PR-0403` first-published the line as ADR and current ruling carriers without relying on a separate legacy ruling snapshot, then appended the later execution and verification framing in-place.

## Current State

Current architecture treats pane layout as a dedicated `GroupLayout` line rather than as a detail hidden inside shell ownership. The authoritative interpretation follows [`../rulings/S10-layout-tree-structure-and-resolve.md`](../rulings/S10-layout-tree-structure-and-resolve.md): layout is an immutable recursive binary tree, `resolve` is top-down, persistence uses a standalone debounced JSON file, migration is a one-shot replacement, pane growth caps at eight panes, and restore is staged so structure appears before buffer content loads. `DOC-012 / DI-4` extends that same line with the stage-2 loading side of restore: restored groups and loading buffers remain stable after phase 1, active/background load timing is shell-owned policy rather than a second layout model, and failure handling stays local to buffer hydration rather than invalidating the structure contract. `DOC-014 / DI-6` then positions the same line inside the rebased dependency model: the old three-track rollout is treated as failed, Gate B becomes the editor-infrastructure checkpoint for this line, and Gate A plus Release Gate become explicit prerequisite and closure boundaries rather than separate replacement themes. `DOC-015 / DI-7` closes the remaining line-specific precision gap by fixing Gate B exactness, benchmark dimensions, the v0.3 SLA table, the two-layer verification model, and the explicit no-benchmark-CI decision for this same line. Broader repo-wide Gate A, Release Gate, and test-migration policy remains explicit carry-forward governance material rather than current layout-tree semantics.

## Open Edges

- Later implementation-lineage evidence may append without changing the structural contract itself.
- Broader repo-wide Gate A / Release Gate / test-migration policy remains outside this line and continues as explicit governance carry-forward material.

## Revision Record

- 2026-03-11: Initial retrospective reconstruction ADR published in `PR-0403` from `DOC-010 / DI-2` without a prior legacy ruling snapshot.
- 2026-03-11: `DOC-011 / DI-3` replay appended standalone JSON persistence, one-shot replacement, pane-cap, and the DI-3 side of the staged restore boundary without reopening the stable why-question.
- 2026-03-11: `DOC-012 / DI-4` replay appended stage-2 loading timing, ownership, scheduling, failure handling, and runtime-load-path unification without creating a second loading-only theme.
- 2026-03-11: `DOC-014 / DI-6` replay appended failed-track diagnosis, rebased dependency sequence, and Gate A/B/Release framing without spinning out a separate execution-governance theme.
- 2026-03-11: `DOC-015 / DI-7` replay appended Gate B precision, benchmark-definition, SLA/verification semantics, and the explicit no-benchmark-CI decision without creating a second benchmark-only or governance-only theme.
