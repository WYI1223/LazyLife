# PR-0402: ADR 基础设施与元数据合同

| 项目 | 值 |
|------|-----|
| **状态** | DRAFT |
| **主题覆盖** | `T1`, `T2`, `T3` |
| **依赖** | `PR-0401` |
| **关联** | [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

建立 ADR 层的接收结构与历史补录元数据合同，为 PR-0403 的 per-ADR 串行全链执行
提供基础设施。本 PR 不预设 TH 占位或 ADR Slot，这些由 PR-0403 的 per-ADR
classification 自然产生。

---

## Scope

### In Scope

1. **Action 1: 建立 `docs/architecture/adr/` 目录结构**
2. **Action 2: 定稿历史补录 ADR 元数据合同**

### Out of Scope

1. Theme Map 条目创建（由 PR-0403 classification 产生）
2. ADR Slot / Carrier State 占位（由 PR-0403 自然产生）
3. ADR 正文编写
4. DN classification

---

## Actions Detail

### Action 1: 建立 `docs/architecture/adr/` 目录结构

产出物：
- `docs/architecture/adr/README.md` — 治理规则摘要、ADR 状态定义（`draft` / `active` / `superseded` / `deprecated`）、与 rulings 的关系说明
- `docs/architecture/adr/topic-map.md` — Theme Map 表头（使用 DI-20 T4 最小字段模型），初始无数据行

消费输入：
- `governance-adr-readme-skeleton.md`（prep 层骨架）
- `governance-adr-topic-map-skeleton.md`（prep 层骨架）

### Action 2: 定稿历史补录 ADR 元数据合同

产出物：历史补录 ADR 的最终元数据字段集与标准声明措辞

确认以下 7 项必填元数据：
1. `Document Class`: `Retrospective Reconstruction ADR`
2. `Narrative Perspective`: 未来视角重述声明
3. `Decision Line`: 本文回答的稳定 why-question
4. `Coverage Scope`: 覆盖阶段与止点
5. `Current Normative Source`: rebuilt current-effective source
6. `Source Corpus Summary`: 关键来源
7. `Revision Record`: 修订记录

确认 Corpus Coverage Declaration（4 类 `present / absent / not applicable`）：
- `Trigger Source`
- `Decision Source`
- `Execution / Closure Source`
- `Superseded / Redirected Source`

确认正文必备章节：
- `Reconstruction Notice`
- `Decision Line`
- `Source Corpus`
- `Journey Timeline / Phases`
- `Current State`
- `Open Edges`
- `Revision Record`

本 Action 同时作为 `retrospective-reconstruction-adr-template.zh-CN.md` 的规划阶段输出
（对应 DI-20 Q5 模板抽离计划）：元数据合同定义 what fields/sections are required，
模板是合同的可执行骨架（fillable markdown structure），起草由 PR-0403 负责，定稿由 PR-0406 负责。

变更约束：元数据合同定稿后，若 PR-0403 执行中发现合同不足（字段缺失、章节结构
无法承载实际内容等），须暂停流程并显式声明 deviation，而非静默回改 PR-0402 产出物。

消费输入：
- `governance-adr-metadata-contract.md`（prep 层筹备）
- DI-20 T3 当前裁决补充

---

## Deliverables

| Action | 产出物 | 存放路径 |
|--------|--------|----------|
| 1 | `adr/README.md` + `adr/topic-map.md` | `docs/architecture/adr/` |
| 2 | 元数据合同定稿 | `docs/reports/v0.4/governance-execution/PR-0402/` |

---

## Exit Gate

- [ ] Action 1: `docs/architecture/adr/` 目录结构与 `README.md` 已建立
- [ ] Action 1: `adr/topic-map.md` 空骨架已建立（有 Theme Map 表头，无数据行）
- [ ] Action 2: 历史补录 ADR 的元数据合同已定稿

---

## Reference

- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)（T1/T3 裁决补充）
- [governance-adr-metadata-contract.md](../../../reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md)（prep 层筹备）
- [governance-adr-readme-skeleton.md](../../../reports/v0.3/governance-kickoff-prep/governance-adr-readme-skeleton.md)（prep 层骨架）
- [governance-adr-topic-map-skeleton.md](../../../reports/v0.3/governance-kickoff-prep/governance-adr-topic-map-skeleton.md)（prep 层骨架）
- [PR-0401-source-corpus-and-dn-extraction.md](PR-0401-source-corpus-and-dn-extraction.md)（前置依赖）
