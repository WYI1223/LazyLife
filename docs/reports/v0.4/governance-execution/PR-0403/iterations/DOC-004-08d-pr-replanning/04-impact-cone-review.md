# DOC-004 / 04 Impact Cone Review

## Purpose and Boundary

Record which published or working-copy surfaces would be affected if `DOC-004` appends evidence or parks bundles.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current mainline ADR registry
- current mainline and working-copy topic-map rows
- `open-items.md`

## Impact Cone

| Surface | Impact | Reason |
|------|------|------|
| `ADR-0002-editor-shell-ownership.md` | append-only text refresh | `DN-098-DN-099` add concrete `PR-0257 -> PR-0258` execution-lane evidence under the already-published shell-ownership line |
| `docs/architecture/rulings/S2-tab-draft-save-ownership.md` | no text change | `08d` adds lane mapping, not a new current normative rule |
| mainline `topic-map.md` row `TH-008` | note refresh only | row notes should reflect that `DOC-004` fixed the concrete v0.2.5 lane mapping without changing status |
| `topic-map-working-copy.md` row `TH-008` | note refresh only | working copy must mirror the append evidence captured in `ADR-0002` |
| `dn-ledger-classification.md` | append classification row + parked bundles | `DOC-004` needs one append row and two parked bundle outcomes |
| `open-items.md` | new carry-forward items | parked governance and closure bundles need explicit future targets |

## Guardrails

1. No new theme row may be created in this run.
2. No current ruling text may be rewritten from `DOC-004`.
3. Mixed governance/closure bundles must stay explicit instead of being smuggled into `TH-008` or `TH-004`.

## Gate Result

Impact cone review confirms a narrow append surface (`ADR-0002` + `TH-008` notes) and a wider parked-bundle surface (`dn-ledger-classification.md` + `open-items.md`) with no need for new ADR or ruling assets.

## References

- [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- [`../../open-items.md`](../../open-items.md)
