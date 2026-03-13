# ADR-0007: Reminders Infrastructure

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S7-reminders-infrastructure.md`](../rulings/S7-reminders-infrastructure.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should reminders be treated as shared/core capability rather than feature-local code, so that Rule E and lifecycle-triggered scheduling stay consistent?
- Coverage Scope: Covers `08a -> 08b -> 08c -> 08d -> 09 -> v0.3 release evidence` for reminder placement and trigger semantics and the rebuilt current ruling published in `PR-0403`. Keeps the later bulk-delete hook as an explicit follow-up edge.
- Current Normative Source: [`../rulings/S7-reminders-infrastructure.md`](../rulings/S7-reminders-infrastructure.md)
- Source Corpus Summary: `08a` placement ambiguity, `08b` S7 semantic freeze, `08c/08d` execution mapping, `09` closure/handoff, `v0.3 release evidence` verification/sign-off, and the legacy S7 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md)
- Historical Normative Snapshot: [`../rulings-legacy/S7-reminders-infrastructure.md`](../rulings-legacy/S7-reminders-infrastructure.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / D10, S7` | `present` | Early reminder-placement and trigger ambiguity preserved |
| Decision Source | `DOC-002 / S7` | `present` | S7 semantic freeze consumed |
| Normative Source | legacy S7 + rebuilt S7 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence` | `present` | Includes migration, lifecycle trigger, handoff evidence, and release-time deferred-boundary confirmation |
| Superseded / Redirected Source | none | `not_applicable` | No later source redirected the line before replay publication |

## Journey Timeline / Phases

1. `08a` recorded that reminders were feature-local and view-triggered instead of being shared infrastructure.
2. `08b` froze the line by moving reminders into shared/core infrastructure and by binding scheduling to Atom lifecycle instead of view loading.
3. `08c` and `08d` translated that direction into concrete migration and lifecycle-trigger execution work.
4. `09` confirmed that the line was ready to hand off with the bulk-delete edge still kept explicit.
5. `PR-0403` rebuilt the line into current ADR and ruling carriers.

## Current State

Current architecture treats reminders as shared platform infrastructure and schedules them from Atom lifecycle changes instead of feature-view loading. The authoritative interpretation follows [`../rulings/S7-reminders-infrastructure.md`](../rulings/S7-reminders-infrastructure.md). The `DOC-003 / 08c` replay confirms that the earliest execution form of this line is the move from `features/` to `lib/core/` with import rewiring, not a separate reminder-subsystem decision.

## Open Edges

- Bulk-delete reminder cancellation remains a later append point.
- Future platform expansion may append additional transport detail without redefining module ownership.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-10: `DOC-003 / 08c` replay appended reminder-migration execution evidence without changing the stable why-question.
- 2026-03-11: `DOC-005 / 09` replay appended closure and v0.3-handoff confirmation while keeping bulk-delete cancellation as an explicit later edge.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended release-sign-off and deferred-boundary confirmation without redefining module ownership.
