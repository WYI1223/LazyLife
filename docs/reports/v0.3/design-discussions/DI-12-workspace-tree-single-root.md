# DI-12: Workspace Tree 单根化与系统语义锚点

| 项目 | 值 |
|------|-----|
| **状态** | **OPEN** |
| **关联裁决** | S1 R5/R6, S3, S4 |
| **影响范围** | Core Tree/Creation Service、FFI 创建/树接口、Flutter Explorer/Tasks/Calendar |
| **前置输入** | DI-11（Atom-first 入口方向）、08b（指定默认路径语义） |
| **目标版本** | v0.4 规划（不回改 v0.3 已收口范围） |

---

## 背景

当前 workspace tree 已完成 `note_ref -> atom_ref` 升级，但仍存在以下结构性张力：

1. 组织树是通用节点模型（folder/atom_ref），但 Tasks/Calendar 的系统语义锚点未作为一等结构约束落地。
2. `designated folder` 语义部分依赖上层约定，导致删除保护、pending 数据口径、创建路由的认知不稳定。
3. 根级别（`parent_uuid = NULL`）与“未分类/系统入口”混用，容易造成产品心智和实现口径分叉。

本议题用于单独讨论“是否将树收敛为单根整树 + 固化系统语义节点”，并形成可执行方案。

---

## 讨论边界

### In Scope

1. Workspace tree 结构模型（单根 vs 现有 root-level null 模型）。
2. Tasks/Calendar 系统文件夹的存在性、生命周期和保护规则。
3. 创建路径路由与 pending 池数据源的结构化定义。
4. 迁移策略（DB + 服务层 + API 兼容）。
5. 验收和回归标准。

### Out of Scope

1. `AtomType -> ViewHint` 命名收敛（已在 DI-11 处理）。
2. Canvas / Conversation 内容模型（S1 R12+）。
3. 视图组件视觉细节（仅讨论语义和契约）。

---

## 待裁决问题（Q1-Q12）

### Q1. 树模型是否改为单根整树？

- A. 维持 `parent_uuid = NULL` 作为根级
- B. 引入隐藏系统根节点 `ROOT`，所有节点必须有父（除 `ROOT`）

### Q2. 根级“未分类”如何表达？

- A. 保留 synthetic uncategorized 展示层
- B. 使用真实结构节点（例如 `Inbox/Unclassified`）承接
- C. 两者并存（过渡期）

### Q3. Tasks/Calendar 系统文件夹是否必须存在？

- A. 可为空（未配置合法）
- B. 必须存在（缺失自动修复/创建）

### Q4. 系统文件夹可执行哪些操作？

- A. 可重命名、可移动、不可删除
- B. 可移动、不可重命名、不可删除
- C. 全部不可变（仅系统维护）

### Q5. 是否保留“重新指定映射”能力？

- A. 保留 `view -> folder` 可重指定映射
- B. 取消映射重指定，改为“移动同一系统文件夹节点”

### Q6. 创建路由如何定义为结构事实？

- A. 由运行时配置映射决定
- B. 由固定系统节点决定（task/calendar 创建直接落系统节点）

### Q7. Calendar Pending 数据源口径？

- A. Calendar 系统文件夹子树内，`start_at/end_at` 均为空
- B. 全局无时间字段集合 + 额外过滤

### Q8. Tasks Pending/Inbox 数据源口径？

- A. Tasks 系统文件夹子树内 + task 条件
- B. 全局 task 条件，不绑定结构子树

### Q9. “active”判定是否纳入 pending/scope 查询？

- A. 仅判 atom `is_deleted=0`
- B. atom + atom_ref + ancestor chain 全部 active

### Q10. API 兼容策略（FFI）？

- A. 保持 `parent_node_id: Option<String>`，`None` 在 service 层映射到系统根/默认入口
- B. 改为显式 `target_scope` 枚举（breaking）

### Q11. 数据迁移策略？

- A. 一次性迁移（新增系统节点 + 回填 parent）
- B. 双轨过渡（兼容旧结构一段时间）

### Q12. 删除策略与安全网？

- A. 继续支持 `dissolve/delete_all`，但对系统节点加硬保护
- B. 收敛为单一删除语义，减少分支

---

## 方案输出要求（本 DI 最终产物）

1. **语义裁决**：Q1-Q12 每项给出唯一结论（可含阶段性结论）。
2. **结构契约**：`workspace_nodes` 约束与系统节点定义。
3. **服务契约**：Creation/Tree Service 路由与保护规则。
4. **FFI 契约**：入参/出参兼容策略与弃用计划。
5. **迁移方案**：SQL 迁移步骤、失败回滚、幂等保障。
6. **验收基线**：最小测试矩阵（Core/FFI/Flutter）。

---

## 讨论顺序建议

1. 先定 Q1-Q5（结构与生命周期）。
2. 再定 Q6-Q9（路由与查询语义）。
3. 最后定 Q10-Q12（迁移与发布策略）。

---

## 备注

本文件是讨论模板，不预设结论。每次讨论只关闭少量问题，避免一次性跨层拍板造成语义漂移。

