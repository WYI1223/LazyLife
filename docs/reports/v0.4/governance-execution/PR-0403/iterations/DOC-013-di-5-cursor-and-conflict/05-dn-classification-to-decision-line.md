# DOC-013 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-013` clause nodes into stable decision-line output without double-counting confirmatory DI-5 logic as a new architecture source.

This stage must not:

1. create a separate cursor-only theme;
2. create a separate conflict-handling theme for the current local model;
3. promote inherited sync-frequency context or open-item notes into fake carrier rows.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-013`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Per-pane cursor independence plus the judgment that no dedicated local conflict-handling subsystem is required inside the current single-process shell model | `TH-008` | `DN-234`, `DN-235`, `DN-236`, `DN-237`, `DN-238` | Append to the existing shell-ownership line. `DI-5` does not create a new why-question; it confirms the direct runtime consequences of the already-published `EditBuffer` and bridge model. |
| Intake, scope framing, summary positioning, inherited sync-frequency context, and explicit open-boundary notes | `pending_internal_trace` | `DN-230`, `DN-231`, `DN-232`, `DN-233`, `DN-239`, `DN-240` | `context_only`. These clauses remain useful replay trace and boundary notes, but they do not become semantic carriers in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-013 / DI-5-cursor-and-conflict.md` |
| Covered Themes | `TH-008` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `preserve_context_trace`, `carry_forward_open_edge` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later `DOC-018 / DI-10`; later shell/editor-mode runs; `docs/product/ideas/undo-redo-architecture.md` |
| Out of Scope | provider-driven external conflict models; final cross-pane undo/redo semantics; any new layout or resolver line |
| Must Preserve | confirmatory nature of DI-5, per-pane cursor independence, no dedicated local conflict subsystem, and inherited sync-frequency semantics from `DI-4` |
| Allowed Simplifications | inherited sync-frequency may stay as row-note context rather than being copied into a second ruling section |
| Escalation Required If Violated | any attempt to create a new cursor/conflict theme or to reinterpret DI-5 as superseding DI-4 |
| Accepted Debt | cross-pane undo/redo remains a later explicit edge rather than a blocker for closing this run |
| Output Docs | `ADR-0002`, `S2`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403` execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-013` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-008` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0002`, `S2`, working-copy + mainline `topic-map.md`, `open-items.md`, execution logs | DI-5 stays a confirmatory shell-line append and does not become a standalone cursor/conflict theme | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-013` yields one append-and-refine run against an existing published line and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
