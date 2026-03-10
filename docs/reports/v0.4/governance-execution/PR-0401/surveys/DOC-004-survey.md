# DOC-004 Survey

- Source: `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md`
- Title: `08d — PR 再规划`
- Doc Class: PR replanning report
- Corpus Role: Execution source

## Structure Snapshot

- The document is split into stable PR-planning units: structure, order, and per-PR landing sections.
- `4.4-4.10` are the actual minimum planning anchors; command blocks inside them are verification evidence, not separate decision nodes by default.
- `4.2` and `4.3` set the global planning frame and should stay distinct from the per-PR sections.

## Candidate DN Anchors

- `## 4.2 新 PR 结构`
- `## 4.2 / ### S1-S8 裁决落地映射`
- `## 4.3 执行顺序`
- `## 4.4 PR-0256 — 语义裁决与文档对齐`
- `## 4.5 PR-0257 — NoteTabManager Pane-Aware 升级`
- `## 4.6 PR-0258 — notes↔workspace 结构性解耦`
- `## 4.7 PR-0259 — Rule E 消减与 CI 防线`
- `## 4.8 PR-0253 更新 — v0.2.5 收尾与 v0.3 交接`
- `## 4.9 v0.3 就绪度检查清单`
- `## 4.10 v0.2.5 Release README 更新计划`

## Notes

- This is the main bridge from 08-series decisions into executable PR lanes.
- Verification grep blocks are supporting evidence, not first-class DN anchors by default.
- Survey stage should preserve each `4.x` PR block separately because later closure/release narratives may consume them independently.
