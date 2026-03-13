# DOC-023 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-023` clause nodes without laundering accepted-but-unlanded workspace-topology rules into premature current publication.

This stage must not:

1. create a current workspace-topology row from `DI-15` while the corresponding repo schema is still unlanded;
2. hide `Q1-Q6` by flattening them into generic background prose;
3. treat the security-model section as non-architectural commentary.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-023`
- current working-copy and mainline topic-map rows
- current repo migration state and `v0.4-kickoff.md`

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Architecture pivot, inherited-constraint map, and explicit in-scope/out-of-scope boundary | `pending_internal_trace` | `DN-363`, `DN-364`, `DN-365`, `DN-366`, `DN-367` | `context_only`. These clauses remain explicit replay framing and direction control, but they do not become carriers in this run. |
| Superseded single-root role storage, ROOT representation, migration sketch, visibility/protection rules, and preserved rollback/version gate | `superseded_single_root_workspace_history_bundle` | `DN-368`, `DN-369`, `DN-370`, `DN-371`, `DN-372`, `DN-373`, `DN-374`, `DN-375`, `DN-376`, `DN-377` | `park_later_historical_bundle`. The entire pre-pivot single-root rule set stays explicit as decision history and audit/provenance material, not as current publication. |
| Active multi-root topology, metadata, designated-folder, and origin-workspace contract | `accepted_unlanded_multi_root_workspace_model_bundle` | `DN-378`, `DN-379`, `DN-380`, `DN-381`, `DN-382`, `DN-383`, `DN-384` | `park_later_accepted_bundle`. `DI-15` resolves the multi-root model, but replay keeps it explicit instead of publishing it because the corresponding workspace schema and service landing work are not yet present in current repo behavior. |
| Active multi-root migration flow plus workspace-root protection contract | `accepted_unlanded_multi_root_workspace_migration_bundle` | `DN-385`, `DN-386`, `DN-387`, `DN-388`, `DN-389`, `DN-390` | `park_later_accepted_bundle`. The migration and protection answer set remains explicit rather than current because migration `0012` and its trigger set are still future work. |
| Cross-workspace security model and local-first security limit | `accepted_unlanded_workspace_security_model_bundle` | `DN-391`, `DN-392`, `DN-393`, `DN-394`, `DN-395` | `park_later_security_bundle`. The section is architectural, not commentary, but replay keeps it explicit because neither the current-stage origin-based gate nor the later storage-encryption stages are landed as current behavior. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-023 / DI-15-rust-data-model-single-root.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `park_later`, `resolve_parent_bundle`, `record_open_items`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-024`, `DOC-025`, `DOC-026`, future workspace implementation PRs `PR-0408-PR-0413`, and `PR-0404` audit |
| Out of Scope | creating a new current row, appending into `TH-011` or `TH-012`, publishing the active multi-root bundle as current rule text, or publishing the security model as current carrier text |
| Must Preserve | the architecture pivot, the full superseded single-root history bundle, the accepted-but-unlanded status of the active multi-root answer set, and the explicit security-model bundle |
| Allowed Simplifications | the active multi-root answer set may stay split at the bundle level instead of being forced into fake published mini-lines before landing work exists |
| Escalation Required If Violated | any attempt to publish `Q7-Q12` as current carrier text before the corresponding workspace schema and landing work exist in current repo behavior |
| Accepted Debt | `OI-030`, `OI-031`, `OI-032`, `OI-033` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403/README.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-023` from `awaiting_signoff` to terminal `parked_later` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `superseded_single_root_workspace_history_bundle` | `park_later + record_open_items` | `historical_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, queue and execution logs | the superseded single-root answer set remains explicit historical lineage rather than disappearing behind the later pivot | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_multi_root_workspace_model_bundle` | `park_later + record_open_items` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, queue and execution logs | the active multi-root topology, metadata, designated-folder, and origin-workspace answer set stays explicit, but not mispublished as current before landing | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_multi_root_workspace_migration_bundle` | `park_later + record_open_items` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, queue and execution logs | the migration/protection bundle stays explicit without being mislabeled as current while migration `0012` remains future work | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_workspace_security_model_bundle` | `park_later + record_open_items` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, queue and execution logs | the security-model bundle stays visible as architecture rather than commentary, without being mispublished as current | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |

## Gate Result

`DOC-023` yields four explicit parked bundles, one context-only trace bundle, zero theme rows, and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
