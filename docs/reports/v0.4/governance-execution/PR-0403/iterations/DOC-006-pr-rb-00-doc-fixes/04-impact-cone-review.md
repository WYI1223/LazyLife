# DOC-006 / 04 Impact Cone Review

## Purpose and Boundary

Identify which publication or execution-layer surfaces would have to change if `DOC-006` were promoted beyond historical governance-source status.

This stage covers:

1. potential governance ADR / ruling / topic-map publication surfaces;
2. execution-layer carry-forward artifacts;
3. provenance-sensitive historical assets.

It does not pre-approve publication by itself.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- current mainline ADR and ruling registry
- current execution-layer working copy and open-item state

## Impact Cone

| Surface | Touched Scope | Reason |
|------|---------------|--------|
| Mainline `docs/architecture/adr/` and `docs/architecture/rulings/` | no direct sync expected in this run | `DOC-006` is an earliest governance-repair source, but the current-effective governance authority lives later in `DI-19` / `DI-20` / `DI-21`. |
| Mainline `docs/architecture/adr/topic-map.md` | no direct sync expected in this run | No `DOC-006` node currently qualifies for publish-complete theme-row creation without jumping over later governance sources. |
| Execution-layer governance artifacts | `doc-run-queue.md`, `dn-ledger-classification.md`, `open-items.md`, `PR-0403/README.md`, iteration records | The run still has to record why publication was deferred and where each governance bundle carries forward. |
| Historical legacy carriers | `rulings-legacy/E1-release-and-versioning.md`, `PR-RB-00` itself | These remain valid replay evidence and lineage inputs, but should not be mistaken for current mainline governance assets. |

## Gate Result

Impact is governance-heavy but bounded. This run is expected to close as a no-mainline-publication replay unless later carrier checks discover a self-contained current line, which the override review does not support.

## References

- [`../../../../../../architecture/adr/README.md`](../../../../../../architecture/adr/README.md)
- [`../../../../../../architecture/rulings/README.md`](../../../../../../architecture/rulings/README.md)
- [`../../../../../../architecture/rulings-legacy/E1-release-and-versioning.md`](../../../../../../architecture/rulings-legacy/E1-release-and-versioning.md)
