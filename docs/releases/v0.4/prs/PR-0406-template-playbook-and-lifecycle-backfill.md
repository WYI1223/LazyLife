# PR-0406: 模板、Playbook 与 Lifecycle 回填

| 项目 | 值 |
|------|-----|
| **状态** | DRAFT |
| **主题覆盖** | `T5`, `T8` |
| **依赖** | `PR-0405` |
| **关联** | [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

在治理激活完成且 Closure Audit Output 未显示阻断级失败后，将本轮治理执行中
已验证的稳定流程回填到长期操作资产中。本 PR 只沉淀经执行验证过的部分，不把
仍处于实验态的规则提前模板化。

---

## Scope

### In Scope

1. **Action 1: 稳定模板定稿与沉淀**
2. **Action 2: Governance Playbook 起草与定稿**
3. **Action 3: Lifecycle Template 回填**

### Out of Scope

1. Native ADR template（显式 deferred，需至少经历一轮真实 Native ADR 工作流后
   再作为 post-activation follow-up 单独规划）
2. 未经本轮执行验证的实验规则
3. 修改已激活的历史补录 ADR（已冻结但可勘误）
4. 重新裁决治理规则（应通过 Native ADR / 新 DI 处理）

---

## Actions Detail

### Action 1: 稳定模板定稿与沉淀

将 PR-0404 起草的模板草稿与 PR-0405 验证过的审计/激活模板定稿，
沉淀到 `docs/development/report-templates/`：

定稿候选（按 DI-20 Q5 模板抽离计划）：
- `retrospective-reconstruction-adr-template.zh-CN.md`
- `governance-source-corpus-inventory-template.zh-CN.md`
- `governance-decision-node-ledger-template.zh-CN.md`
- `governance-theme-map-template.zh-CN.md`
- `governance-theme-delta-contract-template.zh-CN.md`
- `governance-closure-audit-template.zh-CN.md`

定稿约束：
- 只定稿经本轮执行验证的部分
- 若某模板在执行中未被充分验证，保留为草稿态并记录原因
- 定稿内容必须与本轮治理执行经验一致

### Action 2: Governance Playbook 起草与定稿

基于 PR-0405 确认的边界与已闭合的执行经验，起草并定稿 `governance-playbook.md`：

必备章节（按 DI-20 Q5 骨架）：
1. Purpose and Boundaries
2. Trigger Conditions
3. Required Roles
4. Workflow Overview
5. Required Artifacts
6. Gates and Sign-off
7. Allowed Exceptions
8. Template Index
9. Reference Documents

Playbook 约束：
- 只回答"何时触发、先做什么、用什么模板、经过哪些 gate、由谁 sign-off"
- 不重写 DI-19 规则正文，不重写 DI-20 版本上下文
- 规则涉及治理边界/例外/生效范围时，只做摘要并回链相关治理裁决文档
- 不包含本轮尚未验证的实验规则
- 不替代 Ruling 作为规范源

目标位置：`docs/development/governance-playbook.md`

### Action 3: Lifecycle Template 回填

将已验证的治理流程要点回填到 `release-lifecycle-template.md`：
- ADR 治理义务的版本级检查项
- Theme Delta Contract 的 PR 级提醒
- 收口审计的版本级触发条件

回填约束：
- 回填内容必须来自已验证执行经验
- 不超前引入未经本轮验证的规则
- 回填格式与现有 lifecycle template 风格一致

---

## Deliverables

产出物存放路径因模板沉淀分为两部分：

| Action | 产出物 | 存放路径 |
|--------|--------|----------|
| 1 | 定稿模板（最多 6 份） | `docs/development/report-templates/` |
| 2 | `governance-playbook.md` | `docs/development/` |
| 3 | `release-lifecycle-template.md` 更新 | 原位更新 |
| — | 执行记录 | `docs/reports/v0.4/governance-execution/PR-0406/` |

---

## Exit Gate

- [ ] Lifecycle/template 仅回填已验证过的流程
- [ ] 计划抽离的模板与 playbook 仅定稿已被本轮执行验证过的部分
- [ ] 回填内容与本轮治理执行经验一致
- [ ] 未把仍处于实验态的规则提前模板化
- [ ] Native ADR template 已显式标记为 deferred

---

## Reference

- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)（T5/T8 裁决 + Q5 模板抽离计划 + playbook 骨架）
- [governance-template-drafts.md](../../../reports/v0.3/governance-kickoff-prep/governance-template-drafts.md)（prep 层草案集合）
- governance-templates/playbook-seed.md（prep 层 playbook seed，planned, not yet created）
- [PR-0405-closure-audit-and-governance-activation.md](PR-0405-closure-audit-and-governance-activation.md)（治理激活来源 + playbook 边界确认）
