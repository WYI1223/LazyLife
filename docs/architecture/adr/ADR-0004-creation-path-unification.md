# ADR-0004: Creation Path Unification

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S4-creation-path-unification.md`](../rulings/S4-creation-path-unification.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should all creation paths converge on one storage invariant, so that head-create and tree-create no longer produce semantically divergent results?
- Coverage Scope: Covers `08a -> 08b -> 08c -> 08d -> 09 -> v0.3 release evidence` and the rebuilt current ruling. Stops before later single-root and atom-first follow-up lines append more implementation detail.
- Current Normative Source: [`../rulings/S4-creation-path-unification.md`](../rulings/S4-creation-path-unification.md)
- Source Corpus Summary: `08a` creation-route ambiguity, `08b` S4 semantic freeze, `08c/08d` execution mapping, `09` closure/readiness, `v0.3 release evidence` verification/sign-off, and the legacy S4 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md)
- Historical Normative Snapshot: [`../rulings-legacy/S4-creation-path-unification.md`](../rulings-legacy/S4-creation-path-unification.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / D8, S4` | `present` | Earliest creation-route ambiguity preserved |
| Decision Source | `DOC-002 / S4` | `present` | S4 semantic freeze consumed |
| Normative Source | legacy S4 + rebuilt S4 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence` | `present` | Includes v0.3 planning, handoff evidence, and release-time atom_ref / deferred-boundary confirmation |
| Superseded / Redirected Source | none | `not_applicable` | Later follow-up extends the same line rather than redirecting it |

## Journey Timeline / Phases

1. `08a` recorded that different creation entries produced semantically different results.
2. `08b` froze the line by making `Atom + atom_ref` the only valid creation invariant.
3. `08c` and `08d` translated that rule into concrete v0.3 implementation lanes.
4. `09` confirmed that the line was handed off with the defect and its repair path still explicit.
5. `PR-0403` rebuilt the line into ADR and ruling carriers.

## Current State

Current architecture reads creation-path differences as routing differences, not as different object semantics. The authoritative interpretation follows [`../rulings/S4-creation-path-unification.md`](../rulings/S4-creation-path-unification.md).

## Open Edges

- Later atom-first and single-root work may append to this line.
- Designated-folder configuration remains later follow-up rather than a blocker for the current invariant.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-11: `DOC-005 / 09` replay appended closure and v0.3-handoff confirmation without changing the creation-path invariant.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended atom_ref verification, release-sign-off, and deferred-boundary confirmation without changing the invariant.
