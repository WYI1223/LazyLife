# DOC-026 / 04 Impact Cone Review

## Purpose and Boundary

Trace every repo surface that must reflect the `DOC-026` replay outcome.

This stage is intentionally broader than carrier publication because `DI-18` lands as execution obligations, not as current-effective ADR or ruling text.

## Impact Cone

| Surface | Impact | Required Action |
|------|------|------|
| `doc-run-queue.md` | queue state and terminal disposition | promote `DOC-025`, mark `DOC-026` as `awaiting_signoff`, keep `DOC-027` on hold |
| `dn-ledger-classification.md` | clause-level replay classification | add one context-only trace bundle and six parked accepted-but-unlanded execution bundles |
| `open-items.md` | carry-forward ledger | add explicit `OI-045~OI-050` items with downstream targets |
| `workspace-topology-carrier-promotion-workflow.md` | later implementation and audit workflow | add `DOC-026` supporting replay inputs plus ledger rows and update rules for `PR-0408~PR-0413` |
| `PR-0404` spec | audit consumer | require audit of `OI-045~OI-050` and the supporting execution ledger rows |
| `PR-0408` through `PR-0413` specs | implementation consumers | require explicit citation and workflow-row updates for the relevant `DOC-026` bundles |
| `PR-0403/README.md` and `iterations/README.md` | execution log and index | record the new run and its no-publication outcome |
| mainline ADR / ruling / topic-map | publication surface | no change in this run |

## Downstream Consumer Map

| Bundle Family | Primary Downstream PRs |
|------|------|
| sequencing and dependency order | `PR-0408` through `PR-0413` |
| expand-contract and cleanup rules | `PR-0411`, `PR-0413`, `PR-0404` |
| API-doc and ADR ownership | `PR-0411`, `PR-0413`, `PR-0404` |
| per-PR testing and cleanup verification | `PR-0408` through `PR-0413`, `PR-0404` |
| no-move rule and `DI-21` CI extraction | `PR-0413`, later `DOC-029 / DI-21`, `PR-0404` |
| legacy FFI removal inventory | `PR-0413`, `PR-0404` |

## Excluded Surfaces

This run does not touch:

1. `docs/architecture/adr/*.md`
2. `docs/architecture/rulings/*.md`
3. mainline [`docs/architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)

Those remain unchanged because `DI-18` is an execution-plan replay, not a new or updated current carrier.

## Result

The impact cone is execution and audit heavy rather than carrier heavy.

The required repo updates therefore concentrate on:

1. replay classification and carry-forward ledgers;
2. implementation workflow rules;
3. downstream PR specs and audit contract surfaces.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
