# DOC-028 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-028` governance nodes into landed governance-spec sync rather than into new theme rows or a separate governance carrier.

This stage must not:

1. create a synthetic governance `TH-*` row;
2. create a self-referential governance ADR or governance ruling;
3. let superseded per-theme execution wording override the already-landed per-document replay model.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-028`
- current landed governance specs under `docs/releases/v0.4/prs/`
- current replay records under `docs/reports/v0.4/governance-execution/PR-0403/`

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Execution contract and Theme Delta sync | `none (governance-spec surface)` | `DN-572`, `DN-573`, `DN-574`, `DN-576`, `DN-577`, `DN-586`, `DN-601` | `append_existing_governance_surface`. DI-20's anti-downgrade rule, Theme Delta header-vs-row split, and per-PR contract requirement are already landed on the current replay and audit surfaces, so replay tightens those specs rather than creating a new carrier. |
| Gate-stack and closure sync | `none (governance-spec surface)` | `DN-575`, `DN-579`, `DN-595`, `DN-596`, `DN-597`, `DN-598`, `DN-599`, `DN-600` | `append_existing_governance_surface`. DI-20's T6 gate stack and Theme Coverage Closure are already landed on the audit and activation path, so replay tightens those specs rather than creating a new carrier. |
| Template / playbook / lifecycle boundary sync | `none (governance-spec surface)` | `DN-580`, `DN-581`, `DN-582`, `DN-583`, `DN-584` | `append_existing_governance_surface`. DI-20's post-activation backfill boundary and playbook role are already landed on the activation and backfill path, so replay tightens those specs rather than creating a new carrier. |

## Already-Landed Upstream Surfaces

The following DI-20 surfaces are already recorded by earlier landed governance work and do not create a new local sync bundle in this run:

1. T1/T2 registry and authority-boundary work is already carried by `PR-0402` and `DOC-027`;
2. T3 retrospective reconstruction minimum contract is already carried by `PR-0402`;
3. historical prep naming and per-theme execution wording remain source trace only.

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-028 / DI-20-governance-execution-plan.md` |
| Covered Themes | `none (governance execution sync only)` |
| Theme Operations | `append_existing_governance_docs`, `record_classification`, `resolve_seed`, `narrow_seed`, `no_new_theme_row`, `no_new_governance_carrier` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-029`, `PR-0404`, `PR-0405`, `PR-0406` |
| Out of Scope | creating governance-specific `TH-*` rows, creating a separate governance ADR/ruling pair, reviving superseded per-theme execution as current replay model |
| Must Preserve | single-active-doc replay remains the execution unit; Theme Delta remains mandatory; T6 remains four gates plus one closure output; template/playbook/lifecycle extraction remains post-activation only |
| Allowed Simplifications | historical `PR-GOV-*` naming remains in source-layer lineage only |
| Escalation Required If Violated | any attempt to publish a separate governance carrier or to treat superseded per-theme execution wording as the active replay contract |
| Accepted Debt | `OI-014`, `OI-015` |
| Output Docs | iteration records, `PR-0403` through `PR-0406` specs, `dn-ledger-classification.md`, `open-items.md`, queue/log sync |
| Verification | `06`, `07`, `08` stage records plus review-lead sign-off |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-028` from `awaiting_signoff` to terminal `completed` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `governance_execution_contract_sync` | `append_existing_governance_docs` | `existing_published_governance_doc_surface` | `existing_published_governance_doc_surface_synced` | `PR-0403-per-adr-serial-execution.md`, `PR-0404-theme-delta-contract-and-consistency-audit.md`, queue/log surfaces | active replay stays per-document and Theme Delta stays mandatory | `06`, `07`, `08`, review-lead sign-off |
| `governance_gate_stack_and_closure_sync` | `append_existing_governance_docs` | `existing_published_governance_doc_surface` | `existing_published_governance_doc_surface_synced` | `PR-0404-theme-delta-contract-and-consistency-audit.md`, `PR-0405-closure-audit-and-governance-activation.md`, `open-items.md` | T6 remains four gates plus one closure output, and Theme Coverage Closure remains the version-level closeout rule | `06`, `07`, `08`, review-lead sign-off |
| `governance_backfill_boundary_sync` | `append_existing_governance_docs` | `existing_published_governance_doc_surface` | `existing_published_governance_doc_surface_synced` | `PR-0405-closure-audit-and-governance-activation.md`, `PR-0406-template-playbook-and-lifecycle-backfill.md`, `open-items.md` | template/playbook/lifecycle extraction remains post-activation only and `DI-20` remains an execution-report source | `06`, `07`, `08`, review-lead sign-off |

## Gate Result

`DOC-028` yields:

1. three current-effective governance-spec sync outcomes;
2. zero new theme rows;
3. zero new ADR or ruling files;
4. one resolved lifecycle/template seed and one narrowed governance-verification seed.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md`](../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md)
- [`../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md`](../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md)
- [`../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md`](../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md)
- [`../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md`](../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md)
