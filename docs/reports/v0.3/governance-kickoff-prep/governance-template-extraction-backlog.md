# Governance Template Extraction Backlog

> `PR-GOV-01` 产物。本文只记录模板/`playbook` 抽离计划，
> 不提前创建稳定模板正文。

---

## Backlog Rules

1. 本清单服务于 `DI-20 / T8`，用于跟踪“哪些长期操作资产将被抽离出去”。
2. 被列入 backlog 不代表可立即创建正式模板。
3. 未经本轮真实执行验证的规则，不得提前定稿进入 `docs/development/`。
4. `Native ADR template` 在本轮中必须显式标记为 `deferred`，不能默默缺席。

---

## Backlog

| Artifact | Purpose | Planning Stage | Drafting Stage | Finalization Stage | Target Location | Current Status | Blocking Condition | Notes |
|------|------|------|------|------|------|------|------|------|
| `retrospective-reconstruction-adr-template.zh-CN.md` | 固化历史补录 ADR 的最低契约与固定段落 | `PR-GOV-02` | `PR-GOV-03` | `PR-GOV-06` | `docs/development/report-templates/` | `planned` | 需先有真实补录 ADR 样本 | 对应 `TH-001/006/007` 的首批补录 ADR 验证 |
| `governance-theme-map-template.zh-CN.md` | 固化 first-pass / approved theme map 的最小字段模型 | `PR-GOV-01` | `PR-GOV-04` | `PR-GOV-06` | `docs/development/report-templates/` | `planned` | 需先验证主题地图字段是否足够承载真实主题 | 本轮已先以执行文档方式试运行 |
| `governance-theme-delta-contract-template.zh-CN.md` | 固化 `Theme Delta Contract` 模板 | `PR-GOV-04` | `PR-GOV-04` | `PR-GOV-06` | `docs/development/report-templates/` | `planned` | 需先经过至少一轮真实 `PR-GOV` 验证 | 本轮 `PR-GOV-*` draft 正在作为试运行样本 |
| `governance-closure-audit-template.zh-CN.md` | 固化 closure audit 输出格式 | `PR-GOV-04` | `PR-GOV-05` | `PR-GOV-06` | `docs/development/report-templates/` | `planned` | 需先有真实 closure audit 产物 | 不得在 audit 前反向假定其稳定形态 |
| `governance-activation-template.zh-CN.md` | 固化治理激活与 append-only 生效声明 | `PR-GOV-05` | `PR-GOV-05` | `PR-GOV-06` | `docs/development/report-templates/` | `planned` | 需先明确 activation 文档结构 | 与 Native ADR 模板不同 |
| `governance-playbook.md` | 未来治理执行时的稳定操作入口 | `PR-GOV-05` | `PR-GOV-06` | `PR-GOV-06` | `docs/development/` | `planned` | 需先完成本轮治理执行并闭合 | 不得替代 `Ruling` 或治理裁决文本 |
| `native-adr-template.zh-CN.md` | 治理激活后新生 `Native ADR` 的模板 | `post-activation follow-up` | `post-activation follow-up` | `post-activation follow-up` | `docs/development/report-templates/` | `deferred` | 本轮 `PR-GOV-01 ~ 06` 未经历真实 Native ADR 流程 | 已在 `DI-20` 中显式登记为 deferred |

---

## Current Backlog Conclusion

1. 当前 backlog 中，`governance-theme-map-template`、`governance-theme-delta-contract-template`、`governance-closure-audit-template`、`governance-activation-template` 都已经具备 prep 层草案壳，但仍未经过真实主线执行验证。
2. 它们现在只适合做 kickoff 输入审查，不应被误读为 stable template。
3. `native-adr-template.zh-CN.md` 明确不属于当前 `PR-GOV-01 ~ 06` 的收口范围。
