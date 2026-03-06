# PR-GOV-02: ADR 结构交接骨架与元数据合同

- Proposed title: `docs(governance): PR-GOV-02 prepare adr handoff skeletons and reconstruction metadata contract`
- Status: Draft

## Goal

在 `PR-GOV-01` 完成 source corpus 与 first-pass theme map 基线之后，形成一组
future `v0.4 kickoff` 可直接接入主线的 ADR 交接骨架：prep 层的 README / topic-map
skeleton，以及历史补录 ADR 的元数据合同与标准声明。

前置条件：`PR-GOV-01 exit gate` 已满足。

## Theme Delta Contract

### Contract Summary

| 字段 | 内容 |
|------|------|
| Covered Themes | `T1`, `T2`, `T3` |
| Theme Operations | `T1=confirm`, `T2=confirm`, `T3=confirm` |
| Primary Theme Owner | `PR-GOV-02` |
| PR Executor | `TBD (during v0.4 kickoff)` |
| Secondary Coverage | 为 `PR-GOV-03` 提供 ADR draft handoff 载体 |
| Out of Scope | 创建正式 `docs/architecture/adr/` 主线资产、发布任何具体 ADR 正文、运行 repo-wide audit、治理激活 |
| Must Preserve | 当前所有输出都留在 `governance-kickoff-prep/`；正式 `adr/` 目录只在 future kickoff 主线创建；历史补录 ADR 与 Native ADR 明确区分；append-only 不得提前生效 |
| Allowed Simplifications | 允许 `Planned ADR` 暂用占位符；允许 future `Published ADR` 保持 `pending` |
| Escalation Required If Violated | 若 skeleton、元数据合同与 `DI-19/20` 冲突，必须回到治理裁决 |
| Accepted Debt | 允许个别 ADR 文件名在 `PR-GOV-03` 前保持 `<slug-pending>` 占位 |
| Output Docs | ADR README skeleton、ADR topic-map skeleton、ADR 元数据合同执行文档 |
| Verification | prep 层 skeleton 存在且可导航，元数据合同字段完整，并明确 future mainline target |
| Required Sign-off | `Theme Owner` + `governance owner` |

### Theme Delta Rows

| Theme ID | Theme Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------------|---------------|--------------|--------------|---------------|--------------|
| `T1` | `confirm` | ADR 目录边界仅在 DI 中定义 | kickoff prep 层的 ADR README / topic-map skeleton 存在 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` | 正式 `adr/` 目录不在本轮创建 | skeleton 可打开且字段齐全 |
| `T2` | `confirm` | 生效范围与 authority matrix 仅在 DI-19/20 中存在 | ADR README skeleton 明确区分规范源、叙事源与执行源 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md`, `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | `Ruling` 仍为规范源 | README skeleton 写明 authority boundary |
| `T3` | `confirm` | 历史补录 ADR 契约仅在 DI 中定义 | 历史补录 ADR 元数据合同与标准声明形成可执行骨架 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md` | 补录 ADR 不伪装成 contemporaneous 原件 | 合同字段与标准声明存在 |

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` §10-§15 | ADR 结构、生效边界、历史补录 ADR 规范 |
| DI | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | `PR-GOV-02` 主题覆盖、exit gate、模板抽离约束 |
| PR | `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-01-source-corpus-and-theme-map-baseline.md` | source corpus 与 first-pass theme map 基线 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | future `Planned ADR` 槽位来源 |
| Execution Doc | `docs/reports/v0.3/governance-kickoff-prep/governance-template-extraction-backlog.md` | ADR 类模板抽离规划基线 |

---

## Scope

In scope:

- 创建 ADR README 的 prep 层 skeleton
- 创建 ADR topic-map 的 prep 层 skeleton
- 创建 `governance-adr-metadata-contract.md`
- 将 first-pass theme map 中已确认主题映射为 future `Planned ADR` 占位

Out of scope:

- 创建正式 `docs/architecture/adr/` 主线目录与文件
- 发布任何具体 ADR 正文
- 定稿稳定模板到 `docs/development/report-templates/`
- 运行一致性审计或治理激活

---

## Design

### 1. Output Artifact Set

1. `docs/reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md`
2. `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md`
3. `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md`

### 2. ADR Structure Boundary

- `governance-adr-readme-skeleton.md`：future `docs/architecture/adr/README.md` 的 prep 层结构与边界说明
- `governance-adr-topic-map-skeleton.md`：future `docs/architecture/adr/topic-map.md` 的 prep 层字段模型与映射规则
- 正式 `ADR-000X-<slug>.md`：本轮不创建主线文件；仅在 future kickoff mainline 中依据后续 spec 落地

### 3. Metadata Contract Requirements

历史补录 ADR 至少必须包含：

- `Document Class`
- `Narrative Perspective`
- `Decision Line`
- `Coverage Scope`
- `Current Normative Source`
- `Source Corpus Summary`
- `Revision Record`
- 标准 `Reconstruction Notice`

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | A | 创建 ADR README 的 prep 层 skeleton | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md` | 新增 ~70 行 | — |
| T2 | A | 创建 ADR topic-map 的 prep 层 skeleton 并定义与 first-pass theme map 的对接方式 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` | 新增 ~80 行 | — |
| T3 | B | 编写历史补录 ADR 元数据合同与标准声明 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md` | 新增 ~120 行 | — |
| T4 | B | 将已确认主题写入 future `Planned ADR` 占位规则 | `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md`, `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | 编辑 ~60 行 | T2, T3 |
| T5 | C | 同步 `DI-20` / 目录索引中的 `PR-GOV-02` 关联说明 | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`, `docs/reports/v0.3/governance-kickoff-prep/README.md` | 编辑 ~20 行 | T1-T4 |

---

## Planned File Changes

- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md`
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md`
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md`
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md`
- `[edit]` `docs/reports/v0.3/governance-kickoff-prep/README.md`
- `[edit]` `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`

---

## Verification

```powershell
rg -n "Purpose and Boundaries|Authority Boundary|Retrospective Reconstruction ADR|Native ADR" docs/reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md

rg -n "Theme ID|Decision Line Title|Planned ADR|Published ADR|Primary Upstream" docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md

rg -n "Document Class|Narrative Perspective|Decision Line|Coverage Scope|Current Normative Source|Source Corpus Summary|Revision Record|Reconstruction Notice" docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| kickoff prep 文档与 future mainline ADR 资产混线 | HIGH | 所有当前输出都保留在 `governance-kickoff-prep/`，只留下 future target 说明 |
| future `Planned ADR` 占位被误当成已发布 ADR | MEDIUM | skeleton 中显式区分 `Planned ADR` / `Published ADR` |
| 元数据合同遗漏补录必需字段 | HIGH | 直接对齐 `DI-19 §11` 最低契约 |

---

## Kickoff Prep Readiness Review

### Readiness Checklist

- [x] Canonical inputs 已显式列出
- [x] Scope / Out of Scope 已冻结到 spec 级
- [x] Planned File Changes 已冻结到文件级
- [x] Theme Delta Contract 与 Theme Delta Rows 已完整存在
- [x] ADR README / topic-map 的 prep 层 skeleton 已创建，并明确 future mainline target
- [x] `governance-adr-metadata-contract.md` 已创建
- [x] Verification 已可对 prep 层目标文件执行
- [x] Required sign-off 已明确 deferred 到 kickoff

### Current Verdict

| Field | Value |
|------|-------|
| Verdict | `Ready for Kickoff Input` |
| Blocking Items | `None`；formal `docs/architecture/adr/README.md` 与 `topic-map.md` 明确后置到 future kickoff mainline，不再构成 prep blocker |
| Dependency Gate | `PR-GOV-01 exit gate` |
| Last Reviewed | `2026-03-06` |
| Reviewer | `Codex` |
| Notes | `PR-GOV-02` 当前只对 kickoff handoff skeleton 负责；正式 `adr/` 目录创建由 future kickoff mainline PR 承担 |

---

## Acceptance Criteria

- [x] `docs/reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md` 已创建并写明 authority boundary
- [x] `docs/reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md` 已创建并能承载 future `Planned ADR` / `Published ADR`
- [x] `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md` 已创建并包含补录 ADR 最低契约
- [ ] first-pass theme map 中已确认主题可映射到 future `Planned ADR`
- [ ] 本 PR spec 的 kickoff 筹备结论已同步更新
