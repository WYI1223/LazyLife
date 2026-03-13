# DOC-011 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-011` clause nodes into stable decision-line output without splitting persistence off from the already-published layout-tree line.

This stage must not:

1. create a persistence-only theme when the source is operationalizing the already-published layout-tree contract;
2. collapse persistence into `TH-008` shell ownership just because tab shells participate in restore;
3. smuggle `DI-4` stage-2 loading behavior into `DOC-011` classification.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-011`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Standalone JSON persistence, one-shot replacement, pane-count cap, and the DI-3 side of the staged restore boundary for the already-published layout-tree model | `TH-012` | `DN-183`, `DN-184`, `DN-185`, `DN-186` | Append to the existing layout-tree line. `DI-3` does not introduce a second stable why-question; it fixes how the same `GroupLayout` contract persists, migrates, validates split growth, and restores before `DI-4` content loading begins. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-011 / DI-3-layout-persistence.md` |
| Covered Themes | `TH-012` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `sync_current_architecture_backlink` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-010 / DI-2`; later `DOC-014 / DI-6`; later `DOC-015 / DI-7` |
| Out of Scope | detailed `DI-4` stage-2 loading strategy; shell-ownership restatement; creation of a persistence-only layout theme |
| Must Preserve | standalone layout file, debounced atomic write, one-shot replacement, eight-pane cap, no explicit depth cap, and the DI-3/DI-4 staged boundary |
| Allowed Simplifications | file-I/O implementation detail may stay summarized in replay and module-backlink notes rather than copied exhaustively into the ruling body |
| Escalation Required If Violated | any attempt to fork `TH-012` into a second layout line or to absorb DI-4 stage-2 loading detail before its own replay |
| Accepted Debt | stage-2 loading behavior remains outside this run and must stay explicit for later `DOC-012` classification |
| Output Docs | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `doc-run-queue.md`, `layout-persistence.md`, `PR-0403` execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-011` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-012` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `layout-persistence.md`, execution logs | persistence and staged restore remain part of the same layout-tree line instead of becoming a second layout theme | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-011` yields one append-and-refine run against an existing published line and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
