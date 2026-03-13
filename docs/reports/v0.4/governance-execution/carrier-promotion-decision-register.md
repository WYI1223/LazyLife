# Carrier Promotion Decision Register

- Owner: governance audit and closeout chain (`PR-0404` -> `PR-0405`)
- Status: initialized
- Last Updated: 2026-03-12

## Purpose

This register is the shared governance decision point for bundle families that are:

- semantically accepted;
- not yet landed in repo behavior;
- already assigned to later implementation PRs.

Implementation PRs update workflow ledgers and leave evidence. Governance PRs update this register. Carrier publication is allowed only when the relevant row reaches a promotion-ready state.

## Decision Vocabulary

| Value | Meaning |
|------|------|
| `blocked_pending_landing` | implementation work is still missing |
| `blocked_pending_audit` | implementation landed, but governance audit has not cleared promotion |
| `ready_for_promotion` | governance prerequisites are satisfied; closeout PR may promote |
| `promoted` | carrier publication has been performed and recorded |
| `carried_forward` | promotion is intentionally deferred beyond the current release window |

## Decision Rows

| Register ID | Family | Workflow Source | Carry-Forward Inputs | Current Decision | Blocking Conditions | Remaining Owners | Final Promotion Owner | Notes |
|------|------|------|------|------|------|------|------|------|
| `CPR-001` | Workspace topology carrier promotion | [PR-0403 workspace-topology workflow](PR-0403/workspace-topology-carrier-promotion-workflow.md) | `OI-031` through `OI-050` | `blocked_pending_landing` | `PR-0408` through `PR-0413` landed, workflow ledger updated, PR-0404 audit passed | `PR-0408` through `PR-0413`, then governance audit | default `PR-0405` | Covers DI-15 active bundles plus DI-16/17/18 supporting bundles |
| `CPR-002` | CI duplication policy promotion | [PR-0403 CI-duplication workflow](PR-0403/ci-duplication-policy-promotion-workflow.md) | `OI-051` through `OI-053` | `blocked_pending_landing` | `PR-0407` landed, workflow ledger updated, PR-0404 audit passed | `PR-0407`, then governance audit | default `PR-0405` if additional closeout is required | No ADR or ruling publication is expected; this row governs current CI-policy sync |

## Update Rules

1. PR-0403 creates accepted-but-unlanded families and workflow ledgers.
2. Later implementation PRs must update the relevant workflow rows with evidence.
3. PR-0404 updates this register with the current governance decision.
4. PR-0405 closes or explicitly carries forward every open row.
5. No implementation PR may silently mark a family promoted by updating only code or only a workflow ledger.
