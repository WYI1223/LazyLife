# DOC-028 / 04 Impact Cone Review

## Purpose and Boundary

`DOC-028` touches shared governance execution surfaces rather than any published theme row.

This stage identifies which already-landed specs and replay records must stay aligned when `DI-20` is recorded according to the current mainline execution model.

## Impacted Surfaces

| Surface | Why It Is In Scope | Expected Action |
|------|------|------|
| `PR-0403-per-adr-serial-execution.md` | Current replay contract must explicitly stay per-document, single-active-doc, while keeping Theme Delta mandatory. | Tighten and sync wording to active DI-20 execution rules. |
| `PR-0404-theme-delta-contract-and-consistency-audit.md` | Current audit contract must explicitly carry the gate stack, Theme Delta schema split, and promotion-decision responsibility. | Tighten and sync wording to active DI-20 audit rules. |
| `PR-0405-closure-audit-and-governance-activation.md` | Current activation contract must explicitly carry Theme Coverage Closure and post-audit activation boundary. | Tighten and sync wording to active DI-20 closure/activation rules. |
| `PR-0406-template-playbook-and-lifecycle-backfill.md` | Current backfill contract must explicitly carry the post-activation-only extraction boundary and playbook role. | Tighten and sync wording to active DI-20 backfill rules. |
| `doc-run-queue.md`, `README.md`, `iterations/README.md` | Queue and execution log must reflect the `DOC-027` close and `DOC-028` run state. | Advance queue and log. |
| `dn-ledger-classification.md` | Current replay needs a classification record for governance-spec sync. | Add `DOC-028` classification rows. |
| `open-items.md` | Earlier governance seeds may be resolved or narrowed by `DOC-028`. | Resolve `OI-013` and narrow `OI-014`. |

## Non-Impacted Surfaces

The following are intentionally out of scope for this run:

1. creating a new governance ADR asset under `docs/architecture/adr/`;
2. creating a new governance ruling under `docs/architecture/rulings/`;
3. changing mainline `docs/architecture/adr/topic-map.md` rows or `TH-*` numbering;
4. reopening the already-landed T1-T4 governance surfaces handled by `PR-0402` and `DOC-027`.

## Gate Result

`DOC-028` requires:

1. governance-spec sync across already-landed execution, audit, activation, and backfill surfaces;
2. replay-record sync across queue, classification, execution log, and open items;
3. zero new theme rows and zero new current-effective governance carrier files.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../README.md`](../../README.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
