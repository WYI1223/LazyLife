# PR-RB-03: S4 + S1 R5/R6 创建路径统一

- Proposed title: `feat(core): PR-RB-03 unify creation paths with atom_ref forced accompaniment`
- Status: Completed

## Goal

将 `note_ref` 语义升级为 `atom_ref`（Migration 0011），使所有 Atom 类型（note/task/event）都能拥有 workspace 引用。统一全部创建 API：创建 Atom 时原子性地同时创建 `atom_ref`，路由到指定目标文件夹或 root。消除 "创建了 Atom 但无 workspace 引用" 的 orphan 状态。

前置条件：PR-RB-02（`view_hint` 列已存在，`type` 已重命名）

## Design Decisions (Resolved)

### D1: Workspace Tree 展示所有类型 atom_ref

**决策**：选项 B — workspace tree 展示所有类型（note/task/event）的 atom_ref。

**依据**：atom_ref 是统一的 workspace 引用，不应按 atom 类型过滤可见性。用户创建的 task/event 必须在 workspace tree 中可见。

**影响分析**：改动量低于预期。`workspace_tree_children_loader.dart` 的投射逻辑在 `_noteById(atomId)` 返回 null 时已有 fallback（使用 `item.displayName`），task/event 的 atom_ref 通过 workspace tree 自身数据（`workspace_list_children` FFI 返回值）展示，不依赖 `NoteListManager`。核心改动仅为 `'note_ref'` → `'atom_ref'` 字符串替换。

### D2: v0.3 designated_folders 全部为 null — 所有 atom_ref 落在 root

**决策**：v0.3 全部 11 个 PR 中无任何 PR 实现 designated folder 配置 UI 或路由。`designated_folders.tasks` / `.calendar` 始终为 null，所有 atom_ref 一律落在 root → 出现在 "Uncategorized" 虚拟文件夹。

**依据**：v0.3 rebaseline 计划明确将 designated folder 配置 UI 推迟到 v0.4。当前行为正确：root = "uncategorized"（S4 定义）。task/event 仍可通过 Inbox/Today/Upcoming/Calendar 视图访问。

**路由实现**：FFI 创建 API 添加 `parent_node_id: Option<String>` 参数，Flutter 侧读取 settings 后传入。v0.3 实际效果：全部传 null → 全部 root。

### D3: 新建 `CreationService` composite service（Core service 层）

**决策**：新建 `crates/lazynote_core/src/service/creation_service.rs`，持有 `NoteRepository` + `AtomRepository` + `TreeRepository` 三个 repo 在同一 `Connection` 上。

**裁决依据**：
- S4 原文："Core service 层统一创建 API"（v0.3 待实施）
- S1 R5 原文："创建 API（`note_create`, `entry_create_note` 等）统一在 Core service 层同时创建 Atom + atom_ref"
- Engineering Standards Rule A：业务不变量归 Core
- Engineering Standards Rule B：FFI 只暴露用例 API

**替代方案排除**：
- 扩展 `AtomService` 持有 `TreeRepository` — 违反单一职责，让 AtomService 膨胀
- FFI 层直接组合 — 违反 Rule A，业务逻辑不应在 FFI 层

**实现形状**：

```rust
// crates/lazynote_core/src/service/creation_service.rs
pub struct CreationService<'conn> {
    note_repo: SqliteNoteRepository<'conn>,
    atom_repo: SqliteAtomRepository<'conn>,
    tree_repo: SqliteTreeRepository<'conn>,
}

impl<'conn> CreationService<'conn> {
    /// 创建 note + root-level atom_ref（或指定文件夹）
    pub fn create_note_with_ref(&mut self, content, parent_node_id) -> Result<(NoteRecord, WorkspaceNode)>

    /// 创建 task + atom_ref
    pub fn create_task_with_ref(&self, content, parent_node_id) -> Result<(AtomId, WorkspaceNodeId)>

    /// 创建 event + atom_ref
    pub fn create_event_with_ref(&self, request, parent_node_id) -> Result<(AtomId, WorkspaceNodeId)>
}
```

FFI 层新增 `with_creation_service` helper，共享单一 `Connection`。SQLite 隐式事务保证原子性。

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Ruling | `docs/architecture/rulings/S4-creation-path-unification.md` | 全部 4 条规则：forced accompaniment / routing / unified operations / view-folder orthogonality |
| Ruling | `docs/architecture/rulings/S1-atom-projection.md` R5 | atom_ref forced accompaniment：创建必须同时产出 atom_ref |
| Ruling | 同上 R6 | 默认路径路由表：Tasks/Calendar/Root |
| Ruling | 同上 R7 | 多引用语义（本 PR 仅开放能力，不实现创建 UI） |
| Rebaseline | `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-03 | Scope + 依赖 |

## 差距分析

### 1. DB Schema：`note_ref` → `atom_ref`

| 当前 | 目标 | 差距 |
|------|------|------|
| `kind CHECK (kind IN ('folder', 'note_ref'))` | `kind CHECK (kind IN ('folder', 'atom_ref'))` | SQLite 不支持 ALTER COLUMN — 需表重建 |
| INSERT 触发器校验 `a.type = 'note'` | 允许任何 active atom | 触发器需 DROP + 重建（引用 `view_hint` 而非 `type`） |
| 仅 note 类型 atom 有 workspace 引用 | task/event 也有引用 | 回填现有 task/event |

### 2. Core 层：单一类型限制

| 当前 | 目标 | 差距 |
|------|------|------|
| `WorkspaceNodeKind::NoteRef` | `WorkspaceNodeKind::AtomRef` | enum 值重命名 |
| `create_note_ref()` 校验 `atom_kind == Note` | `create_atom_ref()` 校验 atom 存在且未删除 | 移除类型限制 |
| `TreeServiceError::AtomNotNote` | 移除，替换为 `AtomNotFound` | 错误类型变更 |
| 列表查询 `WHERE a.type = 'note'` | `WHERE a.is_deleted = 0` | SQL 过滤条件放宽 |

### 3. 创建 API：无 atom_ref accompaniment

| 创建路径 | 当前行为 | S4 要求 |
|---------|---------|---------|
| `entry_create_note` | 仅创建 Atom | 创建 Atom + root-level atom_ref |
| `entry_create_task` | 仅创建 Atom | 创建 Atom + Tasks designated folder atom_ref（或 root） |
| `entry_schedule` | 仅创建 Atom | 创建 Atom + Calendar designated folder atom_ref（或 root） |
| `note_create` | 仅创建 Atom | 创建 Atom + root-level atom_ref |
| Explorer 右键创建 | 两次 FFI 调用（非原子） | 单次原子创建 |
| Tasks inline create | 调用 `entry_create_note` 而非 `entry_create_task` | 修正为 `entry_create_task` + atom_ref |

### 4. 事务边界问题

当前 `AtomService`/`NoteService` 和 `TreeService` 使用独立的 repository 实例和连接。原子性创建 Atom + atom_ref 需要统一事务。

## 设计方案

### Migration 0011

由于 SQLite 不支持 `ALTER COLUMN` 修改 CHECK 约束，采用表重建策略：

```sql
-- 1. 创建新表（atom_ref 替代 note_ref）
CREATE TABLE workspace_nodes_new (
    node_uuid TEXT PRIMARY KEY NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('folder', 'atom_ref')),
    parent_uuid TEXT NULL,
    atom_uuid TEXT NULL,
    display_name TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    CHECK (parent_uuid IS NULL OR parent_uuid <> node_uuid),
    CHECK (
        (kind = 'folder' AND atom_uuid IS NULL)
        OR (kind = 'atom_ref' AND atom_uuid IS NOT NULL)
    ),
    FOREIGN KEY (parent_uuid) REFERENCES workspace_nodes_new(node_uuid),
    FOREIGN KEY (atom_uuid) REFERENCES atoms(uuid)
);

-- 2. 迁移数据（note_ref → atom_ref）
INSERT INTO workspace_nodes_new
  SELECT node_uuid,
         CASE kind WHEN 'note_ref' THEN 'atom_ref' ELSE kind END,
         parent_uuid, atom_uuid, display_name, sort_order,
         is_deleted, created_at, updated_at
  FROM workspace_nodes;

-- 3. 替换表
DROP TABLE workspace_nodes;
ALTER TABLE workspace_nodes_new RENAME TO workspace_nodes;

-- 4. 重建索引（如有）
CREATE INDEX IF NOT EXISTS idx_workspace_nodes_parent
  ON workspace_nodes(parent_uuid) WHERE is_deleted = 0;
CREATE INDEX IF NOT EXISTS idx_workspace_nodes_atom
  ON workspace_nodes(atom_uuid) WHERE atom_uuid IS NOT NULL;

-- 5. 回填：为现有 task/event 创建 root-level atom_ref
INSERT INTO workspace_nodes (node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order)
  SELECT
    lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
      substr(hex(randomblob(2)),2) || '-' ||
      substr('89ab', abs(random()) % 4 + 1, 1) ||
      substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))),
    'atom_ref',
    NULL,
    a.uuid,
    COALESCE(a.title, ''),
    0
  FROM atoms a
  WHERE a.is_deleted = 0
    AND a.view_hint IN ('task', 'event')
    AND NOT EXISTS (
      SELECT 1 FROM workspace_nodes wn
      WHERE wn.atom_uuid = a.uuid AND wn.is_deleted = 0
    );

-- 6. 触发器：atom_ref 校验（仅验证 atom 存在且未删除）
DROP TRIGGER IF EXISTS workspace_nodes_note_ref_requires_note_insert;
DROP TRIGGER IF EXISTS workspace_nodes_note_ref_requires_note_update;

CREATE TRIGGER workspace_nodes_atom_ref_insert
BEFORE INSERT ON workspace_nodes
WHEN NEW.kind = 'atom_ref'
BEGIN
  SELECT RAISE(ABORT, 'atom_ref references invalid atom')
  WHERE NOT EXISTS (
    SELECT 1 FROM atoms a WHERE a.uuid = NEW.atom_uuid AND a.is_deleted = 0
  );
END;
```

### Core 层：统一创建服务（D3 决策：CreationService）

新建 `CreationService` composite service（见 D3 决策），在同一 `Connection` 上持有三个 repo，保证 Atom + atom_ref 原子性创建：

```rust
// crates/lazynote_core/src/service/creation_service.rs
pub struct CreationService<'conn> {
    note_repo: SqliteNoteRepository<'conn>,
    atom_repo: SqliteAtomRepository<'conn>,
    tree_repo: SqliteTreeRepository<'conn>,
}

impl<'conn> CreationService<'conn> {
    pub fn create_note_with_ref(
        &mut self,
        content: impl Into<String>,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(NoteRecord, WorkspaceNode), CreationServiceError> {
        // 1. NoteRepository::create_note (INSERT atom + derive title/preview)
        // 2. TreeRepository::create_atom_ref (INSERT workspace_nodes)
        // 3. 返回 (NoteRecord, WorkspaceNode)
    }

    pub fn create_task_with_ref(
        &self,
        content: impl Into<String>,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(AtomId, WorkspaceNode), CreationServiceError> { ... }

    pub fn create_event_with_ref(
        &self,
        request: &ScheduleEventRequest,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(AtomId, WorkspaceNode), CreationServiceError> { ... }
}
```

FFI 层新增 `with_creation_service` helper：

```rust
fn with_creation_service<T>(
    f: impl FnOnce(&mut CreationService) -> Result<T, CreationServiceError>
) -> Result<T, CreationFfiError> {
    let db_path = resolve_entry_db_path();
    let mut conn = open_db(&db_path)?;
    let service = CreationService::try_new(&mut conn)?;
    f(&mut service).map_err(map_creation_error)
}
```

各创建路径委托到 `CreationService`，传入 `parent_node_id`：
- Header button / `note_create` / `entry_create_note` → `parent_node_id = None`（root）
- `entry_create_task` → `parent_node_id = tasks_designated_folder()`（无配置时 = None）
- `entry_schedule` → `parent_node_id = calendar_designated_folder()`（无配置时 = None）
- Explorer 右键创建 → `parent_node_id = Some(specified_folder)`

### 默认路径配置

v0.3 采用最简方案：designated folder mapping 存储在 `settings.json`：

```json
{
  "designated_folders": {
    "tasks": null,
    "calendar": null
  }
}
```

`null` = 未配置，回退到 root level。v0.3 暂不实现 designated folder 配置 UI（用户可手动编辑 settings.json 或 v0.4 提供 UI）。

### FFI 响应扩展

`EntryActionResponse` 和 `AtomItemResponse`（PR-RB-01 新增）需包含 `node_uuid`：

```rust
pub struct EntryActionResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub atom_id: Option<String>,
    pub node_uuid: Option<String>,  // 新增：创建的 atom_ref node UUID
}
```

## Scope

In scope:

- Migration 0011：表重建 + `note_ref` → `atom_ref` + task/event 回填
- Core `WorkspaceNodeKind::NoteRef` → `AtomRef`
- Core `create_note_ref` → `create_atom_ref`（移除类型限制）
- Core 统一创建方法：`create_atom_with_ref` 事务性原子创建
- 各创建 API 集成：`entry_create_note`/`entry_create_task`/`entry_schedule`/`note_create`
- FFI `workspace_create_note_ref` → `workspace_create_atom_ref`
- FFI 响应扩展（`node_uuid`）
- Flutter 消费新返回值 + 移除两步创建流程
- 修正 tasks inline create 使用 `entry_create_task`（非 `entry_create_note`）
- `settings.json` 中 designated folder 配置字段（可为 null）

Out of scope:

- Designated folder 配置 UI（v0.4）
- 多引用创建 UI（右键 "Duplicate" / "Add reference to..."）——R7 能力已开放但 UI 不在本 PR
- `/Pending/` pool（S4 open design item，v0.4）

## Task Breakdown

### Phase 1: Migration

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T1 | 创建 migration 0011 SQL（表重建 + 数据迁移 + 回填 + 触发器） | `crates/lazynote_core/src/db/migrations/0011_atom_ref_upgrade.sql` | 新文件 ~60 行 | — |
| T2 | 注册 migration 0011 | `crates/lazynote_core/src/db/migrations/mod.rs` | 追加 MIGRATIONS | T1 |

### Phase 2: Core Model + Repo

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T3 | `WorkspaceNodeKind::NoteRef` → `AtomRef`；序列化字符串 `"note_ref"` → `"atom_ref"` | `crates/lazynote_core/src/repo/tree_repo.rs` | 编辑 enum + 序列化 | T1 |
| T4 | `create_note_ref` → `create_atom_ref`；SQL INSERT 使用 `'atom_ref'` | `crates/lazynote_core/src/repo/tree_repo.rs` | 重命名 + 编辑 SQL | T3 |
| T5 | 列表查询移除 `a.type = 'note'` / `a.view_hint = 'note'` 过滤 | `crates/lazynote_core/src/repo/tree_repo.rs` | 编辑 SQL WHERE | T3 |

### Phase 3: Core Service 统一创建

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T6 | `TreeService`：`create_note_ref` → `create_atom_ref`，`ensure_atom_is_note` → `ensure_atom_exists`，移除 `AtomNotNote` 错误 | `crates/lazynote_core/src/service/tree_service.rs` | 编辑 | T4 |
| T7 | 新建 `CreationService` composite service（D3 决策） | `crates/lazynote_core/src/service/creation_service.rs` | 新文件 ~120 行 | T4, T6 |
| T8 | `CreationService` 实现 `create_note_with_ref` / `create_task_with_ref` / `create_event_with_ref` | `crates/lazynote_core/src/service/creation_service.rs` | 编辑 | T7 |
| T9 | 注册 `creation_service` 模块到 `service/mod.rs` | `crates/lazynote_core/src/service/mod.rs` | 编辑 | T7 |

### Phase 4: FFI 层

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T10 | `workspace_create_note_ref` → `workspace_create_atom_ref` | `crates/lazynote_ffi/src/api.rs` | 重命名 | T4 |
| T11 | `EntryActionResponse` + `AtomItemResponse` 添加 `node_uuid` 字段 | `crates/lazynote_ffi/src/api.rs` | 编辑 struct | — |
| T12 | `entry_create_note`/`entry_create_task`/`entry_schedule`/`note_create` 使用统一创建 + 返回 node_uuid | `crates/lazynote_ffi/src/api.rs` | 编辑 4 个函数 | T7, T11 |
| T13 | 创建 API 添加可选 `parent_node_id` 参数（支持指定文件夹） | `crates/lazynote_ffi/src/api.rs` | 编辑函数签名 | T12 |

### Phase 5: Settings + Codegen + Flutter

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T14 | `settings.json` schema 添加 `designated_folders` 字段 | Core 或 Flutter settings | 编辑 | — |
| T15 | 运行 `scripts/gen_bindings.ps1` | bindings | 自动生成 | T13 |
| T16 | Flutter `createNote()` 简化为单次 FFI 调用 + 处理 `nodeUuid` 返回值 | `notes_coordinator_impl.dart` | 编辑 | T15 |
| T17 | Flutter `createWorkspaceNoteInFolder` 简化为单次 FFI 调用 | `workspace_tree_manager.dart` | 编辑 | T15 |
| T18 | Flutter `createInboxItem` 改用 `entry_create_task` + 处理 node_uuid | `tasks_controller.dart` | 编辑 | T15 |
| T19 | Flutter `createEvent` 处理 node_uuid | `calendar_controller.dart` | 编辑 | T15 |
| T20 | Flutter 全局 `note_ref` / `NoteRef` → `atom_ref` / `AtomRef` 重命名 | 多文件 | 编辑 | T15 |

### Phase 6: Tests + Docs

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T21 | Rust 测试更新：tree repo/service 测试 + 统一创建测试 + migration 测试 | `crates/lazynote_core/tests/` | 编辑 + 新增 | T9 |
| T22 | Flutter 测试更新：mock 构造 + 创建流程测试 | `test/*.dart` | 编辑 | T15 |
| T23 | 文档更新：`data-model.md`、`ffi-contracts.md`、`CLAUDE.md` | docs | 编辑 | T13 |
| T24 | `S4-creation-path-unification.md` + `S1-atom-projection.md` R5/R6 标注 implemented | docs/architecture/rulings/ | 编辑 | T13 |

### Critical Path

```
T1 → T2 → T3 → T4/T5 → T6 → T7 → T8/T9 → T12/T13 → T15 → T16~T20 (并行)
T11 无依赖，可与 T1~T9 并行
T14 无依赖，可并行
```

## Planned File Changes

### Rust Core
- `[add]` `crates/lazynote_core/src/db/migrations/0011_atom_ref_upgrade.sql`
- `[edit]` `crates/lazynote_core/src/db/migrations/mod.rs`
- `[edit]` `crates/lazynote_core/src/repo/tree_repo.rs`
- `[edit]` `crates/lazynote_core/src/service/tree_service.rs`
- `[add]` `crates/lazynote_core/src/service/creation_service.rs`（D3 决策：composite service）
- `[edit]` `crates/lazynote_core/src/service/mod.rs`

### Rust FFI
- `[edit]` `crates/lazynote_ffi/src/api.rs`

### Flutter
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/*.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_manager.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/tasks/tasks_controller.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/calendar/calendar_controller.dart`
- `[edit]` 涉及 `note_ref`/`NoteRef` 引用的全部文件

### Docs
- `[edit]` `docs/architecture/data-model.md`
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `CLAUDE.md`
- `[edit]` `docs/architecture/rulings/S4-creation-path-unification.md`
- `[edit]` `docs/architecture/rulings/S1-atom-projection.md`

## Verification

### CI gates

```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# note_ref 在 Core 中归零
rg "note_ref" crates/lazynote_core/src/ --type rust
# Expected: zero matches（或仅出现在 migration 历史注释中）

# NoteRef enum 值归零
rg "NoteRef" crates/lazynote_core/src/ --type rust
# Expected: zero matches

# 创建 API 返回 node_uuid
rg "node_uuid" crates/lazynote_ffi/src/api.rs
# Expected: ≥ 2 matches (EntryActionResponse + AtomItemResponse)

# Flutter 侧无 NoteRef 残留
rg "NoteRef\b" apps/lazynote_flutter/lib/ --glob '!core/bindings/*'
# Expected: zero matches

# 验证创建原子性：entry_create_note 包含 atom_ref 逻辑
rg "create_atom_with_ref" crates/lazynote_ffi/src/api.rs
# Expected: ≥ 1 match
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 表重建 migration 丢失数据 | HIGH | Migration SQL 先 INSERT 再 DROP，中间无并发写入（app 锁定迁移） |
| task/event 回填 UUID 生成质量 | LOW | SQL `randomblob` 产生 UUIDv4 格式，唯一性由 PRIMARY KEY 约束保证 |
| 事务边界变更影响现有连接管理 | MEDIUM | `create_atom_with_ref` 在单一 `Connection` 上操作，不影响 `with_*_service` 辅助函数 |
| `entry_search` 结果中出现 task/event 的 workspace 引用 | LOW | 搜索结果不涉及 workspace 引用，与本 PR 正交 |
| designated folder 为 null 时所有创建都落到 root | LOW | 这是正确行为：root = "uncategorized"（S4 定义） |

## Test Baseline

Entry: PR-RB-02 exit count
Exit: **≥ PR-RB-02 count + 新增统一创建测试**

## Acceptance Criteria

- [ ] Migration 0011 成功：`workspace_nodes.kind` CHECK 约束包含 `'atom_ref'`
- [ ] 现有 `note_ref` 数据全部迁移为 `atom_ref`
- [ ] 现有 task/event 有 root-level atom_ref
- [ ] `entry_create_note`/`entry_create_task`/`entry_schedule`/`note_create` 全部原子性创建 Atom + atom_ref
- [ ] `EntryActionResponse`/`AtomItemResponse` 包含 `node_uuid`
- [ ] `workspace_create_atom_ref` 接受任何 active atom（非仅 note）
- [ ] Explorer 右键创建为单次 FFI 调用
- [ ] Tasks inline create 使用 `entry_create_task`（非 `entry_create_note`）
- [ ] `settings.json` 支持 `designated_folders` 配置
- [ ] Core 和 Flutter 中 `note_ref`/`NoteRef` 引用归零
- [ ] Workspace tree 展示所有类型 atom_ref（D1 决策：note/task/event 均可见）
- [ ] `CreationService` composite service 位于 Core service 层（D3 决策）
- [ ] 全部 Rust tests 通过
- [ ] 全部 Flutter tests 通过
- [ ] CI green
