# PR-0403: Per-ADR 串行全链执行

| 项目 | 值 |
|------|-----|
| **状态** | DRAFT |
| **主题覆盖** | `T3`, `T4` |
| **依赖** | `PR-0401`, `PR-0402` |
| **关联** | [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

按时间顺序逐个处理 DN 候选，每组走完主链全流程后再进入下一组。通过 per-ADR 串行
执行模拟历史决策的时间演进，使 topic-map 和 ADR 自然生长而非预设。

---

## Scope

### In Scope

1. 按 Time Position 顺序取 DN 候选组
2. 每组 DN 候选走完主链全流程：
   - Historical semantic freeze
   - Retrospective override review
   - Impact cone review（条件触发）
   - DN classification to decision line
   - ADR carrier check
   - ADR create / append
   - Ruling update + topic-map / index / PR sync
3. 逐步填充 DN Ledger 的 classification 阶段字段
4. 逐步填充 topic-map.md 的 TH 条目
5. 产出历史补录 ADR + 对应 ruling update

### Out of Scope

1. 修改 PR-0401 已完成的 extraction 字段
2. 修改 PR-0402 已定稿的元数据合同
3. Repo-wide 一致性审计（由 PR-0404 负责）
4. Theme Delta Contract 模型定稿（由 PR-0404 负责）
5. 独立于执行经验的模板从零创建（per-ADR 执行经验隐式验证模板字段模型，
   构成 DI-20 Q5 所述的 retrospective-reconstruction-adr-template 起草基础）

---

## Execution Model

```
对每组 DN 候选（按文档分组，按 Time Position 顺序）：
  → 02 Historical semantic freeze
    → 03 Retrospective override review
      → 04 Impact cone review (if needed)
        → 05 DN classification to decision line
          → 06 ADR carrier check
            → 07 ADR create / append
              → 08 Ruling update + sync
  → 下一组 DN 候选
```

**分组规则**：以文档为单位，同一 `DOC-xxx` 的全部 DN 作为一组走完全链后，再进入下一个文档。

**串行约束**：
- 前一组 DN 候选必须完成全链，或显式升级回 DI discussion，后一组才能进入 active run
- 每次迭代可能产生：新 TH + 新 ADR、追加到已有 ADR、升级回 DI

**填充规则**：
- DN Ledger classification 字段在 DN classification 步骤中填入
- topic-map TH 条目在 classification 步骤中创建或更新
- 后期 DN 对前期 DN 的覆盖通过 `Supersedes DN IDs` / `Redirected By DN IDs` 表达

**参考模板**（均为 draft 版本，待执行验证后定稿）：
- `governance-templates/02-historical-semantic-freeze/`
- `governance-templates/03-retrospective-override-review/`
- `governance-templates/04-impact-cone-review/`
- `governance-templates/05-dn-classification-to-decision-line/`
- `governance-templates/06-adr-carrier-check/`
- `governance-templates/07-adr-create-append/`
- `governance-templates/08-ruling-update/`

---

## Deliverables

产出物存放于 `docs/reports/v0.4/governance-execution/PR-0403/`。

| 产出物 | 说明 |
|--------|------|
| Per-iteration run records | 每组 DN 候选（per-document）的全链执行记录 |
| DN Ledger（classification 版） | 在 PR-0403/ 下维护含 classification 字段的完整版本，不回改 PR-0401/ 的原始 extraction 版 |
| Topic-map working copy | 在 PR-0403/ 下维护 TH 条目工作副本，不直接修改 PR-0402 创建的 `adr/topic-map.md`；最终合并由正式发布阶段负责 |
| 历史补录 ADR | `docs/architecture/adr/` 下的 ADR 文件 |
| Ruling updates | `docs/architecture/rulings/` 下的 rebuilt rulings |
| 未闭合候选记录 | 升级回 DI 或标记 deferred 的候选 |

---

## Exit Gate

- [ ] 所有 DN 候选已按时间顺序完成全链处理
- [ ] Topic-map 已通过 per-ADR classification 自然填充（非预设占位）
- [ ] 每篇已产出的 ADR 符合 PR-0402 定稿的元数据合同
- [ ] 每篇 ADR 对应的 ruling update + sync 已完成
- [ ] 未闭合的候选已显式记录（升级回 DI 或标记 deferred）

---

## Reference

- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)（T3/T4 裁决 + per-ADR SOP 主链）
- governance-templates/README.md（SOP 阶段模板索引，planned, not yet created）
- governance-templates/playbook-seed.md（整体流程，planned, not yet created）
- [PR-0401-source-corpus-and-dn-extraction.md](PR-0401-source-corpus-and-dn-extraction.md)（DN Ledger 来源）
- [PR-0402-adr-infrastructure-and-metadata-contract.md](PR-0402-adr-infrastructure-and-metadata-contract.md)（ADR 基础设施 + 元数据合同）
