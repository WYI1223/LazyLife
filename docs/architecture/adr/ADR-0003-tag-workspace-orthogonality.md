# ADR-0003: Tag Workspace Orthogonality

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S3-tag-workspace-orthogonality.md`](../rulings/S3-tag-workspace-orthogonality.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should tag filtering and workspace tree stay orthogonal, so that explorer semantics remain stable even when tag query capability evolves?
- Coverage Scope: Covers the earliest trigger, semantic freeze, execution mapping, closure verification, `v0.3 release evidence`, and the rebuilt current ruling. Stops before later explorer-mode expansion beyond the current line.
- Current Normative Source: [`../rulings/S3-tag-workspace-orthogonality.md`](../rulings/S3-tag-workspace-orthogonality.md)
- Source Corpus Summary: `08a` ambiguity source, `08b` S3 semantic freeze, `08c/08d` execution and CI bridge, `09` closure/readiness evidence, `v0.3 release evidence` sign-off, and the legacy S3 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md)
- Historical Normative Snapshot: [`../rulings-legacy/S3-tag-workspace-orthogonality.md`](../rulings-legacy/S3-tag-workspace-orthogonality.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / S3` | `present` | Earliest ambiguity signal preserved |
| Decision Source | `DOC-002 / S3` | `present` | Full S3 semantic freeze consumed |
| Normative Source | legacy S3 + rebuilt S3 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence` | `present` | Includes CI/routing expectations, v0.3 readiness evidence, and release-time sign-off |
| Superseded / Redirected Source | none | `not_applicable` | Later material validates the line rather than redirecting it |

## Journey Timeline / Phases

1. `08a` recorded that tag filtering and workspace structure lacked a stable semantic boundary.
2. `08b` froze the line by making tag and workspace orthogonal dimensions.
3. `08c` and `08d` reframed later work as invariant-preserving implementation rather than semantic redesign.
4. `09` confirmed that the line could be carried into v0.3 without reopening the stable why-question.
5. `PR-0403` rebuilt the line into ADR and ruling carriers.

## Current State

Current architecture treats tag queries as semantic filtering and the workspace tree as structural organization. The authoritative interpretation follows [`../rulings/S3-tag-workspace-orthogonality.md`](../rulings/S3-tag-workspace-orthogonality.md), including the requirement that tag queries preserve explicit path context instead of mutating the tree.

## Open Edges

- Later explorer view-mode work may add list or spatial surfaces, but should preserve the orthogonality invariant.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-11: `DOC-005 / 09` replay appended closure and v0.3-handoff confirmation without reopening the orthogonality line.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended release-sign-off and post-review re-verification evidence without changing the stable boundary.
