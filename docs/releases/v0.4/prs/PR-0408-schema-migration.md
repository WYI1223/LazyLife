# PR-0408: Schema Migration 0012 — 单根树 + Workspace 元数据 + Designated Folders

- Proposed title: `feat(core): migration 0012 single-root workspace tree with designated folders`
- Status: Draft

## Goal

新增 Migration 0012，建立单根 workspace 树结构：`workspaces` 表、designated folders 映射、`atoms.origin_workspace_id` 字段、系统节点回填、DB 触发器保护。为后续 PR-0409~0413 提供 schema 基础。

前置条件：PR-0407（CI 增强应先就位）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md` | Schema 设计、系统节点定义、触发器定义、回填逻辑的完整依据 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0408 行）、Q4（Migration 测试） | PR 定位、测试要求 |
| 现有 schema | `crates/lazynote_core/src/db/migrations/` | 当前 11 个 migration，本 PR 新增第 12 个 |
| Handoff workflow | `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` | `DOC-023 / DI-15` + `DOC-024 / DI-16` + `DOC-026 / DI-18` 的交接合同；本 PR 负责更新 `schema-model` 与 schema 侧 `migration-protection` ledger，同时更新 `execution-order` 与 `verification-gates` rows，并显式消费 `OI-045` 与本 PR 负责的 `OI-048` 部分，不得直接发布 ADR / ruling / topic-map carrier |

## Scope

In scope:
- 新增 `0012_workspace_single_root.sql`
- `workspaces` 表（workspace 元数据：workspace_id、display_name、is_default 等，DI-15 Q9）
- `atoms` 表新增 `origin_workspace_id` 字段（DI-15 Q10：来源 workspace 标记，nullable 以兼容回填）
- `designated_folders` 表（系统节点映射）
- 系统节点创建（workspace root + 3 个 designated folders）
- 现有数据回填（已有 atom 的 atom_ref 归入正确 designated folder）
- DB 触发器：`protect_designated_folder_soft_delete`、`protect_designated_folder_hard_delete`、`validate_designated_folder_workspace`、`protect_workspace_root_reparent`、`protect_workspace_root_kind`
- WorkspaceMetaRepository（Rust：`resolve_designated`、workspace 元数据查询）
- Migration 注册到 `mod.rs` MIGRATIONS 数组
- Migration 测试（全新安装 + 版本升级 + 触发器负测）
- 更新 `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` 中 `schema-model`、schema 侧 `migration-protection`、`execution-order`、以及本 PR 负责的 `verification-gates` rows，写入 landed/partial 状态与证据路径，并说明本 PR 为 `OI-034~OI-038` 和 `OI-045 / OI-048` 提供了哪些 schema / trigger 与 migration-test 前置条件

Out of scope:
- ScopedQueryRepository（PR-0409）
- TreeService 增强 / CreationService（PR-0410）
- FFI 函数变更（PR-0411）
- 直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `docs/architecture/adr/topic-map.md`

## Design

### SQL Schema（DI-15 Q9-Q10）

**新增表：**

```sql
-- Workspace 元数据
CREATE TABLE workspaces (
    workspace_id TEXT PRIMARY KEY
      REFERENCES workspace_nodes(node_uuid) DEFERRABLE INITIALLY DEFERRED,
    name TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
);
CREATE UNIQUE INDEX idx_workspaces_default
ON workspaces(is_default) WHERE is_default = 1;

-- Designated folder 映射
CREATE TABLE designated_folders (
    workspace_id TEXT NOT NULL REFERENCES workspaces(workspace_id),
    role TEXT NOT NULL,        -- 'inbox' | 'tasks' | 'calendar'
    node_uuid TEXT NOT NULL REFERENCES workspace_nodes(node_uuid),
    PRIMARY KEY (workspace_id, role)
);
```

**atoms 表扩展：**

```sql
ALTER TABLE atoms ADD COLUMN origin_workspace_id TEXT
  REFERENCES workspaces(workspace_id);
```

**workspace_nodes.kind CHECK 扩展**：需加入 `'workspace'` 选项，采用 0011 的表重建模式。

### 系统节点定义

| 节点 | Kind | Parent | Role | 可删除 | 可改名 |
|------|------|--------|------|--------|--------|
| Workspace Root | `workspace` | NULL | — | No | No |
| Inbox | `folder` | WS Root | `inbox` | No（须先 reassign） | Yes |
| Tasks | `folder` | WS Root | `tasks` | No（须先 reassign） | Yes |
| Calendar | `folder` | WS Root | `calendar` | No（须先 reassign） | Yes |

### 5 个触发器保护（DI-15 Q12）

| # | 触发器 | 事件 | 保护逻辑 |
|---|--------|------|---------|
| 1 | `protect_workspace_root_reparent` | UPDATE parent_uuid | workspace root 不可 re-parent |
| 2 | `protect_workspace_root_kind` | UPDATE kind | workspace root kind 不可变 |
| 3 | `protect_designated_folder_soft_delete` | UPDATE is_deleted | 有 designated role 时拒绝 soft-delete |
| 4 | `protect_designated_folder_hard_delete` | DELETE | 有 designated role 时拒绝 hard-delete |
| 5 | `validate_designated_folder_workspace` | INSERT/UPDATE on designated_folders | CTE 验证 node 属于指定 workspace |

### 回填策略

1. **Schema 创建**：建表 + ALTER atoms + 重建 workspace_nodes（加 `workspace` kind）
2. **Workspace Root 创建**：生成 UUID → INSERT workspace_nodes（kind=workspace）→ INSERT workspaces
3. **Designated Folders 创建**：3 个 UUID → INSERT 到 workspace_nodes + designated_folders
4. **Reparent 现有节点**：`UPDATE workspace_nodes SET parent_uuid = :ws_root WHERE parent_uuid IS NULL AND node_uuid != :ws_root`
5. **回填 origin_workspace_id**：`UPDATE atoms SET origin_workspace_id = :ws_root WHERE origin_workspace_id IS NULL`
6. **断言检查**：验证恰好 1 个 workspace root、0 个 orphan 根节点、3 个 designated 映射
7. **安装触发器**

### 迁移执行器升级

Migration 0012 需要 Rust 运行时 UUID 生成，纯 SQL `execute_batch` 不足。
`mod.rs` 的 `apply_migrations` 需支持 Rust + SQL 混合执行路径：

```rust
// Migration 枚举支持两种模式
enum MigrationBody {
    Sql(&'static str),
    RustFn(fn(&Transaction) -> Result<()>),
}
```

### WorkspaceMetaRepository 接口

```rust
pub trait WorkspaceMetaRepository {
    fn resolve_designated(&self, workspace_id: WorkspaceId, role: &str)
        -> Result<Option<WorkspaceNodeId>>;
    fn get_default_workspace(&self) -> Result<Option<WorkspaceId>>;
    fn list_workspaces(&self) -> Result<Vec<WorkspaceMetadata>>;
}
```

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T0 | Rust | 迁移执行器升级（支持 Rust+SQL 混合执行） | `crates/lazynote_core/src/db/migrations/mod.rs` | TBD | — |
| T1 | Rust | Migration SQL 编写 | `crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql` | TBD | T0 |
| T2 | Rust | Migration 注册 | `crates/lazynote_core/src/db/migrations/mod.rs` | TBD | T1 |
| T3 | Rust | WorkspaceMetaRepository | `crates/lazynote_core/src/repo/` | TBD | T1 |
| T4 | Rust | 全新安装测试 + 版本升级测试 | `crates/lazynote_core/tests/migration_0012_test.rs` | TBD | T1-T3 |
| T5 | Rust | 触发器负测（5 项） | `crates/lazynote_core/tests/migration_0012_test.rs` | TBD | T1 |

## Planned File Changes

- `[add]` crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql
- `[edit]` crates/lazynote_core/src/db/migrations/mod.rs (注册 migration 12)
- `[add]` crates/lazynote_core/src/repo/workspace_meta_repo.rs (WorkspaceMetaRepository)
- `[edit]` crates/lazynote_core/src/repo/mod.rs (导出新 repo)
- `[add]` crates/lazynote_core/tests/migration_0012_test.rs

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
# 验证 migration 注册
grep -c "0012" crates/lazynote_core/src/db/migrations/mod.rs
# 预期：至少 1 匹配

# 验证触发器存在于 SQL
grep -c "protect_designated_folder" crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql
# 预期：至少 2 匹配（soft-delete + hard-delete）

grep -c "protect_workspace_root" crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql
# 预期：至少 2 匹配（reparent + kind）
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 回填逻辑处理边界情况（orphan atoms、已删除 atoms） | MEDIUM | 充分的版本升级测试覆盖 |
| 触发器阻止合法操作 | LOW | 触发器负测覆盖全部 5 个保护场景 |

## Acceptance Criteria

- [ ] Migration 0012 从空 DB 运行成功，`workspaces` 表存在
- [ ] Migration 0012 从空 DB 运行成功，系统节点（workspace root + 3 designated folders）存在
- [ ] Migration 0012 从空 DB 运行成功，`atoms.origin_workspace_id` 字段存在
- [ ] Migration 0012 从 v11 升级成功，旧 atom 回填到正确 designated folder
- [ ] Migration 0012 从 v11 升级成功，`atoms.origin_workspace_id` 回填正确
- [ ] 触发器负测：designated folder soft-delete 被拒绝
- [ ] 触发器负测：designated folder hard-delete 被拒绝
- [ ] 触发器负测：跨 workspace designated 写入被拒绝
- [ ] 触发器负测：workspace root re-parent 被拒绝
- [ ] 触发器负测：workspace root kind 篡改被拒绝
- [ ] WorkspaceMetaRepository 可查询 workspace 元数据
- [ ] WorkspaceMetaRepository 可查询 designated folder 映射（`resolve_designated`）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `schema-model` row 已更新为本 PR 的实际落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `migration-protection` row 已写明本 PR 覆盖的 schema / trigger 部分与证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `execution-order` row 已更新为本 PR 的实际顺序与依赖落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `verification-gates` row 已写明本 PR 覆盖的 migration-test 部分与证据路径
- [ ] 本 PR 未直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `topic-map.md`
- [ ] PR spec Status updated to Merged
