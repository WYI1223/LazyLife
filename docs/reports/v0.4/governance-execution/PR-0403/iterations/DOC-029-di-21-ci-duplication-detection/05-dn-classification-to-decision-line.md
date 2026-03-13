# DOC-029 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-029` clause nodes without laundering accepted `DI-21` policy into a false claim that the duplication detector, allowlist surface, or CI failure-output contract is already landed in the current repo.

This stage must not:

1. create a governance ADR, ruling, or topic-map row for `DI-21`;
2. collapse Q1, Q2, and Q3 into one oversized bundle that `PR-0407` cannot consume precisely;
3. treat source-level `RESOLVED` as proof that the current `architecture_check.dart` already implements the policy.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-029`
- `ci-duplication-policy-promotion-workflow.md`
- current `PR-0407` implementation spec

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Discussion scope and replay boundary | `pending_internal_trace` | `DN-602`, `DN-603` | `context_only`. Scope boundaries remain explicit replay framing, but they do not become a publishable carrier in this run. |
| Rule E extension, trigger relation to `DI-17`, and general cross-feature governance path | `accepted_unlanded_duplication_governance_rule_bundle` | `DN-604`, `DN-605`, `DN-606` | `park_later_accepted_bundle`. `DI-21` resolves the governance position, but replay keeps it explicit rather than current because the corresponding CI rule surface is not yet landed in repo behavior. |
| Detector algorithm, threshold, scan boundary, and allowlist contract | `accepted_unlanded_duplication_detection_bundle` | `DN-607`, `DN-608`, `DN-609`, `DN-610` | `park_later_accepted_bundle`. The detector contract is resolved, but replay keeps it explicit rather than current because `architecture_check.dart` does not yet contain the landed duplication check or allowlist surface. |
| Three-layer failure output, existing-check reinforcement, and hardcoded reference strategy | `accepted_unlanded_ci_output_contract_bundle` | `DN-611`, `DN-612`, `DN-613`, `DN-614`, `DN-615` | `park_later_accepted_bundle`. The output contract is resolved, but replay keeps it explicit rather than current because the current CI output surface has not yet adopted the landed WHAT-WHY-HOW format or the planned reinforcement for checks 1 through 3. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-029 / DI-21-ci-duplication-detection.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `park_later`, `record_open_items`, `sync_ci_workflow_handoff`, `sync_downstream_pr_spec`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `PR-0407`, `PR-0404` audit, `ci-duplication-policy-promotion-workflow.md`, and carry-forward traces from `DOC-006` and `DOC-026` |
| Out of Scope | creating a governance ADR/ruling/topic-map row, claiming current CI-governance sync, or marking `DI-21` as landed without `architecture_check.dart` implementation |
| Must Preserve | the split between governance rule, detector contract, and output contract; the explicit no-publication state; and the direct handoff into `PR-0407` |
| Allowed Simplifications | `Q2` may stay grouped as one detector bundle and `Q3` may stay grouped as one output-contract bundle as long as they remain distinct from the governance-rule bundle |
| Escalation Required If Violated | any attempt to publish `DI-21` as current CI-governance behavior before the detector, allowlist, and output contract are landed in repo behavior |
| Accepted Debt | `OI-051`, `OI-052`, `OI-053` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `ci-duplication-policy-promotion-workflow.md`, `PR-0407` spec, queue and execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-029` from `awaiting_signoff` to terminal `parked_later` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `accepted_unlanded_duplication_governance_rule_bundle` | `park_later + record_open_items + sync_ci_workflow_handoff + sync_downstream_pr_spec` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `ci-duplication-policy-promotion-workflow.md`, `PR-0407` spec, queue and execution logs | Rule E extension and the general-governance path remain explicit without being mislabeled as current CI behavior before implementation lands | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_duplication_detection_bundle` | `park_later + record_open_items + sync_ci_workflow_handoff + sync_downstream_pr_spec` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `ci-duplication-policy-promotion-workflow.md`, `PR-0407` spec, queue and execution logs | the detector algorithm, threshold, scan boundary, and allowlist requirement remain explicit without implying the check already exists in the current CI script | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_ci_output_contract_bundle` | `park_later + record_open_items + sync_ci_workflow_handoff + sync_downstream_pr_spec` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `ci-duplication-policy-promotion-workflow.md`, `PR-0407` spec, queue and execution logs | the three-layer output model and check-reinforcement rules remain explicit without implying the current CI output already follows them | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |

## Gate Result

`DOC-029` yields three explicit parked accepted-but-unlanded CI-governance bundles, one context-only trace bundle, zero theme rows, and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../ci-duplication-policy-promotion-workflow.md`](../../ci-duplication-policy-promotion-workflow.md)
- [`../../../../../../releases/v0.4/prs/PR-0407-ci-duplication-detection.md`](../../../../../../releases/v0.4/prs/PR-0407-ci-duplication-detection.md)
