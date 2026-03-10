# DOC-026 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md`
- Title: `DI-18: 执行方案 — PR 拆分、迁移顺序与测试策略`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- The document is a resolved execution-plan source, not a current-effective governance carrier.
- The parent `Q1-Q5` prompts matter because they capture migration tradeoffs, but the real executable contract sits in lower anchors such as `依赖关系推导`, `最终序列`, `Expand-Contract 迁移`, `A+ 严格执行规则`, and the numbered test and cleanup blocks.
- `Q1` and `Q2` contain the core migration-order and contract-cutover rules; `Q4` turns those into explicit test gates; `Q5` links execution governance forward into DI-21.
- `附录 A` is a distinct executable verification anchor and should not be dropped as “just appendix”.

## Candidate DN Anchors

- `## 背景`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`
- `## 待裁决问题（Q1-Q5） / ### Q1. PR 依赖图与提交顺序？`
- `## 待裁决问题（Q1-Q5） / #### Q1 裁决：Phase 0 治理 + 6 PR 重构，线性执行顺序`
- `## 待裁决问题（Q1-Q5） / #### Q1 裁决：Phase 0 治理 + 6 PR 重构，线性执行顺序 / **依赖关系推导**`
- `## 待裁决问题（Q1-Q5） / #### Q1 裁决：Phase 0 治理 + 6 PR 重构，线性执行顺序 / **依赖图**`
- `## 待裁决问题（Q1-Q5） / #### Q1 裁决：Phase 0 治理 + 6 PR 重构，线性执行顺序 / **最终序列**`
- `## 待裁决问题（Q1-Q5） / #### Q1 裁决：Phase 0 治理 + 6 PR 重构，线性执行顺序 / **对草案问题的回答**`
- `## 待裁决问题（Q1-Q5） / #### Q1 裁决：Phase 0 治理 + 6 PR 重构，线性执行顺序 / **草案 PR 序列与裁决序列的差异**`
- `## 待裁决问题（Q1-Q5） / ### Q2. 增量迁移 vs 一次性切换？`
- `## 待裁决问题（Q1-Q5） / #### Q2 裁决：A+（增量迁移 + 严格死代码清理）`
- `## 待裁决问题（Q1-Q5） / #### Q2 裁决：A+（增量迁移 + 严格死代码清理） / **核心机制：Expand-Contract 迁移**`
- `## 待裁决问题（Q1-Q5） / #### Q2 裁决：A+（增量迁移 + 严格死代码清理） / **A+ 严格执行规则**`
- `## 待裁决问题（Q1-Q5） / #### Q2 裁决：A+（增量迁移 + 严格死代码清理） / **各 PR 的迁移-清理对照**`
- `## 待裁决问题（Q1-Q5） / ### Q3. FFI Breaking Change 协调？`
- `## 待裁决问题（Q1-Q5） / #### Q3 裁决：技术文档跟随变更 PR + 决策线 ADR 交由 PR-GOV 序列`
- `## 待裁决问题（Q1-Q5） / #### Q3 裁决：技术文档跟随变更 PR + 决策线 ADR 交由 PR-GOV 序列 / **Q3.3：API 文档更新分配**`
- `## 待裁决问题（Q1-Q5） / #### Q3 裁决：技术文档跟随变更 PR + 决策线 ADR 交由 PR-GOV 序列 / **Q3.3 附：决策线 ADR 归属**`
- `## 待裁决问题（Q1-Q5） / ### Q4. 测试策略？`
- `## 待裁决问题（Q1-Q5） / #### Q4 裁决：Per-PR 测试责任制 + 清理验证`
- `## 待裁决问题（Q1-Q5） / #### Q4 裁决：Per-PR 测试责任制 + 清理验证 / 1. Migration 测试（PR-1）`
- `## 待裁决问题（Q1-Q5） / #### Q4 裁决：Per-PR 测试责任制 + 清理验证 / 2. Service 测试（PR-2、PR-3）`
- `## 待裁决问题（Q1-Q5） / #### Q4 裁决：Per-PR 测试责任制 + 清理验证 / 3. FFI 测试（PR-4）`
- `## 待裁决问题（Q1-Q5） / #### Q4 裁决：Per-PR 测试责任制 + 清理验证 / 4. Flutter 测试（PR-5、PR-6）`
- `## 待裁决问题（Q1-Q5） / #### Q4 裁决：Per-PR 测试责任制 + 清理验证 / 5. 清理验证 gate`
- `## 待裁决问题（Q1-Q5） / #### Q4 裁决：Per-PR 测试责任制 + 清理验证 / **设计决策摘要**`
- `## 待裁决问题（Q1-Q5） / ### Q5. 代码文件搬迁策略？`
- `## 待裁决问题（Q1-Q5） / #### Q5 裁决：无搬迁 + CI 强制化提取至 DI-21`
- `## 待裁决问题（Q1-Q5） / #### Q5 裁决：无搬迁 + CI 强制化提取至 DI-21 / **Q5.1 结论：v0.4 不需要文件搬迁**`
- `## 待裁决问题（Q1-Q5） / #### Q5 裁决：无搬迁 + CI 强制化提取至 DI-21 / **Q5.2 提取触发条件的 CI 强制化 -> DI-21**`
- `## 附录 A：旧 FFI 移除清单（PR-6 contract 阶段）`

## Notes

- `DI-18` is an execution-plan source, so later extraction should keep the migration-order contract separate from the cleanup and verification contract.
- `Q1/Q2/Q4` contain several stable execution anchors that are not just narrative explanation and should be treated as first-pass DN candidates.
- The appendix is operationally important because it records the concrete removal and zero-match verification surface.
