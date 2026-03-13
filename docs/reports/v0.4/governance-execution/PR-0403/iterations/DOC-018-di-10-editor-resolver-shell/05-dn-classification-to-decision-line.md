# DOC-018 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-018` clause nodes into stable decision-line output without turning resolver-shell detail into a fake new theme row.

This stage must not:

1. create a standalone resolver-only theme between `TH-008` and `TH-011`;
2. collapse placement clauses back into the shell-ownership line;
3. promote the future `View Mode` reservation into a current published rule;
4. replay DI-4 bridge mechanics as if `DI-10` locally re-decided them.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-018`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Resolver-shell layer split, pane builder interface, positive/negative parameter boundary, explicit registry protocol, and no-fallback safety rule | `TH-008` | `DN-278`, `DN-280`, `DN-281`, `DN-282`, `DN-283`, `DN-284`, `DN-285` | Append to the existing shell-ownership line. `DI-10` answers the later-detail resolver question that `S2` had left open, but it does not create a second shell why-question. |
| Core placement of `editor_resolver.dart` and the extraction boundary between core editor infrastructure and feature chrome | `TH-011` | `DN-279`, `DN-286` | Append to the existing placement line. `DI-10` concretizes where resolver infrastructure lives and what remains feature-local chrome, without creating a second placement why-question. |
| Future `View Mode` expansion placeholder | `pending_view_mode_edge` | `DN-287` | `park_later`. `DI-10` intentionally leaves this as a later v0.4+ edge rather than a current published line. |
| Intake, inherited S1 baseline, v0.3 scope statement, and the explicit DI-4 handoff boundary | `pending_internal_trace` | `DN-275`, `DN-276`, `DN-277`, `DN-288` | `context_only`. These clauses remain explicit replay trace and handoff notes, but they do not become semantic carriers in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-018 / DI-10-editor-resolver-shell.md` |
| Covered Themes | `TH-008`, `TH-011` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `preserve_context_trace`, `carry_forward_open_edge` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later shell/editor-mode DI runs, `docs/product/ideas/rich-block-editing-architecture.md`, later `DOC-022`, later `DOC-026` |
| Out of Scope | creating a resolver-only row, reopening DI-4 bridge semantics, or promoting `View Mode` into a current published rule |
| Must Preserve | resolver as a middle layer, `EditBuffer`-only pane interface, no markdown fallback for unknown carriers, feature-chrome boundary, and the explicit future `View Mode` reservation |
| Allowed Simplifications | inherited S1 context and DI-4 handoff may stay summarized in execution artifacts rather than copied into current rulings verbatim |
| Escalation Required If Violated | any attempt to split a resolver-only theme row or to treat the future `View Mode` placeholder as current publication |
| Accepted Debt | the `View Mode` reservation remains explicit as a later shell/editor-mode edge |
| Output Docs | `ADR-0002`, `S2`, `ADR-0009`, `S9`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403` execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-018` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-008` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0002`, `S2`, working-copy + mainline `topic-map.md`, `open-items.md`, execution logs | resolver-shell detail stays inside the existing shell-ownership line and does not become a second shell carrier | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-011` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0009`, `S9`, working-copy + mainline `topic-map.md`, `open-items.md`, execution logs | editor-resolver placement stays inside the existing placement line rather than reopening a distinct Rule E carrier | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-018` yields two append-and-refine updates against existing published lines, one explicit future edge, and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
