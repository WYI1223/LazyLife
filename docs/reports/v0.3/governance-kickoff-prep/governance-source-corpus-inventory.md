# Governance Source Corpus Inventory

> `PR-GOV-01` 产物。本文只负责建立按时间顺序排列的 `source corpus` 基线，
> 不直接充当 `theme map`，也不预先锁定首批 ADR 主题。

---

## Inventory Rules

1. 本清单按当前仓库内可直接读取的一级来源顺序排列，而不是按主题排列。
2. `Candidate Themes` 只是 first-pass 抽取结果；正式主题确认以后续 `theme map` 为准。
3. 若某条决策线的关键来源尚未纳入本清单，必须显式记录为 `scope gap`，不能静默忽略。
4. `Normative Source` 在本轮基线中只直接覆盖到 `E1`；其余语义主题的当前规范锚点，
   需在 `PR-GOV-02/03` 随主题冻结继续补齐。

---

## Time-Ordered Inventory

| Source ID | Time Position | Source Type | File | Explicit Anchors | Why Included | Candidate Themes | Notes |
|------|------|------|------|------|------|------|------|
| `C01` | `2026-02-26 / 08a` | Trigger Source / Audit | `docs/reports/v0.2.5/frontend-review/08a-audit-findings.md` | `D8`, `D10`, `S1`, `S3`, `S4`, `S7`, `S8` | 提供历史重演的事实触发点：创建入口差异、reminders 位置、S1-S8 语义模糊清单 | `TH-001`, `TH-002`, `TH-003`, `TH-004`, `TH-005` | first-pass 主题抽取的起点；不负责最终裁决 |
| `C02` | `2026-02-26 / 08b` | Decision Source / Semantic Decisions | `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md` | `## S1`, `## S3`, `## S4`, `## S7`, `## S8` | 提供 S1/S3/S4/S7/S8 的正式语义裁决入口 | `TH-001`, `TH-002`, `TH-003`, `TH-004`, `TH-005` | 当前 first-pass 主题的主要上游来源 |
| `C03` | `2026-02-26 / 08c` | Execution Source / Solution Proposals | `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md` | `08d` 将其作为前置方案来源 | 提供 08b 裁决如何转成结构方案与执行 lanes 的中间层 | `TH-001`, `TH-002`, `TH-003`, `TH-004`, `TH-005` | 当前 PR 只将其作为方案来源记录，不在此文内重写 08c 细节 |
| `C04` | `2026-02-26 / 08d` | Execution / Replanning Source | `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md` | `S1-S8 裁决落地映射`, `PR-0256`, `PR-0253`, `v0.3 待规划` | 明确 08a-08c 如何被重新编排成可执行 PR 与 v0.3 handoff | `TH-001`, `TH-002`, `TH-003`, `TH-004`, `TH-005` | first-pass 主题的执行与 handoff 证据来源 |
| `C05` | `2026-02-26 / 09` | Closure Source / Acceptance | `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md` | `§4.1`, `§4.2`, `§7.3`, `S1/S3/S4/S7/S8` | 提供 08 系列的闭合结果、v0.3 handoff 状态与文档同步状态 | `TH-001`, `TH-002`, `TH-003`, `TH-004`, `TH-005` | 用于判定哪些主题已形成稳定 `Current State` |
| `C06` | `2026-03-01 / PR-RB-00` | Governance Source / PR Spec | `docs/releases/v0.3/prs/PR-RB-00-doc-fixes.md` | `B2: ADR 废弃，职责并入 Ruling 体系`, `T7`, `T20`, `T21` | 提供 v0.3 文档治理动作事实：ADR 废弃、E1 迁移、lifecycle template 创建 | `TH-006`, `TH-007` | 是治理载体演进主题的 first seen source |
| `C07` | `2026-03-01 / E1` | Normative Source | `docs/architecture/rulings-legacy/E1-release-and-versioning.md` | `引入版本`, `迁移来源`, `修订历史` | 提供发布与版本策略的当前规范锚点，并记录 ADR-0001 迁移来源 | `TH-006`, `TH-007` | 当前 corpus 中唯一直接纳入的规范源 |
| `C08` | `2026-03-01 / v0.3 closure` | Closure Source / Release Evidence | `docs/releases/v0.3/v0.3-release-evidence.md` | `§6.1 Rulings`, `15 items explicitly deferred`, `v0.3→v0.4 boundary is clean` | 证明 v0.3 已收口，以及 DI-12/14/15/16/17/18 属于 v0.4 planning boundary | `TH-001`, `TH-006`, `TH-007` | 为 first-pass 主题提供 post-v0.3 closure 证据 |
| `C09` | `2026-03-06 / DI-19` | Governance Decision Source | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` | `§10-§15`, `Retrospective Reconstruction ADR`, `Native ADR` | 提供当前有效的 ADR 治理修订规则、历史补录边界与激活边界 | `TH-007` | 当前治理修订的直接规则来源 |
| `C10` | `2026-03-06 / DI-20` | Governance Kickoff-Prep Source | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | `T1-T8`, `PR-GOV-01~06`, `template extraction plan` | 提供本轮治理 kickoff 筹备顺序、主题覆盖矩阵与模板抽离规划 | `TH-007` | 当前 PR-GOV 序列的筹备源 |

---

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| `Trigger Source` | `C01`, `C06` | `present` | `C01` 触发语义重演，`C06` 触发治理载体重演 |
| `Decision Source` | `C02`, `C09`, `C10` | `present` | 语义裁决与治理裁决均已纳入 |
| `Execution / Closure Source` | `C03`, `C04`, `C05`, `C08` | `present` | 已覆盖方案、replanning、acceptance、release evidence |
| `Normative Source` | `C07` | `partial` | 当前仅直接纳入 `E1`；S1/S3/S4/S7/S8 的规范锚点需在主题冻结后继续补齐 |
| `Superseded / Redirected Source` | `C06`, `C07`, `C09` | `present` | 已能追踪 `ADR-0001 -> E1` 与 `ADR 废弃 -> replay/activation` |

---

## First-Pass Theme Extraction Scope

当前 `PR-GOV-01` 只对以下两类主题做 first-pass 抽取：

1. `08a-09` 已形成完整 audit -> decision -> execution -> acceptance 链的主题；
2. `PR-RB-00 / E1 / DI-19 / DI-20` 已形成治理载体演进链的主题。

以下内容暂不纳入本次 first-pass 主题地图：

1. `DI-12 / DI-14 / DI-15 / DI-16 / DI-17 / DI-18` 的 workspace topology 演进；
2. 任何未出现在 `PR-GOV-01` canonical inputs 中的新增来源。

这不是对后续 ADR 主题的否定，而是当前 `PR-GOV-01` 的显式 scope boundary。
