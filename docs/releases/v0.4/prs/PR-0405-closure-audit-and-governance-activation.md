# PR-0405: 收口审计与治理激活

| 项目 | 值 |
|------|-----|
| **状态** | DRAFT |
| **主题覆盖** | `T2`, `T6`, `T7` |
| **依赖** | `PR-0404` |
| **关联** | [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

在 PR-0404 完成一致性审计与合同定稿后，出具正式的 Closure Audit Output，
确认所有治理主题已闭合覆盖，并声明治理激活点——从该点开始，Native ADR 受
append-only 约束，历史补录 ADR 进入"冻结但可勘误"状态。

---

## Scope

### In Scope

1. **Action 1: Repo-wide 收口审计**
2. **Action 2: Closure Audit Output 出具**
3. **Action 3: 治理激活文档起草**
4. **Action 4: Playbook 边界确认**

### Out of Scope

1. 模板正文定稿与沉淀（由 PR-0406 负责）
2. Playbook 正文起草（由 PR-0406 负责）
3. 新增 ADR 或修改已有 ADR 正文
4. lifecycle template 回填

---

## Actions Detail

### Action 1: Repo-wide 收口审计

基于 PR-0404 的审计基线，执行最终收口审计：

1. 验证 `T0-T8` 全部主题至少被一个 PR 覆盖且有主责任 PR
2. 验证每个治理 PR 都包含 Theme Delta Contract
3. 验证首批历史补录 ADR 已标注"未来视角重述"与 source corpus
4. 收口 PR-0404 Semantic Review open items（structural / graph / policy 已在 PR-0404 内 pass，
   Semantic Review 遗留 open items 由本 Action 负责最终判定：处理、记录为 debt 或升级）
5. 确认 DI-20 Q4 收口标准全部满足

### Action 2: Closure Audit Output 出具

按 DI-20 T6 裁决，出具正式 Closure Audit Output，至少记录：
- 各 gate（structural / graph / policy / semantic review）的 pass / fail 结果
- 例外项与理由
- 已接受 debt 与 owner
- 尚未闭合的语义判断
- 是否满足治理激活前提

本 Action 同时作为 `governance-closure-audit-template.zh-CN.md` 的起草阶段输出
（对应 DI-20 Q5 模板抽离计划，PR-0404 规划）：通过实际出具 Closure Audit Output
验证模板的字段模型与章节结构，定稿由 PR-0406 负责。

消费输入：
- `governance-closure-audit-output.md`（prep 层草稿壳）
- PR-0404 Consistency Audit Report + closure-audit-template 规划

### Action 3: 治理激活文档起草

起草治理激活声明，明确：
- append-only 生效点（从何时开始 Native ADR 受约束）
- 历史补录 ADR 的"冻结但可勘误"状态定义
- Phase B（governance migration window）结束条件
- Phase C（post-activation governance）开始条件
- T2 authority matrix 在激活后的适用规则

消费输入：
- `governance-activation-draft.md`（prep 层草稿）
- DI-20 T2 当前裁决补充（Phase A/B/C 定义）

### Action 4: Playbook 边界确认

确认 future `governance-playbook.md` 的边界与入口动作：
- 确认 playbook 章节骨架（9 项）是否需要调整
- 确认 playbook 与 DI-20 的职责分界
- 确认 playbook 引用关系（指向 Ruling / ADR / DI）
- 不起草 playbook 正文（由 PR-0406 负责）

---

## Deliverables

产出物存放于 `docs/reports/v0.4/governance-execution/PR-0405/`。

| Action | 产出物 | 说明 |
|--------|--------|------|
| 1 | 收口审计工作记录 | T0-T8 覆盖验证 + 问题处理记录 |
| 2 | Closure Audit Output | 正式收口审计报告 |
| 3 | 治理激活文档草稿 | append-only 生效点声明 + Phase B/C 边界 |
| 4 | Playbook 边界确认记录 | 章节骨架 + 职责分界 + 引用关系确认 |

---

## Exit Gate

- [ ] Repo-wide 一致性审计已执行（基于 PR-0404 基线的最终收口）
- [ ] Closure Audit Output 已出具
- [ ] 例外项、debt、未闭合判断已显式记录
- [ ] 治理激活文档已明确 append-only 生效点
- [ ] Closure Audit Output 未显示阻断级失败（PR-0406 准入条件）
- [ ] Playbook 边界已确认（章节骨架 + 引用关系）

---

## Reference

- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)（T2/T6/T7 裁决 + Q4 收口标准）
- [governance-closure-audit-output.md](../../../reports/v0.3/governance-kickoff-prep/governance-closure-audit-output.md)（prep 层草稿壳）
- [governance-activation-draft.md](../../../reports/v0.3/governance-kickoff-prep/governance-activation-draft.md)（prep 层草稿）
- [PR-0401-source-corpus-and-dn-extraction.md](PR-0401-source-corpus-and-dn-extraction.md)（T0-T8 全覆盖验证涉及全部前序产出物）
- [PR-0404-theme-delta-contract-and-consistency-audit.md](PR-0404-theme-delta-contract-and-consistency-audit.md)（审计基线 + Semantic Review open items 来源）
