# Carrier Promotion Decision Register

- Owner: governance audit and closeout chain (`PR-0404` -> `PR-0405`)
- Status: audited by PR-0404
- Last Updated: 2026-03-13

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

| Register ID | Family | Workflow Source | Carry-Forward Inputs | Current Decision | PR-0404 Audit Result | Blocking Conditions | Remaining Owners | PR-0405 Closeout Rule | Final Promotion Owner | Notes |
|------|------|------|------|------|------|------|------|------|------|------|
| `CPR-001` | Workspace topology carrier promotion | [PR-0403 workspace-topology workflow](PR-0403/workspace-topology-carrier-promotion-workflow.md) | `OI-031` through `OI-050` | `blocked_pending_landing` | Current published carriers remain consistent only because DI-15/16/17/18 families are still kept out of mainline publication. Promotion remains blocked. | `PR-0408` through `PR-0413` landed, workflow ledger rows updated, and PR-0404/PR-0405 closeout confirms the promotion gate | `PR-0408` through `PR-0413`, then governance audit | carry forward unless every required workflow row is landed before PR-0405 closeout | default `PR-0405` | Covers DI-15 active bundles plus DI-16/17/18 supporting bundles |
| `CPR-002` | CI duplication policy promotion | [PR-0403 CI-duplication workflow](PR-0403/ci-duplication-policy-promotion-workflow.md) | `OI-051` through `OI-053` | `blocked_pending_audit` | PR-0404 audited this family as `blocked_pending_landing` because DI-21 had not landed yet. PR-0407 has now landed the detector, allowlist, and output-contract surfaces, so the shared row is waiting closeout consumption rather than further implementation landing. | PR-0405 closeout must confirm the landed PR-0407 evidence, record the final promotion-or-carry-forward outcome, and keep current CI-policy sync aligned with this shared register. | `PR-0405` governance closeout | promote only if PR-0407 landed evidence remains valid at PR-0405 closeout time; otherwise explicitly carry forward | default `PR-0405` | PR-0407 supplied the in-repo landing evidence for `OI-051` through `OI-053`; no ADR or ruling publication is expected |

## Update Rules

1. PR-0403 creates accepted-but-unlanded families and workflow ledgers.
2. Later implementation PRs must update the relevant workflow rows with evidence.
3. PR-0404 updates this register with the current governance decision and audit result.
4. PR-0405 closes or explicitly carries forward every open row.
5. No implementation PR may silently mark a family promoted by updating only code or only a workflow ledger.
