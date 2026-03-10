# DOC-002 Survey

- Source: `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md`
- Title: `08b - 语义裁决记录`
- Doc Class: Semantic decision log
- Corpus Role: Decision source

## Structure Snapshot

- This source is sectioned by `S1-S8`, but only `S1` was previously split correctly.
- `S2-S8` also contain explicit `####` ruling anchors under `### 裁决`; those are the real minimum survey units and must not be collapsed back to section-level `### 裁决`.
- Survey stage should preserve each explicit ruling clause, including scope/boundary clauses such as `v0.2.5 范围`, because they are part of the original decision surface.

## Candidate DN Anchors

### S1 anchors

- `## S1 / ### 裁决 / #### R1. Atom 是容器，不是类型`
- `## S1 / ### 裁决 / #### R2. 新增 content_type 字段`
- `## S1 / ### 裁决 / #### R3. type 重命名为 view_hint，改为自动推导`
- `## S1 / ### 裁决 / #### R4. 渲染行为矩阵由 time fields + task_status 驱动`
- `## S1 / ### 裁决 / #### R5. note_ref 扩展为 atom_ref，强制伴随 Atom 创建`
- `## S1 / ### 裁决 / #### R6. Workspace Explorer 采用指定默认路径模型`
- `## S1 / ### 裁决 / #### R7. 多引用创建交互`
- `## S1 / ### 裁决 / #### R8. title 作为 Atom 一等公民字段，统一所有视图的名称显示`
- `## S1 / ### 裁决 / #### R9. 新增 icon 字段`
- `## S1 / ### 裁决 / #### R10. 新增 cover_image 字段，与 preview_image 分离`
- `## S1 / ### 裁决 / #### R11. Comment 语义冻结，实现推迟`
- `## S1 / ### 裁决 / #### R12. Spatial Canvas 预留框架`
- `## S1 / ### 裁决 / #### R13. Conversation 内容类型预留`

### S2 anchors

- `## S2 / ### 裁决 / #### 目标架构（v0.3 完成）`
- `## S2 / ### 裁决 / #### 分阶段实施`

### S3 anchors

- `## S3 / ### 裁决 / #### 核心语义：两个正交维度`
- `## S3 / ### 裁决 / #### 指定默认文件夹与 Explorer 的关系`
- `## S3 / ### 裁决 / #### Tag 查询结果展示`
- `## S3 / ### 裁决 / #### 渐进实施方案：Phase A -> Phase B`
- `## S3 / ### 裁决 / #### 未来：三种 Explorer 视图模式`
- `## S3 / ### 裁决 / #### v0.2.5 范围`

### S4 anchors

- `## S4 / ### 裁决 / #### atom_ref 强制伴随`
- `## S4 / ### 裁决 / #### 创建路径路由、指定文件夹模型`
- `## S4 / ### 裁决 / #### v0.2.5 范围`

### S5 anchors

- `## S5 / ### 裁决 / #### 核心立场：两套系统服务不同对象`
- `## S5 / ### 裁决 / #### Flutter 命令系统 = first-party 运行时`
- `## S5 / ### 裁决 / #### Extension Kernel = third-party 安全合约`
- `## S5 / ### 裁决 / #### S1-S4 裁决的影响作用在命令执行层`
- `## S5 / ### 裁决 / #### 桥接的构建时机`
- `## S5 / ### 裁决 / #### v0.2.5 范围`

### S6 anchors

- `## S6 / ### 裁决 / #### 三层职责分离`
- `## S6 / ### 裁决 / #### Provider = 翻译官，Orchestrator = 调度员`
- `## S6 / ### 裁决 / #### S1-S4 裁决对同步流程的影响`
- `## S6 / ### 裁决 / #### external_mappings 表的约束验证`
- `## S6 / ### 裁决 / #### v0.2.5 范围`

### S7 anchors

- `## S7 / ### 裁决 / #### 模块归属：features/ -> lib/core/`
- `## S7 / ### 裁决 / #### 触发语义：绑定 Atom 生命周期，而非视图加载`
- `## S7 / ### 裁决 / #### App 启动恢复`
- `## S7 / ### 裁决 / #### S1 裁决验证`
- `## S7 / ### 裁决 / #### 不选 B / C 的理由`
- `## S7 / ### 裁决 / #### v0.2.5 范围`

### S8 anchors

- `## S8 / ### 裁决 / #### 核心问题：NoteItem 在 FFI 边界主动丢弃信息`
- `## S8 / ### 裁决 / #### S1 统一容器要求 DTO 携带完整状态`
- `## S8 / ### 裁决 / #### 迁移路径`
- `## S8 / ### 裁决 / #### S1 后续字段的收益`
- `## S8 / ### 裁决 / #### v0.2.5 范围`

## Notes

- The previous survey was still incomplete: it fixed `S1`, but it left `S2-S8` at coarse `### 裁决` level even though the source already provides finer `####` anchors.
- Later extraction should keep section scope/boundary clauses such as `v0.2.5 范围` distinct from core semantic clauses.
