# DOC-024 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-024` clause nodes without laundering accepted-but-unlanded service and FFI contracts into premature current publication.

This stage must not:

1. create a current service/FFI theme row from `DI-16`;
2. flatten the source into one oversized "implementation bundle" that later PRs cannot consume precisely;
3. treat clause-level `RESOLVED` as proof that current repo behavior already matches the contract.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-024`
- `workspace-topology-carrier-promotion-workflow.md`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Inherited constraint map, scope boundary, and prerequisite architecture directions | `pending_internal_trace` | `DN-396`, `DN-397`, `DN-398`, `DN-399`, `DN-400`, `DN-401`, `DN-402`, `DN-403`, `DN-404`, `DN-405`, `DN-406`, `DN-407`, `DN-408`, `DN-409`, `DN-410` | `context_only`. These clauses remain explicit replay framing, dependency control, and prerequisite trace, but they do not become carriers in this run. |
| Unified scoped-query stack, repo split, service translation pattern, filter semantics, and internal global-boundary rule | `accepted_unlanded_scoped_query_stack_bundle` | `DN-411`, `DN-412`, `DN-413`, `DN-414`, `DN-415`, `DN-416`, `DN-417`, `DN-418`, `DN-419`, `DN-420`, `DN-421`, `DN-422`, `DN-423`, `DN-424`, `DN-425`, `DN-426`, `DN-427`, `DN-428`, `DN-429` | `park_later_accepted_bundle`. `DI-16` resolves the unified query stack, but replay keeps it explicit rather than current because the corresponding Rust query stack and consumer adoption are not yet fully landed. |
| Dedicated tree-navigation reads for subtree refs, ancestor paths, and ref-location lookup | `accepted_unlanded_tree_navigation_bundle` | `DN-430`, `DN-431`, `DN-432`, `DN-433`, `DN-434` | `park_later_accepted_bundle`. The navigation contract is resolved, but replay keeps it explicit rather than current because ref-path and breadcrumb consumers still belong to later workspace landing work. |
| Unified create contract plus TreeService evolution, designated-folder protection, and ancestor-path correction | `accepted_unlanded_creation_and_tree_service_bundle` | `DN-435`, `DN-436`, `DN-437`, `DN-438`, `DN-439`, `DN-440`, `DN-441`, `DN-442`, `DN-443` | `park_later_accepted_bundle`. The write-path contract is resolved, but replay keeps it explicit rather than current because creation routing, tree protection, and consumer adoption remain future work. |
| AccessGuard wrapper pattern, `CallerContext`, noop runtime strategy, and origin read-path deferral | `accepted_unlanded_access_guard_bundle` | `DN-444`, `DN-445`, `DN-446`, `DN-447`, `DN-448` | `park_later_accepted_bundle`. The access-control shell is resolved as contract direction, but replay keeps it explicit rather than current because the guard is not yet a landed enforcement surface. |
| Guarded query/create FFI, renamed API inventory, response envelopes, error-code extension, compatibility window, and Tag Panel bridge | `accepted_unlanded_ffi_surface_bundle` | `DN-449`, `DN-450`, `DN-451`, `DN-452`, `DN-453`, `DN-454`, `DN-455`, `DN-456`, `DN-457` | `park_later_accepted_bundle`. The transport contract is resolved, but replay keeps it explicit rather than current because the new Rust, Flutter, and migration surfaces are not yet fully landed. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-024 / DI-16-rust-service-ffi-contract.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `park_later`, `record_open_items`, `sync_workflow_handoff`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-025`, `DOC-026`, future workspace implementation PRs `PR-0408-PR-0413`, `workspace-topology-carrier-promotion-workflow.md`, and `PR-0404` audit |
| Out of Scope | creating a new current row, appending into existing published ADR/ruling carriers, or publishing current service/FFI carrier text from this source |
| Must Preserve | the inherited-constraint map, the clause split between query/navigation/creation-TreeService/guard/FFI bundles, and the accepted-but-unlanded status of those bundles |
| Allowed Simplifications | `Q1-Q6` may stay grouped as five implementation-facing bundles rather than being forced into fake published mini-lines before landing work exists |
| Escalation Required If Violated | any attempt to publish `DI-16` service, guard, or FFI clauses as current carrier text before workspace implementation and audit closure exist in repo behavior |
| Accepted Debt | `OI-034`, `OI-035`, `OI-036`, `OI-037`, `OI-038` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `doc-run-queue.md`, `PR-0403/README.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-024` from `awaiting_signoff` to terminal `parked_later` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `accepted_unlanded_scoped_query_stack_bundle` | `park_later + record_open_items + sync_workflow_handoff` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, queue and execution logs | scoped-query stack remains explicit and implementation-facing, but not mispublished as current before query/service landings exist | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_tree_navigation_bundle` | `park_later + record_open_items + sync_workflow_handoff` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, queue and execution logs | dedicated tree-navigation reads stay explicit and separable from the scoped-query stack | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_creation_and_tree_service_bundle` | `park_later + record_open_items + sync_workflow_handoff` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, queue and execution logs | create routing and TreeService evolution stay explicit without being mislabeled as current | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_access_guard_bundle` | `park_later + record_open_items + sync_workflow_handoff` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, queue and execution logs | guard-shell and origin-read-path deferral stay explicit without implying real enforcement already exists | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_ffi_surface_bundle` | `park_later + record_open_items + sync_workflow_handoff` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, queue and execution logs | FFI surface contract stays explicit and auditable without being mispublished as current while migration and consumer adoption remain future work | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |

## Gate Result

`DOC-024` yields five explicit parked accepted-but-unlanded service/FFI bundles, one context-only trace bundle, zero theme rows, and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
