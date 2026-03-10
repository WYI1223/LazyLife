# DI-19: Architecture Decision Records 治理方案

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** |
| **影响范围** | `docs/architecture/adr/`（新建）、Ruling README、architecture_check |
| **前置输入** | E1 迁移经验、v0.2.5 → v0.3 治理演进经历、DI-12→DI-16 跨版本演进痛点 |
| **目标版本** | v0.4 执行 |
| **输出物** | ADR 目录 + README + 模板 + 触发条件 + CI 检查规则 |

---

## 0. Governance Revision Note (2026-03-06)

> 本 DI 保持 `RESOLVED`。本次更新属于 v0.3 收口后的治理修订准备：
> 保留原始 ADR 方案作为历史记录，并为后续
> `SUPERSEDED + replacement` 修订建立骨架。

### 0.1 修订目的

进一步复核后确认，DI-19 的总体方向仍成立：项目需要一层按主题组织、
跨版本串联的决策旅程文档。但原方案在以下方面仍不够自洽，无法直接进入
执行：

1. 历史补录 ADR 的合法性与范围没有定义；
2. `只追加、不改写` 未区分历史补录 ADR 与治理生效后的原生 ADR；
3. 缺少 PR 级文档影响、检查、更新义务；
4. 一致性校验、追溯要求、回链机制强度不足。

因此，本次修订的目标不是否定 ADR 方向，而是修正其治理动作、生效范围、
校验机制和执行顺序。

### 0.2 修订方式

本 DI 采用以下文档演进模式：

- DI 顶部状态保持 `RESOLVED`；
- 原始 DI-19 中被替代的方案段落保留，并在后续修订中标记为 `SUPERSEDED`；
- 新的治理方案以追加章节的方式写入同一文档，成为生效方案。

`reopen` 在本 DI 中仅作为叙事性说明，表示“进入治理修订阶段”，**不是**
新的 DI 状态词。

### 0.3 历史重演锚点

修正后的 ADR 迁移路径以 `08a-audit-findings` 作为历史重演锚点，而不是仅从
`08b-semantic-decisions` 起算。

原因是仓库现有治理叙事已经将 `08a -> 08b -> 08c -> 08d` 视为一条完整链路：

- `08a`：事实基础 / 语义灰区触发
- `08b`：语义裁决
- `08c`：结构方案
- `08d`：PR 重排与执行边界

因此，历史补录 ADR 必须保留这一完整轨迹，而不能只保留裁决切面。

### 0.4 生效范围澄清

修订后的 ADR 治理模型需要明确区分两类文档：

1. **Retrospective Reconstruction ADR**
   - 基于历史 source corpus 事后重建；
   - 必须显式声明自己是“未来视角的重述”；
   - 不追溯受 `只追加、不改写` 约束。
2. **Native ADR**
   - 在 ADR 治理正式生效后创建；
   - 自创建起受 `只追加、不改写` 约束。

这意味着：`只追加、不改写` 规则被保留，但其生效范围仅从未来某个治理激活点
开始，不反向约束历史补录工作。

### 0.5 计划中的 SUPERSEDED 范围

后续修订中，原始 DI-19 下列章节预计会被 supersede：

- `2.2` 核心 SSOT 规则
- `3` ADR 模板
- `4` ADR 创建触发条件
- `5` ADR README.md 规范
- `6` CI 检查
- `7` v0.4 执行清单
- `8` Ruling README 更新规范

下列章节预计保留，仅做增补或小范围修订：

- `1` 背景：治理体系演进脉络
- `2.1` 完整文档层次
- `2.3` 目录结构
- `9` 关联

### 0.6 替代章节骨架

后续 replacement 方案预计追加以下章节：

1. 修订后的 SSOT 规则与生效范围
2. ADR 文档分类：历史补录 vs 原生 ADR
3. 历史重演方法与 source corpus 要求
4. append-only 治理激活点
5. PR 级文档影响矩阵与更新义务
6. 一致性校验、回链与可追溯性要求
7. 执行顺序：先重演、再审计、后激活
8. 与 `release-lifecycle-template.md` 的挂接要求

### 0.7 本轮边界

本轮仅建立修订骨架，不直接完成以下动作：

- 不立即将原章节逐段标记为 `SUPERSEDED`；
- 不在本轮重写 ADR 模板正文；
- 不在本轮改写 lifecycle template；
- 不在本轮定义最终的校验 checklist。

这些内容将在后续修订步骤中基于本骨架继续展开。

---

## 1. 背景：治理体系演进脉络

### 1.1 v0.2.5 — 从 Ad-hoc 走向结构化

v0.2.5 的 frontend-review 是项目治理的转折点。13 份报告（01-09，其中 08 拆为索引 + 08a/08b/08c/08d 四份子文档）形成了一条完整的**诊断→重构→审计→裁决→方案→执行**链：

```
诊断基础 (01-03)
  01-code-health-report → 02-module-split-blueprint → 03-phased-refactor-plan
    → PR-0252 重构执行

验证与残余分析 (04-07)
  04-regression-checklist → 05-refactor-retrospective → 06-remaining-split-analysis
    → 07-wp-wpbridge-analysis

语义治理转折 (08-08d)    ← 治理体系诞生
  08-reassessment-and-replanning（索引）
    → 08a-audit-findings          ← 事实基础：10 项技术债务 + 8 项语义灰区
      → 08b-semantic-decisions    ← 裁决诞生：S1-S8 语义裁决
        → 08c-solution-proposals  ← 结构化方案：3 项解耦 + CI 门禁
          → 08d-pr-replanning     ← 治理驱动的 PR 重排
            → docs/architecture/rulings/ (S1-S8 → 后续补充 S9, E1)

终盘闭合 (09)
  09-acceptance-report → v0.3 输入
```

**关键转折（08a → 08b → 08c → 08d）**：这不是简单的"发现问题→修复问题"。08a 审计发现许多问题不是代码问题，而是**语义歧义**——`type` vs `kind` vs `view_hint` 命名混乱、synthetic uncategorized 补丁增多、tab/draft/save 归属模糊。08b 将这些语义决策形式化为 S1-S8 八条裁决（S9 在后续 v0.2.5 收尾阶段补充）。08c 基于裁决设计了 3 项结构性解耦方案（S2 notes↔workspace 解耦、S7 reminders 迁移、tags 循环依赖打断）并引入 CI 自动化门禁（即现在的 `architecture_check.dart` 前身）。08d 将原有 PR 计划按治理约束重排为 5-PR 序列（PR-0256/0257/0258/0259 + 原 PR-0253 收尾）。

**这条链路建立了"审计事实 → 语义裁决 → 结构方案 → 执行重排"的治理范式，成为后续所有版本的工作流模板。**

同期，原有的 ADR 体系（`docs/architecture/adr/ADR-0001-release-and-versioning.md`）因与新 Ruling 体系信息重叠而被迁移删除（E1 元数据记录了此迁移来源）。**当时的判断在当时是正确的**——单条 ADR 与单条 Ruling 确实承载了相同信息。

### 1.2 v0.3 规划期 — Ruling 驱动的系统化设计

v0.3 kickoff（§9）识别出 Ruling 虽然定义了约束，但在实现层仍有大量未解决的设计问题。这触发了 01-design-readiness-audit，审计报告系统性地扫描所有 v0.3 PR，识别出 ~13 个待裁决的设计决策点。

审计报告的决策点按主题聚类，拆分为 DI-0 到 DI-8 共 9 个独立讨论文档：

| 来源 | DI | 主题 |
|------|-----|------|
| 审计 D4 | DI-0 | NoteTabManager 命名冲突 |
| 审计 D1+D2+D3 | DI-1 | EditorShellService 接口 |
| 审计 D5+D6 | DI-2 | 递归布局树结构 |
| 审计 D7+D8+D9 | DI-3 | 布局持久化 |
| 审计 D10+D11 | DI-4 | Buffer 同步模型 |
| 审计 D12+D13 | DI-5 | 光标独立性 + 冲突 |
| 审计 §5.3+§5.4 | DI-6 | 跨 Track 依赖 |
| 审计 §5.1+§5.2+§5.5 | DI-7 | 验收门禁 + 性能 + 测试 |
| 审计 §5.6 | DI-8 | SPI 验证（DEFERRED v0.4） |

讨论过程中 DI-1 的深入分析衍生了 DI-10（EditorResolver 壳设计）。DI-9（Entry Search 语义）被识别但推迟。

**这一阶段建立了"Ruling 定义约束 → Audit 发现实现缺口 → DI 逐一裁决"的治理工作流。**

### 1.3 v0.3 执行期 — 实现中涌现的新议题

PR 执行过程中，实现细节暴露了规划期未预见的设计问题，产生了 DI-11 到 DI-18：

| DI | 涌现来源 | 主题 | 目标版本 |
|----|---------|------|---------|
| DI-11 | PR-RB-02 实现 S1 R3 时发现命名影响 | AtomType → ViewHint 枚举重命名 | v0.3 |
| DI-12 | S1 R5/R6 + S4 实现时发现结构性张力 | Workspace Tree 单根化 + 系统锚点 | v0.4 |
| DI-13 | PR-RB-04 code review finding | Calendar Range 查询 Limit | v0.3 |
| DI-14 | DI-12 E3 执行项的设计空白 | Workspace Tree Core 层提升 | v0.4 |
| DI-15 | DI-12 概念裁决的数据模型落地 | Rust 数据模型（单根→多根方向变更） | v0.4 |
| DI-16 | DI-15 数据模型确定后的服务层设计 | Rust Service + FFI 契约 | v0.4 |
| DI-17 | DI-16 Rust API 确定后的消费层设计 | Flutter 薄客户端适配 | v0.4 |
| DI-18 | DI-15/16/17 全部裁决后的落地规划 | PR 拆分 + 迁移 + 测试策略 | v0.4 |

**关键观察**：DI-12→DI-14→DI-15→DI-16 形成了一条跨 4 个 DI 的决策链，其中 DI-15 还经历了"单根树→多根森林"的方向变更（Q1-Q6 SUPERSEDED → Q7-Q12 新裁决）。这条链路无法在任何单个 DI 中完整呈现。

### 1.4 当前痛点

治理体系经过三个阶段已经相当成熟，但暴露了三个结构性缺陷：

| 痛点 | 具体表现 | 根因 |
|------|---------|------|
| **DI 版本锁死** | DI-12 写在 v0.3 视野下，但 workspace 拓扑决策跨越 DI-12→DI-14→DI-15→DI-16，读者需跳转 4 个文件 | DI 按版本组织，无跨版本主题线索 |
| **Ruling 密度过高** | S1 包含 R1-R14 + addendum，"为什么 R5 后来改了"淹没在规则堆里 | Ruling 职责是定义约束，不是叙述演进 |
| **叙事断层** | 没有入口能回答"workspace tree 怎么从单根走到多根森林" | 缺少 per-topic 跨版本决策旅程文档 |

### 1.5 为什么现在需要 ADR

v0.2 阶段删除 ADR 时，项目只有 1 条 ADR 和初创的 Ruling 体系，两者内容重叠。现在情况已质变：

- **9 条 S 系列 + 1 条 E 系列 Ruling**，部分 Ruling 经历过 addendum 和方向变更
- **20 个 DI**（DI-0 到 DI-19），跨越规划期和执行期
- **跨 4 个 DI 的决策链**（DI-12→DI-14→DI-15→DI-16）已经超出单个 DI 的叙事能力

ADR 不是回到 v0.2 的旧模式，而是在治理体系成熟后补充一个**按主题组织的叙事层**，填补 DI（版本锁定）和 Ruling（规则导向）之间的叙事断层。

---

## 2. 方案：五层文档体系

### 2.1 完整文档层次

| 层 | 载体 | 回答的问题 | 写入时机 | 更新规则 |
|----|------|-----------|---------|---------|
| **研究层** | `docs/reports/<version>/` | "代码库现在是什么状态、有什么问题" | 版本审查/审计阶段 | **版本冻结后不修改** |
| **探索层** | `docs/reports/<version>/design-discussions/DI-*` | "讨论了什么选项、做了什么裁决" | 版本规划/执行阶段 | **版本冻结后只做勘误** |
| **旅程层** | `docs/architecture/adr/` | "这个主题怎么演进的、为什么变了" | 触发条件满足时 | **跨版本追加 Phase，禁止改写已有 Phase** |
| **权威层** | `docs/architecture/rulings/` | "当前有效的规则是什么" | 裁决产出绑定约束时 | **只维护当前有效状态** |
| **实施层** | `docs/releases/<version>/prs/PR-*` + CLAUDE.md | "怎么落地到代码" | PR 规划阶段 | 随 PR 生命周期 |

**信息流向**：

```
研究层 (frontend-review, audit)
  → 探索层 (DI-0~DI-19, 版本内讨论)
    → 旅程层 (ADR, 跨版本主题串联)    ← 新增
      → 权威层 (Ruling, 绑定规则)
        → 实施层 (PR spec, 代码落地)
```

注：旅程层的更新规则在本次治理修订中被进一步细化为“历史补录 ADR”和
“治理生效后的原生 ADR”两类。表格中的原始表述保留为历史方案背景；
当前有效规则见 §10 和 §11。

### 2.2 核心 SSOT 规则

> **SUPERSEDED (2026-03-06 governance revision)** — 以下规则反映 DI-19 的
> 原始方案，对历史补录、生效范围、治理激活点的区分不足。保留作为决策历史
> 记录；当前有效规则见 §10。

1. **Ruling 是唯一规范源（normative source）**。ADR 描述演进过程，不定义约束。当 ADR 叙述与 Ruling 规则矛盾时，以 Ruling 为准。
2. **DI 版本冻结后只做勘误**。发现事实错误可修正（标注勘误），但不追加新分析或新结论。新的讨论开新 DI。
3. **ADR 只追加、不改写**。新 Phase 追加在末尾，已写入的 Phase 叙述不可事后修改（防止"当前视角叙事"覆盖历史判断）。唯一例外：修正事实性错误（如错误的日期、文件路径），须在修订记录中标注。
4. **研究层报告是历史快照**。版本冻结后不修改，即使后续发现分析有误，也通过新版本的报告或 DI 纠正，不回改原报告。

### 2.3 目录结构

```
docs/architecture/
├── rulings/              # 权威层：绑定规则（现有，不变）
│   ├── README.md
│   ├── Sx-<topic>.md
│   ├── ...
│   └── Ex-<topic>.md
├── adr/                  # 旅程层：决策旅程（新建）
│   ├── README.md         # 治理规则 + Decision Map 索引
│   ├── ADR-0001-<topic>.md
│   ├── ADR-0002-<topic>.md
│   └── ...
└── engineering-standards.md
```

注：此目录结构只表达 ADR 层的结构位置与命名形态，不预先锁定首批 ADR 的
主题、编号顺序或创建时机。具体主题清单必须在 source corpus 盘点与主题地图
完成后确定。相关执行顺序见 §14。

---

## 3. ADR 模板

> **SUPERSEDED (2026-03-06 governance revision)** — 以下模板未区分历史补录
> ADR 与原生 ADR，也未声明 source corpus、叙事视角和治理激活点。保留为
> 原始方案记录；替代规则见 §11。

模板中的链接使用 `{link}` 占位符标记，实际编写时替换为真实 markdown 链接。

```text
# ADR-NNNN: <主题名称>

| 字段 | 值 |
|------|-----|
| 状态 | **Active** / **Stable** / **Deprecated** |
| 创建日期 | YYYY-MM-DD |
| 最后更新 | YYYY-MM-DD |
| 规范源（Normative Source） | Ruling {link: ../rulings/Sx-xxx.md} |
| 关联 DI | {link: ../../reports/<ver>/design-discussions/DI-xx-xxx.md} |

---

## 当前结论

2-3 句话概括当前有效的架构方向。不重复 Ruling 规则条目，
只说"选了什么方向"。详细规则指向 Ruling 链接。

---

## 决策旅程

### Phase 1: <阶段标题>（<版本>, <日期>）

**触发点**：什么问题/矛盾触发了这次讨论。

**方向**：选了什么、为什么。2-3 句话概括，不展开选项分析。

**关键权衡**：用一句话或一个小表说明核心 trade-off。

-> {link: ../../reports/<version>/design-discussions/DI-xx-xxx.md}

### Phase N: ...

（追加新 Phase，不修改已有 Phase）

---

## 未解决 / 待观察

列出已知但未裁决的开放问题，标注预期解决版本。

---

## 修订记录

| 日期 | 变更 |
|------|------|
| YYYY-MM-DD | 初始创建：Phase 1-N |
| YYYY-MM-DD | 追加 Phase N+1：<概述变更内容> |
```

### 3.1 模板设计决策

| 决策 | 理由 |
|------|------|
| `规范源` 字段强制填写 | 每篇 ADR 必须指向其输出的 Ruling，防 ADR 抢 SSOT |
| Phase 只追加不改写 | 防止历史被"当前视角叙事"覆盖 |
| 不设 `Supersedes / Superseded by` | ADR 是 per-topic 演进日志，同一主题在同一文件内追加 Phase。主题废弃时整篇标 `Deprecated` 即可 |
| 修订记录每行写清变更内容 | 兼顾 change delta 功能，不需要独立 change delta 段落 |
| Phase 中不写执行细则 | "怎么做"属于 DI 和 PR Spec，ADR 只说"选了什么、为什么变了" |
| 关联 DI 用完整相对路径 | 跨目录引用需要可点击链接，且 CI 可检查断链 |

### 3.2 内容边界规则

| ADR 应写 | ADR 不应写 |
|---------|-----------|
| "我们选了多根森林" | "多根森林的 CTE 查询写法是..." |
| "从单根转向多根，因为 atoms 与 workspace_nodes 解耦" | 完整的选项对比表（那是 DI 的内容） |
| "这次转变影响了 S1 R5/R6" | R5/R6 的具体规则条目（那是 Ruling 的内容） |
| 指向 DI 和 Ruling 的链接 | 复制 DI 中的分析段落 |

**经验法则**：如果一段文字从 ADR 中删除后，读者仍然可以通过链接找到完整信息，那这段文字就太长了。

---

## 4. ADR 创建触发条件

> **SUPERSEDED (2026-03-06 governance revision)** — 以下触发条件仅适用于
> DI-19 原始设想中的“直接建 ADR”路径，没有覆盖历史重演/补录阶段。保留为
> 原始方案记录；当前有效创建与补录规则见 §11.6、§11.7 和 §14。

### 4.1 正向触发（满足任一即建）

1. **跨版本演进**：同一架构主题的设计讨论跨越 2 个或以上版本的 DI。
2. **多 DI / 多 Ruling 交汇**：1 个主题关联 2 个以上 DI，或触发 2 个以上 Ruling 的变更。

### 4.2 反向约束（不建 ADR 的场景）

- **单版本内完结的决策**：DI 自身已充分记录，不需要 ADR 提供跨版本线索。
- **纯工程执行决策**：如"用 partial unique index 还是 CHECK 约束"，属于 DI 内的实现选择，不是架构主题。

### 4.3 粒度原则

ADR 的粒度是**架构主题**（如"workspace 树拓扑"、"Atom 投影模型"），不是**单个决策点**（如"system_role 用列还是表"）。一个 ADR 下可能包含多个相关决策的演进历程。

### 4.4 与现有文档生命周期的配合

| 事件 | 文档动作 |
|------|---------|
| 新版本启动，审计报告识别设计缺口 | 开新 DI |
| DI 讨论完成，产出绑定约束 | 更新/新建 Ruling |
| 满足触发条件的主题出现 | 新建 ADR，串联已有 DI |
| 下一版本对同一主题追加讨论 | 在 ADR 中追加 Phase，链接到新 DI |
| Ruling 更新（addendum / deprecation） | 在对应 ADR 中追加 Phase 记录变更原因 |

---

## 5. ADR README.md 规范

> **SUPERSEDED (2026-03-06 governance revision)** — 以下 README 规范以
> `Decision Map` 为中心，但对反向追溯和多点校验要求不足。保留为原始方案
> 记录；当前有效追溯要求见 §13。

README 模板使用 `{link}` 占位符标记，实际编写时替换为真实 markdown 链接。

```text
# Architecture Decision Records

> 按主题组织的跨版本决策演进记录。
> ADR 是叙事层，不是规范层。绑定规则见 {link: ../rulings-legacy/README.md}。

## 治理规则

### SSOT 边界

- **Ruling 是唯一规范源**。ADR 与 Ruling 矛盾时，以 Ruling 为准。
- **DI 版本冻结后只做勘误**。新讨论开新 DI，不改旧 DI。
- **ADR 只追加、不改写**。已有 Phase 叙述不可事后修改。

### 创建条件

满足任一即建：
1. 同一主题跨 2+ 版本的 DI
2. 1 个主题关联 2+ DI 或 2+ Ruling 变更

不建 ADR：单版本完结的决策、纯工程执行决策。

### 内容边界

ADR 只写"选了什么、为什么变了"。选项分析在 DI，规则条目在 Ruling，
执行方案在 PR spec。经验法则：能通过链接找到的信息不在 ADR 中重复。

## Decision Map

| 主题 | ADR | 规范源 (Rulings) | 关联 DI | 关联 PR |
|------|-----|-----------------|---------|---------|
| 发布与版本策略 | ADR-0001 | E1 | — | — |
| Workspace Tree 拓扑 | ADR-0002 | S1 R5/R6, S4 | DI-12, DI-14, DI-15, DI-16 | v0.4 TBD |
| Atom 投影模型 | ADR-0003 | S1 R1-R4, S8 | DI-11, DI-12 | PR-RB-02, PR-RB-03 |

## 状态定义

| 状态 | 含义 |
|------|------|
| **Active** | 主题仍在演进，可追加 Phase |
| **Stable** | 主题已收敛，短期无变更预期 |
| **Deprecated** | 主题已废弃或被合并到其他 ADR |

## 编号规则

- 四位数字，顺序递增：ADR-0001, ADR-0002, ...
- 编号一旦分配不可复用
```

---

## 6. CI 检查

> **SUPERSEDED (2026-03-06 governance revision)** — 以下检查方案只覆盖
> 断链风险，对一致性、回链、状态词、规范源完整性等关键治理检查约束不足。
> 保留为原始方案记录；当前有效校验要求见 §13。

### 6.1 现有覆盖

`architecture_check.dart` 的 Check 4（docs cross-reference）已递归扫描 `docs/` 下全部 `.md` 文件。`docs/architecture/adr/` 位于此范围内，**无需扩展扫描逻辑**。ADR 创建后其内部链接自动纳入断链检查。

### 6.2 模板防断链约定

architecture_check 的链接正则（`\[text\]\(path\)`）不区分代码块内外。为避免模板示例中的占位链接触发 CI 误报：

- 模板代码块使用 ` ```text ` 而非 ` ```markdown `（降低读者误解为可直接复制的风险）
- 占位链接使用 `{link: path}` 格式而非 `[text](path)`
- 本 DI 及未来 ADR README 中的模板示例均遵循此约定

### 6.3 暂不实施的检查（ADR 数量超 10 篇后评估）

| 检查项 | 推迟原因 |
|--------|---------|
| Ruling 回链 ADR | ADR 数量少时人工可覆盖 |
| ADR 状态词汇合法性 | 3 种状态，人工不会出错 |
| `规范源` 字段非空 | 模板约束已足够 |
| ADR 与 Ruling 的双向一致性 | 实现复杂度高，收益低 |

---

## 7. v0.4 执行清单

> **SUPERSEDED (2026-03-06 governance revision)** — 以下执行顺序默认 ADR
> 可直接建档并进入治理，但未先完成历史重演与全量一致性审计。保留为原始
> 方案记录；当前有效执行顺序见 §14。

### 7.1 执行步骤

| 步骤 | 内容 | 产出 | 依赖 |
|------|------|------|------|
| 1 | 创建 `docs/architecture/adr/` 目录 | 目录结构 | — |
| 2 | 编写 `adr/README.md`（治理规则 + Decision Map） | 治理文档 | 步骤 1 |
| 3 | 新建 ADR-0001（从 E1 元数据恢复） | 历史决策旅程 | 步骤 2 |
| 4 | 新建 ADR-0002（workspace 拓扑演进） | 核心架构旅程 | 步骤 2 |
| 5 | 新建 ADR-0003（Atom 投影模型演进） | 数据模型旅程 | 步骤 2 |
| 6 | 更新 `rulings-legacy/README.md` 增加 ADR 反向引用说明 | 双向链接 | 步骤 3-5 |
| 7 | 更新 `docs/index.md` 增加 ADR 入口 | 文档导航同步 | 步骤 2 |
| 8 | 更新 `design-discussions/README.md` 补充 DI-19 | DI 索引同步 | 步骤 2 |
| 9 | 更新 CLAUDE.md 文档地图 | Agent 指引 | 步骤 6-8 |

注意：CI 断链检查无需额外工作。`architecture_check.dart` 已递归扫描 `docs/` 全部 `.md` 文件（§6.1），`docs/architecture/adr/` 自动纳入覆盖。

### 7.2 首批 ADR 识别

基于触发条件扫描现有 DI 和 Ruling：

| ADR | 主题 | 触发原因 | 涉及 DI | 规范源 |
|-----|------|---------|---------|--------|
| ADR-0001 | 发布与版本策略 | 历史 ADR 恢复（E1 迁移来源） | — | E1 |
| ADR-0002 | Workspace Tree 拓扑 | 跨 4 个 DI + 单根→多根方向变更 | DI-12, DI-14, DI-15, DI-16 | S1 R5/R6, S4 |
| ADR-0003 | Atom 投影模型 | 跨 2 个 DI + S1 多次 addendum | DI-11, DI-12 | S1 R1-R4, S8 |

### 7.3 不建 ADR 的主题（当前不满足触发条件）

| 主题 | 原因 |
|------|------|
| Tab/Draft/Save 归属 (S2) | 单版本内完结（DI-1 → S2，无后续 DI） |
| Tag × Workspace 正交性 (S3) | 单版本内完结（PR-RB-10 落地，无跨版本演进） |
| 创建路径统一 (S4) | 虽关联 DI-12，但 S4 自身规则未发生方向变更。若 v0.4 workspace 落地后 S4 发生实质性变化，届时再建 ADR |
| Extension / SPI (S5, S6) | 仍为声明阶段，无实质性决策演进 |
| Reminders (S7) | 单次裁决，Landed，无后续 |
| Cross-feature 归属 (S9) | 单版本内完结 |

---

## 8. Ruling README 更新规范

> **SUPERSEDED (2026-03-06 governance revision)** — 以下方案将反向追溯
> 压在 ADR README 单点索引上，无法满足修订后的可追溯性要求。保留为原始
> 方案记录；当前有效追溯要求见 §13。

在 `docs/architecture/rulings-legacy/README.md` 中增加一个段落，说明 ADR 的存在和关系：

```text
## 决策旅程（ADR）

每条 Ruling 的演进背景和变更原因记录在 {link: ../adr/README.md} 中。
ADR 是叙事层，Ruling 是规范层。两者矛盾时以 Ruling 为准。
```

各 Ruling 文件本身不修改结构——不强制增加 ADR 反向链接字段。Ruling 保持精简的规则文档定位。读者从 ADR README 的 Decision Map 可反向查找对应 Ruling。

---

## 9. 关联

- ← v0.2.5 `frontend-review/08a` → `08b`（裁决体系诞生的历史经验）
- ← v0.3 `01-design-readiness-audit` → DI-0~DI-8（审计驱动 DI 的工作流模板）
- ← DI-12 → DI-14 → DI-15 → DI-16（直接触发本 DI 的跨版本演进痛点）
- ← E1 `迁移来源: ADR-0001`（ADR 删除与恢复的历史闭环）
- → DI-20（将本 DI 的有效主题拆分为执行 PR 覆盖矩阵）
- → v0.4 执行（本 DI 的落地版本）

---

## 10. 修订后的 SSOT 规则与生效范围

### 10.1 规范源层级

1. **Ruling 仍是唯一规范源**。ADR 只承载“如何演进、为什么变化”的叙事，
   不直接定义架构约束。
2. **DI 仍是探索层文档**。正常情况下，版本冻结后的 DI 只做勘误，不追加新的
   实质性结论。
3. **研究层报告仍是历史快照**。审计报告、review 报告、acceptance 报告不因
   后续判断变化而回改。
4. **实施层文档允许随执行结果同步**。PR spec、release evidence、lifecycle
   模板可因执行反馈和闭环需要更新。

### 10.2 本 DI 的治理修订例外

本 DI 是治理方案文档本身。由于 ADR 制度尚未正式激活，且原 DI-19 无法通过
“新建 ADR”来自我修正，因此允许对本 DI 执行一次显式的治理修订例外：

- 原方案必须完整保留；
- 被替代内容必须显式标记为 `SUPERSEDED`；
- 新方案必须在同一文档中追加，而非覆盖；
- 修订目的必须限定为治理自洽性修正，不得借机回写无关设计内容。

### 10.3 生效范围

修订后的 ADR 治理分为两个阶段：

1. **历史重演阶段**
   - 目标：基于既有 source corpus 补录 ADR；
   - 文档类型：Retrospective Reconstruction ADR；
   - 规则：允许事后整理，但必须显式标注“未来视角重述”。
2. **治理生效阶段**
   - 目标：ADR 成为正式治理载体之一；
   - 文档类型：Native ADR；
   - 规则：从激活点开始执行 `只追加、不改写`。

### 10.4 append-only 的有效边界

`只追加、不改写` 是**原生 ADR 的前瞻性规则**，不是对历史补录 ADR 的追溯性
限制。历史补录 ADR 的可信度来自 source corpus 完整性与重述声明，而不是来自
“假装它们曾在当时被原样写下”。

---

## 11. 历史补录 ADR 规范

### 11.1 文档分类

补录阶段创建的 ADR 必须归类为 **Retrospective Reconstruction ADR**，并在
文档元数据中明确写出以下信息：

- 文档性质：历史补录 / 未来视角重述
- 补录日期
- 叙事覆盖范围
- Source Corpus
- 当前规范源

治理激活后的新 ADR 才属于 **Native ADR**。

### 11.2 历史重演锚点

每一篇历史补录 ADR 的叙事都必须从**事实触发点**开始，而不是只从裁决结果
开始。对 v0.2.5 / v0.3 这条治理线，默认锚点顺序是：

`08a audit -> 08b rulings -> 08c solutions -> 08d replanning -> acceptance / release evidence`

若某主题在后续版本继续演进，再继续串联对应 DI、Ruling、PR 和 release docs。

### 11.3 Source Corpus 要求

每篇历史补录 ADR 必须最少列出以下来源中的适用项：

- 审计或 review 报告
- 语义裁决 / DI 文档
- 结构方案或 execution plan
- 关联 Ruling
- 关联 PR spec / release evidence / acceptance report

缺少 source corpus 的 ADR 不视为可接受补录。

### 11.4 叙事约束

历史补录 ADR 必须遵守以下约束：

1. 不伪装成 contemporaneous 原件；
2. 不省略关键方向变更、废弃结论或 superseded 轨迹；
3. 不把事后认识回写成“当时已经明确”的判断；
4. 不复制 DI 的选项分析全文，而是保留链路并指向来源。

### 11.5 首批主题识别规则

首批补录 ADR **不在本 DI 中预先锁定**。主题清单必须在 source corpus 盘点后
确定，避免在缺乏全量审计的前提下提前固定编号、主题和粒度。

### 11.6 建立 ADR 的判断条件

是否值得建立 ADR，不以“文档数量”作为硬门槛，而以是否形成**可独立追溯的
决策线**为判断标准。

满足以下任一条件时，通常就值得建立 ADR：

1. 已经形成一个稳定的核心 why-question，需要长期回答“为什么这样设计”；
2. 仅靠当前 Ruling 或 PR 文档，已经无法恢复方向变化的原因链；
3. 单个 DI 内部就发生了显著方向切换、前提变化或 superseded 轨迹；
4. 同一主题横跨 audit / DI / Ruling / PR / release evidence，多层文档都在
   提及它，需要稳定的追溯入口；
5. 该主题未来大概率还会继续演进，值得用 Phase 方式持续记录。

以下信号可以作为**强提示**，但不再作为硬触发条件：

- 跨 2+ 版本
- 关联 2+ DI
- 触发 2+ Ruling 变更

因此：

- 一个 DI 文档本身就可能足以支撑一篇 ADR；
- 多个 DI 文档也可能只属于同一条决策线，因此只需要一篇 ADR。

### 11.7 粒度原则：以“决策线”为单位

ADR 的粒度不按“单个决策点”切，也不按“整个子系统”切，而按**决策线
（decision line）**切分。

定义：决策线是围绕一个稳定核心问题、能够跨多个阶段反复演进的 why-question。

治理对象之间的关系如下：

- `ADR`：一条决策线
- `Phase`：这条决策线上的一次方向转折或阶段变化
- `DI`：某次讨论载体
- `Ruling`：规范结果
- `PR`：执行与落地产物

具体拆分规则：

1. 如果两个内容回答的是同一个稳定核心问题，应进入同一 ADR，不同阶段写成
   不同 `Phase`；
2. 如果两个内容虽然都属于同一子系统，但回答的是不同核心问题，应拆成不同
   ADR；
3. 如果内容只涉及实现策略、SQL 写法、迁移手法、脚本细节，而不回答
   “为什么这样变”，则保留在 DI / PR，不升级为 ADR。

---

## 12. PR 级文档影响与更新义务

### 12.1 文档影响矩阵

从治理激活准备开始，每个 PR spec 都应包含一张 **Documentation Impact
Matrix**，至少列出：

- 文档路径
- 动作：新增 / 更新 / 不变
- 原因
- 验证方式

如果某 PR 声明“无文档影响”，也必须写出理由，而不是留空。

### 12.2 必查对象

当 PR 涉及治理、边界、语义、接口或版本收口时，至少要审查下列文档是否需要
同步：

- 相关 Ruling
- 相关 DI / DI 索引
- ADR / ADR 索引（激活后）
- `CLAUDE.md`
- `docs/index.md`
- release docs / PR specs / release evidence
- 相关 architecture docs 和 API docs

### 12.3 阻断条件

下列情况不得视为文档闭环完成：

- 改了治理事实但没有记录影响文档；
- 新增/替代规则但没有同步规范源；
- 依赖旧索引、旧链接、旧状态词而未清理；
- 声称“无需更新文档”但未给出理由。

---

## 13. 一致性校验、回链与可追溯性要求

### 13.1 两层校验

修订后的治理校验分两层：

1. **PR 级校验**
   - 检查 Documentation Impact Matrix 是否完整；
   - 检查本 PR 相关文档是否同步；
   - 检查新增链接、状态、规范源是否自洽。
2. **版本级一致性审计**
   - 在历史重演完成后执行一次 repo-wide 文档一致性检查；
   - 核对 ADR / Ruling / DI / README / index / release docs 的相互指向。

### 13.2 最低追溯要求

修订后的可追溯性不允许只依赖单一 `Decision Map`。至少需要满足：

1. ADR 正向指向 source corpus 与规范源；
2. ADR 索引能反查到 Ruling / DI / PR；
3. Ruling 侧至少存在一个稳定的反向入口到 ADR 索引或主题映射；
4. release / PR 文档能回溯到其使用的 DI / Ruling / ADR。

### 13.3 自动化与人工校验边界

在短期内，可以接受“断链自动化 + 结构一致性人工检查”的组合；但以下检查
不再视为可长期无限期推迟：

- 规范源非空
- 状态词合法性
- ADR / Ruling / DI 的必要回链
- 关键索引的一致性

---

## 14. 修订后的执行顺序

### 14.1 顺序原则

修订后的执行顺序不是“先建 ADR，再逐步补内容”，而是：

1. **先盘点 source corpus**
2. **再按主题历史重演**
3. **再做全量一致性审计**
4. **再宣布 ADR 治理正式生效**
5. **最后把 PR 级规则挂入 release lifecycle**

### 14.2 建议步骤

| 步骤 | 内容 | 产出 |
|------|------|------|
| 1 | 盘点 08a/08b/08c/08d、09、相关 DI/Ruling/PR/release docs | 主题地图 + source corpus 清单 |
| 2 | 按主题编写历史补录 ADR | Reconstruction ADR 草案 |
| 3 | 执行一次 repo-wide 文档一致性审计 | 一致性审计结果 |
| 4 | 编写治理激活 ADR，声明 append-only 从此生效 | Governance Activation ADR |
| 5 | 将 PR 级文档规则接入 lifecycle template 和后续 PR spec 模板 | 可执行流程约束 |

### 14.3 治理激活点

append-only 规则不由 DI-19 原文自动生效，而由**历史重演完成后的治理激活
文档**显式生效。只有在该激活点之后创建的 ADR，才进入原生治理生命周期。

---

## 15. 与 Release Lifecycle 的挂接要求

本 DI 的修订方案要求后续将文档治理规则接入
`docs/development/release-lifecycle-template.md`，至少覆盖以下环节：

1. `Kickoff`：增加 source corpus / 文档基线盘点
2. `Rulings / Modules Backfill`：增加治理文档影响扫描
3. `PR Spec Writing`：增加 Documentation Impact Matrix
4. `PR Execution`：增加合并前文档闭环检查
5. `Doc Sync / Closure`：增加版本级一致性审计
6. `Lifecycle Retrospective`：回填本轮文档治理中的新发现

本挂接要求在本 DI 中先定义为治理义务，具体模板措辞与 checklist 细节可在
后续单独修订 `release-lifecycle-template.md` 时展开。
