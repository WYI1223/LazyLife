# Governance Kickoff Readiness Matrix

> 汇总 `PR-GOV-01 ~ PR-GOV-06` 作为 future `v0.4 kickoff` 输入时所需的最小条件。
> 本文不扩展 PR 状态机；这些 spec 当前保持 `Draft`，`Ready for Kickoff Input`
> 仅作为筹备结论使用，不表示 PR 已进入正式实现。

---

## Readiness Rules

每个 `PR-GOV-*` 文档只有在其内部 `Kickoff Prep Readiness Review` 满足以下条件时，
才可将 verdict 置为 `Ready for Kickoff Input`：

1. 关键输入与边界已冻结到 spec 级
2. 计划输出文档已存在，或已被明确收敛为 prep 层固定目标
3. Verification 可对真实 prep 层目标文件执行
4. future mainline 动作已被显式后置，而不是被误当作当前 blocker
5. Required sign-off 已完成，或已明确 deferred 到 kickoff

若以上任一条件不满足，则 verdict 必须保持 `Blocked`。

---

## Matrix

| PR | Spec | Current Status | Readiness Verdict | Dependency Gate | Primary Blockers | PR Executor | Last Reviewed |
|----|------|----------------|-------------------|-----------------|------------------|-------------|---------------|
| `PR-GOV-01` | [PR-GOV-01-source-corpus-and-theme-map-baseline.md](PR-GOV-01-source-corpus-and-theme-map-baseline.md) | `Draft` | `Ready for Kickoff Input` | `N/A` | `None`；仅保留 future kickoff 时再确认的 owner / sign-off | `TBD (during v0.4 kickoff)` | `2026-03-06` |
| `PR-GOV-02` | [PR-GOV-02-adr-structure-and-metadata-contract.md](PR-GOV-02-adr-structure-and-metadata-contract.md) | `Draft` | `Ready for Kickoff Input` | `PR-GOV-01 exit gate` | `None`；formal `docs/architecture/adr/*` 资产已明确后置到 future kickoff mainline，不再构成 prep blocker | `TBD (during v0.4 kickoff)` | `2026-03-06` |
| `PR-GOV-03` | [PR-GOV-03-first-batch-retrospective-adrs.md](PR-GOV-03-first-batch-retrospective-adrs.md) | `Draft` | `Blocked` | `PR-GOV-02 exit gate` | 首批主题未确认；`ADR-000X-<slug>-draft.md` 仍为占位 | `TBD (during v0.4 kickoff)` | `2026-03-06` |
| `PR-GOV-04` | [PR-GOV-04-contracts-backlinks-and-checks.md](PR-GOV-04-contracts-backlinks-and-checks.md) | `Draft` | `Blocked` | `PR-GOV-03 exit gate` | prep 层规则与模板草案已创建，但 `PR-GOV-03 exit gate` 尚未满足 | `TBD (during v0.4 kickoff)` | `2026-03-06` |
| `PR-GOV-05` | [PR-GOV-05-closure-audit-and-governance-activation.md](PR-GOV-05-closure-audit-and-governance-activation.md) | `Draft` | `Blocked` | `PR-GOV-04 exit gate` | prep 层 closure/activation draft 已创建，但 `PR-GOV-04 exit gate` 尚未满足 | `TBD (during v0.4 kickoff)` | `2026-03-06` |
| `PR-GOV-06` | [PR-GOV-06-template-playbook-and-lifecycle-backfill.md](PR-GOV-06-template-playbook-and-lifecycle-backfill.md) | `Draft` | `Blocked` | `PR-GOV-05 exit gate` + `Closure Audit Output` 无阻断级失败 | 稳定模板/playbook/lifecycle 回填缺少已验证输入 | `TBD (during v0.4 kickoff)` | `2026-03-06` |

---

## Notes

- `Native ADR template` 已在 `DI-20` 与 `PR-GOV-05` 中显式记为 `post-activation follow-up deferred`，不属于当前 `PR-GOV-01 ~ PR-GOV-06` 的 ready blocker。
- 若后续需要更新 readiness 结论，应先更新对应 `PR-GOV-*` 文档中的 `Kickoff Prep Readiness Review`，再同步本矩阵。
