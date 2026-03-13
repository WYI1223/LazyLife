# DOC-027 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-027` governance nodes into landed governance-surface sync rather than into new theme rows.

This stage must not:

1. create a synthetic governance `TH-xxx` row;
2. create a self-referential governance ADR or governance ruling;
3. let superseded proposal sections override the already-landed current governance docs.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-027`
- current landed governance docs under `docs/architecture/adr/`
- `PR-0402` retrospective ADR metadata contract

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Five-layer governance model sync | `none (governance-doc surface)` | `DN-008` | `append_existing_governance_surface`. `DI-19`'s active five-layer model is already landed in the ADR directory boundary and topic-map publication discipline, so replay tightens those docs instead of creating a new carrier. |
| ADR admission gate sync | `none (governance-doc surface)` | `DN-009` | `append_existing_governance_surface`. The active ADR-worthiness rule is recorded by tightening the landed metadata contract and registry admission wording around stable why-question plus independently traceable decision line. |
| Active SSOT boundary sync | `none (governance-doc surface)` | `DN-010` | `append_existing_governance_surface`. The active authority split is already in force; replay makes that rule more explicit in landed governance docs without publishing a separate governance carrier. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-027 / DI-19-adr-governance.md` |
| Covered Themes | `none (governance-doc sync only)` |
| Theme Operations | `append_existing_governance_docs`, `record_classification`, `resolve_consumed_seed`, `no_new_theme_row`, `no_new_governance_carrier` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-028`, `PR-0404`, `PR-0405`, `PR-0406` |
| Out of Scope | creating governance-specific `TH-*` rows, creating a separate governance ADR/ruling pair, importing `DI-20` execution-order detail into this run |
| Must Preserve | active vs superseded layer split, five-layer model, active SSOT boundary, stable why-question gate, and the fact that current sync happens by tightening already-landed docs |
| Allowed Simplifications | superseded proposal sections remain frozen as source evidence and are not replayed into separate carry-forward bundles in this run |
| Escalation Required If Violated | any attempt to create a self-referential governance carrier or let superseded `DI-19` proposal blocks rewrite current-effective governance docs |
| Accepted Debt | `OI-013`, `OI-014`, `OI-015` |
| Output Docs | iteration records, `docs/architecture/adr/README.md`, `docs/architecture/adr/topic-map.md`, `PR-0402/adr-metadata-contract.md`, `dn-ledger-classification.md`, `open-items.md`, queue/log sync |
| Verification | `06`, `07`, `08` stage records plus review-lead sign-off |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-027` from `awaiting_signoff` to terminal `completed` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `governance_five_layer_model_sync` | `append_existing_governance_docs` | `existing_published_governance_doc_surface` | `existing_published_governance_doc_surface_synced` | `docs/architecture/adr/README.md`, `docs/architecture/adr/topic-map.md` | ADR remains journey layer inside the active five-layer model; no new governance carrier is created | `06`, `07`, `08`, review-lead sign-off |
| `governance_adr_admission_rule_sync` | `append_existing_governance_docs` | `existing_published_governance_doc_surface` | `existing_published_governance_doc_surface_synced` | `docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`, `docs/architecture/adr/README.md`, `docs/architecture/adr/topic-map.md` | ADR admission stays tied to stable why-question plus independently traceable decision line | `06`, `07`, `08`, review-lead sign-off |
| `governance_ssot_boundary_sync` | `append_existing_governance_docs` | `existing_published_governance_doc_surface` | `existing_published_governance_doc_surface_synced` | `docs/architecture/adr/README.md`, `docs/architecture/adr/topic-map.md`, `docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md` | Ruling remains normative, ADR remains journey, DI remains exploration, and PR/release docs remain execution sync | `06`, `07`, `08`, review-lead sign-off |

## Gate Result

`DOC-027` yields:

1. three current-effective governance sync outcomes;
2. zero new theme rows;
3. zero new ADR or ruling files;
4. one resolved historical governance seed from `DOC-006`.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../../../../../architecture/adr/README.md`](../../../../../../architecture/adr/README.md)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- [`../../../PR-0402/adr-metadata-contract.md`](../../../PR-0402/adr-metadata-contract.md)
