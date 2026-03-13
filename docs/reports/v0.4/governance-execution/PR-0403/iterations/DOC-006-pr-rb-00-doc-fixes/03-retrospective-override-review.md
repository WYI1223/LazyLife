# DOC-006 / 03 Retrospective Override Review

## Purpose and Boundary

Review how later governance sources reinterpreted or absorbed the `PR-RB-00` governance-repair moves.

This stage decides whether each frozen line was:

1. carried forward as-is;
2. revised or superseded by later current-effective governance rules;
3. still unsuitable for standalone publication from `DOC-006` alone.

## Trigger and Inputs

- `DOC-027 / DI-19`
- `DOC-028 / DI-20`
- `DOC-029 / DI-21`
- `PR-0402` ADR metadata contract
- current mainline ADR and ruling registry state

## Override Review

| Line | Later Sources Consumed | Result |
|------|------------------------|--------|
| Governance carrier transition | `DI-19 2.1, 10.1, 11.6`; `DI-20 T1-T4`; current ADR/ruling registry | Continued but materially revised. `PR-RB-00` treated ADR as deprecated and absorbed by Ruling, while later governance reintroduced ADR as the journey layer and kept Ruling as the sole normative source. `DOC-006` therefore remains a historical migration phase, not the current governance rule by itself. |
| Ruling lifecycle status normalization | `DI-19` governance layering; `DI-20` execution and schema rules | Continued as lineage, but not as a standalone published current line from `DOC-006`. Later governance moved lifecycle interpretation under the revised replay-aware governance model. |
| Docs-link verification infrastructure | `DI-19` CI/link-check boundary; `DI-21` checker-extension policy | Continued and expanded. `PR-RB-00` is the first docs-link verification source, but later governance owns the broader current checker policy surface. |
| Lifecycle and process-template infrastructure | `DI-19` lifecycle hook note; `DI-20 T8 / Q5`; later `PR-0406` scope | Continued with delayed activation. `PR-RB-00` created the earliest template lineage, but later governance explicitly postponed stable template backfill until governance activation completed. |
| Navigation/product refresh | later release docs and roadmap sync surfaces | Historical only. Later documents consume the updated navigation state, but these refresh clauses do not define an independently publishable governance line. |
| Historical retention and orphan disposition | `PR-0401` source-corpus work; later audit/provenance work | Historical provenance boundary only. This line matters for auditability and source lineage, but not as a mainline ADR/ruling carrier in this run. |

## Gate Result

No `DOC-006` line is publish-complete by itself. The governance-bearing clauses remain important, but later current-effective governance sources must speak for the active rule layer.

## References

- [`../../../../../../reports/v0.3/design-discussions/DI-19-adr-governance.md`](../../../../../../reports/v0.3/design-discussions/DI-19-adr-governance.md)
- [`../../../../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`](../../../../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)
- [`../../../../../../reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md`](../../../../../../reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md)
