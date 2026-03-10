# PR-0402: ADR 基础设施与元数据合同

- Proposed title: `docs(governance): establish ADR directory bootstrap and retrospective metadata contract`
- Execution status: Merged
- Spec review status: Review-clean (`docs/releases/v0.4/pr-spec-review-resolution.md`)

| 项目 | 值 |
|------|-----|
| **执行状态** | MERGED |
| **规格评审状态** | Review-clean |
| **主题覆盖** | `T1`, `T2`, `T3` |
| **依赖** | `PR-0401` |
| **关联** | [DI-19-adr-governance.md](../../../reports/v0.3/design-discussions/DI-19-adr-governance.md), [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

在 `PR-0401` 已建立 source corpus、survey、DN baseline 之后，建立 ADR 主线目录骨架与历史补录 ADR 的元数据合同，使 `PR-0403` 可以直接消费统一的 mainline shell、topic-map header contract 与 retrospective metadata boundary，而不需要边执行边发明载体规则。

---

## Scope

### In Scope

1. **Action 1: 建立 `docs/architecture/adr/` 主线目录骨架**
2. **Action 2: 定稿历史补录 ADR 元数据合同**

### Out of Scope

1. `topic-map.md` 主题行填充
2. `ADR-000X-<slug>.md` 正式正文发布
3. DN classification、theme approval、theme delta 审计
4. `Native ADR` 模板定稿
5. append-only 激活与治理 closure audit

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| 当前有效治理规则 | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` | 定义 `Retrospective Reconstruction ADR` / `Native ADR` 分类边界、authority boundary、append-only 生效边界 |
| 当前有效执行规则 | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | 定义 PR-0402 在治理工作流中的位置、topic-map 最小字段模型、metadata contract 最低要求 |
| 上游执行基线 | `docs/reports/v0.4/governance-execution/PR-0401/document-inventory.md`, `dn-ledger.md`, `coverage-matrix.md` | 提供 PR-0402 的直接 handoff 输入；确认 `DI-19` / `DI-20` 为当前治理执行权威输入 |
| Prep 层 handoff skeleton | `governance-adr-readme-skeleton.md`, `governance-adr-topic-map-skeleton.md`, `governance-adr-metadata-contract.md` | 作为结构种子，被提升、收敛并改写为 mainline / execution artifacts；不得原样冒充正式资产 |

边界规则：

1. `DI-19` / `DI-20` 是当前有效治理规则源，prep 文档只是 handoff 输入。
2. `docs/architecture/adr/` 在本 PR 中只建立主线骨架，不发布任何 `ADR-000X-*.md` 正文。
3. `topic-map.md` 在本 PR 中只建立 header contract；`PR-0403` 在其执行目录维护 working copy，不直接覆写 mainline skeleton。

---

## Actions Detail

### Action 1: 建立 `docs/architecture/adr/` 主线目录骨架

产出物：

- `docs/architecture/adr/README.md`
- `docs/architecture/adr/topic-map.md`

`adr/README.md` 必须满足：

1. 明确 `Ruling` 仍是当前架构约束的规范源，`ADR` 是跨版本决策旅程层，不是规范层。
2. 明确区分 `Retrospective Reconstruction ADR` 与 `Native ADR`。
3. 明确 append-only 只在治理激活后、且仅对 `Native ADR` 自动生效。
4. 明确 `docs/architecture/adr/` 只存放正式发布的 ADR 资产，不存放 scratchpad、candidate inventory、execution notes。
5. 至少包含以下章节：
   - `Purpose and Boundaries`
   - `Authority Boundary`
   - `ADR Classes and Statuses`
   - `Directory Contents`
   - `Reading Guide`
   - `Maintenance Rules`
   - `Reference Documents`

`topic-map.md` 必须满足：

1. 使用 `DI-20` 的最小字段模型并为 normative backlink 补 dedicated 列，至少包含以下 17 列：
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
   - `Current Normative Source`
   - `Planned ADR`
   - `Published ADR`
   - `Owner`
   - `Notes`
2. 当前阶段为 header-only skeleton，不写任何 `TH-*` 数据行。
3. 明确正式 mainline topic map 只收录已批准主题；候选主题与 unresolved split / merge 继续留在 execution-layer working copy。
4. `Current Normative Source` 必须作为 dedicated topic-map 列存在，不能借用 `Published ADR`，也不能只藏在 `Notes`。

### Action 2: 定稿历史补录 ADR 元数据合同

产出物：

- `docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`

必须定稿以下合同面：

1. **Required Metadata**：至少定稿以下 11 个必填字段：
   - `Document Class`
   - `Narrative Perspective`
   - `Decision Line`
   - `Coverage Scope`
   - `Current Normative Source`
   - `Source Corpus Summary`
   - `Corpus Coverage Declaration`
   - `Journey Timeline / Phases`
   - `Current State`
   - `Open Edges`
   - `Revision Record`
2. **Corpus Coverage Declaration**：至少定稿以下 5 类覆盖声明与允许状态：
   - `Trigger Source`: `present / absent / not_applicable`
   - `Decision Source`: `present / absent / not_applicable`
   - `Normative Source`: `present / partial / absent`
   - `Execution / Closure Source`: `present / absent / not_applicable`
   - `Superseded / Redirected Source`: `present / absent / not_applicable`
3. **Standard Reconstruction Notice**：定稿历史补录 ADR 顶部标准声明的最低要求。
4. **Standard Section Skeleton**：至少定稿以下 8 个正文骨架章节：
   - `Reconstruction Notice`
   - `Decision Line`
   - `Source Corpus`
   - `Corpus Coverage Declaration`
   - `Journey Timeline / Phases`
   - `Current State`
   - `Open Edges`
   - `Revision Record`
5. **Revision Rules During Migration Window**：定稿补源、纠错、边界修订、superseded / redirected 回补的允许范围，并写明哪些变更必须升级回治理裁决。
6. **Theme Map Alignment**：定稿 ADR 字段与 topic-map 字段的最小对齐关系。

补充约束：

1. 本合同回答的是 “字段/声明/骨架/修订规则是什么”，不是 “首批到底写哪几篇 ADR”。
2. 本合同是未来 `retrospective-reconstruction-adr-template.zh-CN.md` 的上游约束，不等于模板正文；模板起草与 lifecycle backfill 继续由 `PR-0403` / `PR-0406` 承接。
3. 如果 `PR-0403` 执行中发现合同缺项，必须显式记录 deviation 或回收治理合同，而不是静默在执行期改写 mainline shell。

---

## Deliverables

所有产出物存放于如下路径：

| Action | 产出物 | 存放路径 |
|--------|--------|----------|
| 1 | `README.md` | `docs/architecture/adr/` |
| 1 | `topic-map.md` | `docs/architecture/adr/` |
| 2 | `adr-metadata-contract.md` | `docs/reports/v0.4/governance-execution/PR-0402/` |
| Support | `README.md` 执行日志 | `docs/reports/v0.4/governance-execution/PR-0402/` |

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Docs | 将 PR-0402 spec 收敛为可执行合同，写清 canonical inputs、字段模型、边界与验证方式 | `docs/releases/v0.4/prs/PR-0402-adr-infrastructure-and-metadata-contract.md` | TBD | `PR-0401` |
| T2 | Docs | 建立 `docs/architecture/adr/README.md` 主线入口，固化 authority boundary、ADR class / status 与维护规则 | `docs/architecture/adr/README.md` | TBD | T1 |
| T3 | Docs | 建立 `docs/architecture/adr/topic-map.md` header-only skeleton，定稿 17 列字段模型与 row admission rule，并为 normative backlink 补 dedicated 列 | `docs/architecture/adr/topic-map.md` | TBD | T1 |
| T4 | Docs | 定稿 retrospective metadata contract，沉淀为 PR-0402 execution artifact | `docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md` | TBD | T1 |
| T5 | Docs | 更新 PR-0402 执行日志与 governance/release 跟踪面，避免 status 分裂 | `docs/reports/v0.4/governance-execution/PR-0402/README.md`, `docs/reports/v0.4/governance-execution/README.md`, `docs/releases/v0.4/README.md` | TBD | T2-T4 |
| T6 | Verify | 运行 docs 结构检查并执行 PR-0402 的结构性校验 | `tools/ci/architecture_check.dart` | TBD | T1-T5 |

## Planned / Applied File Changes

- `[edit]` `docs/releases/v0.4/prs/PR-0402-adr-infrastructure-and-metadata-contract.md`
- `[add]` `docs/architecture/adr/README.md`
- `[add]` `docs/architecture/adr/topic-map.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`
- `[edit]` `docs/reports/v0.4/governance-execution/PR-0402/README.md`
- `[edit]` `docs/reports/v0.4/governance-execution/README.md`
- `[edit]` `docs/releases/v0.4/README.md`
- `[edit]` `docs/releases/v0.4/v0.4-kickoff.md`

## Verification

### CI gate

```bash
cd apps/lazynote_flutter/
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```powershell
# PR-0402 不应提前发布任何 ADR 正文
$adrFiles = Get-ChildItem 'docs/architecture/adr' -Filter 'ADR-*.md' -File -ErrorAction SilentlyContinue
if ($adrFiles.Count -ne 0) {
  throw "PR-0402 should not publish ADR files yet: $($adrFiles.Name -join ', ')"
}

# topic-map 必须只有表头，没有 TH 数据行
$topicRows = Get-Content 'docs/architecture/adr/topic-map.md' |
  Where-Object { $_ -match '^\| `?TH-' }
if ($topicRows.Count -ne 0) {
  throw "topic-map should be header-only in PR-0402"
}

# README / topic-map / metadata contract 的关键字段必须存在
rg -n "Purpose and Boundaries|Authority Boundary|ADR Classes and Statuses|Maintenance Rules" docs/architecture/adr/README.md
rg -n "Theme ID|Stable Why-Question|Current Normative Source|Planned ADR|Published ADR" docs/architecture/adr/topic-map.md
rg -n "Document Class|Narrative Perspective|Coverage Scope|Corpus Coverage Declaration|Revision Record" docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| mainline ADR README 与 metadata contract 用词漂移，导致 `PR-0403` 一边执行一边修规则 | HIGH | 在 `README.md`、`topic-map.md`、`adr-metadata-contract.md` 中复用同一组 class / boundary / field 名称 |
| `topic-map.md` 被过早填入候选或 working rows，污染 mainline | HIGH | 在 PR-0402 只保留 header-only skeleton，并显式要求 PR-0403 在执行目录维护 working copy |
| append-only 与 historical reconstruction 边界再次混淆 | MEDIUM | 在 `adr/README.md` 与 metadata contract 中重复声明：append-only 仅在治理激活后自动适用于 `Native ADR` |

## Exit Gate

- [x] Action 1: `docs/architecture/adr/README.md` 已建立并写明 authority boundary、ADR class / status、maintenance rule
- [x] Action 1: `docs/architecture/adr/topic-map.md` 已建立且为 header-only skeleton，包含 dedicated `Current Normative Source` 列以及 `Planned ADR` / `Published ADR` 等最小字段模型
- [x] Action 1: `docs/architecture/adr/` 目录下未提前发布任何 `ADR-000X-*.md`
- [x] Action 2: 历史补录 ADR 元数据合同已定稿为独立 execution artifact
- [x] Action 2: metadata contract 已写明 11 个 required metadata fields、5 类 corpus coverage、8 个 section skeleton、revision rule 与 theme-map alignment

---

## Reference

- [DI-19-adr-governance.md](../../../reports/v0.3/design-discussions/DI-19-adr-governance.md)
- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)
- [governance-adr-readme-skeleton.md](../../../reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md)
- [governance-adr-topic-map-skeleton.md](../../../reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md)
- [governance-adr-metadata-contract.md](../../../reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md)
- [PR-0401-source-corpus-and-dn-extraction.md](PR-0401-source-corpus-and-dn-extraction.md)
