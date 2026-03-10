# DOC-023 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md`
- Title: `DI-15: Rust Core 数据模型 — 工作区树架构`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- The document has four distinct layers: architecture-shift framing, superseded single-root rulings `Q1-Q6`, active multi-root rulings `Q7-Q12`, and a separate cross-workspace security model section.
- The superseded block is still part of the historical decision line and must remain separable from the current multi-root block.
- The framing layer matters because it explains why the document changes direction midstream and which inherited DI-12 constraints are preserved, adjusted, or covered.
- `Q3`, `Q4`, `Q7`, `Q9`, and `Q11` each expand into lower-level subclauses that are the actual minimum stable anchors.

## Candidate DN Anchors

### Framing anchors

- `## 背景`
- `### 架构方向变更说明 / **从单根到多根的核心洞察**`
- `### 输入约束（从 DI-12 继承，部分被多根方案覆盖）`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`

### Superseded single-root anchors

- `## 已替代的裁决（Q1-Q6，原单根方案） / ### Q1. 系统节点 role 存储机制？（~~RESOLVED~~ -> SUPERSEDED）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / ### Q2. ROOT 节点的表达方式？（~~RESOLVED~~ -> SUPERSEDED）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / ### Q3. Migration SQL 设计？（~~RESOLVED~~ -> SUPERSEDED）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### Q3.1 系统节点 UUID 生成策略（RESOLVED）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### Q3.2 回填规则（RESOLVED）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### Q3.3 UNIQUE 约束（RESOLVED）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### Q3 综合：Migration SQL 草案`
- `## 已替代的裁决（Q1-Q6，原单根方案） / ### Q4. Active 可见性不变量与数据层保证？（RESOLVED — 微调后保留，见 Q7 附注）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### 不变量定义`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### 写路径保证机制`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### 巡检修复前提`
- `## 已替代的裁决（Q1-Q6，原单根方案） / #### 级联 soft-delete 触发器（RESOLVED — 不加）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / ### Q5. 系统节点保护约束的实现层级？（~~RESOLVED~~ -> SUPERSEDED）`
- `## 已替代的裁决（Q1-Q6，原单根方案） / ### Q6. 迁移回滚与版本门禁？（RESOLVED — 不变，保留）`

### Active multi-root anchors

- `## 多根森林裁决（Q7-Q12） / ### Q7. Workspace Root 表达与拓扑规则？（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q7.1 workspace root 如何识别？（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q7.2 parent_uuid IS NULL 多行约束（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q7.3 可见性不变量微调（承接 Q4）（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / ### Q8. system_role 列处置？（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / ### Q9. Workspace 元数据存储？（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q9.1 Designated Folder 映射与保护（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / ### Q10. origin_workspace_id 字段设计？（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / ### Q11. Migration SQL 设计？（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q11.1 UUID 策略（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q11.2 回填规则（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q11.3 Designated Folders 创建时机（RESOLVED）`
- `## 多根森林裁决（Q7-Q12） / #### Q11.4 现有触发器兼容性`
- `## 多根森林裁决（Q7-Q12） / #### Q11 综合：Migration 执行流程草案`
- `## 多根森林裁决（Q7-Q12） / ### Q12. Workspace Root 保护约束？（RESOLVED）`

### Security model anchors

- `## 跨工作区安全模型 / ### 根本约束：Local-first 下代码逻辑不等于安全`
- `## 跨工作区安全模型 / ### 三层安全架构`
- `## 跨工作区安全模型 / ### v0.x 方案（当前阶段）`
- `## 跨工作区安全模型 / ### v1.x 存储加密方向（预留）`
- `## 跨工作区安全模型 / ### 不可解悖论（The Local-First Paradox）`

## Notes

- `DI-15` is one of the most important “do not flatten” sources in the corpus: superseded history, current data model, and security framing all coexist.
- The earlier survey was under-specified because it skipped the architecture-shift framing and inherited-constraint layer that explain why `Q1-Q6` were superseded and how `Q7-Q12` should be interpreted.
- The security-model section is not merely commentary; it carries architectural constraints that can later affect governance classification.
