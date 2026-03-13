# DOC-012 / 04 Impact Cone Review

## Purpose and Boundary

Record the downstream surfaces touched if `DOC-012` appends into the published shell and staged-restore lines.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current `TH-008` and `TH-012` rows in working copy + mainline topic maps
- current published `ADR-0002`, `S2`, `ADR-0010`, and `S10`

## Touched Surfaces

| Surface | Why It Changes | Expected Action |
|------|------|------|
| `ADR-0002` | The journey carrier must absorb DI-4's buffer model, granularity, bridge, and future-mode protocol detail | append |
| `S2` | Current shell interpretation should carry DI-4's D10/D11/D12 rules instead of leaving them as ADR-only narrative | update current ruling text |
| `ADR-0010` | The journey carrier must absorb the stage-2 loading continuation of the DI-3 staged-restore line | append |
| `S10` | Current staged-restore interpretation should include phase-2 loading timing, ownership, scheduling, and failure handling | update current ruling text |
| working-copy + mainline `topic-map.md` | `TH-008` and `TH-012` notes and secondary-input constraints must reflect that `DOC-012` is now consumed | sync existing rows |
| `dn-ledger-classification.md` | Classification working copy must record the `DOC-012 -> TH-008` and `DOC-012 -> TH-012` append results | append rows |
| `doc-run-queue.md`, iteration index, and `PR-0403` execution log | queue advancement and review state must reflect `DOC-011` completion and the new active run | sync execution state |
| `edit-buffer.md` and `editor-shell-service.md` | Current shell line backlinks should become explicit for the DI-4-rich surfaces most directly governed by `S2` | sync current-architecture backlinks |

## Risks To Guard

1. Do not create a new theme row for future editor-mode reservations unless a genuinely distinct stable why-question appears.
2. Do not let stage-2 loading overwrite the already-published DI-3 phase boundary semantics.
3. Do not park D10/D11/D12 after `S2` has already declared DI-4 as the detailed follow-up line.

## Gate Result

The impact cone is limited to two existing published lines, two topic-map rows, and two core-editor module backlink surfaces; no new ADR filename or ruling filename is required.
