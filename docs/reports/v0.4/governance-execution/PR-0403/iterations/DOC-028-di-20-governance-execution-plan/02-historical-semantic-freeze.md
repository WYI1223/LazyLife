# DOC-028 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze `DOC-028 / DI-20` as a governance execution source with two simultaneous surfaces:

1. current-effective execution rules that are already landed on `PR-0403` through `PR-0406` and related governance docs;
2. historical or superseded planning language that must remain source trace only.

This stage must preserve:

1. the landed `Theme Delta Contract` header-vs-row schema split;
2. the landed anti-downgrade rule and gate stack model;
3. the landed closure, activation, and post-activation backfill boundary;
4. the fact that some older DI-20 wording predates the current per-document replay model and therefore cannot override already-landed governance execution docs.

This stage must not:

1. revive the superseded per-theme execution-unit wording as the active replay contract;
2. treat historical `PR-GOV-*` naming as current mainline execution naming;
3. create a synthetic governance `TH-*` row, governance ADR, or governance ruling.

## Source Freeze

| Frozen Surface | Source Anchor | Freeze Result |
|------|------|------|
| scope boundary | `## 讨论边界 / In Scope`, `Out of Scope` | Preserve as active governance execution scope. |
| anti-downgrade and Theme Delta rules | `Q1 / T5-T7` | Preserve as current-effective execution obligations. |
| T6 gate stack and closure output | `Q1 / T6` | Preserve as current-effective audit and closure model. |
| closure and activation boundary | `Q4` | Preserve as current-effective closeout rule. |
| template / playbook / lifecycle timing boundary | `Q4 / T8`, `Q5` | Preserve as current-effective post-activation backfill rule. |
| historical `PR-GOV-*` stage naming | source-level planning language | Preserve as lineage only; do not treat as current mainline execution naming. |
| per-theme execution-unit wording | `Q1` top-level historical wording | Preserve as superseded execution-language trace only; current landed replay is per-document. |

## Source Classification

| Field | Value |
|------|------|
| Source Status | `RESOLVED` |
| Replay Role | `current-effective governance execution source` |
| Carrier Eligibility In This Run | `sync already-landed governance specs and replay records, no separate governance ADR/ruling carrier` |
| Expected Replay Outcome | `append existing governance execution surfaces and keep superseded execution-language trace explicit` |

## Freeze Result

`DOC-028` is frozen as a current-effective governance execution source whose active rules are already materially landed across:

1. `PR-0403` execution contract;
2. `PR-0404` audit contract;
3. `PR-0405` activation boundary;
4. `PR-0406` post-activation template/playbook/lifecycle backfill boundary.

Replay must therefore:

1. record DI-20 on those landed governance spec surfaces;
2. keep superseded execution-language trace explicit in source form only;
3. avoid creating a separate governance carrier.

## References

- [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)
- [`../../../PR-0401/surveys/DOC-028-survey.md`](../../../PR-0401/surveys/DOC-028-survey.md)
- [`../../../../../v0.3/design-discussions/DI-20-governance-execution-plan.md`](../../../../../v0.3/design-discussions/DI-20-governance-execution-plan.md)
- [`../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md`](../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md)
- [`../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md`](../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md)
- [`../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md`](../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md)
- [`../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md`](../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md)
