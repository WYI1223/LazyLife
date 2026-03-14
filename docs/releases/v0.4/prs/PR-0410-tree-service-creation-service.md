# PR-0410: TreeService 增强 + CreationService

- Proposed title: `feat(core): tree service protection rules and unified creation service`
- Status: Draft

## Goal

### Dependency Clarification (2026-03-13)

This PR consumes the **post-0012 schema contract** from `PR-0408`. It may rely on:

- workspace roots being first-class `workspace_nodes`;
- designated folders already existing as protected schema state;
- `WorkspaceMetaRepository` already covering the read-side metadata needed for default-workspace and designated-folder lookup.

This PR is where service-routing and designated reassignment semantics land. It should not re-specify migration/backfill behavior from `PR-0408`.

增强 TreeService（签名修复、保护规则、move 硬约束），引入 CreationService 统一 atom 创建路由（`resolve_creation_role` + `origin_workspace_id` 事务写入），实现 `reassign_designated` repo/service 层。

前置条件：PR-0408（需要 Migration 0012 的 schema 和系统节点）

## Execution Contract (Canonical Inputs)

Shared promotion register:

- `docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md`
- This PR must leave evidence sufficient for `CPR-001`, but may not publish carrier text directly.

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q2-Q4 | TreeService 增强、CreationService 设计、保护规则 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md` Q9、Q12 | 系统节点保护规则、designated folder 语义 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0410 行）、Q4（Service 测试） | PR 定位、测试要求 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md` Q6 | 创建路由优先级 |
| Handoff workflow | `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` | `DOC-023 / DI-15` + `DOC-024 / DI-16` + `DOC-026 / DI-18` 的交接合同；本 PR 负责更新 `service-routing` 与 service 侧 `migration-protection` ledger，同时更新 `execution-order` 与 `verification-gates` rows，并显式消费 `OI-035`、`OI-036`、`OI-045`、以及本 PR 负责的 `OI-048` 部分，不得直接发布 ADR / ruling / topic-map carrier |

## Scope

In scope:
- `get_ancestor_path` 签名修复（DI-16 Q2）
- `list_atom_refs_for_atom` 新方法
- TreeService 保护规则：系统节点不可删除/移出
- move 硬约束：不可移入非本 workspace
- CreationService：`resolve_creation_role` 优先级（指定 folder > designated > root）+ `origin_workspace_id` 事务写入（DI-16 Q3）
- `reassign_designated` repo 方法 + service 层实现（DI-16 Q4）
- 跨 workspace 保护
- Service 层测试
- 更新 `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` 中 `service-routing`、service 侧 `migration-protection`、`execution-order`、以及本 PR 负责的 `verification-gates` rows，显式对齐 `OI-035` / `OI-036` / `OI-045` / `OI-048`，写入 landed/partial 状态与证据路径

Out of scope:
- ScopedQueryRepository（PR-0409）
- Guard / FFI（PR-0411）
- Flutter 层变更（PR-0412/6）
- 直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `docs/architecture/adr/topic-map.md`

## Design

### 1. TreeRepo 层：签名修复 + 新查询方法（T1）

#### 1.1 `get_ancestor_path` 签名修复（DI-16 Q4.4）

当前 `ancestor_path` 按 `atom_uuid` 查路径，同一 atom 有多个 `atom_ref` 时无法确定唯一路径。修正后按 `node_uuid` 查，消费方（Editor 面包屑）已持有当前打开的具体节点 ID：

```rust
// 旧（v0.3）— tree_repo.rs TreeRepository trait
fn ancestor_path(&self, atom_uuid: AtomId) -> TreeRepoResult<Vec<String>>;

// 新（v0.4）
fn get_ancestor_path(&self, node_uuid: WorkspaceNodeId)
    -> TreeRepoResult<Vec<(WorkspaceNodeId, String)>>;
```

返回类型从 `Vec<String>` 改为 `Vec<(WorkspaceNodeId, String)>`，提供结构化路径（workspace root → 直接父节点方向），支持 Flutter 层点击导航。

#### 1.2 `list_atom_refs_for_atom` 新方法（DI-16 Q2.3）

按 `atom_uuid` 查该 atom 在所有 workspace 树中的出现位置。归入 `TreeRepository` trait（操作对象是 `workspace_nodes`，纯树读查询）：

```rust
pub struct AtomRefLocation {
    pub node_uuid: WorkspaceNodeId,
    pub workspace_id: WorkspaceNodeId,   // 所属 workspace root 的 node_uuid
    pub path: String,                    // workspace root → 该 ref 的路径，纯展示
    pub display_name: String,
}

// TreeRepository trait 新增
fn list_atom_refs_for_atom(&self, atom_uuid: AtomId)
    -> TreeRepoResult<Vec<AtomRefLocation>>;
```

SQL：先 `WHERE atom_uuid = ? AND kind = 'atom_ref'` 收集所有 ref，每条向上 CTE 拼路径。单 atom 通常 1-3 个 ref，逐条上溯可接受。`workspace_id` 通过向上遍历祖先链到 `kind = 'workspace'` 的节点获取。

---

### 2. TreeService 增强：保护规则 + move 硬约束（T2）

#### 2.1 泛型签名扩展（DI-16 Q4.3）

TreeService 增加 `W: WorkspaceMetaRepository` 泛型参数，用于 designated folder 状态查询：

```rust
pub struct TreeService<R: TreeRepository, W: WorkspaceMetaRepository> {
    repo: R,
    workspace_meta: W,
}
```

`WorkspaceMetaRepository` 提供的保护相关方法（由 PR-0408 的 `workspace_meta_repo.rs` 实现）：

```rust
fn is_designated(&self, node_uuid: WorkspaceNodeId) -> Result<bool>;
fn resolve_designated(&self, workspace_id: WorkspaceNodeId, role: &str)
    -> Result<Option<WorkspaceNodeId>>;
fn reassign_designated(&self, workspace_id: WorkspaceNodeId, role: &str,
    new_node_uuid: WorkspaceNodeId) -> Result<()>;
```

#### 2.2 新增 `TreeServiceError` 变体（DI-16 Q4.1）

```rust
/// Cannot delete or move workspace root node.
WorkspaceRootProtected(WorkspaceNodeId),
/// Cannot delete a designated folder; reassign role to another folder first.
DesignatedFolderProtected(WorkspaceNodeId),
/// Cannot move workspace root node.
CannotMoveWorkspaceRoot(WorkspaceNodeId),
/// Node cannot be moved to root level (parent=None reserved for workspace roots).
CannotMoveToRoot(WorkspaceNodeId),
/// Move rejected: source and target parent belong to different workspace trees.
CrossWorkspaceMoveNotAllowed {
    node_uuid: WorkspaceNodeId,
    target_parent: WorkspaceNodeId,
},
```

#### 2.3 保护规则一览表（DI-16 Q4.1）

| 操作 | workspace root (`kind='workspace'`) | designated folder | 普通节点 |
|------|--------------------------------------|-------------------|---------|
| `delete_folder` | 拦截 → `WorkspaceRootProtected` | 拦截 → `DesignatedFolderProtected` | 放行 |
| `move_node`（同 workspace） | 拦截 → `CannotMoveWorkspaceRoot` | 放行（仅改位置，不改映射） | 放行 |
| `move_node`（跨 workspace） | 拦截 → `CrossWorkspaceMoveNotAllowed` | 拦截 → `CrossWorkspaceMoveNotAllowed` | 拦截 → `CrossWorkspaceMoveNotAllowed` |
| `move_node`（`new_parent=None`） | 拦截 → `CannotMoveToRoot` | 拦截 → `CannotMoveToRoot` | 拦截 → `CannotMoveToRoot` |

DB 触发器（由 Migration 0012 创建）保留为最终兜底防线；Service 层前置检查提供语义清晰的错误变体，便于 FFI 层映射结构化错误码（DI-16 Q4.1 理由）。

#### 2.4 跨 workspace 判断逻辑

`move_node` 的跨 workspace 检查：向上遍历被移动节点和目标 parent 的祖先链，各自找到第一个 `kind = 'workspace'` 的祖先节点（即所属 workspace root）。若两者的 workspace root `node_uuid` 不同，拒绝操作返回 `CrossWorkspaceMoveNotAllowed`。

跨 workspace 移动不走 `move_node`；未来跨 workspace 迁移走专用 transfer/copy API。

#### 2.5 `move_node` 硬约束说明（DI-16 Q4.1）

`new_parent_uuid = None` 在 v0.4 中对普通节点无条件拒绝。`parent_uuid IS NULL` 只有 workspace root 节点（`kind = 'workspace'`）才合法；普通节点移到 None 会脱离所有 workspace 树，ScopedAtomQuery 的 CTE 从 workspace root 出发永远遍历不到该节点。

---

### 3. CreationService 重构：统一创建路由 + `origin_workspace_id`（T3）

#### 3.1 请求模型（DI-16 Q3.1）

```rust
pub struct CreateAtomRequest {
    pub workspace_id: WorkspaceNodeId,             // 必传，定位 workspace
    pub content: String,
    pub content_type: String,                       // v0.4 白名单：仅接受 "markdown"
    pub task_status: Option<TaskStatus>,            // 有值 → view_hint 推导为 Task
    pub start_at: Option<i64>,                      // 时间属性，影响路由推导
    pub end_at: Option<i64>,
    pub tags: Option<Vec<String>>,                  // 创建时原子绑定 tag，同事务
    pub target_folder: Option<WorkspaceNodeId>,     // 显式路由目标；None → 按属性推导
    pub display_name: Option<String>,               // atom_ref 展示名；None → derive_title
}
```

`view_hint` 不作为输入字段，由 S1 R3 内部推导（`task_status` 优先规则）。`origin_workspace_id` 由 CreationService 自动填入 `workspace_id`（DI-15 Q10），不由调用方传入。

#### 3.2 `resolve_creation_role` 路由函数（DI-16 Q3.2 + DI-12 Q6）

路由优先级（高 → 低）：

| 优先级 | 条件 | 目标 |
|--------|------|------|
| 1（最高） | `request.target_folder = Some(_)` | 显式指定的 folder（直接使用，跳过推导） |
| 2 | `task_status.is_some()` | `designated_folders WHERE role = 'tasks'` |
| 3 | `start_at.is_some() \|\| end_at.is_some()` | `designated_folders WHERE role = 'calendar'` |
| 4（兜底） | 以上均不满足 | `designated_folders WHERE role = 'inbox'` |

```rust
/// 纯函数：根据 request 属性推导 designated folder role（DI-16 Q3.2）
fn resolve_creation_role(request: &CreateAtomRequest) -> &str {
    if request.task_status.is_some() { "tasks" }
    else if request.start_at.is_some() || request.end_at.is_some() { "calendar" }
    else { "inbox" }
}
```

`target_folder` 为 `Some` 时跳过此函数，直接使用显式目标。`resolve_creation_role` 是纯函数，路由规则变更只改此函数，不影响事务/校验逻辑。

#### 3.3 创建流程（4 步事务，DI-16 Q3.2）

```
BEGIN IMMEDIATE;
  1. 校验：content_type 白名单、end_at >= start_at（两者都存在时）
  2. 推导 view_hint：按 S1 R3（task_status 优先 → Task；start_at/end_at → Event；其余 → Note）
  3. 路由 + 边界校验：
       target = request.target_folder
                .unwrap_or_else(|| workspace_meta.resolve_designated(
                    workspace_id, resolve_creation_role(&request)))
       // 跨 workspace 防护：校验 target 属于 workspace_id 的树
       // 失败 → CreationServiceError::TargetFolderNotInWorkspace
  4. 事务内执行：
       INSERT INTO atoms (... origin_workspace_id = workspace_id ...)
       INSERT INTO workspace_nodes (atom_ref → target folder)
       // if tags: INSERT atom_tags（同事务）
COMMIT;
```

`origin_workspace_id` 在 INSERT 时一次性写入，v0.4 写入但不消费（DI-15 Q10 C+）；字段打好数据基础，升级为应用层门禁或 v1.x 加密索引时无需改列。

#### 3.4 CreationService 泛型签名

```rust
pub struct CreationService<'conn> {
    conn: &'conn Connection,
}
```

现有 `CreationService` 通过 `&Connection` 持有连接并在内部构造 repo。v0.4 重构时在内部构造 `WorkspaceMetaRepository` 用于路由解析，保持外部接口一致（`conn` 注入模式不变）。

新增公开方法：

```rust
/// 统一创建入口：atom + atom_ref + optional tags，事务内完成（S4 ruling）。
pub fn create_atom(&self, request: &CreateAtomRequest)
    -> Result<(AtomId, WorkspaceNode), CreationServiceError>;
```

现有 `create_note_with_ref` / `create_task_with_ref` / `create_event_with_ref` 在 PR-0410 阶段保留，由 PR-0411（Guard+FFI expand 阶段）改为薄 wrapper 委托 `create_atom`，PR-0413（contract 阶段）移除。

---

### 4. WorkspaceMetaRepository：`reassign_designated` 实现（T4）

`WorkspaceMetaRepository` trait 由 PR-0408 引入（`workspace_meta_repo.rs`）。本 PR 为 `reassign_designated` 添加完整实现：

```rust
/// 将 role 重指定到同 workspace 下的另一个 active folder。
/// 不允许删除映射（DI-15 Q9.1），只允许 reassign。
/// 失败条件：new_node_uuid 不在 workspace_id 的树内 → CrossWorkspaceDesignated
///          new_node_uuid 的 kind != folder → DesignatedTargetMustBeFolder
fn reassign_designated(
    &self,
    workspace_id: WorkspaceNodeId,
    role: &str,
    new_node_uuid: WorkspaceNodeId,
) -> Result<()>;
```

实现要点：
- 先校验 `new_node_uuid` 属于 `workspace_id` 的子树（向上遍历祖先，确认 workspace root 匹配），防止旁路 SQL 绕过 DB 触发器
- 再执行 `UPDATE designated_folders SET node_uuid = ? WHERE workspace_id = ? AND role = ?`
- DB 触发器 `validate_designated_folder_workspace_update` 作为最终兜底（DI-15 Q9.1）

---

### 5. 数据流总结

```
[调用方传入 CreateAtomRequest]
        │
        ▼
CreationService::create_atom()
  ├── 校验 content_type / end_at >= start_at
  ├── 推导 view_hint（S1 R3）
  ├── 路由目标解析：
  │     target_folder Some ──────────────────────────┐
  │     target_folder None → resolve_creation_role() │
  │       → WorkspaceMetaRepository::resolve_designated() → folder_id
  │                                                   │
  ├── 跨 workspace 校验（folder_id 的祖先链确认属于 workspace_id）
  │                                                   │
  └── BEGIN IMMEDIATE 事务 ◄──────────────────────────┘
        ├── INSERT atoms (含 origin_workspace_id)
        ├── INSERT workspace_nodes (atom_ref → resolved folder)
        └── INSERT atom_tags (if tags present)
      COMMIT
```

```
[调用方传入 move_node(node_uuid, new_parent_uuid)]
        │
        ▼
TreeService::move_node()
  ├── new_parent_uuid == None → CannotMoveToRoot（硬拒绝）
  ├── get_node(node_uuid).kind == Workspace → CannotMoveWorkspaceRoot
  ├── 跨 workspace 校验（两端祖先链 workspace root 是否相同）
  │     不同 → CrossWorkspaceMoveNotAllowed
  └── 通过 → TreeRepository::move_node()（现有排序逻辑不变）

[调用方传入 delete_folder(folder_uuid, mode)]
        │
        ▼
TreeService::delete_folder()
  ├── get_node(folder_uuid).kind == Workspace → WorkspaceRootProtected
  ├── WorkspaceMetaRepository::is_designated(folder_uuid) == true
  │     → DesignatedFolderProtected（需先 reassign）
  └── 通过 → 现有 dissolve / delete_all 逻辑不变
```

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | `get_ancestor_path` 签名修复 + `list_atom_refs_for_atom` | `crates/lazynote_core/src/repo/tree_repo.rs` | TBD | — |
| T2 | Rust | TreeService 保护规则 + move 硬约束 | `crates/lazynote_core/src/service/tree_service.rs` | TBD | T1 |
| T3 | Rust | CreationService（`resolve_creation_role` + `origin_workspace_id` 写入） | `crates/lazynote_core/src/service/creation_service.rs` | TBD | — |
| T4 | Rust | `reassign_designated` repo + service | `crates/lazynote_core/src/repo/`, `crates/lazynote_core/src/service/` | TBD | — |
| T5 | Rust | 保护规则测试 + 创建路由优先级测试 + reassign 测试 | `crates/lazynote_core/tests/` | TBD | T2-T4 |

## Planned File Changes

- `[edit]` crates/lazynote_core/src/repo/tree_repo.rs (签名修复 + 新方法)
- `[edit]` crates/lazynote_core/src/repo/workspace_meta_repo.rs (`reassign_designated` repo 实现，DI-16 Q2)
- `[edit]` crates/lazynote_core/src/service/tree_service.rs (保护规则 + move 硬约束)
- `[edit]` crates/lazynote_core/src/service/creation_service.rs (resolve_creation_role 优先级 + origin_workspace_id 写入)
- `[edit]` crates/lazynote_core/src/service/mod.rs (导出)
- `[add]` crates/lazynote_core/tests/tree_service_protection_test.rs (或合入现有测试文件)

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
# 验证 CreationService 存在
grep -rn "resolve_creation_role" crates/lazynote_core/src/ --include="*.rs"
# 预期：函数定义 + 至少一处调用

# 验证保护规则
grep -rn "system_node\|designated" crates/lazynote_core/src/service/tree_service.rs
# 预期：保护逻辑相关匹配
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 创建路由优先级边界情况（无 designated folder 时 fallback） | LOW | `resolve_creation_role` 优先级链有明确 fallback 到 root |
| move 硬约束与现有 move 测试冲突 | LOW | 新约束仅限跨 workspace，当前只有单 workspace |

## Acceptance Criteria

- [ ] `get_ancestor_path` 签名修复完成
- [ ] `list_atom_refs_for_atom` 方法可查询 atom 在树中的所有引用
- [ ] 系统节点不可通过 TreeService 删除
- [ ] 系统节点不可通过 TreeService 移出 workspace
- [ ] move 操作拒绝跨 workspace 移动
- [ ] `resolve_creation_role` 优先级：指定 folder > designated > root
- [ ] CreationService 事务内写入 `origin_workspace_id`
- [ ] `reassign_designated` repo/service 实现可重新指定 designated folder
- [ ] CreationService 拒绝跨 workspace 创建
- [ ] 现有 TreeService 测试全绿（语义不变回归）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `service-routing` row 已更新为本 PR 的实际落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `migration-protection` row 已写明本 PR 覆盖的 runtime / service 保护部分与证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `execution-order` row 已更新为本 PR 的实际顺序与依赖落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `verification-gates` row 已写明本 PR 覆盖的 service-test 部分与证据路径
- [ ] 本 PR 未直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `topic-map.md`
- [ ] PR spec Status updated to Merged
