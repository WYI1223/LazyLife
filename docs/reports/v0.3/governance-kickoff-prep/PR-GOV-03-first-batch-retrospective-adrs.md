# PR-GOV-03: 首批历史补录 ADR 草稿包

- Proposed title: `docs(governance): PR-GOV-03 prepare first batch retrospective ADR draft package`
- Status: Draft

## Goal

基于 `PR-GOV-01` 的 source corpus / theme map 基线和 `PR-GOV-02` 的 ADR handoff
skeleton 与元数据合同，准备首批历史补录 ADR 草稿包，并建立 future kickoff mainline
可直接采用的 ADR ↔ 主题映射。

前置条件：`PR-GOV-02 exit gate` 已满足。

## Theme Delta Contract

### Contract Summary

| 字段 | 内容 |
|------|------|
| Covered Themes | `T3`, `T4` |
| Theme Operations | `T3=prepare_adr_draft`, `T4=confirm+prepare_adr_draft` |
| Primary Theme Owner | `PR-GOV-03` |
| PR Executor | `TBD (during v0.4 kickoff)` |
| Secondary Coverage | 为 `PR-GOV-04` 的回链与一致性检查提供 prep 层真实对象 |
| Out of Scope | 创建正式 `docs/architecture/adr/ADR-*.md`、repo-wide audit、治理激活、稳定模板定稿 |
| Must Preserve | 补录 ADR draft 必须显式标注“未来视角重述”；未成熟主题必须继续留在 prep 主题地图，不得消失 |
| Allowed Simplifications | 允许首批 ADR draft 数量少于最终总量；允许未定稿主题保留 `pending` |
| Escalation Required If Violated | 若主题边界仍无法形成稳定 ADR draft，必须回退到 `PR-GOV-01/02` 主题裁决 |
| Accepted Debt | 允许个别 ADR draft 文件名与编号保持 `<slot-pending>` 占位，待 ready-for-implement 时定稿 |
| Output Docs | 首批历史补录 ADR 草稿包 + prep 层主题映射同步 |
| Verification | 每篇 ADR draft 都具备 source corpus、reconstruction notice、revision record、current normative source |
| Required Sign-off | `Theme Owner` + `governance owner` |

### Theme Delta Rows

| Theme ID | Theme Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------------|---------------|--------------|--------------|---------------|--------------|
| `T3` | `prepare_adr_draft` | 历史补录 ADR 仅有结构，无正文实例 | 首批补录 ADR 草稿包已形成 | `docs/reports/v0.3/governance-kickoff-prep/adr-drafts/ADR-000X-<slug>-draft.md` | 必须保留 reconstruction notice 与 source corpus | 每篇 ADR draft 字段完整 |
| `T4` | `confirm`, `prepare_adr_draft` | 主题切分仍停留在 first-pass | 已确认主题进入 ADR draft 包，未确认主题继续保留在 prep 主题地图 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | 不得把 unresolved theme 静默删掉 | prep 主题地图保留未完成主题 |

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` §11 | 历史补录 ADR 规则、source corpus、叙事约束 |
| DI | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | `PR-GOV-03` 主题覆盖、exit gate、模板规划依赖 |
| PR | `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-01-source-corpus-and-theme-map-baseline.md` | 主题地图与 source corpus 基线 |
| PR | `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-02-adr-structure-and-metadata-contract.md` | ADR handoff skeleton 与元数据合同 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` | 首批已确认主题与 future `Planned ADR` 槽位 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md` | 历史补录 ADR 必填字段与标准声明 |

---

## Scope

In scope:

- 选择首批已确认主题
- 编写首批历史补录 ADR draft manuscripts
- 同步 prep 层 topic-map skeleton 中的 `Planned ADR` / future `Published ADR` 映射
- 保留 unresolved themes 在 prep 主题地图中的可见性

Out of scope:

- 创建正式 `docs/architecture/adr/ADR-*.md`
- repo-wide 一致性审计
- 治理激活
- 稳定模板定稿

---

## Design

### 1. ADR Slot Policy

本 PR 为 kickoff prep 阶段，允许使用如下占位槽位：

- `docs/reports/v0.3/governance-kickoff-prep/adr-drafts/ADR-000X-<slug>-draft.md`

ready-for-implement 阶段再根据 `PR-GOV-01/02` 的主题确认结果，决定 future kickoff
mainline 是否将其提升为正式 `docs/architecture/adr/ADR-XXXX-*.md`。

### 2. First Batch Selection Rule

只有满足以下条件的主题才进入首批 ADR draft：

1. `stable why-question` 已足够稳定
2. `Primary Upstream` / `Relation Types` 已记录
3. `Current Normative Source` 可明确指向现有 `Ruling`
4. `Source Corpus` 至少覆盖触发、裁决、执行/收口中的适用项

### 3. Minimum ADR Sections

每篇首批历史补录 ADR draft 至少包括：

- `Reconstruction Notice`
- `Decision Line`
- `Source Corpus`
- `Journey Timeline / Phases`
- `Current State`
- `Open Edges`
- `Revision Record`

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | A | 从 prep 主题图中挑选首批确认主题 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` | 编辑 ~40 行 | — |
| T2 | A | 为每个已确认主题确定 draft ADR 槽位与 slug | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` | 编辑 ~40 行 | T1 |
| T3 | B | 编写首批历史补录 ADR draft 正文 | `docs/reports/v0.3/governance-kickoff-prep/adr-drafts/ADR-000X-<slug>-draft.md` | 新增 ~150-250 行/篇 | T2 |
| T4 | B | 将 future `Published ADR`、`Published Date` 等信息同步回 prep topic-map skeleton | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` | 编辑 ~60 行 | T3 |
| T5 | C | 将未完成主题保留为 `pending`，并记录未进入首批 ADR draft 的原因 | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | 编辑 ~60 行 | T1 |

---

## Planned File Changes

- `[add]` `docs/reports/v0.3/governance-kickoff-prep/adr-drafts/ADR-000X-<slug>-draft.md`（首批历史补录 ADR draft，精确文件名待 ready-for-implement 定稿）
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md`
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md`

---

## Verification

```powershell
rg -n "Reconstruction Notice|Decision Line|Source Corpus|Journey Timeline|Current State|Open Edges|Revision Record" docs/reports/v0.3/governance-kickoff-prep/adr-drafts/ADR-000*-draft.md

rg -n "Published ADR|Planned ADR|Current Status" docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md

rg -n "pending|not selected|blocked" docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 首批 ADR draft 过早锁定主题 | HIGH | 只准备已确认主题的 draft，未确认主题继续留在 prep 主题图 |
| 历史补录 ADR 写成“当时原件”口吻 | HIGH | 强制 `Reconstruction Notice` |
| prep 主题地图与 ADR draft 脱节 | MEDIUM | 同 PR 内同步 future `Published ADR` 映射 |

---

## Kickoff Prep Readiness Review

### Readiness Checklist

- [x] Canonical inputs 已显式列出
- [x] Scope / Out of Scope 已冻结到 spec 级
- [x] Planned File Changes 已冻结到文件级
- [x] Theme Delta Contract 与 Theme Delta Rows 已完整存在
- [ ] 首批已确认主题清单已稳定
- [ ] `ADR-000X-<slug>-draft.md` 等占位文件名已定稿，或被显式允许保留到实现前最后一轮
- [ ] Verification 已可对真实 prep 层 ADR draft 目标文件执行
- [ ] Required sign-off 已完成，或已明确 deferred 到 kickoff

### Current Verdict

| Field | Value |
|------|-------|
| Verdict | `Blocked` |
| Blocking Items | 首批主题尚未确认；ADR draft 文件名仍为 `ADR-000X-<slug>-draft.md` 占位 |
| Dependency Gate | `PR-GOV-02 exit gate` |
| Last Reviewed | `2026-03-06` |
| Reviewer | `Codex` |
| Notes | `PR-GOV-03` 在 prep 层只形成首批 ADR 草稿包；正式发布动作仍留给 future kickoff mainline |

---

## Acceptance Criteria

- [ ] 首批历史补录 ADR draft 已形成
- [ ] 每篇 ADR draft 均包含 `Reconstruction Notice`、`Source Corpus`、`Revision Record`
- [ ] prep topic-map skeleton 中已建立 future `Published ADR` 映射
- [ ] 未完成主题仍保留在 prep 主题图中并带原因
- [ ] 本 PR spec 的 kickoff 筹备结论已同步更新
