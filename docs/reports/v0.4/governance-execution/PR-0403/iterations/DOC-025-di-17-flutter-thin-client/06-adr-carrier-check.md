# DOC-025 / 06 ADR Carrier Check

## Purpose and Boundary

Decide whether `DOC-025` justifies ADR or ruling publication, append, redirect, or explicit no-publication handling.

## Carrier Review

| Bundle / Candidate | Carrier Decision | Reason |
|------|------|------|
| `accepted_unlanded_flutter_workspace_tree_service_bundle` | `park_later` | The Flutter core service shape is semantically resolved, but WorkspaceTreeService landing and consumer migration are not yet fully present in repo behavior. |
| `accepted_unlanded_flutter_mutation_delta_bundle` | `park_later` | The mutation-delta contract is resolved, but replay cannot publish it as current while targeted reload consumers still depend on future landing work. |
| `accepted_unlanded_flutter_tree_ui_layering_bundle` | `park_later` | The tree UI layering rule is resolved, but current repo behavior has not yet landed the intended Explorer/future-picker split boundary. |
| `accepted_unlanded_flutter_system_node_resolution_bundle` | `park_later` | System-node resolution ownership is resolved, but replay keeps it explicit rather than current until the Flutter core and feature adoption are landed. |
| `accepted_unlanded_flutter_controller_adaptation_bundle` | `park_later` | Controller migration and query-helper usage are resolved, but feature migration is still future work. |
| `accepted_unlanded_flutter_synthetic_removal_bundle` | `park_later` | Synthetic removal and cleanup rules are resolved, but replay keeps them explicit rather than current until legacy-path removal is landed. |
| `pending_internal_trace` | `context_only` | Input constraints, scope boundaries, and execution framing remain execution-layer trace only. |

## Gate Result

Carrier outcome for `DOC-025` is:

1. zero new ADR files;
2. zero ADR append operations;
3. zero current-ruling updates;
4. six explicit no-publication parked bundles.

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
