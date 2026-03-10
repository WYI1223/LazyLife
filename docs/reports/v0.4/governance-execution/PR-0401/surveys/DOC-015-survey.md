# DOC-015 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-7-gates-perf-testing.md`
- Title: `DI-7: Gate 验证标准 + 性能基线 + 测试策略`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- The document resolves four execution-facing question lines `Q1-Q4`.
- `Q1` and `Q2` are not single-block rulings: each expands into gate/SLA/verification subclauses that are the real minimum extraction anchors.
- The final summary table is derivative and should not replace the clause-level anchors that appear earlier in the document.

## Candidate DN Anchors

- `## Q1 裁决：Gate 验证标准精确化 / ### Gate A — 语义与契约（PR-RB-05 后）`
- `## Q1 裁决：Gate 验证标准精确化 / ### Gate B — 编辑器基础设施（PR-RB-09 后）`
- `## Q1 裁决：Gate 验证标准精确化 / ### Release Gate（v0.3）`
- `## Q1 裁决：Gate 验证标准精确化 / ### 审计报告 §5.1 三个模糊条件的精确化对照`
- `## Q2 裁决：性能基准定义 / ### 已有 SLA（来自 DI-4）`
- `## Q2 裁决：性能基准定义 / ### 审计报告 §5.2 五个缺失维度的补充`
- `## Q2 裁决：性能基准定义 / ### 性能 SLA 总表（v0.3 标准）`
- `## Q2 裁决：性能基准定义 / ### 两层验证方法 / #### 层 1：Service 层 — Stopwatch 回归守卫（CI 自动执行）`
- `## Q2 裁决：性能基准定义 / ### 两层验证方法 / #### 层 2：UI 帧率 — Flutter integration_test（Gate B 本地手动触发）`
- `## Q2 裁决：性能基准定义 / ### 裁决：不引入自动化性能 CI`
- `## Q3 裁决：测试方法论 / ### 核心结论：不需要自定义 test harness`
- `## Q3 裁决：测试方法论 / ### 每个 PR 的测试期望`
- `## Q4 裁决：现有测试迁移策略 / ### 影响分析`
- `## Q4 裁决：现有测试迁移策略 / ### 迁移原则`

## Notes

- This document is mostly execution contract, not product/domain semantics; later extraction should preserve the gate/SLA/test-method split instead of merging everything into a generic “testing strategy” node.
- `Q2` contains both strict SLA targets and looser CI regression-guard thresholds; those are related but not identical decision statements.
