# DOC-002 / 08 Ruling Update And Sync

## Purpose and Boundary

Publish rebuilt rulings, sync completed rows to mainline topic-map, and update current architecture backlinks.

## Trigger and Inputs

- `07-adr-create-append.md`
- current-empty `docs/architecture/rulings/`
- current-empty mainline topic-map rows
- current architecture docs still pointing at `rulings-legacy/S1-S8`

## Sync Result

| Surface | Result |
|------|--------|
| Rebuilt rulings | Published `S1` through `S8` into `docs/architecture/rulings/` |
| Mainline topic map | Added publish-complete rows for `TH-001`, `TH-002`, `TH-003`, `TH-004`, `TH-005`, `TH-008`, `TH-009`, `TH-010` |
| ADR registry | `docs/architecture/adr/README.md` updated to reflect the first published ADR set |
| Ruling registry | `docs/architecture/rulings/README.md` updated from empty-set bootstrap to active registry list |
| Current architecture backlinks | Current `docs/architecture/` surfaces now point to rebuilt current rulings; historical evidence docs remain on `rulings-legacy/` |

## Historical Boundary Preserved

Historical replay and release evidence files were intentionally not mass-rewritten:

1. they remain valid source-corpus evidence;
2. they should continue to describe the historical snapshot they actually used;
3. current architecture docs now carry the current-effective backlink surface instead.

## Gate Result

`DOC-002` reaches publish-complete status after review-lead approval is recorded in [`review-lead-signoff.md`](review-lead-signoff.md).

Queue consequence:

1. `DOC-002` becomes `completed`;
2. `DOC-003` becomes `active`.

## References

- [`../../../../../../architecture/rulings/`](../../../../../../architecture/rulings/)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
