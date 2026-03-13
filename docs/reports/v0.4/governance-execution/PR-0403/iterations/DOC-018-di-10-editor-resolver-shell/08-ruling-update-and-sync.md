# DOC-018 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-018` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-008` | update current ruling text | sync `DOC-018` resolver-shell note to working copy + mainline row | Published shell-ownership line stays active; resolver interface, registration, fallback safety, and the preserved future `View Mode` edge now appear in the current ruling, journey carrier, and row notes |
| `TH-011` | update current ruling text | sync `DOC-018` editor-resolver placement note to working copy + mainline row | Published placement line stays active; `editor_resolver.dart` landing under `lib/core/editor/` and the feature-chrome boundary now appear in the current ruling, journey carrier, and row notes |
| `pending_view_mode_edge` | `park_later` | update carry-forward notes only | Future `View Mode` expansion remains explicit and non-blocking rather than being silently dropped or prematurely published |
| `pending_internal_trace` | `context_only` | no mainline sync | Intake framing, inherited context, scope wording, and DI-4 handoff notes remain explicit in execution artifacts only |

## Additional Sync Surfaces

1. `open-items.md` now updates `OI-002` and `OI-020` to reflect that `DOC-018` consumed the expected shell-detail and placement append points while leaving later `View Mode` and later placement cleanup edges explicit.

## Queue and Sign-off State

1. `DOC-018` has completed `02 -> 08` and its sync work is closed.
2. Because this run updated two published ADR carriers and refined two current rulings, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-016` is now terminal `deferred`, `DOC-017` remains the explicit missing-slot record, `DOC-018` therefore moves to `awaiting_signoff`, and `DOC-019` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-018` reaches post-sync status:

1. zero new ADR files;
2. two ADR append updates;
3. two current ruling text updates;
4. topic-map notes synced for two existing rows;
5. carry-forward notes updated for existing open items;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
