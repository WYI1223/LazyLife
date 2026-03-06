# PR-GOV-06: 模板、playbook 与 lifecycle 回填

- Proposed title: `docs(governance): PR-GOV-06 finalize templates, playbook, and lifecycle backfill from validated execution`
- Status: Draft

## Goal

在治理激活完成之后，把本轮已验证的治理执行经验沉淀为稳定模板、`governance-playbook`
和 `release-lifecycle-template.md` 的回填内容；同时明确哪些内容仍不得模板化。

前置条件：治理激活已经完成，且 `Closure Audit Output` 未显示阻断级失败。

## Theme Delta Contract

### Contract Summary

| 字段 | 内容 |
|------|------|
| Covered Themes | `T5`, `T8` |
| Theme Operations | `T5=template_sync`, `T8=template_sync+confirm` |
| Primary Theme Owner | `PR-GOV-06` |
| PR Executor | `TBD` |
| Secondary Coverage | 将 `PR-GOV-01` ~ `PR-GOV-05` 的执行经验提炼为长期操作资产 |
| Out of Scope | 任何未验证规则的提前模板化；新增治理实验 |
| Must Preserve | `Ruling` 仍是规范源；`playbook` 不替代治理裁决；template 只沉淀已验证流程 |
| Allowed Simplifications | 若某模板对应规则尚未被完整验证，可继续保留在 plan/draft 态，不强制定稿 |
| Escalation Required If Violated | 若回填内容需要新增治理规则，必须先回到治理裁决文档 |
| Accepted Debt | 允许暂缓定稿个别模板，但必须记录原因与 follow-up |
| Output Docs | 稳定模板、`governance-playbook.md`、`release-lifecycle-template.md` 回填 |
| Verification | 回填内容全部可回链到已闭合执行经验 |
| Required Sign-off | `Theme Owner` + `governance owner` |

### Theme Delta Rows

| Theme ID | Theme Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------------|---------------|--------------|--------------|---------------|--------------|
| `T5` | `template_sync` | 执行模板仅存在于 `PR-GOV-04` 草案与 `DI-20` 规划中 | 已验证的执行模板被定稿到 `docs/development/report-templates/`，未验证项被显式保留在 plan/draft 态 | `docs/development/report-templates/*.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | 只沉淀已验证流程，不把 draft 直接升级为稳定模板 | 稳定模板内容可回链到已闭合执行经验 |
| `T8` | `template_sync`, `confirm` | template / playbook / lifecycle 的边界与回填要求仅在 `DI-20` 中定义 | `governance-playbook.md` 与 `release-lifecycle-template.md` 完成回填，且边界与已验证执行经验一致 | `docs/development/governance-playbook.md`, `docs/development/release-lifecycle-template.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | `playbook` 不得替代 `Ruling` / 相关治理裁决；lifecycle 只回填通用流程义务 | playbook / lifecycle 回填内容均可回链到 `PR-GOV-01 ~ PR-GOV-05` 的已验证产物 |

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` §T8 / §Q5 | 模板抽离计划、playbook 边界、lifecycle 回填约束 |
| PR | `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-04-contracts-backlinks-and-checks.md` | 执行模板草案来源 |
| PR | `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-05-closure-audit-and-governance-activation.md` | closure audit 与治理激活输入 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | 模板草案来源 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md` | 已验证执行经验与阻断检查 |
| Template | `docs/development/release-lifecycle-template.md` | 版本级回填目标 |

---

## Scope

In scope:
- 定稿稳定模板到 `docs/development/report-templates/`
- 起草并定稿 `docs/development/governance-playbook.md`
- 回填 `docs/development/release-lifecycle-template.md`
- 明确未能定稿的模板或规则仍保持计划态

Out of scope:
- 新增治理实验
- 回改 `DI-19` / `DI-20` 的核心规则
- 任何未经执行验证的新增模板化规则

---

## Design

### 1. Planned Stable Outputs

1. `docs/development/report-templates/retrospective-reconstruction-adr-template.zh-CN.md`
2. `docs/development/report-templates/governance-theme-map-template.zh-CN.md`
3. `docs/development/report-templates/governance-theme-delta-contract-template.zh-CN.md`
4. `docs/development/report-templates/governance-closure-audit-template.zh-CN.md`
5. `docs/development/report-templates/governance-activation-template.zh-CN.md`
6. `docs/development/governance-playbook.md`

### 2. Backfill Boundary

- `template`：只承载可填写、可复用的操作骨架
- `playbook`：只承载稳定动作入口、gate、角色与导航
- `release-lifecycle-template.md`：只承载版本级通用回填要求

### 3. Non-Backfillable Items

以下内容不得直接沉淀进稳定模板：

- 本轮 `v0.3` / `v0.4` 迁移窗口的特定上下文
- 尚未验证的实验性规则
- 依赖具体历史争议的临时 workaround

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | A | 根据已验证执行经验定稿 5 份治理模板 | `docs/development/report-templates/*.md` | 新增 ~120-180 行/份 | — |
| T2 | B | 起草并定稿 `governance-playbook.md` | `docs/development/governance-playbook.md` | 新增 ~180 行 | T1 |
| T3 | C | 将稳定流程回填到 `release-lifecycle-template.md` | `docs/development/release-lifecycle-template.md` | 编辑 ~60 行 | T1, T2 |
| T4 | C | 对未验证内容保留计划态并记录不回填原因 | `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md` | 编辑 ~40 行 | T1-T3 |

---

## Planned File Changes

- `[add]` `docs/development/report-templates/retrospective-reconstruction-adr-template.zh-CN.md`
- `[add]` `docs/development/report-templates/governance-theme-map-template.zh-CN.md`
- `[add]` `docs/development/report-templates/governance-theme-delta-contract-template.zh-CN.md`
- `[add]` `docs/development/report-templates/governance-closure-audit-template.zh-CN.md`
- `[add]` `docs/development/report-templates/governance-activation-template.zh-CN.md`
- `[add]` `docs/development/governance-playbook.md`
- `[edit]` `docs/development/release-lifecycle-template.md`
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/governance-template-drafts.md`

---

## Verification

```powershell
rg -n "Reconstruction Notice|Document Class|Current Normative Source" docs/development/report-templates/retrospective-reconstruction-adr-template.zh-CN.md

rg -n "Theme ID|Decision Line Title|Primary Upstream|Published ADR" docs/development/report-templates/governance-theme-map-template.zh-CN.md

rg -n "Theme Delta Contract|Covered Themes|Theme Operations|Required Sign-off" docs/development/report-templates/governance-theme-delta-contract-template.zh-CN.md

rg -n "Purpose and Boundaries|Trigger Conditions|Workflow Overview|Template Index|Reference Documents" docs/development/governance-playbook.md

rg -n "governance|Theme Delta Contract|closure audit|playbook" docs/development/release-lifecycle-template.md
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 把实验规则错误沉淀成稳定模板 | HIGH | 所有回填必须回链已闭合执行经验 |
| `playbook` 越权变成规范源 | HIGH | 明确 `Ruling` 仍是规范源，`playbook` 只做入口导航 |
| lifecycle 回填过多版本上下文 | MEDIUM | 只回填通用流程义务，不回填本轮历史细节 |

---

## Kickoff Prep Readiness Review

### Readiness Checklist

- [x] Canonical inputs 已显式列出
- [x] Scope / Out of Scope 已冻结到 spec 级
- [x] Planned File Changes 已冻结到文件级
- [x] Theme Delta Contract 与 Theme Delta Rows 已完整存在
- [x] non-backfillable 项已显式列出
- [ ] 所有 `TBD` 字段已清零
- [ ] `PR-GOV-05 exit gate` 已满足，且 `Closure Audit Output` 无阻断级失败
- [ ] 目标模板、`governance-playbook.md`、`release-lifecycle-template.md` 回填内容已具备可验证输入
- [ ] Verification 已可对真实目标文件执行
- [ ] Required sign-off 已完成，或已明确 deferred 到 kickoff

### Current Verdict

| Field | Value |
|------|-------|
| Verdict | `Blocked` |
| Blocking Items | `PR Executor` 仍为 `TBD`；依赖 `PR-GOV-05 exit gate`；稳定模板、`governance-playbook.md` 与 lifecycle 回填尚未具备已验证输入 |
| Dependency Gate | `PR-GOV-05 exit gate` + `Closure Audit Output` 无阻断级失败 |
| Last Reviewed | `2026-03-06` |
| Reviewer | `Codex` |
| Notes | `PR-GOV-06` 只能消费已闭合执行经验，因此它的 ready 结论天然晚于前 5 个 GOV PR |

---

## Acceptance Criteria

- [ ] 计划中的稳定模板已定稿或明确标记为暂缓
- [ ] `governance-playbook.md` 已创建并符合既定边界
- [ ] `release-lifecycle-template.md` 已回填已验证流程
- [ ] 所有回填内容均可回链到已闭合执行经验
- [ ] `PR-GOV-06` 的 exit gate 已记录为 `satisfied` 或 `blocked`
- [ ] 本 PR spec 的 kickoff 筹备结论已同步更新
