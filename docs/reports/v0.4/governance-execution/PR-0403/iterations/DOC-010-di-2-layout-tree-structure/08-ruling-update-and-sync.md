# DOC-010 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-010` replay run by recording ruling impact, topic-map sync, registry updates, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-012` | publish new current ruling `S10` | add new publish-complete row to working copy + mainline topic map | Layout-tree structure and resolve line is now active with explicit ADR/ruling backlinks |

## Additional Sync Surfaces

1. `docs/architecture/rulings/README.md` now registers `S10` as current-effective.
2. `docs/architecture/adr/README.md` now registers `ADR-0010`.
3. `docs/architecture/modules/core-editor/group-layout.md` now carries explicit backlinks to the published ADR and current ruling for this line.

## Queue and Sign-off State

1. `DOC-010` has completed `02 -> 08` and its publication sync work is closed.
2. Because this run published a new ADR/ruling pair and a new mainline topic-map row, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-010` therefore moves to `awaiting_signoff`, and `DOC-011` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-010` reaches post-sync status:

1. one new ADR file;
2. one new current ruling file;
3. one new publish-complete topic-map row;
4. one current-architecture backlink sync surface;
5. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
