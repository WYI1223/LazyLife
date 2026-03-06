# DI-20: 治理执行计划 — ADR 历史重演、主题覆盖与激活顺序

| 项目 | 值 |
|------|-----|
| **状态** | RESOLVED |
| **关联决策点** | DI-19（ADR 治理方案修订） |
| **影响范围** | `docs/architecture/adr/`、`docs/architecture/rulings/`、`docs/index.md`、`docs/releases/`、`docs/development/`、DI 索引 |
| **前置依赖** | DI-19 §10-§15 有效规则 |
| **目标版本** | v0.4 kickoff 筹备 |
| **输出物** | 主题覆盖矩阵 + PR 草案序列 + kickoff 前 handoff / 激活边界 |

---

## 背景

DI-19 已经给出修订后的治理方向：引入 ADR 作为旅程层，并区分历史补录 ADR 与
治理生效后的原生 ADR。但 DI-19 本身不负责回答“如何安全地把这套治理落到
仓库中”。

本 DI 的任务是把 DI-19 的有效主题拆解成**可执行的治理工作包**，并规划：

1. 以什么为执行单位；
2. 如何拆分 PR；
3. 每个 PR 必须覆盖哪些治理主题；
4. 如何验证所有主题最终都被覆盖；
5. 何时才能把稳定下来的规则沉淀到 release lifecycle template。

**边界原则**：本 DI 只讨论治理执行策略，不重新裁决 ADR 的制度方向。治理
方向由 DI-19 提供，本 DI 只负责“怎么安全、有序、可审计地组织后续落地”。

**当前口径说明**：本 DI 派生出的 `PR-GOV-*` 与配套基线文档当前位于
`docs/reports/v0.3/governance-kickoff-prep/`，它们是 future `v0.4 kickoff`
组织正式 PR spec 时的参考输入，而不是已进入 `docs/releases/v0.4/` 主线的执行文档。

---

## 讨论边界

### In Scope

1. DI-19 当前有效主题的执行拆分。
2. 主题覆盖矩阵与 PR 责任分配。
3. 治理执行 PR 的依赖顺序。
4. 历史重演、审计、治理激活、模板沉淀的先后关系。
5. 收口标准与 coverage closure 机制。

### Out of Scope

1. 重写 DI-19 的治理规则本身。
2. 具体 ADR 正文内容的逐篇定稿。
3. 立即修改 release lifecycle template 的细节措辞。
4. 与 ADR 治理无关的其他文档清理工作。

---

## 待裁决问题（Q1-Q5）

### Q1. 治理执行的最小单位是什么？

如果直接按文档文件拆分，容易出现“一个 PR 修很多文件，但没有回答清楚自己
到底在完成哪一类治理义务”；如果直接按章节号拆分，又会被文档重排牵着走。

#### Q1 裁决：以“治理主题（governance themes）”作为执行单位

执行单位不是单个文件，也不是单个 PR，而是 **DI-19 当前有效主题**。每个主题
是一个必须被治理执行覆盖的责任包。

**主题清单（T1-T8）**：

| 主题码 | 来源 | 主题 | 核心问题 |
|------|------|------|---------|
| `T1` | DI-19 §2.3, §11.5 | ADR 目录结构与主题地图边界 | ADR 结构如何表达，以及正式目录与执行期主题地图如何分界 |
| `T2` | DI-19 §10 | SSOT、生效范围、治理修订例外 | 哪些规则何时生效、对谁生效 |
| `T3` | DI-19 §11.1-§11.5 | 历史补录 ADR 规范 | 历史 ADR 如何合法补录、如何标注 |
| `T4` | DI-19 §11.6-§11.7 | ADR 建立判断条件与粒度 | 何时值得建 ADR、如何按决策线切分 |
| `T5` | DI-19 §12 | PR 级文档影响与更新义务 | 每个 PR 如何声明自己的文档责任 |
| `T6` | DI-19 §13 | 一致性校验、回链、可追溯性 | 如何保证文档网络可验证、可追踪 |
| `T7` | DI-19 §14 | 执行顺序与治理激活点 | 历史重演、审计、激活如何排序 |
| `T8` | DI-19 §15 | 与 lifecycle template 的挂接 | 何时、如何把稳定流程沉淀成模板 |

**结论**：所有治理执行 PR 的覆盖范围都必须回到 `T1-T8` 之一或多项，而不是
只写“改了哪些文件”。

**T1 当前裁决补充**：

1. `docs/architecture/adr/` 只承载**正式发布的 ADR 层资产**，不承载执行期
   候选主题草稿或 scratchpad。
2. `adr/README.md` 负责治理规则、状态定义与阅读入口。
3. `adr/topic-map.md` 只记录**已批准**主题与实际 ADR 的映射，不承担候选主题
   盘点功能。
4. 候选主题地图、source corpus 盘点、编号草案等执行期内容，保留在 `DI-20`
   或 `PR-GOV-01` 等执行文档中，待确认后再提升进入 `adr/`。
5. ADR 模板不放入 `adr/` 目录本身；`adr/` 是资产目录，不是流程工具目录。

**T2 当前裁决补充**：

1. `T2` 不再被表述为单一句式的“Ruling 是唯一 SSOT”，而是采用
   **authority matrix**：不同问题由不同层级文档回答。
2. 对“当前有效的架构/产品约束是什么”，权威源仍然是 `Ruling`；对“某条决策线如何
   演进、为何变化”，权威源是 `ADR`，但它是**叙事权威**，不是规范权威。
3. 对“某个版本内讨论了什么、当时有哪些备选项与裁决过程”，权威源是 `DI`；对“某个
   PR 承诺覆盖哪些治理主题、产出哪些文档”，权威源是该 PR 的
   `Theme Delta Contract`。
4. `T2` 的生效范围按三个阶段理解：
   - `Phase A: pre-migration history`：保留既有 reports / DI / Ruling 的历史职责，不
     追溯适用 append-only；
   - `Phase B: governance migration window`：由 `DI-19 + DI-20 + PR-GOV-01~05` 授权，
     允许创建和整理 `Retrospective Reconstruction ADR`，并以显式治理迁移例外修改
     相关治理文档；
   - `Phase C: post-activation governance`：从治理激活点开始，`Native ADR` 受
     append-only 约束，`Ruling` 继续承担规范源职责。
5. 治理例外不是通用授权，而是**迁移窗口内、限定文档集合、限定目的**的显式授权：
   只允许作用于治理执行计划列入范围的文档，且必须写清楚例外原因、作用对象和结束
   条件；治理激活后自动失效。

**T3 当前裁决补充**：

1. `T3` 的目标不是先发明一份抽象模板，而是先定义历史补录 ADR 的
   **最低可接受契约**；不满足该契约的补录文档，不视为合格治理资产。
2. 每篇历史补录 ADR 至少必须声明以下元数据：
   - `Document Class`: `Retrospective Reconstruction ADR`
   - `Narrative Perspective`: 未来视角重述，不是当期原件
   - `Decision Line`: 本文回答的稳定 `why-question`
   - `Coverage Scope`: 覆盖哪些阶段、止于何处
   - `Current Normative Source`: 当前有效 `Ruling`
   - `Source Corpus Summary`: 本文实际采用的关键来源
   - `Revision Record`: 修订记录
3. `source corpus` 不仅要列链接，还必须给出一份 **Corpus Coverage Declaration**，
   按类别声明 `present / absent / not applicable`：
   - `Trigger Source`
   - `Decision Source`
   - `Normative Source`
   - `Execution / Closure Source`
   - `Superseded / Redirected Source`
4. 历史补录 ADR 可以摘要 source corpus，但不得选择性失忆：若已知存在关键方向切换、
   addendum、superseded 轨迹或后续改判，必须显式写出或至少在覆盖声明中说明并给出
   稳定入口。
5. 每篇历史补录 ADR 的正文结构应至少包含：
   - `Reconstruction Notice`
   - `Decision Line`
   - `Source Corpus`
   - `Journey Timeline / Phases`
   - `Current State`
   - `Open Edges`
   - `Revision Record`
6. “未来视角重述”应采用标准声明，明确本文的补录性质、补录日期、所依据的
   `source corpus`，以及“当前规范以链接 `Ruling` 为准”。
7. 在 `PR-GOV-01` ~ `PR-GOV-05` 的治理迁移窗口内，历史补录 ADR 允许受控修订；但每次
   修订只允许出于以下原因：
   - 补入新发现的一级来源
   - 校正事实错误或阶段边界
   - 补回此前遗漏的 superseded / redirected 轨迹
8. 治理激活后，历史补录 ADR 进入“冻结但可勘误”状态：不转为 append-only，但也不再
   自由改写；后续仅允许勘误或补充新发现的一级来源，并必须写入 `Revision Record`。

**T4 前置原则补充**：

1. ADR 的组织轴与历史重演的证据轴不是同一条轴：
   - `source corpus inventory` 按时间顺序建立；
   - `ADR / decision line` 按主题切分建立。
2. 时间轴用于保持因果链和历史忠实度；主题轴用于形成可长期维护、可独立追溯的 ADR。
   两者允许不一致，但不得互相覆盖。
3. 若一份早期来源同时包含多个主题，必须允许“一份来源，多条决策线”；不得因为它们共存
   于同一文档，就被强行合并为同一篇 ADR。
4. 相反，若多个 DI / PR / Ruling 实际回答的是同一个稳定 `why-question`，则允许它们
   被归入同一条 `decision line`，并在同一 ADR 中以多个 `Phase` 表达。
5. `ADR` 的编号顺序和发布顺序，不由“首次出现时间”机械决定，而由主题确认状态、依赖关系
   和重演准备度共同决定。
6. 但每一条 `decision line` 的内部 `Phase` 必须保持时间顺序；不得为了主题叙事便利，
   打乱实际发生顺序。
7. 若某个非基础主题在早期文档中先于基础主题出现，并不自动获得更高优先级；它应根据
   实际依赖关系在主题地图中标明 `upstream dependency` 或 `co-occurrence only`。

**T4 当前裁决补充：decision line extraction rules**：

1. 一条 `decision line` 的边界，以其是否持续回答同一个稳定 `why-question` 为准；若
   核心问题、规范目标或验收语义已经变成另一类问题，则应视为新的 `decision line`。
2. `stable why-question` 采用三元组判定，而不是靠直觉描述：
   - `Decision Subject`：被决定的核心对象是什么
   - `Governing Tension`：该主题持续在解决哪组稳定矛盾
   - `Acceptance Semantics`：什么算“这件事已被正确解决”
3. 只有当 `Decision Subject + Governing Tension + Acceptance Semantics` 仍然保持同一组
   问题时，才视为同一条稳定 `decision line`。若三元组中的任一项发生实质变化，就应高度
   怀疑已经进入新的 `decision line`。
4. 为便于抽取，候选主题应尽量先被重写为标准句：
   `Why should <Decision Subject> be designed as <Direction Class> under <Governing Tension>, so that <Acceptance Semantics> hold?`
5. 满足以下任一情况时，通常应拆成两篇 ADR：
   - 两组材料回答的是不同的核心 `why-question`
   - 其中一条线可以独立继续演进，而另一条线不需要同步变化
   - 其中一条线被 supersede / redirect 后，另一条线仍然成立
   - 两条线对应不同的当前规范源或不同的验收目标
6. 满足以下情况时，通常应合入同一篇 ADR：
   - 材料虽跨多个 DI / PR / Ruling，但持续回答同一个稳定 `why-question`
   - 后续变化属于阶段切换、实现策略变更或前提重估，而不是主题更换
   - 读者若分成两篇 ADR，会丢失该决策线内部的 why-chain
7. “方向翻转”不自动等于新线；若核心仍是同一个 `Decision Subject`，且张力与验收语义未
   变，则更可能是同一条线内的 supersede / redirect / phase change，而不是新的 ADR。
8. 相反，“实现层切换”往往意味着新线：若主题已经从“系统应具备什么语义 / 结构”切换到
   “服务 / FFI / 客户端应如何承载该语义”，通常应视为新的 `Decision Subject`，除非有
   强证据表明三元组保持不变。
9. 主题关系至少区分四类：
   - `upstream dependency`：A 的成立依赖 B 已经确定某项前提或语义边界
   - `inherited context`：A 继承 B 已固定的背景约束，但不重新打开 B 的核心问题
   - `superseding dependency`：A 从 B 出发继续推进，但显式重开并覆盖了 B 的部分结论
   - `co-occurrence only`：A 与 B 只是在同一来源或同一时间共现，并无语义依赖
10. `inherited context` 不等于 `upstream dependency`：前者表示“沿用已定背景”，后者表示
    “当前裁决若无上游结论则无法成立”。
11. `superseding dependency` 不等于普通上游：它说明下游文档不是单纯消费上游结论，而是在推进中
    显式回改、覆盖或 redirect 上游的一部分判断。此类关系必须在主题地图中单独标注，避免把
    “概念重开”误记成普通继承。
12. 主题地图应同时支持两层关系表达：
    - `document-level primary upstream`：当前主题主要依赖哪一份上游文档
    - `clause-level input constraints`：当前主题具体消费了哪些上游 Q / A / 约束
13. 若一个主题的主上游只有一个，但同时吸收了多个上游文档的硬约束，则不得把这些输入压扁成
    单一“继承”关系；至少要保留主上游与次级输入边的区分。
14. `ADR` 编号顺序和发布顺序允许不一致：
    - 编号顺序基于经确认的主题地图
    - 发布顺序基于依赖关系与重演准备度
    - 两者若不一致，主题地图必须同时记录 `first seen in corpus` 与 `published as ADR`
15. `source corpus` 很大时，`PR-GOV-01` 负责 first-pass 主题抽取与候选切分；但最终切分
    不是由盘点执行人单独拍板，而应由对应 `Theme Owner` 与治理 owner 共同确认。
16. 若 first-pass 抽取与最终切分存在分歧，且分歧已经影响主题边界、依赖关系或 ADR 数量，
    则不得靠口头沟通解决；必须在执行文档中留下显式裁决记录，必要时升级为新的 DI。
17. 主题地图不得只靠自由文本描述，必须具备**最小字段模型**。每个主题节点至少记录：
    - `Theme ID`
    - `Decision Line Title`
    - `Stable Why-Question`
    - `Decision Subject`
    - `Governing Tension`
    - `Acceptance Semantics`
    - `Primary Upstream`
    - `Secondary Input Constraints`
    - `Relation Types`
    - `Supersedes / Redirected By`
    - `First Seen In Corpus`
    - `Current Status`
    - `Planned ADR`
    - `Published ADR`
    - `Owner`
    - `Notes`
18. 上述字段的最小职责如下：
    - `Primary Upstream`：文档级主上游
    - `Secondary Input Constraints`：条款级输入边
    - `Relation Types`：记录 `upstream dependency / inherited context / superseding dependency / co-occurrence only`
    - `Supersedes / Redirected By`：记录主题线内部的覆盖或改向
    - `First Seen In Corpus`：记录最早证据出现点
    - `Published ADR`：记录该主题最终落到哪篇正式 ADR
19. `PR-GOV-01` 产出的 first-pass 主题地图即使尚未最终定稿，也必须遵守这套最小字段模型；
    不允许用散文式清单替代结构化字段。
20. 后续若需要为 `topic-map.md` 增加更多展示字段，可追加，但不得删减上述最小字段，除非通过
    新的治理裁决显式修改。

**T4 主题地图最小字段模型（建议表头）**：

| Field | Purpose |
|------|---------|
| `Theme ID` | 主题稳定标识 |
| `Decision Line Title` | 决策线名称 |
| `Stable Why-Question` | 标准化核心问题 |
| `Decision Subject` | 被决定对象 |
| `Governing Tension` | 核心张力 |
| `Acceptance Semantics` | 完成语义 |
| `Primary Upstream` | 文档级主上游 |
| `Secondary Input Constraints` | 条款级输入边 |
| `Relation Types` | 与其他主题/文档的关系类型 |
| `Supersedes / Redirected By` | 覆盖/改向关系 |
| `First Seen In Corpus` | 最早出现位置 |
| `Current Status` | draft / confirmed / published / superseded 等 |
| `Planned ADR` | 预期 ADR 编号或占位 |
| `Published ADR` | 已发布 ADR |
| `Owner` | 主题责任人 |
| `Notes` | 补充说明 |

**T5/T6 前置治理约束：执行降级防护原则**：

1. `Theme Owner` 与 `PR Executor` 是两个不同职责：前者守住主题语义边界与验收目标，
   后者负责本次 PR 的实现与交付；两者不得在口头沟通中直接重写治理目标。
2. 执行中若发现 spec 过重、依赖未就绪或实现路径不可行，允许提出调整建议；但凡涉及
   主题语义、验收标准、规范边界或实现目标的削弱，都不得通过私下沟通直接生效。
3. 所有可能构成“实现降级”的变化，必须显式落为文档化决策，且至少归类为以下三者之一：
   - `implementation staging`：仅分阶段交付，不改变最终语义目标
   - `scope reduction`：缩小本 PR 范围，但不改规范目标
   - `semantic downgrade`：降低语义目标或验收标准
4. 其中 `semantic downgrade` 不得由执行 PR 自行吸收，必须升级为新的 DI、对现有 DI 的
   显式 supersede/replacement，或等效治理裁决记录。
5. 每个治理执行 PR 除 `Theme Delta Contract` 外，还应声明：
   - `Must Preserve`
   - `Allowed Simplifications`
   - `Escalation Required If Violated`
6. Review / audit 的判断单位不是“代码能跑”，而是“是否满足 DI / Ruling / PR spec 中
   已承诺的语义目标”；未记录的语义折损不视为合格完成。
7. `Theme Owner` 拥有对语义降级的 veto 权，但没有通过口头确认直接放宽规范的权力；
   规范变更仍必须回到治理文档。

**T5/T6 执行化补充：anti-downgrade gate**：

1. 流程模板负责把“潜在降级”变成显式对象。每个治理 PR 在进入 review 前，除
   `Theme Delta Contract` 外，还必须补齐：
   - `Must Preserve`
   - `Allowed Simplifications`
   - `Escalation Required If Violated`
   - `Accepted Debt` / `Debt Owner` / `Debt Expiry or Exit Condition`
2. 自动化检查负责抓结构违规，而不是假装自动理解语义。CI / 检测程序至少应检查：
   - 上述字段是否存在且非空
   - 若声明 `semantic downgrade` 或等效表述，是否附带 DI / supersede / deviation doc
   - 是否存在 `Theme Owner`
   - 必要回链是否成立
   - 是否出现未登记 debt 标记
3. 人工 gate 负责抓语义降级。`Theme Owner sign-off` 不可省略，因为“是否构成语义折损”
   很多时候是治理判断，不是结构检查能自动完成的事。
4. 收口审计按“承诺兑现”而非“代码可运行”验收：closure audit 必须回看 DI / Ruling /
   PR contract，确认没有把未记录的语义缩水包装成已完成交付。
5. 结论：模板 + CI 可以大量压缩隐性降级空间，但不能替代 owner sign-off 和收口审计；
   三者必须同时存在，才构成有效的 anti-downgrade gate。

**T5 当前裁决补充：Theme Delta Contract**：

1. `Theme Delta Contract` 不应只是一张“本 PR 覆盖了哪些主题”的静态列表，而应描述本 PR
   对主题地图施加了什么增量。
2. 因此，每个治理 PR 对每个 `Covered Theme` 都必须声明至少一项 `Theme Operation`。推荐操作类型：
   - `inventory`
   - `confirm`
   - `split`
   - `merge`
   - `supersede`
   - `redirect`
   - `publish_adr`
   - `backlink_sync`
   - `closure_audit`
   - `template_sync`
3. 若 PR 涉及主题边界变化，则不得只改 ADR 正文，必须同时更新主题地图中的对应字段：
   至少包括 `Relation Types`、`Supersedes / Redirected By`、`Current Status`、`Planned ADR` /
   `Published ADR`。
4. 每个 `Covered Theme` 在合同中至少应记录：
   - `Theme ID`
   - `Theme Operation`
   - `Before Status`
   - `After Status`
   - `Docs Touched`
   - `Must Preserve`
   - `Verification`
5. PR 级合同除主题行之外，还必须有全局字段：
   - `Primary Theme Owner`
   - `PR Executor`
   - `Out of Scope`
   - `Allowed Simplifications`
   - `Escalation Required If Violated`
   - `Accepted Debt / Debt Owner / Debt Exit`
   - `Required Sign-off`
6. `Docs Touched` 不能只列文件路径，还必须能回指到主题地图中的主题行；反过来，凡是主题合同声称
   有变化，也必须能在输出文档中找到对应落点。禁止“改了文档但没有主题 delta”或“宣称主题 delta
   但找不到文档落点”。
7. 若 PR 仅做结构同步（如索引、回链、README 更新），也不能写成“无主题影响”；应通过
   `backlink_sync` / `closure_audit` / `template_sync` 等操作类型显式记录其治理作用。
8. 只有在 PR 确实不改变任何主题地图字段、也不触发任何治理义务时，才允许声明
   `No Theme Delta`；且必须附理由，不得留空。
9. `Theme Delta Contract` 的验收不是“字段填满”，而是：
   - 合同中的主题行与主题地图一致
   - 合同中的 `Docs Touched` 与实际产出一致
   - `Before Status -> After Status` 合理
   - 必要 sign-off 齐备
10. 结论：PR 不再只声明“覆盖哪些主题”，而是声明“对哪些主题施加了什么增量、保留了什么、
    用什么文档和什么验证闭环”。

**T6 当前裁决补充：Consistency, Backlink, and Traceability Gates**：

1. `T6` 不再被理解为一次模糊的大审计，而是拆成 4 层 gate + 1 份收口产物：
   - `Structural Checks`
   - `Graph Checks`
   - `Policy Checks`
   - `Semantic Review`
   - `Closure Audit Output`
2. `Structural Checks` 负责最低结构完整性，优先自动化：
   - 链接不悬挂
   - 必填字段存在且非空
   - 状态词合法
   - 必要章节存在
   - 主题地图字段齐全
   - `Theme Delta Contract` 结构齐全
3. `Graph Checks` 负责文档网络可达性与关系自洽，可用脚本或 CI 检查：
   - 每个 `Theme ID` 都真实存在于主题地图
   - 每条 `Theme Delta Row` 都能指向真实主题
   - `Primary Upstream`、`Secondary Input Constraints`、`Published ADR` 指向真实对象
   - 已发布 ADR 能反查回主题地图
   - 关系边端点真实存在
   - 依赖边（`upstream dependency` / `inherited context` / `superseding dependency`）应保持有向无环
   - 不允许 orphan theme / orphan ADR / orphan PR delta
4. `Policy Checks` 负责“结构合法但治理违规”的情况，适合做半自动检查：
   - `publish_adr` 必须同步更新 `Current Status` 与 `Published ADR`
   - `split / merge / supersede / redirect` 必须同步更新主题地图关系字段
   - `semantic downgrade` 必须附带 DI / supersede / deviation 记录
   - `No Theme Delta` 必须写明理由
   - `Docs Touched` 必须能在输出文档中找到对应落点
5. `Semantic Review` 保留为人工 gate，不伪装成可完全自动化：
   - `stable why-question` 是否真的保持稳定
   - `upstream dependency` / `inherited context` / `superseding dependency` 是否判定正确
   - 是否存在隐藏的 split / merge
   - 是否存在选择性失忆或未记录的语义降级
6. 自动化与人工的边界应明确：
   - CI 优先覆盖 `Structural Checks`、`Graph Checks` 和可结构化的 `Policy Checks`
   - `Theme Owner` / governance owner 负责 `Semantic Review` 与剩余政策判断
   - 不允许用“CI 全绿”替代语义 sign-off
7. `Closure Audit Output` 是版本级一致性审计的正式产物，至少应记录：
   - 各 gate 的 pass / fail 结果
   - 例外项与理由
   - 已接受 debt 与 owner
   - 尚未闭合的语义判断
   - 是否满足治理激活前提
8. 结论：`T6` 的目标不是证明“所有文档都长得像对的”，而是证明“文档结构、关系图、政策约束和语义判断共同闭环”。

**T7 当前裁决补充：Per-PR Entry / Exit Gates**：

1. `T7` 不仅定义总体顺序，还必须为每个 `PR-GOV-*` 定义显式 `entry gate` 与 `exit gate`；
   未满足前一阶段 `exit gate`，不得进入后一阶段实施。
2. 所有治理 PR 的通用 `entry gate`：
   - 已声明 `Theme Delta Contract`
   - `Covered Themes`、`Theme Operations`、`Owner`、`Verification` 非空
   - `Out of Scope` 明确
   - 必要 sign-off 责任人已指定
3. `PR-GOV-01` 的 `exit gate`：
   - source corpus 盘点完成且有稳定清单
   - first-pass 主题地图已按最小字段模型产出
   - coverage matrix 基线已建立
   - 关键 split / merge 分歧已记录，而不是留在口头讨论中
4. 只有在 `PR-GOV-01 exit gate` 满足后，才允许进入 `PR-GOV-02`。`PR-GOV-02` 的 `exit gate`：
   - `adr/` 目录结构与 `README.md` / `topic-map` 骨架建立
   - 历史补录 ADR 的元数据合同与标准声明定稿
   - 主题地图中的 `Planned ADR` 字段至少达到可用占位状态
5. 只有在 `PR-GOV-02 exit gate` 满足后，才允许进入 `PR-GOV-03`。`PR-GOV-03` 的 `exit gate`：
   - 首批历史补录 ADR 已产出
   - 每篇补录 ADR 具备 source corpus、reconstruction notice、revision record
   - 已发布 ADR 与主题地图之间存在双向稳定映射
   - 未完成主题被保留在主题地图中，而不是被默默遗漏
6. 只有在 `PR-GOV-03 exit gate` 满足后，才允许进入 `PR-GOV-04`。`PR-GOV-04` 的 `exit gate`：
   - `Theme Delta Contract` 模型定稿
   - 最低回链规则落地
   - `T6` 的结构性 / 图结构 / 政策检查至少达到可运行状态
   - 索引同步策略形成可执行规则
7. 只有在 `PR-GOV-04 exit gate` 满足后，才允许进入 `PR-GOV-05`。`PR-GOV-05` 的 `exit gate`：
   - repo-wide 一致性审计已执行
   - `Closure Audit Output` 已出具
   - 例外项、debt、未闭合判断已显式记录
   - 治理激活文档已明确 append-only 生效点
8. `PR-GOV-06` 的 `entry gate` 是：治理激活已经完成，且 `Closure Audit Output` 未显示阻断级失败。
   `PR-GOV-06` 的 `exit gate`：
   - lifecycle/template 仅回填已验证过的流程
   - 计划抽离的模板与 playbook 仅定稿已被本轮执行验证过的部分
   - 回填内容与本轮治理执行经验一致
   - 未把仍处于实验态的规则提前模板化
9. 若任一 PR 在执行中发现其 `exit gate` 无法满足，不得通过缩写交付声明“先合后补”；必须：
   - 显式记录阻断点
   - 更新 `Theme Delta Contract`
   - 必要时回退到上游主题或升级为新的治理裁决
10. 结论：顺序不是“建议顺序”，而是带 `entry/exit` 条件的 stage-gated execution；这才是
    `T7` 真正的治理价值。

---

### Q2. PR 应如何声明主题覆盖责任？

用户已经明确提出一个关键要求：每个 PR 必须说明自己修复/覆盖了哪些 DI-19
主题；最终所有 PR 的并集必须覆盖全部有效主题。

#### Q2 裁决：每个 PR 必须携带 Theme Delta Contract

每个治理执行 PR 必须显式声明一份 **Theme Delta Contract**，至少包含：

| 字段 | 说明 |
|------|------|
| Covered Themes | 本 PR 负责处理的 `T1-T8` 主题 |
| Theme Operations | 对每个主题执行的操作类型 |
| Primary Theme Owner | 若某主题在多个 PR 中出现，谁是主责任 PR |
| PR Executor | 本 PR 的执行责任人 |
| Secondary Coverage | 本 PR 对其他主题的辅助覆盖 |
| Out of Scope | 本 PR 明确不处理哪些主题 |
| Must Preserve | 本 PR 不得削弱的语义与约束 |
| Allowed Simplifications | 允许的阶段性简化 |
| Escalation Required If Violated | 何种情况必须升级为治理裁决 |
| Accepted Debt | 本 PR 显式接受的技术债与责任归属 |
| Output Docs | 本 PR 新增/修改的治理文档 |
| Verification | 如何验证本 PR 对主题的覆盖成立 |
| Required Sign-off | 需要的 owner / governance sign-off |

**约束规则**：

1. 每个 PR 至少覆盖 1 个主题；
2. 每个主题必须至少有 1 个 **Primary Owner PR**；
3. 允许一个 PR 覆盖多个主题；
4. 允许多个 PR 覆盖同一主题，但必须指定主责任 PR；
5. 最终所有 PR 的 `Covered Themes` 并集必须覆盖 `T1-T8` 全部主题；
6. 每个 `Covered Theme` 必须有显式 `Theme Operation`，不得只列主题名；
7. 若合同声明了主题增量，则主题地图与输出文档中必须存在对应落点；
8. 若声明 `No Theme Delta`，必须给出理由并通过 review 确认。

**直接推论**：

- 不是“每个 PR 覆盖全部主题”；
- 而是“每个 PR 对明确主题施加明确增量，最终所有 PR 的增量闭合集合覆盖全部主题”。

---

### Q3. PR 依赖图与提交顺序如何安排？

治理执行不能一上来就改 template，因为 template 代表稳定流程；在流程尚未经受
一次完整执行前，先改 template 会把未验证经验过早固化。

#### Q3 裁决：6 PR 线性执行，先重演、再审计、后激活、最后沉淀

**最终序列**：

| PR | 主题覆盖 | 核心产出 | 依赖 |
|----|---------|---------|------|
| `PR-GOV-01` | `T1`, `T3`, `T4`, `T7` | source corpus 盘点 + 主题地图 + coverage matrix 基线 + 模板抽离清单 | — |
| `PR-GOV-02` | `T1`, `T2`, `T3` | ADR handoff skeleton（README / topic-map）+ 历史补录元数据规范 | `PR-GOV-01` |
| `PR-GOV-03` | `T3`, `T4` | 首批历史补录 ADR 草稿包 | `PR-GOV-01`, `PR-GOV-02` |
| `PR-GOV-04` | `T5`, `T6` | Theme Delta Contract、回链/一致性审计规则、索引同步 + 执行模板草案 | `PR-GOV-02`, `PR-GOV-03` |
| `PR-GOV-05` | `T2`, `T6`, `T7` | 治理激活草稿 + repo-wide 一致性审计收口包 + 激活/审计模板验证 | `PR-GOV-04` |
| `PR-GOV-06` | `T5`, `T8` | 将稳定下来的流程回填到 lifecycle/template + 定稿模板与 playbook | `PR-GOV-05` |

**线性顺序**：

```
PR-GOV-01
  → PR-GOV-02
    → PR-GOV-03
      → PR-GOV-04
        → PR-GOV-05
          → PR-GOV-06
```

**原因**：

1. `PR-GOV-01` 先确立 source corpus 和主题地图，否则后续 ADR 和 PR 覆盖都
   没有统一基线；
2. `PR-GOV-02` 先搭建结构和元数据合同，才能安全承载历史补录 ADR；
3. `PR-GOV-03` 先完成历史重演，后续一致性审计才有可审对象；
4. `PR-GOV-04` 在补录之后再补回链和一致性规则，避免规则先写、对象不存在；
5. `PR-GOV-05` 必须在审计完成后才宣布治理激活；
6. `PR-GOV-06` 最后才把经验回填到 lifecycle template，避免过早模板化。

**当前边界说明**：

1. 上表描述的是 future `v0.4 kickoff` 进入主线前的组织顺序；
2. 在当前 `docs/reports/v0.3/governance-kickoff-prep/` 阶段，`PR-GOV-02 ~ 05`
   只产出 handoff skeleton、draft package 与 prep-layer evidence；
3. 正式 `docs/architecture/adr/` 资产与主线激活动作，仍留给 future kickoff mainline
   的正式 PR 组织阶段。

---

### Q4. 如何定义治理收口标准？

如果没有明确 closure 标准，执行到一半就会开始修改 template，或在还有主题未
覆盖时就声称“治理已经落地”。

#### Q4 裁决：以 Theme Coverage Closure 为唯一收口门

治理执行收口必须满足以下全部条件：

1. `T1-T8` 全部主题至少被一个 PR 覆盖；
2. 每个主题都存在主责任 PR；
3. 每个治理 PR 都包含 Theme Delta Contract；
4. 首批历史补录 ADR 已明确标注“未来视角重述”与 source corpus；
5. repo-wide 一致性审计已执行并出具结果；
6. 治理激活点已用独立文档明确声明；
7. lifecycle/template 的回填发生在治理激活之后，而不是之前。

**收口判断单位**不是“文档数量”或“已创建 ADR 篇数”，而是
**主题覆盖闭合（Theme Coverage Closure）**。

---

**T8 当前裁决补充：Template / Playbook / Lifecycle Backfill Boundary**：

1. `T8` 关注的不是单一 `release-lifecycle-template.md` 文件，而是**稳定治理流程如何
   从执行报告中提炼为长期操作资产**；
2. `DI-20` 在 `T8` 中保留为执行报告与上下文来源，不作为未来长期执行时的主操作
   手册；
3. `template`、`playbook`、`lifecycle` 三者的职责必须分离：
   - `template` 承载可填写、可复用的操作骨架；
   - `playbook` 承载稳定的动作入口、gate 与导航；
   - `lifecycle template` 承载版本级 release 流程的通用回填要求；
4. `T8` 的所有回填动作都必须后置到治理激活之后，并且只允许沉淀经本轮执行验证过
   的稳定流程。

### Q5. 何时才能修改 release lifecycle template？

这是当前最容易提前动作的一步，但也是最不应该最早发生的一步。

#### Q5 裁决：template 回填必须后置到治理激活完成之后

`release-lifecycle-template.md` 是**总结性模板文档**，不是治理实验场。

因此：

1. 在 `PR-GOV-01` ~ `PR-GOV-05` 期间，不直接把未验证流程沉淀进 template；
2. 只有在历史重演、审计、治理激活全部完成后，才能进入 `PR-GOV-06`；
3. `PR-GOV-06` 的内容必须来自已验证执行经验，而不是来自事前假设。

这保证 template 记录的是“经执行验证的流程”，而不是“尚未证明有效的理想
流程”。

#### Q5 当前裁决补充：DI-20 保留为执行报告，模板抽离纳入 PR 规划

`DI-20` 当前承担的是**本轮治理迁移的执行报告与上下文说明**，而不是未来各版本
复用时的主操作手册。因此：

1. `DI-20` 可以作为模板、playbook、lifecycle 回填的**来源文档**，但不应成为
   未来执行治理动作时的主要操作入口；
2. 未来可复用的“怎么做 / 要怎么做 / 能怎么做”内容，应在治理执行完成后，提炼到
   `docs/development/report-templates/` 与后续的治理 playbook 中；
3. 在本轮治理执行尚未完成前，不提前创建完整模板正文；先把**模板抽离计划**纳入
   `PR-GOV-*` 序列，待对应 gate 满足后再逐步落地。

#### Q5 当前裁决补充：模板抽离计划

下表定义本轮治理迁移中预计抽离的稳定模板资产，以及它们各自的规划、起草、定稿
阶段。此表是 `T8` 的执行约束，不代表这些模板已可立即创建。

| Template / Playbook | 目的 | 规划阶段 | 起草阶段 | 定稿阶段 | 目标位置 |
|---------------------|------|----------|----------|----------|----------|
| `retrospective-reconstruction-adr-template.zh-CN.md` | 历史补录 ADR 的最低契约与固定段落 | `PR-GOV-02` | `PR-GOV-03` | `PR-GOV-06` | `docs/development/report-templates/` |
| `governance-theme-map-template.zh-CN.md` | 主题地图最小字段模型与填写约束 | `PR-GOV-01` | `PR-GOV-04` | `PR-GOV-06` | `docs/development/report-templates/` |
| `governance-theme-delta-contract-template.zh-CN.md` | PR 级 `Theme Delta Contract` 模板 | `PR-GOV-04` | `PR-GOV-04` | `PR-GOV-06` | `docs/development/report-templates/` |
| `governance-closure-audit-template.zh-CN.md` | `Closure Audit Output` 模板 | `PR-GOV-04` | `PR-GOV-05` | `PR-GOV-06` | `docs/development/report-templates/` |
| `governance-activation-template.zh-CN.md` | 治理激活与 append-only 生效声明 | `PR-GOV-05` | `PR-GOV-05` | `PR-GOV-06` | `docs/development/report-templates/` |
| `governance-playbook.md` | 未来执行时的总操作入口与导航 | `PR-GOV-05` | `PR-GOV-06` | `PR-GOV-06` | `docs/development/` |

**模板抽离约束**：

1. `PR-GOV-01` 只负责识别需要哪些模板，不负责创建模板正文；
2. `PR-GOV-02` 允许锁定 ADR 类模板的字段与骨架，但不把未验证流程写成稳定模板；
3. `PR-GOV-03` 通过实际历史补录 ADR 验证补录模板的必要字段与段落；
4. `PR-GOV-04` 才允许起草主题地图、`Theme Delta Contract`、closure audit 等执行模板；
5. `PR-GOV-05` 通过真实审计与治理激活文档验证模板是否足够承载执行闭环；
6. `PR-GOV-06` 才允许将已验证模板正式放入 `docs/development/report-templates/`，
   并由 `release-lifecycle-template.md` 或 `governance-playbook.md` 引用；
7. 若某模板在其对应 PR 阶段尚未经过真实执行验证，则该模板必须继续留在计划态，
   不得提前定稿。
8. `Native ADR template` **不属于当前 `PR-GOV-01 ~ PR-GOV-06` 收口范围**。它应在
   治理激活完成、且至少经历一轮真实 Native ADR 工作流之后，再作为
   `post-activation follow-up` 单独规划与定稿；在本轮中应显式视为 deferred，而不是
   被默默忽略。

#### Q5 当前裁决补充：governance-playbook 的边界与最小骨架

`governance-playbook.md` 的定位是**未来执行治理动作时的稳定操作入口**，不是新的
规范源，也不是 `DI-20` 的压缩摘要。因此：

1. `playbook` 只回答“何时触发、先做什么、用什么模板、经过哪些 gate、由谁 sign-off”；
2. `playbook` 不重写 `DI-19` 的规则正文，也不重写 `DI-20` 的版本上下文与取舍过程；
3. 若某条规则涉及治理边界、例外、生效范围，`playbook` 只做摘要并回链**相关治理
   裁决文档**；在当前基线下通常指向 `DI-19`，在治理激活后则应指向对应的
   Native ADR / Ruling；
4. 若某条规则涉及本轮执行经验、PR 依赖、迁移窗口内的具体安排，`playbook` 只做
   入口说明并回链 `DI-20`；
5. `playbook` 的章节组织必须按**动作**而不是按历史或 `T1-T8` 编号组织，避免再次
   变成上下文密集型报告。

`governance-playbook.md` 的最小章节骨架应至少包括：

1. `Purpose and Boundaries`
2. `Trigger Conditions`
3. `Required Roles`
4. `Workflow Overview`
5. `Required Artifacts`
6. `Gates and Sign-off`
7. `Allowed Exceptions`
8. `Template Index`
9. `Reference Documents`

**落地约束**：

1. `PR-GOV-05` 只允许确定 `playbook` 的边界、入口动作和引用关系；
2. `PR-GOV-06` 才允许依据已闭合的治理执行经验起草并定稿 `playbook`；
3. `playbook` 不得包含本轮尚未验证的实验规则，也不得替代 `Ruling` 作为规范源；
   对“为什么这样演进、何时激活、如何分期”的说明，则应回链相关 ADR / 治理裁决；
4. 若后续治理流程再次演进，应优先新增或更新**相关治理裁决文档**，再回填
   `playbook`；治理激活前通常体现为新的 DI / 治理修订文档，治理激活后则应体现为
   新的 Native ADR（及必要的 Ruling），而不是优先回改 `DI-19`。

---

## 主题覆盖矩阵（初版）

| 主题 | 主责任 PR | 辅助 PR | 闭合证据 |
|------|-----------|--------|---------|
| `T1` | `PR-GOV-02` | `PR-GOV-01` | `adr/` 结构 + 主题地图 |
| `T2` | `PR-GOV-05` | `PR-GOV-02` | 治理激活文档 + 生效边界说明 |
| `T3` | `PR-GOV-03` | `PR-GOV-01`, `PR-GOV-02` | 历史补录 ADR |
| `T4` | `PR-GOV-03` | `PR-GOV-01` | ADR 主题切分与决策线实例 |
| `T5` | `PR-GOV-04` | `PR-GOV-06` | Theme Delta Contract + 执行模板回填 |
| `T6` | `PR-GOV-04` | `PR-GOV-05` | 一致性审计与回链结果 |
| `T7` | `PR-GOV-05` | `PR-GOV-01` | 激活前后顺序闭环 |
| `T8` | `PR-GOV-06` | `PR-GOV-04`, `PR-GOV-05` | lifecycle template + playbook + 稳定模板更新 |

注：若后续执行中调整 PR 拆分，可改主责任 PR，但不得让任何主题失去 owner。

---

## Per-PR 最低模板

每个治理执行 PR 至少应包含如下最小段落：

```text
## Theme Delta Contract

| 字段 | 内容 |
|------|------|
| Covered Themes | T? , T? |
| Theme Operations | confirm / split / publish_adr / ... |
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
| TH-? | ... | ... | ... | ... | ... | ... |
```

---

## 风险与缓解

| 风险 | 表现 | 缓解 |
|------|------|------|
| 先改模板后执行 | 未验证规则被固化 | 强制 `PR-GOV-06` 后置 |
| PR 覆盖写文件不写主题 | 文档很多但治理义务不清 | 强制 Theme Delta Contract |
| 主题无人负责 | 收口时发现空白区 | Coverage matrix 预先分配 owner |
| 提前锁定首批 ADR 主题 | 历史重演被预设结论牵引 | `PR-GOV-01` 先做 source corpus 盘点 |
| 只靠单点索引追溯 | 索引漂移后全局失真 | `PR-GOV-04` 补回链与一致性审计 |

---

## 关联

- ← [DI-19-adr-governance.md](DI-19-adr-governance.md)（治理规则与有效主题）
- → [../governance-kickoff-prep/PR-GOV-01-source-corpus-and-theme-map-baseline.md](../governance-kickoff-prep/PR-GOV-01-source-corpus-and-theme-map-baseline.md)（future `v0.4 kickoff` 的首个候选 PR spec）
- → [../governance-kickoff-prep/README.md](../governance-kickoff-prep/README.md)（治理 kickoff 筹备 PR 草案目录）
- → `release-lifecycle-template.md`（在 `PR-GOV-06` 阶段回填）
