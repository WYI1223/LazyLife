# DOC-011 / 04 Impact Cone Review

## Purpose and Boundary

Record the downstream surfaces touched if `DOC-011` appends into the published layout-tree line.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current `TH-012` row in working copy + mainline topic map
- current published `ADR-0010` and `S10`

## Touched Surfaces

| Surface | Why It Changes | Expected Action |
|------|------|------|
| `ADR-0010` | The journey carrier must absorb DI-3 persistence, one-shot replacement, pane-cap, and staged-restore-boundary evidence | append |
| `S10` | Current-effective interpretation should now carry DI-3 persistence and restore rules, not leave them implicit in ADR-only prose | update current ruling text |
| working-copy + mainline `topic-map.md` | `TH-012` notes and secondary-input constraints must reflect that `DOC-011` is now consumed | sync existing row |
| `dn-ledger-classification.md` | Classification working copy must record the `DOC-011 -> TH-012` append result | append row |
| `doc-run-queue.md`, iteration index, and `PR-0403` execution log | queue advancement and review state must reflect `DOC-010` completion and the new active run | sync execution state |
| `layout-persistence.md` | Current module backlink surface must point to the published `ADR-0010 / S10` pair | sync current-architecture backlink |

## Risks To Guard

1. Do not create a second layout theme just because persistence introduces file I/O and recovery vocabulary.
2. Do not let the DI-3/DI-4 boundary collapse into a fake replay of `DI-4`.
3. Do not push pane-cap or migration wording into shell-ownership or cross-feature-placement lines.

## Gate Result

The impact cone is limited to one existing published line plus one current module-backlink surface; no new row, ADR filename, or ruling filename is required.
