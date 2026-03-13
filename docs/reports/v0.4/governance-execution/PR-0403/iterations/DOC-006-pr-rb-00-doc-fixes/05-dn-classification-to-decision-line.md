# DOC-006 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-006` governance nodes into explicit later-governance seeds, provenance carry-forward, or context-only historical traces.

This stage must not:

1. publish a governance theme row before the later current-effective governance sources are replayed;
2. treat `PR-RB-00`'s temporary `ADR -> Ruling` collapse as the final governance model;
3. flatten navigation refresh or orphan cleanup work into fake ADR-worthy lines.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-006`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Governance carrier migration and layer split seed | `pending_governance_carrier_evolution_seed` | `DN-001` | `park_later`. `PR-RB-00` captured the first major governance migration, but later `DI-19` / `DI-20` redefined the current model by restoring ADR as journey layer. `DOC-006` alone therefore cannot publish the line as current mainline truth. |
| Lifecycle and process-template lineage seed | `pending_lifecycle_template_lineage_seed` | `DN-002`, `DN-132` | `park_later`. These clauses seed later lifecycle / template governance, but `DI-20 T8 / Q5` explicitly postpones stable template backfill until governance activation and later template-playbook work. |
| Ruling status normalization and docs-verification seed | `pending_governance_verification_seed` | `DN-126`, `DN-127` | `park_later`. Both clauses matter for governance replay, but later governance and CI-policy sources define the active checker and status-layer semantics. |
| Navigation and product-doc refresh trace | `pending_doc_refresh_trace` | `DN-128-DN-130` | `context_only`. These refresh clauses matter as release-navigation evidence, but they do not answer a stable cross-version why-question that deserves its own journey carrier. |
| Provenance and orphan-retention boundary | `pending_provenance_boundary_seed` | `DN-131` | `park_later`. The explicit keep / move / delete policy matters for later audit and source provenance, but not as a publishable mainline ADR/ruling line in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-006 / PR-RB-00-doc-fixes.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `park_later`, `context_only`, `record_open_items`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-027`, `DOC-028`, `DOC-029`, later `PR-0404`, `PR-0405`, and `PR-0406` |
| Out of Scope | creating governance mainline rows before replay reaches the current-effective governance sources, publishing template/lifecycle carriers from historical template scaffolding alone, collapsing navigation refresh into governance themes |
| Must Preserve | `ADR -> Ruling` migration as historical phase, explicit template/lifecycle lineage, explicit docs-verification lineage, orphan/provenance intent, and the fact that no mainline publication occurs in this run |
| Allowed Simplifications | Lane C refresh details may remain summarized as context-only trace instead of turning into a theme row |
| Escalation Required If Violated | any attempt to publish governance mainline rows directly from `DOC-006` without replaying the later current-effective governance sources |
| Accepted Debt | `OI-012`, `OI-013`, `OI-014`, `OI-015` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403/README.md` |
| Verification | `06`, `07`, `08` stage records plus later review-lead sign-off |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-006` from `awaiting_signoff` to terminal `parked_later` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `pending_governance_carrier_evolution_seed` | `park_later + record_open_items` | `historical_governance_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md` | `PR-RB-00` remains visible as the first major carrier migration phase rather than being rewritten into the later five-layer model | `06`, `07`, `08`, review-lead sign-off |
| `pending_lifecycle_template_lineage_seed` | `park_later + record_open_items` | `historical_governance_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md` | lifecycle / template lineage must remain explicit until later governance activation and backfill work | `06`, `07`, `08`, review-lead sign-off |
| `pending_governance_verification_seed` | `park_later + record_open_items` | `historical_governance_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md` | the first docs-link checker and status-normalization layer must remain visible without being mistaken for final current governance | `06`, `07`, `08`, review-lead sign-off |
| `pending_doc_refresh_trace` | `context_only` | `historical_release_navigation_trace` | `context_only` | iteration docs, `dn-ledger-classification.md` | entrypoint / roadmap refresh stays explicit as release-navigation evidence, not a fake governance theme | `06`, `07`, `08`, review-lead sign-off |
| `pending_provenance_boundary_seed` | `park_later + record_open_items` | `historical_provenance_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md` | orphan-retention choices stay explicit for later source-provenance audit | `06`, `07`, `08`, review-lead sign-off |

## Gate Result

`DOC-006` yields:

1. three governance-lineage bundles parked for later replay;
2. one provenance-boundary bundle parked for later audit;
3. one context-only navigation/product refresh trace;
4. zero new theme rows and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
