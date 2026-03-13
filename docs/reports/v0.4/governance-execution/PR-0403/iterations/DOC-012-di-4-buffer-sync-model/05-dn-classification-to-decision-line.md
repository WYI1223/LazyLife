# DOC-012 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-012` clause nodes into stable decision-line output without inventing a new theme for every dense DI-4 subsection.

This stage must not:

1. fork a new theme for future editing modes and sidecar overlays when the source still treats them as extensions of the same shell-buffer line;
2. hide phase-2 loading continuation inside `TH-008` if it is actually the continuation of the staged-restore line;
3. promote intake, baselines, or problem framing into fake carrier rows.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-012`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Centralized per-atom `EditBuffer` ownership, full-string truth with advisory `EditOp`, manual-listener bridge, cross-mode protocol reservations, and the shell-side loading boundary | `TH-008` | `DN-193`, `DN-194`, `DN-195`, `DN-196`, `DN-197`, `DN-198`, `DN-199`, `DN-200`, `DN-201`, `DN-202`, `DN-203`, `DN-204`, `DN-206`, `DN-207`, `DN-208`, `DN-209`, `DN-210`, `DN-211`, `DN-214`, `DN-215`, `DN-216`, `DN-217`, `DN-218`, `DN-219`, `DN-229` | Append to the existing shell-ownership line. `DI-4` resolves the detailed buffer-sync and bridge contract that `S2` had kept explicit as later follow-up, but it does not introduce a second shell why-question. |
| Stage-2 loading timing, layout-failure recovery, ownership, scheduling, and unified runtime loading path for the staged restore model | `TH-012` | `DN-191`, `DN-221`, `DN-222`, `DN-223`, `DN-224`, `DN-225`, `DN-226`, `DN-227`, `DN-228` | Append to the existing staged-restore line. These clauses complete the DI-3 phase boundary from the loading side without reopening the published layout-tree structure question. |
| Intake, source-gap framing, audit method baseline, current code baselines, and opening problem statements | `pending_internal_trace` | `DN-187`, `DN-188`, `DN-189`, `DN-190`, `DN-192`, `DN-205`, `DN-212`, `DN-213`, `DN-220` | `context_only`. These clauses remain useful replay trace and problem framing, but they do not become stable semantic carriers in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-012 / DI-4-buffer-sync-model.md` |
| Covered Themes | `TH-008`, `TH-012` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `sync_current_architecture_backlink`, `preserve_context_trace` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | later `DOC-018 / DI-10`; later `DOC-022 / DI-14`; later `DOC-026 / DI-18` |
| Out of Scope | creating a future editor-mode theme row; replaying DI-10 editor-resolver shell decisions early; reopening DI-2 layout structure |
| Must Preserve | per-atom `EditBuffer`, per-keystroke sync, full-string source of truth with advisory `EditOp`, manual listener bridge, staged restore split, and stage-2 `_loadSingleBuffer` unification |
| Allowed Simplifications | forward-looking rich-mode protocol detail may stay summarized in ADR/ruling notes rather than copied clause-for-clause into every module doc |
| Escalation Required If Violated | any attempt to create a new theme for DI-4's future-mode reservations or to collapse phase-2 loading back into shell ownership without preserving the staged boundary |
| Accepted Debt | future editor-mode / block runtime detail remains current-line reservation rather than separately published theme inventory |
| Output Docs | `ADR-0002`, `S2`, `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `doc-run-queue.md`, `edit-buffer.md`, `editor-shell-service.md`, `PR-0403` execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-012` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-008` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0002`, `S2`, working-copy + mainline `topic-map.md`, `edit-buffer.md`, `editor-shell-service.md`, execution logs | DI-4 remains the detailed shell/buffer follow-up line rather than becoming a separate theme or being silently dropped into implementation docs | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-012` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, execution logs | the DI-3/DI-4 staged-restore contract remains explicit rather than collapsing stage-2 loading into shell-only wording | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-012` yields two append-and-refine runs against existing published lines and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
