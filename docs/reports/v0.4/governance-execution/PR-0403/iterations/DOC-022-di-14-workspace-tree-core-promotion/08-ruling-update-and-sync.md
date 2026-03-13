# DOC-022 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-022` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-011` | update current ruling text | sync `DOC-022` workspace-tree core-promotion note to working copy + mainline row | Published placement line stays active; workspace-tree shared state/service infrastructure now explicitly belongs under `lib/core/workspace/`, subtree-rooted shared query primitives are part of the line, and feature-local tree UI responsibilities remain outside the shared carrier |
| `workspace_tree_di17_migration_boundary_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md` and `dn-ledger-classification.md` | `DI-14`'s migrated `Q3-Q5` boundary remains explicit for `DOC-025 / DI-17` instead of being mispublished locally |
| `pending_internal_trace` | `context_only` | no mainline sync | Conceptual-parent framing, scope controls, and current-vs-target gap notes remain explicit in execution artifacts only |

## Additional Sync Surfaces

1. `workspace-tree-service.md` now carries a `DOC-022 / DI-14` replay addendum so the module-level architecture spec reflects the current placement-line interpretation.
2. `open-items.md` now updates `OI-020` and adds `OI-029` so the consumed append point and the remaining `DI-17` migration boundary stay explicit.

## Queue and Sign-off State

1. `DOC-022` has completed `02 -> 08` and its sync work is closed.
2. Because this run refined one published ADR carrier and one current ruling, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-021` is now terminal `escalate_to_governance`, `DOC-022` therefore moves to `awaiting_signoff`, and `DOC-023` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-022` reaches post-sync status:

1. zero new ADR files;
2. one ADR append update;
3. one current ruling text update;
4. topic-map notes synced for one existing row;
5. one explicit migration-boundary bundle carried forward;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
