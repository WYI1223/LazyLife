# DOC-020 / 04 Impact Cone Review

## Purpose and Boundary

Identify what this run is allowed to touch once the no-publication conceptual-parent outcome is chosen.

## Impact Surfaces

| Surface | Action | Reason |
|------|------|------|
| `dn-ledger-classification.md` | update | Record the accepted-but-unlanded workspace-topology parent bundle explicitly |
| `open-items.md` | update | Carry forward the parent bundle to `DOC-023-DOC-026` and `PR-0404` audit |
| `doc-run-queue.md` | update | Move `DOC-020` to `awaiting_signoff` after `02 -> 08` closes |
| `PR-0403/README.md` | update | Record the no-publication conceptual-parent replay result |
| `iterations/README.md` | update | Index the new iteration folder and pending sign-off state |

## Explicit Non-Targets

This run must not touch:

1. mainline `docs/architecture/adr/topic-map.md`;
2. published ADR assets;
3. current ruling text under `docs/architecture/rulings/`;
4. current architecture docs such as `workspace-tree-service.md`, `data-model.md`, or `ffi-contracts.md`.

## Impact Conclusion

`DOC-020` is an execution-layer preservation run only. The impact cone is limited to replay artifacts, queue state, and carry-forward ledgers.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../doc-run-queue.md`](../../doc-run-queue.md)
