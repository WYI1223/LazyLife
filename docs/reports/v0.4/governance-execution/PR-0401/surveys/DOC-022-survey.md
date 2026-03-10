# DOC-022 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md`
- Title: `DI-14: Workspace Tree 提升为 Core 层一等公民`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- This is a conceptual-parent document with four layers:
  - governance note plus background and scope framing
  - local resolved anchors `Q0-Q2`
  - deeper stable subclauses inside `Q1` and `Q2`
  - explicit migration-out anchors `Q3-Q5` into DI-17
- `Q1` and `Q2` each contain lower-level analysis clauses that are more stable than the parent question heading alone.
- Later extraction should preserve the migration boundary instead of treating `Q3-Q5` as unresolved leftovers inside DI-14.

## Candidate DN Anchors

- `治理说明：本文件为概念母题（Conceptual Parent）`
- `## 背景`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`
- `## 待裁决问题（Q0-Q5） / ### Q0. Workspace tree 是否应提升为 Core 层一等公民？（RESOLVED）`
- `## 待裁决问题（Q0-Q5） / ### Q1. Core workspace tree service 应提供什么核心能力？（RESOLVED）`
- `## 待裁决问题（Q0-Q5） / #### 需求端推导`
- `## 待裁决问题（Q0-Q5） / ### Q1. ... / **裁决：Core 核心能力（从需求端收敛）**`
- `## 待裁决问题（Q0-Q5） / ### Q1. ... / **裁决：Feature 层自有职责（不属于 core）**`
- `## 待裁决问题（Q0-Q5） / ### Q2. 子树查询的接口设计？（RESOLVED）`
- `## 待裁决问题（Q0-Q5） / #### 现状 vs 目标`
- `## 待裁决问题（Q0-Q5） / #### 用户视角的两种操作模式`
- `## 待裁决问题（Q0-Q5） / #### 裁决`
- `## 待裁决问题（Q0-Q5） / ### Q2. ... / **辅助查询接口**`
- `## 待裁决问题（Q0-Q5） / ### Q2. ... / **接口完备性原则**`
- `## 待裁决问题（Q0-Q5） / ### Q2. ... / **收集模式需要新的 Rust Core FFI**`
- `## 待裁决问题（Q0-Q5） / ### Q3. 变更通知与缓存一致性？ -> 迁移至 DI-17 Q2`
- `## 待裁决问题（Q0-Q5） / ### Q4. 树 UI 组件的共享层级？ -> 迁移至 DI-17 Q3`
- `## 待裁决问题（Q0-Q5） / ### Q5. 系统节点解析归属？ -> 迁移至 DI-17 Q4`

## Notes

- `DI-14` should remain visible as the conceptual parent even though a large part of the downstream implementation discussion moved into DI-17.
- The earlier survey was under-specified because it skipped the conceptual-parent framing, the explicit scope boundary, and the stable non-heading decision blocks inside `Q1` and `Q2`.
- `Q0-Q2` and `Q3-Q5` serve different governance roles: local ruling vs. migration boundary.
