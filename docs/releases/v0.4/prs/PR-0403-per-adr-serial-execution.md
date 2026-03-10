# PR-0403: Per-ADR 串行全链执行

- Proposed title: `docs(governance): execute serial per-document replay for retrospective ADR outputs`
- Execution status: In Progress
- Spec review status: Review-clean (`docs/releases/v0.4/pr-spec-review-resolution.md`)

| 项目 | 值 |
|------|-----|
| **执行状态** | IN PROGRESS |
| **规格评审状态** | Review-clean |
| **主题覆盖** | `T3`, `T4` |
| **依赖** | `PR-0401`, `PR-0402` |
| **关联** | [DI-19-adr-governance.md](../../../reports/v0.3/design-discussions/DI-19-adr-governance.md), [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

在 `PR-0401` 已建立 source corpus、survey、DN extraction baseline，且 `PR-0402` 已建立 ADR shell 与 metadata contract 之后，按 `Time Position` 的历史顺序逐个处理 `DOC-xxx` 候选组。每个文档组走完 `02 -> 08` 全链后，再进入下一个文档组，以此模拟历史决策线如何在 source corpus 中逐步成形，并自然长出 topic-map、retrospective ADR 与 rebuilt ruling。

---

## Scope

### In Scope

1. **Action 0: 首批文档批次锁定 + working-copy bootstrap**
2. **Action 1: 按文档顺序执行串行 replay runs**
3. **Action 2: 在 execution working copy 中填充 classification 与 topic-map rows**
4. **Action 3: 产出首批 retrospective ADR + rebuilt rulings**
5. **Action 4: 记录未闭合文档组、deviation 与后续 handoff**

### Out of Scope

1. 把 `PR-0401` 全部 `DOC-xxx` 一次性做完
2. 回改 `PR-0401` 的 extraction 字段
3. 回改 `PR-0402` 的 metadata contract，除非显式记录 deviation 并升级治理决策
4. repo-wide consistency audit（由 `PR-0404` 负责）
5. governance activation 与 append-only 生效声明（由 `PR-0405` 负责）
6. 将模板正式沉淀到 `docs/development/report-templates/`（由 `PR-0406` 负责）

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| 当前治理规则 | `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md` | 定义 `Retrospective Reconstruction ADR` / `Native ADR` 边界，以及历史补录与 append-only 的关系 |
| 当前执行规则 | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | 定义 `PR-0403` 的位置、exit gate、模板抽离边界、per-PR 最低 `Theme Delta Contract` |
| 上游 source baseline | `docs/reports/v0.4/governance-execution/PR-0401/document-inventory.md`, `dn-ledger.md`, `coverage-matrix.md`, `surveys/` | 提供 source corpus、文档顺序、clause-node extraction baseline 与 source anchors |
| 上游 ADR shell / contract | `docs/architecture/adr/README.md`, `docs/architecture/adr/topic-map.md`, `docs/reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md` | 提供 mainline shell、topic-map field contract、retrospective ADR metadata contract |
| prep first-pass theme map | `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md` | 仅作为 post-classification comparison source；不得作为 doc-run queue 输入，也不得变成独立的“先建主题”步骤 |
| 规范锚点 | `docs/architecture/rulings-legacy/`, `docs/architecture/rulings/README.md` | 提供 historical normative anchors 与 current-effective rebuilt rulings 的目标目录边界 |

边界规则：

1. `PR-0403` 的执行单元是 **文档组**，不是主题组。
2. 文档组必须按 `document-inventory.md` 的 `Time Position` 顺序推进；不得因为 `DI-19` 样例或 prep first-pass map 而跳到后期文档。
3. `08a` 是 trigger/evidence source，`08b` 是最早的成体系 decision-source；如果进入“首批裁定落地”，应从 `08b` 及其紧邻上游输入开始，而不是从 `DI-19` 开始。
4. `docs/architecture/adr/topic-map.md` 在执行期间保持 mainline 发布面；working rows 在 `PR-0403/` 下维护，只有当某个文档组推动出 publish-complete ADR / ruling 结果时，才允许把对应行同步回 mainline。
5. 本 PR 不存在 planning-start 前的独立“新建主题 / 确认主题”步骤；任何 `TH-xxx` 行的创建或更新，只能作为某个 active `DOC-xxx` 在 `05 DN classification to decision line` 阶段的产物被记录。
6. `PR-0402` 的 metadata contract 是本 PR 的硬约束；若执行中发现合同不足，必须显式记录 deviation，而不是静默修改 mainline contract。

---

## Single-Active-Doc Queue Strategy

### Action 0: Single-Active-Doc Queue Bootstrap

`PR-0403` 开始前，不预锁定文档批次，只建立 `doc-run-queue.md` 作为单文档串行执行队列。

默认顺序规则：

1. 从 `PR-0401/document-inventory.md` 的最早文档开始，按 `Time Position` 顺序推进。
2. 若当前目标是“最早的已裁定 decision-source”，则起点应是 `DOC-002 / 08b`，并显式声明其依赖的 trigger/evidence 上游为 `DOC-001 / 08a`。
3. 后期治理文档（如 `DI-19`, `DI-20`）只能在其时间位置到来后作为后段 replay 输入，不得被拿来定义起点。

`doc-run-queue.md` 至少要覆盖：

1. `DOC-001 / 08a`
2. `DOC-002 / 08b`
3. `DOC-003 / 08c`
4. `DOC-004 / 08d`
5. `DOC-005 / 09`

每个文档组必须显式标成以下状态之一：

- `ready_next`
- `active`
- `completed`
- `parked_later`
- `deferred`
- `escalate_to_governance`
- `context_only`

### Queue Defaults

如果本轮只做最小安全起步，推荐顺序是：

1. `DOC-001 / 08a` 作为 supporting context
2. `DOC-002 / 08b` 作为第一份 active run 的真正裁定源
3. 视执行复杂度决定是否继续纳入 `DOC-003 / 08c`、`DOC-004 / 08d`、`DOC-005 / 09`

目的：

1. 先按真实时间顺序重演最早裁定链
2. 避免一开始就跳到 `DI-19 / DI-20` 这种后期治理层文档
3. 为 `PR-0404` 提供从 earliest decision-source 长出的真实执行样本

---

## Execution Model

### Iteration Unit

`PR-0403` 的执行单元是 **文档组 / DOC-xxx**。

说明：

1. 每次 active run 只处理一个 `DOC-xxx` 的全量 `DN` 候选组。
2. 同一文档组的 `DN` 必须在本轮走完 `02 -> 08`，或被显式 parked / escalated，再进入下一文档。
3. 主题、ADR、ruling 是文档组执行后自然长出的结果，不是预先取代文档顺序的执行单元。

### Strict Step Order

对每一个进入本轮的文档组，必须按以下顺序执行，不得跳步：

```text
00 Doc-run bootstrap
  -> 02 Historical semantic freeze
    -> 03 Retrospective override review
      -> 04 Impact cone review (if needed)
        -> 05 DN classification to decision line
          -> 06 ADR carrier check
            -> 07 ADR create / append
              -> 08 Ruling update + sync
```

阶段规则：

1. `02 Historical semantic freeze`
   - 只冻结该 `DOC-xxx` 内部的历史语义，不写当前规范结论。
2. `03 Retrospective override review`
   - 必须识别该文档相对更早 source 的继承 / override / redirect / supersede 关系。
3. `04 Impact cone review`
   - 当文档组触及共享规范源、共享 ADR carrier、跨文档 supersede / redirect，或需要改动已有 ADR / ruling 时触发。
4. `05 DN classification to decision line`
   - 在 working copy 中填 classification-stage 字段，但不回改 `PR-0401` 原始 extraction 版。
5. `06 ADR carrier check`
   - 只能输出 `create_new_adr` / `append_existing_adr` / `redirect_to_existing_adr` / `park_later` / `escalate_to_governance` 之一。
6. `07 ADR create / append`
   - ADR 必须满足 `PR-0402` metadata contract。
7. `08 Ruling update + sync`
   - 只有文档组真正推动出 publish-complete 结果时，才允许同步 mainline `topic-map.md` 与 rebuilt rulings。

### Per-Document Minimum Record

每个文档组迭代记录必须包含 `Theme Delta Contract` 与 `Theme Delta Rows`，但其 `Covered Themes` 由该文档组实际长出的结果决定，而不是预先指定。这里的 `Theme Delta` 是对文档 run 结果的记录面，不是开跑前先选题或先建主题的 planning step：

```text
## Theme Delta Contract

| 字段 | 内容 |
|------|------|
| Source Doc Group | DOC-... |
| Covered Themes | TH-... / pending |
| Theme Operations | confirm / split / merge / publish_adr / append_adr / publish_ruling / redirect / park |
| Primary Theme Owner | ... |
| PR Executor | ... |
| Secondary Coverage | ... |
| Out of Scope | ... |
| Must Preserve | ... |
| Allowed Simplifications | ... |
| Escalation Required If Violated | ... |
| Accepted Debt | ... |
| Output Docs | ... |
| Verification | ... |
| Required Sign-off | ... |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| TH-... | ... | ... | ... | ... | ... | ... |
```

---

## Actions Detail

### Action 0: Batch Lock + Working-Copy Bootstrap

产出物：

- `doc-run-queue.md`
- `dn-ledger-classification.md`
- `topic-map-working-copy.md`
- `iterations/README.md`
- `open-items.md`

要求：

1. `doc-run-queue.md` 必须记录 `ready_next` / `active` / `completed` / `parked_later` / `deferred` / `escalate_to_governance` / `context_only` disposition。
2. `dn-ledger-classification.md` 必须从 `PR-0401/dn-ledger.md` 派生，不得回改 extraction 原件。
3. `topic-map-working-copy.md` 必须从 `PR-0402` 的 mainline header contract 派生，保留 `Current Normative Source` dedicated 列。
4. `open-items.md` 必须收纳：
   - parked docs / later-run docs
   - split / merge disputes
   - escalation back to governance
   - accepted debt / deviation

### Action 1: Serial Per-Document Replay Runs

产出物：

- `iterations/DOC-xxx-<slug>/02-historical-semantic-freeze.md`
- `iterations/DOC-xxx-<slug>/03-retrospective-override-review.md`
- `iterations/DOC-xxx-<slug>/04-impact-cone-review.md`（条件触发）
- `iterations/DOC-xxx-<slug>/05-dn-classification-to-decision-line.md`
- `iterations/DOC-xxx-<slug>/06-adr-carrier-check.md`
- `iterations/DOC-xxx-<slug>/07-adr-create-append.md`
- `iterations/DOC-xxx-<slug>/08-ruling-update-and-sync.md`

要求：

1. 一次只允许一个文档组处于 active run。
2. 前一文档组未完成 `08` 或未显式 parked / escalated，不得启动下一文档组。
3. 若某文档组在 `05` / `06` 发现主题需要拆分或合并，必须在本组记录里显式记录，并同步 `topic-map-working-copy.md` 与 `open-items.md`。

### Action 2: Working-Copy Classification + Topic Map Sync

产出物：

- `dn-ledger-classification.md`
- `topic-map-working-copy.md`
- selective sync to mainline `docs/architecture/adr/topic-map.md`

规则：

1. `dn-ledger-classification.md` 承载 classification-stage 字段，不污染 `PR-0401` extraction baseline。
2. `topic-map-working-copy.md` 可以承载 in-flight theme rows；mainline `topic-map.md` 只收 publish-complete rows。
3. mainline `topic-map.md` 中新增行时，必须同时具备：
   - `Current Normative Source`
   - `Planned ADR`
   - `Published ADR`
   - 与已发布 ADR 的双向稳定映射

### Action 3: Publish Retrospective ADRs + Rebuilt Rulings

产出物：

- `docs/architecture/adr/ADR-000X-<slug>.md`
- `docs/architecture/rulings/<code>-<slug>.md`

发布规则：

1. 每篇 ADR 必须满足 `PR-0402` metadata contract。
2. 每篇 ADR 必须显式链接 `Current Normative Source`。
3. 每篇 rebuilt ruling 必须与对应 ADR 建立双向 backlink。
4. 若某文档组到 `06` 仍判定不适合发布，则必须回写 `park_later` 或 `escalate_to_governance`，而不是强行发布半成品 ADR。

### Action 4: Open Items + Carry-Forward Handoff

产出物：

- `open-items.md`
- PR-0403 execution log closeout section

必须记录：

1. parked docs / later-run docs
2. split / merge disputes 未收口项
3. contract deviation
4. 需要 `PR-0404` 审计的结构 / 图结构 / 政策风险
5. 需要 `PR-0406` 用真实执行再验证的模板边界

---

## Deliverables

所有执行产物存放于 `docs/reports/v0.4/governance-execution/PR-0403/`，除正式发布资产外。

| Action | 产出物 | 存放路径 |
|--------|--------|----------|
| 0 | `doc-run-queue.md` | `PR-0403/` |
| 0 | `dn-ledger-classification.md` | `PR-0403/` |
| 0 | `topic-map-working-copy.md` | `PR-0403/` |
| 0 | `open-items.md` | `PR-0403/` |
| 0 | `iterations/README.md` | `PR-0403/iterations/` |
| 1 | per-document stage records | `PR-0403/iterations/DOC-xxx-<slug>/` |
| 2 | selective mainline row sync | `docs/architecture/adr/topic-map.md` |
| 3 | published retrospective ADRs | `docs/architecture/adr/` |
| 3 | rebuilt rulings | `docs/architecture/rulings/` |
| 4 | execution log | `PR-0403/README.md` |

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Docs | 将 PR-0403 spec 收敛为按文档顺序推进的 single-active-doc 执行合同，明确严格顺序、working copy / mainline 分离规则 | `docs/releases/v0.4/prs/PR-0403-per-adr-serial-execution.md` | TBD | `PR-0402` |
| T2 | Docs | 建立 PR-0403 planning kickoff log，记录“规划已启动、实际 replay 未开始”的当前状态 | `docs/reports/v0.4/governance-execution/PR-0403/README.md` | TBD | T1 |
| T3 | Docs | 建立 doc-run queue，记录按 `Time Position` 的 next-run 顺序、terminal state 与 context-only docs | `docs/reports/v0.4/governance-execution/PR-0403/doc-run-queue.md` | TBD | T1 |
| T4 | Docs | 派生 classification working copy 与 topic-map working copy | `docs/reports/v0.4/governance-execution/PR-0403/dn-ledger-classification.md`, `topic-map-working-copy.md` | TBD | T3 |
| T5 | Docs | 为每个 accepted doc group 建立 02-08 阶段记录并串行执行 | `docs/reports/v0.4/governance-execution/PR-0403/iterations/DOC-xxx-<slug>/` | TBD | T4 |
| T6 | Docs | 发布 retrospective ADR 与 rebuilt ruling，并做 selective mainline topic-map sync | `docs/architecture/adr/`, `docs/architecture/rulings/`, `docs/architecture/adr/topic-map.md` | TBD | T5 |
| T7 | Docs | 收口 open items / deviation / carry-forward handoff | `docs/reports/v0.4/governance-execution/PR-0403/open-items.md`, `README.md` | TBD | T5-T6 |
| T8 | Verify | 运行 docs 结构检查与 PR-0403 专项验证 | `tools/ci/architecture_check.dart` | TBD | T1-T7 |

## Planned File Changes

- `[edit]` `docs/releases/v0.4/prs/PR-0403-per-adr-serial-execution.md`
- `[edit]` `docs/reports/v0.4/governance-execution/PR-0403/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0403/doc-run-queue.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0403/dn-ledger-classification.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0403/topic-map-working-copy.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0403/open-items.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0403/iterations/README.md`
- `[add]` per-document stage files under `docs/reports/v0.4/governance-execution/PR-0403/iterations/`
- `[add/edit]` `docs/architecture/adr/ADR-000X-<slug>.md`
- `[add/edit]` `docs/architecture/rulings/*.md`
- `[edit]` `docs/architecture/adr/topic-map.md`

## Verification

### CI gate

```bash
cd apps/lazynote_flutter/
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```powershell
# PR-0403 planning / execution 分离：working copy 必须在 execution 目录，mainline 只允许 publish-complete rows
rg -n "Current Normative Source|Published ADR" docs/reports/v0.4/governance-execution/PR-0403/topic-map-working-copy.md docs/architecture/adr/topic-map.md

# 每篇已发布 ADR 必须具备 PR-0402 contract 的最小骨架
rg -n "Reconstruction Notice|Decision Line|Source Corpus|Corpus Coverage Declaration|Journey Timeline / Phases|Current State|Open Edges|Revision Record" docs/architecture/adr/ADR-*.md

# mainline topic-map 中的每个 Published ADR 必须真实存在
$published = Get-Content 'docs/architecture/adr/topic-map.md' |
  Where-Object { $_ -match '^\| `?TH-' -and $_ -notmatch '\| *(pending)? *\|' }
foreach ($row in $published) { $row }
```

验证说明：

1. 真正的逐行图结构与回链一致性审计由 `PR-0404` 负责。
2. `PR-0403` 本阶段只要求每个已发布文档组达到最小 publish-complete consistency。

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 因为 `DI-19` 样例或 prep first-pass map 而跳过更早文档，破坏历史顺序 | HIGH | 将 `doc-run-queue.md` 设为唯一 run-order 事实来源，只允许按 `Time Position` 选择 next doc |
| working copy 与 mainline topic-map 混写，导致 `PR-0404` 无法区分执行中状态与已发布状态 | HIGH | 执行层维护 `topic-map-working-copy.md`，mainline 只同步 publish-complete rows |
| 把 too many docs 硬塞进首批，导致 PR-0403 变成无限扩张 PR | HIGH | 首批只接受 earliest accepted docs，后续文档一律显式 parked / deferred / escalated |
| 执行中静默修改 PR-0402 contract，破坏 ADR 元数据稳定性 | MEDIUM | 要求 deviation 显式记录并回收到治理层，而不是静默修 contract |

## Exit Gate

- [ ] `doc-run-queue.md` 已建立，且 `ready_next` / `active` / `completed` / `parked_later` / `deferred` / `escalate_to_governance` / `context_only` 均有明确定义
- [ ] 每个 accepted doc group 已按 `02 -> 08` 顺序完成全链执行，或被显式 parked / escalated
- [ ] 每篇已发布 retrospective ADR 均满足 `PR-0402` metadata contract
- [ ] 每篇已发布 ADR 均已建立对应 rebuilt ruling 与双向 backlink
- [ ] mainline `docs/architecture/adr/topic-map.md` 只包含 publish-complete rows，且每行具备稳定 `Published ADR` / `Current Normative Source`
- [ ] 未完成文档组、split / merge 争议、deviation、accepted debt 已写入 `open-items.md`

---

## Reference

- [DI-19-adr-governance.md](../../../reports/v0.3/design-discussions/DI-19-adr-governance.md)
- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)
- [governance-theme-map-first-pass.md](../../../reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md)
- [PR-0401-source-corpus-and-dn-extraction.md](PR-0401-source-corpus-and-dn-extraction.md)
- [PR-0402-adr-infrastructure-and-metadata-contract.md](PR-0402-adr-infrastructure-and-metadata-contract.md)
