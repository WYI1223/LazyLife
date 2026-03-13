# DOC-025 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-025` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`
- `workspace-topology-carrier-promotion-workflow.md`
- `PR-0412-flutter-core.md`
- `PR-0413-flutter-features.md`
- `PR-0404-theme-delta-contract-and-consistency-audit.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `accepted_unlanded_flutter_workspace_tree_service_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md`, `dn-ledger-classification.md`, `workspace-topology-carrier-promotion-workflow.md`, and downstream `PR-0412` / `PR-0413` / `PR-0404` specs | WorkspaceTreeService shape remains explicit for later Flutter implementation and audit work instead of producing a premature current ruling or topic-map row. |
| `accepted_unlanded_flutter_mutation_delta_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md`, `dn-ledger-classification.md`, `workspace-topology-carrier-promotion-workflow.md`, and downstream `PR-0412` / `PR-0413` / `PR-0404` specs | Mutation-delta contract remains explicit for later Flutter implementation and audit work instead of producing a premature current ruling or topic-map row. |
| `accepted_unlanded_flutter_tree_ui_layering_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md`, `dn-ledger-classification.md`, `workspace-topology-carrier-promotion-workflow.md`, and downstream `PR-0413` / `PR-0404` specs | Tree UI layering contract remains explicit for later Flutter implementation and audit work instead of producing a premature current ruling or topic-map row. |
| `accepted_unlanded_flutter_system_node_resolution_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md`, `dn-ledger-classification.md`, `workspace-topology-carrier-promotion-workflow.md`, and downstream `PR-0412` / `PR-0413` / `PR-0404` specs | System-node resolution contract remains explicit for later Flutter implementation and audit work instead of producing a premature current ruling or topic-map row. |
| `accepted_unlanded_flutter_controller_adaptation_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md`, `dn-ledger-classification.md`, `workspace-topology-carrier-promotion-workflow.md`, and downstream `PR-0413` / `PR-0404` specs | Controller adaptation contract remains explicit until feature migration is actually landed. |
| `accepted_unlanded_flutter_synthetic_removal_bundle` | `park_later` | no mainline sync; record carry-forward in `open-items.md`, `dn-ledger-classification.md`, `workspace-topology-carrier-promotion-workflow.md`, and downstream `PR-0413` / `PR-0404` specs | Synthetic-removal contract remains explicit until legacy-path cleanup is actually landed. |
| `pending_internal_trace` | `context_only` | no mainline sync | Input constraints and scope framing remain explicit in execution artifacts only. |

## Queue and Sign-off State

1. `DOC-025` has completed `02 -> 08` and its no-publication sync work is closed.
2. Because this run intentionally preserves accepted-but-unlanded Flutter thin-client bundles without mainline publication, review-lead approval is required before promoting the run to terminal `parked_later`.
3. `DOC-024` is now terminal `parked_later`, `DOC-025` therefore moves to `awaiting_signoff`, and `DOC-026` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-025` reaches post-sync status:

1. zero ADR create or append work;
2. zero current ruling text changes;
3. zero topic-map row sync;
4. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
