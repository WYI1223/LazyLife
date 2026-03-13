# DOC-019 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-019` clause nodes without publishing mixed accepted-but-unlanded material as if it were already a current-effective line.

This stage must not:

1. create a fake `atom-first API` theme row from an accepted-but-unlanded contract;
2. publish `Pending` semantics as current rule text before later closure exists;
3. scatter the resolved rename maps into separate micro-themes instead of appending them to the existing S1 line.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-019`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Stack-wide convergence from `AtomType` / `kind` naming to `ViewHint` / `view_hint`, including the enum, field, helper, and batch-landing rule | `TH-001` | `DN-314`, `DN-315`, `DN-316`, `DN-317`, `DN-318` | Append to the existing Atom-projection line. `DI-11` does not reopen the stable S1 why-question; it closes the naming-alignment consequence of the already-published `view_hint` semantic rule. |
| accepted `atom_create` direction, unified entry relation, accepted contract baseline, implementation lanes, and phased migration plan | `accepted_unlanded_atom_first_api_bundle` | `DN-291`, `DN-293`, `DN-294`, `DN-295`, `DN-296`, `DN-297`, `DN-298`, `DN-299`, `DN-300`, `DN-301`, `DN-302`, `DN-303`, `DN-304`, `DN-305`, `DN-306` | `park_later_governance_bundle`. These clauses are no longer just a proposal: replay treats them as accepted v0.4 contract direction, but still not as a publish-complete current line because they are not yet landed in repo behavior. |
| `Pending` semantics baseline, tasks/calendar pending rules, archive boundary, and API-impact consequence | `pending_pending_semantics_bundle` | `DN-307`, `DN-308`, `DN-309`, `DN-310`, `DN-311`, `DN-312` | `park_later_governance_bundle`. `DI-11` preserves this semantic-harmonization bundle explicitly, but current replay does not yet publish it as a stable line. |
| Notes-only API constraint, model-gap framing, v0.3-complete baseline rule, and rename blast-radius assessment | `pending_internal_trace` | `DN-289`, `DN-290`, `DN-292`, `DN-313` | `context_only`. These clauses remain explicit replay trace and execution framing, but they do not become carriers in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-019 / DI-11-atomtype-rename-impact.md` |
| Covered Themes | `TH-001` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `preserve_context_trace`, `park_atom_first_bundle`, `park_pending_bundle` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later atom-first API implementation work, API compatibility review, later task/calendar semantics work, and `PR-0404` audit |
| Out of Scope | publishing `atom_create` as current contract, creating a new `Pending` theme row, rewriting `TH-003` from an accepted-but-unlanded bundle |
| Must Preserve | the distinction between the resolved naming-convergence line, the accepted-but-unlanded atom-first contract, and the still-not-landed Pending bundle |
| Allowed Simplifications | the mixed current-state and blast-radius framing may stay summarized in execution artifacts rather than copied into current ruling text |
| Escalation Required If Violated | any attempt to publish the accepted-but-unlanded atom-first contract or the Pending bundle as current rule text, or to create a new theme row from unresolved follow-up material |
| Accepted Debt | `OI-003`, `OI-025`, `OI-026` |
| Output Docs | `ADR-0001`, `S1`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403` execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-019` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-001` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0001`, `S1`, working-copy + mainline `topic-map.md`, execution logs | `view_hint` remains a semantic projection hint rather than a user-owned type system, and the rename-convergence evidence stays inside the existing Atom-projection line | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-019` yields one append-and-refine run against an existing published line, one explicit parked accepted-but-unlanded contract bundle, one parked Pending bundle, and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
