# DI-16: Rust Service 层与 FFI 契约

| 项目 | 值 |
|------|-----|
| **状态** | IN PROGRESS |
| **关联决策点** | DI-12（概念母题）、DI-14 Q1-Q2（核心能力与接口需求）、DI-15（数据模型） |
| **影响范围** | `lazynote_core` service/repo 层、`lazynote_ffi` API、`ffi-contracts.md`、`API_COMPATIBILITY.md` |
| **前置依赖** | DI-15（Rust 数据模型裁决） |
| **目标版本** | v0.4 |
| **输出物** | API 契约文档（Rust service 接口 + FFI 导出函数 + error code + 兼容策略） |

---

## 背景

DI-15 确定了多根森林（Multi-Root Forest）的数据模型：`workspaces` 元数据表、`designated_folders` 映射表、`kind = 'workspace'` 识别机制、`origin_workspace_id` 归属标记、保护触发器。本 DI 在此基础上设计 Rust Core 的服务层接口和 FFI 导出，将数据模型转化为可消费的 API。

**边界原则**：本 DI 只讨论 Rust 层的服务接口与 FFI 契约（"怎么暴露和使用数据"），不讨论数据 schema（DI-15）或 Flutter 消费（DI-17）。

### 输入约束

| 来源 | 约束 |
|------|------|
| DI-14 Q1 | 5 项核心能力：子树查询、CRUD、workspace/designated 解析、创建路由、变更通知 |
| DI-14 Q2 | 5 个查询元接口：listChildren、listSubtreeAtomRefs、getNode、getAncestorPath、listAtomRefsForAtom |
| DI-12 Q6 | 创建路由优先级：显式目标 > 意图上下文 > Inbox designated folder |
| DI-12 Q7/Q8 | Tasks/Calendar 数据源 = designated folder 子树（DI-15 Q9.1 落地为 `designated_folders` 表） |
| DI-12 Q10 | FFI 兼容优先：保持 `parent_node_id: Option<String>` |
| DI-14 Q1 | AccessGuard 权限层预留（关联 DI-15 Q10 `origin_workspace_id`） |
| S1 R1 | Atom 统一容器模型 — view_hint 是渲染提示，不是类型约束 |
| S1 R3 | view_hint 自动推导 — task_status 优先规则 |
| S1 R6 | 指定默认路径模型 — 所有文件夹结构平等，designated folder = 指定了默认路径的文件夹 |
| S1 R7 | 多引用 — 同一 Atom 可有多个 atom_ref，所有引用平等 |
| DI-15 Q7 | workspace root = `kind = 'workspace'`，多根森林 |
| DI-15 Q9 | `workspaces` 独立表（含 `is_default`），FK to workspace_nodes |
| DI-15 Q9.1 | `designated_folders(workspace_id, role, node_uuid)` 为 DB 真相，只允许 reassign |
| DI-15 Q10 | `origin_workspace_id` 写入但不消费（C+），本 DI 决定是否升级读路径 |

---

## 讨论边界

### In Scope

1. 统一查询层设计（ScopedAtomQuery）。
2. 树导航专用方法（get_ancestor_path、list_subtree_atom_refs、list_atom_refs_for_atom）。
3. 统一创建入口设计（CreateAtomRequest）。
4. TreeService 演进（系统节点感知、查询委托）。
5. AccessGuard 接口设计（caller context、透明放行策略）。
6. FFI 新增/修改函数、响应类型、error code、兼容策略。

### Out of Scope

1. 数据 schema 与 migration → DI-15。
2. Flutter 层消费设计 → DI-17。
3. PR 拆分与执行顺序 → DI-18。

---

## 已确认的架构方向

以下架构认知在讨论中确认，作为后续各 Q 裁决的前提。

### A1. 数据结构：多根森林 + 共享 atom pool

workspace_nodes 构成多根森林——每个 workspace 是一棵独立的树（root = `kind = 'workspace'`），树之间物理隔离（递归 CTE 从 workspace root 出发，天然不跨树）。atoms 表是全局扁平数据池，atom_refs 跨 workspace 指向同一 atom，形成 DAG 可达性图。

### A2. 文件夹语义归属

designated folder（Tasks/Calendar/Inbox）的 atom_ref 放置 = 语义声明。"把 atom_ref 放入 Tasks designated folder"定义了"这个 atom 在 Tasks 视图中有意义"。时间/状态是属性，不是身份。这与 S1 R6 指定默认路径模型一致：

- atom 放入 Tasks designated folder → 出现在 Tasks 智能视图
- atom 放入 Calendar designated folder → 出现在 Calendar 智能视图
- atom 从 designated folder 移出 → 从对应智能视图消失
- 用户通过空间操作（拖拽/复制引用）表达语义意图

### A3. 智能视图 = designated folder 子树查询

Tasks/Calendar 视图的数据源是对应 designated folder 的子树（S1 R6、DI-15 Q9.1），不是全局 atoms 表直查。Service 层通过 `designated_folders` 表查询 `role = 'tasks'` 获取目标 folder_id。文件夹内未匹配视图查询条件的 atom 进入承接区域（S1 R6）：

- Tasks：Inbox section 承接有 task_status 但无时间字段的 atom
- Calendar：待排期池承接无时间字段的 atom

### A4. 两种消费模式

| 消费模式 | 消费者 | 需要 | 不需要 |
|---------|--------|------|--------|
| 智能视图消费 | Tasks / Calendar | atom 字段（时间/状态）做 section 分区 + 分页排序 | 路径 |
| 树导航消费 | Tag Explorer / 文件夹概览 | 路径字符串做位置展示 | 复杂 section 分区 |

智能视图和树导航是两种独立消费模式，共享子树查询基础设施但输出形态不同。

### A5. view_hint 保持 S1 R3 定义

view_hint 是 atom 上的自动推导渲染提示，与文件夹位置正交：

- **视图上下文**决定"在哪个视图展示"（由文件夹位置决定）
- **view_hint** 决定"怎么画"（由 atom 属性自动推导）

view_hint 不需要移到 atom_ref 上。在搜索结果、Explorer 等脱离视图上下文的场景中，view_hint 提供渲染 fallback。

### A6. 文件夹结构平等

所有文件夹在结构上完全平等（均为 workspace_node kind=folder）。操作行为一致：可重命名、可移入移出子节点、可被移动。designated folder（Tasks/Calendar 等视图数据源）与普通文件夹的唯一差异是 **`designated_folders` 表的映射关系**和**对应的 DB 触发器删除保护**，不是 schema 层的固有属性。

### A7. 指定文件夹 = DB 层映射（designated_folders 表）

"哪个文件夹是 Tasks 视图的数据源"由 `designated_folders(workspace_id, role, node_uuid)` 表管理（DI-15 Q9.1）：

- **DB 是真相**，config 仅存 UI 偏好（如视图排列顺序）
- 只允许 **reassign**（将 role 指向另一个 folder），不允许删除映射 — 智能视图始终有目标文件夹
- 被 designated 的 folder 受 DB 触发器保护，不可删除
- 同一 folder 可承载多 role（路由收敛），Service/UI 给确认提示
- `PRIMARY KEY(workspace_id, role)` 保证每个 role 恰好一个映射

Service 层通过查询此表解析 designated folder：`SELECT node_uuid FROM designated_folders WHERE workspace_id = ? AND role = ?`

### A8. 子树查询策略：CTE + 索引 — RESOLVED

**裁决**：不引入 `scope_folder` 反规范化列。子树查询统一使用递归 CTE，从目标 folder 出发遍历子树。

**理由**：
- 个人笔记应用中，单个 folder 下节点数为几十到几百，CTE 性能完全足够
- 多根森林的 CTE 已天然隔离到单 workspace / 单 designated folder，查询范围自然收窄
- scope_folder 是反规范化——需要在 INSERT/MOVE/DELETE 时维护一致性，增加 bug 风险和写路径复杂度
- scope_folder 锚定"某一级文件夹"的假设限制了 designated folder 可在任意深度的灵活性

**v0.4 索引优化（S0）**：
```sql
CREATE INDEX idx_wn_parent_deleted_kind ON workspace_nodes(parent_uuid, is_deleted, kind);
CREATE INDEX idx_wn_atom_deleted ON workspace_nodes(atom_uuid, is_deleted);
-- designated_folders(node_uuid) 已在 DI-15 Q9.1 中建立
```

**分层升级路径**（按 profiling 数据触发，不预实现）：

| 阶段 | 策略 | 触发条件 |
|------|------|---------|
| S0 | CTE + 上述索引（v0.4 采用） | — |
| S1 | 查询拆段：CTE 先收集 node_uuid 集，再单独 JOIN atoms | CTE+JOIN 放大明显 |
| S2 | designated 视图物化缓存表 `designated_scope_members` | designated folder 子树查询成为瓶颈 |
| S3 | 通用 closure table（ancestor, descendant, depth） | 任意子树查询频繁且数据量大 |

S1 为编码实践（不需 schema 变更），S2/S3 需要额外 migration 和写路径触发器。

### A9. 多视图与共享扩展性

架构应支持未来扩展到：
- **单人多视图**：一个用户可以有多个 Tasks/Calendar 视图（如 Work-Tasks、Personal-Tasks）
- **多人共享**：多个用户共享文件夹，通过 atom_ref 自然合并到各自视图

ref 模型的天然优势：共享导入 = 在自己的文件夹中创建 atom_ref，零数据复制，自动出现在视图中。ScopedAtomQuery 以 folder_id 为唯一范围参数，天然支持单视图/多视图/共享场景的统一查询。

### A10. DI-15 回溯审视 — DONE

DI-15 已完成多根森林方案的全面重审（Q7-Q12），所有回溯项已裁决：

| 原回溯项 | DI-15 裁决 |
|---------|-----------|
| `system_role` 列 | Q8：完全不引入 |
| well-known UUID | Q11.1：随机生成，逻辑键定位 |
| protection triggers | Q12：2 个 workspace root 触发器 + Q9.1：2+2 个 designated folder 触发器 |
| migration 预插入 | Q11.3：migration 中创建 workspace root + 3 个 designated folder（消除空窗期） |

### A11. 统一查询方向

现有分散的 section 查询（`fetch_inbox` / `fetch_today` / `fetch_upcoming` / `fetch_by_time_range`，分布在 `AtomRepository` + `TaskService`）可收敛为一个可组合的查询结构。子树范围通过递归 CTE 从目标 folder 出发遍历（A8），query builder 统一组合 CTE + WHERE + JOIN。

**现状问题**：v0.3 要给每个 section 查询加子树范围 = 修改 5+ 个方法，每个都加相同的递归 CTE 代码。且 TaskService 需同时依赖 AtomRepository + TreeRepository，耦合度上升。

**收敛方向**：一个 query builder 在 SQL 层组合递归 CTE（子树范围）+ WHERE（时间/状态过滤）+ JOIN（atom 字段），所有 section 查询变为参数组合：

| 现有调用 | 等价 ScopedAtomQuery 参数 |
|---------|------------|
| `tasks_list_inbox` | `{ scope: FolderSubtree(tasks_folder), time: Timeless, shape: Any, status: ActiveOnly }` |
| `tasks_list_today` | `{ scope: FolderSubtree(tasks_folder), time: Range(bod, Some(eod)), shape: Any, status: ActiveOnly }` |
| `tasks_list_upcoming` | `{ scope: FolderSubtree(tasks_folder), time: Range(eod, None), shape: Any, status: ActiveOnly }` |
| `calendar_list_by_range` | `{ scope: FolderSubtree(cal_folder), time: Range(s, Some(e)), shape: BoundedOnly, status: Any }` |
| Calendar 待排期池 | `{ scope: FolderSubtree(cal_folder), time: Timeless, shape: Any, status: Any }` |
| Tag Explorer | `{ scope: FolderSubtree(ws_root), tag: "work", shape: Any, include_path: true }` |
| 文件夹内容概览 | `{ scope: FolderSubtree(some_folder), shape: Any, include_path: true }` |

其中 `tasks_folder` / `cal_folder` 由 Service 层查 `designated_folders WHERE role = ?` 解析得到。Repo 层只认 `folder_id`，不认 role。folder 过滤通过递归 CTE 实现，A8 索引优化确保 CTE 每步遍历高效。产品层不暴露 Global scope（见 Q1.2 "Global 分层归属"）。

### A12. 统一创建方向

现有 3 个分立创建方法（`create_note_with_ref` / `create_task_with_ref` / `create_event_with_ref`）可收敛为 1 个属性驱动的统一创建入口。调用方声明属性（task_status、time fields），view_hint 由 S1 R3 自动推导，`origin_workspace_id` 自动填入当前 workspace（DI-15 Q10）。与 DI-11 atom_create 收敛方向一致。现有 FFI 函数（`entry_create_task` 等）变为统一入口的薄包装。

路由目标解析从"查询 system_role"改为"查询 `designated_folders` 表"：`target_folder = None` 时，按 S1 R6 路由到对应 designated folder（有 task_status → `role='tasks'`，有 time fields → `role='calendar'`，否则 → `role='inbox'`）。

---

## 裁决记录（Q1-Q6）

### Q1. 统一查询层 ScopedAtomQuery — RESOLVED

**背景**：A11 确定了统一查询方向，A8 确定子树查询使用递归 CTE + 索引优化。本 Q 裁决具体接口设计。

#### Q1.1 结构体字段 — RESOLVED

```rust
pub enum TimeFilter {
    Any,
    Timeless,
    Range { start_ms: i64, end_ms: Option<i64> },  // overlap 语义；end_ms = None 表示无上界
}

pub enum TimeShapeFilter {
    Any,
    BoundedOnly,  // start_at IS NOT NULL AND end_at IS NOT NULL
}

pub enum StatusFilter {
    Any,
    ActiveOnly,
    TaskStatuses(Vec<TaskStatus>),
}

pub enum SortSpec {
    UpdatedAtDesc,
    StartAtAsc,
    TitleAsc,
}

pub struct ScopedAtomQuery {
    pub folder_id: WorkspaceNodeId,          // 始终 scoped — workspace 级查询传 workspace_root
    pub view_hint: Option<ViewHint>,
    pub time_filter: TimeFilter,
    pub time_shape: TimeShapeFilter,
    pub status_filter: StatusFilter,
    pub tag: Option<String>,
    pub text_query: Option<String>,            // FTS5 全文搜索过滤
    pub include_path: bool,
    pub include_overdue_deadlines: bool,       // Today 场景：Repository 内部 UNION overdue T1
    pub sort: SortSpec,
    pub limit: u32,
    pub offset: u32,
}

pub enum ProjectionMode {
    Atom,  // 智能视图：按 atom 去重（Tasks/Calendar）
    Ref,   // 树导航：按 ref，每个 atom_ref 独立条目（Explorer/Tag）
}

pub struct ScopedAtomResult {
    pub representative_node_uuid: WorkspaceNodeId,  // Atom 投影：非稳定提示；Ref 投影：稳定
    pub atom: Atom,
    pub path: Option<String>,  // include_path=true 时填充；Atom 投影下为非稳定代表路径
}
```

**设计要点**：

- **folder_id 始终必传**：不存在 Global scope。查询边界 = 加密边界（见下方"Global 分层归属"）。"全 workspace" = 传 workspace_root 的 node_uuid。跨 workspace 聚合未来另开 `WorkspaceSet{ids}` 专用路径。
- **TimeFilter**：Repo 层只认三种查询原语（Any/Timeless/Range）。`Range.end_ms = None` 表示无上界（SQL 省略上界条件），消除 `i64::MAX` 哨兵值。Today/Upcoming 是业务概念，由 Service 层转换后传入：
  - `Today(bod, eod)` → `Range(bod, Some(eod))`
  - `Upcoming(eod)` → `Range(eod, None)`
- **TimeShapeFilter**：与 TimeFilter 正交的"时间形态"维度。TimeFilter 过滤"时间范围在哪"，TimeShapeFilter 过滤"时间字段的 NULL 形态"。`BoundedOnly`（start_at + end_at 都非 NULL）用于 Calendar 主网格——只有完整时间块才能画成日程条。
- **StatusFilter**：`ActiveOnly` 覆盖主流场景，`TaskStatuses(Vec)` 支持精确状态查询（如"只看 Done"）。
- **view_hint**：过滤 ≠ 推导，不违反 S1 R3。支持"文件夹内只看 Task 类型"等 UI 操作。
- **SortSpec**：显式排序，不藏在 TimeFilter 的隐式规则里。
- **include_path**：所有投影模式均可使用（见契约表）。`Atom + include_path=true` 返回 representative ref 的非稳定路径，适用于 tag 搜索等需要去重 + 面包屑提示的场景。
- **text_query**：FTS5 全文搜索过滤。与 tag/time/status 等过滤正交，AND 连接。用于 Single Entry 搜索统一到 ScopedAtomQuery 管线，获得与所有查询一致的子树范围和面包屑路径支持。
- **designated(role) 解析**：Service 层查 `designated_folders` 表获取 folder_id，Repo 只认 folder_id，不认 role。

#### Q1.2 SQL 组合策略 — RESOLVED

**裁决**：采用固定 CTE 管线 + 双投影模型。

##### 双投影模型

同一 atom 可有多个 atom_ref（S1 R7），同一 subtree 内可能出现重复。两种消费模式需要不同处理：

```rust
pub enum ProjectionMode {
    /// 智能视图消费（Tasks/Calendar）：按 atom 去重，每个 atom 只出现一次
    Atom,
    /// 树导航消费（Explorer/Tag）：按 ref，每个 atom_ref 独立条目，含路径
    Ref,
}
```

- `Atom`：去重规则 `ROW_NUMBER() OVER (PARTITION BY atom_uuid ORDER BY depth ASC, node_uuid ASC)` 取 `rn = 1`，最浅深度的 ref 为代表，UUID 保证确定性。**`representative_node_uuid` 在 Atom 投影下是非稳定提示字段**——用户移动节点后代表 ref 可能切换，消费者不应依赖其稳定性作为业务主键。需要操作具体 ref 时（如"从视图移除"），应走 Ref 投影。
- `Ref`：不去重，每个 atom_ref 独立返回，`include_path = true` 时附带路径

查询入口签名：`query_scoped_atoms(query: ScopedAtomQuery, projection: ProjectionMode)`

##### 输出契约表

| ProjectionMode | include_path | representative_node_uuid | path | 合法性 |
|----------------|-------------|--------------------------|------|--------|
| Atom | false | 非稳定提示 | None | ✓ |
| Atom | true | 非稳定提示 | Some（非稳定代表路径） | ✓ |
| Ref | false | 稳定 | None | ✓ |
| Ref | true | 稳定 | Some | ✓ |

所有 4 种组合均合法。

约束规则：
- `Atom + include_path=true`：路径取自 representative ref（去重后的最浅深度 ref），**非稳定**——用户移动节点后代表 ref 可能切换，路径随之变化。适用场景：Tag 搜索结果展示面包屑（需要去重 + 需要路径提示），消费者不应将此路径作为可靠定位依据
- `Ref + include_path=true`：路径稳定，每个 atom_ref 独立返回其完整路径
- `representative_node_uuid` 在 Atom 投影下为非稳定提示——用户移动节点后代表 ref 可能切换，消费者不应依赖其稳定性作为业务主键。需要操作具体 ref 时（如"从视图移除"），应走 Ref 投影

##### CTE 管线（3-4 段）

```sql
-- 第 1 段：scope（递归 CTE 遍历子树，收集 atom_ref）
-- 输出列结构：(node_uuid, atom_uuid, depth [, path])
WITH scope_refs AS (
  WITH RECURSIVE subtree AS (
    SELECT node_uuid, 0 AS depth, CAST(display_name AS TEXT) AS path
    FROM workspace_nodes
    WHERE node_uuid = ?folder_id AND is_deleted = 0
    UNION ALL
    SELECT wn.node_uuid, s.depth + 1, s.path || '/' || wn.display_name
    FROM workspace_nodes wn
    JOIN subtree s ON wn.parent_uuid = s.node_uuid
    WHERE wn.is_deleted = 0
  )
  SELECT wn.node_uuid, wn.atom_uuid, st.depth, st.path
  FROM subtree st
  JOIN workspace_nodes wn ON wn.node_uuid = st.node_uuid
    AND wn.kind = 'atom_ref' AND wn.is_deleted = 0
),

-- 第 2 段：filter（语义过滤）
-- JOIN atoms + 所有 WHERE 条件（time/shape/status/view_hint/tag）
filtered AS (
  SELECT sr.node_uuid, sr.depth, sr.path, a.*
  FROM scope_refs sr
  JOIN atoms a ON a.uuid = sr.atom_uuid
  -- 条件按参数动态拼接（白名单编译，不允许业务词）
  -- 精确 SQL 条件见下方"Filter SQL 真值规则表"
  WHERE a.is_deleted = 0
    AND (... TimeFilter 条件 ...)
    AND (... TimeShapeFilter 条件 ...)
    AND (... StatusFilter 条件 ...)
    AND (... view_hint 条件 ...)
    -- tag 过滤时追加 EXISTS subquery
    -- text_query 过滤时追加 IN (SELECT uuid FROM atoms_fts WHERE atoms_fts MATCH ?q)
),

-- 第 3 段：dedup（仅 Atom 投影时）
-- Ref 投影跳过此段
deduped AS (
  -- Atom 模式：
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY uuid ORDER BY depth ASC, node_uuid ASC
  ) AS rn
  FROM filtered

  -- Ref 模式：直接透传
  -- SELECT *, 1 AS rn FROM filtered
),

-- 第 4 段：sort + page
SELECT ... FROM deduped
WHERE rn = 1  -- Atom 模式；Ref 模式无此条件
ORDER BY ...  -- SortSpec 决定
LIMIT ? OFFSET ?
```

**设计要点**：

- **include_path 隔离**：`include_path = false` 时，CTE 中省略 path 拼接列（用 `NULL AS path`），避免无用字符串拼接开销。`include_path = true` 时所有投影模式均拼接路径——Atom 投影取 representative ref 的路径（非稳定），Ref 投影取各 ref 自身路径（稳定）
- **filter 阶段白名单**：只认 Repo 层原语（TimeFilter/StatusFilter 等），不允许 Today/Upcoming 等业务词进入 SQL
- **tag 过滤用 EXISTS**：避免 JOIN 导致的行重复，`WHERE EXISTS (SELECT 1 FROM atom_tags at JOIN tags t ON t.id = at.tag_id WHERE at.atom_uuid = a.uuid AND t.name = ?tag)`
- **offset 分页**：v0.4 采用 offset，keyset pagination 记为未来升级路径

##### Filter SQL 真值规则表

Atom 时间矩阵有 4 种 NULL 组合（时间形态）：

| 形态 | start_at | end_at | 语义 |
|------|----------|--------|------|
| T0 | NULL | NULL | Timeless（无时间维度） |
| T1 | NULL | VAL | Deadline（截止日期） |
| T2 | VAL | NULL | Ongoing（开始日期） |
| T3 | VAL | VAL | TimeBlock（时间块） |

**TimeFilter 单独的 SQL 条件与形态匹配**：

| 变体 | SQL 条件 | T0 | T1 | T2 | T3 |
|------|---------|----|----|----|----|
| `Any` | （无条件） | ✓ | ✓ | ✓ | ✓ |
| `Timeless` | `a.start_at IS NULL AND a.end_at IS NULL` | ✓ | | | |
| `Range(s, Some(e))` | 按形态分支（见下） | | ✓* | ✓* | ✓* |
| `Range(s, None)` | 按形态分支（见下） | | ✓* | ✓* | ✓* |

**重要**：`Range(s, Some(e))` 和 `Range(s, None)` 使用**不同的语义模型**：

- `Range(s, Some(e))`：**区间 overlap** — atom 的有效时间区间与 [s, e) 有交集
- `Range(s, None)`：**锚点前移** — atom 的主时间锚点 ≥ s（尚未开始/到期）

原因：Upcoming(eod) 不是"与 [eod, +∞) 有交集"。一个昨天开始的 ongoing task (T2) 与 [eod, +∞) 有交集，但它属于 Today 不属于 Upcoming。Upcoming 的语义是"尚未开始/到期的未来事项"，需要锚点前移模型。

**`Range(s, Some(e))` — 区间 overlap 语义**：

每个形态建模为有效时间区间，检查与 [s, e) 的交集：

| 形态 | 有效区间 | overlap 条件 | SQL |
|------|---------|-------------|-----|
| T1 (-∞, end_at] | `end_at >= s` | `a.start_at IS NULL AND a.end_at IS NOT NULL AND a.end_at >= ?s` |
| T2 [start_at, +∞) | `start_at < e` | `a.start_at IS NOT NULL AND a.end_at IS NULL AND a.start_at < ?e` |
| T3 [start_at, end_at] | `start_at < e AND end_at >= s` | `a.start_at IS NOT NULL AND a.end_at IS NOT NULL AND a.start_at < ?e AND a.end_at >= ?s` |

组合 SQL（per-forma OR）：
```sql
NOT (a.start_at IS NULL AND a.end_at IS NULL)           -- 排除 T0
AND (
  (a.start_at IS NULL AND a.end_at >= ?s)               -- T1: deadline overlap
  OR (a.end_at IS NULL AND a.start_at < ?e)             -- T2: ongoing overlap
  OR (a.start_at < ?e AND a.end_at >= ?s)               -- T3: bounded overlap
)
```

**`Range(s, None)` — 锚点前移语义**：

每个形态的主时间锚点 ≥ s（"从 s 起的未来事项"）：

| 形态 | 主锚点 | 条件 | SQL |
|------|-------|------|-----|
| T1 | end_at（截止日期） | `end_at >= s` | `a.start_at IS NULL AND a.end_at IS NOT NULL AND a.end_at >= ?s` |
| T2 | start_at（开始日期） | `start_at >= s` | `a.start_at IS NOT NULL AND a.end_at IS NULL AND a.start_at >= ?s` |
| T3 | start_at（开始日期） | `start_at >= s` | `a.start_at IS NOT NULL AND a.end_at IS NOT NULL AND a.start_at >= ?s` |

组合 SQL（per-forma OR）：
```sql
NOT (a.start_at IS NULL AND a.end_at IS NULL)           -- 排除 T0
AND (
  (a.start_at IS NULL AND a.end_at >= ?s)               -- T1: deadline >= s
  OR (a.start_at >= ?s)                                  -- T2+T3: starts >= s
)
```

##### Service 层映射测试矩阵

以下验证 Today/Upcoming 的 Service 层参数转换是否产生正确结果。

**Today = `Range(bod, Some(eod))`**（区间 overlap）：

| 形态 | 测试用例 | 匹配？ | 说明 |
|------|---------|--------|------|
| T1 | end_at = eod - 1（今天到期） | ✓ `end_at >= bod` | 今天的 deadline |
| T1 | end_at = bod - 1（昨天到期） | ✗ `end_at < bod` | **overdue 未捕获** — Service 需补偿 |
| T1 | end_at = eod + 1（明天到期） | ✓ `end_at >= bod` | 明天 deadline 但 (-∞, end_at] overlap today |
| T2 | start_at = bod - 100（早已开始） | ✓ `start_at < eod` | 进行中任务 |
| T2 | start_at = eod + 1（明天开始） | ✗ `start_at >= eod` | 未来任务 |
| T3 | [bod-1h, eod+1h]（跨今天） | ✓ overlap | |
| T3 | [eod+1, eod+2]（明天） | ✗ `start_at >= eod` | |

**Upcoming = `Range(eod, None)`**（锚点前移）：

| 形态 | 测试用例 | 匹配？ | 说明 |
|------|---------|--------|------|
| T1 | end_at = eod + 1（明天到期） | ✓ `end_at >= eod` | |
| T1 | end_at = eod - 1（今天/过期） | ✗ `end_at < eod` | |
| T2 | start_at = eod + 1（明天开始） | ✓ `start_at >= eod` | |
| T2 | start_at = bod - 100（早已开始） | ✗ `start_at < eod` | 进行中 → Today，不是 Upcoming |
| T3 | [eod+1, eod+10]（明天起） | ✓ `start_at >= eod` | |
| T3 | [bod-1h, eod+1h]（跨今天） | ✗ `start_at < eod` | overlap today → Today |

**Service 层 overdue 补偿**（Today T1 gap）：

Range(bod, eod) 的 overlap 模型会漏掉 T1 overdue 项（deadline < bod）。Time-Matrix 要求"Today if overdue/today"。

**已裁决（Q1.4）**：采用方案 B（双查询合并）。主查询 `Range(bod, eod)` + 补查询 `query_overdue_deadlines(folder_id, bod)` + Service 层合并去重。方案 A（`Range(0, eod)` 扩大左边界）因会把未来 deadline 拉入 Today 而否决。详见 Q1.4。

**TimeShapeFilter 单独的 SQL 条件**：

| 变体 | SQL 条件 | T0 | T1 | T2 | T3 |
|------|---------|----|----|----|----|
| `Any` | （无条件） | ✓ | ✓ | ✓ | ✓ |
| `BoundedOnly` | `a.start_at IS NOT NULL AND a.end_at IS NOT NULL` | | | | ✓ |

**TimeFilter × TimeShapeFilter 组合矩阵**：

组合优先级：两个条件 AND 连接，结果为交集。BoundedOnly 额外约束 `start_at IS NOT NULL AND end_at IS NOT NULL`，实际上只保留 T3。

| TimeFilter \ TimeShapeFilter | Any | BoundedOnly |
|------------------------------|-----|-------------|
| `Any` | T0+T1+T2+T3 | T3 |
| `Timeless` | T0 | **空集**（矛盾：Timeless 要求全 NULL，BoundedOnly 要求全非 NULL） |
| `Range(s, Some(e))` overlap | T1*+T2*+T3* | T3*（`start_at < e AND end_at >= s`） |
| `Range(s, None)` 锚点 | T1*+T2*+T3* | T3*（`start_at >= s`） |

`Timeless + BoundedOnly` 组合逻辑上矛盾，返回空结果（不报错，合法但无结果）。
`Range + BoundedOnly` 组合自然退化为只查 T3，因为 BoundedOnly 排除了 T1/T2。

**StatusFilter SQL 条件**：

| 变体 | SQL 条件 |
|------|---------|
| `Any` | （无条件） |
| `ActiveOnly` | `(a.task_status NOT IN ('done','cancelled') OR a.task_status IS NULL)` |
| `TaskStatuses(vec)` | `a.task_status IN (?, ?, ...)` |

**其他 Filter SQL 条件**：

| Filter | SQL 条件 |
|--------|---------|
| `view_hint = Some(h)` | `a.view_hint = ?h` |
| `view_hint = None` | （无条件） |
| `tag = Some(t)` | `EXISTS (SELECT 1 FROM atom_tags at JOIN tags t ON t.id = at.tag_id WHERE at.atom_uuid = a.uuid AND t.name = ?t)` |
| `tag = None` | （无条件） |
| `text_query = Some(q)` | `a.uuid IN (SELECT uuid FROM atoms_fts WHERE atoms_fts MATCH ?q)` |
| `text_query = None` | （无条件） |

##### 索引配套（A8 已定义 + 补充）

```sql
-- A8 已定义
CREATE INDEX idx_wn_parent_deleted_kind ON workspace_nodes(parent_uuid, is_deleted, kind);
CREATE INDEX idx_wn_atom_deleted ON workspace_nodes(atom_uuid, is_deleted);

-- Q1.2 补充
CREATE INDEX idx_atoms_deleted_status ON atoms(is_deleted, task_status);
CREATE INDEX idx_atom_tags_atom ON atom_tags(atom_uuid);
```

atoms 不建全覆盖复合索引——按实际查询模式建窄索引，写入成本低，v0.4 足够。

**时间列索引暂不添加的理由**：`FolderSubtree` 查询路径是 CTE 先收窄到子树（designated folder 下通常几十到几百个 atom_ref），再 JOIN atoms 过滤。此规模下 atoms 表的时间列扫描开销极低，索引无实际收益。且 Range overlap 的 OR IS NULL 模式不利于 B-tree 索引命中。如 profiling 证明 atoms 过滤成为瓶颈（数千+ atom_ref 子树），再补 `idx_atoms_deleted_start(is_deleted, start_at)` 和 `idx_atoms_deleted_end(is_deleted, end_at)`。

##### Global 分层归属

产品层（FFI/UI）不暴露 Global scope。理由：

1. **加密边界**：v1.x per-workspace AES-256 加密下，跨 workspace 查询需逐个解密授权，"Global"语义不确定（取决于当前解锁状态）
2. **查询边界 = 加密边界**：ScopedAtomQuery 始终 scoped to 一个 folder，天然对齐 workspace 隔离
3. **"全 workspace"** = `folder_id = workspace_root`，递归 CTE 遍历整棵树

Global 的残留价值分层处理：
- **元数据级 global**（巡检、统计、迁移）：不碰 content，不解密 → 内部 `InternalGlobal` + capability gate
- **系统能力 global**（重建索引、批处理）：admin/internal 路径 → `debug_*`/`experimental_*` FFI 前缀（Architecture Rule B）
- **跨 workspace 聚合**：未来显式 `WorkspaceSet{ids}` 专用路径，调用方声明已解锁的 workspace 集合

#### Q1.3 repo 层归属 — RESOLVED

**裁决**：四仓重构（A+ 方案）。

##### 重构后 repo 层边界

| Repository | 职责 | 操作的表 |
|------------|------|---------|
| `AtomRepository` | 单 atom 写路径：CRUD / status update / time update + atom-tag 关系写入 | `atoms`, `atom_tags`, `tags` |
| `ScopedQueryRepository`（新建） | Q1.2 统一读查询：CTE 管线 + filter + 双投影 | `workspace_nodes` + `atoms`（只读 JOIN） |
| `TreeRepository` | workspace_nodes 结构操作：create / move / rename / delete / list_children | `workspace_nodes` |
| `WorkspaceMetaRepository`（新建） | workspace 元数据 + designated folder 解析/重指定 | `workspaces`, `designated_folders` |

##### 变更说明

1. **AtomRepository 瘦身**：移除 `fetch_inbox` / `fetch_today` / `fetch_upcoming` / `fetch_by_time_range` 等 section queries，这些被 `ScopedQueryRepository` 取代。合并 `NoteRepository` 的 atom 级能力（tag 操作）。

2. **ScopedQueryRepository 新建**：唯一入口 `query_scoped_atoms(query, projection)`。跨 `workspace_nodes` + `atoms` 两表的只读查询，不属于任何现有 repo 的职责边界。

3. **TreeRepository 保持纯拓扑**：只管 parent-child 结构操作，不涉及 workspace/designated folder 语义层。

4. **WorkspaceMetaRepository 新建**：`resolve_designated(workspace_id, role) -> Option<WorkspaceNodeId>` 和 `reassign_designated(workspace_id, role, new_node_uuid)` 等。语义上属于 workspace 元数据，不是树拓扑。与 TreeRepository 分离。

5. **NoteRepository 兼容壳过渡**：v0.4 初期保留为兼容壳，内部委托给 `AtomRepository`。等 Q1.4 / Q6 稳定、上层调用方迁移完成后再删除，降低回归风险。

##### 依赖关系

```
Service 层
├── TaskService / CalendarService → ScopedQueryRepository + WorkspaceMetaRepository
├── CreationService → AtomRepository + TreeRepository + WorkspaceMetaRepository
├── TreeService → TreeRepository
└── NoteService → AtomRepository（兼容期通过 NoteRepository 壳）

ScopedQueryRepository（只读，不依赖其他 repo）
WorkspaceMetaRepository（只读/写 workspaces + designated_folders）
AtomRepository（写 atoms + tags）
TreeRepository（写 workspace_nodes）
```

#### Q1.4 service 层影响 — RESOLVED

**裁决**：方案 A — 保留业务域 Service，内部委托 ScopedQueryRepository。

##### 重构后 service 层

| Service | 职责 | 依赖的 repo |
|---------|------|------------|
| `TaskService`（瘦身） | Tasks 视图查询（inbox/today/upcoming）+ status update | ScopedQueryRepository, WorkspaceMetaRepository, AtomRepository |
| `CalendarService`（新建或拆出） | Calendar 视图查询（range/pending） | ScopedQueryRepository, WorkspaceMetaRepository |
| `TreeService` | 树结构操作（move/rename/delete）+ 保护校验 | TreeRepository |
| `CreationService` | 统一 atom 创建 + atom_ref 路由到 designated folder | AtomRepository, TreeRepository, WorkspaceMetaRepository |
| `NoteService`（兼容壳） | 过渡期委托给 AtomRepository，稳定后删除 | AtomRepository |

##### 业务域 Service 的三段职责

每个视图查询方法做三件事：

1. **解析**：调 WorkspaceMetaRepository 获取 designated folder 的 folder_id
2. **翻译**：将业务概念（Today/Upcoming/Inbox）转换为 ScopedAtomQuery 参数
3. **执行**：调 ScopedQueryRepository 查询

```rust
// TaskService 方法签名示例

impl<S: ScopedQueryRepository, W: WorkspaceMetaRepository, A: AtomRepository> TaskService<S, W, A> {

    /// Inbox = designated('tasks') 子树中无时间维度的活跃 atom
    pub fn list_inbox(&self, workspace_id: &str, limit: u32, offset: u32)
        -> Result<Vec<ScopedAtomResult>>
    {
        let folder_id = self.workspace_meta.resolve_designated(workspace_id, "tasks")?;
        let query = ScopedAtomQuery {
            folder_id,
            time_filter: TimeFilter::Timeless,
            status_filter: StatusFilter::ActiveOnly,
            sort: SortSpec::UpdatedAtDesc,
            limit,
            offset,
            ..Default::default()
        };
        self.scoped_query.query_scoped_atoms(query, ProjectionMode::Atom)
    }

    /// Today = designated('tasks') 子树中与 [bod, eod) overlap 的活跃 atom
    ///       + overdue T1（通过 include_overdue_deadlines 由 Repository 内部处理）
    pub fn list_today(&self, workspace_id: &str, bod_ms: i64, eod_ms: i64, limit: u32, offset: u32)
        -> Result<Vec<ScopedAtomResult>>
    {
        let folder_id = self.workspace_meta.resolve_designated(workspace_id, "tasks")?;
        let query = ScopedAtomQuery {
            folder_id,
            time_filter: TimeFilter::Range { start_ms: bod_ms, end_ms: Some(eod_ms) },
            status_filter: StatusFilter::ActiveOnly,
            sort: SortSpec::StartAtAsc,
            include_overdue_deadlines: true,  // Repository 内部 UNION overdue T1 并去重
            limit,
            offset,
            ..Default::default()
        };
        self.scoped_query.query_scoped_atoms(query, ProjectionMode::Atom)
    }

    /// Upcoming = designated('tasks') 子树中主锚点 >= eod 的活跃 atom
    pub fn list_upcoming(&self, workspace_id: &str, eod_ms: i64, limit: u32, offset: u32)
        -> Result<Vec<ScopedAtomResult>>
    {
        let folder_id = self.workspace_meta.resolve_designated(workspace_id, "tasks")?;
        let query = ScopedAtomQuery {
            folder_id,
            time_filter: TimeFilter::Range { start_ms: eod_ms, end_ms: None },
            status_filter: StatusFilter::ActiveOnly,
            sort: SortSpec::StartAtAsc,
            limit,
            offset,
            ..Default::default()
        };
        self.scoped_query.query_scoped_atoms(query, ProjectionMode::Atom)
    }

    /// Status update 保留在 TaskService（写路径委托 AtomRepository）
    pub fn update_status(&self, atom_id: &str, status: Option<TaskStatus>)
        -> Result<()>
    {
        self.atom_repo.update_status(atom_id, status)
    }
}
```

##### Today overdue 补偿

Q1.2 测试矩阵揭示 `Range(bod, eod)` 的 overlap 模型会漏掉 T1 overdue 项（deadline < bod）。

**裁决**：overdue 补偿下沉到 ScopedQueryRepository，通过 `include_overdue_deadlines: bool` 参数控制。

**为什么下沉到 Repository 而非留在 Service**（Q6.1 裁决后回溯更新）：
- Q6.1 消除了所有分立查询 FFI，所有查询走单一 `query_atoms`
- 如果 overdue 补偿留在 Service 层，FFI 适配器需要判断"这是不是 Today 查询"然后走不同 Service——本质又变成分立入口
- 下沉到 Repository 后，`include_overdue_deadlines` 作为查询参数在通用管线内自然组合

**Repository 内部实现**：当 `include_overdue_deadlines = true` 且 `time_filter = Range(s, Some(e))` 时，CTE 管线在 filter 段之后 UNION overdue T1 子查询，然后统一进入 dedup 段：

```sql
-- 主查询 filtered CTE 正常输出 ...

-- overdue 补充（仅 include_overdue_deadlines = true 时拼接）
UNION ALL
SELECT sr.node_uuid, sr.depth, sr.path, a.*
FROM scope_refs sr
JOIN atoms a ON a.uuid = sr.atom_uuid
WHERE a.is_deleted = 0
  AND a.start_at IS NULL AND a.end_at IS NOT NULL  -- T1 形态
  AND a.end_at < ?start_ms                          -- overdue（deadline < Range 起点）
  AND (a.task_status NOT IN ('done','cancelled') OR a.task_status IS NULL)
```

UNION ALL 后统一进入 dedup 段（ROW_NUMBER 去重），分页在最外层 LIMIT/OFFSET 处理。不需要 Service 侧 HashSet 去重和手动分页截取。

**为什么不用方案 A（扩大左边界 `Range(0, eod)`）**：`Range(0, eod)` overlap 下 T1 条件为 `end_at >= 0`，会把明天/未来到期的 deadline 也拉入 Today，破坏 Today/Upcoming 分区。

**`include_overdue_deadlines` 的校验规则**（C2）：
- `include_overdue_deadlines = true` 仅在 `time_filter = Range(s, Some(e))` 时合法
- 与 `Timeless` / `Any` / `Range(s, None)` 组合返回 `invalid_query_descriptor`

##### 设计要点

- **业务语义不泄漏**：Today/Upcoming/Inbox 的定义（包括 overdue 规则）封装在 Service 层，FFI/Flutter 不感知
- **designated folder 解析集中**：每个 Service 方法首先解析 designated folder，这是协调职责
- **Service 瘦而不空**：翻译 + 协调 + 补偿是 Service 的核心价值，不是纯透传
- **泛型可测**：Service 对 repo 依赖通过泛型注入，可在测试中 mock

---

### Q2. 树导航专用方法 — RESOLVED

**背景**：A4 确认两种消费模式。智能视图走 Q1 统一查询，树导航走专用方法。

**已确认方向**：

1. **`list_subtree_atom_refs`**（Explorer / Tag 过滤用）：

   返回类型：
   ```rust
   pub struct SubtreeAtomRef {
       pub node_uuid: WorkspaceNodeId,
       pub atom_uuid: AtomId,
       pub display_name: String,
       pub path: String,              // CTE 递归下降时拼接，纯展示
   }
   ```

   - 不含 atom 领域字段（view_hint、task_status、start_at 等）
   - 路径为字符串，SQL CTE 下降时免费积累
   - 消费者：Tag Explorer、文件夹内容概览

2. **`get_ancestor_path(node_uuid: WorkspaceNodeId)`**（Editor 面包屑用）：

   返回类型：`Vec<(WorkspaceNodeId, String)>`，结构化路径（root → target 方向），支持点击导航。

   - **输入是 `node_uuid`（具体 workspace_node），不是 `atom_uuid`**。同一 atom 有多个 ref 时，atom_uuid 无法确定唯一路径。消费者（Editor 面包屑）已持有当前打开的 node_uuid
   - 唯一消费者：Editor 区域面包屑，只为当前打开的 1 个 atom 服务
   - 按需调用，不做批量

**已裁决子项**：

3. **`list_atom_refs_for_atom`** — RESOLVED

   返回类型：
   ```rust
   pub struct AtomRefLocation {
       pub node_uuid: WorkspaceNodeId,
       pub workspace_id: String,         // 所属 workspace
       pub path: String,                 // 从 workspace root 到该 ref 的路径
       pub display_name: String,
   }
   ```

   - 包含路径——消费者（Editor 侧边栏"引用位置"）需要展示"这个 atom 出现在哪"
   - 包含 workspace_id——多 workspace 时需要知道引用在哪个 workspace
   - 不含 atom 内容字段（调用方已有 atom 本体）
   - SQL：先查 `workspace_nodes WHERE atom_uuid = ? AND kind = 'atom_ref'`，每个结果向上 CTE 拼路径。量小（一个 atom 通常 1-3 个 ref），逐条上溯可接受

4. **trait 组织** — RESOLVED

   三个方法都是 workspace_nodes 表的只读查询，全部归入 **TreeRepository trait**：

   | 方法 | 归属理由 |
   |------|---------|
   | `list_subtree_atom_refs` | 遍历子树收集 atom_ref — 纯树操作 |
   | `get_ancestor_path` | 向上遍历祖先 — 纯树操作 |
   | `list_atom_refs_for_atom` | 按 atom_uuid 查树节点位置 — 操作对象是 workspace_nodes |

   不需要新建 TreeQueryRepository。TreeRepository 本身负责树结构的读和写，这些只读查询是自然扩展。

---

### Q3. 统一创建入口 — RESOLVED

**背景**：A12 确定了统一创建方向。本 Q 裁决具体接口设计。

#### Q3.1 CreateAtomRequest 结构体 — RESOLVED

```rust
pub struct CreateAtomRequest {
    pub workspace_id: WorkspaceId,               // 必传，多 workspace 支持
    pub content: String,
    pub content_type: String,                     // 默认 "markdown"，v0.4 白名单校验
    pub task_status: Option<TaskStatus>,          // 设了 → view_hint 推导为 Task
    pub start_at: Option<i64>,                    // 时间属性
    pub end_at: Option<i64>,
    pub tags: Option<Vec<String>>,                // 可选，创建时原子绑定 tag
    pub target_folder: Option<WorkspaceNodeId>,   // 显式路由目标；None → 按属性推导 designated folder
    pub display_name: Option<String>,             // atom_ref 展示名；None → derive_title 推导
}
```

**设计要点**：

- **workspace_id 必传**：多 workspace 场景下调用方必须指定目标 workspace。v0.4 单 workspace 时 Flutter 层传 default workspace
- **content_type 暴露但校验**：v0.4 白名单仅接受 `"markdown"`，不认识的格式返回错误。暴露的好处是 API 形状稳定——未来支持新格式只需放宽校验，不需变更 FFI 签名
- **tags 原子绑定**：create + tag 在同一事务中完成，避免"atom 创建成功但 set_tags 失败"的中间态。`None` 或空 vec 时跳过
- **display_name**：作用于 atom_ref 节点（`workspace_nodes.display_name`），不是 atom 本体。右键菜单 rename 独立于 markdown content，因此需要暴露为可选字段。`None` 时走 `derive_title` 从 content 第一行推导
- **view_hint 不作为输入**：由 S1 R3 内部推导（task_status 优先规则），调用方不感知
- **origin_workspace_id**：由 CreationService 自动填入 `workspace_id`（DI-15 Q10）

#### Q3.2 路由实现 — RESOLVED

**裁决**：纯函数提取，不引入独立 struct/trait。

```rust
/// 根据 request 属性推导目标 designated folder role
fn resolve_creation_role(request: &CreateAtomRequest) -> &str {
    if request.task_status.is_some() { "tasks" }
    else if request.start_at.is_some() || request.end_at.is_some() { "calendar" }
    else { "inbox" }
}
```

CreationService 的创建流程（4 步）：

1. **校验**：content_type 白名单、`end_at >= start_at`（当两者都存在时）
2. **推导 view_hint**：按 S1 R3 规则（task_status 优先）
3. **路由 + 边界校验**：
   - `target_folder.unwrap_or_else(|| resolve_designated(workspace_id, resolve_creation_role(&request)))`
   - **跨 workspace 防护**：校验解析后的 target_folder 属于 `workspace_id` 的树。向上遍历 target_folder 祖先链，确认根节点是 `workspace_id` 对应的 workspace root。校验失败返回 `target_folder_not_in_workspace` 错误（需注册到 `error-codes.md`）
4. **事务内执行**：insert atom（含 `origin_workspace_id = workspace_id`，一次性写入） → create atom_ref（display_name 取 `request.display_name` 或 `derive_title(content)`） → set_tags（if any）

**设计要点**：

- `resolve_creation_role` 是纯函数，路由规则变更只改这一个函数，不影响 CreationService 的事务/校验逻辑
- `target_folder` 显式指定时跳过路由推导——对应 DI-12 Q6 路由优先级"显式目标 > 意图上下文 > Inbox"
- 路由解析依赖 `WorkspaceMetaRepository::resolve_designated`，与 Q1.4 的 Service 三段模式一致

#### Q3.3 现有方法迁移 — RESOLVED

**裁决**：v0.4 内同版本全量迁移，按 PR 分批：

| PR | 内容 | 依赖 |
|----|------|------|
| PR-A | Core 层 `CreationService::create_atom` + 新 FFI `atom_create` | — |
| PR-B | Flutter 层所有调用方迁移到 `atom_create` | PR-A |
| PR-C | 移除旧 FFI（`entry_create_task` / `note_create` / `entry_create_note`）+ 移除旧 Core 方法 | PR-B |

不保留 deprecated 包装。三个 PR 在 v0.4 内合入完成。

---

### Q4. TreeService 演进 — RESOLVED

**背景**：Q1 统一查询接管了大部分读路径。TreeService 主要负责树结构写操作和验证。

#### Q4.1 workspace root 和 designated folder 保护 — RESOLVED

**现状**：当前 `TreeService::delete_folder` 和 `move_node` 没有 workspace root / designated folder 前置检查，完全依赖 DB 触发器（DI-15 Q9.1 + Q12）。

**裁决**：Service 层加前置检查，DB 触发器保留为兜底防线。

**理由**：
- DB 触发器报错是 `TreeRepoError::Repo(rusqlite::Error)` — 错误信息是 SQLite 的 `RAISE(ABORT, '...')`，不友好且难以在 FFI 层映射为结构化错误码
- 前置检查可以返回语义清晰的 `TreeServiceError` 变体，FFI 层直接映射为结构化错误码

**保护规则**：

| 操作 | workspace root | designated folder | 普通节点 |
|------|---------------|-------------------|---------|
| `delete_folder` | 拦截 → `WorkspaceRootProtected` | 拦截 → `DesignatedFolderProtected`（需先 reassign） | 放行 |
| `move_node` | 拦截 → `CannotMoveWorkspaceRoot` | 放行（同 workspace 内移动，只改位置不改映射） | 放行（同 workspace 内） |
| `move_node` 跨 workspace | 拦截 → `CrossWorkspaceMoveNotAllowed` | 拦截 → `CrossWorkspaceMoveNotAllowed` | 拦截 → `CrossWorkspaceMoveNotAllowed` |
| `move_node` parent=None | 拦截 → `CannotMoveToRoot` | 拦截 → `CannotMoveToRoot` | 拦截 → `CannotMoveToRoot` |

**move_node 硬约束**（v0.4）：

1. **禁止 parent=None**：`parent_uuid = NULL` 只有 workspace root 节点才合法。普通节点移到 None 会脱离所有 workspace 树，成为悬挂子树——ScopedAtomQuery 的 CTE 从 workspace root 出发永远遍历不到它。`new_parent_uuid` 对非 workspace root 节点必须为 `Some`
2. **禁止跨 workspace 移动**：校验目标 parent 与被移动节点属于同一 workspace root（向上遍历祖先链确认）。跨 workspace 会导致 `designated_folders(workspace_id, role → node_uuid)` 映射与实际树归属漂移。未来跨 workspace 需求走专用 transfer/copy API，不走普通 move

**新增 `TreeServiceError` 变体**：

```rust
/// Cannot delete workspace root node.
WorkspaceRootProtected(WorkspaceNodeId),
/// Cannot delete a designated folder (must reassign first).
DesignatedFolderProtected(WorkspaceNodeId),
/// Cannot move workspace root node.
CannotMoveWorkspaceRoot(WorkspaceNodeId),
/// Cannot move node to parent=None (only workspace root may have NULL parent).
CannotMoveToRoot(WorkspaceNodeId),
/// Cannot move node across workspace boundaries (v0.4).
CrossWorkspaceMoveNotAllowed { node_uuid: WorkspaceNodeId, target_parent: WorkspaceNodeId },
```

**检查实现**：
- workspace root 判断：`get_node(node_uuid).kind == WorkspaceNodeKind::Workspace`（纯拓扑，走 TreeRepository）
- 跨 workspace 判断：分别向上遍历被移动节点和目标 parent 的祖先链，确认两者的 workspace root 相同
- designated folder 判断：`WorkspaceMetaRepository::is_designated(node_uuid) -> bool`（语义层查询，走 WorkspaceMetaRepository）

#### Q4.2 designated folder 解析归属 — RESOLVED

**裁决**：`resolve_designated` 归入 `WorkspaceMetaRepository`（Q1.3 已裁决），TreeService 通过依赖 `WorkspaceMetaRepository` 完成保护检查。

**归属理由**：保护检查是语义层操作（"这个 folder 是否承载 designated 角色"），不是纯拓扑操作。TreeService 需要知道 designated 状态，应依赖 `WorkspaceMetaRepository` 而非自行查表。

**WorkspaceMetaRepository 提供的保护相关方法**：

```rust
/// 检查某节点是否被任何 designated_folders 记录引用
fn is_designated(&self, node_uuid: WorkspaceNodeId) -> Result<bool>;

/// 解析指定 workspace 和 role 对应的 designated folder
fn resolve_designated(&self, workspace_id: &str, role: &str) -> Result<Option<WorkspaceNodeId>>;

/// 将 role 重指定到另一个 folder
fn reassign_designated(&self, workspace_id: &str, role: &str, new_node_uuid: WorkspaceNodeId) -> Result<()>;
```

**缓存策略**：按需查询，不缓存。理由：
- designated folder 很少变更（只在 reassign 时）
- `designated_folders` 表行数 = workspace 数 × role 数（当前 3 个 role），查询是主键精确匹配，毫秒级
- 缓存引入失效管理复杂度，收益不足

#### Q4.3 泛型约束 — RESOLVED

**裁决**：TreeService 增加 `W: WorkspaceMetaRepository` 泛型参数。

```rust
pub struct TreeService<R: TreeRepository, W: WorkspaceMetaRepository> {
    repo: R,
    workspace_meta: W,
}
```

**设计要点**：
- 统一查询层（ScopedQueryRepository）不引入 TreeService — 统一查询走独立路径，TreeService 只管树结构写操作 + 保护校验
- 依赖关系清晰：TreeService → TreeRepository + WorkspaceMetaRepository，不与 ScopedQueryRepository 交叉

**v0.4 依赖关系总览**（Q1.3 + Q1.4 + Q4.3）：

```
Service 层
├── TaskService<S, W, A>           → ScopedQueryRepository + WorkspaceMetaRepository + AtomRepository
├── CalendarService<S, W>          → ScopedQueryRepository + WorkspaceMetaRepository
├── CreationService<A, R, W>       → AtomRepository + TreeRepository + WorkspaceMetaRepository
├── TreeService<R, W>              → TreeRepository + WorkspaceMetaRepository
└── NoteService<A>                 → AtomRepository（兼容壳，稳定后删除）

Repository 层（互不依赖）
├── AtomRepository                 → atoms, atom_tags, tags
├── ScopedQueryRepository          → workspace_nodes + atoms（只读 JOIN）
├── TreeRepository                 → workspace_nodes
└── WorkspaceMetaRepository        → workspaces, designated_folders
```

#### Q4.4 ancestor_path 签名修正 — RESOLVED

**现状**：当前代码 `TreeService::ancestor_path(&self, atom_uuid: AtomId)` 按 `atom_uuid` 查路径——与 Q2 裁决矛盾（`get_ancestor_path` 应按 `node_uuid` 查，同一 atom 多 ref 时 atom_uuid 无法确定唯一路径）。

**裁决**：v0.4 修正签名：

```rust
// 旧（v0.3）
pub fn ancestor_path(&self, atom_uuid: AtomId) -> Result<Vec<String>, TreeServiceError>

// 新（v0.4）
pub fn get_ancestor_path(&self, node_uuid: WorkspaceNodeId) -> Result<Vec<(WorkspaceNodeId, String)>, TreeServiceError>
```

变更点：
- 输入从 `atom_uuid: AtomId` 改为 `node_uuid: WorkspaceNodeId`
- 返回从 `Vec<String>` 改为 `Vec<(WorkspaceNodeId, String)>`（结构化路径，支持点击导航）
- 方法名对齐 Q2 命名：`ancestor_path` → `get_ancestor_path`
- 旧签名在 Q3.3 迁移 PR-C 中一并移除

---

### Q5. AccessGuard 接口设计 — RESOLVED

DI-14 Q1 裁决所有树访问预留 caller 身份传递能力。DI-15 Q10 引入了 `origin_workspace_id`（v0.x 写入但不消费），本 Q 裁决 v0.4 的访问控制架构。

#### Q5.1 CallerContext 类型 — RESOLVED

**裁决**：选 B — 结构化 CallerContext，最小化字段。

```rust
pub struct CallerContext {
    pub identity: CallerIdentity,
    pub scope_workspace_id: Option<WorkspaceId>,  // 权限范围；None = 未限定
}

pub enum CallerIdentity {
    App,          // Flutter app（v0.4 唯一值）
    // 未来扩展：Cli, Extension(ExtensionId), Test
}
```

**设计要点**：

- `scope_workspace_id` 是调用方声明的**权限范围/会话上下文**，不是业务目标。v0.4 Flutter 传 `Some(default_workspace)`
- `scope_workspace_id: None` 预留给未来 admin/maintenance 场景（如 InternalGlobal 巡检）
- 业务目标 workspace 由各 Service 方法的业务参数传递（如 `request.workspace_id`、方法参数 `workspace_id`）
- **唯一业务真值是 `request.workspace_id`**（或方法参数），不是 `caller.scope_workspace_id`

**"谁在调用"与"要操作哪个 workspace"分离**：

| 概念 | 载体 | 语义 | 谁消费 |
|------|------|------|--------|
| 调用方身份 + 权限范围 | `CallerContext` | "谁在调用，有权访问哪些 workspace" | Guard 层 |
| 操作目标 workspace | `request.workspace_id` / 方法参数 | "这次操作要落在哪个 workspace" | Inner Service |

**硬规则**：
- Guard 只认 `target = request.workspace_id`（业务真值）
- 若 `caller.scope_workspace_id` 存在且不等于 `target`，默认拒绝（除非有显式跨域 capability）
- Inner service 只收业务参数，不收 `CallerContext`

#### Q5.2 Guard 位置 — RESOLVED

**裁决**：选 B — Guarded\*Service 包装层，在 Core 层内部。

**三层架构**：

```
FFI / UI（入口层）
  ↓ 传递 CallerContext + 业务参数
Guarded*Service（访问控制壳）
  ↓ 校验通过后委托，只传业务参数
Inner Service（纯业务逻辑）
```

**Guarded\*Service 实现**：

```rust
pub struct GuardedTreeService<R: TreeRepository, W: WorkspaceMetaRepository> {
    guard: Box<dyn AccessGuard>,
    inner: TreeService<R, W>,
}

impl<R: TreeRepository, W: WorkspaceMetaRepository> GuardedTreeService<R, W> {
    pub fn move_node(
        &self,
        caller: &CallerContext,
        node_uuid: WorkspaceNodeId,
        new_parent_uuid: WorkspaceNodeId,  // Q4 裁决：非 workspace root 必须 Some
        target_order: Option<i64>,
    ) -> Result<(), TreeServiceError> {
        // Guard 层：先解析 target workspace，再校验权限
        let target_workspace = self.inner.resolve_workspace_for_node(&node_uuid)?;
        self.guard.check_write(caller, &target_workspace)?;
        // 委托 inner：纯业务逻辑，不感知 CallerContext
        self.inner.move_node(node_uuid, new_parent_uuid, target_order)
    }
}
```

**设计要点**：

- Inner service 方法签名**不带 `CallerContext` 参数**——纯业务逻辑，不耦合鉴权
- Guarded\*Service 持有 `Box<dyn AccessGuard>`（运行时分发）+ 具体 inner service 实例
- Inner service 不需要抽 trait——wrapper 直接持有具体类型委托
- FFI/UI 层只与 Guarded\*Service 交互，不直接调用 inner service
- 测试分层：业务单测只测 inner service，鉴权单测只测 guard

**适用范围**：所有需要访问控制的 Service 都走 Guarded\* 包装：

| Facade | Inner |
|--------|-------|
| `GuardedTreeService` | `TreeService<R, W>` |
| `GuardedTaskService` | `TaskService<S, W, A>` |
| `GuardedCalendarService` | `CalendarService<S, W>` |
| `GuardedCreationService` | `CreationService<A, R, W>` |
| `GuardedQueryService` | 统一查询入口，委托 ScopedQueryRepository |
| `GuardedAtomService` | 单 atom 读取（`atom_get`） |
| `GuardedWorkspaceService` | workspace 元数据读写（list/get_default/resolve_designated） |

**优势**：
- 遗漏防护是架构级保证——消费者只依赖 Guarded\*Service，漏了方法 = 编译不过
- 关注点分离——inner service 代码无安全噪声
- 多入口共享——Flutter FFI、未来 CLI、测试 harness 都通过同一 Guard 层
- 审计友好——日志可记录 `actor(identity) + scope(scope_workspace_id) + target(request.workspace_id)` 三元组

#### Q5.3 当前实现 — RESOLVED

**裁决**：运行时 pass-through（`NoopGuard`），保留完整接口与错误码通道。

```rust
pub trait AccessGuard {
    fn check_read(&self, caller: &CallerContext, target_workspace: &WorkspaceId) -> Result<(), AccessError>;
    fn check_write(&self, caller: &CallerContext, target_workspace: &WorkspaceId) -> Result<(), AccessError>;
}

pub enum AccessError {
    /// Caller scope does not cover target workspace.
    CrossWorkspaceAccessDenied { scope: WorkspaceId, target: WorkspaceId },
    /// Caller identity lacks required capability.
    InsufficientCapability { identity: CallerIdentity, required: Capability },
}

/// 强类型能力枚举，避免字符串漂移
pub enum Capability {
    WorkspaceRead,
    WorkspaceWrite,
    // 未来扩展：AdminMaintenance, CrossWorkspaceTransfer, ...
}

/// v0.4 透明放行实现
pub struct NoopGuard;

impl AccessGuard for NoopGuard {
    fn check_read(&self, _: &CallerContext, _: &WorkspaceId) -> Result<(), AccessError> { Ok(()) }
    fn check_write(&self, _: &CallerContext, _: &WorkspaceId) -> Result<(), AccessError> { Ok(()) }
}
```

**设计要点**：

- 选运行时 pass-through 而非编译期零开销（泛型单态化），理由：
  - 可运行时切换 guard 实现（未来 feature flag、debug 模式），不需重编译
  - 类型签名简洁——`Box<dyn AccessGuard>` 不增加泛型参数，避免泛型爆炸
  - guard 调用频次 = 每次 Service 方法调用一次，虚表分发开销完全可忽略
- `AccessError` 枚举预定义错误码通道，v0.4 不会触发但 FFI 映射已就绪
- `NoopGuard` 是唯一的 v0.4 实现，所有 Guarded\*Service 注入同一个 `NoopGuard` 实例

#### Q5.4 origin_workspace_id 读路径 — RESOLVED

**裁决**：选 A — v0.x 不启用核心读路径校验，保持 DI-15 Q10 的 C+（写入但不消费）。

**理由**：
- 读路径校验的前提是多 workspace + per-workspace 加密，v0.4 都不具备
- 过早引入读校验会影响 ScopedAtomQuery 的 CTE 性能（每行结果要校验 workspace 权限）
- origin_workspace_id 持续写入，数据积累不丢失，未来启用读校验时数据已就绪

**可选软校验**：如需试点门禁，可在 FFI/UI 层做可开关的软校验（通过 settings flag 控制），不影响核心 Service/Repo 层。软校验发现越权时记录日志 + UI 提示，不阻断操作。这是观测手段，不是强制门禁。

---

### Q6. FFI API 变更 — RESOLVED

**背景**：统一查询（Q1）和统一创建（Q3）改变了 FFI 的设计方向。Q5 引入 Guarded\*Service 包装层。本 Q 裁决 FFI 层的最终 API 面。

#### Q6.0 万能接口约束 — RESOLVED

统一查询/统一创建收敛为单一 FFI 入口后，需防止"万能接口失控"。以下 5 条硬约束贯穿所有 Q6 子项：

| # | 约束 | 防范风险 |
|---|------|---------|
| C1 | **descriptor 必须强类型**（enum/字段约束），不做自由字符串 DSL | 任意查询注入、参数语义漂移 |
| C2 | **Rust 侧统一校验**并返回标准错误码（`invalid_query_descriptor`） | 非法参数组合泄漏到 SQL 层 |
| C3 | **Dart helper 只做参数模板**（工厂方法填默认值），不承载业务逻辑 | 业务规则泄漏到 Flutter 层（违反 Rule A） |
| C4 | **默认分页与硬上限内建**：`Default::default()` 给合理 limit，Rust 侧 clamp 到硬上限 | 全量扫描、OOM |
| C5 | **一次性迁移删除旧入口**，不维护双轨 FFI | 语义漂移、维护成本翻倍 |

**分页硬规则**：
- `ScopedAtomQuery::default()` 的 limit = 50
- Rust 侧 clamp：`query.limit = query.limit.min(MAX_QUERY_LIMIT)`，`MAX_QUERY_LIMIT = 200`
- offset 无硬上限（offset 过大时 SQL 自然返回空集）
- Today 双查询场景（Q1.4）主查询内部用 `limit: u32::MAX` 是 Service 层内部行为，不经 FFI 暴露

#### Q6.1 统一查询 FFI 入口 — RESOLVED

**裁决**：单一 `query_atoms` FFI，无分立查询 FFI、无语义快捷方式。与 Q3 统一创建策略一致。

**FFI 函数**（C1：全部强类型 enum，无字符串参数）：

```rust
/// FRB 生成对应 Dart enum，跨 FFI 传递强类型
pub enum FfiTimeFilterKind { Any, Timeless, Range }
pub enum FfiTimeShapeFilter { Any, BoundedOnly }
pub enum FfiStatusFilterKind { Any, ActiveOnly, TaskStatuses }
pub enum FfiSortSpec { UpdatedAtDesc, StartAtAsc, TitleAsc }
pub enum FfiProjectionMode { Atom, Ref }

pub enum FfiViewHint { Note, Task, Event }
pub enum FfiTaskStatus { Todo, InProgress, Done, Cancelled }

pub struct FfiScopedAtomQuery {
    pub folder_id: String,
    pub view_hint: Option<FfiViewHint>,       // None = 不过滤
    pub time_filter: FfiTimeFilterKind,
    pub time_start_ms: Option<i64>,           // Range 时必填
    pub time_end_ms: Option<i64>,             // Range 时可选（None = 无上界）
    pub time_shape: FfiTimeShapeFilter,
    pub status_filter: FfiStatusFilterKind,
    pub task_statuses: Option<Vec<FfiTaskStatus>>,  // TaskStatuses 时必填
    pub tag: Option<String>,
    pub text_query: Option<String>,
    pub include_path: bool,
    pub include_overdue_deadlines: bool,       // Today 场景设 true，触发 overdue T1 补偿
    pub sort: FfiSortSpec,
    pub limit: u32,
    pub offset: u32,
}

/// 统一查询入口
pub async fn query_atoms(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse
```

**内部流程**（FFI 适配器）：

1. 反序列化 `FfiCallerContext` → `CallerContext`
2. 反序列化 `FfiScopedAtomQuery` → `ScopedAtomQuery`（C2 校验：枚举组合合法性、Range 时 time_start_ms 必填等）
3. 调 `GuardedQueryService::query`（统一 Guard 入口，不绕过）
4. 序列化结果 → `ScopedQueryResponse`

**Today overdue 补偿**：通过 `include_overdue_deadlines: bool` 下沉到 ScopedAtomQuery。当 `include_overdue_deadlines = true` 且 `time_filter = Range` 时，ScopedQueryRepository 自动 UNION overdue T1 查询（Q1.4 的补查询 SQL）并去重。不需要独立 FFI 入口。

- Dart helper `tasksToday` 模板设 `include_overdue_deadlines: true`
- 其他模板设 `false`（默认值）
- Q1.4 的 `TaskService::list_today` 双查询合并逻辑迁移到 ScopedQueryRepository 内部

**Dart helper 示例**（C3：只做参数模板，不做业务转换；C1：强类型 enum）：

```dart
/// Dart 层工厂方法 — 只填参数模板，不含业务逻辑
class QueryDescriptors {
  static FfiScopedAtomQuery tasksInbox(String folderId) =>
    FfiScopedAtomQuery(
      folderId: folderId,
      timeFilter: FfiTimeFilterKind.timeless,
      timeShape: FfiTimeShapeFilter.any,
      statusFilter: FfiStatusFilterKind.activeOnly,
      sort: FfiSortSpec.updatedAtDesc,
      includeOverdueDeadlines: false,
      includePath: false,
    );

  static FfiScopedAtomQuery tasksToday(String folderId, int bodMs, int eodMs) =>
    FfiScopedAtomQuery(
      folderId: folderId,
      timeFilter: FfiTimeFilterKind.range,
      timeStartMs: bodMs,
      timeEndMs: eodMs,
      timeShape: FfiTimeShapeFilter.any,
      statusFilter: FfiStatusFilterKind.activeOnly,
      sort: FfiSortSpec.startAtAsc,
      includeOverdueDeadlines: true,  // Today 场景：自动补偿 overdue T1
      includePath: false,
    );
}
```

**旧查询 FFI 移除清单**（C5）：

| 移除函数 | 替代 |
|---------|------|
| `tasks_list_inbox` | `query_atoms` + Dart helper `tasksInbox` |
| `tasks_list_today` | `query_atoms` + Dart helper `tasksToday`（`include_overdue_deadlines: true`） |
| `tasks_list_upcoming` | `query_atoms` + Dart helper `tasksUpcoming` |
| `calendar_list_by_range` | `query_atoms` + Dart helper `calendarRange` |
| `notes_list` | `query_atoms` + Dart helper |
| `entry_search` | `query_atoms` + `text_query` 参数 |

**树导航方法独立暴露**（不走 ScopedAtomQuery 管线）：

| 函数 | 说明 |
|------|------|
| `workspace_get_ancestor_path(caller, node_uuid)` | Q2/Q4.4：面包屑路径 |
| `workspace_list_atom_refs_for_atom(caller, atom_uuid)` | Q2：atom 引用位置 |

#### Q6.2 统一创建 FFI 入口 — RESOLVED

**裁决**：Q3.3 已裁决。新增 `atom_create`，分批迁移后移除旧 FFI。

```rust
pub async fn atom_create(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
) -> AtomCreateResponse
```

旧 FFI 移除清单：`entry_create_note`、`entry_create_task`、`entry_schedule`、`note_create`。

#### Q6.3 新增 FFI 完整清单 — RESOLVED

v0.4 新增 FFI 函数总览（含 Q1-Q5 产出）：

| 函数 | 来源 | 调用的 Guarded\*Service |
|------|------|------------------------|
| `query_atoms(caller, descriptor, projection)` | Q1/Q6.1 | GuardedQueryService::query |
| `atom_create(caller, request)` | Q3/Q6.2 | GuardedCreationService::create_atom |
| `atom_get(caller, atom_id)` | 保留 | GuardedAtomService::get |
| `atom_update_status(caller, atom_id, status)` | 保留 | GuardedTaskService::update_status |
| `workspace_list(caller)` | DI-15 Q9 | GuardedWorkspaceService::list |
| `workspace_get_default(caller)` | DI-15 Q9 | GuardedWorkspaceService::get_default |
| `workspace_resolve_designated(caller, workspace_id, role)` | Q4.2 | GuardedWorkspaceService::resolve_designated |
| `workspace_reassign_designated(caller, workspace_id, role, new_node_uuid)` | Q4.2 | GuardedTreeService::reassign_designated |
| `workspace_get_ancestor_path(caller, node_uuid)` | Q2/Q4.4 | GuardedTreeService::get_ancestor_path |
| `workspace_list_atom_refs_for_atom(caller, atom_uuid)` | Q2 | GuardedTreeService::list_atom_refs_for_atom |
| `workspace_create_folder(caller, parent_node_id, name)` | 保留（签名变更） | GuardedTreeService::create_folder |
| `workspace_create_atom_ref(caller, parent_node_id, atom_id, display_name)` | 保留（签名变更） | GuardedTreeService::create_atom_ref |
| `workspace_list_children(caller, parent_node_id)` | 保留（签名变更） | GuardedTreeService::list_children |
| `workspace_rename_node(caller, node_id, new_name)` | 保留（签名变更） | GuardedTreeService::rename_node |
| `workspace_move_node(caller, node_id, new_parent_id, target_order)` | 保留（签名变更） | GuardedTreeService::move_node |
| `workspace_delete_folder(caller, node_id, mode)` | 保留（签名变更） | GuardedTreeService::delete_folder |
| `atom_update_content(caller, atom_id, content)` | 保留（重命名 `note_update`，签名变更） | GuardedAtomService::update_content |
| `atom_set_tags(caller, atom_id, tags)` | 保留（重命名 `note_set_tags`，签名变更） | GuardedAtomService::set_tags |
| `atom_update_time(caller, atom_id, start_ms, end_ms)` | 保留（重命名 `calendar_update_event`，签名变更） | GuardedAtomService::update_time |

**不暴露**：`workspace_create`（v0.4 单 workspace，migration 预创建）。

**旧名称移除**（DI-17 Q5 补充）：`note_update` → `atom_update_content`、`note_set_tags` → `atom_set_tags`、`calendar_update_event` → `atom_update_time`、`note_get` → `atom_get`（已列出）、`atoms_list_timed` → `query_atoms` 替代。

**保留函数签名变更**：所有保留的 FFI 函数加 `caller: FfiCallerContext` 首参数（Q5 裁决）。workspace 树操作函数的 `parent_node_id` 语义不变但上下文明确（Q4 硬约束：非 workspace root 时 parent 必须非 None）。

#### Q6.4 响应类型 — RESOLVED

**统一查询响应**：

所有新 response envelope 统一遵循现有 codebase 惯例：`ok: bool` + `error_code: Option<String>` + `message: String`。

```rust
pub struct ScopedQueryResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub items: Vec<ScopedAtomItem>,
}

pub struct ScopedAtomItem {
    // Atom 字段平坦展开（与现有 AtomListResponse 中的 item 对齐）
    pub uuid: String,
    pub view_hint: String,
    pub title: String,
    pub content: String,
    pub content_type: String,
    pub preview_text: Option<String>,
    pub task_status: Option<String>,
    pub start_at: Option<i64>,
    pub end_at: Option<i64>,
    pub is_deleted: bool,
    pub created_at: i64,
    pub updated_at: i64,
    // ScopedAtomResult 附加字段
    pub representative_node_uuid: String,
    pub path: Option<String>,
}
```

**统一创建响应**：

```rust
pub struct AtomCreateResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub atom_uuid: Option<String>,
    pub node_uuid: Option<String>,  // 创建的 atom_ref 节点
}
```

**树导航响应**：

```rust
pub struct AncestorPathResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub segments: Vec<PathSegment>,
}

pub struct PathSegment {
    pub node_uuid: String,
    pub display_name: String,
}

pub struct AtomRefLocationsResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub locations: Vec<FfiAtomRefLocation>,
}

pub struct FfiAtomRefLocation {
    pub node_uuid: String,
    pub workspace_id: String,
    pub path: String,
    pub display_name: String,
}
```

**workspace 管理响应**：

```rust
pub struct WorkspaceListResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub workspaces: Vec<WorkspaceInfo>,
}

pub struct WorkspaceInfo {
    pub workspace_id: String,
    pub name: String,
    pub is_default: bool,
}

pub struct DesignatedFolderResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub node_uuid: Option<String>,
}
```

#### Q6.5 Error code 扩展 — RESOLVED

v0.4 新增错误码（需注册到 `error-codes.md`）：

| 错误码 | 来源 | 场景 |
|--------|------|------|
| `invalid_query_descriptor` | Q6.0 C2 | ScopedAtomQuery 参数校验失败（非法 enum 值、矛盾组合等） |
| `workspace_root_protected` | Q4.1 | 尝试删除 workspace root |
| `designated_folder_protected` | Q4.1 | 尝试删除 designated folder |
| `cannot_move_workspace_root` | Q4.1 | 尝试移动 workspace root |
| `cannot_move_to_root` | Q4.1 | 尝试移动节点到 parent=None |
| `cross_workspace_move_not_allowed` | Q4.1 | 跨 workspace 移动 |
| `target_folder_not_in_workspace` | Q3.2 | 创建时 target_folder 不属于指定 workspace |
| `invalid_content_type` | Q3.1 | 不支持的 content_type |
| `cross_workspace_access_denied` | Q5.3 | Guard 拒绝跨 workspace 访问 |
| `insufficient_capability` | Q5.3 | Guard 能力不足 |
| `workspace_not_found` | Q6.3 | 指定的 workspace_id 不存在 |
| `designated_role_not_found` | Q6.3 | 指定的 role 在 designated_folders 中无记录 |

#### Q6.6 兼容策略 — RESOLVED

**裁决**：v0.4 允许 breaking change（pre-1.0）。一次性迁移删除旧入口（C5）。

**迁移策略**：与 Q3.3 统一，按 PR 分批：

| PR | 内容 |
|----|------|
| PR-α | Rust Core 新 Service + 新 FFI 函数（query_atoms、atom_create 等） |
| PR-β | Flutter 层迁移到新 FFI |
| PR-γ | 移除旧 FFI 函数 + 旧 Service 方法 |

三个 PR 在 v0.4 内合入。Q3.3 的 PR-A/B/C 与此合并（查询和创建同批次迁移）。

#### Q6.7 PR-RB-10 迁移桥接 — RESOLVED

- PR-RB-10（Tag Panel）当前使用 `notes_list(tag=)` + `workspace_get_ancestor_path` 逐条补路径（N+1 模式）
- v0.4 迁移为单次 `query_atoms({ tag, include_path: true, folder_id: workspace_root }, FfiProjectionMode.Atom)`
- `workspace_get_ancestor_path` 保留（Editor 面包屑仍需要），但 Tag Panel 的 N+1 批量补路径用法被统一查询取代
- `notes_list` 在 PR-γ 中移除

---

## 关联

- ← DI-15（Rust 数据模型：多根森林、workspaces、designated_folders、origin_workspace_id）
- ← DI-12（概念母题：路由、查询、兼容裁决；部分被多根方案覆盖）
- ← DI-14（概念母题：核心能力与接口需求）
- ← S1（Atom 投影语义：view_hint 定义、指定路径模型、多引用）
- ← DI-11（AtomType → ViewHint 重命名，atom_create 收敛方向）
- → DI-17（Flutter 薄客户端：消费本 DI 的 FFI 契约）
- → DI-18（执行方案：API 变更的部署策略）

---

*前序议题：[DI-15 Rust Core 数据模型 — 工作区树架构](DI-15-rust-data-model-single-root.md)*
