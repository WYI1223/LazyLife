# DOC-015 / 04 Impact Cone Review

## Purpose and Boundary

Record the downstream surfaces touched if `DOC-015` appends line-specific gate precision and SLA semantics into the published layout-tree line.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current `TH-012` row in working copy + mainline topic map
- current published `ADR-0010` and `S10`

## Touched Surfaces

| Surface | Why It Changes | Expected Action |
|------|------|------|
| `ADR-0010` | The journey carrier must absorb the DI-7 line-specific precision layer: Gate B exactness, benchmark dimensions, SLA table, two-layer verification, and the explicit no-benchmark-CI decision | append |
| `S10` | Current-effective interpretation should now carry DI-7 line-specific gate precision and verification semantics instead of leaving that edge open after `DI-6` | update current ruling text |
| working-copy + mainline `topic-map.md` | `TH-012` notes and secondary-input constraints must reflect that `DOC-015` is now consumed | sync existing row |
| `dn-ledger-classification.md` | Classification working copy must record the `DOC-015 -> TH-012` append result, the parked governance bundle, and the intake bundle | append row |
| `open-items.md` | `OI-021` should close because the line-specific DI-7 edge is now consumed; the broader repo-wide gate/test bundle should remain explicit as a new carry-forward item | resolve one item and add one item |
| `doc-run-queue.md`, iteration index, and `PR-0403` execution log | queue advancement and review state must reflect `DOC-014` completion and the new active run | sync execution state |

## Risks To Guard

1. Do not silently treat repo-wide Gate A or Release Gate policy as current `TH-012` semantics.
2. Do not create a separate benchmark-only row when the stable why-question remains unchanged.
3. Do not hide the parked test-governance bundle just because one part of `DI-7` appends successfully.

## Gate Result

The impact cone is limited to one existing published line and its tracking surfaces; no new row, ADR filename, ruling filename, or module-backlink surface is required.
