# PR-0401: Source Corpus 盘点与 DN Extraction

- Proposed title: `docs(governance): establish source corpus inventory and first-pass DN ledger baseline`
- Execution status: In Progress
- Spec review status: Review-clean (`docs/releases/v0.4/pr-spec-review-resolution.md`)

| 项目 | 值 |
|------|-----|
| **执行状态** | IN PROGRESS |
| **规格评审状态** | Review-clean |
| **主题覆盖** | `T3`, `T4`, `T7` |
| **依赖** | `PR-0400` |
| **关联** | [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

在 legacy rulings 归档完成后，对全量 source corpus 进行结构化盘点，建立 Document Inventory
和 Decision Node Ledger，为后续 per-ADR 全链执行提供统一基线。

---

## Scope

### In Scope

1. **Action 1: Document Inventory** — 全量文档盘点，建立 `DOC-xxx` 稳定清单
2. **Action 2a: Document Structure Survey** — 对每个 `DOC-xxx` 独立执行内部结构分析
3. **Action 2b: DN Extraction** — 从每个文档抽取条款级决策节点，仅填 extraction 阶段字段
4. **Action 3: Coverage Matrix** — 建立执行进度视图，记录每个文档的 survey / extraction 完成状态
5. **Action 4: Template Extraction Backlog** — 确认 PR-0401 规划阶段的 3 项模板，补录遗漏项

### Out of Scope

1. DN classification（`classification` 阶段字段留空，由 PR-0403 填入）
2. Theme Map 条目创建（由 PR-0403 per-ADR classification 自然产生）
3. 创建模板正文（仅确认清单）
4. 跨文档 DN→DN 语义关系（留给 classification 阶段）
5. ADR 正文编写

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| 历史审计链 | `docs/reports/v0.2.5/frontend-review/08a-audit-findings.md` 至 `09-acceptance-report.md` | 提供 trigger / decision / execution / closure 基线 |
| v0.3 文档治理链 | `docs/releases/v0.3/prs/PR-RB-00-doc-fixes.md`, `docs/releases/v0.3/v0.3-release-evidence.md` | 提供 ADR→Ruling 演进、release closure 与 handoff 边界 |
| 设计讨论主链 | `docs/reports/v0.3/design-discussions/DI-0` 至 `DI-21` | 必须按顺序纳入 source corpus；`DI-9` 作为缺失槽位显式记录 |
| 治理执行裁决 | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | 提供 T4 的最小字段模型、source corpus / decision line 抽取规则 |
| 前置主线 PR | `docs/releases/v0.4/prs/PR-0400-legacy-rulings-archive.md` | legacy snapshot 已归档，为 source corpus 范围提供边界 |

## Source Corpus Baseline

PR-0401 的主线 source corpus 按以下顺序建立：

1. `08a` → `08b` → `08c` → `08d` → `09`
2. `PR-RB-00-doc-fixes.md`
3. `v0.3-release-evidence.md`
4. `DI-0` → `DI-21`（按编号顺序逐项写入）

补充边界：

- `DI-9` 当前无实体文件，必须作为缺失槽位写入 inventory，不能静默跳过。
- `docs/architecture/rulings-legacy/` 不进入主 inventory 行，但允许在 `Notes` / `Current Normative Anchor` 中作为当前规范锚点引用。
- `DI-0~DI-21` 的顺序要求高于“只挑已 resolved 的文档”；`pending` / `deferred` / `in_progress` 项同样必须入表。

---

## Execution Model

- **全局步骤**：Action 1（Document Inventory，一次性）
- **Per-document 串行步骤**：Action 2a（Survey）→ Action 2b（DN Extraction），完成一个文档后再进入下一个
- **全局收尾步骤**：Action 3（Coverage Matrix）+ Action 4（Template Backlog）
- Per-document 步骤之间必须完全独立，不允许在抽取 A 文档时引用 B 文档的抽取结果
- DN extraction 按 Document Inventory 的 Time Position 顺序执行
- 跨文档语义冲突不是边界问题，而是决策演进的正常表现

---

## Actions Detail

### Action 1: Document Inventory

产出物：`document-inventory.md`

字段模型：`Doc ID` / `Path` / `Doc Class` / `Corpus Role` / `Time Position` / `Normative Status` / `Extracted DN IDs` / `Notes`

- `Doc ID` 使用 `DOC-xxx` 命名空间
- `Normative Status`：`historical` / `current_effective` / `deferred` / `pending`
- `Normative Status` 映射按以下优先级执行：
  - 角色覆盖优先：仅对被 PR-0401 明确指定为当前治理执行权威输入的文档赋值 `current_effective`；当前范围仅限 `DI-19` / `DI-20`，该值不是源文档头部状态的直接拷贝
  - 其余文档按权威状态源映射：文档头部状态优先于 `docs/reports/v0.3/design-discussions/README.md` 索引；若头部缺失或非标准，再回退到索引状态
  - `RESOLVED` / `APPLIED` -> `historical`
  - `OPEN` / `PENDING` / `IN PROGRESS` -> `pending`
  - `DEFERRED*` 或缺失槽位 -> `deferred`
  - 若文档头部与索引状态冲突，`Normative Status` 采用头部映射结果，并在 `Notes` 中显式记录冲突
- `DI-0` 至 `DI-21` 必须按编号顺序连续入表；`DI-9` 使用缺失槽位占位
- legacy rulings 不进入 inventory 主表（已由 PR-0400 归档），但可在 `Notes` 中声明 current normative anchor

### Action 2a: Document Structure Survey

产出物：`surveys/DOC-xxx-survey.md`（每文档一份）

参考模板：`governance-templates/01-dn-extraction/document-structure-survey-template.md`

### Action 2b: DN Extraction

产出物：`dn-ledger.md`（全局汇总）

仅填 extraction 阶段字段（8 项）：`DN ID` / `Decision Tier` / `Source Doc ID` / `Source Anchor` / `Node Role` / `Statement` / `Effective Status` / `Notes`

classification 阶段字段（9 项）标记为 `pending`。

参考模板：`governance-templates/01-dn-extraction/dn-extraction-sop-template.md`

### Action 3: Coverage Matrix

产出物：`coverage-matrix.md`

字段模型：`Doc ID` / `Doc Title` / `Survey Status` / `DN Extraction Status` / `Extracted DN Count` / `Notes`

- `Notes` 列承载 `missing_source` / `scope_overflow` 等少量边界备注
- 是 Document Inventory 的执行进度视图，不重复内容字段

### Action 4: Template Extraction Backlog

产出物：`template-extraction-backlog.md`

确认 PR-0401 规划阶段负责的 3 项模板是否成立：
- `governance-source-corpus-inventory-template.zh-CN.md`
- `governance-decision-node-ledger-template.zh-CN.md`
- `governance-theme-map-template.zh-CN.md`

若 Actions 1-3 执行中发现遗漏的模板需求，记录为新增项。

---

## Deliverables

所有产出物存放于 `docs/reports/v0.4/governance-execution/PR-0401/`。

| Action | 产出物 | 存放路径 |
|--------|--------|----------|
| 1 | `document-inventory.md` | `PR-0401/` |
| 2a | `DOC-xxx-survey.md` | `PR-0401/surveys/` |
| 2b | `dn-ledger.md` | `PR-0401/` |
| 3 | `coverage-matrix.md` | `PR-0401/` |
| 4 | `template-extraction-backlog.md` | `PR-0401/` |

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Docs | 将 PR-0401 spec 补全为可执行合同，写明 expanded source corpus 与 DI-0~DI-21 顺序要求 | `docs/releases/v0.4/prs/PR-0401-source-corpus-and-dn-extraction.md` | TBD | — |
| T2 | Docs | 建立 `document-inventory.md`，覆盖 08a-09、PR-RB-00、release evidence、DI-0~DI-21（含 DI-9 占位） | `docs/reports/v0.4/governance-execution/PR-0401/document-inventory.md` | TBD | T1 |
| T3 | Docs | 建立 `coverage-matrix.md`，按 inventory 同步 survey / extraction 进度 | `docs/reports/v0.4/governance-execution/PR-0401/coverage-matrix.md` | TBD | T2 |
| T4 | Docs | 建立 `template-extraction-backlog.md`，确认 3 项计划模板并补录 survey / extraction SOP 缺口 | `docs/reports/v0.4/governance-execution/PR-0401/template-extraction-backlog.md` | TBD | T2 |
| T5 | Docs | 初始化 `dn-ledger.md`，先落第一批治理核心文档的 extraction seed | `docs/reports/v0.4/governance-execution/PR-0401/dn-ledger.md` | TBD | T2 |
| T6 | Docs | 更新 `PR-0401/README.md` 执行日志，记录已落地范围与待继续项 | `docs/reports/v0.4/governance-execution/PR-0401/README.md` | TBD | T2-T5 |
| T7 | Verify | 运行 docs 结构检查，确认新增执行物无 broken links | `tools/ci/architecture_check.dart` | TBD | T1-T6 |

## Planned File Changes

- `[edit]` `docs/releases/v0.4/prs/PR-0401-source-corpus-and-dn-extraction.md`
- `[edit]` `docs/reports/v0.4/governance-execution/PR-0401/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0401/document-inventory.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0401/coverage-matrix.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0401/template-extraction-backlog.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0401/dn-ledger.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0401/surveys/README.md`
- `[add]` initial survey files under `docs/reports/v0.4/governance-execution/PR-0401/surveys/`

## Verification

### CI gates

```bash
cd apps/lazynote_flutter/
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```powershell
# inventory 中 DI-0 ~ DI-21 必须连续且按序出现
$diRows = Get-Content 'docs/reports/v0.4/governance-execution/PR-0401/document-inventory.md' |
  Where-Object { $_ -match '^\| `DOC-0(0[89]|1[0-9]|2[0-9])` \|' } |
  ForEach-Object {
    if ($_ -match '\| `[^`]* / DI-(\d+)` \|') { [int]$matches[1] }
  }
$expected = 0..21
if (($diRows -join ',') -ne ($expected -join ',')) {
  throw "DI chain mismatch: $($diRows -join ',')"
}

# 缺失槽位 DI-9 必须显式存在
rg -n "DI-9|缺失槽位|missing slot" docs/reports/v0.4/governance-execution/PR-0401/document-inventory.md docs/reports/v0.4/governance-execution/PR-0401/coverage-matrix.md
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| source corpus 只覆盖治理链，遗漏 DI-0~DI-18 的历史设计上下文 | HIGH | 将 `DI-0~DI-21` 作为顺序主链整体纳入 inventory |
| `DI-9` 无文件导致后续执行误以为链条完整 | MEDIUM | 在 inventory / coverage matrix 中显式写为缺失槽位 |
| 旧 prep 产物与 mainline 命名不一致 | MEDIUM | PR-0401 仅在 `docs/reports/v0.4/governance-execution/PR-0401/` 产出主线版本，prep 仅作输入 |

## Exit Gate

- [ ] Action 1: Document Inventory 完成且有稳定 `DOC-xxx` 清单
- [ ] Action 2a: 每个 `DOC-xxx` 的 Document Structure Survey 已完成
- [ ] Action 2b: Decision Node Ledger 已建立并完成 first-pass DN extraction（仅 extraction 阶段字段）
- [ ] Action 3: Coverage Matrix 基线已建立
- [ ] Action 4: PR-0401 规划阶段的 3 项模板已确认，遗漏项已补录

---

## Reference

- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)（T4 最小数据模型 + PR-0401 Actions 汇总）
- governance-templates/README.md（模板索引，planned, not yet created）
- [PR-0400-legacy-rulings-archive.md](PR-0400-legacy-rulings-archive.md)（前置依赖）
