# PR-GOV-04: Theme Delta Contract 定稿与 Repo-wide 一致性审计

| 项目 | 值 |
|------|-----|
| **状态** | DRAFT |
| **主题覆盖** | `T5`, `T6` |
| **依赖** | `PR-GOV-02`, `PR-GOV-03` |
| **关联** | [DI-20-governance-execution-plan.md](../design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

在 PR-GOV-03 完成 per-ADR 串行全链执行后，基于实际执行经验定稿 Theme Delta Contract
模型，并执行 repo-wide 一致性审计，验证跨 ADR 的结构、图、政策与 DN→DN 关系完整性。

本 PR 不发明新规则，而是把 PR-GOV-03 实际验证过的执行模式固化为可复用的合同模型
与审计规则。

---

## Scope

### In Scope

1. **Action 1: Theme Delta Contract 模型定稿**
2. **Action 2: Repo-wide 一致性审计**
3. **Action 3: 索引同步策略形成**
4. **Action 4: 执行模板起草**

### Out of Scope

1. 新增 ADR 或修改已有 ADR 正文（由 PR-GOV-03 负责）
2. 治理激活声明（由 PR-GOV-05 负责）
3. 模板最终定稿与沉淀到 `docs/development/report-templates/`（由 PR-GOV-06 负责）
4. `Semantic Review` 的最终 sign-off（仍为人工 gate）

---

## Actions Detail

### Action 1: Theme Delta Contract 模型定稿

基于 PR-GOV-03 实际执行经验，将 prep 层的 `governance-theme-delta-contract-model.md`
定稿为可执行的合同模型。

确认项：
- 全局合同字段（13 项）是否完整且可操作
- 行级 delta 字段（7 项）是否足以覆盖实际执行场景
- Operation Catalog 是否需要补充新操作类型
- Anti-downgrade hooks 是否有效识别了语义降级

消费输入：
- `governance-theme-delta-contract-model.md`（prep 层模型）
- PR-GOV-03 各 iteration 的实际 theme delta 记录

### Action 2: Repo-wide 一致性审计

按 DI-20 T6 裁决的四层检查模型，对 PR-GOV-01~03 全部产出执行跨阶段、跨 ADR 审计：

1. **Structural Checks**：链接不悬挂、必填字段非空、状态词合法、必要章节存在
2. **Graph Checks**：
   - 每个 `TH-xxx` 真实存在于 topic-map
   - `DN → DN` 语义关系边端点真实存在
   - `Doc → DN → TH` 三层映射自洽
   - 依赖边保持有向无环
   - 无 orphan theme / orphan ADR / orphan PR delta
3. **Policy Checks**：
   - `adr_carrier_update` 同步更新 `Current Status` / `ADR Carrier State` / `ADR Carrier Reference`
   - `split / merge / supersede / redirect` 同步更新主题地图关系字段
   - `Docs Touched` 能在输出文档中找到对应落点
4. **Semantic Review**（人工 gate，由 governance owner 在 PR-GOV-04 内执行；
   structural / graph / policy 必须 pass，Semantic Review 允许产出 open items，
   显式记录在 Consistency Audit Report 中，传递给 PR-GOV-05 收口）

审计范围覆盖 PR-GOV-01~03 全部产出物：
- PR-GOV-01/：Document Inventory + DN Ledger（extraction 原始版）+ Coverage Matrix
- PR-GOV-03/：DN Ledger（classification 版）+ topic-map working copy + per-iteration run records + ADR + ruling updates
- 跨阶段一致性：extraction 版与 classification 版的 DN 字段不冲突

消费输入：
- `governance-backlink-rules.md`（prep 层回链规则）
- `governance-check-model.md`（prep 层检查模型）

### Action 3: 索引同步策略形成

基于审计结果，形成索引同步的可执行规则：
- `adr/topic-map.md` 与 DN Ledger 的同步频率与触发点
- `docs/index.md` 与 `adr/README.md` 的回链维护规则
- PR spec 中 `Output Docs` 与实际产出的一致性检查规则

### Action 4: 模板审计确认与规划

按 DI-20 Q5 模板抽离计划，对前序阶段已验证的模板字段模型进行审计确认，并规划后续模板：

**审计确认**（字段模型已被前序阶段执行验证，确认完整性 + 补漏）：
- `governance-source-corpus-inventory-template.zh-CN.md`（PR-GOV-01 规划 + 使用）
- `governance-decision-node-ledger-template.zh-CN.md`（PR-GOV-01 规划 + PR-GOV-03 classification 填充）
- `governance-theme-map-template.zh-CN.md`（PR-GOV-01 规划 + PR-GOV-03 TH 填充）

**已由 Action 1 覆盖**：
- `governance-theme-delta-contract-template.zh-CN.md`（Action 1 模型定稿即为该模板的起草产出）

**规划**（确认字段与章节结构，不写正文，起草由 PR-GOV-05 负责）：
- `governance-closure-audit-template.zh-CN.md`

---

## Deliverables

产出物存放于 `docs/reports/v0.4/governance-execution/PR-GOV-04/`。

| Action | 产出物 | 说明 |
|--------|--------|------|
| 1 | Theme Delta Contract 定稿文档 | 基于执行经验的最终合同模型（同时覆盖 theme-delta-contract-template 起草） |
| 2 | Consistency Audit Report | 四层检查结果 + Semantic Review open items（传递给 PR-GOV-05） |
| 3 | Index Sync Strategy | 索引同步可执行规则 |
| 4 | 模板审计确认记录 + closure-audit-template 规划 | 3 份字段确认 + 1 份规划，不沉淀到 `docs/development/` |

---

## Exit Gate

- [ ] Theme Delta Contract 模型基于 PR-GOV-03 实际执行经验定稿
- [ ] Repo-wide 一致性审计已执行（跨 ADR 结构/图/政策检查）
- [ ] 跨 ADR 的 DN→DN 关系完整性已验证
- [ ] 索引同步策略形成可执行规则
- [ ] 前序模板字段模型审计确认完成（3 份）
- [ ] closure-audit-template 规划完成（字段与章节结构确认）

---

## Reference

- [DI-20-governance-execution-plan.md](../design-discussions/DI-20-governance-execution-plan.md)（T5/T6 裁决 + 四层检查模型）
- [governance-theme-delta-contract-model.md](governance-theme-delta-contract-model.md)（prep 层合同模型）
- [governance-backlink-rules.md](governance-backlink-rules.md)（prep 层回链规则）
- [governance-check-model.md](governance-check-model.md)（prep 层检查模型）
- [PR-GOV-01-source-corpus-and-dn-extraction.md](PR-GOV-01-source-corpus-and-dn-extraction.md)（Action 2 审计范围覆盖其 Document Inventory + DN Ledger extraction 版 + Coverage Matrix）
- [PR-GOV-03-per-adr-serial-execution.md](PR-GOV-03-per-adr-serial-execution.md)（执行产出来源）
