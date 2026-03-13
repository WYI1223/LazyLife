# DOC-014 / 04 Impact Cone Review

## Purpose and Boundary

Record the downstream surfaces touched if `DOC-014` appends into the published layout-tree line.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current `TH-012` row in working copy + mainline topic map
- current published `ADR-0010` and `S10`

## Touched Surfaces

| Surface | Why It Changes | Expected Action |
|------|------|------|
| `ADR-0010` | The journey carrier must absorb the failed-track diagnosis, PR remap, rebased dependency sequence, delivery-value model, and Gate A/B/Release framing | append |
| `S10` | Current-effective interpretation should now carry the DI-6 dependency/gate framing, not leave it implied in ADR-only prose | update current ruling text |
| working-copy + mainline `topic-map.md` | `TH-012` notes and secondary-input constraints must reflect that `DOC-014` is now consumed | sync existing row |
| `dn-ledger-classification.md` | Classification working copy must record the `DOC-014 -> TH-012` append result and keep intake/summary clauses explicit as `context_only` | append row |
| `doc-run-queue.md`, iteration index, and `PR-0403` execution log | queue advancement and review state must reflect `DOC-013` completion and the new active run | sync execution state |
| `open-items.md` | The later append target for `TH-012` should narrow from `DOC-014 + DOC-015` to `DOC-015` only | sync carry-forward note |

## Risks To Guard

1. Do not create a second governance-only theme just because DI-6 is execution-facing.
2. Do not rewrite `TH-008` shell ownership when DI-6 only uses it as causal diagnosis.
3. Do not silently pull `DI-7` precision, SLA, or test-method detail forward into this run.

## Gate Result

The impact cone is limited to one existing published line and its tracking surfaces; no new row, ADR filename, ruling filename, or module-backlink surface is required.
