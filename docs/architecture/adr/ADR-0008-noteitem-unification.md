# ADR-0008: NoteItem Unification

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S8-noteitem-unification.md`](../rulings/S8-noteitem-unification.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should list-oriented FFI DTOs converge on atom-oriented responses, so that projection consumers stop carrying a parallel NoteItem lineage?
- Coverage Scope: Covers `08a -> 08b -> 08c -> 08d -> 09 -> v0.3 release evidence` for the DTO unification line and the rebuilt current ruling published in `PR-0403`. Stops before later consumer cleanup and deprecation policy work.
- Current Normative Source: [`../rulings/S8-noteitem-unification.md`](../rulings/S8-noteitem-unification.md)
- Source Corpus Summary: `08a` DTO-boundary ambiguity, `08b` S8 semantic freeze, `08c/08d` execution mapping, `09` closure/handoff, `v0.3 release evidence` verification/sign-off, and the legacy S8 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md)
- Historical Normative Snapshot: [`../rulings-legacy/S8-noteitem-unification.md`](../rulings-legacy/S8-noteitem-unification.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / S8` | `present` | Early DTO-boundary ambiguity preserved |
| Decision Source | `DOC-002 / S8` | `present` | S8 semantic freeze consumed |
| Normative Source | legacy S8 + rebuilt S8 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence` | `present` | Includes v0.3 type-unification planning, release closure, and release-time verification/sign-off |
| Superseded / Redirected Source | none | `not_applicable` | No later source redirected the line before replay publication |

## Journey Timeline / Phases

1. `08a` recorded that note-oriented DTOs were dropping Atom fields that later projections needed.
2. `08b` froze the line by declaring `AtomListItem` the single list-oriented FFI superset and by retiring `NoteItem` as the primary boundary type.
3. `08c` and `08d` translated the line into concrete v0.3 migration work.
4. `09` confirmed that the type-unification line was ready for release closure and handoff.
5. `PR-0403` rebuilt the line into current ADR and ruling carriers.

## Current State

Current architecture reads list-oriented FFI responses through an atom-oriented superset boundary rather than through a note-specific DTO split. The authoritative interpretation follows [`../rulings/S8-noteitem-unification.md`](../rulings/S8-noteitem-unification.md).

## Open Edges

- Later consumer cleanup and deprecation mechanics remain implementation follow-up.
- Search-specific snippet DTOs remain intentionally separate from this line.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-11: `DOC-005 / 09` replay appended release-closure and v0.3-handoff confirmation without collapsing the DTO-boundary line into `TH-001`.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended release-verification and ruling-layer sign-off without collapsing the DTO-boundary line into `TH-001`.
