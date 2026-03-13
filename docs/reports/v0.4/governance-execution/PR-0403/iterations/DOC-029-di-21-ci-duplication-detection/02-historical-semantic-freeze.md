# DOC-029 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze `DI-21` as a resolved policy source without laundering that source-level resolution into a false claim that the current repo already contains the duplication detector or its landed failure-output contract.

## Source Snapshot

| Field | Value |
|------|------|
| Source Doc | `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md` |
| Source Status | `RESOLVED` |
| Corpus Role | `Governance policy source` |
| Replay Position | `DOC-029`, last document in the `PR-0401` inventory chain |

## Frozen Semantic Points

1. `DI-21` declares itself a normative extension of Rule E, not a mere implementation note.
2. The document resolves three policy questions:
   - general cross-feature duplication governance rather than a tree-only rule;
   - line-hash detector plus `>100` threshold plus allowlist;
   - three-layer output contract plus reinforcement for existing checks 1 through 3.
3. The output target is `tools/ci/architecture_check.dart` and CI behavior, not a new ADR, ruling, or topic-map row.

## Current Repo Observation

At replay time, the current repo does not yet show a landed `DI-21` implementation surface:

1. `tools/ci/architecture_check.dart` still exposes Rule E import, structural, and docs-link checks only;
2. no duplication-detection check is present in the current script;
3. no dedicated duplication allowlist surface is landed in `tools/ci/`;
4. `engineering-standards.md` does not yet record the Rule E extension as a current CI-governance rule.

## Freeze Result

`DOC-029` must therefore replay `DI-21` as accepted policy direction with explicit downstream handoff, not as already-landed current CI-governance behavior.

## References

- [`../../../../../v0.3/design-discussions/DI-21-ci-duplication-detection.md`](../../../../../v0.3/design-discussions/DI-21-ci-duplication-detection.md)
- [`../../../PR-0401/surveys/DOC-029-survey.md`](../../../PR-0401/surveys/DOC-029-survey.md)
