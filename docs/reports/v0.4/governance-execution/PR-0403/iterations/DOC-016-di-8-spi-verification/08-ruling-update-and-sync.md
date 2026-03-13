# DOC-016 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-016` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `pending_spi_verification_deferred_bundle` | `deferred` | no mainline sync; record carry-forward in `open-items.md` | The unresolved SPI-verification bundle remains explicit for later provider-runtime or audit work instead of producing a premature current ruling or topic-map row |

## Queue and Sign-off State

1. `DOC-016` has completed `02 -> 08` and its no-publication sync work is closed.
2. Because this run intentionally preserves an unresolved deferred bundle and leaves no mainline publication, review-lead approval is required before promoting the run to terminal `deferred`.
3. `DOC-016` therefore moves to `awaiting_signoff`, `DOC-017` remains terminal `deferred` as the explicit missing-slot record, and `DOC-018` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-016` reaches post-sync status:

1. zero ADR append or create work;
2. zero current ruling text changes;
3. zero topic-map row sync;
4. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
