# DOC-029 / 06 ADR Carrier Check

## Purpose and Boundary

Confirm whether `DI-21` should create or amend an ADR/ruling/topic-map carrier in this run, or whether it must stay as a no-publication CI-governance handoff.

## Candidate Carrier Review

| Candidate Surface | Eligibility | Decision | Reason |
|------|------|------|------|
| Governance ADR | not eligible | `do_not_create` | `DI-21` targets CI policy and implementation behavior rather than a stable ADR-worthy architecture journey line |
| Current ruling | not eligible | `do_not_create` | No current architecture module rule can truthfully claim the duplication detector or output contract is already landed |
| Topic-map row | not eligible | `do_not_create` | `DI-21` is not a theme-line publication surface; later implementation must land in CI and governance docs instead |
| Current CI-governance doc sync in this run | blocked | `do_not_sync_yet` | The current repo still lacks the landed detector, allowlist surface, and output contract implementation |

## Carrier Decision

`DOC-029` is a no-publication governance-policy replay.

Allowed outputs in this run:

1. explicit accepted-but-unlanded bundles in replay artifacts;
2. downstream workflow handoff to `PR-0407`;
3. downstream spec sync into `PR-0407`;
4. carry-forward visibility for later audit.

Disallowed outputs in this run:

1. any governance ADR creation or append;
2. any current ruling publication or wording update;
3. any topic-map row creation or mutation;
4. any current-doc sync that implies the detector/output contract is already landed.

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
- [`../../ci-duplication-policy-promotion-workflow.md`](../../ci-duplication-policy-promotion-workflow.md)
- [`../../../../../../releases/v0.4/prs/PR-0407-ci-duplication-detection.md`](../../../../../../releases/v0.4/prs/PR-0407-ci-duplication-detection.md)
