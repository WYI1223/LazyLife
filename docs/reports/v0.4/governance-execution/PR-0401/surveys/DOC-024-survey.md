# DOC-024 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md`
- Title: `DI-16: Rust Service 层与 FFI 契约`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- The file header is `IN PROGRESS`, but the body already contains many explicit `RESOLVED` clause anchors; survey must preserve that split.
- There are four distinct anchor surfaces in this source:
  - contract framing (`背景`, `输入约束`, `讨论边界`)
  - prerequisite architecture directions (`A1-A12`)
  - top-level contract decisions (`Q1-Q6`)
  - lower contract clauses (`Q1.1`, `Q3.1`, `Q4.1`, `Q5.1`, `Q6.0` and so on)
- `Q1` contains a second layer of stable `#####` subanchors that carry the actual query-pipeline contract (`双投影模型`, `输出契约表`, `CTE 管线`, `Filter SQL 真值规则表`, `Service 层映射测试矩阵`, `索引配套`, `Global 分层归属`).
- `Q2` uses numbered list items rather than markdown subheadings, but those numbered items are still stable candidate anchors because each one defines a separate tree-navigation method contract.
- Extraction should preserve the parent-child chain for `Q1/Q2/Q3/Q4/Q5/Q6`; the parent question anchor still carries problem framing and contract scope even when lower anchors are more detailed.

## Candidate DN Anchors

### Framing anchors

- `## 背景 / ### 输入约束`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`

### Architecture prerequisite anchors

- `## 已确认的架构方向 / ### A1. 数据结构：多根森林 + 共享 atom pool`
- `## 已确认的架构方向 / ### A2. 文件夹语义归属`
- `## 已确认的架构方向 / ### A3. 智能视图 = designated folder 子树查询`
- `## 已确认的架构方向 / ### A4. 两种消费模式`
- `## 已确认的架构方向 / ### A5. view_hint 保持 S1 R3 定义`
- `## 已确认的架构方向 / ### A6. 文件夹结构平等`
- `## 已确认的架构方向 / ### A7. 指定文件夹 = DB 层映射（designated_folders 表）`
- `## 已确认的架构方向 / ### A8. 子树查询策略：CTE + 索引 — RESOLVED`
- `## 已确认的架构方向 / ### A9. 多视图与共享扩展性`
- `## 已确认的架构方向 / ### A10. DI-15 回溯审视 — DONE`
- `## 已确认的架构方向 / ### A11. 统一查询方向`
- `## 已确认的架构方向 / ### A12. 统一创建方向`

### Top-level contract anchors

- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q2. 树导航专用方法 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q3. 统一创建入口 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q4. TreeService 演进 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q5. AccessGuard 接口设计 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED`

### Clause-level contract anchors

- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.1 结构体字段 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED / ##### 双投影模型`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED / ##### 输出契约表`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED / ##### CTE 管线（3-4 段）`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED / ##### Filter SQL 真值规则表`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED / ##### Service 层映射测试矩阵`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED / ##### 索引配套（A8 已定义 + 补充）`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.2 SQL 组合策略 — RESOLVED / ##### Global 分层归属`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.3 repo 层归属 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.3 repo 层归属 — RESOLVED / ##### 重构后 repo 层边界`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.3 repo 层归属 — RESOLVED / ##### 变更说明`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.3 repo 层归属 — RESOLVED / ##### 依赖关系`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.4 service 层影响 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.4 service 层影响 — RESOLVED / ##### 重构后 service 层`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.4 service 层影响 — RESOLVED / ##### 业务域 Service 的三段职责`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.4 service 层影响 — RESOLVED / ##### Today overdue 补偿`
- `## 裁决记录（Q1-Q6） / ### Q1. 统一查询层 ScopedAtomQuery — RESOLVED / #### Q1.4 service 层影响 — RESOLVED / ##### 设计要点`
- `## 裁决记录（Q1-Q6） / ### Q2. 树导航专用方法 — RESOLVED / 1. list_subtree_atom_refs（Explorer / Tag 过滤用）`
- `## 裁决记录（Q1-Q6） / ### Q2. 树导航专用方法 — RESOLVED / 2. get_ancestor_path(node_uuid: WorkspaceNodeId)（Editor 面包屑用）`
- `## 裁决记录（Q1-Q6） / ### Q2. 树导航专用方法 — RESOLVED / 3. list_atom_refs_for_atom — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q2. 树导航专用方法 — RESOLVED / 4. trait 组织 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q3. 统一创建入口 — RESOLVED / #### Q3.1 CreateAtomRequest 结构体 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q3. 统一创建入口 — RESOLVED / #### Q3.2 路由实现 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q3. 统一创建入口 — RESOLVED / #### Q3.3 现有方法迁移 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q4. TreeService 演进 — RESOLVED / #### Q4.1 workspace root 和 designated folder 保护 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q4. TreeService 演进 — RESOLVED / #### Q4.2 designated folder 解析归属 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q4. TreeService 演进 — RESOLVED / #### Q4.3 泛型约束 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q4. TreeService 演进 — RESOLVED / #### Q4.4 ancestor_path 签名修正 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q5. AccessGuard 接口设计 — RESOLVED / #### Q5.1 CallerContext 类型 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q5. AccessGuard 接口设计 — RESOLVED / #### Q5.2 Guard 位置 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q5. AccessGuard 接口设计 — RESOLVED / #### Q5.3 当前实现 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q5. AccessGuard 接口设计 — RESOLVED / #### Q5.4 origin_workspace_id 读路径 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.0 万能接口约束 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.1 统一查询 FFI 入口 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.2 统一创建 FFI 入口 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.3 新增 FFI 完整清单 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.4 响应类型 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.5 Error code 扩展 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.6 兼容策略 — RESOLVED`
- `## 裁决记录（Q1-Q6） / ### Q6. FFI API 变更 — RESOLVED / #### Q6.7 PR-RB-10 迁移桥接 — RESOLVED`

## Notes

- The previous survey was missing the `Q1.2/Q1.3/Q1.4` stable `#####` subanchors and the numbered `Q2` method anchors, which made the file look flatter than it is.
- Later extraction should distinguish between:
  - prerequisite architecture lines (`A*`)
  - primary contract decisions (`Q1-Q6`)
  - implementation/detail clauses (`Q1.1`, `Q6.3`, etc.)
  - stable mid-layer contract anchors inside `Q1` and `Q2`
- `DOC-024` remains a special case in status handling: inventory-level state is still in-progress, but many clause-level decisions are already closed and surveyable.
