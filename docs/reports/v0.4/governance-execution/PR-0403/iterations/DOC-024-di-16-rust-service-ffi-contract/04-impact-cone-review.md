# DOC-024 / 04 Impact Cone Review

## Purpose and Boundary

Review which surfaces would change if `DI-16` were treated as current publication, then constrain this run to the safe replay boundary.

## Impact Cone

| Surface | Potential Impact | This Run |
|------|------|------|
| Rust query repositories and service orchestration | high | record accepted-but-unlanded bundle only |
| Tree navigation and structural write APIs | high | record accepted-but-unlanded bundle only |
| AccessGuard and origin-based read-path | high | record accepted-but-unlanded bundle only |
| FFI surface and error-code contract | high | record accepted-but-unlanded bundle only |
| Flutter thin-client adoption | high | defer to `DOC-025` and workspace implementation PRs |
| Mainline ADR / ruling / topic-map | high | no publication in this run |
| Workflow handoff for `PR-0408-PR-0413` | high | must be updated in this run |
| Audit visibility for `PR-0404` | high | must be updated in this run |

## Safe Replay Boundary

This run may:

1. classify `Q1-Q6` into accepted-but-unlanded service/FFI bundles;
2. record those bundles in `dn-ledger-classification.md`, `open-items.md`, and the workflow handoff doc;
3. advance the queue only to `awaiting_signoff`.

This run must not:

1. amend mainline ADRs;
2. amend current rulings;
3. add or modify mainline topic-map rows.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
