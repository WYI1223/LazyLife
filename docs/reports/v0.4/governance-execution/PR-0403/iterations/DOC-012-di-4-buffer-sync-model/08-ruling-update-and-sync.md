# DOC-012 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-012` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-008` | update current ruling text | sync `DOC-012` shell-buffer note to working copy + mainline row | Published shell-ownership line stays active; DI-4 buffer model, bridge, granularity, and mode-compatible protocol detail now appear in the current ruling, journey carrier, and row notes |
| `TH-012` | update current ruling text | sync `DOC-012` staged-loading note to working copy + mainline row | Published layout-tree line stays active; DI-4 stage-2 loading timing, ownership, scheduling, failure, and runtime unification now appear in the current ruling, journey carrier, and row notes |
| `pending_internal_trace` | `context_only` | no mainline sync | Intake, baselines, and problem framing remain explicit in execution artifacts only |

## Additional Sync Surfaces

1. `docs/architecture/modules/core-editor/edit-buffer.md` now carries explicit current ADR / ruling backlinks for the shell line.
2. `docs/architecture/modules/core-editor/editor-shell-service.md` now carries explicit current ADR / ruling backlinks for the shell line.

## Queue and Sign-off State

1. `DOC-012` has completed `02 -> 08` and its sync work is closed.
2. Because this run updated two published ADR carriers and refined two current rulings, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-012` therefore moves to `awaiting_signoff`, and `DOC-013` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-012` reaches post-sync status:

1. zero new ADR files;
2. two ADR append updates;
3. two current ruling text updates;
4. topic-map notes synced for two existing rows;
5. two current-module backlink surfaces synced;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
