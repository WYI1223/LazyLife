# DOC-012 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-4-buffer-sync-model.md`
- Title: `DI-4: Buffer 同步模型 + 粒度`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- This is one of the densest technical-contract sources in the corpus and cannot be represented accurately by top-level `Q1-Q5` alone.
- `Q1`, `Q2`, `Q3`, and `Q5` each already contain multiple stable `###` anchors, and `Q1 补充` expands further into `####`-level protocol/design anchors.
- `Q4` is even denser: the source uses explicit `细化1/3/2/4` headings in that exact order, so survey should preserve the source order rather than silently renumbering it.
- The line `# 我的巨著` appears inside an illustrative example and is not a document-level survey anchor.

## Candidate DN Anchors

### Intake / framing anchors

- `## 问题提取 / ### 来源 §1 执行摘要`
- `## 问题提取 / ### 来源 §4.3 设计空白详析`
- `## 问题提取 / ### 设计决策（审计报告原文）`
- `## 问题提取 / ### 审计报告 §6.3 — 执行方法论评估`
- `## 问题提取 / ### DI-3 边界约定（阶段 2 入口）`
- `## 讨论大纲`

### Q1 anchors

- `## Q1: D10 同步模型选型 — RESOLVED / ### 当前代码实现`
- `## Q1: D10 同步模型选型 — RESOLVED / ### 已有裁决约束`
- `## Q1: D10 同步模型选型 — RESOLVED / ### 三选项分析`
- `## Q1: D10 同步模型选型 — RESOLVED / ### 同步时机：为什么必须实时（per-keystroke）`
- `## Q1: D10 同步模型选型 — RESOLVED / ### 性能分析`
- `## Q1: D10 同步模型选型 — RESOLVED / ### 消费者分层设计原则`
- `## Q1: D10 同步模型选型 — RESOLVED / ### 与 EditorResolver 的关系`
- `## Q1: D10 同步模型选型 — RESOLVED / ### 裁决`

### Q1 supplement anchors

- `## Q1 补充：编辑范式兼容与同步协议 / #### 三种编辑范式`
- `## Q1 补充：编辑范式兼容与同步协议 / #### 持久化模型：Markdown + Sidecar Overlay`
- `## Q1 补充：编辑范式兼容与同步协议 / #### Block 能力分级`
- `## Q1 补充：编辑范式兼容与同步协议 / #### Reconciliation 协议`
- `## Q1 补充：编辑范式兼容与同步协议 / #### 同步协议：三路 EditOp`
- `## Q1 补充：编辑范式兼容与同步协议 / #### 跨模式同步 SLA`
- `## Q1 补充：编辑范式兼容与同步协议 / #### 运行时层级模型`
- `## Q1 补充：编辑范式兼容与同步协议 / #### v0.3 实现 vs 预留`

### Q2 anchors

- `## Q2: D11 同步粒度 — RESOLVED / ### 当前代码实现`
- `## Q2: D11 同步粒度 — RESOLVED / ### 已有裁决约束`
- `## Q2: D11 同步粒度 — RESOLVED / ### Q1 与 Q2 的关系澄清`
- `## Q2: D11 同步粒度 — RESOLVED / ### 三选项分析`
- `## Q2: D11 同步粒度 — RESOLVED / ### 两层模型`
- `## Q2: D11 同步粒度 — RESOLVED / ### 性能估算`
- `## Q2: D11 同步粒度 — RESOLVED / ### 消费者侧的 delta 应用路径`
- `## Q2: D11 同步粒度 — RESOLVED / ### 持久化粒度`
- `## Q2: D11 同步粒度 — RESOLVED / ### 大文档演化路径`
- `## Q2: D11 同步粒度 — RESOLVED / ### 裁决`

### Q3 anchors

- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### 问题定义`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### 当前实现分析`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### 目标架构：Manual Listener`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### 循环风险确认`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### 字符串比较守卫的通用性`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### 方案比较`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### Buffer 加载阶段处理`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### Mixin 提取策略`
- `## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED / ### 裁决`

### Q4 anchors

- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 问题定义`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 当前代码实现`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 已有裁决约束`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化议题`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化1: 触发时序 — RESOLVED / #### 用户体感分析`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化1: 触发时序 — RESOLVED / #### 方案比较`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化1: 触发时序 — RESOLVED / #### 耗时拆解`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化1: 触发时序 — RESOLVED / #### 阶段 1 -> 阶段 2 衔接`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化1: 触发时序 — RESOLVED / #### Layout 加载失败保护`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化1: 触发时序 — RESOLVED / #### 裁决`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化3: 加载职责归属 — RESOLVED / #### 当前实现`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化3: 加载职责归属 — RESOLVED / #### 方案比较`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化3: 加载职责归属 — RESOLVED / #### Coordinator 作为接线员原则`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化3: 加载职责归属 — RESOLVED / #### Service 双闭包对称设计`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化3: 加载职责归属 — RESOLVED / #### content_type 扩展性`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化3: 加载职责归属 — RESOLVED / #### 裁决`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化2: 优先级与调度 — RESOLVED / #### 内存估算`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化2: 优先级与调度 — RESOLVED / #### 调度策略`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化2: 优先级与调度 — RESOLVED / #### 资源生命周期架构预留`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化2: 优先级与调度 — RESOLVED / #### 裁决`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化2: 优先级与调度 — RESOLVED / #### 补充：渲染策略前瞻`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化4: 失败处理与运行时统一 — RESOLVED / #### 失败信号设计`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化4: 失败处理与运行时统一 — RESOLVED / #### 失败场景处理`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化4: 失败处理与运行时统一 — RESOLVED / #### 运行时统一`
- `## Q4: 阶段 2 内容加载策略 — RESOLVED / ### 细化4: 失败处理与运行时统一 — RESOLVED / #### 裁决`

### Q5 anchors

- `## Q5: 方法论 — RESOLVED / ### 审计报告建议`
- `## Q5: 方法论 — RESOLVED / ### §6.3 原始顾虑解消状态`
- `## Q5: 方法论 — RESOLVED / ### 裁决：方案 A（仅文档）`

## Notes

- The previous survey was still too coarse: it treated most of `Q1-Q3/Q5` as single anchors and only partially expanded `Q4`.
- `Q4` must preserve the source’s actual refinement order `1 -> 3 -> 2 -> 4`; re-sorting it would lose traceability to the original document.
- The illustrative heading `# 我的巨著` is intentionally excluded because it belongs to an example block, not the document’s decision structure.
