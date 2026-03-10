# DOC-003 Survey

- Source: `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md`
- Title: `08c — 解决方案`
- Doc Class: Solution proposal
- Corpus Role: Execution source

## Structure Snapshot

- The document is already split at the right operational granularity: `3.1.x` for structural proposals, `3.2.x` for CI guardrails, and `3.3.x` for documentation work.
- Each numbered subsection is a distinct proposal unit and should be preserved separately at survey stage.
- `3.3` is lighter-weight than `3.1/3.2`, but its document-action lists are still valid extraction candidates because they later drive doc-governance work.

## Candidate DN Anchors

- `## 3.1 结构性解耦方案 / ### 3.1.1 notes↔workspace 解耦（S2 Phase 1）`
- `## 3.1 结构性解耦方案 / ### 3.1.2 notes↔tags 循环依赖打破`
- `## 3.1 结构性解耦方案 / ### 3.1.3 Coordinator 瘦身`
- `## 3.1 结构性解耦方案 / ### 3.1.4 Reminders 迁移（S7）`
- `## 3.1 结构性解耦方案 / ### 3.1.5 低优先级解耦`
- `## 3.2 CI 防线方案 / ### 3.2.1 Rule E 自动化检查`
- `## 3.2 CI 防线方案 / ### 3.2.2 文件大小监控`
- `## 3.2 CI 防线方案 / ### 3.2.3 结构层次检查`
- `## 3.2 CI 防线方案 / ### 3.2.4 S1-S8 裁决的未来 CI 规则（v0.3 范围）`
- `## 3.3 文档同步方案 / ### 需要行动的文档（7 项）`
- `## 3.3 文档同步方案 / ### 已验证无需行动的文档（3 项）`

## Notes

- This document bridges findings and executable changes, but remains proposal-stage rather than current-effective.
- Survey stage should keep `3.1.x`, `3.2.x`, and `3.3.x` separate; they answer different kinds of “what should happen next” questions.
