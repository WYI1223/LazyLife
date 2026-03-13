# DOC-027 / 04 Impact Cone Review

## Purpose and Boundary

`DOC-027` touches shared governance surfaces rather than one published theme row.

This stage identifies which already-landed docs must stay aligned when the current-effective `DI-19` rules are replayed.

## Impacted Surfaces

| Surface | Why It Is In Scope | Expected Action |
|------|------|------|
| `docs/architecture/adr/README.md` | Mainline ADR boundary doc already embodies the journey-layer role and governance stack position. | Tighten and sync wording to active `DI-19` rules. |
| `docs/architecture/adr/topic-map.md` | Mainline topic-map is the published registry governed by the active ADR admission rule. | Tighten row-admission wording to active `DI-19` rule. |
| `docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md` | Current replay uses this as the retrospective ADR publication contract. | Append the explicit ADR admission gate. |
| `docs/reports/v0.4/governance-execution/PR-0403/dn-ledger-classification.md` | Current replay needs a classification record for governance-doc sync. | Add `DOC-027` classification rows. |
| `docs/reports/v0.4/governance-execution/PR-0403/open-items.md` | Earlier governance seeds may be resolved or narrowed by `DOC-027`. | Resolve the consumed carrier-evolution seed. |
| `docs/reports/v0.4/governance-execution/PR-0403/doc-run-queue.md` and `README.md` | Queue and execution log must reflect the new run state. | Advance queue and log. |

## Non-Impacted Surfaces

The following are intentionally out of scope for this run:

1. creating a new governance ADR asset under `docs/architecture/adr/`;
2. creating a new governance ruling under `docs/architecture/rulings/`;
3. changing mainline topic-map rows or `TH-*` numbering;
4. pulling `DI-20` execution-order detail into `DOC-027`.

## Gate Result

`DOC-027` requires:

1. governance-doc sync across already-landed rule surfaces;
2. replay-record sync across queue, classification, and execution log;
3. zero new theme rows and zero new current-effective governance carrier files.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../../../../../architecture/adr/README.md`](../../../../../../architecture/adr/README.md)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- [`../../README.md`](../../README.md)
