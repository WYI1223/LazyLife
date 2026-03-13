# DOC-008 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-008` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-008` | no ruling text change | sync `DOC-008` naming-clarification note to working copy + mainline row | Published shell-ownership line stays active; DI-0 naming split and implementation linkage now appear in the journey carrier and row notes |
| `pending_pr_spec_trace` | `context_only` | no mainline sync | PR-spec traceability remains explicit in execution artifacts only |

## Queue and Sign-off State

1. `DOC-008` has completed `02 -> 08` and its append-only sync work is closed.
2. Because this run updated one published ADR carrier, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-008` therefore moves to `awaiting_signoff`, and `DOC-009` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-008` reaches post-sync status:

1. zero new ADR files;
2. one ADR append update;
3. zero current ruling text changes;
4. topic-map notes synced for one existing row;
5. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
