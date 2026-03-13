# DOC-026 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-026` clause nodes without laundering execution-plan clauses into premature current publication.

This stage must not:

1. create a new current theme row from `DI-18`;
2. publish execution-policy clauses as ADR or ruling text;
3. hide accepted-but-unlanded execution obligations inside generic notes.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-026`
- `workspace-topology-carrier-promotion-workflow.md`
- current `PR-0404` and `PR-0408~PR-0413` specs

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| source framing, scope boundary, and open execution questions | `pending_internal_trace` | `DN-501`, `DN-502`, `DN-503`, `DN-510`, `DN-515`, `DN-519`, `DN-527` | `context_only`. These clauses remain explicit replay framing and question surfaces, but they do not become carriers in this run. |
| execution sequencing, dependency graph, final PR lineup, and normalized current-path mapping | `accepted_unlanded_execution_sequence_bundle` | `DN-504`, `DN-505`, `DN-506`, `DN-507`, `DN-508`, `DN-509` | `park_later_accepted_bundle`. `DI-18` resolves the execution order, but replay keeps it explicit as downstream implementation contract rather than current carrier text. |
| expand-contract cutover, strict dead-code cleanup, and per-PR cleanup pairing | `accepted_unlanded_expand_contract_cleanup_bundle` | `DN-511`, `DN-512`, `DN-513`, `DN-514` | `park_later_accepted_bundle`. The cutover mechanics are accepted execution direction, but they remain workflow and implementation obligations rather than publishable current architecture carrier text. |
| API-doc ownership, compatibility-doc ownership, error-code ownership, and ADR-replay ownership split | `accepted_unlanded_api_doc_and_adr_ownership_bundle` | `DN-516`, `DN-517`, `DN-518` | `park_later_accepted_bundle`. These clauses remain explicit ownership contract for later PRs and governance audit. |
| migration, service, FFI, Flutter, and cleanup-verification test matrix | `accepted_unlanded_per_pr_test_verification_bundle` | `DN-520`, `DN-521`, `DN-522`, `DN-523`, `DN-524`, `DN-525`, `DN-526` | `park_later_accepted_bundle`. The test matrix is accepted execution direction, but replay keeps it explicit as later PR acceptance obligations rather than a current carrier. |
| no additional file move rule and `DI-21` CI extraction handoff | `accepted_unlanded_no_move_ci_extraction_bundle` | `DN-528`, `DN-529`, `DN-530` | `park_later_accepted_bundle`. The no-move rule and CI-enforcement handoff remain explicit implementation and governance obligations rather than current carrier text. |
| legacy FFI removal inventory and zero-match verification surface | `accepted_unlanded_legacy_ffi_removal_inventory_bundle` | `DN-531` | `park_later_accepted_bundle`. Appendix A remains an executable cleanup contract for the later contract-stage PR rather than background appendix prose. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-026 / DI-18-execution-plan.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `park_later`, `record_open_items`, `sync_workflow_handoff`, `sync_downstream_specs`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `PR-0404`, `PR-0408` through `PR-0413`, later `DOC-029 / DI-21`, `workspace-topology-carrier-promotion-workflow.md` |
| Out of Scope | publishing ADRs, publishing rulings, or editing mainline `topic-map.md` from this source |
| Must Preserve | the split between sequencing, cutover-cleanup, docs ownership, testing, no-move or CI handoff, and Appendix A removal inventory |
| Allowed Simplifications | execution-plan clauses may stay grouped as six explicit bundles rather than being forced into fake semantic carrier rows |
| Escalation Required If Violated | any attempt to publish `DI-18` execution clauses as current carrier text or to consume them in later PRs without explicit workflow and spec updates |
| Accepted Debt | `OI-045`, `OI-046`, `OI-047`, `OI-048`, `OI-049`, `OI-050` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `doc-run-queue.md`, `PR-0403/README.md`, updated later PR specs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-026` from `awaiting_signoff` to terminal `parked_later` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `accepted_unlanded_execution_sequence_bundle` | `park_later + record_open_items + sync_workflow_handoff + sync_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, `workspace-topology-carrier-promotion-workflow.md`, `PR-0404`, `PR-0408~PR-0413`, queue and execution logs | execution ordering remains explicit and auditable rather than disappearing into informal sequencing folklore | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_expand_contract_cleanup_bundle` | `park_later + record_open_items + sync_workflow_handoff + sync_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, workflow, `PR-0404`, `PR-0411`, `PR-0413`, queue and execution logs | expand-contract and cleanup rules remain explicit and machine-checkable rather than being reduced to an unstated migration style | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_api_doc_and_adr_ownership_bundle` | `park_later + record_open_items + sync_workflow_handoff + sync_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, workflow, `PR-0404`, `PR-0411`, `PR-0413`, queue and execution logs | doc ownership and governance ADR ownership stay explicit instead of being rediscovered ad hoc in later PRs | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_per_pr_test_verification_bundle` | `park_later + record_open_items + sync_workflow_handoff + sync_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, workflow, `PR-0404`, `PR-0408~PR-0413`, queue and execution logs | per-PR testing and cleanup verification remain explicit acceptance obligations | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_no_move_ci_extraction_bundle` | `park_later + record_open_items + sync_workflow_handoff + sync_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, workflow, `PR-0404`, `PR-0413`, queue and execution logs | the no-move rule and DI-21 CI handoff remain explicit instead of vanishing into later cleanup assumptions | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |
| `accepted_unlanded_legacy_ffi_removal_inventory_bundle` | `park_later + record_open_items + sync_workflow_handoff + sync_downstream_specs` | `resolved_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, workflow, `PR-0404`, `PR-0413`, queue and execution logs | Appendix A remains a first-class removal inventory and zero-match verification surface | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |

## Gate Result

`DOC-026` yields six explicit parked accepted-but-unlanded execution bundles, one context-only trace bundle, zero theme rows, and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
