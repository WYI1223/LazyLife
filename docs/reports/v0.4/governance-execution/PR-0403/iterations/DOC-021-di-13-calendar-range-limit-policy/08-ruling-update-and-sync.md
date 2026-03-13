# DOC-021 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-021` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `pending_calendar_range_limit_governance_bundle` | `escalate_to_governance` | no mainline sync; record carry-forward in `open-items.md` and `dn-ledger-classification.md` | The unresolved range-limit contract remains explicit for later governance and implementation work instead of producing a premature current ruling or topic-map row. |

## Queue and Sign-off State

1. `DOC-021` has completed `02 -> 08` and its no-publication sync work is closed.
2. Because this run intentionally preserves an unresolved governance bundle and leaves no mainline publication, review-lead approval is required before promoting the run to terminal `escalate_to_governance`.
3. `DOC-020` is now terminal `parked_later`, `DOC-021` therefore moves to `awaiting_signoff`, and `DOC-022` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-021` reaches post-sync status:

1. zero ADR create or append work;
2. zero current ruling text changes;
3. zero topic-map row sync;
4. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
