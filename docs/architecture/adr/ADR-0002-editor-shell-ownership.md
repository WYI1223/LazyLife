# ADR-0002: Editor Shell Ownership

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S2-tab-draft-save-ownership.md`](../rulings/S2-tab-draft-save-ownership.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should tab, draft, and save state live in a workbench-level editor shell rather than inside notes feature state, so that pane-aware editing can keep one authoritative state model?
- Coverage Scope: Covers `08a -> 08b -> 08c -> 08d -> 09 -> v0.3 release evidence -> DI-0 -> DI-1 -> DI-4 -> DI-5 -> DI-10` for the earliest shell-ownership line and the rebuilt current ruling published in `PR-0403`. Later shell and editor-mode details remain append-only follow-up.
- Current Normative Source: [`../rulings/S2-tab-draft-save-ownership.md`](../rulings/S2-tab-draft-save-ownership.md)
- Source Corpus Summary: `08a` ambiguity trigger, `08b` S2 semantic freeze, `08c` phase-1 execution bridge, `08d` PR mapping, `09` closure/handoff, `v0.3 release evidence` gate/sign-off confirmation, `DI-0` naming clarification, `DI-1` shell-detail contract, `DI-4` buffer-sync / load-guard refinement, `DI-5` cursor/conflict confirmation, `DI-10` resolver-shell contract, and the legacy S2 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md),
  [`../../reports/v0.3/design-discussions/DI-0-dual-tab-manager.md`](../../reports/v0.3/design-discussions/DI-0-dual-tab-manager.md),
  [`../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md`](../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md),
  [`../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md`](../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md),
  [`../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md`](../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md),
  [`../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`](../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md)
- Historical Normative Snapshot: [`../rulings-legacy/S2-tab-draft-save-ownership.md`](../rulings-legacy/S2-tab-draft-save-ownership.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / S2` | `present` | Early ownership ambiguity preserved |
| Decision Source | `DOC-002 / S2` | `present` | S2 target architecture and phased plan consumed |
| Normative Source | legacy S2 + rebuilt S2 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence`, `DOC-008 / DI-0`, `DOC-009 / DI-1`, `DOC-012 / DI-4`, `DOC-013 / DI-5`, `DOC-018 / DI-10` | `present` | Includes v0.3 planning, readiness evidence, release-time gate/sign-off confirmation, naming clarification / implementation linkage, the first DI-level shell-detail contract, the later buffer-sync / load-guard refinement, the confirmatory cursor/conflict closure, and the resolver-shell contract |
| Superseded / Redirected Source | none | `not_applicable` | Later sources extend phases instead of redirecting the line |

## Journey Timeline / Phases

1. `08a` recorded that tab, draft, and save ownership was split across notes and workspace surfaces.
2. `08b` declared that these states belong to a workbench-level shell, not to notes-local state.
3. `08c` proposed the phase-1 bridge removal path.
4. `08d` mapped the later extraction into concrete v0.3 lanes.
5. `09` confirmed that the line was ready for handoff into later shell-focused DI work.
6. `DI-0` clarified the naming split between the state-side group model and the widget-side tab strip.
7. `DI-1` supplied the first full DI-level shell-detail contract without reopening the stable why-question.
8. `DI-4` then fixed the shared `EditBuffer` model, manual-listener bridge semantics, advisory `EditOp` posture, real-time multi-pane sync, and loading/error guards under the same line.
9. `DI-5` then confirmed that per-pane cursor independence and the absence of a dedicated local conflict subsystem follow directly from that published shell / buffer model.
10. `PR-0403` rebuilt the line into current ADR and ruling carriers.

## Current State

Current architecture treats tab, draft, save, and pane-aware editing state as editor-shell infrastructure. The authoritative interpretation follows [`../rulings/S2-tab-draft-save-ownership.md`](../rulings/S2-tab-draft-save-ownership.md), while later DI work may append more detailed shell phases to this same line. The `DOC-003 / 08c` replay confirms that phase-1 shell work means removing the workspace bridge, shrinking `WorkspaceProvider` to pane layout, and treating coordinator slimming as execution evidence under this same line rather than as a separate decision. The `DOC-004 / 08d` replay further fixes `PR-0257` and `PR-0258` as the concrete v0.2.5 execution lanes for this same line, while carrying phase-2 extraction into later v0.3 shell work. The `DOC-008 / DI-0` replay then clarifies that the old `NoteTabManager` naming collision was a layer-boundary ambiguity, not a dual-version semantic conflict: the state-side artifact becomes `EditorGroupModel`, while the widget becomes `NoteTabStrip`. The `DOC-009 / DI-1` replay then adds the first stable shell-detail contract for this line: per-pane `EditorGroupModel`, per-atom `EditBuffer`, title flow on `atom.title`, injected load/persist callbacks, coordinator-as-mediator boundaries, and an explicit handoff to `DI-4` for multi-pane buffer synchronization detail. The `DOC-012 / DI-4` replay then closes that handoff without changing the stable why-question: the same line now includes shared per-atom `EditBuffer` truth across panes, manual-listener plus string-guard bridge semantics, advisory `EditOp` as non-authoritative optimization metadata, immediate buffer notifications with consumer-side debounce only, and explicit ready/loading/error guards around load, edit, save, and flush behavior. The `DOC-013 / DI-5` replay then confirms two user-facing consequences of that same model rather than creating a new line: each pane keeps its own cursor/selection state, and the current single-process local model does not require a dedicated conflict-resolution subsystem beyond the already-published stale-save and serial-edit guarantees. The `DOC-018 / DI-10` replay then adds the resolver-shell layer that the published line had already left open: `EditorResolver` is the middle selection layer between shell state and feature chrome, pane builders accept `BuildContext` plus `EditBuffer`-derived inputs only, registration stays explicit via `Map + register()`, unsupported types render a visible placeholder rather than silently falling back to markdown, and the future `View Mode` expansion remains an explicit later edge rather than current publication.

## Open Edges

- Later DI shell work should append implementation detail rather than fork the decision line by default.
- View-mode and richer editor-mode concerns remain later follow-up rather than blockers for this reconstruction.
- Resolver-facing editor-mode or thin-client changes may append here only if they preserve the same single-source ownership direction.
- Cross-pane undo/redo semantics remain an explicit later edge rather than a resolved part of this reconstruction.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-10: `DOC-003 / 08c` replay appended phase-1 bridge-removal and coordinator-slimming execution evidence without changing the stable why-question.
- 2026-03-10: `DOC-004 / 08d` replay appended the concrete `PR-0257 -> PR-0258` lane mapping and preserved phase-2 extraction as later handoff without changing the stable why-question.
- 2026-03-11: `DOC-005 / 09` replay appended closure and v0.3-handoff confirmation while keeping later shell detail as append-only follow-up.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended Gate B, DI-chain sign-off, and release-sign-off confirmation without creating a release-only shell carrier.
- 2026-03-11: `DOC-008 / DI-0` replay appended naming clarification, widget rename blast radius, and `PR-RB-06` implementation linkage without creating a separate naming theme.
- 2026-03-11: `DOC-009 / DI-1` replay appended the first DI-level shell-detail contract, covering group lifecycle, unified `EditBuffer`, coordinator boundary, title flow, and the explicit `DI-4` handoff.
- 2026-03-11: `DOC-012 / DI-4` replay appended shared-buffer sync, advisory `EditOp`, manual-listener bridge semantics, immediate-notification plus consumer-debounce rules, and load/error guards without changing the stable ownership line.
- 2026-03-11: `DOC-013 / DI-5` replay appended confirmatory cursor-independence and local-conflict-absence rules, while leaving cross-pane undo/redo as an explicit later follow-up.
- 2026-03-12: `DOC-018 / DI-10` replay appended the resolver-shell layer, including the middle-layer split, `EditorPaneBuilder` interface boundary, explicit registration protocol, unsupported-type placeholder rule, and the preserved future `View Mode` reservation.
