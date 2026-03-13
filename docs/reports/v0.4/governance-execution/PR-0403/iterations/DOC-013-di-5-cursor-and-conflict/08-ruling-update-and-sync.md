# DOC-013 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-013` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-008` | update current ruling text | sync `DOC-013` cursor/conflict note to working copy + mainline row | Published shell-ownership line stays active; cursor independence and no-conflict local-model rules now appear in the current ruling, journey carrier, and row notes |
| `pending_internal_trace` | `context_only` | no mainline sync | Intake framing, inherited sync-frequency context, and open-boundary notes remain explicit in execution artifacts only |

## Additional Sync Surfaces

1. `open-items.md` now records the explicit carry-forward edge for cross-pane undo/redo semantics.

## Queue and Sign-off State

1. `DOC-013` has completed `02 -> 08` and its sync work is closed.
2. Because this run updated one published ADR carrier and refined one current ruling, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-013` therefore moves to `awaiting_signoff`, and `DOC-014` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-013` reaches post-sync status:

1. zero new ADR files;
2. one ADR append update;
3. one current ruling text update;
4. topic-map notes synced for one existing row;
5. one open-item carry-forward surface synced;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
