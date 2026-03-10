# DOC-010 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-2-layout-tree-structure.md`
- Title: `DI-2: 递归布局树节点结构 + 约束传播`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- Organized as a layered model: methodology, visual state, interaction, constraints, operation set, data structure, invariants, and model mapping.
- The named minimum decision anchors are `D5`, `D6`, the invariants section, and the explicit model-mapping sections around node shape and leaf/group correspondence.
- This document is architectural and model-heavy rather than execution-plan-heavy.

## Candidate DN Anchors

- `### D5 裁决：Sealed class + 不可变 rebuild`
- `## 第五层：数据结构 / ### 节点定义`
- `## 第五层：数据结构 / ### 封装层`
- `### D6 裁决：自顶向下 resolve`
- `## 树不变量（Invariants）`
- `## EditorGroupModel ↔ Leaf 对应关系`

## Notes

- DI-2 is a foundational structural-model source for later editor/layout ADR replay.
- Invariants and node-shape definitions should remain distinct at extraction time even if later ADR classification groups them together.
