# DOC-014 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-014` clause nodes into stable decision-line output without splitting execution framing away from the already-published editor-infrastructure line.

This stage must not:

1. create a second governance-only theme for DI-6 gate framing;
2. collapse the DI-6 diagnosis back into `TH-008` shell ownership;
3. promote intake anchors or top-level summary positioning into fake carrier rows.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-014`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Failed-track diagnosis, PR remap, rebased ordering principles, replacement dependency model, incremental-delivery model, and Gate A/B/Release framing for the editor-infrastructure sequence | `TH-012` | `DN-244`, `DN-245`, `DN-246`, `DN-247`, `DN-248`, `DN-249`, `DN-250`, `DN-251` | Append to the existing layout-tree / editor-infrastructure line. `DI-6` does not create a second stable why-question; it explains why the already-published structural line becomes the stage-two dependency spine and Gate B checkpoint after the old three-track model fails. |
| Intake anchors and top-level summary positioning | `pending_internal_trace` | `DN-241`, `DN-242`, `DN-243` | `context_only`. These clauses remain useful replay trace and problem framing, but they do not become semantic carriers in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-014 / DI-6-cross-track-dependencies.md` |
| Covered Themes | `TH-012` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `preserve_context_trace`, `narrow_carry_forward_target` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later `DOC-015 / DI-7-gates-perf-testing.md` |
| Out of Scope | creating a governance-only gate theme; reopening `TH-008`; importing DI-7 SLA or testing-method detail early |
| Must Preserve | DI-6 as failed-track diagnosis plus gate/dependency framing, Gate B as the editor-infrastructure checkpoint, and DI-7 as the later precision/SLA source |
| Allowed Simplifications | the rebaseline document may remain cited as the detailed execution plan instead of being copied clause-for-clause into ADR/ruling prose |
| Escalation Required If Violated | any attempt to split DI-6 into a separate governance row or to treat its gate clauses as superseding the existing layout line |
| Accepted Debt | exact gate precision, SLA thresholds, and test methodology stay carried forward to `DOC-015` |
| Output Docs | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403` execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-014` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-012` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `open-items.md`, execution logs | DI-6 stays an append to the existing editor-infrastructure line and does not become a separate governance-only carrier | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-014` yields one append-and-refine run against an existing published line and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
