# DOC-027 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze `DOC-027 / DI-19` as a governance decision source with a split surface:

1. current-effective governance rules in the revision payload;
2. historical and superseded proposal blocks preserved for replay trace.

This stage must preserve:

1. the active five-layer governance model;
2. the active SSOT boundary between `Ruling`, `ADR`, `DI`, and execution documents;
3. the active ADR admission rule built around a stable why-question and an independently traceable decision line;
4. the fact that superseded proposal sections remain historical evidence, not current rule text.

This stage must not:

1. let superseded proposal sections override already-landed current governance docs;
2. force `DI-19` into a new governance theme row or self-referential governance ADR;
3. treat governance-doc sync as equivalent to publishing a new semantic carrier.

## Source Freeze

| Frozen Surface | Source Anchor | Freeze Result |
|------|------|------|
| five-layer governance model | `### 2.1 完整文档层次` | Preserve as current-effective governance structure. |
| ADR directory structure | `### 2.3 目录结构` | Preserve as current-effective mainline governance shape. |
| active SSOT boundary | `### 10.1 规范源层级` | Preserve as current-effective authority boundary. |
| active scope and activation boundary | `### 10.2-10.4` | Preserve as current-effective migration-window and append-only boundary rules. |
| historical reconstruction ADR rules | `### 11.1-11.7` | Preserve as current-effective replay rules for retrospective ADRs. |
| PR-level update duty and gates | `### 12.1-12.3`, `### 13.1-13.3`, `### 14.1-14.3`, `## 15` | Preserve as current-effective governance obligations and activation boundary. |
| superseded proposal blocks | `### 2.2`, `## 3-9` | Preserve as replay evidence only; do not treat as active rule text. |

## Source Classification

| Field | Value |
|------|------|
| Source Status | `RESOLVED` |
| Replay Role | `current-effective governance source` |
| Carrier Eligibility In This Run | `sync already-landed governance docs, no separate governance ADR/ruling carrier` |
| Expected Replay Outcome | `append existing governance surfaces and keep superseded proposal blocks explicit as historical trace` |

## Freeze Result

`DOC-027` is frozen as a current-effective governance source whose active rules are already materially landed in the repository.

Replay must therefore:

1. sync `DI-19` into existing governance docs rather than creating a separate governance carrier;
2. keep the active and superseded layers separate;
3. leave later execution-specific refinement to `DOC-028 / DI-20`.

## References

- [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)
- [`../../../PR-0401/surveys/DOC-027-survey.md`](../../../PR-0401/surveys/DOC-027-survey.md)
- [`../../../../../v0.3/design-discussions/DI-19-adr-governance.md`](../../../../../v0.3/design-discussions/DI-19-adr-governance.md)
- [`../../../../../../architecture/adr/README.md`](../../../../../../architecture/adr/README.md)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- [`../../../PR-0402/adr-metadata-contract.md`](../../../PR-0402/adr-metadata-contract.md)
