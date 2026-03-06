# Governance Theme Coverage Baseline

> `PR-GOV-01` 产物。本文把 first-pass 候选主题映射到后续
> `PR-GOV-02 ~ PR-GOV-06` 的预期消费关系。

---

## Coverage Rules

1. `candidate_first_batch` 主题必须至少被 `PR-GOV-02` 和 `PR-GOV-03` 显式消费。
2. `later_batch_candidate` 主题在本轮至少要完成元数据承载与覆盖保留，不能在后续 PR 中静默消失。
3. `split_pending` 主题必须在 `PR-GOV-02` 前后被显式裁决边界，未裁决前不得直接发布 ADR。
4. `PR-GOV-04 ~ PR-GOV-06` 对已发布主题与未发布主题承担不同责任：
   - 已发布主题：检查回链、审计、回填；
   - 未发布主题：保留可追溯状态、记录 deferred / pending 原因。

---

## Theme -> PR-GOV Baseline Matrix

| Theme ID | Current Status | `PR-GOV-02` | `PR-GOV-03` | `PR-GOV-04` | `PR-GOV-05` | `PR-GOV-06` | Blocking Notes |
|------|------|------|------|------|------|------|------|
| `TH-001` | `candidate_first_batch` | 建立 `Planned ADR` 槽位与补录元数据合同 | 首批发布候选 | 为已发布 ADR 建回链与检查规则 | 纳入 closure audit | 作为回填模板样本之一 | 无当前 blocker |
| `TH-002` | `later_batch_candidate` | 保留 `Planned ADR` 与状态 | 不要求首批发布；若不发布需保留原因 | 若仍未发布，检查其 pending 状态是否可追溯 | 审计其 deferred 记录 | 不直接作为首轮回填样本 | 当前 corpus 只证明 later-batch 合理性 |
| `TH-003` | `later_batch_candidate` | 保留 `Planned ADR` 与状态 | 不要求首批发布；后续 batch 再决定 | 若未发布，必须有可追溯 pending 记录 | 审计其与 `TH-001` 的关系是否仍成立 | 不直接作为首轮回填样本 | 与 `TH-001` 的 inherited context 需保留 |
| `TH-004` | `later_batch_candidate` | 保留 `Planned ADR` 与状态 | 不要求首批发布；可在后续 batch 消费 | 若未发布，检查 deferred 说明 | closure audit 记录其未进入首批的理由 | 不直接作为首轮回填样本 | 当前 corpus 足以识别主题，但不强制首批 |
| `TH-005` | `split_pending` | 先裁决与 `TH-001` 的边界；再决定是否保留独立槽位 | 在 split 未闭合前不得发布 | 若仍未闭合，必须将 pending 原因写入检查输出 | closure audit 必须记录该边界是否已关闭 | 不得在未裁决边界时回填为稳定模板规则 | 这是当前 first-pass 最明确的 open edge |
| `TH-006` | `candidate_first_batch` | 建立 `ADR-0001` 规划槽位与元数据合同 | 首批发布候选 | 为已发布 ADR 建回链与检查规则 | 纳入 closure audit | 作为补录 ADR 模板样本之一 | 无当前 blocker |
| `TH-007` | `candidate_first_batch` | 建立治理旅程 ADR 槽位与元数据合同 | 首批发布候选 | 为治理旅程 ADR 建回链与检查规则 | 纳入 closure audit，并与 activation 文档对齐 | 为 playbook/template 回填提供经过验证的治理样本 | 必须避免与 Native ADR 模板事项混淆 |

---

## Per-PR Expected Consumption

| PR | Baseline Obligation |
|------|------|
| `PR-GOV-02` | 把 `TH-001 ~ TH-007` 承接进 `adr/` 结构、`Planned ADR` 规则和补录元数据合同；同时对 `TH-005` 做边界裁决或保留 pending 理由。 |
| `PR-GOV-03` | 至少消费 `TH-001`, `TH-006`, `TH-007` 三个 `candidate_first_batch` 主题，或显式说明其中任一为何未能进入首批。 |
| `PR-GOV-04` | 对 `PR-GOV-03` 已发布 ADR 建立回链、检查规则和 `Theme Delta Contract` 落点；对未发布主题保留可追溯状态。 |
| `PR-GOV-05` | 以 closure audit 形式判断：首批已发布主题是否闭合、later-batch / pending 主题是否被正确记录。 |
| `PR-GOV-06` | 只从已经验证过的已发布主题中提炼模板与 playbook，不从 `pending` / `deferred` 主题直接回填稳定规则。 |

---

## Current Baseline Conclusion

1. 当前 first-pass 地图允许 `PR-GOV-03` 形成最小首批：
   `TH-001 + TH-006 + TH-007`。
2. `TH-002`, `TH-003`, `TH-004` 已具备独立候选主题身份，但 first-pass 不强制它们进入首批。
3. `TH-005` 是当前最需要在 `PR-GOV-02` 明确裁决的 split 边界。

