# PR-0410: TreeService 增强 + CreationService 收口

- Proposed title: `feat(core): land tree protection rules and designated creation routing`
- Status: Merged

## Implementation Update (2026-03-15)

The `PR-0410` landing slice is now represented in-repo by these concrete contracts:

- `TreeRepository` and `TreeService` expose canonical node-based path and ref-location helpers:
  - `get_ancestor_path(node_uuid)`
  - `list_atom_refs_for_atom(atom_uuid)`
- `TreeService` now enforces runtime protection above the `0012` schema guards:
  - reject workspace-root delete
  - reject workspace-root move
  - reject designated-folder delete until reassign
  - reject `move_node(..., None, ...)` for ordinary nodes
  - reject cross-workspace move
  - allow same-workspace `reassign_designated(...)`
- `CreationService` now exposes canonical business creation input via `CreateAtomRequest` and `create_atom(...)`.
- Business creation writes now route to explicit target folders or designated folders only; they no longer create new root-scoped refs.
- The `PR-0409` default-workspace compatibility bridge remains read-only legacy behavior for section queries. `PR-0410` consumes that bridge explicitly rather than extending it for new writes.

Downstream handoff for `PR-0411`:

- keep the old atom-based `workspace_ancestor_path(atom_id)` wrapper only as temporary compatibility surface;
- export node-based path and ref-location contracts through guarded FFI instead of reopening schema decisions;
- map the new service-side protection and creation errors at the FFI boundary without changing the Rust Core semantics landed here.

### Verification Snapshot (2026-03-15)

Passed on the current branch:

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `dart run tools/ci/architecture_check.dart`

### Closeout Snapshot (2026-03-15)

Current closeout state on this branch:

- all pre-merge implementation acceptance criteria are satisfied;
- workflow ledger rows for `service-routing`, `migration-protection`,
  `execution-order`, and `verification-gates` are already synchronized;
- the only remaining status transition is to update `Status` to `Merged` after
  the branch is actually merged.

## Goal

在 `PR-0408` 的 post-`0012` schema 和 `PR-0409` 的 scoped-query bridge 之上，完成 Rust Core service 层收口：

- 让 `TreeService` 具备 workspace root / designated folder 感知能力；
- 让 `CreationService` 成为统一的新写入入口，完成 designated routing 和 `origin_workspace_id` 写入；
- 落地 `reassign_designated`；
- 显式消费 `PR-0409` 的兼容 bridge，而不是让它以“历史残留”形式继续存在；
- 为 `PR-0411` 的 guarded FFI、`PR-0412` / `PR-0413` 的 Flutter 消费改造提供稳定上游契约。

本 PR 只负责 Core service / repo 层，不直接发布 carrier 文本，也不做 Flutter 侧消费收口。

## Why This PR Exists

当前 upstream 状态已经形成明确分工：

- `PR-0408` 已落 schema、default workspace backfill、designated folder schema truth、`origin_workspace_id` 列，以及 DB triggers；
- `PR-0409` 已落 `ScopedQueryRepository`，并通过 default-workspace-root bridge 暂时保住 root-scoped legacy refs 的可见性；
- workflow ledger 里 `service-routing` 仍是 `pending`，`migration-protection` 仍是 `partial`，说明 `PR-0410` 正是负责把 service 语义补齐的那一段；
- `PR-0411` 以后要消费的不是“草案中的理想接口”，而是本 PR 实际落地后的 tree / creation / designated contract。

## Upstream Facts To Consume

### `PR-0408` 已经保证的事实

- `workspaces`、`designated_folders`、`origin_workspace_id` 已存在；
- 每个 workspace 都已有 `inbox / tasks / calendar` designated folders；
- workspace root 和 designated folder 的 DB trigger 保护已经生效；
- latest-schema 的拓扑不变量是“top level 只允许 workspace roots”。

### `PR-0409` 已经落地且必须被消费的 bridge

- `ScopedQueryRepository` 已成为 canonical subtree query engine；
- `TaskService` 当前仍保留一个显式 bridge：section reads 先从 default workspace root 起查，以保证 pre-`PR-0410` root-scoped refs 仍可见；
- 这个 bridge 不是抽象占位符，而是当前在代码中的 active behavior；
- `PR-0410` 必须决定它在服务层 cutover 之后的语义边界。

### 本 PR 在 workflow 中必须消费的 open items

| Open Item | 本 PR 责任 |
|------|------|
| `OI-035` | Tree / creation service contract 落地 |
| `OI-036` | designated folder reassign 与 service-side protection 落地 |
| `OI-045` | execution-order handoff 显式收敛 |
| `OI-048` | verification / evidence path 回填 |

## Execution Contract (Canonical Inputs)

本 PR 以以下文档为约束输入，不重新定义它们已经确定的事实：

| 类型 | 引用 | 本 PR 的消费方式 |
|------|------|------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md` | 消费 workspace root / designated folder / `origin_workspace_id` / trigger protection 语义 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md` | 消费 tree service、creation routing、workspace meta repo、FFI handoff 方向 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` | 消费 `PR-0410` 在执行序列中的定位和 service-test 责任 |
| PR 规格 | `docs/releases/v0.4/prs/PR-0408-schema-migration.md` | 消费 post-`0012` schema contract 和 designated pre-create 事实 |
| PR 规格 | `docs/releases/v0.4/prs/PR-0409-scoped-query-repository.md` | 消费 scoped-query bridge 的现状和 cutover 责任 |
| Workflow | `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md` | 回填 `service-routing`、`migration-protection`、`execution-order`、`verification-gates` |
| Shared register | `docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md` | 留下 `CPR-001` 所需实现证据，但不直接发布 carrier |

## Scope

### In Scope

- `TreeRepository` / `TreeService` 的 node-based path contract 补齐；
- `list_atom_refs_for_atom` 读侧能力补齐；
- `TreeService` 的 workspace-aware protection：
  - workspace root 不可删；
  - workspace root 不可 move；
  - designated folder 不可删，必须先 reassign；
  - 所有普通节点 `move_node(..., None, ...)` 一律拒绝；
  - 禁止 cross-workspace move；
- `WorkspaceMetaRepository` 增补 `is_designated` / `reassign_designated`；
- `CreationService` 统一创建入口、designated routing、`origin_workspace_id` 事务写入；
- 将 `PR-0409` 的 bridge 定义为“legacy-read compatibility only”；
- service / repo / integration tests；
- workflow ledger 与本 spec 的同步。

### Out Of Scope

- 新 public FFI surface、error-code 扩散、export contract 收口：留给 `PR-0411`；
- Flutter core / feature 消费适配：留给 `PR-0412` / `PR-0413`；
- schema migration、trigger SQL 改写：不在本 PR 主路径，除非发现必须修复的 blocker；
- carrier publication、ADR/ruling/topic-map 更新。

## Canonical Decisions

### 1. `PR-0409` bridge 的 cutover 规则

本 PR 采用以下明确决策：

1. `CreationService` 在 `PR-0410` 之后创建的新 refs，必须落到显式 target folder 或 designated folder。
2. 新写入不允许再依赖 default-workspace-root bridge。
3. `PR-0409` bridge 继续保留，但语义收窄为：
   - 仅用于读取历史 root-scoped refs；
   - 仅作为 `PR-0410` 之后的 legacy compatibility；
   - 不再作为任何新写路径的默认目标。
4. 是否在后续版本移除 bridge，由 `PR-0411` / `PR-0413` 在完成 export contract 和 Flutter 消费收口后再决定。

换句话说，`PR-0410` 的职责不是“立刻删掉 bridge”，而是“让 bridge 变成显式、受限、只服务历史数据的兼容层”。

### 2. 原始 tree API 与业务创建路径分离

为避免把“通用拓扑操作”和“业务写入语义”混在一起，本 PR 明确区分两类入口：

- `TreeService::create_folder(None, ...)` / `create_atom_ref(None, ...)`
  - 仍视为低层 topology helper；
  - 允许继续沿用 default workspace fallback；
  - 目的是保证通用树工具与现有 FFI/测试可平滑过渡。
- `CreationService`
  - 视为业务写入唯一 canonical path；
  - 不允许 root fallback；
  - 只允许显式 target folder 或 designated folder routing。

这条区分是本 PR 的关键边界。后续 `PR-0411` / `PR-0413` 应持续把上层消费迁移到业务路径，而不是继续扩散 raw tree fallback。

### 3. `TreeRepository` 保持纯拓扑，workspace 语义留在 `WorkspaceMetaRepository`

本 PR 不把 designated / workspace 语义塞回 `TreeRepository`。边界保持为：

- `TreeRepository`
  - 纯 `workspace_nodes` 拓扑；
  - create / list / move / rename / delete；
  - node-based path 和 atom-ref location 查询。
- `WorkspaceMetaRepository`
  - workspace metadata；
  - designated folder resolve / reassign / status query。
- `TreeService` / `CreationService`
  - 组合两个 repo，落业务规则和 protection。

### 4. canonical path contract 改为 node-based，但保留临时兼容 wrapper

`DI-16` 要求 canonical breadcrumb contract 改成按 `node_uuid` 解析，而不是按 `atom_uuid` 猜一条路径。本 PR 的落地方式是：

- 新增 canonical API：
  - `get_ancestor_path(node_uuid) -> Vec<(WorkspaceNodeId, String)>`
- 新增 canonical helper：
  - `list_atom_refs_for_atom(atom_uuid) -> Vec<AtomRefLocation>`
- 旧的 atom-based `ancestor_path(atom_uuid)` 不在本 PR 里直接删除；
  - 允许在 Core 内部保留一层 temporary compatibility wrapper；
  - 由后续 `PR-0411` / `PR-0413` 在 FFI 和 Flutter consumer 完成改造后移除。

这能同时满足“本 PR 把 canonical contract 立起来”和“当前 public FFI 还没扩面”的两个约束。

### 5. `CreationService` 不再有“designated 失败就退回 root”语义

旧草案里“指定 folder > designated > root”的描述不再作为业务创建规则。

本 PR 的最终规则是：

1. `target_folder = Some(_)`：直接使用显式目标；
2. `target_folder = None`：由 `resolve_creation_role` 解析 role，再去 `designated_folders` 查目标；
3. designated resolve 失败：返回错误，视为不变量破坏；
4. 业务创建不允许 fallback 到 workspace root。

理由：

- `PR-0408` 已经保证 designated folders 必然存在；
- root fallback 会继续制造 `PR-0409` bridge 依赖；
- 一旦 designated 丢失，更合理的处理是显式报错，而不是静默把新数据写错地方。

### 6. cross-workspace move 永久禁止，跨 workspace 迁移不走 `move_node`

`move_node` 的契约在本 PR 收紧为：

- `new_parent_uuid = None`：拒绝；
- source / target parent 不在同一 workspace tree：拒绝；
- workspace root：拒绝移动；
- designated folder：允许同 workspace 内改位置，但不自动改变 designated 映射；
- 跨 workspace 迁移留给未来专门的 transfer/copy API，不在本 PR 发明半套语义。

### 7. designated folder 只能 reassign，不能 unassign

本 PR 保持 `DI-15` / `DI-16` 的 designated 语义：

- `designated_folders` 是 DB truth；
- 可以把 role 重指向同一 workspace 子树内的另一个 active folder；
- 不允许删除映射；
- 不允许把 role 指向非 folder；
- 不允许指向别的 workspace。

## Target Data Contracts

### `AtomRefLocation`

```rust
pub struct AtomRefLocation {
    pub node_uuid: WorkspaceNodeId,
    pub workspace_id: WorkspaceNodeId,
    pub path: String,
    pub display_name: String,
}
```

### `CreateAtomRequest`

```rust
pub struct CreateAtomRequest {
    pub workspace_id: WorkspaceNodeId,
    pub content: String,
    pub content_type: String,
    pub task_status: Option<TaskStatus>,
    pub start_at: Option<i64>,
    pub end_at: Option<i64>,
    pub tags: Option<Vec<String>>,
    pub target_folder: Option<WorkspaceNodeId>,
    pub display_name: Option<String>,
}
```

补充约束：

- `view_hint` 不作为输入，由服务层推导；
- `origin_workspace_id` 不由调用方传入，由服务层在事务内写入；
- `content_type` 在本 PR 仍只接受当前白名单；
- `end_at >= start_at` 在 service 入口校验。

### `resolve_creation_role`

```rust
fn resolve_creation_role(request: &CreateAtomRequest) -> &'static str {
    if request.task_status.is_some() {
        "tasks"
    } else if request.start_at.is_some() || request.end_at.is_some() {
        "calendar"
    } else {
        "inbox"
    }
}
```

规则：

- 显式 `target_folder` 的优先级高于一切；
- 没有显式 target 时，才走 role 解析；
- role 解析结果只影响 designated 目标，不改变 atom 的属性真相。

## Planned File Changes

- `[edit]` `crates/lazynote_core/src/repo/tree_repo.rs`
- `[edit]` `crates/lazynote_core/src/repo/workspace_meta_repo.rs`
- `[edit]` `crates/lazynote_core/src/service/tree_service.rs`
- `[edit]` `crates/lazynote_core/src/service/creation_service.rs`
- `[edit]` `crates/lazynote_core/src/service/mod.rs`
- `[edit]` `crates/lazynote_core/src/lib.rs`
- `[edit]` `crates/lazynote_core/tests/workspace_tree.rs`
- `[edit]` `crates/lazynote_core/tests/time_matrix.rs`
- `[add or edit]` `crates/lazynote_core/tests/creation_service_routing.rs`
- `[conditional edit]` `crates/lazynote_ffi/src/api.rs`
  - 仅当内部 service 构造或临时兼容 wrapper 需要同步时允许修改；
  - 不新增 public FFI endpoint。

## Executable Plan

### Chunk 1: 先写 RED 测试，锁定 `PR-0410` 契约

**目标**

- 把 tree protection、designated reassign、creation routing、bridge consumption 的预期行为先写成失败测试；
- 避免实现过程中再次回到“边写边猜语义”。

**文件**

- `crates/lazynote_core/tests/workspace_tree.rs`
- `crates/lazynote_core/tests/time_matrix.rs`
- `crates/lazynote_core/tests/creation_service_routing.rs`

**必须先写出来的测试**

1. `move_node(..., None, ...)` 拒绝普通节点。
2. workspace root 不能 delete / move。
3. designated folder 不能 delete，必须先 `reassign_designated`。
4. `reassign_designated` 允许 same-workspace nested folder，拒绝 cross-workspace / non-folder。
5. `CreationService`：
   - 显式 `target_folder` 优先；
   - `task_status` 路由到 `tasks`；
   - `start_at/end_at` 路由到 `calendar`；
   - 默认路由到 `inbox`；
   - 不再 fallback 到 root；
   - 事务内写入 `origin_workspace_id`。
6. `PR-0409` bridge 回归：
   - legacy root-scoped refs 仍可被 section read 看到；
   - 通过 `CreationService` 新创建的 atoms 不再落 root。

**阶段验证**

```bash
cd crates
cargo test -p lazynote_core --test workspace_tree -- --nocapture
cargo test -p lazynote_core --test creation_service_routing -- --nocapture
cargo test -p lazynote_core --test time_matrix -- --nocapture
```

预期：先 RED，再进入实现。

### Chunk 2: 补齐 repo contract，不碰 public FFI

**目标**

- 在 repo 层先把 canonical 查询和 workspace meta 能力补齐；
- 保持 `TreeRepository` 纯拓扑、`WorkspaceMetaRepository` 纯元数据。

**实现项**

- `tree_repo.rs`
  - 新增 `get_ancestor_path(node_uuid)`
  - 新增 `list_atom_refs_for_atom(atom_uuid)`
- `workspace_meta_repo.rs`
  - 新增 `is_designated(node_uuid)`
  - 新增 `reassign_designated(workspace_id, role, new_node_uuid)`
  - 明确 same-workspace subtree 校验和 folder-kind 校验

**阶段出口**

- repo 层测试转绿；
- 还未修改 service 前，public surface 仍可编译。

### Chunk 3: 落 `TreeService` protection 和 move contract

**目标**

- 把 schema triggers 提前到 service 层，提供更清晰的错误语义；
- 为 `PR-0411` 的 error-code 映射准备稳定上游。

**实现项**

- `TreeService` 改为组合 `TreeRepository + WorkspaceMetaRepository`
- 新增/收紧错误变体：
  - `WorkspaceRootProtected`
  - `DesignatedFolderProtected`
  - `CannotMoveWorkspaceRoot`
  - `CannotMoveToRoot`
  - `CrossWorkspaceMoveNotAllowed`
- `delete_folder` 增加 workspace root / designated folder 拦截
- `move_node` 增加：
  - no-root
  - no-cross-workspace
  - no-workspace-root-move
- canonical `get_ancestor_path(node_uuid)` 对外可用
- 如当前 compile path 仍依赖 atom-based `ancestor_path(atom_uuid)`，在本层保留 temporary wrapper

**阶段出口**

- `workspace_tree.rs` 对应保护与路径测试转绿；
- 旧 FFI 若仍依赖 atom-based path，不因本 chunk 直接断编。

### Chunk 4: 落 `CreationService` 统一创建入口

**目标**

- 让业务创建从“直接往 root 或 parent 塞 ref”收口到“显式目标或 designated routing”；
- 把 `origin_workspace_id` 真正接入写路径。

**实现项**

- 引入 `CreateAtomRequest`
- 引入 `create_atom(&CreateAtomRequest)`
- 内部事务顺序：
  1. 校验输入；
  2. 推导 `view_hint`；
  3. 解析目标 folder；
  4. 校验目标属于 `workspace_id` 子树；
  5. 写 atom（含 `origin_workspace_id`）；
  6. 写 atom_ref；
  7. 可选写 tags；
  8. commit
- 现有
  - `create_note_with_ref`
  - `create_task_with_ref`
  - `create_event_with_ref`
  保留为 thin wrappers 或 compatibility entrypoints，但内部统一委托新路径

**明确不允许**

- designated resolve 失败后 fallback 到 root；
- 创建跨 workspace ref；
- 在 service 层绕过 `origin_workspace_id` 写入。

### Chunk 5: 显式消费 `PR-0409` bridge，并把下游 handoff 写清楚

**目标**

- 让 `PR-0410` 成为 `PR-0409` bridge 的正式消费点；
- 给 `PR-0411` 留下明确的“还能做什么、不能做什么”。

**本 chunk 要写入 spec / workflow 的结论**

- `PR-0409` bridge 继续保留，但仅服务 legacy root-scoped refs；
- `CreationService` 新写入不再制造新的 bridge 依赖；
- `service-routing` 在本 PR 落地；
- `migration-protection` 若 service-side protection 全部补齐，可在 workflow 中收敛为 `landed`；
- `execution-order` / `verification-gates` 补入本 PR 的证据路径；
- `PR-0411` 负责消费：
  - 新错误变体的 FFI 映射；
  - node-based path 的 public export contract；
  - 旧兼容 wrapper 的进一步收缩或下线。

### Chunk 6: 全量验证与文档收口

**目标**

- 确保这次不是“局部测试过”，而是整个 Rust/Core/FFI 仍然绿。

**必须跑的验证**

```bash
cd crates
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd ..
dart run tools/ci/architecture_check.dart
```

**本 PR 必须同步的文档**

- `docs/releases/v0.4/prs/PR-0410-tree-service-creation-service.md`
- `docs/releases/v0.4/prs/PR-0411-guard-ffi.md`（至少同步 handoff context，若实现期需要）
- `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`

## Workflow Update Requirements

本 PR 完成后，至少要回填以下 ledger rows：

| Slice | 预期状态 | 说明 |
|------|------|------|
| `service-routing` | `landed` | TreeService / CreationService / reassign contract 落地 |
| `migration-protection` | `landed` 或带证据的 `partial` | 取决于 service-side protection 是否完整覆盖 schema-side guard 预期 |
| `execution-order` | `partial` | 增加 `PR-0410` 已消费 `PR-0409` bridge 的证据 |
| `verification-gates` | `partial` | 增加 service / routing / reassign / bridge tests 的证据 |

本 PR 不得直接发布 carrier，不得直接改写 `DI-15` active bundle 的主线发布面。

## Risks And Mitigations

| 风险 | 影响 | 缓解 |
|------|------|------|
| node-based path 直接替换导致旧 FFI 断编 | 中 | 保留临时 compatibility wrapper，到 `PR-0411` 再扩 public contract |
| 误把 raw tree fallback 和业务创建 fallback 混为一谈 | 高 | 在 spec 中明确两类入口分离，并用测试锁死 |
| designated reassign 校验做成“必须直挂 root”而不是“同 workspace 子树” | 高 | 测试必须覆盖 nested folder same-workspace reassign |
| 新写入仍悄悄落 root，继续扩大 bridge 依赖 | 高 | `CreationService` 测试中显式断言新 ref 不落 root |
| service-side protection 不完整，workflow 状态写早 | 中 | 只有 delete/move/reassign/create 保护都落地并有测试时，才允许把 `migration-protection` 标成 `landed` |

## Current Acceptance Status (2026-03-15)

This is the authoritative closeout checklist for the current branch. The
historical draft checklist below is retained as planning history.

- [x] canonical `get_ancestor_path(node_uuid)` is landed
- [x] `list_atom_refs_for_atom(atom_uuid)` is landed
- [x] `WorkspaceMetaRepository::is_designated` is landed
- [x] `WorkspaceMetaRepository::reassign_designated` is landed
- [x] `TreeService` enforces workspace-root and designated-folder protection
- [x] `move_node(..., None, ...)` is rejected for ordinary nodes
- [x] cross-workspace move is rejected
- [x] `CreationService::create_atom` is landed
- [x] existing creation entrypoints delegate to the canonical creation path
- [x] `CreationService` writes `origin_workspace_id` inside the transaction
- [x] newly created refs no longer rely on the default-workspace-root bridge
- [x] the `PR-0409` bridge is documented as legacy-read compatibility only
- [x] service / routing / reassign / bridge tests are landed
- [x] `cargo fmt --all -- --check` passes
- [x] `cargo clippy --all -- -D warnings` passes
- [x] `cargo test --all` passes
- [x] `dart run tools/ci/architecture_check.dart` passes
- [x] workflow ledger is synchronized for `service-routing`,
      `migration-protection`, `execution-order`, and `verification-gates`
- [x] `Status` is updated to `Merged`

## Historical Acceptance Draft

- [ ] canonical `get_ancestor_path(node_uuid)` 已落地
- [ ] `list_atom_refs_for_atom(atom_uuid)` 已落地
- [ ] `WorkspaceMetaRepository::is_designated` 已落地
- [ ] `WorkspaceMetaRepository::reassign_designated` 已落地
- [ ] `TreeService` 已具备 workspace root / designated folder 保护
- [ ] `move_node(..., None, ...)` 对普通节点恒拒绝
- [ ] cross-workspace move 恒拒绝
- [ ] `CreationService::create_atom` 已落地
- [ ] 现有创建入口已统一委托新路径或保持明确兼容壳
- [ ] `CreationService` 事务内写入 `origin_workspace_id`
- [ ] 新创建 refs 不再依赖 default-workspace-root bridge
- [ ] `PR-0409` bridge 的 legacy-only 语义已在本 spec 和 workflow 中写明
- [ ] service / routing / reassign / bridge 测试已落地
- [ ] `cargo fmt --all -- --check` 通过
- [ ] `cargo clippy --all -- -D warnings` 通过
- [ ] `cargo test --all` 通过
- [ ] `dart run tools/ci/architecture_check.dart` 通过
- [ ] workflow ledger 已同步 `service-routing` / `migration-protection` / `execution-order` / `verification-gates`
- [ ] PR 合并后再将 Status 更新为 `Merged`
