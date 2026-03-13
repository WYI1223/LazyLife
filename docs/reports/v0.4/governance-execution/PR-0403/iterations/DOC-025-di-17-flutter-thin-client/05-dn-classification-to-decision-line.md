# DOC-025 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-025` clause nodes without laundering accepted-but-unlanded Flutter thin-client contracts into premature current publication.

This stage must not:

1. create a current Flutter consumer theme row from `DI-17`;
2. flatten the source into one oversized "Flutter migration bundle" that later PRs cannot consume precisely;
3. treat clause-level `RESOLVED` as proof that current repo behavior already matches the contract.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-025`
- `workspace-topology-carrier-promotion-workflow.md`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Input constraints, scope boundaries, and execution framing | `pending_internal_trace` | `DN-458`, `DN-459`, `DN-460` | `context_only`. These clauses remain explicit replay framing, dependency control, and execution trace, but they do not become carriers in this run. |
| `WorkspaceTreeService` B+ shape, no-cache rule, feature-side cache boundary, and future upgrade valve | `accepted_unlanded_flutter_workspace_tree_service_bundle` | `DN-461`, `DN-462`, `DN-463`, `DN-464`, `DN-465` | `park_later_accepted_bundle`. `DI-17` resolves the Flutter core service shape, but replay keeps it explicit rather than current because WorkspaceTreeService landing and consumer migration remain future implementation work. |
| Global `ChangeNotifier` plus `TreeMutationDelta`, affected-parent targeting, and consumer reload pattern | `accepted_unlanded_flutter_mutation_delta_bundle` | `DN-466`, `DN-467`, `DN-468`, `DN-469`, `DN-470` | `park_later_accepted_bundle`. The thin-client notification contract is resolved, but replay keeps it explicit rather than current because the Flutter delta pipeline is not yet landed. |
| Tree UI no-extraction-yet rule, internal layering, anti-reverse-coupling rule, extraction trigger, and Rule E compatibility | `accepted_unlanded_flutter_tree_ui_layering_bundle` | `DN-471`, `DN-472`, `DN-473`, `DN-474`, `DN-475`, `DN-476` | `park_later_accepted_bundle`. The tree UI layering rule is resolved, but replay keeps it explicit rather than current because Explorer and future picker layering work is not yet landed. |
| `WorkspaceTreeService`-owned system-node resolution, cache-key rule, reassign refresh, explicit errors, and synchronous consumer access | `accepted_unlanded_flutter_system_node_resolution_bundle` | `DN-477`, `DN-478`, `DN-479`, `DN-480`, `DN-481`, `DN-482`, `DN-483`, `DN-484` | `park_later_accepted_bundle`. The system-node resolution contract is resolved, but replay keeps it explicit rather than current because the Flutter core and feature adoption are not yet landed. |
| Tasks and Calendar controller adaptation, query-helper migration, one-shot switch-over, and grouping-placement rules | `accepted_unlanded_flutter_controller_adaptation_bundle` | `DN-485`, `DN-486`, `DN-487`, `DN-488`, `DN-489`, `DN-490`, `DN-491`, `DN-492`, `DN-493`, `DN-494` | `park_later_accepted_bundle`. The controller adaptation contract is resolved, but replay keeps it explicit rather than current because feature migration is not yet landed. |
| Synthetic uncategorized full removal, loader deletion, cleanup scope, no runtime migration UI, and test strategy | `accepted_unlanded_flutter_synthetic_removal_bundle` | `DN-495`, `DN-496`, `DN-497`, `DN-498`, `DN-499`, `DN-500` | `park_later_accepted_bundle`. The synthetic-removal contract is resolved, but replay keeps it explicit rather than current because the legacy-path cleanup is not yet landed. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-025 / DI-17-flutter-thin-client.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `park_later`, `record_open_items`, `sync_workflow_handoff`, `update_downstream_specs`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `PR-0412`, `PR-0413`, `PR-0404`, and later governance audit surfaces |
| Out of Scope | creating a new current row, appending into existing published ADR/ruling carriers, or publishing current Flutter thin-client carrier text from this source |
| Must Preserve | the split between service shape, mutation delta, tree UI layering, system-node resolution, controller adaptation, and synthetic-removal bundles |
| Allowed Simplifications | `Q1-Q6` may stay grouped as six implementation-facing bundles rather than being forced into fake published mini-lines before landing work exists |
| Escalation Required If Violated | any attempt to publish `DI-17` Flutter consumer clauses as current carrier text before `PR-0412` and `PR-0413` land and audit closure exists |
| Accepted Debt | `OI-039`, `OI-040`, `OI-041`, `OI-042`, `OI-043`, `OI-044` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0412-flutter-core.md`, `PR-0413-flutter-features.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, `doc-run-queue.md`, `PR-0403/README.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-025` from `awaiting_signoff` to terminal `parked_later` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `accepted_unlanded_flutter_workspace_tree_service_bundle` | `park_later + record_open_items + sync_workflow_handoff + update_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0412-flutter-core.md`, `PR-0413-flutter-features.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, queue and execution logs | WorkspaceTreeService B+ shape stays explicit and implementation-facing, but not mispublished as current before Flutter landing work exists | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_flutter_mutation_delta_bundle` | `park_later + record_open_items + sync_workflow_handoff + update_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0412-flutter-core.md`, `PR-0413-flutter-features.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, queue and execution logs | mutation-delta contract stays explicit and separable from generic service-shape work | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_flutter_tree_ui_layering_bundle` | `park_later + record_open_items + sync_workflow_handoff + update_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0413-flutter-features.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, queue and execution logs | tree UI layering and Rule E boundary stay explicit without implying current shared-tree extraction already exists | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_flutter_system_node_resolution_bundle` | `park_later + record_open_items + sync_workflow_handoff + update_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0412-flutter-core.md`, `PR-0413-flutter-features.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, queue and execution logs | system-node resolution ownership and consumer pattern stay explicit without implying current landing already exists | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_flutter_controller_adaptation_bundle` | `park_later + record_open_items + sync_workflow_handoff + update_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0413-flutter-features.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, queue and execution logs | controller migration remains explicit and audit-ready rather than silently implied by later feature code changes | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_flutter_synthetic_removal_bundle` | `park_later + record_open_items + sync_workflow_handoff + update_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0413-flutter-features.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, queue and execution logs | synthetic-removal scope, no-runtime-migration-UI rule, and cleanup/test surface stay explicit until the actual legacy-path removal lands | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |

## Gate Result

`DOC-025` yields six explicit parked accepted-but-unlanded Flutter thin-client bundles, one context-only trace bundle, zero theme rows, and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
