# DOC-010 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze `DOC-010 / DI-2` as a historical design source for the layout-tree decision line.

This stage must not:

1. import later `DI-3`, `DI-6`, or `DI-7` detail into the frozen meaning of `DI-2`;
2. treat current implementation rollout as if it were part of the original DI-2 source text;
3. collapse layout-tree structure into the broader shell-ownership line before classification.

## Trigger and Inputs

- [`../../../PR-0401/surveys/DOC-010-survey.md`](../../../PR-0401/surveys/DOC-010-survey.md)
- `PR-0401` DN baseline `DN-177` through `DN-182`
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md`](../../../../../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md)

## Frozen Historical Meaning

1. `DI-2` exists because the earlier flat layout model could not support recursive nested pane layout cleanly.
2. `D5` chooses an immutable recursive binary tree with sealed node types and whole-tree rebuild semantics.
3. `DI-2` fixes the node shape and the `GroupLayout` wrapper API as part of the same structural contract.
4. `D6` chooses top-down `resolve` as the data-layer authority for split, resize, and validation behavior.
5. The invariant set and the `EditorGroupModel ↔ Leaf` mapping are part of the same layout-tree line, not optional commentary.

## Freeze Result

For replay purposes, `DOC-010` is treated as one resolved design-source document with one stable why-question around layout-tree structure and resolve. Later docs may append persistence, dependency, or SLA evidence, but they do not change the frozen semantic meaning established here.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
- [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)
