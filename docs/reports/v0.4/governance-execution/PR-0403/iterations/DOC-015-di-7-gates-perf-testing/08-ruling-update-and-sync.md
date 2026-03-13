# DOC-015 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-015` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-012` | update current ruling text | sync `DOC-015` Gate B precision and SLA/verification note to working copy + mainline row | Published layout/editor-infrastructure line stays active; DI-7 Gate B precision, benchmark-definition, SLA, two-layer verification, and no-benchmark-CI semantics now appear in the current ruling, journey carrier, and row notes |
| `pending_gate_and_test_policy_bundle` | `park_later` | no mainline sync | Gate A precision, Release Gate exact suite, PR-level test expectations, and test-migration rules remain explicit in execution artifacts and `open-items.md` only |
| `pending_internal_trace` | `context_only` | no mainline sync | Intake anchors remain explicit in execution artifacts only |

## Additional Sync Surfaces

1. `open-items.md` resolves `OI-021` because the line-specific DI-7 edge for `TH-012` is now consumed.
2. `open-items.md` adds a new carry-forward item for the broader repo-wide gate/test policy bundle left outside the current line.

## Queue and Sign-off State

1. `DOC-015` has completed `02 -> 08` and its sync work is closed.
2. Because this run updated one published ADR carrier and refined one current ruling, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-015` therefore moves to `awaiting_signoff`, and `DOC-016` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-015` reaches post-sync status:

1. zero new ADR files;
2. one ADR append update;
3. one current ruling text update;
4. topic-map notes synced for one existing row;
5. one open item resolved and one open item added;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
