# ADR-0001: Atom Projection Model

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S1-atom-projection.md`](../rulings/S1-atom-projection.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should Atom projection be defined by unified atom semantics rather than legacy type-only hints, so that notes/tasks/calendar surfaces consume one truth consistently?
- Coverage Scope: Covers the `08a -> 08b -> 08c -> 08d -> 09 -> v0.3 release evidence -> DI-1 -> DI-11` chain and the rebuilt current-effective ruling published in `PR-0403`. Stops before later native ADR workflow.
- Current Normative Source: [`../rulings/S1-atom-projection.md`](../rulings/S1-atom-projection.md)
- Source Corpus Summary: `08a` trigger findings, `08b` S1 semantic freeze, `08c` execution and CI bridge, `08d` v0.3 PR mapping, `09` closure and orphan ledger, `v0.3 release evidence` verification/sign-off, `DI-1` title-semantics application to tab carriers, `DI-11` stack-wide `ViewHint` naming convergence, plus the legacy S1 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md),
  [`../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md`](../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md),
  [`../../reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md`](../../reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md)
- Historical Normative Snapshot: [`../rulings-legacy/S1-atom-projection.md`](../rulings-legacy/S1-atom-projection.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / S1` | `present` | Earliest ambiguity signal is preserved |
| Decision Source | `DOC-002 / S1` | `present` | Full clause-level S1 decision set consumed |
| Normative Source | legacy S1 + rebuilt S1 | `present` | Current interpretation follows the rebuilt ruling |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence`, `DOC-009 / DI-1`, `DOC-019 / DI-11` | `present` | Includes handoff, orphan-ledger treatment, release-time verification/sign-off, DI-1 tab-title application, and DI-11 naming convergence |
| Superseded / Redirected Source | none | `not_applicable` | Later material extends the line without redirecting it |

## Journey Timeline / Phases

1. `08a` recorded that projection semantics were underdefined across `type`, time fields, and task state.
2. `08b` answered that gap by redefining Atom as a unified container and by fixing the first projection rules around carrier, rendering, routing, and title semantics.
3. `08c` and `08d` translated that semantic freeze into planned execution lanes and future CI checks.
4. `09` confirmed that the line was closed enough to hand off into v0.3 while keeping deferred sub-lines visible.
5. `PR-0403` rebuilt the line into current ADR and ruling carriers without erasing the deferred edges.

## Current State

Current architecture reads Atom as a unified semantic container whose rendering and routing are driven by real fields, not by a user-chosen type label. The authoritative current rule is [`../rulings/S1-atom-projection.md`](../rulings/S1-atom-projection.md), which preserves both landed rules and still-open future reservations. `DOC-009 / DI-1` further applied the same naming truth to tab carriers by keeping tab labels on `atom.title` rather than inventing a per-ref `display_name` title line. `DOC-019 / DI-11` then closed the stack-wide naming consequence of that same rule by aligning the type, field, and helper vocabulary on `ViewHint / view_hint` instead of `AtomType / kind`.

## Open Edges

- Comment semantics remain a preserved future-facing edge.
- Canvas and conversation carriers remain explicitly reserved rather than silently dropped.
- Overlay / block-sidecar work remains later follow-up, not part of this replay closure.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-11: `DOC-005 / 09` replay appended release-closure and v0.3-handoff evidence while explicitly preserving the deferred S1 placeholder ledger.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended release-verification, ruling-layer sign-off, and deferred-boundary confirmation without changing the stable why-question.
- 2026-03-11: `DOC-009 / DI-1` replay appended tab-title semantics evidence, confirming that tab carriers consume `atom.title` rather than per-ref `display_name`.
- 2026-03-12: `DOC-019 / DI-11` replay appended the resolved `AtomType -> ViewHint` naming-convergence evidence, making the cross-layer `view_hint` vocabulary explicit without reopening the stable why-question.
