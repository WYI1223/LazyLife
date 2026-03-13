# DOC-016 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-016` clause nodes without inventing a publishable line from an explicitly deferred discussion source.

This stage must not:

1. append unresolved verification questions into `TH-010`;
2. split one deferred bundle into fake mini-decisions;
3. downgrade the explicit deferred state into unstructured context-only noise.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-016`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Deferred SPI-verification question surface, readiness signal, and risk R6 bundle | `pending_spi_verification_deferred_bundle` | `DN-269`, `DN-270`, `DN-271`, `DN-272`, `DN-273`, `DN-274` | `deferred`. `DI-8` is an explicit deferred question surface for later provider-runtime work. No node in this source closes the timing, method, or blast-radius questions needed to append or publish a line. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-016 / DI-8-spi-verification.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `deferred`, `record_open_items`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later provider-runtime work, `PR-0404` audit, and later sync-governance follow-up |
| Out of Scope | appending unresolved questions into `TH-010`, creating a verification-only theme row, publishing a current ADR/ruling from this source |
| Must Preserve | explicit deferred status, risk R6, open questions on timing and method, and the fact that no publication occurs in this run |
| Allowed Simplifications | the six nodes may remain one deferred bundle rather than being split into multiple fake parked lines |
| Escalation Required If Violated | any attempt to turn this deferred question surface into a published line without a later closing source |
| Accepted Debt | `OI-024` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403/README.md` |
| Verification | `06`, `07`, `08` stage records plus later review-lead sign-off |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-016` from `awaiting_signoff` to terminal `deferred` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `pending_spi_verification_deferred_bundle` | `deferred + record_open_items` | `deferred_source_only` | `deferred` | iteration docs, `dn-ledger-classification.md`, `open-items.md` | DI-8 remains visible as an unresolved SPI-verification source rather than fake provider semantics | `06`, `07`, `08`, review-lead sign-off |

## Gate Result

`DOC-016` yields one explicit deferred bundle, zero theme rows, and zero mainline publication actions.
