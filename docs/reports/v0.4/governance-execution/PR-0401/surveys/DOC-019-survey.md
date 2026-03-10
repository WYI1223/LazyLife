# DOC-019 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md`
- Title: `DI-11: AtomType -> ViewHint 枚举重命名影响分析`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- This document mixes three layers: the confirmed rename decision, the v0.4 `atom_create` contract draft, and pending semantic-harmonization follow-ups.
- The minimum survey anchors are the clause heads `A-H`, the `C` subclauses for request/semantic/response contract, the `E1-E4` implementation lanes, and the `H1-H4` pending-semantics subclauses.
- Later extraction must preserve the distinction between “已确认”, “草案”, and “待细化” rather than flattening them into a single rename decision.

## Candidate DN Anchors

- `## 现状补充（2026-03-01 讨论） / ### Notes 专用 API 入口约束（当前实现）`
- `## 现状补充（2026-03-01 讨论） / ### 用户心智模型暴露的问题`
- `## 现状补充（2026-03-01 讨论） / ### DI-11 范围判定`
- `## 讨论基线与已确认条件（2026-03-01） / ### 讨论基线`
- `## 讨论基线与已确认条件（2026-03-01） / ### 已确认条件`
- `## 讨论基线与已确认条件（2026-03-01） / ### 后续讨论清单（按顺序细化）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### A. 总体立场（已确认）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### B. v0.3 完成态下 note_create 与 entry_create_* 的关系定位`
- `## v0.4 规范入口裁决草案（Atom Create） / ### C. atom_create 规范契约（草案）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### 请求模型（建议）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### 语义规则（必须）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### 返回模型（建议统一）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### D. 场景映射（从 feature 入口到统一入口）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### E. monorepo 实施清单（v0.4） / ### E1. Rust Core`
- `## v0.4 规范入口裁决草案（Atom Create） / ### E. monorepo 实施清单（v0.4） / ### E2. FFI`
- `## v0.4 规范入口裁决草案（Atom Create） / ### E. monorepo 实施清单（v0.4） / ### E3. Flutter`
- `## v0.4 规范入口裁决草案（Atom Create） / ### E. monorepo 实施清单（v0.4） / ### E4. Tests + Docs`
- `## v0.4 规范入口裁决草案（Atom Create） / ### F. 迁移策略（建议）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### G. 待细化问题（下一轮讨论）`
- `## v0.4 规范入口裁决草案（Atom Create） / ### H. Pending 语义统一（2026-03-01 新增共识）`
- `## v0.4 规范入口裁决草案（Atom Create） / #### H1. Tasks Pending（对应当前 Tasks Inbox）`
- `## v0.4 规范入口裁决草案（Atom Create） / #### H2. Calendar Pending（对应当前待排期池）`
- `## v0.4 规范入口裁决草案（Atom Create） / #### H3. 与 Archive 的边界`
- `## v0.4 规范入口裁决草案（Atom Create） / #### H4. 对 atom_create 的影响`
- `## 影响面统计`
- `## 重命名策略 / ### 枚举重命名`
- `## 重命名策略 / ### 字段重命名`
- `## 重命名策略 / ### 函数重命名`
- `## 决策`
- `## 执行方式`

## Notes

- `DI-11` is not just a rename memo; it is also an upstream source for later creation-contract and pending-semantics governance lines.
- The final `## 决策` section should be read together with the earlier `重命名策略` and `执行方式` anchors, not as a replacement for them.
