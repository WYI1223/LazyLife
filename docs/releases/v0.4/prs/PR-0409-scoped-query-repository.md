# PR-0409: ScopedAtomQuery + ScopedQueryRepository

- Proposed title: `feat(core): scoped atom query engine with CTE pipeline`
- Status: Merged

## Goal

### Dependency Clarification (2026-03-13)

This PR consumes the **post-0012 schema contract** from `PR-0408`, rather than restating migration internals. It may assume:

- `workspace_nodes.kind` includes `workspace`;
- `workspaces` exists and current migrated data contains one default workspace;
- `designated_folders` exists and current migrated data contains `inbox/tasks/calendar`;
- `WorkspaceMetaRepository` is the read-side bridge for designated-folder resolution.

This PR must build scoped-query behavior on top of those landed schema guarantees, but must not reopen migration/backfill design inside `PR-0409`.

### Transitional Compatibility Clarification (2026-03-14)

`PR-0409` lands the canonical `ScopedQueryRepository` and subtree-query contract, but it also carries a temporary compatibility bridge for the current pre-`PR-0410` runtime:

- existing creation paths still place new `atom_ref` rows under the default workspace root when no explicit parent is provided;
- `PR-0409` therefore must not make current FFI-consumed section views silently drop those root-scoped refs;
- the bridge is limited to current service-consumer compatibility and does not weaken the canonical query contract itself;
- `PR-0410` is the first PR allowed to tighten, replace, or explicitly retire this bridge once service-routing and creation-role ownership land.

引入统一查询引擎 ScopedQueryRepository，支持按 workspace 子树范围查询 atoms。替代 TaskService/CalendarService 的直查 atoms 路径，为 PR-0411 FFI 层的 `query_atoms` 提供后端。

前置条件：PR-0408（需要 Migration 0012 的 schema）

## Execution Contract (Canonical Inputs)

Shared promotion register:

- `docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md`
- This PR must leave evidence sufficient for `CPR-001`, but may not publish carrier text directly.

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q1 | ScopedAtomQuery 结构、枚举、CTE 管线设计 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0409 行）、Q4（Service 测试） | PR 定位、测试要求（契约真值表） |
| 现有实现 | `crates/lazynote_core/src/service/task_service.rs` | 查询路径改造目标 |
| 现有实现 | `crates/lazynote_core/src/service/atom_service.rs` | 查询路径改造目标 |
| Handoff workflow | `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` | `DOC-023 / DI-15` + `DOC-024 / DI-16` + `DOC-026 / DI-18` 的交接合同；本 PR 负责更新 `scoped-query` ledger，同时更新 `execution-order` 与 `verification-gates` rows，并显式消费 `OI-034`、`OI-045`、以及本 PR 负责的 `OI-048` 部分，不得直接发布 ADR / ruling / topic-map carrier |

## Scope

In scope:
- ScopedAtomQuery struct + 全套枚举（ProjectionMode、TimeFilter、SortOrder 等）
- ScopedQueryRepository：CTE 管线实现（子树展开 → 时间过滤 → 排序 → 分页）
- TaskService 查询路径改造：`list_inbox`/`list_today`/`list_upcoming` 委托到 ScopedAtomQuery（DI-16 Q1.4）
- CalendarService 查询路径改造：`list_by_range` 委托到 ScopedAtomQuery
- 契约真值表测试：descriptor 合法/非法组合覆盖
- overdue T1 补偿逻辑
- 更新 `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` 中 `scoped-query`、`execution-order`、以及本 PR 负责的 `verification-gates` rows，显式对齐 `OI-034`、`OI-045`、`OI-048`，写入 landed/partial 状态与证据路径

Out of scope:
- TreeService 增强 / CreationService（PR-0410）
- FFI 层变更（PR-0411）
- Flutter 消费方变更（PR-0412/6）
- 直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `docs/architecture/adr/topic-map.md`

## Design

### 总体架构（DI-16 Q1.3）

PR-0409 引入 `ScopedQueryRepository` 作为统一只读查询入口，替代 `AtomRepository` 中分散的 section 查询方法（`fetch_inbox`/`fetch_today`/`fetch_upcoming`/`fetch_by_time_range`）。

```
TaskService / CalendarService
  ├── WorkspaceMetaRepository  → resolve_designated(workspace_id, role) → folder_id
  └── ScopedQueryRepository    → query_scoped_atoms(query, projection) → Vec<ScopedAtomResult>
                                     ↑
                               CTE 管线（scope → filter → dedup → sort+page）
                               只读 JOIN: workspace_nodes + atoms
```

`AtomRepository` 保留写路径（CRUD / status / time update），不再承载读查询逻辑。`ScopedQueryRepository` 只读，不依赖其他 repo。

### Transitional Query Bridge (2026-03-14)

Because `PR-0410` has not yet landed creation routing, current runtime writes can still leave newly created refs under the default workspace root rather than a designated folder. To avoid a silent behavior regression while still landing the scoped-query engine in this PR:

- `ScopedQueryRepository` itself remains fully subtree-scoped and designated-folder-capable;
- `TaskService` may temporarily route current FFI-consumed section reads through a compatibility scope that preserves pre-`PR-0410` visibility for root-scoped refs;
- this bridge must be explicit in code and tests, not hidden in ad-hoc SQL branches;
- `PR-0410` must consume this bridge and either replace it with service-routing-backed designated semantics or preserve an intentional compatibility rule with explicit rationale.

Current landed shape in this branch:

- `ScopedQueryRepository` itself is fully subtree-scoped and accepts any folder or workspace root as `folder_id`;
- `TaskService` currently implements the bridge by resolving the default workspace root and using that root as the compatibility scope for existing section reads;
- the bridge is covered by `crates/lazynote_core/tests/scoped_query_repo.rs`, updated `time_matrix.rs`, and `lazynote_ffi` tests for `tasks_list_inbox` / `tasks_list_today` / `tasks_list_upcoming`, so later PRs can tighten it against explicit evidence rather than inference.

---

### ScopedAtomQuery 结构体与枚举（DI-16 Q1.1）

```rust
/// 统一查询描述符，传递给 ScopedQueryRepository::query_scoped_atoms。
pub struct ScopedAtomQuery {
    /// 查询范围起始节点（必传）。"全 workspace" 传 workspace_root uuid。
    pub folder_id: WorkspaceNodeId,
    /// 可选 view_hint 过滤（不违反 S1 R3，过滤 ≠ 推导）。
    pub view_hint: Option<ViewHint>,
    /// 时间范围语义（Any / Timeless / Range）。
    pub time_filter: TimeFilter,
    /// 时间字段 NULL 形态过滤（Any / BoundedOnly）。
    pub time_shape: TimeShapeFilter,
    /// 状态过滤（Any / ActiveOnly / TaskStatuses）。
    pub status_filter: StatusFilter,
    /// 标签过滤（单标签，lowercase）。
    pub tag: Option<String>,
    /// FTS5 全文搜索过滤，与其他过滤 AND 连接。
    pub text_query: Option<String>,
    /// 是否在结果中附带 workspace 路径字符串。
    pub include_path: bool,
    /// Today 场景：UNION overdue T1（deadline < Range.start_ms）。
    /// 仅在 time_filter = Range(s, Some(e)) 时合法，其余组合返回 invalid_query_descriptor。
    pub include_overdue_deadlines: bool,
    /// 排序规则。
    pub sort: SortSpec,
    /// 分页 limit。
    pub limit: u32,
    /// 分页 offset。
    pub offset: u32,
}

pub enum TimeFilter {
    Any,
    Timeless,
    /// overlap 语义（end_ms = Some）或锚点前移语义（end_ms = None）。
    Range { start_ms: i64, end_ms: Option<i64> },
}

pub enum TimeShapeFilter {
    Any,
    /// start_at IS NOT NULL AND end_at IS NOT NULL（Calendar 主网格专用）。
    BoundedOnly,
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

/// 双投影模式。
pub enum ProjectionMode {
    /// 智能视图：按 atom 去重，每个 atom 只出现一次（Tasks/Calendar）。
    Atom,
    /// 树导航：按 atom_ref，每个引用独立返回，含路径（Explorer/Tag）。
    Ref,
}

pub struct ScopedAtomResult {
    /// Atom 投影：非稳定提示（节点移动后可能切换）；Ref 投影：稳定。
    pub representative_node_uuid: WorkspaceNodeId,
    pub atom: Atom,
    /// include_path = true 时填充；Atom 投影下为 representative ref 的非稳定路径。
    pub path: Option<String>,
}
```

---

### ScopedQueryRepository 接口（DI-16 Q1.3）

```rust
pub trait ScopedQueryRepository {
    /// 统一只读查询入口。
    ///
    /// # Errors
    /// - `invalid_query_descriptor`：descriptor 中存在非法参数组合（见契约真值表）。
    fn query_scoped_atoms(
        &self,
        query: ScopedAtomQuery,
        projection: ProjectionMode,
    ) -> Result<Vec<ScopedAtomResult>, ScopedQueryError>;
}
```

**契约真值表（descriptor 合法性）**：

| ProjectionMode | include_path | 合法性 | 说明 |
|----------------|-------------|--------|------|
| `Atom` | false | ✓ | 标准智能视图查询 |
| `Atom` | true | ✓ | 去重 + 非稳定代表路径（Tag 搜索场景） |
| `Ref` | false | ✓ | 不含路径的树导航列表 |
| `Ref` | true | ✓ | 完整 atom_ref 路径（稳定） |

| include_overdue_deadlines | time_filter | 合法性 |
|--------------------------|------------|--------|
| `true` | `Range(s, Some(e))` | ✓ |
| `true` | `Any` / `Timeless` / `Range(s, None)` | ✗ → `invalid_query_descriptor` |

---

### CTE 管线设计（DI-16 Q1.2）

固定四段 CTE 管线，在 SQL 层组合子树遍历 + 过滤 + 去重 + 排序分页：

```sql
-- 第 1 段：scope — 从 folder_id 出发递归展开子树，收集 atom_ref
WITH scope_refs AS (
  WITH RECURSIVE subtree AS (
    SELECT node_uuid, 0 AS depth,
           CAST(display_name AS TEXT) AS path  -- include_path=false 时 NULL AS path
    FROM workspace_nodes
    WHERE node_uuid = ?folder_id AND is_deleted = 0
    UNION ALL
    SELECT wn.node_uuid, s.depth + 1,
           s.path || '/' || wn.display_name
    FROM workspace_nodes wn
    JOIN subtree s ON wn.parent_uuid = s.node_uuid
    WHERE wn.is_deleted = 0
  )
  SELECT wn.node_uuid, wn.atom_uuid, st.depth, st.path
  FROM subtree st
  JOIN workspace_nodes wn ON wn.node_uuid = st.node_uuid
    AND wn.kind = 'atom_ref' AND wn.is_deleted = 0
),

-- 第 2 段：filter — JOIN atoms + 所有 WHERE 条件（白名单原语，不含业务词）
filtered AS (
  SELECT sr.node_uuid, sr.depth, sr.path, a.*
  FROM scope_refs sr
  JOIN atoms a ON a.uuid = sr.atom_uuid
  WHERE a.is_deleted = 0
    AND (... TimeFilter 条件 ...)
    AND (... TimeShapeFilter 条件 ...)
    AND (... StatusFilter 条件 ...)
    AND (... view_hint / tag / text_query 条件 ...)

  -- include_overdue_deadlines = true 时追加：
  UNION ALL
  SELECT sr.node_uuid, sr.depth, sr.path, a.*
  FROM scope_refs sr
  JOIN atoms a ON a.uuid = sr.atom_uuid
  WHERE a.is_deleted = 0
    AND a.start_at IS NULL AND a.end_at IS NOT NULL
    AND a.end_at < ?start_ms   -- overdue T1（deadline < Range 起点）
    AND (a.task_status NOT IN ('done','cancelled') OR a.task_status IS NULL)
),

-- 第 3 段：dedup — Atom 投影时按 atom_uuid 去重（取最浅深度 ref）
deduped AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY uuid ORDER BY depth ASC, node_uuid ASC
  ) AS rn
  FROM filtered
  -- Ref 投影：SELECT *, 1 AS rn FROM filtered（透传）
),

-- 第 4 段：sort + page
SELECT ... FROM deduped
WHERE rn = 1   -- Atom 投影；Ref 投影无此条件
ORDER BY ...   -- SortSpec 决定
LIMIT ? OFFSET ?
```

**配套索引**（Migration 0012 或本 PR 补建，参考 DI-16 A8 + Q1.2）：

```sql
CREATE INDEX idx_wn_parent_deleted_kind ON workspace_nodes(parent_uuid, is_deleted, kind);
CREATE INDEX idx_wn_atom_deleted ON workspace_nodes(atom_uuid, is_deleted);
CREATE INDEX idx_atoms_deleted_status ON atoms(is_deleted, task_status);
CREATE INDEX idx_atom_tags_atom ON atom_tags(atom_uuid);
```

---

### Workspace 子树范围与 designated folder 解析

**数据流**：Service 层 → WorkspaceMetaRepository → folder_id → ScopedQueryRepository

1. Service 方法首先调用 `WorkspaceMetaRepository::resolve_designated(workspace_id, role)` 获取 designated folder 的 `folder_id`。
2. Repo 层只接受 `folder_id`，不理解 role 语义（`tasks`/`calendar`/`inbox` 是 Service 层概念）。
3. `folder_id` 作为递归 CTE 的起点，天然将查询范围限制在该 folder 的子树内，不跨 workspace。

**"全 workspace" 查询**：传入 workspace root 的 `node_uuid`（`kind = 'workspace'`），递归 CTE 遍历整棵树。

**`origin_workspace_id` 字段（PR-0408 新增）**：本 PR 的查询管线不读取 `origin_workspace_id`——范围由 `folder_id` 子树决定，不依赖 atom 上的来源标记。`origin_workspace_id` 是写路径归属标记（C+ 模式，DI-15 Q10），读路径升级由后续 PR 处理。

---

### time-matrix 四象限过滤规则（DI-16 Q1.2）

| 形态 | start_at | end_at | Timeless | Range overlap | Range 锚点前移 |
|------|----------|--------|----------|---------------|---------------|
| T0 | NULL | NULL | ✓ | ✗ | ✗ |
| T1 | NULL | VAL | ✗ | `end_at >= s` | `end_at >= s` |
| T2 | VAL | NULL | ✗ | `start_at < e` | `start_at >= s` |
| T3 | VAL | VAL | ✗ | `start_at < e AND end_at >= s` | `start_at >= s` |

`Range(s, Some(e))` 使用 **overlap 语义**（atom 有效区间与 [s, e) 有交集）；`Range(s, None)` 使用**锚点前移语义**（atom 主时间锚点 >= s），两者语义不同。混用会导致 Today/Upcoming 分区错误（进行中的 T2 task 在 overlap 下属于 Today，在锚点前移下不属于 Upcoming）。

**Today overdue T1 补偿**：`Range(bod, Some(eod))` 的 overlap 条件会漏掉 deadline < bod 的 T1 项。`include_overdue_deadlines = true` 时，Repository 内部在 filter 段之后 UNION 补查，统一进入 dedup 阶段处理去重，分页在最外层 LIMIT/OFFSET 截取。

---

### TaskService / CalendarService 查询路径改造（DI-16 Q1.4）

Service 层每个查询方法做三件事：**解析 designated folder** → **翻译业务概念为 ScopedAtomQuery 参数** → **执行查询**。

**TaskService 业务语义 → ScopedAtomQuery 映射**：

| 方法 | folder_id | time_filter | status_filter | include_overdue | sort |
|------|-----------|-------------|---------------|-----------------|------|
| `list_inbox` | `designated('tasks')` | `Timeless` | `ActiveOnly` | false | `UpdatedAtDesc` |
| `list_today` | `designated('tasks')` | `Range(bod, Some(eod))` | `ActiveOnly` | **true** | `StartAtAsc` |
| `list_upcoming` | `designated('tasks')` | `Range(eod, None)` | `ActiveOnly` | false | `StartAtAsc` |

**CalendarService 业务语义 → ScopedAtomQuery 映射**：

| 方法 | folder_id | time_filter | time_shape | status_filter |
|------|-----------|-------------|------------|---------------|
| `list_by_range(s, e)` | `designated('calendar')` | `Range(s, Some(e))` | `BoundedOnly` | `Any` |
| `list_pending` | `designated('calendar')` | `Timeless` | `Any` | `Any` |

**泛型签名示意**：

```rust
pub struct TaskService<S, W, A>
where
    S: ScopedQueryRepository,
    W: WorkspaceMetaRepository,
    A: AtomRepository,
{
    scoped_query: S,
    workspace_meta: W,
    atom_repo: A,
}
```

泛型依赖注入保证 mock 可测性，与现有 `TaskService<'conn, R: AtomRepository>` 模式一致。

**向后兼容**：现有 `AtomRepository` 的 `fetch_inbox`/`fetch_today`/`fetch_upcoming`/`fetch_by_time_range` 方法在本 PR 中随 service 路径改造一并移除（纯 Rust 内部重构，无 Flutter 侧 FFI 依赖）。`TaskService`/`CalendarService` 对外语义不变；旧 FFI 函数（`tasks_list_inbox` 等）在 PR-0411 才变为薄 wrapper，本 PR 不涉及 FFI 层。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | ScopedAtomQuery struct + 枚举定义 | `crates/lazynote_core/src/repo/` | TBD | — |
| T2 | Rust | ScopedQueryRepository CTE 管线 | `crates/lazynote_core/src/repo/` | TBD | T1 |
| T3 | Rust | TaskService 查询路径委托改造 | `crates/lazynote_core/src/service/task_service.rs` | TBD | T2 |
| T4 | Rust | CalendarService 查询路径委托改造 | `crates/lazynote_core/src/service/atom_service.rs` | TBD | T2 |
| T5 | Rust | 契约真值表测试 + time-matrix 四象限测试 | `crates/lazynote_core/tests/` | TBD | T2 |

## Planned File Changes

- `[add]` crates/lazynote_core/src/repo/scoped_query_repo.rs (landed scoped-query contract + CTE implementation)
- `[edit]` crates/lazynote_core/src/repo/atom_repo.rs (remove legacy section-read surface; keep write paths and shared row parsers)
- `[edit]` crates/lazynote_core/src/service/task_service.rs (delegate section reads through ScopedQueryRepository with explicit pre-PR-0410 compatibility scope)
- `[edit]` crates/lazynote_core/src/repo/mod.rs (export scoped query repo module)
- `[edit]` crates/lazynote_core/src/lib.rs (re-export scoped query contracts)
- `[add]` crates/lazynote_core/tests/scoped_query_repo.rs (truth-table, dedup, subtree, and bridge coverage)
- `[edit]` crates/lazynote_core/tests/time_matrix.rs (service-level regression coverage)
- `[edit]` crates/lazynote_ffi/src/api.rs (TaskService bridge wiring + inbox/today/upcoming regression tests)
- `[edit]` docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md (landed evidence sync)

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
```

### Structural verification

```bash
# 验证 ScopedAtomQuery 类型存在
grep -rn "ScopedAtomQuery" crates/lazynote_core/src/ --include="*.rs"
# 预期：struct 定义 + 至少一处使用

# 验证 TaskService 委托到新查询
grep -rn "ScopedAtomQuery\|ScopedQueryRepository" crates/lazynote_core/src/service/task_service.rs
# 预期：至少 1 匹配
```

### Closeout Verification (2026-03-14)

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd ..
dart run tools/ci/architecture_check.dart
```

Confirmed on 2026-03-14:

- `cargo fmt --all -- --check` exits `0`
- `cargo clippy --all -- -D warnings` exits `0`
- `cargo test --all` passes
- `dart run tools/ci/architecture_check.dart` passes with `0 violations / 0 broken links / 2 allowlisted exemptions`

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| CTE 管线 SQL 复杂度高 | MEDIUM | 充分的四象限测试 + overdue 补偿测试 |
| 旧 TaskService/CalendarService 测试因路径改造失败 | LOW | 委托改造保持语义不变，旧测试全绿即回归通过 |

## Acceptance Criteria

- [x] `ScopedAtomQuery`, its enums, and `ScopedQueryRepository` land in `crates/lazynote_core/src/repo/scoped_query_repo.rs`
- [x] subtree scope, dedup, stable ref ordering, and open-ended range semantics are covered by `crates/lazynote_core/tests/scoped_query_repo.rs`
- [x] overdue T1 compensation and time-matrix regressions remain covered by `crates/lazynote_core/tests/time_matrix.rs`
- [x] `TaskService` routes `list_inbox` / `list_today` / `list_upcoming` / `fetch_by_time_range` through `ScopedQueryRepository`
- [x] the pre-`PR-0410` default-workspace compatibility bridge remains explicit in service code and tests
- [x] the old `AtomRepository` section-read surface is removed from the canonical read path
- [x] FFI bridge coverage exists for `tasks_list_inbox`, `tasks_list_today`, and `tasks_list_upcoming`
- [x] `workspace-topology-carrier-promotion-workflow.md` records landed `scoped-query` evidence plus updated `execution-order` and `verification-gates` rows
- [x] this PR does not publish or amend `DI-15` active-bundle ADR / ruling / `topic-map.md` carrier text
- [x] `cargo fmt --all -- --check`, `cargo clippy --all -- -D warnings`, `cargo test --all`, and `dart run tools/ci/architecture_check.dart` all passed on 2026-03-14
- [x] PR spec Status updated to Merged
