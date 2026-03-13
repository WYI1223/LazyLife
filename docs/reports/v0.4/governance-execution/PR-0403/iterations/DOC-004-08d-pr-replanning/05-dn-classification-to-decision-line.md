# DOC-004 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-004` clause nodes into append candidates, parked governance/closure bundles, and explicit non-new-theme outcomes.

This stage must not:

1. create a semantic carrier just because `08d` names a PR lane;
2. flatten mixed Rule E / CI / closure bundles into an existing semantic line;
3. treat replanning order as current normative text by itself.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-004`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Global replanning, S1-S8 landing map, dependency order, and PR-0256 prerequisite | `pending_governance_seed` | `DN-094-DN-097` | `park_later`. These clauses are execution/governance planning material and cross-theme mapping, not a clean semantic carrier for this run. |
| S2 pane-aware and dual-state-removal execution lanes | `TH-008` | `DN-098-DN-099` | Append to the existing shell-ownership line. `08d` fixes `PR-0257 -> PR-0258` as the concrete v0.2.5 execution path without changing the stable why-question. |
| Mixed Rule E / reminders / CI lane | `pending_governance_seed` | `DN-100` | `park_later`. The bundle mixes reminders execution evidence with Rule E and CI guardrail planning, so later closure/governance sources provide the cleaner carrier boundary. |
| Closure handoff, readiness gate, and release-sync planning | `pending_closure_seed` | `DN-101-DN-103` | `park_later`. These clauses belong to closure and release replay surfaces more than to a published semantic line in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-004 / 08d-pr-replanning.md` |
| Covered Themes | `TH-008` |
| Theme Operations | `append_adr`, `confirm_no_new_theme`, `park_later`, `sync_mainline_notes`, `record_open_items` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-002`, `DOC-003`, `DOC-005`, later governance sources |
| Out of Scope | creating a new theme from replanning order, publishing a governance ADR from `08d` alone, rewriting current ruling text from planning clauses |
| Must Preserve | existing shell-ownership why-question, explicit parked bundles, no silent flattening of mixed closure/governance material |
| Allowed Simplifications | PR-lane task detail may remain summarized as execution evidence rather than being copied line-by-line into current semantic carriers |
| Escalation Required If Violated | any attempt to create a new semantic row from global replanning bundles or to rewrite current ruling text from `08d` |
| Accepted Debt | `OI-002`, `OI-008`, `OI-009` |
| Output Docs | `ADR-0002`, working-copy + mainline `topic-map.md` notes, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-004` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-008` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0002`, working-copy + mainline `topic-map.md` | shell ownership remains one line; `08d` adds concrete lane mapping without turning replanning into a separate semantic carrier | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-004` yields:

1. one append candidate for an already-published row (`TH-008`);
2. one parked governance-seed bundle (`DN-094-DN-097`);
3. one parked mixed governance-seed clause (`DN-100`);
4. one parked closure-seed bundle (`DN-101-DN-103`);
5. zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
