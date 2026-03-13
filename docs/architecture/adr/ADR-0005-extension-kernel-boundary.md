# ADR-0005: Extension Kernel Boundary

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S5-extension-kernel-boundary.md`](../rulings/S5-extension-kernel-boundary.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should first-party command execution stay outside Extension Kernel while keeping a separate third-party extension contract, so that trusted product features iterate without collapsing future capability boundaries?
- Coverage Scope: Covers `08a -> 08b -> 08c -> 08d -> 09 -> v0.3 release evidence` for the first-party versus extension-kernel boundary and the rebuilt current ruling published in `PR-0403`. Stops before any real third-party runtime is introduced.
- Current Normative Source: [`../rulings/S5-extension-kernel-boundary.md`](../rulings/S5-extension-kernel-boundary.md)
- Source Corpus Summary: `08a` runtime-boundary ambiguity, `08b` S5 semantic freeze, `08c/08d` execution mapping, `09` closure/handoff, `v0.3 release evidence` verification/sign-off, and the legacy S5 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md)
- Historical Normative Snapshot: [`../rulings-legacy/S5-extension-kernel-boundary.md`](../rulings-legacy/S5-extension-kernel-boundary.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / S5` | `present` | Early runtime-boundary ambiguity preserved |
| Decision Source | `DOC-002 / S5` | `present` | S5 semantic freeze consumed |
| Normative Source | legacy S5 + rebuilt S5 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence` | `present` | Includes command/plugin planning, release handoff, and release-time verification/sign-off |
| Superseded / Redirected Source | none | `not_applicable` | No later source redirected this line before replay publication |

## Journey Timeline / Phases

1. `08a` recorded that first-party command runtime and future extension runtime were being discussed through one blurred boundary.
2. `08b` froze the line by separating trusted first-party command execution from the future third-party extension contract.
3. `08c` and `08d` translated that decision into concrete v0.3 execution lanes without forcing an early third-party runtime.
4. `09` confirmed that the line could hand off with declaration-only extension infrastructure still considered the correct current state.
5. `PR-0403` rebuilt the line into current ADR and ruling carriers.

## Current State

Current architecture keeps first-party command execution in the direct product runtime and treats Extension Kernel as a separate third-party contract surface. The authoritative interpretation follows [`../rulings/S5-extension-kernel-boundary.md`](../rulings/S5-extension-kernel-boundary.md).

## Open Edges

- The first real third-party plugin demand remains the natural append point for runtime bridge work.
- Sandboxed extension execution strategy remains a later follow-up.
- Optional manifest-style description for first-party capabilities remains documentation debt rather than a blocker.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-11: `DOC-005 / 09` replay appended declaration-only handoff confirmation and preserved the manifest-style question as explicit later debt.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended release-verification and ruling-layer sign-off without forcing runtime publication.
