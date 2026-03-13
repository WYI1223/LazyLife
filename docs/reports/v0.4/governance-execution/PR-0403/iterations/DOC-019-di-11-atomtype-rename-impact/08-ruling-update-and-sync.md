# DOC-019 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-019` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-001` | update current ruling text | sync `DOC-019` naming-convergence note to working copy + mainline row | Published Atom-projection line stays active; the `view_hint` semantic line now explicitly includes stack-wide naming convergence rather than allowing `AtomType` / `kind` to imply a second semantic type system |
| `accepted_unlanded_atom_first_api_bundle` | `park_later` | update carry-forward notes only | The accepted-but-unlanded atom-first API contract stays explicit and non-blocking rather than being prematurely published as current rule text |
| `pending_pending_semantics_bundle` | `park_later` | add carry-forward notes only | Later `Pending` semantics work stays explicit and non-blocking rather than being silently dropped |
| `pending_internal_trace` | `context_only` | no mainline sync | Current-state constraints, baseline framing, and blast-radius notes remain explicit in execution artifacts only |

## Additional Sync Surfaces

1. `open-items.md` now updates `OI-003` and adds `OI-026` so the later atom-first follow-up edge records the accepted-but-unlanded `DI-11` contract explicitly.
2. `open-items.md` now adds `OI-025` so the `Pending` semantics bundle remains explicit as later work rather than disappearing into context.

## Queue and Sign-off State

1. `DOC-019` has completed `02 -> 08` and its sync work is closed.
2. Because this run updated one published ADR carrier and refined one current ruling, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-018` is now fully `completed`, `DOC-019` therefore moves to `awaiting_signoff`, and `DOC-020` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-019` reaches post-sync status:

1. zero new ADR files;
2. one ADR append update;
3. one current ruling text update;
4. topic-map notes synced for one existing row;
5. one existing open item updated plus one new carry-forward item added;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
