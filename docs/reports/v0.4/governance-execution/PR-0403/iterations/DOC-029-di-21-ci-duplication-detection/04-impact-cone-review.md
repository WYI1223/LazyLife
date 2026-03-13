# DOC-029 / 04 Impact Cone Review

## Purpose and Boundary

Map the real landing surfaces that would have to change if `DI-21` were implemented, so this replay run can distinguish source acceptance from current landed behavior.

## Impact Surfaces

| Surface | Current State | Replay Impact |
|------|------|------|
| `tools/ci/architecture_check.dart` | landed CI script without a duplication-detection check | later implementation target only |
| `tools/ci/duplication_allowlist.yaml` or equivalent allowlist surface | not landed | later implementation target only |
| `docs/architecture/engineering-standards.md` | Rule E currently documents cross-feature import and slice boundaries only | later current-doc sync target only |
| `PR-0407-ci-duplication-detection.md` | draft downstream implementation spec | must be synchronized in this replay run |
| `PR-0404-theme-delta-contract-and-consistency-audit.md` | later audit surface | receives carry-forward visibility only |
| `PR-0403` execution artifacts | active replay surface | must record the no-publication handoff in this run |

## Mainline Publication Check

This run must not:

1. create a governance ADR or ruling for `DI-21`;
2. add a topic-map row for the CI policy;
3. update current CI-governance docs as if the detector and output contract were already landed.

## Replay Consequence

`DOC-029` is a no-publication governance-policy replay. Its required outputs are:

1. explicit accepted-but-unlanded bundles in `dn-ledger-classification.md`;
2. active carry-forward items in `open-items.md`;
3. a downstream workflow handoff document for `PR-0407`;
4. explicit downstream consumption in the `PR-0407` spec.

## References

- [`02-historical-semantic-freeze.md`](02-historical-semantic-freeze.md)
- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../../../../../../tools/ci/architecture_check.dart`](../../../../../../../tools/ci/architecture_check.dart)
- [`../../../../../../architecture/engineering-standards.md`](../../../../../../architecture/engineering-standards.md)
