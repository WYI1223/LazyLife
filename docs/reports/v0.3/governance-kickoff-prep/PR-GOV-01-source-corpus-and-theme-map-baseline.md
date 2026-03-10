# PR-GOV-01: source corpus 盘点与主题地图基线

- Proposed title: `docs(governance): PR-GOV-01 establish source corpus inventory and first-pass theme map baseline`
- Status: Draft

## Goal

为未来 `v0.4 kickoff` 组织正式治理 PR spec 预留第一层筹备输入：按时间顺序盘点
`source corpus`，抽取 first-pass `decision line` 主题地图，记录
`split / merge / supersede` 候选边界，并为后续 `PR-GOV-02 ~ PR-GOV-06`
草案提供统一输入。

前置条件：无。当前阶段它是 future `v0.4 kickoff` 的首个候选 PR spec，而不是已进入执行的正式 PR。

## Theme Delta Contract

### Contract Summary

| 字段 | 内容 |
|------|------|
| Covered Themes | `T1`, `T3`, `T4`, `T7` |
| Theme Operations | `T1=inventory+confirm`, `T3=inventory+confirm`, `T4=inventory+split/merge-candidate-capture`, `T7=confirm` |
| Primary Theme Owner | `PR-GOV-01` |
| PR Executor | `TBD (during v0.4 kickoff)` |
| Secondary Coverage | 为 `PR-GOV-02` ~ `PR-GOV-06` 提供统一输入基线 |
| Out of Scope | 发布 ADR、治理激活、repo-wide 一致性审计、template/playbook 正式落地 |
| Must Preserve | `08a -> 08b -> 08c -> 08d -> 09` 时间顺序；主题切分不受文档边界绑死；`T1-T8` 与 `Theme ID` 不混用 |
| Allowed Simplifications | first-pass 主题地图可保留 `split_pending` / `merge_pending` / `status_pending` |
| Escalation Required If Violated | 若发现 `stable why-question` 无法判定、主题边界持续冲突、或 source corpus 缺口阻断主题抽取，必须回到 `DI-20` 或新治理裁决 |
| Accepted Debt | 允许 first-pass 主题地图保留少量 `open questions`，但必须显式登记 owner 与退出条件 |
| Output Docs | 本 PR spec + source corpus inventory + first-pass theme map + theme coverage baseline + template extraction backlog |
| Verification | 结构字段完整、核心 source corpus 已收录、所有候选主题都有 `Theme ID` 与 owner/status |
| Required Sign-off | `Theme Owner` + `governance owner` |

### Theme Delta Rows

| Theme ID | Theme Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------------|---------------|--------------|--------------|---------------|--------------|
| `T1` | `inventory`, `confirm` | `adr/` 结构与主题地图边界仅在 `DI-19/20` 中定义 | source corpus 盘点与 first-pass 主题地图存在统一基线 | `PR-GOV-01-source-corpus-and-theme-map-baseline.md`, `governance-source-corpus-inventory.md`, `governance-theme-map-first-pass.md` | `adr/` 目录不承载执行期草稿 | 主题地图存在且字段齐全 |
| `T3` | `inventory`, `confirm` | 历史补录 ADR 规则已定义，但无正式 source corpus 盘点产物 | source corpus inventory 明确列出历史补录输入与覆盖声明基线 | `governance-source-corpus-inventory.md` | 历史重演锚点必须从 `08a` 开始 | inventory 覆盖 08a/08b/08c/08d/09 + v0.3 关键治理证据 |
| `T4` | `inventory`, `split`, `merge` | `decision line` 切分规则已在 `DI-20` 定义，但无实例化输出 | first-pass theme map 形成候选主题与关系边 | `governance-theme-map-first-pass.md`, `governance-theme-coverage-baseline.md` | 主题切分按 `stable why-question`，不按文档文件数 | 每个候选主题均具备最小字段模型 |
| `T7` | `confirm` | 治理顺序存在原则定义，但缺 kickoff 组织入口基线 | `PR-GOV-01` 的 kickoff 输入已准备，可供未来 `v0.4 kickoff` 组织 `PR-GOV-02` 接续 | `PR-GOV-01-source-corpus-and-theme-map-baseline.md`, `DI-20-governance-execution-plan.md` | 后续 kickoff 组织不得跳过 `PR-GOV-01` 基线 | kickoff 输入结论明确记录为 ready 或 blocked |

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` §10-§15 | 当前有效治理规则、source corpus 要求、append-only 生效边界 |
| DI | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | `PR-GOV-01` 主题覆盖、Theme Delta Contract、未来执行 gate 与模板抽离计划 |
| Review Index | `docs/reports/v0.2.5/frontend-review/08-reassessment-and-replanning.md` | `08a-08d` 的统一时间轴入口 |
| Audit | `docs/reports/v0.2.5/frontend-review/08a-audit-findings.md` | 历史重演的事实触发点 |
| Semantic Decisions | `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md` | 首轮语义裁决源 |
| Solution Proposals | `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md` | 结构方案与解决策略来源 |
| PR Replanning | `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md` | 历史 PR 编排与执行边界来源 |
| Acceptance | `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md` | 08 系列闭合与历史执行结果 |
| PR Spec | `docs/releases/v0.3/prs/PR-RB-00-doc-fixes.md` | ADR 废弃、E1 迁移、v0.3 文档治理动作事实来源 |
| Ruling | `docs/architecture/rulings-legacy/E1-release-and-versioning.md` | ADR-0001 迁移与 release/versioning 语义背景 |
| Release Evidence | `docs/releases/v0.3/v0.3-release-evidence.md` | v0.3 收口完成、DI-12~18 处于 v0.4 planning boundary 的证据 |
| Index | `docs/reports/v0.3/design-discussions/README.md` | 执行文档入口与状态同步 |

---

## Scope

In scope:
- 建立按时间顺序排序的 `source corpus inventory`
- 建立 first-pass `theme map`，并为每个候选主题分配临时 `Theme ID`
- 建立 `theme coverage baseline`，记录候选主题与后续 `PR-GOV-*` 的预期覆盖关系
- 建立 `template extraction backlog` 基线
- 记录 `split_pending` / `merge_pending` / `status_pending` 等未决项
- 为 `PR-GOV-02` 提供可消费的入口基线与阻断列表

Out of scope:
- 发布任何历史补录 ADR 或 Native ADR
- 决定最终 ADR 编号、标题或发布时间
- 创建稳定模板正文、`governance-playbook.md` 或修改 `release-lifecycle-template.md`
- 执行 repo-wide 一致性审计
- 宣布治理激活或 append-only 生效

---

## Design

### 1. Output Artifact Set

本候选 PR spec 预期交付以下 kickoff 筹备基线文档：

1. `docs/reports/v0.3/governance-kickoff-prep/governance-source-corpus-inventory.md`
2. `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md`
3. `docs/reports/v0.3/governance-kickoff-prep/governance-theme-coverage-baseline.md`
4. `docs/reports/v0.3/governance-kickoff-prep/governance-template-extraction-backlog.md`

### 2. Ordering Model

`source corpus inventory` 按**时间与证据出现顺序**建立，至少覆盖：

`08a -> 08b -> 08c -> 08d -> 09 -> PR-0256 / v0.3 doc-fix/release evidence -> DI-19 -> DI-20`

主题切分不按文档顺序建立，而按 `stable why-question` 建立；但每个主题内部的
`Journey Timeline / Phases` 必须保持时间顺序。

### 3. Theme ID Policy

`PR-GOV-01` 中抽取的候选主题不得复用 `T1-T8` 编号。为避免“治理主题”和“决策线主题”
混淆，first-pass 主题地图使用临时 `Theme ID`：

- `TH-001`, `TH-002`, `TH-003`, ...

其中：

- `T1-T8` = `DI-20` 中的治理执行主题
- `TH-xxx` = 历史重演中抽取出的 `decision line` 候选主题

### 4. First-Pass Theme Map Contract

first-pass 主题地图至少必须包含 `DI-20` 已定义的最小字段模型：

- `Theme ID`
- `Decision Line Title`
- `Stable Why-Question`
- `Decision Subject`
- `Governing Tension`
- `Acceptance Semantics`
- `Primary Upstream`
- `Secondary Input Constraints`
- `Relation Types`
- `Supersedes / Redirected By`
- `First Seen In Corpus`
- `Current Status`
- `Planned ADR`
- `Published ADR`
- `Owner`
- `Notes`

允许新增 first-pass 辅助字段，但不得删减上述最小字段。

### 5. Open Questions Handling

若 `stable why-question` 无法立即判定，允许在 first-pass 主题地图中使用以下状态：

- `split_pending`
- `merge_pending`
- `status_pending`
- `owner_pending`

这些状态必须伴随：

- 明确的阻断原因
- owner
- 预期在哪个后续 `PR-GOV-*` 阶段闭合

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | A | 建立 `source corpus inventory` 骨架，按时间顺序列出一级来源与 source type | `docs/reports/v0.3/governance-kickoff-prep/governance-source-corpus-inventory.md` | 新增 ~120 行 | — |
| T2 | A | 将 `08a/08b/08c/08d/09`、`PR-RB-00`、`E1`、`v0.3-release-evidence` 录入 inventory 并标注覆盖关系 | `docs/reports/v0.3/governance-kickoff-prep/governance-source-corpus-inventory.md` | 编辑 ~120 行 | T1 |
| T3 | B | 建立 first-pass 主题地图骨架并写入最小字段模型列 | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | 新增 ~140 行 | — |
| T4 | B | 基于 source corpus 抽取第一批候选 `TH-xxx` 主题，记录 `primary upstream` / `relation type` / `first seen in corpus` | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | 编辑 ~180 行 | T2, T3 |
| T5 | B | 记录 `split_pending` / `merge_pending` / `superseding dependency` 等边界争议与 owner | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | 编辑 ~80 行 | T4 |
| T6 | C | 建立主题覆盖基线，映射候选主题到 `PR-GOV-02` ~ `PR-GOV-06` 的预期消费关系 | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-coverage-baseline.md` | 新增 ~100 行 | T4 |
| T7 | C | 建立模板抽离清单基线，记录 planned template / planning stage / drafting stage / finalization stage | `docs/reports/v0.3/governance-kickoff-prep/governance-template-extraction-backlog.md` | 新增 ~90 行 | T2 |
| T8 | D | 将 `PR-GOV-01` 入口文档接入索引，必要时同步 `DI-20` 关联或执行表说明 | `docs/reports/v0.3/design-discussions/README.md`, `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`, `docs/reports/v0.3/governance-kickoff-prep/README.md` | 编辑 ~30 行 | T1-T7 |

---

## Planned File Changes

- `[add]` `docs/reports/v0.3/governance-kickoff-prep/PR-GOV-01-source-corpus-and-theme-map-baseline.md` (本 PR spec)
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-source-corpus-inventory.md` (`source corpus` 盘点基线)
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` (first-pass `decision line` 主题地图)
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-theme-coverage-baseline.md` (候选主题到后续 `PR-GOV-*` 的覆盖基线)
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/governance-template-extraction-backlog.md` (模板抽离清单基线)
- `[add]` `docs/reports/v0.3/governance-kickoff-prep/README.md` (治理 kickoff 筹备目录入口)
- `[edit]` `docs/reports/v0.3/design-discussions/README.md` (增加治理 kickoff 筹备 PR 草案入口)
- `[edit]` `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` (补回链接与筹备语义说明)

---

## Verification

### Structural verification

```powershell
rg -n "08a-audit-findings.md|08b-semantic-decisions.md|08c-solution-proposals.md|08d-pr-replanning.md|09-acceptance-report.md|PR-RB-00-doc-fixes.md|E1-release-and-versioning.md|v0.3-release-evidence.md" docs/reports/v0.3/governance-kickoff-prep/governance-source-corpus-inventory.md

rg -n "^\\| `Theme ID` \\||^\\| `Decision Line Title` \\||^\\| `Stable Why-Question` \\||^\\| `Decision Subject` \\||^\\| `Governing Tension` \\||^\\| `Acceptance Semantics` \\||^\\| `Primary Upstream` \\||^\\| `Secondary Input Constraints` \\||^\\| `Relation Types` \\||^\\| `Supersedes / Redirected By` \\||^\\| `First Seen In Corpus` \\||^\\| `Current Status` \\||^\\| `Planned ADR` \\||^\\| `Published ADR` \\||^\\| `Owner` \\||^\\| `Notes` \\|" docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md

rg -n "TH-00[1-9]|split_pending|merge_pending|status_pending|owner_pending" docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md

rg -n "PR-GOV-02|PR-GOV-03|PR-GOV-04|PR-GOV-05|PR-GOV-06" docs/reports/v0.3/governance-kickoff-prep/governance-theme-coverage-baseline.md docs/reports/v0.3/governance-kickoff-prep/governance-template-extraction-backlog.md

rg -n "Covered Themes|Theme Operations|Primary Theme Owner|PR Executor|Must Preserve|Allowed Simplifications|Accepted Debt|Required Sign-off" docs/reports/v0.3/governance-kickoff-prep/PR-GOV-01-source-corpus-and-theme-map-baseline.md
```

### Kickoff-prep verification

```powershell
rg -n "Kickoff Prep Readiness Review|Ready for Kickoff Input|Blocked" docs/reports/v0.3/governance-kickoff-prep/PR-GOV-01-source-corpus-and-theme-map-baseline.md
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| source corpus 盘点被文档顺序替代主题抽取 | HIGH | 明确要求 inventory 按时间轴、主题地图按 `stable why-question` |
| `T1-T8` 与 `TH-xxx` 混用 | HIGH | 固定 `Theme ID Policy`，禁止候选主题复用治理主题编号 |
| first-pass 主题切分过早定稿 | MEDIUM | 允许 `split_pending` / `merge_pending`，并显式记录 owner 与后续闭合阶段 |
| 模板抽离过早固化 | MEDIUM | 仅创建模板抽离清单，不创建稳定模板正文 |
| 执行入口文档孤立，后续 PR 无法回链 | LOW | README 与 `DI-20` 关系处同步最小入口 |

---

## Kickoff Prep Readiness Review

### Kickoff Prep Checklist

- [x] Canonical inputs 已显式列出
- [x] Scope / Out of Scope 已冻结到 spec 级
- [x] Planned File Changes 已冻结到文件级
- [x] Theme Delta Contract 与 Theme Delta Rows 已完整存在
- [x] 所有 `TBD` 字段已清零
- [x] 前置筹备依赖已满足（`PR-GOV-01` 无前置依赖）
- [x] 计划输出文档已创建并可供 future `v0.4 kickoff` 组织消费
- [x] Verification 已可对真实目标文件执行
- [x] 当前文档已明确为 kickoff 筹备输入，而非已进入执行的正式 PR

### Current Verdict

| Field | Value |
|------|-------|
| Verdict | `Ready for Kickoff Input` |
| Blocking Items | `None` |
| Dependency Gate | `N/A` |
| Last Reviewed | `2026-03-06` |
| Reviewer | `Codex` |
| Notes | 这是 future `v0.4 kickoff` 的首个候选 PR spec；当前已整理出可直接供 kickoff 使用的 baseline 输入，但尚未进入正式执行态 |

---

## Kickoff Input Review

| Field | Value |
|------|-------|
| Prep Verdict | `ready` |
| Reviewed On | `2026-03-06` |
| Reviewer | `Codex` |
| Evidence | `governance-source-corpus-inventory.md`、`governance-theme-map-first-pass.md`、`governance-theme-coverage-baseline.md`、`governance-template-extraction-backlog.md` 已整理完成，可直接作为 kickoff 输入 |
| Residual Notes | first-pass 仍保留 `TH-005 split_pending`；该 pending 已显式记录，后续应在正式 kickoff 编排 `PR-GOV-02/03` 时继续裁决 |

---

## Acceptance Criteria

- [x] `docs/reports/v0.3/governance-kickoff-prep/governance-source-corpus-inventory.md` 已创建，并显式覆盖 `08a/08b/08c/08d/09`、`PR-RB-00-doc-fixes.md`、`E1-release-and-versioning.md`、`v0.3-release-evidence.md`
- [x] `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` 已创建，并包含 `DI-20` 规定的最小字段模型
- [x] 每个候选主题均拥有临时 `Theme ID`、owner、status，且未复用 `T1-T8`
- [x] `docs/reports/v0.3/governance-kickoff-prep/governance-theme-coverage-baseline.md` 已创建，并为后续 `PR-GOV-02` ~ `PR-GOV-06` 提供初始覆盖映射
- [x] `docs/reports/v0.3/governance-kickoff-prep/governance-template-extraction-backlog.md` 已创建，并为每个计划模板记录规划/起草/定稿阶段
- [x] 本 spec 已明确标注为 future `v0.4 kickoff` 的输入文档，而不是已进入执行的正式 PR
- [x] kickoff 输入结论已在本 spec 中记录为 `ready` 或 `blocked`
