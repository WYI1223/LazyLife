# DOC-015 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-015` clause nodes into stable decision-line output without flattening repo-wide gate/test policy into the already-published layout-tree line.

This stage must not:

1. create a benchmark-only theme for DI-7;
2. promote Gate A or Release Gate execution policy into fake `TH-012` semantics just because the same source document contains line-specific clauses;
3. hide the broader testing-methodology and migration bundle by pretending it was consumed by the layout-tree why-question.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-015`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Gate B precision, audit-language-to-check mapping, inherited baseline SLA, benchmark dimensions, v0.3 SLA table, two-layer verification model, and the no-benchmark-CI decision for the editor-infrastructure line | `TH-012` | `DN-256`, `DN-258`, `DN-259`, `DN-260`, `DN-261`, `DN-262`, `DN-263`, `DN-264` | Append to the existing layout-tree / editor-infrastructure line. These clauses close the exact DI-7 edge left open in `DOC-014`: how the already-published line is verified, performance-bounded, and judged at Gate B without changing its stable why-question. |
| Gate A precision, Release Gate exact command suite, PR-level test expectations, and test-migration rules | `pending_gate_and_test_policy_bundle` | `DN-255`, `DN-257`, `DN-265`, `DN-266`, `DN-267`, `DN-268` | `park_later_governance_bundle`. These clauses remain explicit repo-wide execution policy spanning multiple lines and PRs; they are important, but this run does not promote them into the current `TH-012` semantics. |
| Intake anchors | `pending_internal_trace` | `DN-252`, `DN-253`, `DN-254` | `context_only`. These clauses remain useful replay trace and problem framing, but they do not become semantic carriers in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-015 / DI-7-gates-perf-testing.md` |
| Covered Themes | `TH-012` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `resolve_open_item`, `preserve_context_trace`, `park_policy_bundle` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later `PR-0404` audit and `PR-0406` playbook backfill for the parked policy bundle |
| Out of Scope | creating a separate benchmark theme; rewriting `TH-008`; promoting Gate A or Release Gate policy into current `TH-012` wording |
| Must Preserve | `DI-7` as the line-specific precision layer for Gate B and performance verification, while keeping broader repo-wide gate/test policy explicit and parked |
| Allowed Simplifications | repo-wide Gate A and Release Gate command-suite detail may remain summarized in execution artifacts instead of being duplicated into the current ruling |
| Escalation Required If Violated | any attempt to turn the parked policy bundle into hidden debt or to treat it as already consumed by `TH-012` |
| Accepted Debt | repo-wide gate policy, PR-level testing expectations, and migration rules remain explicit non-blocking carry-forward material |
| Output Docs | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403` execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-015` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-012` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `open-items.md`, execution logs | DI-7 stays the line-specific Gate B precision and SLA/verification append; broader repo-wide gate/test policy stays outside the current line | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-015` yields one append-and-refine run against an existing published line, one parked governance bundle, and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
