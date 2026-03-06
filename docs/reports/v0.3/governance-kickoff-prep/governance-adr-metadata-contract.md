# Governance ADR Metadata Contract

> `PR-GOV-02` 的 kickoff 筹备输入。
> 本文定义历史补录 ADR 在 future `v0.4 kickoff` 组织正式 PR spec 时应遵循的
> 最低元数据合同、标准声明与修订约束。
> 本文不是正式 `docs/architecture/adr/` 资产，也不替代 `DI-19` / `DI-20`。

---

## Purpose and Boundary

本文只回答三个问题：

1. 历史补录 ADR 至少必须包含哪些元数据字段；
2. `Reconstruction Notice`、`Corpus Coverage Declaration`、`Revision Record`
   应如何最小化表达；
3. 哪些修订在治理迁移窗口内是允许的，哪些必须升级回治理裁决。

本文不回答：

1. 首批 ADR 具体写哪几篇；
2. `ADR-000X-<slug>.md` 的最终编号与标题；
3. 治理激活后的 `Native ADR` 模板细节。

---

## Classification Rule

future `v0.4 kickoff` 若按 `DI-19` / `DI-20` 启动 ADR 治理，则当前轮次首先创建的 ADR
应归类为：

- `Retrospective Reconstruction ADR`

它必须明确声明：

- 这是基于已列明 `source corpus` 的未来视角重述；
- 它不是当期原始记录；
- 当前规范锚点仍以链接到的 `Ruling` 为准；
- 它不追溯受 `append-only` 约束。

`Native ADR` 不在本文合同范围内；其模板应作为 post-activation follow-up 单独规划。

---

## Required Metadata

| Field | Required | Purpose | Notes |
|------|----------|---------|-------|
| `Document Class` | Yes | 区分历史补录 ADR 与未来原生 ADR | 当前阶段固定为 `Retrospective Reconstruction ADR` |
| `Narrative Perspective` | Yes | 明示本文是未来视角重述 | 不得省略 |
| `Decision Line` | Yes | 指明本文回答的稳定 `why-question` | 与 theme map 的 `Stable Why-Question` 对齐 |
| `Coverage Scope` | Yes | 指明本文覆盖哪些阶段、止于何处 | 允许写明排除范围 |
| `Current Normative Source` | Yes | 指向当前有效规范源 | 当前通常是 `Ruling` |
| `Source Corpus Summary` | Yes | 列出本文实际使用的关键来源 | 不要求复制全文 |
| `Corpus Coverage Declaration` | Yes | 说明不同来源类别的覆盖情况 | 见下节 |
| `Journey Timeline / Phases` | Yes | 按时间顺序组织演进阶段 | 不得打乱时序 |
| `Current State` | Yes | 说明当前应以什么状态理解该主题 | 应回链当前规范锚点 |
| `Open Edges` | Yes | 记录仍未闭合的边界、待跟进点 | 不得静默忽略 |
| `Revision Record` | Yes | 记录补源、纠错、边界修正 | 后续修订必须更新 |

---

## Standard Reconstruction Notice

每篇历史补录 ADR 顶部应包含一段标准声明。推荐骨架如下：

```md
> 本文为历史补录 ADR，于 <date> 基于列明的 `source corpus`
> 从未来视角重述该决策线，不是当期原始记录；
> 当前规范以所链接 `Current Normative Source` 为准。
```

最小要求：

1. 必须出现“历史补录”或等价表达；
2. 必须出现“未来视角重述”或等价表达；
3. 必须出现“不是当期原始记录”或等价表达；
4. 必须出现“当前规范以 `<Ruling>` 为准”或等价表达。

---

## Corpus Coverage Declaration

每篇历史补录 ADR 必须声明 `source corpus` 的覆盖状态，而不只是随意列链接。

最小分类如下：

| Coverage Class | Allowed Status | Meaning |
|------|------|------|
| `Trigger Source` | `present` / `absent` / `not_applicable` | 是否纳入事实触发 / 审计来源 |
| `Decision Source` | `present` / `absent` / `not_applicable` | 是否纳入 DI / semantic decisions |
| `Normative Source` | `present` / `partial` / `absent` | 是否纳入当前有效规范锚点 |
| `Execution / Closure Source` | `present` / `absent` / `not_applicable` | 是否纳入 PR / acceptance / release evidence |
| `Superseded / Redirected Source` | `present` / `absent` / `not_applicable` | 是否纳入方向变更、superseded、redirect 轨迹 |

推荐表头：

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|

约束：

1. 若已知某类关键来源存在，不得将其静默省略；
2. 若状态为 `absent` 或 `partial`，必须在 `Notes` 说明原因；
3. 若状态为 `partial`，应说明后续在哪一阶段继续补齐。

---

## Standard Section Skeleton

每篇历史补录 ADR 最少应具有以下正文段落：

1. `Reconstruction Notice`
2. `Decision Line`
3. `Source Corpus`
4. `Corpus Coverage Declaration`
5. `Journey Timeline / Phases`
6. `Current State`
7. `Open Edges`
8. `Revision Record`

允许追加主题特有段落，但不得删除上述最小骨架。

---

## Revision Rules During Migration Window

在 `DI-20` 定义的治理迁移窗口内，历史补录 ADR 允许受控修订，但必须满足：

1. 每次修订都写入 `Revision Record`；
2. 修订理由仅允许：
   - 补入新发现的一级来源；
   - 校正事实错误；
   - 校正阶段边界；
   - 补回 superseded / redirected 轨迹；
3. 不允许无痕重写；
4. 若修订影响 `Decision Line`、`Current Normative Source` 或主题边界，
   必须回到治理裁决或 theme map 裁决。

治理激活后，历史补录 ADR 不转为 `append-only`，但进入“冻结但可勘误”状态：

1. 允许勘误；
2. 允许补入新发现的一级来源；
3. 不允许自由改写演进叙事。

---

## Theme Map Alignment

历史补录 ADR 与 first-pass / approved theme map 至少应对齐以下字段：

| ADR Field | Theme Map Field |
|------|------|
| `Decision Line` | `Stable Why-Question` |
| `Current Normative Source` | `Published ADR` / related ruling note |
| `Journey Timeline / Phases` | `First Seen In Corpus`, relation notes |
| `Open Edges` | `Current Status`, `Notes` |

若 `theme map` 与 ADR 正文出现冲突：

1. 先修正 prep 文档；
2. 若冲突已经影响主题边界或依赖关系，必须升级为治理裁决问题。

---

## Out of Scope for This Contract

以下内容明确不在本文中定稿：

1. `Native ADR` 模板；
2. `ADR-000X-<slug>.md` 的编号策略细节；
3. `docs/architecture/adr/README.md` 的完整正文；
4. `topic-map.md` 的最终展示样式。

这些内容应分别在 `PR-GOV-02` 正式 kickoff 组织、`PR-GOV-03` 首批发布、
以及 post-activation follow-up 中继续细化。
