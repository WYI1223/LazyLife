# DI-15: Rust Core 数据模型 — 工作区树架构

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** |
| **关联决策点** | DI-12（概念母题）、DI-14 Q2（接口需求）、DI-16（讨论中发现的架构演进） |
| **影响范围** | `lazynote_core` schema、migration、`tree_repo`、数据不变量 |
| **前置依赖** | DI-12 Q1-Q12 裁决（概念架构） |
| **目标版本** | v0.4 |
| **输出物** | 数据契约 + migration 策略 |

---

## 背景

DI-12 在概念层裁决了单根树 + 系统节点架构（Q1-Q12）。本 DI 最初将这些概念裁决落地为 Rust Core 的具体数据模型设计（Q1-Q6，单根方案）。

在 DI-16 讨论过程中，通过对 DAG 拓扑、跨工作区共享、多用户扩展性、以及 Local-first 安全模型的深入分析，确认**多根森林（Multi-Root Forest）**方案在几乎所有维度上优于单根方案。原 Q1-Q6 裁决已标记为 SUPERSEDED，新的 Q7-Q12 承载多根森林裁决。

**边界原则**：本 DI 只讨论数据结构真相（"数据长什么样"），不讨论服务层 API（DI-16）或 Flutter 消费（DI-17）。本 DI 不产出任何 service/FFI 方法签名。

### 架构方向变更说明

**从单根到多根的核心洞察**：atoms 表（扁平数据池）与 workspace_nodes（拓扑结构）是解耦的两层。atom_ref 指向 atoms 表中的行，而非其他树节点。因此多根森林不会破坏跨工作区共享。

多根森林的优势：

| 维度 | 单根树 | 多根森林 |
|------|--------|----------|
| CTE 隔离性 | 需要额外过滤排除其他子树 | CTE 从 workspace root 出发，天然隔离 |
| ROOT 节点 | 需要隐藏系统根 + 触发器保护 | 不需要 ROOT，workspace 自身即 root |
| 多用户/多视图 | ROOT 下挂多个 workspace 子树 | 每个 workspace 独立 root，天然支持 |
| 未来拆库 | 需要从单棵树中剥离子树 | workspace 天然独立，可直接拆为独立 DB |
| 权限边界 | 需额外逻辑在单树中划定边界 | workspace = 权限边界，结构天然对齐 |
| 概念复杂度 | ROOT + system_role + 3 触发器 + 4 well-known UUID | 仅 workspace root，无额外概念 |

### 输入约束（从 DI-12 继承，部分被多根方案覆盖）

| DI-12 裁决 | 约束 | 多根方案影响 |
|-----------|------|-------------|
| Q1 | 单根整树，ROOT 为隐藏系统根 | **覆盖**：改为多根森林 |
| Q2 | Inbox 为真实系统节点 | **覆盖**：Inbox 为普通文件夹，config 指定 |
| Q3 | Tasks/Calendar 系统文件夹必须存在 | **覆盖**：普通文件夹，app bootstrap 创建 |
| Q4 | Profile Soft：可重命名、可移动、不可删除 | **调整**：仅 workspace root 不可删除 |
| Q5 | role+uuid 绑定，不允许映射重指定 | **覆盖**：无固定 role 绑定 |
| Q9 | ancestor chain active 全局可见性约束 | **保留**：范围缩小为 per-workspace |
| Q11 | 一次性迁移（A+ 策略） | **保留** |
| Q12 | 双模式删除保留，系统节点禁删 | **调整**：双模式保留，workspace root 禁删 |

---

## 讨论边界

### In Scope

1. `workspace_nodes` schema 演进（新列 / 新表）。
2. 系统节点 role 存储机制。
3. Migration SQL 设计与回填策略。
4. Active 可见性不变量的数据层表达。
5. 系统节点保护约束的数据层实现。
6. 迁移事务化与回滚策略。

### Out of Scope

1. Service/Repository Rust API 设计 → DI-16。
2. FFI 函数签名与兼容策略 → DI-16。
3. Flutter 消费层设计 → DI-17。
4. PR 拆分与执行顺序 → DI-18。

---

## 已替代的裁决（Q1-Q6，原单根方案）

> **SUPERSEDED** — 以下裁决在原单根树架构下成立，现已被多根森林方案（Q7-Q12）替代。保留作为决策历史记录和对比参考。

### Q1. 系统节点 role 存储机制？（~~RESOLVED~~ → SUPERSEDED）

系统节点（ROOT/Inbox/Tasks/Calendar）的角色标识如何在数据库中表达？

- A. **独立绑定表 `workspace_system_roles(role TEXT, node_uuid TEXT)`**
  - 优点：职责分离，系统角色与节点表解耦；DI-12 Q11 建议此方案
  - 缺点：多一张表，查询需 JOIN

- B. **在 `workspace_nodes` 增加 `system_role` 列（nullable TEXT）**
  - 优点：单表查询，无 JOIN；schema 简单
  - 缺点：大量节点该列为 NULL；角色与节点强耦合

- C. **`workspace_nodes` 增加 `is_system BOOLEAN` + 独立绑定表**
  - 优点：快速判断是否系统节点（不需 JOIN），角色细节查绑定表
  - 缺点：两处存储需保持一致

**裁决**：选择 **B（`workspace_nodes` 增加 `system_role` 列）**。

```sql
ALTER TABLE workspace_nodes ADD COLUMN system_role TEXT;
-- UNIQUE 约束：SQLite 允许多个 NULL，非 NULL 值全局唯一
```

**裁决理由**：

1. **单表闭环（操作唯一性）**：所有节点操作、保护检查、角色查询在同一张表内完成，无跨表一致性负担。
2. **保护逻辑自然内聚**：delete 操作加 `AND system_role IS NULL` 即可，不需 JOIN。最频繁的保护检查（按 UUID 查节点时读 `system_role` 列）零额外开销。
3. **一列两用**：`system_role IS NOT NULL` 回答"是否系统节点"，`system_role = 'tasks'` 回答"扮演什么角色"。无需额外 `is_system` 标志。
4. **SQLite UNIQUE 语义适配**：多行 NULL 合法，非 NULL 值全局唯一，正好表达"每个 role 最多绑定一个节点"。
5. **可扩展性保留**：新增系统角色只需 INSERT 带 `system_role` 值的节点，无需 schema 变更。未来若需多 role 绑定（极不可能），可迁移到独立表。

**Trade-off 记录**：舍弃概念上的职责分离（角色语义与节点数据同表），换取操作的单一归属（single source of truth）。启动时 role 解析需扫描 `workspace_nodes` 而非专用小表，但仅发生一次，代价可忽略。

**覆盖 DI-12 Q11 建议**：DI-12 Q11 A+ 步骤 3 建议独立绑定表。该建议的动机是"避免按名称识别角色"，但 A 和 B 方案均使用字符串 role 标识，绑定表不额外解决此问题。B 方案更简洁且满足相同需求，故覆盖原建议。

---

### Q2. ROOT 节点的表达方式？（~~RESOLVED~~ → SUPERSEDED）

ROOT 是隐藏系统根，所有节点的最终祖先。它在 schema 中如何存在？

**裁决**：**真实记录** — ROOT 是 `workspace_nodes` 中的一行，`parent_uuid = NULL`，`system_role = 'root'`。

```sql
-- ROOT 是唯一允许 parent_uuid IS NULL 的节点
-- 迁移后数据不变量：
--   SELECT COUNT(*) FROM workspace_nodes
--   WHERE parent_uuid IS NULL AND is_deleted = 0
--   → 恰好 1（即 ROOT）
```

**裁决理由**：

1. **零特殊路径**：所有树操作（list_children、move_node、get_ancestor_path、递归 CTE）对 ROOT 和普通 folder 走完全相同的代码路径，无需 `if root then ...` 分支。
2. **数据完整性**：所有 `parent_uuid` 值指向表中真实存在的行（ROOT 自身为 NULL 是唯一例外），外键语义完整。
3. **与 Q1 自然衔接**：ROOT 即 `system_role = 'root'` 的行，Q1 的列直接覆盖，无需额外标识机制。
4. **不变量可审计**：`parent_uuid IS NULL` 恰好 1 行，启动巡检可验证。

**派生约束**：

- 迁移后禁止任何操作产生新的 `parent_uuid IS NULL` 节点。
- ROOT 不对用户可见（UI 层过滤），但数据层始终存在。

---

### Q3. Migration SQL 设计？（~~RESOLVED~~ → SUPERSEDED）

新 migration（`0012_workspace_single_root.sql`）的具体内容。分为三个子项。

#### Q3.1 系统节点 UUID 生成策略（RESOLVED）

- A. 迁移时随机生成（每个 DB 实例不同）
- B. 预定义 well-known UUID（所有实例相同）

**裁决**：选择 **B（well-known UUID）**。

| 系统节点 | UUID |
|---------|------|
| ROOT | `00000000-0000-0000-0000-000000000001` |
| Inbox | `00000000-0000-0000-0000-000000000002` |
| Tasks | `00000000-0000-0000-0000-000000000003` |
| Calendar | `00000000-0000-0000-0000-000000000004` |
| 预留区间 | `...0005` ~ `...00FF`（255 槽位，供未来系统节点使用） |

**裁决理由**：

1. **系统节点是结构常量，不是用户内容**——可预测性是优势，不是缺陷。
2. **Migration SQL 确定性**——不依赖运行时随机数，迁移结果可精确验证。
3. **测试直接引用**——测试代码用常量 UUID，无需先查 `WHERE system_role = ?`。
4. **调试可识别**——日志中一眼认出全零前缀 UUID 为系统节点。
5. **碰撞风险为零**——UUIDv4 第 13 位 hex 固定为 `4`（如 `xxxxxxxx-xxxx-4xxx-...`），与全零前缀在格式上不可能重叠。

**预留区间约束**：`00000000-0000-0000-0000-000000000001` ~ `...0000000000FF` 为系统节点保留区间，用户节点（`Uuid::new_v4()`）永远不会落在此区间。预留区间是文档化硬规则，不仅依赖概率。

#### Q3.2 回填规则（RESOLVED）

**裁决**：按 kind 分流回填，同时覆盖 active 和 soft-deleted 节点。

**Re-parent 规则**：

| 迁移前状态 | 迁移后 parent_uuid |
|-----------|-------------------|
| `folder` + `parent_uuid IS NULL` | ROOT |
| `atom_ref` + `parent_uuid IS NULL` | Inbox |
| 上述两条同时覆盖 `is_deleted = 0` 和 `is_deleted = 1` | — |

**sort_order 处理**：

- ROOT 直接子节点顺序：系统节点在前（Inbox=0, Tasks=1, Calendar=2），用户文件夹保持相对顺序、整体 offset +3。
- 回填到 Inbox 的 atom_ref：保持原有 sort_order 不变。

**兜底约束**：迁移完成后，`parent_uuid IS NULL` 仅 ROOT 一行。WHERE 条件用 `parent_uuid IS NULL AND system_role IS NULL` 确保不遗漏任何非系统节点。

**风险缓解**：

| 风险 | 措施 |
|------|------|
| 绕过 Service 层验证 | Migration 是 schema 级操作，在 service 层初始化之前运行，SQL-only 是框架约束 |
| 触发器副作用 | 迁移前检查 `workspace_nodes` 上是否有触发器，必要时临时禁用 |
| `updated_at` 遗漏 | UPDATE 语句显式 `SET updated_at = (strftime('%s','now') * 1000)` |
| 数据依赖性（sort_order 间隙等） | Migration test 覆盖多种边界场景（空库、连续 sort_order、间隙 sort_order、大量 root-level 节点） |
| 中间状态 | 整个迁移在单事务内完成，外部不可见中间状态 |

#### Q3.3 UNIQUE 约束（RESOLVED）

**裁决**：Partial unique index 保障系统角色唯一性。

```sql
CREATE UNIQUE INDEX idx_workspace_system_role
ON workspace_nodes(system_role) WHERE system_role IS NOT NULL;
```

- **约束范围**：INSERT 和 UPDATE——禁止两行拥有相同的非 NULL `system_role` 值。
- **不约束 DELETE**——删除保护由 DI-15 Q5（service 层 / 触发器）另行处理。
- **NULL 行为**：多行 `system_role = NULL` 合法（普通节点）。

#### Q3 综合：Migration SQL 草案

```sql
-- Step 1: 新增 system_role 列
ALTER TABLE workspace_nodes ADD COLUMN system_role TEXT;

-- Step 2: Partial unique index（防 role 碰撞）
CREATE UNIQUE INDEX idx_workspace_system_role
ON workspace_nodes(system_role) WHERE system_role IS NOT NULL;

-- Step 3: 创建 ROOT
INSERT INTO workspace_nodes
  (node_uuid, kind, parent_uuid, system_role, display_name, sort_order, is_deleted)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'folder', NULL, 'root', 'ROOT', 0, 0);

-- Step 4: 创建 Inbox / Tasks / Calendar（挂在 ROOT 下）
INSERT INTO workspace_nodes
  (node_uuid, kind, parent_uuid, system_role, display_name, sort_order, is_deleted)
VALUES
  ('00000000-0000-0000-0000-000000000002', 'folder',
   '00000000-0000-0000-0000-000000000001', 'inbox', 'Inbox', 0, 0),
  ('00000000-0000-0000-0000-000000000003', 'folder',
   '00000000-0000-0000-0000-000000000001', 'tasks', 'Tasks', 1, 0),
  ('00000000-0000-0000-0000-000000000004', 'folder',
   '00000000-0000-0000-0000-000000000001', 'calendar', 'Calendar', 2, 0);

-- Step 5: 回填 — root-level folder → ROOT（offset sort_order +3）
UPDATE workspace_nodes
SET parent_uuid = '00000000-0000-0000-0000-000000000001',
    sort_order = sort_order + 3,
    updated_at = (strftime('%s', 'now') * 1000)
WHERE parent_uuid IS NULL
  AND system_role IS NULL
  AND kind = 'folder';

-- Step 6: 回填 — root-level atom_ref → Inbox
UPDATE workspace_nodes
SET parent_uuid = '00000000-0000-0000-0000-000000000002',
    updated_at = (strftime('%s', 'now') * 1000)
WHERE parent_uuid IS NULL
  AND system_role IS NULL
  AND kind = 'atom_ref';
```

---

### Q4. Active 可见性不变量与数据层保证？（RESOLVED — 微调后保留，见 Q7 附注）

DI-12 Q9 裁决 ancestor chain active 作为全局可见性约束。本 Q 只定义不变量的精确语义及数据层如何保证其成立。读路径策略（轻查询 vs 递归校验、各 API 的过滤口径、错误码）归入 DI-16。

#### 不变量定义

> 若 `atom_ref.is_deleted = 0`，则从该 `atom_ref` 到 ROOT 的全部祖先节点必须满足 `is_deleted = 0`。
>
> 等价表述：不存在"active 子节点挂在 deleted 父节点下"的悬挂链。

#### 写路径保证机制

| 写操作 | 保证方式 |
|--------|---------|
| `delete_folder(delete_all)` | `soft_delete_workspace_subtree` 递归 CTE：事务内整棵子树全部 soft-delete，不产生悬挂链 |
| `delete_folder(dissolve)` | 先将子节点 re-parent 到上级（active 父），再 soft-delete 文件夹自身 |
| `move_node` | `ensure_parent_is_folder` 验证目标父节点 `is_deleted = 0`，不可能移到已删除父下 |
| soft-delete atom | atom 层面操作，不影响 workspace_nodes 结构；`list_children` 已过滤 `a.is_deleted = 0` |

以上写路径在单根树 + 系统节点（不可删除）下进一步增强：从任意节点到 ROOT 的祖先链上，系统节点段永远 active。

#### 巡检修复前提

后台一致性巡检作为第三层保障，捕获绕过 service 层的异常数据：

- **检测条件**：扫描 `is_deleted = 0` 的节点，验证其 `parent_uuid` 指向的节点也满足 `is_deleted = 0`。
- **修复策略**：发现悬挂链时，将孤立 active 节点移至 Inbox（保数据不丢），写诊断日志。
- **幂等性**：巡检可重复执行，不改变已一致的数据。

#### 级联 soft-delete 触发器（RESOLVED — 不加）

当前级联 soft-delete 仅在 repo 代码（`soft_delete_workspace_subtree`）中实现。直接执行 `UPDATE workspace_nodes SET is_deleted = 1 WHERE node_uuid = ?` 可以绕过级联，产生悬挂链。

**裁决**：**不加触发器**。级联 soft-delete 是递归业务逻辑，继续由 Service/Repo 层的递归 CTE 保证。巡检修复作为兜底。理由：触发器内递归逻辑不透明、调试困难，且与 repo 层递归 CTE 重复。

---

### Q5. 系统节点保护约束的实现层级？（~~RESOLVED~~ → SUPERSEDED）

系统节点不可删除、不可去系统化（DI-12 Q4/Q12）。保护在哪层实现？

**裁决**：**Service 层 + DB 触发器双重保护**。区分"递归业务逻辑"和"结构守卫"：

- **级联 soft-delete**（递归业务逻辑）→ Service/Repo 层（Q4 已裁决）
- **系统节点禁删 + 禁去系统化**（结构守卫）→ DB 触发器最后防线 + Service 层友好错误

**裁决理由**：

1. Service 层保护覆盖正常业务路径（Rule B 保证），提供友好错误信息。
2. DB 触发器保护所有路径，包括维护工具 purge SQL、手动 DB 操作等 service 层不可达的旁路。
3. 系统节点触发器是简单守卫（条件判断 + RAISE），不含业务逻辑，与"不在触发器里写业务逻辑"原则不矛盾。性质类似 UNIQUE 约束。

**DB 触发器（3 个结构守卫）**：

```sql
-- 1. 禁止 soft-delete 系统节点
CREATE TRIGGER protect_system_node_soft_delete
BEFORE UPDATE OF is_deleted ON workspace_nodes
WHEN NEW.is_deleted = 1 AND OLD.system_role IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'cannot soft-delete system node');
END;

-- 2. 禁止 hard-delete 系统节点
CREATE TRIGGER protect_system_node_hard_delete
BEFORE DELETE ON workspace_nodes
WHEN OLD.system_role IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'cannot hard-delete system node');
END;

-- 3. 禁止修改/清除 system_role（防去系统化）
CREATE TRIGGER protect_system_node_role_immutable
BEFORE UPDATE OF system_role ON workspace_nodes
WHEN OLD.system_role IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'cannot modify system_role of system node');
END;
```

**三个触发器覆盖的攻击面**：

| 场景 | 触发器 |
|------|--------|
| 业务 bug 意外 soft-delete 系统节点 | `protect_system_node_soft_delete` |
| 维护 purge SQL hard-delete 系统节点 | `protect_system_node_hard_delete` |
| 将系统节点的 `system_role` 改为 NULL 或其他值 | `protect_system_node_role_immutable` |

---

### Q6. 迁移回滚与版本门禁？（RESOLVED — 不变，保留）

**裁决**：选择 **A（PRAGMA user_version 门禁 + 事务回滚，不提供降级迁移）**。

**裁决理由**：

1. **现有 migration executor 已保证事务性**：`apply_migrations()`（`src/db/migrations/mod.rs:92`）在单个 `conn.transaction()` 内执行所有待应用的 migration，任何一步失败整体回滚，DB 保持原版本。0012 无需额外工作。
2. **11 个 migration 全部单向**：项目无降级先例，引入降级 migration 是新模式。
3. **降级不可行**：从单根树退回 forest 需要 re-parent 系统节点子节点回 NULL，且 Inbox 中用户新创建的内容无法安全归还原位。数据丢失风险高。
4. **DI-12 Q11 的"回滚"是事务级的**：指 migration 执行失败时自动回滚，不是版本降级。

**已有保障**（无需新增）：

```
apply_migrations()
  → conn.transaction()          // 单事务
    → execute_batch(sql)        // 执行 migration SQL
    → PRAGMA user_version = N   // 成功后更新版本
  → tx.commit()                 // 全部成功才提交
  // 任何一步失败 → 自动 rollback → DB 保持 v11
```

---

## 多根森林裁决（Q7-Q12）

> 以下裁决基于多根森林架构方向。讨论中逐条裁决。

### Q7. Workspace Root 表达与拓扑规则？（RESOLVED）

多根森林中，每个 workspace 的顶级节点如何在 `workspace_nodes` 中表达？

```
workspace_nodes 表：
  root_a  (kind = 'workspace', parent_uuid = NULL)  ← workspace A root
  root_b  (kind = 'workspace', parent_uuid = NULL)  ← workspace B root
  folder_1 (kind = 'folder', parent_uuid = root_a)
  ...
```

#### Q7.1 workspace root 如何识别？（RESOLVED）

**裁决**：选择 **B（`kind = 'workspace'`）** — 扩展现有 kind 枚举为 `folder | atom_ref | workspace`。

**裁决理由**：

1. **身份不随位置丢失**：若 bug 或维护 SQL 意外修改 `parent_uuid`，节点仍保留 `kind = 'workspace'` 身份，系统仍可定位。方案 A（`parent_uuid IS NULL` 即 root）在此场景下会静默丧失 workspace root 身份——灾难性静默失败。
2. **逻辑等效 CHECK 约束**：`kind != 'workspace' OR parent_uuid IS NULL` 作为不变量，DB 层面阻止 workspace root 被 re-parent。因 SQLite 不支持 `ALTER TABLE ADD CHECK`（`workspace_nodes` 已存在），实际由触发器落地（见 Q12）。
3. **查询语义明确**：`WHERE kind = 'workspace'` 自文档化，无需读者知道 `parent_uuid IS NULL` 的约定含义。
4. **Q9 配合**：与 `workspaces` 元数据表 JOIN 时，`kind = 'workspace'` 提供清晰的连接锚点。
5. **未来扩展安全**：若需要非 workspace 的 `parent_uuid IS NULL` 节点（导入暂存区、回收站等），不会破坏识别机制。

**Trade-off 记录**：现有 `match kind { folder => ..., atom_ref => ... }` 代码需增加 `workspace` 分支。但 workspace root 在树遍历中行为与 folder 一致（可有子节点），大部分分支为 `folder | workspace => ...`。新增分支的代价远小于静默失败的风险。

#### Q7.2 `parent_uuid IS NULL` 多行约束（RESOLVED）

**裁决**：多根方案下允许多行 `parent_uuid IS NULL`。

- 不建立 `parent_uuid IS NULL` 唯一性约束（与 Q2 的"恰好 1 行"相反）
- `kind = 'workspace'` 的行必须满足 `parent_uuid IS NULL`（CHECK 约束保证）
- `parent_uuid IS NULL` 的行必须满足 `kind = 'workspace'`（巡检验证，非 CHECK 约束——允许迁移过渡期的灵活性）
- 巡检可验证：`COUNT(*) WHERE parent_uuid IS NULL` = `COUNT(*) WHERE kind = 'workspace'`

#### Q7.3 可见性不变量微调（承接 Q4）（RESOLVED）

Q4 的核心不变量语义不变，范围从"全局单树到 ROOT"缩小为"per-workspace 树到 workspace root"：

> 若 `atom_ref.is_deleted = 0`，则从该 `atom_ref` 到其所属 **workspace root** 的全部祖先节点必须满足 `is_deleted = 0`。

写路径保证机制（delete_folder、move_node 等）不变。巡检修复的兜底目标从"移至 Inbox"改为"移至该 workspace root 级别"。

workspace root 自身不可删除（Q12 CHECK 约束保证），因此从任意节点到 workspace root 的祖先链上，root 段永远 active——与原方案中"系统节点段永远 active"的保证等价。

---

### Q8. `system_role` 列处置？（RESOLVED）

**裁决**：选择 **A（完全不引入 `system_role` 列）**。

Q7.1 选择 `kind = 'workspace'` 后，workspace root 的身份由 kind 承载，`system_role` 列的所有原始功能均已被覆盖：

| 原 `system_role` 功能 | 多根方案替代 |
|----------------------|-------------|
| 识别系统节点 | `kind = 'workspace'` 识别 workspace root |
| 保护系统节点 | 触发器（Q12，等效 CHECK 约束） |
| 指定 Tasks/Calendar/Inbox | `designated_folders` 表（Q9.1）；config 仅存 UI 偏好 |

**裁决理由**：schema 层不承载业务角色语义。workspace root 是结构概念（由 kind 表达），Tasks/Calendar 是业务概念（由 `designated_folders` 表表达）。两者分离，各自演进互不影响。

---

### Q9. Workspace 元数据存储？（RESOLVED）

**裁决**：选择 **A（独立 `workspaces` 表）**。

```sql
CREATE TABLE workspaces (
    workspace_id TEXT PRIMARY KEY
      REFERENCES workspace_nodes(node_uuid) DEFERRABLE INITIALLY DEFERRED,
    name TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
    -- v1.x 预留方向：
    -- owner_id TEXT,              -- 所有者用户 ID
    -- encryption_key_id TEXT,     -- per-workspace 加密密钥标识
    -- sharing_mode TEXT,          -- 'private' | 'shared'
    -- sync_endpoint TEXT,
    -- last_synced_at INTEGER
);

-- 全局最多一个 default workspace
CREATE UNIQUE INDEX idx_workspaces_default
ON workspaces(is_default) WHERE is_default = 1;
```

`is_default` 作为逻辑键定位默认 workspace，替代固定 UUID。partial unique index 保证全局最多一个 default。

**核心关系**：`workspaces.workspace_id` = `workspace_nodes.node_uuid`（`kind = 'workspace'` 的行）。同一 UUID，一对一。

**裁决理由**：

1. **三表职责分离**：
   - `workspaces` → workspace 级元数据（名称、权限、加密、同步）
   - `workspace_nodes` → 树拓扑结构（节点层级、排序、父子关系）
   - `atoms` → 扁平数据池（内容、状态、时间）
2. **通用表不承载特化语义**：`workspace_nodes` 中有成千上万的 folder/atom_ref 行，workspace 级元数据（加密密钥、同步端点、共享模式）只对极少数 `kind = 'workspace'` 行有意义。加在通用表上会导致绝大多数行的这些列永远为 NULL，语义污染。
3. **未来扩展隔离**：workspace 元数据会不断增长（用户权限、同步历史、密钥版本…），独立表可自由演进而不影响 `workspace_nodes` 的拓扑查询性能和语义清晰度。
4. **与 Q10 配合**：`atoms.origin_workspace_id` 可自然外键 `REFERENCES workspaces(workspace_id)`。
5. **事务一致**：workspace 创建是原子操作，两表通过共享 UUID 保持一致。

**一致性约束（防漂移/防脏数据）**：

| 风险 | 措施 |
|------|------|
| 孤儿 workspace 元数据（workspace_id 指向不存在的 node） | FK `REFERENCES workspace_nodes(node_uuid) DEFERRABLE INITIALLY DEFERRED`。延迟校验允许事务内任意插入顺序 |
| workspace_id 指向非 workspace 节点（如普通 folder） | Service 层保证插入顺序（先 workspace_nodes 再 workspaces）+ 巡检验证（`workspace_id` 对应的 node 必须 `kind = 'workspace'`）。SQLite 触发器立即执行、不支持 deferred，无法在事务内跨表校验，故不使用触发器 |
| `workspaces.name` 与 workspace root `display_name` 漂移 | **`workspaces.name` 为单一真相**。workspace root 的 `display_name` 在创建和重命名时由 Service 层同步写入，但读取 workspace 名称以 `workspaces.name` 为准 |
| `is_deleted` 双写不一致 | **`workspaces` 不设 `is_deleted` 列**。workspace 存活状态的单一真相是 workspace root node 的 `is_deleted`。查询活跃 workspace 时 JOIN：`SELECT w.* FROM workspaces w JOIN workspace_nodes n ON n.node_uuid = w.workspace_id WHERE n.is_deleted = 0` |

**创建 workspace 的事务流程**：

```
BEGIN IMMEDIATE;
  1. INSERT INTO workspace_nodes (node_uuid = <uuid>, kind = 'workspace',
     parent_uuid = NULL, display_name = <name>, ...)
  2. INSERT INTO workspaces (workspace_id = <uuid>, name = <name>, ...)
  3. 可选：创建默认子文件夹（Tasks、Calendar 等，由 app bootstrap 决定）
COMMIT;  -- FK 延迟到此时校验
```

> 注意插入顺序：先 workspace_nodes 再 workspaces，确保 Service 层 kind 校验可在第 2 步前验证目标 node 存在且 kind 正确。

**排除方案记录**：

- B（复用 workspace root 行）：workspace_nodes 是通用拓扑表，承载 workspace 级元数据会导致语义污染和列膨胀。
- C（Config 层管理）：config 文件与 DB 之间缺乏事务一致性保证，workspace 元数据属于持久化数据而非配置。

#### Q9.1 Designated Folder 映射与保护（RESOLVED）

**裁决**：选择 **C+（DB 真相 + Service 友好报错 + DB 触发器兜底）**。

Designated folder 映射（Tasks、Calendar、Inbox 等）作为 workspace 级配置数据存入 DB，而非 config 文件。config 只存 UI 偏好（如视图排列），不存 designated 真相。

**Schema**：

```sql
CREATE TABLE designated_folders (
    workspace_id TEXT NOT NULL REFERENCES workspaces(workspace_id),
    role TEXT NOT NULL,        -- 'tasks' | 'calendar' | 'inbox' | ...
    node_uuid TEXT NOT NULL REFERENCES workspace_nodes(node_uuid),
    PRIMARY KEY (workspace_id, role)
);

-- 删除保护触发器按 node_uuid 单列查询，需单列索引
CREATE INDEX idx_designated_folders_by_node
ON designated_folders(node_uuid);

-- reassign 查询和同 workspace 校验的性能保障
CREATE INDEX idx_designated_folders_by_ws_node
ON designated_folders(workspace_id, node_uuid);
```

**约束设计**：

| 约束 | 机制 | 说明 |
|------|------|------|
| 每个 role 恰好一个映射 | `PRIMARY KEY(workspace_id, role)` | 智能视图始终有目标文件夹 |
| 同一 folder 可承载多 role | 不加 `UNIQUE(workspace_id, node_uuid)` | 语义不冲突，只是路由收敛。Service/UI 在第二个 role 指向同一 folder 时给确认提示 |
| 只允许 reassign，不允许删除映射 | Service 层拒绝 `DELETE FROM designated_folders` | role 永远有映射，app 无需处理"无目标文件夹"边缘情况 |
| 被 designated 的 folder 不可删除 | DB 触发器（见下） + Service 层友好报错 | 要删当前 designated folder → 先 reassign 到另一个 folder |
| node_uuid 必须属于同一 workspace | DB 触发器（见下） + Service 层校验 | 防止旁路 SQL 跨 workspace 指定 designated folder |

**触发器**：

```sql
-- 1. 同 workspace 校验：designated folder 必须属于对应 workspace 的子树
CREATE TRIGGER validate_designated_folder_workspace
BEFORE INSERT ON designated_folders
BEGIN
    SELECT CASE WHEN NOT EXISTS (
        -- 验证 node_uuid 存在、是 active folder、且其 workspace root 匹配 workspace_id
        WITH RECURSIVE ancestors(uuid, parent) AS (
            SELECT node_uuid, parent_uuid FROM workspace_nodes
            WHERE node_uuid = NEW.node_uuid AND is_deleted = 0 AND kind = 'folder'
            UNION ALL
            SELECT wn.node_uuid, wn.parent_uuid FROM workspace_nodes wn
            JOIN ancestors a ON wn.node_uuid = a.parent
        )
        SELECT 1 FROM ancestors WHERE uuid = NEW.workspace_id
    ) THEN RAISE(ABORT, 'designated folder must belong to the same workspace') END;
END;

-- 同 workspace 校验（UPDATE 时同样需要）
CREATE TRIGGER validate_designated_folder_workspace_update
BEFORE UPDATE OF node_uuid ON designated_folders
BEGIN
    SELECT CASE WHEN NOT EXISTS (
        WITH RECURSIVE ancestors(uuid, parent) AS (
            SELECT node_uuid, parent_uuid FROM workspace_nodes
            WHERE node_uuid = NEW.node_uuid AND is_deleted = 0 AND kind = 'folder'
            UNION ALL
            SELECT wn.node_uuid, wn.parent_uuid FROM workspace_nodes wn
            JOIN ancestors a ON wn.node_uuid = a.parent
        )
        SELECT 1 FROM ancestors WHERE uuid = NEW.workspace_id
    ) THEN RAISE(ABORT, 'designated folder must belong to the same workspace') END;
END;

-- 2. 禁止 soft-delete 被 designated 的 folder
CREATE TRIGGER protect_designated_folder_soft_delete
BEFORE UPDATE OF is_deleted ON workspace_nodes
WHEN NEW.is_deleted = 1 AND EXISTS (
    SELECT 1 FROM designated_folders WHERE node_uuid = OLD.node_uuid
)
BEGIN
    SELECT RAISE(ABORT, 'cannot delete designated folder; reassign first');
END;

-- 3. 禁止 hard-delete 被 designated 的 folder
CREATE TRIGGER protect_designated_folder_hard_delete
BEFORE DELETE ON workspace_nodes
WHEN EXISTS (
    SELECT 1 FROM designated_folders WHERE node_uuid = OLD.node_uuid
)
BEGIN
    SELECT RAISE(ABORT, 'cannot hard-delete designated folder');
END;
```

**裁决理由**：

1. **消除 config/DB 脑裂**：designated 映射与树数据在同一 DB 内，事务一致。config 文件无法保证与 DB 的原子性。
2. **删除保护闭环**：触发器是简单的存在性检查（非业务逻辑），性质类似 FK 约束。Service 层提供友好报错（"请先将 Tasks 角色 reassign 到其他文件夹"）。
3. **Q8 精神不变**：`workspace_nodes` 表本身无业务角色列。designated 映射在独立表中，是 workspace 级配置数据，与 `workspaces` 表同级。
4. **"只允许 reassign" 消除边缘情况**：智能视图始终有目标文件夹，零空指针风险。

**对 DI-16 的影响**：DI-16 A8 "config 层指定 designated folder" 需修正为 "designated_folders 表指定"。

---

### Q10. `origin_workspace_id` 字段设计？（RESOLVED）

**裁决**：选择 **C+（引入但先不做强消费，DI-16 决定是否升级读路径）**。

```sql
ALTER TABLE atoms ADD COLUMN origin_workspace_id TEXT
  REFERENCES workspaces(workspace_id);
```

**裁决理由**：

1. **符合分层**：DI-15 是数据模型层，只管"列存不存在"。读路径是否校验此字段属于 Service/FFI 行为，归 DI-16 决策。
2. **避免假安全承诺**：Local-first 下 v0.x 的"鉴权"本质只是应用层门禁，不是真安全（见安全模型章节）。在数据模型层声称"鉴权"会误导。
3. **先打数据基础**：现在加列、回填、建外键，后续升级（v0.x UI 门禁 / v1.x 密钥索引）成本最低。

**落地口径**：

| 项 | 规则 |
|---|------|
| 加列 | `atoms.origin_workspace_id TEXT REFERENCES workspaces(workspace_id)` |
| Migration 回填 | 所有现有 atom 回填为 default workspace 的 `workspace_id` |
| 新写入 | Service 层保证创建 atom 时必须填 `origin_workspace_id`（NOT NULL by convention，列本身 nullable 以兼容回填） |
| v0.x 读路径 | **不做硬拒绝**。此字段写入但不消费 |
| 升级路径 | DI-16 决定是否升级为 A 化（UI 门禁 / Dead Link）；v1.x 升级为密钥索引 |

**双重语义路线图**：

| 阶段 | 语义 |
|------|------|
| v0.x | 数据归属标记 — 标识 atom 由哪个 workspace 创建。写入但不消费 |
| v0.x+ (DI-16) | 可选升级为应用层门禁 — FFI 读取时检查 workspace 权限，Dead Link UI |
| v1.x | 密钥索引 — 标识用哪把 workspace key 加密了 atom content |

---

### Q11. Migration SQL 设计？（RESOLVED）

新 migration（`0012_workspace_multi_root.sql`）的具体内容。Migration executor 需要从纯 SQL `execute_batch` 升级为 **Rust 代码 + SQL 混合执行**，以支持运行时 UUID 生成。

**与原 Q3 的关键差异**：

| 原 Q3（单根） | Q11（多根） |
|---------------|------------|
| 创建 ROOT + Inbox + Tasks + Calendar 4 个系统节点 | 1 个 workspace root + 3 个 designated folder |
| 4 个 well-known UUID | 全部随机生成，逻辑键定位 |
| root-level folder → ROOT, root-level atom_ref → Inbox | 全部 root-level 节点统一 → workspace root |
| system_role 列 + UNIQUE index | 不引入（Q8） |

#### Q11.1 UUID 策略（RESOLVED）

**裁决**：选择 **B（随机生成，逻辑键定位）**。

所有 UUID 在 Rust migration 代码中 `Uuid::new_v4()` 生成，作为事务内中间变量使用，不硬编码为常量。

**逻辑键定位**（替代固定 UUID 的稳定锚点）：

| 查询目标 | 逻辑键 |
|---------|--------|
| 所有 workspace root | `WHERE kind = 'workspace'` |
| 默认 workspace | `workspaces WHERE is_default = 1`（partial unique index 保证唯一） |
| 某 workspace 的 Tasks 文件夹 | `designated_folders WHERE workspace_id = ? AND role = 'tasks'` |

**裁决理由**：

1. **多实例同步安全**：固定 UUID 在两个独立安装间共享时产生确定性碰撞。随机 UUID 无此风险。
2. **概念一致性**：default workspace 与用户创建的 workspace 走相同代码路径（`Uuid::new_v4()`），无特殊分支。
3. **逻辑键已充分**：`kind = 'workspace'`（Q7）和 `designated_folders.role`（Q9.1）提供了所有必要的语义查询路径，无需 UUID 常量。

#### Q11.2 回填规则（RESOLVED）

**裁决**：所有 root-level 节点统一 re-parent，不按 kind 分流。

```sql
-- 所有 parent_uuid IS NULL 的现有节点 → default workspace root
UPDATE workspace_nodes
SET parent_uuid = :ws_root_uuid,
    updated_at = (strftime('%s', 'now') * 1000)
WHERE parent_uuid IS NULL
  AND node_uuid != :ws_root_uuid;
```

比原 Q3 简单：不需要区分 folder 和 atom_ref 的回填目标。

`atoms.origin_workspace_id` 回填（Q10）：

```sql
UPDATE atoms
SET origin_workspace_id = :ws_id
WHERE origin_workspace_id IS NULL;
```

#### Q11.3 Designated Folders 创建时机（RESOLVED）

**裁决**：**Migration 中创建**。默认 designated roles = `inbox`、`tasks`、`calendar`。

**理由**：Q9.1 裁决"只允许 reassign，不允许删除映射"。如果 designated_folders 表在 migration 后为空，app 首次启动前存在违反此不变量的空窗期。Migration 中创建 3 个 folder + 3 条 designated_folders 映射，不变量从迁移完成那一刻起即成立。

#### Q11.4 现有触发器兼容性

Migration 11 加入了 S4 触发器（atom_ref 创建时自动 accompaniment）。0012 migration 需要注意：

- UPDATE `parent_uuid`（回填）不会触发 S4（S4 是 INSERT 触发器，不是 UPDATE）
- INSERT workspace root node 的 `kind = 'workspace'`（非 `atom_ref`），不触发 S4
- INSERT designated folder nodes 的 `kind = 'folder'`（非 `atom_ref`），不触发 S4
- **结论**：S4 触发器与 0012 migration 不冲突，无需临时禁用

#### Q11 综合：Migration 执行流程草案

执行顺序原则：**数据操作 → 断言校验 → 最终保护触发器**。触发器在所有数据就位后再创建，避免干扰 migration 自身的数据写入。不使用临时触发器。

```
-- 在 Rust migration 代码中执行（单事务内）

let ws_root_uuid = Uuid::new_v4();
let inbox_uuid = Uuid::new_v4();
let tasks_uuid = Uuid::new_v4();
let calendar_uuid = Uuid::new_v4();

-- ═══ Phase 1: Schema 变更 ═══

-- Step 1: 新建表（不含触发器）
CREATE TABLE workspaces (...);              -- Q9 schema（含 is_default 列 + partial unique index）
CREATE TABLE designated_folders (...);       -- Q9.1 schema（含反查索引）

-- Step 2: atoms 加列（Q10）
ALTER TABLE atoms ADD COLUMN origin_workspace_id TEXT
  REFERENCES workspaces(workspace_id);

-- ═══ Phase 2: 数据操作 ═══

-- Step 3: 创建 workspace root node
INSERT INTO workspace_nodes
  (node_uuid, kind, parent_uuid, display_name, sort_order, is_deleted, ...)
VALUES (:ws_root_uuid, 'workspace', NULL, 'My Workspace', 0, 0, ...);

-- Step 4: 创建 workspaces 元数据
INSERT INTO workspaces (workspace_id, name, is_default, ...)
VALUES (:ws_root_uuid, 'My Workspace', 1, ...);

-- Step 5: 回填 — 现有 root-level 节点 → workspace root
UPDATE workspace_nodes
SET parent_uuid = :ws_root_uuid,
    updated_at = (strftime('%s', 'now') * 1000)
WHERE parent_uuid IS NULL AND node_uuid != :ws_root_uuid;

-- Step 6: 创建 3 个 designated folder
INSERT INTO workspace_nodes (node_uuid, kind, parent_uuid, display_name, sort_order, ...)
VALUES
  (:inbox_uuid, 'folder', :ws_root_uuid, 'Inbox', 0, ...),
  (:tasks_uuid, 'folder', :ws_root_uuid, 'Tasks', 1, ...),
  (:calendar_uuid, 'folder', :ws_root_uuid, 'Calendar', 2, ...);

-- Step 7: 创建 designated_folders 映射
INSERT INTO designated_folders (workspace_id, role, node_uuid)
VALUES
  (:ws_root_uuid, 'inbox', :inbox_uuid),
  (:ws_root_uuid, 'tasks', :tasks_uuid),
  (:ws_root_uuid, 'calendar', :calendar_uuid);

-- Step 8: 回填 atoms.origin_workspace_id
UPDATE atoms SET origin_workspace_id = :ws_root_uuid
WHERE origin_workspace_id IS NULL;

-- ═══ Phase 3: 断言校验 ═══

-- Step 9: 校验数据正确性（任何断言失败 → 事务回滚）
-- 9a: workspace root 存在且唯一（v0.x）
SELECT CASE WHEN (SELECT COUNT(*) FROM workspace_nodes
  WHERE kind = 'workspace' AND is_deleted = 0) != 1
  THEN RAISE(ABORT, 'assertion: expected exactly 1 workspace root') END;

-- 9b: 无孤儿 root-level 节点
SELECT CASE WHEN (SELECT COUNT(*) FROM workspace_nodes
  WHERE parent_uuid IS NULL AND kind != 'workspace') != 0
  THEN RAISE(ABORT, 'assertion: orphan root-level nodes remain') END;

-- 9c: designated_folders 完整
SELECT CASE WHEN (SELECT COUNT(*) FROM designated_folders
  WHERE workspace_id = :ws_root_uuid) != 3
  THEN RAISE(ABORT, 'assertion: expected 3 designated folder mappings') END;

-- ═══ Phase 4: 最终保护触发器 ═══

-- Step 10: workspace root re-parent 保护（Q12）
CREATE TRIGGER protect_workspace_root_reparent
BEFORE UPDATE OF parent_uuid ON workspace_nodes
WHEN OLD.kind = 'workspace' AND NEW.parent_uuid IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'cannot re-parent workspace root');
END;

-- Step 11: workspace root kind 变更保护（Q12）
CREATE TRIGGER protect_workspace_root_kind
BEFORE UPDATE OF kind ON workspace_nodes
WHEN OLD.kind = 'workspace'
BEGIN
    SELECT RAISE(ABORT, 'cannot change kind of workspace root');
END;

-- Step 12: designated folder 同 workspace 校验（Q9.1）
CREATE TRIGGER validate_designated_folder_workspace ...;     -- INSERT
CREATE TRIGGER validate_designated_folder_workspace_update ...; -- UPDATE
-- （完整 SQL 见 Q9.1 触发器定义）

-- Step 13: designated folder 删除保护（Q9.1）
CREATE TRIGGER protect_designated_folder_soft_delete ...;
CREATE TRIGGER protect_designated_folder_hard_delete ...;
-- （完整 SQL 见 Q9.1 触发器定义）

-- ═══ Finalize ═══
-- Step 14: PRAGMA user_version = 12
```

**App bootstrap 职责**：不负责首次落库真相（migration 已完成）。仅做幂等巡检/自愈：验证 designated_folders 映射完整、workspace root 存在、无悬挂链。

**风险缓解**（承接原 Q3.2）：

| 风险 | 措施 |
|------|------|
| 触发器干扰 migration 数据操作 | Phase 4 在所有数据就位后才创建触发器 |
| S4 触发器副作用 | 已分析无冲突（Q11.4） |
| `updated_at` 遗漏 | UPDATE 语句显式 SET `updated_at` |
| 中间状态 | 整个迁移在单事务内完成 |
| 空库场景（无现有节点） | Step 5 WHERE 条件 match 0 行，无副作用 |
| 断言失败 | Phase 3 任何断言失败 → RAISE(ABORT) → 事务回滚 → DB 保持 v11 |
| Migration executor 升级 | 需从纯 SQL `execute_batch` 升级为 Rust 代码执行。仅 0012 需要此能力（UUID 生成），0001-0011 不受影响 |

---

### Q12. Workspace Root 保护约束？（RESOLVED）

替代原 Q5 的系统节点保护。多根方案下需要保护的对象更少、更简单。

**裁决**：选择 **B+（Service 层 + DB 触发器，触发器作为最终守卫）**。

原方案 C（CHECK 约束）概念上最优，但 SQLite 不支持 `ALTER TABLE ADD CHECK` — `workspace_nodes` 表已存在，无法追加 CHECK 约束（除非重建表，风险过高）。触发器是等效替代。

**需要保护的操作与对应触发器**：

| 操作 | 保护理由 | 触发器 |
|------|---------|--------|
| re-parent workspace root | root 不能成为其他节点的子节点 | `protect_workspace_root_reparent` |
| 修改 workspace root 的 kind | 防止 kind 从 'workspace' 改为 'folder' 导致身份丢失 | `protect_workspace_root_kind` |
| 删除 designated folder | Q9.1 已覆盖 | `protect_designated_folder_soft_delete` / `_hard_delete` |

**workspace root 的删除保护**由 Q9.1 间接覆盖：workspace root 下存在 designated folders → designated folders 不可删除 → `delete_folder(delete_all)` 在递归到 designated folder 时被触发器拦截。Service 层额外拒绝直接 soft-delete `kind = 'workspace'` 的节点，提供友好报错。

**触发器（2 个，在 Q11 migration Phase 4 创建）**：

```sql
-- 禁止 workspace root 被 re-parent（等效 CHECK: kind != 'workspace' OR parent_uuid IS NULL）
CREATE TRIGGER protect_workspace_root_reparent
BEFORE UPDATE OF parent_uuid ON workspace_nodes
WHEN OLD.kind = 'workspace' AND NEW.parent_uuid IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'cannot re-parent workspace root');
END;

-- 禁止修改 workspace root 的 kind（防身份丢失）
CREATE TRIGGER protect_workspace_root_kind
BEFORE UPDATE OF kind ON workspace_nodes
WHEN OLD.kind = 'workspace'
BEGIN
    SELECT RAISE(ABORT, 'cannot change kind of workspace root');
END;
```

**与原 Q5 的对比**：

| | 原 Q5（单根） | Q12（多根） |
|---|---|---|
| 保护对象 | 4 个系统节点（ROOT/Inbox/Tasks/Calendar） | workspace root（kind 保护）+ designated folders（映射保护） |
| 触发器数量 | 3 个（禁删 + 禁 hard-delete + 禁改 role） | 2 个 workspace root 触发器 + 2 个 designated folder 触发器 = 4 个 |
| 保护机制 | system_role 列 + 触发器 | kind 枚举 + designated_folders 表 + 触发器 |
| 灵活性 | 系统节点固定不可变 | designated folder 可 reassign，workspace root 的 kind 和 parent 不可变 |

**裁决理由**：

1. **触发器等效 CHECK**：`protect_workspace_root_reparent` 精确等效 `CHECK(kind != 'workspace' OR parent_uuid IS NULL)`，只是实现形式不同（SQLite ALTER TABLE 限制）。
2. **kind 保护必要性**：如果 kind 从 `workspace` 改为 `folder`，re-parent 触发器失效（条件 `OLD.kind = 'workspace'` 不再匹配），形成绕过路径。`protect_workspace_root_kind` 封堵此漏洞。
3. **删除保护无需专用触发器**：designated_folders 触发器（Q9.1）已间接阻止 workspace root 被 `delete_all` 清空。Service 层直接拒绝 soft-delete workspace root。两层叠加，无需第三个触发器。

---

## 跨工作区安全模型

> 本节独立于具体树拓扑方案 — 只要支持跨 workspace 共享，安全模型就需要解决。

### 根本约束：Local-first 下代码逻辑不等于安全

> "Never trust the client." — SQLite 文件物理落盘在用户本地设备上，任何代码级别的 `if-else` 鉴权在物理读取面前均无效。用户无需逆向 Rust 内核，仅用 DB Browser for SQLite 即可明文读取 atoms 表全部内容。

### 三层安全架构

| 阶段 | 机制 | 防御对象 | 局限性 |
|------|------|----------|--------|
| **v0.x 应用层防护** | `origin_workspace_id` + 代码逻辑拦截 + Dead Link UI | 正常 UI 路径下的误操作（防君子） | 物理访问 DB 即绕过 |
| **v1.x 存储层加密** | Per-workspace AES-256 对称密钥，atoms content 存密文 blob | 物理窃取（本地 DB 打开也是乱码） | 已同步明文无法追回 |
| **v2.x 前向保密** | Key Ratcheting — 成员变更时密钥滚动，旧密钥销毁 | 权限撤销后的未来数据泄露 | 撤销前已查看的数据不可追回 |

### v0.x 方案（当前阶段）

1. **`origin_workspace_id`** on atoms：来源 workspace 标记。v0.x **写入但不消费**（Q10 C+ 裁决），仅打数据基础。
2. **可选升级路径（DI-16 决定）**：FFI 层读取时校验 workspace 权限（应用层门禁）、Dead Link UI。是否在 v0.x 启用由 DI-16 裁决。
3. **已知局限**：即使启用 FFI 门禁，也仅防 UI 路径，无法防物理 DB 访问。

### v1.x 存储加密方向（预留）

- 写入 SQLite 前，Rust Core 用 workspace key 加密 atom content → 存储密文 blob。
- 撤销权限 = 从本地密钥链销毁对应 workspace key → 本地密文不可解。
- `origin_workspace_id` 的双重语义（鉴权索引 → 密钥索引）使得升级无需改列。

### 不可解悖论（The Local-First Paradox）

> 已同步到本地且已查看过的数据，物理上无法追回。密钥滚动（Key Ratcheting）只能保证撤销时刻之后的新数据不可读。这是 Local-first 架构的固有物理约束，非设计缺陷。

---

## 关联

- ← DI-12（概念母题：Q1-Q12 裁决；部分被多根方案覆盖）
- ← DI-14 Q2（接口需求：5 个查询元接口对数据层的要求）
- ↔ DI-16（Rust Service + FFI 契约：A8 designated folder、ScopedAtomQuery 依赖本 DI schema）
- → DI-18（执行方案：migration 的实际部署策略）

---

*前序议题：[DI-14 Workspace Tree Core Promotion](DI-14-workspace-tree-core-promotion.md)*
