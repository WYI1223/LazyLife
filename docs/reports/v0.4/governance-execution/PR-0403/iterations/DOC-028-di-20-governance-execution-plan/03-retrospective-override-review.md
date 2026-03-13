# DOC-028 / 03 Retrospective Override Review

## Purpose and Boundary

Review which parts of `DI-20` should tighten landed governance execution surfaces and which parts remain historical planning trace only.

For this document, the central replay question is:

1. which `DI-20` rules are already in force on the current mainline governance specs; and
2. which earlier planning expressions would incorrectly pull replay back toward a superseded execution model.

## Override Findings

| Source Layer | Finding | Replay Consequence |
|------|------|------|
| `Q1 / T5-T7`, `Q4`, `Q5`, `Theme Delta Contract`, `Theme Delta Rows` | These clauses define the active governance execution model. | Treat as current-effective governance execution inputs. |
| `Q1` historical per-theme execution wording | This conflicts with the already-landed per-document single-active-doc replay model. | Keep as superseded execution-language trace only; do not rewrite `PR-0403` back to per-theme execution. |
| historical `PR-GOV-*` stage naming | This is prep-lineage naming, not current mainline execution naming. | Keep as historical lineage only; current mainline uses `PR-0401` through `PR-0406`. |
| `PR-0403` spec | Already carries the active single-document replay contract and mandatory Theme Delta surface. | Append / tighten only. |
| `PR-0404` and `PR-0405` specs | Already carry the gate-stack, closure, and activation surfaces. | Append / tighten only. |
| `PR-0406` spec | Already carries the post-activation backfill boundary. | Append / tighten only. |
| `PR-0402` contract and `DOC-027` sync | Already carry the landed T1-T4 governance and retrospective-ADR surfaces. | No new T1-T4 carrier work should be created here. |

## Replay Judgment

`DOC-028` is not a source that should create:

1. a new `TH-*` row;
2. a governance ADR asset;
3. a governance ruling; or
4. a fresh execution model that supersedes the already-landed `single-active-doc` contract.

Instead, the replay outcome is:

1. tighten the landed governance execution specs so they explicitly reflect the active DI-20 rule surface;
2. resolve the lifecycle-template seed opened by `DOC-006`;
3. narrow the remaining governance verification seed to the CI-facing failure/output shape that still belongs to `DOC-029 / DI-21`.

## References

- [`02-historical-semantic-freeze.md`](02-historical-semantic-freeze.md)
- [`../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md`](../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md)
- [`../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md`](../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md)
- [`../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md`](../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md)
- [`../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md`](../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md)
- [`../../open-items.md`](../../open-items.md)
