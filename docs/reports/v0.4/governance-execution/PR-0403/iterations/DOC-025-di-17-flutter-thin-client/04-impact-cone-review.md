# DOC-025 / 04 Impact Cone Review

## Purpose and Boundary

Review which surfaces would change if `DI-17` were treated as current publication, then constrain this run to the safe replay boundary.

## Impact Cone

| Surface | Potential Impact | This Run |
|------|------|------|
| Flutter core `WorkspaceTreeService` shape and designated-folder consumption | high | record accepted-but-unlanded bundle only |
| Flutter mutation-delta pipeline and targeted reload behavior | high | record accepted-but-unlanded bundle only |
| Explorer tree UI layering and Rule E extraction boundary | high | record accepted-but-unlanded bundle only |
| system-node resolution ownership and consumer access | high | record accepted-but-unlanded bundle only |
| Tasks/Calendar controller migration and query-helper landing | high | record accepted-but-unlanded bundle only |
| synthetic uncategorized removal and legacy-path cleanup | high | record accepted-but-unlanded bundle only |
| Mainline ADR / ruling / topic-map | high | no publication in this run |
| Workflow handoff for `PR-0412` and `PR-0413` | high | must be updated in this run |
| Audit visibility for `PR-0404` | high | must be updated in this run |

## Safe Replay Boundary

This run may:

1. classify `Q1-Q6` into accepted-but-unlanded Flutter thin-client bundles;
2. record those bundles in `dn-ledger-classification.md`, `open-items.md`, and the workflow handoff doc;
3. update downstream implementation PR specs so the later landing chain sees the required changes explicitly;
4. advance the queue only to `awaiting_signoff`.

This run must not:

1. amend mainline ADRs;
2. amend current rulings;
3. add or modify mainline topic-map rows;
4. imply that `PR-0412` or `PR-0413` work is already landed.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
