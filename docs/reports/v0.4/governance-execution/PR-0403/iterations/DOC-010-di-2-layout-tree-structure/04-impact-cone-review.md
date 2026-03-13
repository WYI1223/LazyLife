# DOC-010 / 04 Impact Cone Review

## Purpose and Boundary

Record the live surfaces affected if `DOC-010` becomes a new published layout-tree line.

## Trigger and Inputs

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- current mainline ADR and ruling registries
- current mainline and working-copy topic maps

## Impact Cone

| Surface | Impact | Reason |
|------|------|------|
| `dn-ledger-classification.md` | add `TH-012` classification row | `DOC-010` produces a new approved line rather than an append |
| `topic-map-working-copy.md` | add in-flight / publish-complete row | working copy must record the new row before or alongside mainline sync |
| `docs/architecture/adr/topic-map.md` | add publish-complete row | new current line needs a stable registry identity |
| `docs/architecture/adr/README.md` | add `ADR-0010` registry entry | mainline ADR registry must expose the new asset |
| `docs/architecture/rulings/README.md` | add `S10` registry entry | current ruling registry must expose the new asset |
| `docs/architecture/modules/core-editor/group-layout.md` | add current ADR/ruling backlinks | current architecture docs should point at the published current line |

## Non-Impacted Published Lines

1. `TH-008 / S2` does not require a ruling rewrite in this run.
2. `TH-011 / S9` does not require any placement change in this run.
3. no existing published ADR needs append text from `DOC-010`; publication happens as a new carrier pair.

## Gate Result

Impact cone is bounded and publication-safe: `DOC-010` adds one new line and syncs one current-architecture backlink surface, without forcing rewrites to previously published theme rows.

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
