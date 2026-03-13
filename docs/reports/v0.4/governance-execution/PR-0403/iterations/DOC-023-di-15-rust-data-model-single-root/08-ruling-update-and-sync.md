# DOC-023 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-023` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `superseded_single_root_workspace_history_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md` and `dn-ledger-classification.md` | The superseded single-root rule set remains explicit for topology lineage and audit work instead of being silently erased or republished as current. |
| `accepted_unlanded_multi_root_workspace_model_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md` and `dn-ledger-classification.md` | The active multi-root model remains explicit for later workspace runs and implementation PRs instead of producing a premature current ruling or topic-map row. |
| `accepted_unlanded_multi_root_workspace_migration_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md` and `dn-ledger-classification.md` | The multi-root migration/protection bundle remains explicit until migration `0012` and related work land. |
| `accepted_unlanded_workspace_security_model_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md` and `dn-ledger-classification.md` | The security-model bundle remains explicit for later sharing/security work instead of being flattened into background prose. |
| `pending_internal_trace` | `context_only` | no mainline sync | Pivot framing and scope boundaries remain explicit in execution artifacts only. |

## Queue and Sign-off State

1. `DOC-023` has completed `02 -> 08` and its no-publication sync work is closed.
2. Because this run intentionally preserves historical and accepted-but-unlanded workspace-topology bundles without mainline publication, review-lead approval is required before promoting the run to terminal `parked_later`.
3. `DOC-022` is now fully `completed`, `DOC-023` therefore moves to `awaiting_signoff`, and `DOC-024` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-023` reaches post-sync status:

1. zero ADR create or append work;
2. zero current ruling text changes;
3. zero topic-map row sync;
4. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
