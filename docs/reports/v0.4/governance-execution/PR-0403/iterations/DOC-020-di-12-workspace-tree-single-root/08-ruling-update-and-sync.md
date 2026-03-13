# DOC-020 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-020` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `accepted_unlanded_workspace_topology_parent_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md` and `dn-ledger-classification.md` | The resolved single-root conceptual-parent bundle remains explicit for `DOC-023-DOC-026` and audit work instead of producing a premature current ruling or topic-map row. |
| `pending_internal_trace` | `context_only` | no mainline sync | Conceptual-parent framing and discussion boundaries remain explicit in execution artifacts only. |

## Queue and Sign-off State

1. `DOC-020` has completed `02 -> 08` and its no-publication sync work is closed.
2. Because this run intentionally preserves an accepted-but-unlanded conceptual-parent bundle and leaves no mainline publication, review-lead approval is required before promoting the run to terminal `parked_later`.
3. `DOC-019` is now fully `completed`, `DOC-020` therefore moves to `awaiting_signoff`, and `DOC-021` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-020` reaches post-sync status:

1. zero ADR create or append work;
2. zero current ruling text changes;
3. zero topic-map row sync;
4. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
