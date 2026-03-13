# DOC-021 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-021` clause nodes without inventing a publishable calendar-query line from an explicitly pending discussion source.

This stage must not:

1. append unresolved query-limit options into an existing published theme;
2. split one pending policy surface into fake mini-decisions;
3. downgrade the still-open governance choice into unstructured context-only noise.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-021`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Pending calendar range-limit governance question, scope boundary, and reproduction evidence bundle | `pending_calendar_range_limit_governance_bundle` | `DN-341`, `DN-342`, `DN-343`, `DN-344`, `DN-345`, `DN-346` | `escalate_to_governance`. `DI-13` fixes the policy surface and the concrete bug evidence, but it does not choose one stable answer for default-limit semantics, safety-cap semantics, or API-governance classification. Publication would therefore fake a closure that does not exist in this source. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-021 / DI-13-calendar-range-limit-policy.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `escalate_to_governance`, `record_open_items`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later calendar policy decision work, API compatibility review, contract-doc update work, and `PR-0404` audit |
| Out of Scope | publishing a current ADR/ruling, silently folding the decision into later workspace replay, or rewriting API docs as if the policy had already been chosen |
| Must Preserve | pending source status, the Tasks-vs-Calendar semantics split, the silent truncation reproduction evidence, and the three still-open governance questions |
| Allowed Simplifications | the six nodes may remain one governance-escalation bundle rather than being split into fake parked sub-lines |
| Escalation Required If Violated | any attempt to publish a current line without an explicit later source choosing the limit, safety-cap, and API-governance stance |
| Accepted Debt | `OI-028` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403/README.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-021` from `awaiting_signoff` to terminal `escalate_to_governance` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `pending_calendar_range_limit_governance_bundle` | `escalate_to_governance + record_open_items` | `pending_source_only` | `escalate_to_governance` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, queue and execution logs | the range-limit question stays explicit as an unresolved policy contract rather than being hidden in implementation prose or mispublished as current rule text | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |

## Gate Result

`DOC-021` yields one explicit governance-escalation bundle, zero theme rows, and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
