# PR-0411: AccessGuard 体系 + FFI 新增（Expand 阶段）

- Proposed title: `feat(ffi): access guard architecture and new guarded FFI functions`
- Status: Merged

## Implementation Snapshot (2026-03-15)

Current branch status for `PR-0411`:

- guarded caller plumbing is landed in Rust Core via `CallerContext`,
  `CallerIdentity`, `AccessGuard`, `NoopGuard`, and `GuardedServiceError`
- guarded facades are landed for query, creation, atom, task, tree, and
  workspace access
- new guarded FFI exports are landed for scoped query, canonical creation, and
  workspace-facing navigation/designated operations
- guarded workspace designated lookup now distinguishes
  `workspace_not_found` from `designated_role_not_found`
- 14 expand-stage legacy wrappers now delegate through guarded exports or
  guarded facades; `entry_search` remains a thin documented FTS compatibility
  bridge so legacy ranking/snippet semantics stay intact without parallel
  business logic
- FRB bindings were regenerated after the guarded export surface was introduced

Important boundary:

- `guarded-ffi` is landed in this branch
- `security-surface` is not yet fully landed because runtime still defaults to
  `NoopGuard`; denial-path coverage exists, but production enforcement remains
  deferred

Downstream ownership that remains unchanged:

- `PR-0411A` owns structure-only cleanup of `crates/lazynote_ffi/src/api.rs`
- `PR-0413` owns contract-stage removal of the expand-stage legacy wrappers

## Verification Snapshot (2026-03-15)

Implementation verification executed on this branch:

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1`
- `cd apps/lazynote_flutter && dart format --output=none --set-exit-if-changed .`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`
- `dart run tools/ci/architecture_check.dart`

Key verification evidence now in-repo:

- `crates/lazynote_core/tests/guard_test.rs`
- `crates/lazynote_ffi/src/api.rs` guarded-export tests
- `crates/lazynote_ffi/src/api.rs`
  `workspace_resolve_designated_returns_workspace_not_found_for_unknown_workspace`
- `crates/lazynote_ffi/src/api.rs`
  `ffi_query_atoms_maps_cross_workspace_deny_guard_error_code`
- `crates/lazynote_ffi/src/api.rs`
  `ffi_atom_create_maps_insufficient_capability_guard_error_code`
- `crates/lazynote_ffi/src/api.rs` `legacy_wrapper_*_preserves_contract` tests
- `crates/lazynote_ffi/src/api.rs`
  `legacy_wrapper_bodies_delegate_to_approved_surfaces`

## Goal

### Dependency Clarification (2026-03-13)

This PR assumes `PR-0409` and `PR-0410` already consume the post-`0012` schema contract from `PR-0408`. At the FFI boundary, the schema should therefore be treated as an upstream fact, not a design surface to reopen.

Canonical implication:

- guarded FFI consumes workspace-aware query and creation services;
- designated-folder lookup is consumed through repository/service contracts, not raw schema access;
- `PR-0411` must not add migration-specific fallback logic.

### Additional Handoff From PR-0410 (2026-03-15)

`PR-0410` leaves these upstream Rust Core contracts ready for guarded export:

- canonical tree navigation now lives in `TreeService` as:
  - `get_ancestor_path(node_uuid)`
  - `list_atom_refs_for_atom(atom_uuid)`
- `reassign_designated(...)` is now a service-level operation, not a schema-only assumption;
- `CreationService::create_atom(CreateAtomRequest)` is the canonical business write path;
- the old atom-based `workspace_ancestor_path(atom_id)` path remains temporary compatibility only and should not be expanded into new public surface.

Implication for `PR-0411`:

- guarded FFI should export the new node-based contracts and canonical creation request;
- error mapping should consume the service-level protection errors landed in `PR-0410`;
- guarded wrappers must preserve the `PR-0409` legacy-read bridge as compatibility behavior only, not as a new write path.

### Structural Cleanup Handoff (2026-03-15)

`PR-0411` should leave the FFI surface ready for downstream cleanup PR
`PR-0411A`.

`PR-0411A` owns the refactor-only split of `crates/lazynote_ffi/src/api.rs`
into an `api/` module tree without changing the public FFI contract.

引入 CallerContext + AccessGuard 体系，包装全套 Guarded*Service，新增 FFI 函数（`query_atoms`、`atom_create`、`workspace_resolve_designated` 等）。旧 FFI 保留为薄 wrapper（expand-contract 的 expand 阶段），保证 Flutter 侧编译通过。

前置条件：PR-0409 + PR-0410（需要 ScopedQueryRepository + CreationService + TreeService 增强）

## Why This PR Exists

当前 workspace execution 主链已经推进到“Core contract landed, FFI export pending”的位置：

- `PR-0408` 已落 schema、workspace metadata、designated folders、`origin_workspace_id` 与 trigger protection；
- `PR-0409` 已落 scoped subtree query engine，并保留 legacy root-scoped read bridge；
- `PR-0410` 已落 canonical creation path、service-side protection、node-based path/ref-location contract；
- workflow ledger 中 `guarded-ffi` 仍是 `pending`，`flutter-core` / `flutter-features` 也都以本 PR 的 FFI contract 为前置。

因此，`PR-0411` 不是重新设计 workspace model，而是把已经 landed 的 Rust Core contract 通过 guarded FFI 以 expand 方式稳定导出，并为 `PR-0412` / `PR-0413` 保留兼容过渡层。

## Upstream Facts To Consume

### `PR-0408` 和 `PR-0410` 已经保证的事实

- workspace-aware schema 已经存在，designated folders 是 schema truth；
- `CreationService::create_atom(CreateAtomRequest)` 已经是 canonical business write path；
- `TreeService` 已经提供：
  - `get_ancestor_path(node_uuid)`
  - `list_atom_refs_for_atom(atom_uuid)`
  - `reassign_designated(...)`
- service-side protection 已经覆盖 workspace root delete/move、designated folder delete、cross-workspace move、move-to-root。

### `PR-0409` bridge 的当前边界

- `ScopedQueryRepository` 已经是 canonical read engine；
- legacy root-scoped visibility 仍通过 `PR-0409` bridge 保持；
- 本 PR 只能“显式消费并导出这层兼容”，不能重新把它扩散成新写路径或新的 schema fallback。

### 本 PR 在 workflow 中必须消费的 rows

| Workflow Row | 本 PR 责任 |
|------|------|
| `guarded-ffi` | 落地 guarded export contract 并写入证据路径 |
| `security-surface` | 只有在实际接入非-Noop 的 origin-aware gate 时才允许标记 landed；否则保留 `pending`/`partial` 并解释原因 |
| `execution-order` | 记录 expand-stage 已落地、contract-stage 清理仍待 `PR-0413` |
| `cutover-cleanup` | 明确本 PR 保留 legacy wrappers，删除责任留给 `PR-0413` |
| `api-doc-ownership` | 同步 `ffi-contracts.md`、`API_COMPATIBILITY.md`、`error-codes.md` |
| `verification-gates` | 回填 FFI、新 wrapper、DenyGuard、binding regen 与 Flutter compile-validation 证据 |

## Execution Contract (Canonical Inputs)

Shared promotion register:

- `docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md`
- This PR must leave evidence sufficient for `CPR-001`, but may not publish carrier text directly.

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` Q5-Q6 | Guard 设计、FFI 函数清单、expand-contract 策略 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0411 行）、Q2（expand-contract）、Q4（FFI 测试 + DenyGuard） | PR 定位、迁移策略、测试要求 |
| 规范源 | `docs/api/ffi-contracts.md` | 需更新：新增 FFI 函数契约 |
| 规范源 | `docs/governance/API_COMPATIBILITY.md` | 需更新：expand-stage coexistence 与 `PR-0413` removal handoff |
| 现有实现 | `crates/lazynote_ffi/src/api.rs` | 需修改的目标文件 |
| Handoff workflow | `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` | `DOC-023 / DI-15` + `DOC-024 / DI-16` + `DOC-026 / DI-18` 的交接合同；本 PR 负责更新 `guarded-ffi` 与已实际落地的 `security-surface` ledger，同时更新 `execution-order`、`cutover-cleanup`、`api-doc-ownership`、以及本 PR 负责的 `verification-gates` rows，并显式消费 `OI-037`、`OI-038`、`OI-045`、`OI-046`、`OI-047`、`OI-048`，不得直接发布 ADR / ruling / topic-map carrier |

## Scope

In scope:
- CallerContext struct
- AccessGuard trait + NoopGuard 默认实现
- Guarded*Service 全套包装
- FFI 新函数：`query_atoms`、`atom_create`、`workspace_resolve_designated`、`workspace_reassign_designated` 等
- 旧 FFI 函数改为薄 wrapper（内部委托到 Guarded*Service / guarded export；
  `entry_search` 保留为薄 FTS compatibility bridge）
- FRB 绑定重生成
- DenyGuard 测试专用实现
- 更新 `docs/api/ffi-contracts.md`（新函数）
- 更新 `docs/governance/API_COMPATIBILITY.md`（expand-stage compatibility note，而非旧接口移除）
- 更新 `docs/api/error-codes.md`（新增 Guard 相关错误码，DI-16 要求）
- 更新 `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` 中 `guarded-ffi`、如有实际安全落地则更新 `security-surface`、以及 `execution-order` / `cutover-cleanup` / `api-doc-ownership` / 本 PR 负责的 `verification-gates` rows，显式对齐 `OI-037` / `OI-038` / `OI-045` / `OI-046` / `OI-047` / `OI-048`，写入 landed/partial 状态与证据路径

Out of scope:
- 旧 FFI 函数移除（PR-0413 contract 阶段）
- Flutter 消费方变更（`PR-0412` / `PR-0413`）
- 直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `docs/architecture/adr/topic-map.md`

## Canonical Delivery Decisions

### 1. 本 PR 落 guard architecture，不默认宣称 security enforcement 已 landed

`NoopGuard` 是 v0.4 的默认运行时实现。它负责把 caller plumbing、Guarded facade、错误映射、测试注入点和后续 origin-aware gate 的插槽立起来，但它本身不构成“安全门禁已在生产态启用”。

因此：

- `guarded-ffi` row 可以在本 PR 落地后标记 `landed`；
- `security-surface` row 只有在本 PR 真的把非-Noop 的 origin-aware policy 接入默认路径时才允许标记 `landed`；
- 若本 PR 只落 architecture + DenyGuard tests，则 `security-surface` 应保持 `pending` 或 `partial`，并明确说明“guard scaffolding landed, production enforcement deferred”。

### 2. 新 FFI surface 是 additive export；旧 surface 只收窄为 compatibility wrapper

本 PR 的 expand-stage 规则是：

1. 新增 guarded FFI 函数；
2. 旧函数签名全部保留；
3. 旧函数内部只能做一次 Guarded facade/export 委托，或进入一次已文档化
   的 compatibility bridge（当前仅 `entry_search -> legacy_entry_search_via_fts`），
   不保留独立业务逻辑；
4. 旧函数删除、rename、contract-stage cleanup 统一留给 `PR-0413`。

这意味着本 PR 不应在 release 语义上制造 breaking removal。

### 3. `API_COMPATIBILITY.md` 在本 PR 记录的是“expand-stage coexistence”，不是 breaking change

由于旧接口仍然保留，本 PR 对兼容性的要求是：

- 新接口及其 caller contract 被正式记录；
- 旧接口进入 compatibility wrapper 状态；
- `PR-0413` 才是 contract-stage removal 的 breaking surface。

所以本 PR 应更新 `docs/governance/API_COMPATIBILITY.md` 的共存/迁移说明，而不是把本次落地写成“旧接口已 break”。

### 4. Guard 只包在 FFI/export boundary 外侧，不反向污染 Inner Service

`CallerContext` 与 `AccessGuard` 只存在于 guarded facade 和 FFI adapter 边界：

- Inner Service 继续只接业务参数；
- workspace 目标解析由 request 或 node/workspace lookup 得出；
- Guard 决策不进入 `CreationService` / `TreeService` / `TaskService` 的纯业务签名。

### 5. `PR-0411A` 只承接结构整理，不承接本 PR 未完成的行为责任

本 PR 必须先把 guarded contract、docs、tests、binding regen 和 wrapper cutover 落完整。`PR-0411A` 只负责把已经 landed 的 `api.rs` 结构拆开，不能替代本 PR 补行为或补验证。

## Design

### 总体架构：三层结构

PR-0411 在 Rust Core 和 FFI 之间建立三层结构，是 expand-contract 迁移的 expand 阶段：

```
Flutter / FFI 入口层
  ↓ CallerContext + 业务参数
Guarded*Service（访问控制壳，本 PR 新增）
  ↓ 校验通过后，只传业务参数
Inner Service（PR-0409/0410 已就绪的 TaskService / CalendarService / CreationService / TreeService）
```

### 1. CallerContext + AccessGuard 体系

**CallerContext 结构体**（新增到 `crates/lazynote_core/src/guard/mod.rs`）：

```rust
pub struct CallerContext {
    pub identity: CallerIdentity,
    pub scope_workspace_id: Option<WorkspaceId>,  // 调用方声明的权限范围；None = 未限定
}

pub enum CallerIdentity {
    App,  // Flutter app（v0.4 唯一值）
}
```

`scope_workspace_id` 是调用方权限范围声明，不是业务目标。v0.4 Flutter 传 `Some(default_workspace_id)`。业务目标 workspace 由各 Service 方法的业务参数（如 `request.workspace_id`）传递，两者不互相替代。

**AccessGuard trait**：

```rust
pub trait AccessGuard {
    fn check_read(
        &self,
        caller: &CallerContext,
        target_workspace: &WorkspaceId,
    ) -> Result<(), AccessError>;

    fn check_write(
        &self,
        caller: &CallerContext,
        target_workspace: &WorkspaceId,
    ) -> Result<(), AccessError>;
}

pub enum AccessError {
    CrossWorkspaceAccessDenied { scope: WorkspaceId, target: WorkspaceId },
    InsufficientCapability { identity: CallerIdentity, required: Capability },
}

pub enum Capability {
    WorkspaceRead,
    WorkspaceWrite,
}
```

**v0.4 默认实现 `NoopGuard`**：运行时 pass-through，透明放行。选运行时 `Box<dyn AccessGuard>` 而非编译期泛型单态化，以支持未来可运行时切换 guard（debug 模式、feature flag），并避免泛型爆炸。

```rust
pub struct NoopGuard;

impl AccessGuard for NoopGuard {
    fn check_read(&self, _: &CallerContext, _: &WorkspaceId) -> Result<(), AccessError> { Ok(()) }
    fn check_write(&self, _: &CallerContext, _: &WorkspaceId) -> Result<(), AccessError> { Ok(()) }
}
```

**测试专用 `DenyGuard`**：拒绝所有请求，验证 Guard 拒绝路径与错误码映射实际生效（DI-18 Q4 裁决）：

```rust
// tests/guard_test.rs
pub struct DenyGuard;

impl AccessGuard for DenyGuard {
    fn check_read(&self, _: &CallerContext, _: &WorkspaceId) -> Result<(), AccessError> {
        Err(AccessError::CrossWorkspaceAccessDenied { ... })
    }
    fn check_write(&self, _: &CallerContext, _: &WorkspaceId) -> Result<(), AccessError> {
        Err(AccessError::CrossWorkspaceAccessDenied { ... })
    }
}
```

### 2. Guarded*Service 全套包装

每个 Inner Service 有对应的 Guarded\* 包装层，模式统一：

| Facade | Inner Service | 负责操作 |
|--------|--------------|---------|
| `GuardedQueryService` | `ScopedQueryRepository`（委托） | `query_atoms` |
| `GuardedCreationService` | `CreationService<A, R, W>` | `atom_create` |
| `GuardedAtomService` | `AtomRepository` | `atom_get`、`atom_update_content`、`atom_set_tags`、`atom_update_time` |
| `GuardedTaskService` | `TaskService<S, W, A>` | `atom_update_status` |
| `GuardedTreeService` | `TreeService<R, W>` | 树结构 CRUD + `get_ancestor_path`、`list_atom_refs_for_atom`、`reassign_designated` |
| `GuardedWorkspaceService` | `WorkspaceMetaRepository` | `workspace_list`、`workspace_get_default`、`workspace_resolve_designated` |

包装层结构示例：

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
        new_parent_uuid: WorkspaceNodeId,
        target_order: Option<i64>,
    ) -> Result<(), TreeServiceError> {
        let target_workspace = self.inner.resolve_workspace_for_node(&node_uuid)?;
        self.guard.check_write(caller, &target_workspace)?;
        self.inner.move_node(node_uuid, new_parent_uuid, target_order)
    }
}
```

**硬规则**：Guard 只认 `request.workspace_id` 或从节点 UUID 解析出的 workspace 作为权限校验目标（业务真值）。若 `caller.scope_workspace_id` 存在且与目标不符，则拒绝。Inner Service 方法签名不含 `CallerContext`，纯业务逻辑不耦合鉴权。

### 3. 新增 FFI 函数

所有新增函数均以 `caller: FfiCallerContext` 为首参数（DI-16 Q5 裁决）。

**CallerContext FFI 类型**（FRB 生成对应 Dart 类）：

```rust
pub struct FfiCallerContext {
    pub identity: FfiCallerIdentity,
    pub scope_workspace_id: Option<String>,
}

pub enum FfiCallerIdentity { App }
```

#### 3.1 统一查询入口 `query_atoms`

```rust
pub enum FfiTimeFilterKind { Any, Timeless, Range }
pub enum FfiTimeShapeFilter { Any, BoundedOnly }
pub enum FfiStatusFilterKind { Any, ActiveOnly, TaskStatuses }
pub enum FfiSortSpec { UpdatedAtDesc, StartAtAsc, TitleAsc }
pub enum FfiProjectionMode { Atom, Ref }
pub enum FfiViewHint { Note, Task, Event }
pub enum FfiTaskStatus { Todo, InProgress, Done, Cancelled }

pub struct FfiScopedAtomQuery {
    pub folder_id: String,
    pub view_hint: Option<FfiViewHint>,
    pub time_filter: FfiTimeFilterKind,
    pub time_start_ms: Option<i64>,           // Range 时必填
    pub time_end_ms: Option<i64>,             // Range 时可选（None = 无上界）
    pub time_shape: FfiTimeShapeFilter,
    pub status_filter: FfiStatusFilterKind,
    pub task_statuses: Option<Vec<FfiTaskStatus>>,
    pub tag: Option<String>,
    pub text_query: Option<String>,
    pub include_path: bool,
    pub include_overdue_deadlines: bool,       // Today 场景设 true，触发 overdue T1 补偿
    pub sort: FfiSortSpec,
    pub limit: u32,
    pub offset: u32,
}

pub async fn query_atoms(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse
```

FFI 适配器内部流程：反序列化 `FfiCallerContext` → `CallerContext`；反序列化 `FfiScopedAtomQuery` → `ScopedAtomQuery`（含参数校验：`include_overdue_deadlines = true` 仅在 `time_filter = Range` 时合法，否则返回 `invalid_query_descriptor`；`Range` 时 `time_start_ms` 必填）；调 `GuardedQueryService::query`；序列化结果为 `ScopedQueryResponse`。

#### 3.2 统一创建入口 `atom_create`

```rust
pub struct FfiCreateAtomRequest {
    pub workspace_id: String,
    pub content: String,
    pub content_type: String,                  // "markdown"（白名单）
    pub task_status: Option<FfiTaskStatus>,
    pub start_at: Option<i64>,
    pub end_at: Option<i64>,
    pub tags: Option<Vec<String>>,
    pub target_folder: Option<String>,         // None → 按属性推导 designated folder
    pub display_name: Option<String>,          // None → derive_title 推导
}

pub async fn atom_create(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
) -> AtomCreateResponse
```

#### 3.3 Workspace 管理函数（新增）

```rust
pub async fn workspace_list(caller: FfiCallerContext) -> WorkspaceListResponse

pub async fn workspace_get_default(caller: FfiCallerContext) -> WorkspaceInfoResponse

pub async fn workspace_resolve_designated(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,                              // "inbox" | "tasks" | "calendar"
) -> DesignatedFolderResponse

pub async fn workspace_reassign_designated(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,
    new_node_uuid: String,
) -> WorkspaceActionResponse
```

#### 3.4 树导航函数（新增）

```rust
pub async fn workspace_get_ancestor_path(
    caller: FfiCallerContext,
    node_uuid: String,
) -> AncestorPathResponse

pub async fn workspace_list_atom_refs_for_atom(
    caller: FfiCallerContext,
    atom_uuid: String,
) -> AtomRefLocationsResponse
```

### 4. 旧 FFI 函数改为薄 Wrapper（Expand 阶段）

15 个旧 FFI 函数的函数签名全部保留（Flutter 侧编译不受影响），函数体替换为对 Guarded\*Service 的单次委托调用，剥离原有逻辑：

| 旧 FFI 函数 | 类别 | 委托到的 Guarded\*Service 方法 |
|------------|------|-------------------------------|
| `tasks_list_inbox` | 查询 | `GuardedQueryService::query`（`TimeFilter::Timeless` + `StatusFilter::ActiveOnly`，`role='tasks'` 解析 folder） |
| `tasks_list_today` | 查询 | `GuardedQueryService::query`（`TimeFilter::Range(bod, Some(eod))` + `include_overdue_deadlines=true`） |
| `tasks_list_upcoming` | 查询 | `GuardedQueryService::query`（`TimeFilter::Range(eod, None)` + 锚点前移） |
| `calendar_list_by_range` | 查询 | `GuardedQueryService::query`（`TimeFilter::Range` + `TimeShapeFilter::Any`） |
| `notes_list` | 查询 | `GuardedQueryService::query`（`view_hint=Note`） |
| `entry_search` | 查询 | `legacy_entry_search_via_fts`（保留 legacy FTS `bm25` 排序与 snippet 语义，直到 `PR-0413` 删除旧入口） |
| `atoms_list_timed` | 查询 | `GuardedQueryService::query`（`TimeFilter::Any` 排除 Timeless） |
| `entry_create_note` | 创建 | `GuardedCreationService::create_atom`（`content_type=markdown`） |
| `entry_create_task` | 创建 | `GuardedCreationService::create_atom`（`task_status=Some(Todo)`） |
| `entry_schedule` | 创建 | `GuardedCreationService::create_atom`（`start_at/end_at` 填充） |
| `note_create` | 创建 | `GuardedCreationService::create_atom`（`target_folder` 透传） |
| `note_update` | 写入 | `GuardedAtomService::update_content` |
| `note_set_tags` | 写入 | `GuardedAtomService::set_tags` |
| `calendar_update_event` | 写入 | `GuardedAtomService::update_time` |
| `note_get` | 读取 | `GuardedAtomService::get` |

除 `entry_search` 外，其余旧 wrapper 都在内部构造默认
`CallerContext { identity: App, scope_workspace_id: None }` 传入
Guarded\*Service / guarded export，保持无 caller 参数时的 v0.3 行为不变。
`entry_search` 则保留 legacy FTS compatibility bridge，以避免在 expand
阶段提前改变排序和 snippet 合同。

**wrapper 形式约束**（Review checklist R1）：每个旧函数内部只有一次
Guarded\*Service/guarded export 委托，或一次已文档化的 compatibility
bridge 调用，不残留原有业务逻辑。

**可复放验证约束**：这条规则不能只靠 reviewer 肉眼检查。实现阶段必须补一组
legacy wrapper parity tests，按旧 FFI inventory 一一对应，证明每个 wrapper
仍保持当前 envelope/行为，同时没有保留第二套独立业务分支。

建议测试命名约定：

- `legacy_wrapper_tasks_list_inbox_preserves_contract`
- `legacy_wrapper_tasks_list_today_preserves_contract`
- `legacy_wrapper_tasks_list_upcoming_preserves_contract`
- `legacy_wrapper_calendar_list_by_range_preserves_contract`
- `legacy_wrapper_notes_list_preserves_contract`
- `legacy_wrapper_entry_search_preserves_contract`
- `legacy_wrapper_atoms_list_timed_preserves_contract`
- `legacy_wrapper_entry_create_note_preserves_contract`
- `legacy_wrapper_entry_create_task_preserves_contract`
- `legacy_wrapper_entry_schedule_preserves_contract`
- `legacy_wrapper_note_create_preserves_contract`
- `legacy_wrapper_note_update_preserves_contract`
- `legacy_wrapper_note_set_tags_preserves_contract`
- `legacy_wrapper_calendar_update_event_preserves_contract`
- `legacy_wrapper_note_get_preserves_contract`

最低要求不是“名字存在”，而是 15 项旧入口各有一条 parity test，并进入可执行验证命令。

### 5. 新增响应类型

```rust
// 统一查询响应
pub struct ScopedQueryResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub items: Vec<ScopedAtomItem>,
}

pub struct ScopedAtomItem {
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
    pub representative_node_uuid: String,  // Atom 投影下非稳定；Ref 投影下稳定
    pub path: Option<String>,              // include_path=true 时填充
}

// 统一创建响应
pub struct AtomCreateResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub atom_uuid: Option<String>,
    pub node_uuid: Option<String>,
}

// 树导航响应
pub struct AncestorPathResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub segments: Vec<PathSegment>,   // root → target 方向
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

// Workspace 管理响应
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

### 6. 新增错误码

需注册到 `docs/api/error-codes.md`（DI-16 Q6.5）：

| 错误码 | 来源 | 场景 |
|--------|------|------|
| `invalid_query_descriptor` | Guard / FFI 适配器 | `FfiScopedAtomQuery` 参数校验失败 |
| `cross_workspace_access_denied` | `AccessError::CrossWorkspaceAccessDenied` | Guard 拒绝：caller scope 不覆盖目标 workspace |
| `insufficient_capability` | `AccessError::InsufficientCapability` | Guard 拒绝：identity 缺少所需 capability |
| `workspace_not_found` | `GuardedWorkspaceService` | 指定的 `workspace_id` 不存在 |
| `designated_role_not_found` | `GuardedWorkspaceService` | 指定的 role 在 `designated_folders` 无记录 |
| `invalid_content_type` | `GuardedCreationService` | 不支持的 `content_type`（非 `"markdown"`） |
| `target_folder_not_in_workspace` | `GuardedCreationService` | 创建时 `target_folder` 不属于指定 workspace |

### 7. Expand-Contract 迁移机制说明

```
PR-0411（Expand，本 PR）
  → 新增 Guarded*Service + 新增 FFI 函数（query_atoms、atom_create 等）
  → 旧 15 个 FFI 函数体替换为薄 wrapper（签名保留）
  → Flutter 侧编译通过，行为不变

PR-0412（Flutter core/feature 迁移，Flutter 侧使用新 FFI）
  → Flutter 消费方切换到新 FFI 函数

PR-0413（Contract，移除旧接口）
  → 移除 15 个旧 FFI wrapper + FRB 重生成
```

**中间态保证**：本 PR 合入后，Flutter 侧无需任何修改即可通过 `flutter analyze` 和 `flutter test`。旧函数内部的委托实现保证行为回归：现有集成测试全绿即视为 wrapper 语义正确。

## Executable Plan

### Chunk 1: 先写 RED 测试，锁定 guarded FFI contract

**目标**

- 先把 caller plumbing、DenyGuard 拒绝路径、新 FFI surface、旧 wrapper compatibility 写成失败测试；
- 避免后续在 `api.rs` 里边搬函数边重新决定 contract。

**优先测试面**

1. 新增 guarded FFI：
   - `query_atoms`
   - `atom_create`
   - `workspace_list`
   - `workspace_get_default`
   - `workspace_resolve_designated`
   - `workspace_reassign_designated`
   - `workspace_get_ancestor_path`
   - `workspace_list_atom_refs_for_atom`
2. DenyGuard：
   - read path 拒绝
   - write path 拒绝
   - 错误码映射正确
3. 旧 wrapper：
   - 旧入口仍可调用
   - 行为与当前测试基线一致
   - 不因 caller plumbing 破坏现有 response envelope
   - 15 项 legacy wrapper parity tests 先 RED，再随 cutover 一起转绿

**文件**

- `[edit]` `crates/lazynote_ffi/src/api.rs`
- `[add]` `crates/lazynote_core/tests/guard_test.rs`

**阶段出口**

```bash
cd crates
cargo test -p lazynote_ffi api::tests:: -- --nocapture
cargo test -p lazynote_core --test guard_test -- --nocapture
```

预期：先 RED，再进入实现。

### Chunk 2: 落 core-side guard scaffolding 与 guarded facades

**目标**

- 先把 `CallerContext`、`AccessGuard`、`NoopGuard`、`AccessError` 以及 Guarded facade 壳子搭起来；
- 保持 Inner Service 完全不引入 caller 参数。

**文件**

- `[add]` `crates/lazynote_core/src/guard/mod.rs`
- `[add]` `crates/lazynote_core/src/service/guarded_query_service.rs`
- `[add]` `crates/lazynote_core/src/service/guarded_creation_service.rs`
- `[add]` `crates/lazynote_core/src/service/guarded_atom_service.rs`
- `[add]` `crates/lazynote_core/src/service/guarded_task_service.rs`
- `[add]` `crates/lazynote_core/src/service/guarded_tree_service.rs`
- `[add]` `crates/lazynote_core/src/service/guarded_workspace_service.rs`
- `[edit]` `crates/lazynote_core/src/service/mod.rs`
- `[edit]` `crates/lazynote_core/src/lib.rs`

**阶段出口**

- 所有 Guarded facade 都能编译；
- `NoopGuard` 走通 happy path；
- `DenyGuard` 可被测试注入并稳定拒绝。

### Chunk 3: 落 FFI 新 surface 与旧 wrapper cutover

**目标**

- 在 `api.rs` 中导出新 guarded 函数；
- 把旧函数改成薄 wrapper；
- 旧 wrapper 每个入口只保留一次 Guarded facade/export 委托，或一次
  已文档化的 compatibility bridge 调用。

**文件**

- `[edit]` `crates/lazynote_ffi/src/api.rs`

**执行约束**

1. 新函数先落内部 `*_impl`；
2. 再落 FRB export；
3. 最后把旧函数替换为 compatibility wrapper；
4. 本 chunk 不拆 `api.rs` 结构，结构整理留给 `PR-0411A`。

**阶段出口**

- 新旧 FFI surface 可同时存在；
- 旧 surface 没有残留独立业务分支；
- 15 项 legacy wrapper parity tests 全部转绿；
- 现有 `api.rs` 回归测试保持可读并可通过。

### Chunk 4: FRB 绑定、Flutter compile-validation 与文档同步

**目标**

- 完成 bindings regen；
- 确认 Flutter 在“不改消费方”的前提下仍能 analyze / test；
- 同步 API 文档与 governance 文档。

**文件**

- `[regen]` `crates/lazynote_ffi/src/frb_generated.rs`
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/`
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `docs/api/error-codes.md`
- `[edit]` `docs/governance/API_COMPATIBILITY.md`

**文档收口要求**

- `ffi-contracts.md`：记录新入口和 caller contract；
- `error-codes.md`：记录新增 access/query descriptor 错误码；
- `API_COMPATIBILITY.md`：写明 expand-stage coexistence，不把本 PR 写成旧接口删除。

### Chunk 5: workflow ledger 与 closeout evidence 回填

**目标**

- 让 workflow 和 spec 对当前 landed 事实达成一致；
- 明确哪些 row 这轮能落、哪些只能保持 `partial`/`pending`。

**文件**

- `[edit]` `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0411-guard-ffi.md`

**回填规则**

- `guarded-ffi`：本 PR 完成后应 `landed`
- `security-surface`：只有默认路径接入实际非-Noop gate 才能 `landed`，否则写明原因并保持 `pending`/`partial`
- `execution-order`：写明 expand-stage 已落、contract-stage removal 仍待 `PR-0413`
- `cutover-cleanup`：写明 `PR-0411A` 只承接结构 cleanup
- `api-doc-ownership`：写入本 PR 已消费的 API 文档责任
- `verification-gates`：写入 FFI / DenyGuard / wrapper / binding regen / Flutter compile-validation 证据路径

## Planned File Changes

- `[add]` crates/lazynote_core/src/guard/mod.rs (CallerContext, AccessGuard trait, NoopGuard, AccessError, Capability)
- `[add]` crates/lazynote_core/src/service/guarded_query_service.rs (GuardedQueryService)
- `[add]` crates/lazynote_core/src/service/guarded_creation_service.rs (GuardedCreationService)
- `[add]` crates/lazynote_core/src/service/guarded_atom_service.rs (GuardedAtomService)
- `[add]` crates/lazynote_core/src/service/guarded_task_service.rs (GuardedTaskService)
- `[add]` crates/lazynote_core/src/service/guarded_tree_service.rs (GuardedTreeService)
- `[add]` crates/lazynote_core/src/service/guarded_workspace_service.rs (GuardedWorkspaceService)
- `[edit]` crates/lazynote_core/src/service/mod.rs (export guarded facades)
- `[edit]` crates/lazynote_core/src/lib.rs (re-export guard and guarded service contracts as needed)
- `[edit]` crates/lazynote_ffi/src/api.rs (新 FFI 函数 + 旧 FFI 改 wrapper)
- `[regen]` crates/lazynote_ffi/src/frb_generated.rs (FRB 自动生成)
- `[regen]` apps/lazynote_flutter/lib/core/bindings/ (FRB 自动生成)
- `[edit]` docs/api/ffi-contracts.md (新函数契约)
- `[edit]` docs/governance/API_COMPATIBILITY.md (expand-stage coexistence / removal handoff)
- `[edit]` docs/api/error-codes.md (新增 Guard 相关错误码)
- `[add]` crates/lazynote_core/tests/guard_test.rs (DenyGuard 测试)

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd ../apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Chunk replay commands

```bash
cd crates
cargo test -p lazynote_core --test guard_test -- --nocapture
cargo test -p lazynote_ffi api::tests:: -- --nocapture

powershell -NoProfile -ExecutionPolicy Bypass -File ..\\scripts\\gen_bindings.ps1

cd ..\\apps\\lazynote_flutter
flutter analyze
flutter test
```

### Structural verification

```bash
# 验证旧 FFI 函数已改为薄 wrapper（只有一次委托调用）
# 机械约束：15 项 legacy wrapper parity tests 必须存在并可执行

rg -n "legacy_wrapper_.*_preserves_contract" crates/lazynote_ffi/src/api.rs
# 预期：至少 15 匹配（1:1 对应旧 FFI inventory）

cargo test -p lazynote_ffi legacy_wrapper_ -- --nocapture
# 预期：15 项 wrapper parity tests 全绿

# 验证新 FFI 函数存在
rg -n "query_atoms|atom_create|workspace_resolve_designated" crates/lazynote_ffi/src/api.rs
# 预期：至少 3 匹配

# 验证 DenyGuard 测试存在
rg -n "DenyGuard|deny_guard" crates/lazynote_core/tests
# 预期：至少 1 匹配
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| FRB 重生成后 Flutter 编译失败 | MEDIUM | 旧 FFI 签名保留，先 replay bindings regen，再做 Flutter compile-validation |
| 将 NoopGuard 误写成“安全已落地” | MEDIUM | 在 spec / workflow 中显式区分 `guarded-ffi` 与 `security-surface` |
| Guard 架构引入过多 boilerplate | LOW | 先落统一 facade 模板，避免在 `api.rs` 内散落重复 guard 逻辑 |
| 旧函数 wrapper 内部逻辑遗留 | LOW | wrapper checklist：每个旧函数只允许一次 Guarded facade/export 委托，或一次已文档化 compatibility bridge |

## Acceptance Criteria

- [ ] CallerContext struct 定义完成
- [ ] AccessGuard trait 定义完成
- [ ] NoopGuard 默认实现
- [ ] Guarded*Service 全套包装正确委托到底层 Service
- [ ] FFI 新函数（`query_atoms`、`atom_create`、`workspace_resolve_designated`、`workspace_reassign_designated` 等）可调用
- [ ] 旧 FFI 函数改为薄 wrapper（内部仅一次 Guarded*Service/guarded export 委托，或一次已文档化 compatibility bridge 调用）
- [ ] 15 项 legacy wrapper parity tests 已按旧 FFI inventory 落齐
- [ ] DenyGuard 测试通过：拒绝路径返回预期错误
- [ ] DenyGuard 测试通过：错误码映射正确（如 `cross_workspace_access_denied`、`insufficient_capability`）
- [ ] 旧 FFI 函数行为不变（现有测试全绿）
- [ ] FRB 绑定重生成后 `flutter analyze` 零 warning
- [ ] `docs/api/ffi-contracts.md` 已更新新函数契约
- [ ] `docs/governance/API_COMPATIBILITY.md` 已记录 expand-stage coexistence 与 `PR-0413` cleanup handoff
- [ ] `docs/api/error-codes.md` 已注册新增错误码（如 `cross_workspace_access_denied`、`insufficient_capability`、`invalid_query_descriptor`）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `guarded-ffi` row 已更新为本 PR 的实际落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `security-surface` row 已明确写明本 PR 是否实际落地安全门禁；若未落地则保持 `pending`/`partial` 并附说明
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `execution-order` row 已更新为本 PR 的实际顺序与依赖落地状态并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `cutover-cleanup` row 已写明本 PR 覆盖的 expand 阶段与 cleanup 责任并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `api-doc-ownership` row 已写明本 PR 覆盖的 API 文档与兼容性文档更新责任并附证据路径
- [ ] `workspace-topology-carrier-promotion-workflow.md` 的 `verification-gates` row 已写明本 PR 覆盖的 FFI / DenyGuard 测试部分与证据路径
- [ ] 本 PR 未直接发布或改写 `DI-15` active bundle 的 ADR / ruling / `topic-map.md`
- [ ] PR spec `Status` updated to `Merged` after landing
