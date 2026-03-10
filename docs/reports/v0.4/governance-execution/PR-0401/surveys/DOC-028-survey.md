# DOC-028 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`
- Title: `DI-20: 治理执行计划 — ADR 历史重演、主题覆盖与激活顺序`
- Doc Class: Governance decision discussion
- Corpus Role: Governance execution source

## Structure Snapshot

- The document is Q-driven at the top level, but several `Q*` ruling blocks contain lower-level `T* 当前裁决补充` clauses that are the real minimum extraction anchors.
- `Q1-Q5` provide the main governance execution contract; the later `主题覆盖矩阵` and `Theme Delta Contract` sections add schema and handoff structure.
- Survey stage should not collapse `T4`, `T5/T6`, and `T8` supplements into their parent `Q*` headings because they answer different governance questions.

## Candidate DN Anchors

### Framing anchors

- `## 背景`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`

### Q-level ruling anchors

- `## 待裁决问题 / ### Q1. 治理执行的最小单位是什么？ / #### Q1 裁决：以“治理主题（governance themes）”作为执行单位`
- `## 待裁决问题 / ### Q2. PR 应如何声明主题覆盖责任？ / #### Q2 裁决：每个 PR 必须携带 Theme Delta Contract`
- `## 待裁决问题 / ### Q3. PR 依赖图与提交顺序如何安排？ / #### Q3 裁决：6 PR 线性执行，先重演、再审计、后激活、最后沉淀`
- `## 待裁决问题 / ### Q4. 如何定义治理收口标准？ / #### Q4 裁决：以 Theme Coverage Closure 为唯一收口门`
- `## 待裁决问题 / ### Q5. 何时才能修改 release lifecycle template？ / #### Q5 裁决：template 回填必须后置到治理激活完成之后`

### Clause-level supplement anchors

- `Q1 / T1 当前裁决补充`
- `Q1 / T2 当前裁决补充`
- `Q1 / T3 当前裁决补充`
- `Q1 / T4 前置原则补充`
- `Q1 / T4 当前裁决补充：decision line extraction rules`
- `Q1 / T4 主题地图最小字段模型（建议表头）`
- `Q1 / T5/T6 前置治理约束：执行降级防护原则`
- `Q1 / T5/T6 执行化补充：anti-downgrade gate`
- `Q1 / T5 当前裁决补充：Theme Delta Contract`
- `Q1 / T6 当前裁决补充：Consistency, Backlink, and Traceability Gates`
- `Q1 / T7 当前裁决补充：Per-PR Entry / Exit Gates`
- `Q1 / T8 当前裁决补充：Template / Playbook / Lifecycle Backfill Boundary`
- `Q5 当前裁决补充：DI-20 保留为执行报告，模板抽离纳入 PR 规划`
- `Q5 当前裁决补充：模板抽离计划`
- `Q5 当前裁决补充：governance-playbook 的边界与最小骨架`

### Schema / handoff anchors

- `## 主题覆盖矩阵（初版）`
- `## Per-PR 最低模板 / ## Theme Delta Contract`
- `## Per-PR 最低模板 / ### Theme Delta Rows`
- `## 风险与缓解`

## Notes

- DI-20 is current-effective for governance execution and directly governs PR-0401 design.
- The existing DN seed only captured part of the `T4` block; the survey now records the broader clause surface so later extraction can proceed without inventing new anchors.
- `Q1` is especially dense: it should be treated as a container for multiple clause-level decision nodes, not a single monolithic ruling.
