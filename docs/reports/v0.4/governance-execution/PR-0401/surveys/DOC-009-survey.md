# DOC-009 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-1-editor-shell-service.md`
- Title: `DI-1: EditorShellService 接口设计 + 状态归属`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- This source is not just a flat `Q1-Q5` ruling chain. It has three distinct layers:
  - upstream intake and S2 baseline (`问题提取`, `S2 裁决已定义的方向`)
  - primary question blocks `Q1-Q5`
  - deeper refinement ladders under `Q3` and `Q4`
- `Q3` is the densest block in the document and explicitly splits into `细化 1-4`; those subanchors are the minimum stable extraction units for the draft/save line.
- `Q4` also already splits into three stable refinement anchors; keeping it as one monolithic `Q4` would lose the distinction between tab title, coordinator shape, and workspace-tree extraction.

## Candidate DN Anchors

### Intake / baseline anchors

- `## 问题提取 / ### 来源 §4.1 设计空白详析`
- `## 问题提取 / ### 审计报告原始决策点`
- `## S2 裁决已定义的方向`

### Primary question anchors

- `## Q1: EditorGroupModel 拥有什么状态？ — RESOLVED / ### 设计原则`
- `## Q1: EditorGroupModel 拥有什么状态？ — RESOLVED / ### 裁决`
- `## Q2: EditorGroupModel 生命周期 — RESOLVED / ### 核心规则`
- `## Q2: EditorGroupModel 生命周期 — RESOLVED / ### 生命周期事件`
- `## Q3: Draft/Save 状态统一 — 方案已确定，待细化 / ### 问题`
- `## Q3: Draft/Save 状态统一 — 方案已确定，待细化 / ### 当前设计的三个问题`
- `## Q3: Draft/Save 状态统一 — 方案已确定，待细化 / ### 方案 1：统一为 EditBuffer`
- `## Q3: Draft/Save 状态统一 — 方案已确定，待细化 / ### 对 S2 原文的修正`
- `## Q3: Draft/Save 状态统一 — 方案已确定，待细化 / ### Undo（Ctrl+Z）兼容性`
- `## Q4: Coordinator 残留职责（D3） — 部分由 Q3 细化3 覆盖 / ### Q3 细化3 已裁决的部分（直接沿用）`
- `## Q4: Coordinator 残留职责（D3） — 部分由 Q3 细化3 覆盖 / ### 增量裁决点`
- `## Q5: 文件位置 — RESOLVED / ### 裁决`
- `## Q5: 文件位置 — RESOLVED / ### 分析`
- `## Q5: 文件位置 — RESOLVED / ### 文件结构`

### Refinement anchors

- `## Q3 / ### 细化分析 / #### 细化 1：EditBuffer 生命周期 — RESOLVED`
- `## Q3 / ### 细化分析 / #### 细化 2：edit() 与 save() 完整时序 — RESOLVED`
- `## Q3 / ### 细化分析 / #### 细化 3：与 Coordinator 的交互边界 — RESOLVED`
- `## Q3 / ### 细化分析 / #### 细化 4：多 Pane 并发编辑同一 Buffer — 边界确认，详见 DI-4`
- `## Q4 / ### 增量裁决点 / #### 细化 1：Tab 标题机制 — RESOLVED`
- `## Q4 / ### 增量裁决点 / #### 细化 2：Coordinator 提取后的结构定义 — RESOLVED`
- `## Q4 / ### 增量裁决点 / #### 细化 3：WorkspaceTreeManager 独立提取 — RESOLVED`

### Handoff anchors

- `## 整体架构图（方案）`
- `## 实施关联 [PR-RB-06 新增]`

## Notes

- The previous survey was under-specified: it incorrectly treated `Q3` and `Q4` as single anchors even though the source already provides stable `细化 *` headings.
- `Q3 细化 4` is only a boundary confirmation and explicitly hands off to `DI-4`; later extraction should keep that handoff distinct from the locally resolved `细化 1-3`.
- `Q4 细化 3` is not just a local implementation note; it is an upstream anchor for the later workspace-service line.
