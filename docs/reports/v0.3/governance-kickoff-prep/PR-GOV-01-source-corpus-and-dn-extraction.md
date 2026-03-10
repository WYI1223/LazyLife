# PR-GOV-01: Source Corpus 盘点与 DN Extraction

| 项目 | 值 |
|------|-----|
| **状态** | DRAFT |
| **主题覆盖** | `T3`, `T4`, `T7` |
| **依赖** | `PR-GOV-00` |
| **关联** | [DI-20-governance-execution-plan.md](../design-discussions/DI-20-governance-execution-plan.md) |

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
5. **Action 4: Template Extraction Backlog** — 确认 PR-GOV-01 规划阶段的 3 项模板，补录遗漏项

### Out of Scope

1. DN classification（`classification` 阶段字段留空，由 PR-GOV-03 填入）
2. Theme Map 条目创建（由 PR-GOV-03 per-ADR classification 自然产生）
3. 创建模板正文（仅确认清单）
4. 跨文档 DN→DN 语义关系（留给 classification 阶段）
5. ADR 正文编写

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
- legacy rulings 不进入 inventory（已由 PR-GOV-00 归档）

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

确认 PR-GOV-01 规划阶段负责的 3 项模板是否成立：
- `governance-source-corpus-inventory-template.zh-CN.md`
- `governance-decision-node-ledger-template.zh-CN.md`
- `governance-theme-map-template.zh-CN.md`

若 Actions 1-3 执行中发现遗漏的模板需求，记录为新增项。

---

## Deliverables

所有产出物存放于 `docs/reports/v0.4/governance-execution/PR-GOV-01/`。

| Action | 产出物 | 存放路径 |
|--------|--------|----------|
| 1 | `document-inventory.md` | `PR-GOV-01/` |
| 2a | `DOC-xxx-survey.md` | `PR-GOV-01/surveys/` |
| 2b | `dn-ledger.md` | `PR-GOV-01/` |
| 3 | `coverage-matrix.md` | `PR-GOV-01/` |
| 4 | `template-extraction-backlog.md` | `PR-GOV-01/` |

---

## Exit Gate

- [ ] Action 1: Document Inventory 完成且有稳定 `DOC-xxx` 清单
- [ ] Action 2a: 每个 `DOC-xxx` 的 Document Structure Survey 已完成
- [ ] Action 2b: Decision Node Ledger 已建立并完成 first-pass DN extraction（仅 extraction 阶段字段）
- [ ] Action 3: Coverage Matrix 基线已建立
- [ ] Action 4: PR-GOV-01 规划阶段的 3 项模板已确认，遗漏项已补录

---

## Reference

- [DI-20-governance-execution-plan.md](../design-discussions/DI-20-governance-execution-plan.md)（T4 最小数据模型 + PR-GOV-01 Actions 汇总）
- governance-templates/README.md（模板索引，planned, not yet created）
- [PR-GOV-00-legacy-rulings-archive.md](PR-GOV-00-legacy-rulings-archive.md)（前置依赖）
