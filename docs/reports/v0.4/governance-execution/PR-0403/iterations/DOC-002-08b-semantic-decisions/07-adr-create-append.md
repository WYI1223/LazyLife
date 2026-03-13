# DOC-002 / 07 ADR Create Or Append

## Purpose and Boundary

Record the retrospective ADR assets created from the `DOC-002` run.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- `PR-0402` metadata contract
- `DOC-001` through `DOC-005` replay evidence chain
- `rulings-legacy/S1-S8`

## Created ADR Assets

| Theme ID | ADR File | Coverage Declaration Summary | Notes |
|------|------|------|------|
| `TH-001` | `ADR-0001-atom-projection-model.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Keeps deferred sub-lines visible in `Open Edges` |
| `TH-008` | `ADR-0002-editor-shell-ownership.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Later DI shell work remains an append point, not a blocker |
| `TH-002` | `ADR-0003-tag-workspace-orthogonality.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Publishes the invariant and leaves later view-mode expansion explicit |
| `TH-003` | `ADR-0004-creation-path-unification.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Notes inherited context from `TH-001` without merging carriers |
| `TH-009` | `ADR-0005-extension-kernel-boundary.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Publishes the carrier split before any third-party runtime exists |
| `TH-010` | `ADR-0006-provider-spi-interaction.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Publishes the provider/orchestrator/mapping split with runtime still deferred |
| `TH-004` | `ADR-0007-reminders-infrastructure.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Keeps bulk-delete follow-up explicit rather than delaying current publication |
| `TH-005` | `ADR-0008-noteitem-unification.md` | Trigger `present`; Decision `present`; Normative `present`; Execution/Closure `present`; Superseded/Redirected `not_applicable` | Resolves prep split ambiguity and publishes a distinct DTO line |

## Gate Result

All eight ADR assets were created as retrospective reconstruction ADRs and, after explicit `Reconstruction Notice` backfill, satisfy the minimum PR-0402 skeleton. Review-lead sign-off has been recorded separately for final run closure.

## References

- [`../../../../../../architecture/adr/`](../../../../../../architecture/adr/)
- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
