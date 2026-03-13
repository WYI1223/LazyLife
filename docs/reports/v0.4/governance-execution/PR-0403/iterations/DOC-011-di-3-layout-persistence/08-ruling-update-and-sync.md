# DOC-011 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-011` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-012` | update current ruling text | sync `DOC-011` persistence note to working copy + mainline row | Published layout-tree line stays active; DI-3 persistence, one-shot replacement, pane-cap, and staged restore now appear in the current ruling, journey carrier, and row notes |

## Additional Sync Surfaces

1. `docs/architecture/modules/core-editor/layout-persistence.md` now carries explicit current ADR / ruling backlinks for the line.

## Queue and Sign-off State

1. `DOC-011` has completed `02 -> 08` and its sync work is closed.
2. Because this run updated one published ADR carrier and refined one current ruling, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-011` therefore moves to `awaiting_signoff`, and `DOC-012` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-011` reaches post-sync status:

1. zero new ADR files;
2. one ADR append update;
3. one current ruling text update;
4. topic-map notes synced for one existing row;
5. one current-module backlink surface synced;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
