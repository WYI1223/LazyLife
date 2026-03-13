# DOC-021 / 04 Impact Cone Review

## Purpose and Boundary

Identify what this run is allowed to touch once the pending-governance outcome is chosen.

## Impact Surfaces

| Surface | Action | Reason |
|------|------|------|
| `dn-ledger-classification.md` | update | Record the explicit pending calendar-range governance bundle |
| `open-items.md` | update | Carry the unresolved contract question into later governance and implementation work |
| `doc-run-queue.md` | update | Move `DOC-021` to `awaiting_signoff` after `02 -> 08` closes |
| `PR-0403/README.md` | update | Record the no-publication governance-escalation replay result |
| `iterations/README.md` | update | Index the new iteration folder and pending sign-off state |

## Explicit Non-Targets

This run must not touch:

1. mainline `docs/architecture/adr/topic-map.md`;
2. published ADR assets;
3. current ruling text under `docs/architecture/rulings/`;
4. API contract docs such as `docs/api/ffi-contracts.md` or `CLAUDE.md`.

## Impact Conclusion

`DOC-021` is an execution-layer preservation and escalation run only. The impact cone is limited to replay artifacts, queue state, and carry-forward ledgers.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../doc-run-queue.md`](../../doc-run-queue.md)
