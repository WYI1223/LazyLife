# PR-GOV-04: Theme Delta Contract、回链与一致性检查

- Proposed title: `docs(governance): PR-GOV-04 finalize theme delta contract, backlink rules, and governance checks`
- Status: Draft

## Goal

在 `PR-GOV-03` 产出真实 ADR draft 对象后，落定 `Theme Delta Contract` 模型、最低回链规则、
一致性检查模型，以及执行模板草案，使治理执行具备可检查、可追溯、可收口的结构约束。

前置条件：`PR-GOV-03 exit gate` 已满足。

## Theme Delta Contract

### Contract Summary

| 字段 | 内容 |
|------|------|
| Covered Themes | `T5`, `T6` |
| Theme Operations | `T5=confirm+template_sync`, `T6=confirm+backlink_sync` |
| Primary Theme Owner | `PR-GOV-04` |
| PR Executor | `TBD (during v0.4 kickoff)` |
| Secondary Coverage | 为 `PR-GOV-05` 审计提供检查骨架，并为 `T8` 的 template/playbook/lifecycle 回填提供执行模板与回链规则输入 |
| Out of Scope | repo-wide audit 实际执行、治理激活、lifecycle 回填 |
| Must Preserve | 结构检查、图检查、政策检查、语义检查四层分工；语义检查不得假装完全自动化 |
| Allowed Simplifications | 允许检查脚本 / 模板仍处草案态，但最低规则必须可运行 |
| Escalation Required If Violated | 若回链规则与 prep 主题地图 / ADR draft 实际结构不兼容，必须回到主题裁决 |
| Accepted Debt | 允许部分自动化检查仍由人工替代，但必须记录替代方案 |
| Output Docs | Theme Delta Contract 草案、回链规则、检查规则、执行模板草案 |
| Verification | 最低回链规则存在、检查分类明确、模板草案可承载执行 |
| Required Sign-off | `Theme Owner` + `governance owner` |

### Theme Delta Rows

| Theme ID | Theme Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------------|---------------|--------------|--------------|---------------|--------------|
| `T5` | `confirm`, `template_sync` | PR 级文档责任与 Theme Delta Contract 仅在 `DI-20` 中定义 | Theme Delta Contract 模型与执行模板草案已形成 | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-delta-contract-model.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | PR 责任必须显式、可检查，且模板仍处 draft 态 | Contract 模型包含 required fields，模板草案可回链 `T5` |
| `T6` | `confirm`, `backlink_sync` | 回链与一致性检查仅在 `DI-20` 中定义 | 最低回链规则与四层检查模型已形成可执行文档 | `docs/reports/v0.3/governance-kickoff-prep/governance-backlink-rules.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-check-model.md` | `Semantic Review` 不得被伪装成完全自动化 | 回链规则存在，且检查模型显式区分 Structural/Graph/Policy/Semantic |

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` §T5/§T6 | Theme Delta Contract、检查模型、模板抽离规划 |
| PR | `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-03-first-batch-retrospective-adrs.md` | 已存在 ADR draft / prep topic-map 映射对象 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` | 回链与图检查的主要对象 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-template-extraction-backlog.md` | 执行模板草案规划 |

---

## Scope

In scope:

- 定稿 `Theme Delta Contract` 字段与行级结构
- 制定最低回链规则
- 制定结构 / 图 / 政策 / 语义检查模型
- 起草 `Theme Map` / `Theme Delta Contract` / `Closure Audit` 等执行模板草案

Out of scope:

- repo-wide audit 实际执行
- 治理激活
- 稳定模板最终定稿

---

## Design

### 1. Output Artifact Set

1. `docs/reports/v0.3/governance-kickoff-prep/governance-theme-delta-contract-model.md`
2. `docs/reports/v0.3/governance-kickoff-prep/governance-backlink-rules.md`
3. `docs/reports/v0.3/governance-kickoff-prep/governance-check-model.md`
4. `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md`

### 2. Check Model Boundary

必须显式区分：

- `Structural Checks`
- `Graph Checks`
- `Policy Checks`
- `Semantic Review`

其中仅前三类可部分自动化，`Semantic Review` 仍需 owner 参与。

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | A | 落定 Theme Delta Contract 模型 | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-delta-contract-model.md` | 新增 ~120 行 | — |
| T2 | A | 落定最低回链规则 | `docs/reports/v0.3/governance-kickoff-prep/governance-backlink-rules.md` | 新增 ~100 行 | — |
| T3 | B | 落定四层检查模型 | `docs/reports/v0.3/governance-kickoff-prep/governance-check-model.md` | 新增 ~120 行 | — |
| T4 | C | 起草执行模板草案（theme map / theme delta / closure audit） | `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | 新增 ~140 行 | T1-T3 |
| T5 | C | 同步 `DI-20` 与目录索引中的 `PR-GOV-04` 产出说明 | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`, `docs/reports/v0.3/governance-kickoff-prep/README.md` | 编辑 ~20 行 | T1-T4 |

---

## Planned File Changes

- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-theme-delta-contract-model.md`
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-backlink-rules.md`
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-check-model.md`
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md`
- `[edit]` `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/README.md`

---

## Verification

```powershell
rg -n "Covered Themes|Theme Operations|Primary Theme Owner|PR Executor|Must Preserve|Allowed Simplifications|Accepted Debt|Required Sign-off" docs/reports/v0.3/governance-kickoff-prep/governance-theme-delta-contract-model.md

rg -n "Structural Checks|Graph Checks|Policy Checks|Semantic Review" docs/reports/v0.3/governance-kickoff-prep/governance-check-model.md

rg -n "backlink|topic-map|Published ADR|Primary Upstream" docs/reports/v0.3/governance-kickoff-prep/governance-backlink-rules.md
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 假装所有检查都能自动化 | HIGH | 在模型中保留 `Semantic Review` 人工 gate |
| 回链规则与真实 ADR draft / prep topic-map 结构脱节 | MEDIUM | 以 `PR-GOV-03` 已产出对象为输入 |
| 模板草案过早定稿 | MEDIUM | 本 PR 只产出 draft，不进入 `docs/development/` |

---

## Kickoff Prep Readiness Review

### Readiness Checklist

- [x] Canonical inputs 已显式列出
- [x] Scope / Out of Scope 已冻结到 spec 级
- [x] Planned File Changes 已冻结到文件级
- [x] Theme Delta Contract 与 Theme Delta Rows 已完整存在
- [x] 计划输出文档已创建并具备最低可读内容
- [x] Verification 已可对真实目标文件执行
- [ ] `PR-GOV-03 exit gate` 已满足
- [x] Required sign-off 已明确 deferred 到 kickoff

### Current Verdict

| Field | Value |
|------|-------|
| Verdict | `Blocked` |
| Blocking Items | `PR-GOV-03 exit gate` 尚未满足；当前仅完成 prep 层规则与模板草案落点 |
| Dependency Gate | `PR-GOV-03 exit gate` |
| Last Reviewed | `2026-03-06` |
| Reviewer | `Codex` |
| Notes | `PR-GOV-04` 是后续 audit 与 template backfill 的结构前提，ready 前必须先有真实对象与规则草案落地 |

---

## Acceptance Criteria

- [ ] Theme Delta Contract 模型已形成独立执行文档
- [ ] 回链规则已形成独立执行文档
- [ ] 四层检查模型已形成独立执行文档
- [ ] 执行模板草案已形成独立执行文档
- [ ] 本 PR spec 的 kickoff 筹备结论已同步更新
