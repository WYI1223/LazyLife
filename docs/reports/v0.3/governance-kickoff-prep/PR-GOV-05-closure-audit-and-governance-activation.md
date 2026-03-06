# PR-GOV-05: 收口审计与治理激活草稿

- Proposed title: `docs(governance): PR-GOV-05 prepare closure audit package and governance activation draft`
- Status: Draft

## Goal

在 `PR-GOV-04` 建立回链与检查规则之后，准备 repo-wide 一致性审计的收口包，
输出 `Closure Audit Output` 草稿，并以 prep 层治理激活草稿明确 append-only 的生效点，
供 future kickoff mainline 采用。

前置条件：`PR-GOV-04 exit gate` 已满足。

## Theme Delta Contract

### Contract Summary

| 字段 | 内容 |
|------|------|
| Covered Themes | `T2`, `T6`, `T7` |
| Theme Operations | `T2=confirm`, `T6=closure_audit`, `T7=confirm` |
| Primary Theme Owner | `PR-GOV-05` |
| PR Executor | `TBD (during v0.4 kickoff)` |
| Secondary Coverage | 为 `PR-GOV-06` 的模板/playbook/lifecycle 回填提供已验证执行证据，并为 `T8` 提供激活后回填的合法边界与审计输入 |
| Out of Scope | 稳定模板定稿、lifecycle template 回填、创建正式 `docs/architecture/adr/ADR-XXXX-governance-activation.md` |
| Must Preserve | 治理激活不得早于 audit 闭合；append-only 生效点必须显式、单点、可回链 |
| Allowed Simplifications | 允许 closure audit 记录已接受 debt / exception，但不得省略 |
| Escalation Required If Violated | 若 audit 暴露阻断级冲突，必须阻止治理激活 |
| Accepted Debt | 可接受非阻断级 debt，但必须记录 owner 与退出条件；`Native ADR template` 明确 deferred 到 post-activation follow-up，待至少一轮真实 Native ADR 工作流后再规划 |
| Output Docs | `Closure Audit Output` 草稿 + 治理激活草稿 |
| Verification | closure audit package 字段完整；激活 draft 明确 append-only 生效点与 post-activation boundary |
| Required Sign-off | `Theme Owner` + `governance owner` |

### Theme Delta Rows

| Theme ID | Theme Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------------|---------------|--------------|--------------|---------------|--------------|
| `T2` | `confirm` | authority matrix 与生效边界仍停留在 DI / draft 规则层 | 治理激活 draft 明确激活后 authority boundary 与 append-only 生效点 | `docs/reports/v0.3/governance-kickoff-prep/governance-activation-draft.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md` | `Ruling` 仍为规范源，治理激活不得改写这一点 | 激活 draft 明确 post-activation boundary |
| `T6` | `closure_audit` | 一致性检查模型已定义，但尚未执行 repo-wide audit | `Closure Audit Output` 已形成并对阻断/debt/exception/follow-up 分级 | `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md` | 阻断级问题不得被降级为普通 debt | 审计输出包含结果分级与结论 |
| `T7` | `confirm` | 顺序与 gate 仍停留在规划层 | 治理激活 draft 在 audit 之后形成，顺序闭环得到真实执行验证 | `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-activation-draft.md` | 激活不得早于审计闭合 | 审计与激活文档时间/依赖关系可回链验证 |

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` §13-§15 | 一致性、可追溯性、治理激活边界 |
| DI | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | `PR-GOV-05` 主题覆盖、exit gate、T8 约束 |
| PR | `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-04-contracts-backlinks-and-checks.md` | audit 与回链规则输入 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-check-model.md` | audit 执行标准 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | closure / activation 模板草案 |

---

## Scope

In scope:

- 准备 repo-wide 一致性审计的收口包
- 产出 `Closure Audit Output` 草稿
- 产出治理激活草稿
- 验证 closure / activation 模板草案是否足够承载闭环

Out of scope:

- lifecycle template 回填
- 稳定模板定稿
- `playbook` 定稿
- 创建正式 `docs/architecture/adr/ADR-XXXX-governance-activation.md`

---

## Design

### 1. Output Artifact Set

1. `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md`
2. `docs/reports/v0.3/governance-kickoff-prep/governance-activation-draft.md`

### 2. Audit Result Classes

closure audit 至少必须区分：

- `blocking`
- `non_blocking_debt`
- `accepted_exception`
- `follow_up_required`

### 3. Activation Rule

治理激活草稿必须显式说明：

- append-only 从何时生效
- 对哪些 ADR 类型生效
- 历史补录 ADR 进入何种冻结状态
- 后续治理演进应回到何种裁决载体

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | A | 执行 repo-wide 一致性审计并形成问题清单 | `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md` | 新增 ~160 行 | — |
| T2 | A | 将阻断级问题、debt、例外、follow-up 分类记录 | `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md` | 编辑 ~80 行 | T1 |
| T3 | B | 编写治理激活草稿并声明 append-only 生效点 | `docs/reports/v0.3/governance-kickoff-prep/governance-activation-draft.md` | 新增 ~120 行 | T1 |
| T4 | C | 验证 closure / activation 模板草案，记录需要带入 `PR-GOV-06` 的修正 | `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | 编辑 ~40 行 | T1-T3 |

---

## Planned File Changes

- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md`
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-activation-draft.md`
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md`
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md`

---

## Verification

```powershell
rg -n "blocking|non_blocking_debt|accepted_exception|follow_up_required" docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md

rg -n "append-only|Retrospective Reconstruction ADR|Native ADR|effective from|activation" docs/reports/v0.3/governance-kickoff-prep/governance-activation-draft.md
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 未完成 audit 就宣布激活 | HIGH | 将 audit 作为 activation 硬前置 |
| 阻断级问题被当作 accepted debt 吞掉 | HIGH | closure audit 强制问题分级 |
| 激活草稿写不清 append-only 边界 | HIGH | 强制写入 ADR 类型与生效点 |

---

## Kickoff Prep Readiness Review

### Readiness Checklist

- [x] Canonical inputs 已显式列出
- [x] Scope / Out of Scope 已冻结到 spec 级
- [x] Planned File Changes 已冻结到文件级
- [x] Theme Delta Contract 与 Theme Delta Rows 已完整存在
- [x] deferred / debt 已显式记录（含 `Native ADR template`）
- [x] 治理激活目标文件名已收敛为 prep 层固定文件名 `governance-activation-draft.md`
- [x] `Closure Audit Output` 与治理激活 draft 已创建
- [x] Verification 已可对真实目标文件执行
- [ ] `PR-GOV-04 exit gate` 已满足
- [x] Required sign-off 已明确 deferred 到 kickoff

### Current Verdict

| Field | Value |
|------|-------|
| Verdict | `Blocked` |
| Blocking Items | `PR-GOV-04 exit gate` 尚未满足；当前仅完成 prep 层 closure/activation draft 壳 |
| Dependency Gate | `PR-GOV-04 exit gate` |
| Last Reviewed | `2026-03-06` |
| Reviewer | `Codex` |
| Notes | `Native ADR template` 已显式 deferred，不构成本轮 ready blocker，但应保留在 post-activation follow-up 中 |

---

## Acceptance Criteria

- [ ] repo-wide 一致性审计已执行并形成 `Closure Audit Output`
- [ ] 阻断级问题、debt、例外、follow-up 已分级记录
- [ ] 治理激活 draft 已创建并明确 append-only 生效点
- [ ] 本 PR spec 的 kickoff 筹备结论已同步更新
