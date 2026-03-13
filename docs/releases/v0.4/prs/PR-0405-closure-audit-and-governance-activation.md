# PR-0405: Closure Audit and Governance Activation

| Field | Value |
|------|-----|
| **Status** | Draft |
| **Theme Coverage** | `T2`, `T6`, `T7` |
| **Dependencies** | `PR-0404` |
| **Related Decision** | [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

PR-0405 performs governance closeout after PR-0404 completes the first repo-wide consistency audit.

It has three closeout responsibilities:

1. convert PR-0404 audit output into a formal closure decision;
2. decide whether shared carrier-promotion register rows are closed, still blocked, or explicitly carried forward;
3. declare the governance activation boundary once closure conditions are satisfied.

The shared closeout sink is [carrier-promotion-decision-register.md](../../../reports/v0.4/governance-execution/carrier-promotion-decision-register.md). PR-0405 must consume every open row in that register, but only after PR-0404 has replaced its current scaffolds with finalized audit outputs.

---

## Current Landed Interpretation

`DOC-028 / DI-20` confirms the current landed activation interpretation for this PR:

1. `Theme Coverage Closure` is the only version-level closeout gate for governance replay.
2. Governance activation may occur only after PR-0404 produces a closure-audit result with no blocking failure.
3. After activation, native ADR work becomes append-only while retrospective reconstruction ADRs move to a frozen-but-correctable state.
4. Template, playbook, and lifecycle backfill remain downstream work and are not allowed to move ahead of activation.

---

## Scope

### In Scope

1. Repo-wide closeout audit based on PR-0404 results.
2. Formal `Closure Audit Output`.
3. Governance activation decision.
4. Final decision or carry-forward state for all rows in the shared carrier-promotion register.

### Out of Scope

1. Template finalization. That belongs to PR-0406.
2. Reopening PR-0403 replay outcomes without explicit new evidence.
3. Direct implementation landing for PR-0407 through PR-0413.

---

## Actions

### Action 1: Run Final Closeout Audit

Consume PR-0404 audit output and verify:

- theme coverage is closed at the release level;
- governance outputs have no unresolved blocking contradiction;
- any semantic-review remainder is explicitly handled.

### Action 2: Produce Closure Audit Output

Generate the final closeout report with:

- pass or fail status for structural, graph, policy, and semantic layers;
- exceptions and accepted debt;
- remaining unclosed judgments;
- activation recommendation.

### Action 3: Consume Shared Carrier Promotion Decision Register

Consume and update:

- [carrier-promotion-decision-register.md](../../../reports/v0.4/governance-execution/carrier-promotion-decision-register.md)

Every open register row must end PR-0405 in one of these states:

- `promoted`
- `carried_forward`
- `blocked_pending_landing` with explicit release-level acceptance

No open row may remain implicit.

### Action 4: Draft Governance Activation Boundary

Write the activation decision that defines:

- when append-only rules begin;
- how retrospective ADRs behave after activation;
- what remains downstream work for PR-0406 and later execution PRs.

---

## Deliverables

Outputs live under `docs/reports/v0.4/governance-execution/PR-0405/`.

| Action | Deliverable | Purpose |
|------|------|------|
| 1 | closeout audit notes | release-level closure evidence |
| 2 | closure audit output | formal governance closeout result |
| 3 | shared register update | final state for every carrier-promotion decision row |
| 4 | governance activation draft | activation boundary and post-activation rules |

---

## Exit Gate

- [ ] PR-0404 audit outputs consumed
- [ ] closure audit output produced
- [ ] every row in `carrier-promotion-decision-register.md` explicitly closed, promoted, or carried forward
- [ ] governance activation boundary drafted
- [ ] no blocking governance inconsistency remains open

---

## References

- [PR-0404-theme-delta-contract-and-consistency-audit.md](PR-0404-theme-delta-contract-and-consistency-audit.md)
- [carrier-promotion-decision-register.md](../../../reports/v0.4/governance-execution/carrier-promotion-decision-register.md)
- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)
