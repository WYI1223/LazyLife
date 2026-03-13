# DOC-008 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-008` clause nodes into append candidates for already-published theme rows and explicit non-carrier traces.

This stage must not:

1. create a new semantic carrier from naming clarification alone;
2. turn PR-spec traceability into a fake theme row;
3. rewrite current shell-ownership ruling text from implementation naming detail.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-008`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| DI-0 layer clarification, naming split, rename blast radius, and implementation landing | `TH-008` | `DN-146`, `DN-147`, `DN-148`, `DN-150` | Append to the existing shell-ownership line. `DOC-008` clarifies that the two `note_tab_manager` artifacts belong to different layers, fixes the state/widget naming split, records the concrete widget rename blast radius, and ties the clarification to the actual `PR-RB-06` implementation landing without changing the stable why-question. |
| PR-spec traceability for the rename split | `pending_pr_spec_trace` | `DN-149` | `context_only`. This clause is valuable traceability into `PR-0300D` and `PR-0301B`, but it does not justify a semantic carrier by itself. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-008 / DI-0-dual-tab-manager.md` |
| Covered Themes | `TH-008` |
| Theme Operations | `append_adr`, `sync_mainline_notes`, `confirm_no_new_theme`, `preserve_context_trace` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-002 / S2`, `DOC-003`, `DOC-004`, `DOC-005`, later `DOC-009 / DI-1` |
| Out of Scope | creating a new theme row from naming clarification alone, rewriting current ruling text from rename impact detail, publishing PR-spec traceability as a semantic carrier |
| Must Preserve | shell-ownership stable why-question, explicit naming split, explicit widget rename blast radius, and explicit PR-spec traceability |
| Allowed Simplifications | import/test-key rename detail may stay summarized in ADR revision records instead of being copied into current rulings |
| Escalation Required If Violated | any attempt to split naming clarification into a separate theme or to hide the PR-spec traceability edge |
| Accepted Debt | none introduced by this run |
| Output Docs | `ADR-0002`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `doc-run-queue.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-008` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-008` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0002`, working-copy + mainline `topic-map.md` | naming clarification stays inside the shell-ownership line rather than spawning a new line | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-008` yields:

1. one append candidate for an already-published theme row;
2. one explicit `context_only` PR-spec traceability clause;
3. zero new theme rows and zero current-ruling rewrites.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
