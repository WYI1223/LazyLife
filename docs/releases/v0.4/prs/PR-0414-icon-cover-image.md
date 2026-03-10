# PR-0414: Atom Icon + Cover Image 元数据字段

- Proposed title: `feat(core): add icon and cover_image atom metadata fields`
- Status: Draft

## Goal

实现 S1 Ruling R9/R10：为 Atom 新增 `icon`（自定义图标）和 `cover_image`（封面图）两个元数据字段，覆盖 migration → Core model → repo → service → FFI → Flutter UI 全链路。用户可在 Explorer、列表卡片中直观感知 Atom 的个性化身份标识。

前置条件：PR-0413（需要 Flutter 消费方已完成 v0.4 新接口迁移，FFI `AtomListItem` 稳定后统一扩展）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| S1 Ruling | `docs/architecture/rulings-legacy/S1-atom-projection.md` R9/R10 | icon / cover_image 语义定义、`cover_image` vs `preview_image` 区别、列表渲染优先级规则 |
| 现有 schema | `crates/lazynote_core/src/db/migrations/` | 当前 12 个 migration（PR-0408 新增 0012），本 PR 新增第 13 个 |
| 现有 model | `crates/lazynote_core/src/model/atom.rs` | Atom struct，需新增两字段 |
| 现有 repo | `crates/lazynote_core/src/repo/atom_repo.rs` | ATOM_SELECT_SQL、SECTION_SELECT_SQL、parse_atom_row、create_atom、update_atom，全部需感知新字段 |
| 现有 repo | `crates/lazynote_core/src/repo/note_repo.rs` | NoteRecord DTO，需新增两字段 |
| 现有 FFI | `crates/lazynote_ffi/src/api.rs` | AtomListItem struct，新增 FFI 函数 `atom_update_metadata` |
| 规范源 | `docs/api/ffi-contracts.md` | 需更新：AtomListItem 新增字段、新增 `atom_update_metadata` 函数契约 |
| 规范源 | `docs/governance/API_COMPATIBILITY.md` | 需更新：breaking change 记录（AtomListItem 结构扩展） |

## Scope

In scope:
- Migration 0013：`atoms` 表新增 `icon TEXT` 和 `cover_image TEXT` 两列（nullable）
- `Atom` struct 新增 `icon: Option<String>` 和 `cover_image: Option<String>`
- `AtomDe`（反序列化辅助 struct）同步新增字段
- `Atom::new()` / `Atom::with_id()` / `TryFrom<AtomDe>` 同步更新
- `atom_repo.rs`：ATOM_SELECT_SQL、SECTION_SELECT_SQL 新增两列，`parse_atom_row` 读取新字段，`create_atom` / `update_atom` INSERT/UPDATE 语句新增两列
- `ensure_connection_ready` 列名验证列表新增 `icon`、`cover_image`
- `NoteRecord` DTO 新增 `icon: Option<String>` 和 `cover_image: Option<String>`
- `note_repo.rs` 读取路径（SELECT SQL + row 解析）感知新字段
- 新增 repo 接口方法 `update_atom_metadata`：仅更新 `icon` / `cover_image`，不触碰 content/status/time
- 新增 FFI 函数 `atom_update_metadata(atom_id, icon?, cover_image?)` → `AtomItemResponse`
- `AtomListItem` 新增 `icon: Option<String>` 和 `cover_image: Option<String>`
- `to_atom_list_item_from_note` 映射函数同步传递两字段
- 已有从 SectionAtomRow 构建 AtomListItem 的路径（tasks/calendar 视图）同步更新
- Flutter UI：Explorer tree item `atom_ref` 节点根据 `icon` 字段选择渲染图标
- Flutter UI：Notes list card（及 Tasks/Calendar 卡片）根据 S1 R10 优先级规则渲染封面图（`cover_image` > `preview_image` > NULL）
- Rust 集成测试（migration 验证、`atom_update_metadata` 正向/边界用例）
- Flutter widget 测试（icon 渲染、cover_image 渲染优先级）
- 更新 `docs/api/ffi-contracts.md`（AtomListItem 扩展 + 新函数）
- 更新 `docs/architecture/data-model.md`（schema 变更）
- 更新 `docs/governance/API_COMPATIBILITY.md`

Out of scope:
- icon/cover_image 的 UI 设置入口（picker 交互、拖拽设置封面）——v0.4 仅做渲染消费，写入由 `atom_update_metadata` FFI 驱动，但 UI 设置触发点不在本 PR
- cover_image 管理附件路径（v0.5 计划迁移到 managed attachments，本 PR 仅存储为 opaque 绝对路径字符串）
- icon 值域验证（Core 存储为 opaque string，Flutter 层按 emoji / Material Icons name 解释，Core 不做任何格式校验）
- FTS5 对 icon/cover_image 建索引（无搜索需求，不纳入 FTS 表）
- 现有已存储 `preview_image` 的自动合并或迁移（两字段独立，S1 R10 已定义优先级）

## Design

### 1. Migration 0013

```sql
-- Migration: 0013_icon_cover_image.sql
-- Purpose: S1 R9/R10 — add icon and cover_image metadata fields to atoms.
-- Invariants:
-- - Both columns are nullable (NULL = not set, no default value).
-- - icon: opaque string, max 64 chars enforced at application layer only (Core 不做 DB 约束).
-- - cover_image: opaque absolute file path string (v0.4). Will migrate to managed
--   attachment URL in v0.5; no DB-level format constraint today.
-- - No FTS re-index required (fields not indexed for full-text search).
-- Backward compatibility:
-- - Additive-only. Existing rows default to NULL for both columns.

ALTER TABLE atoms ADD COLUMN icon TEXT;
ALTER TABLE atoms ADD COLUMN cover_image TEXT;
```

新 migration 版本号 = 13（PR-0408 新增 0012，本 PR 为顺序下一个）。注册到 `crates/lazynote_core/src/db/migrations/mod.rs` 的 `MIGRATIONS` 数组。

### 2. Atom Model 变更

`crates/lazynote_core/src/model/atom.rs`：

```rust
pub struct Atom {
    // ... 现有字段不变 ...

    /// User-defined icon for this atom. Opaque string (max 64 chars, enforced at
    /// application boundary). Flutter interprets as Unicode emoji or Material Icons name.
    /// NULL = use default view_hint icon.
    pub icon: Option<String>,

    /// User-set cover image path (absolute file path, v0.4).
    /// Takes display priority over auto-derived `preview_image`.
    /// NULL = fall back to `preview_image` or no cover.
    /// Note: Will migrate to managed attachment URL in v0.5.
    pub cover_image: Option<String>,
}
```

`Atom::validate()` 不新增 icon/cover_image 约束（opaque string，不做 Core 层校验）。`AtomDe` 同步新增两字段（`#[serde(default)]`）。

### 3. Repo 层变更

#### 3.1 ATOM_SELECT_SQL / SECTION_SELECT_SQL

两个常量均追加 `icon, cover_image` 列。`parse_atom_row` 新增读取：

```rust
let atom = Atom {
    // ... 现有字段 ...
    icon: row.get("icon")?,
    cover_image: row.get("cover_image")?,
};
```

#### 3.2 create_atom / update_atom

INSERT 和 UPDATE 语句追加 `icon`、`cover_image` 列及对应参数绑定。

#### 3.3 ensure_connection_ready 列验证

现有列验证数组新增 `"icon"` 和 `"cover_image"`。

#### 3.4 新 trait 方法 `update_atom_metadata`

```rust
/// Updates only `icon` and `cover_image` for an existing atom.
///
/// Pass `None` to clear the corresponding field.
/// Pass `Some(value)` to set the field.
/// Does not affect content, status, time fields, or `updated_at` schema rows.
///
/// Returns `RepoError::NotFound` when atom does not exist or is soft-deleted.
fn update_atom_metadata(
    &self,
    id: AtomId,
    icon: Option<Option<&str>>,
    cover_image: Option<Option<&str>>,
) -> RepoResult<()>;
```

参数语义：`None` = 不更新该字段；`Some(None)` = 清空该字段；`Some(Some(value))` = 设置新值。SQL 使用 `CASE WHEN` 实现按需更新（只修改调用方提供的字段）：

```sql
UPDATE atoms
SET
    icon       = CASE WHEN ?1 = 1 THEN ?2 ELSE icon END,
    cover_image = CASE WHEN ?3 = 1 THEN ?4 ELSE cover_image END,
    updated_at = (strftime('%s', 'now') * 1000)
WHERE uuid = ?5
  AND is_deleted = 0;
```

`?1`/`?3` 为 "是否提供该字段" 的布尔标志位（1=提供，0=跳过）。

### 4. NoteRecord DTO

`crates/lazynote_core/src/repo/note_repo.rs` 中 `NoteRecord` 新增两字段：

```rust
pub struct NoteRecord {
    // ... 现有字段 ...
    /// User-defined icon (see Atom.icon).
    pub icon: Option<String>,
    /// User-set cover image path (see Atom.cover_image).
    pub cover_image: Option<String>,
}
```

`note_repo.rs` 的 note SELECT SQL 和 row 解析同步更新。

### 5. FFI 变更

#### 5.1 AtomListItem 扩展

```rust
pub struct AtomListItem {
    // ... 现有字段不变 ...
    /// User-defined icon (opaque string). NULL = use default view_hint icon.
    pub icon: Option<String>,
    /// User-set cover image path. NULL = fall back to preview_image or no cover.
    pub cover_image: Option<String>,
}
```

`to_atom_list_item_from_note` 映射函数追加 `icon: nr.icon, cover_image: nr.cover_image`。

已有从 `SectionAtomRow` 构建 `AtomListItem` 的路径（tasks 视图 `to_section_atom_list_item` 等辅助函数）同步更新，从 `SectionAtomRow.atom` 读取 `icon` 和 `cover_image`。

#### 5.2 新增 FFI 函数 `atom_update_metadata`

```rust
/// Updates icon and cover_image metadata for an existing atom.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `icon`: optional, pass `None` to leave unchanged, `Some(None)` to clear.
/// - `cover_image`: optional, pass `None` to leave unchanged, `Some(None)` to clear.
/// - Returns `AtomItemResponse` with updated atom on success.
/// - Returns `atom_not_found` error code when atom does not exist.
/// - icon value is stored as-is (opaque string, max 64 chars recommended).
#[flutter_rust_bridge::frb]
pub async fn atom_update_metadata(
    atom_id: String,
    icon: Option<Option<String>>,
    cover_image: Option<Option<String>>,
) -> AtomItemResponse
```

FRB 对 `Option<Option<T>>` 的 Dart 端生成为 nullable nullable 类型，适合表达"未提供 / 清空 / 设值"三态语义。

#### 5.3 新增 AtomFfiError 变体

复用现有 `AtomFfiError::AtomNotFound` 即可，无需新增错误码。

### 6. Flutter UI 变更

#### 6.1 Explorer tree — icon 显示

`apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart`：

`atom_ref` 节点当前显示固定的 `Icons.description`（或 view_hint 默认图标）。引入 icon 渲染逻辑：

```
if (icon != null && icon.isNotEmpty)
  → 判断 icon 值是否为 emoji（`icon.runes.first > 0xFF`）
    → emoji：Text(icon, style: ...) 替代 Icon widget
    → 否则：Icons.fromMaterialName(icon) 或 fallback 到 default icon
else
  → 使用当前 view_hint 默认图标（保持现状）
```

icon 数据来源：`WorkspaceNodeItem` 目前不携带 `icon`——Explorer 通过 atom_id 查询 `AtomListItem` 获取 icon，或在 `WorkspaceTreeService` 的节点数据模型中缓存 atom 的 icon。

**设计决策**：Explorer 节点 icon 渲染所需的 `icon` 值，通过扩展 `WorkspaceNodeItem`（增加 `icon` 字段，从 atom 表 JOIN 填充）或在 Flutter 侧维护 atom_id → icon 的轻量缓存。本 PR 选择**扩展 `WorkspaceNodeItem` + JOIN**，避免双重查询：

```sql
-- workspace_list_children 的 SELECT 扩展
LEFT JOIN atoms ON workspace_nodes.atom_uuid = atoms.uuid
SELECT workspace_nodes.*, atoms.icon AS atom_icon
```

对应：`WorkspaceNodeItem` 新增 `atom_icon: Option<String>`，`to_workspace_node_item` 映射函数同步更新。

#### 6.2 Notes list card — cover_image 显示优先级

Notes 列表卡片（及 Tasks/Calendar 卡片中的 preview 区域）渲染封面图时遵循 S1 R10 优先级：

```
cover_image != null → 显示 cover_image 指向的本地文件
  └─ 文件加载失败 → 回退到 preview_image
preview_image != null → 显示 preview_image
null → 不渲染封面图区域
```

Widget 层使用 `FileImage` 加载本地绝对路径；加载失败 `errorBuilder` 回退到 `preview_image`（网络/资源图）或空。

具体文件：notes list card widget（当前在 `notes_coordinator_impl.dart` 或独立 card widget，需定位后编辑）。

### 7. 数据流总览

```
Flutter UI (icon/cover_image 设置)
  → atom_update_metadata(atom_id, icon?, cover_image?) [FFI]
  → AtomRepository::update_atom_metadata() [Core repo]
  → UPDATE atoms SET icon=?, cover_image=? [SQLite migration 0013]

Flutter UI (读取)
  → query_atoms / atom_get / notes_list [FFI]
  → AtomListItem { icon, cover_image, ... }
  → Explorer: icon → 渲染个性化图标
  → List card: cover_image > preview_image > null → 渲染封面
```

### 8. 开放决策

| 问题 | 决策 |
|------|------|
| icon 最大长度 | 64 chars，Core 不做 DB 约束；FFI 层截断或返回 `invalid_icon` 错误码？本 PR：FFI 层不做截断，直接存储（owner 决策：opaque，no validation） |
| `WorkspaceNodeItem` 是否携带 `icon` | **是**（JOIN 方案），见 6.1。破坏变更需更新 `docs/api/ffi-contracts.md` |
| cover_image 加载失败回退 | Flutter `errorBuilder` 回退到 `preview_image`，Core 不参与 |

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | Migration 0013 SQL 编写 | `crates/lazynote_core/src/db/migrations/0013_icon_cover_image.sql` | ~30 min | — |
| T2 | Rust | Migration 注册 | `crates/lazynote_core/src/db/migrations/mod.rs` | ~10 min | T1 |
| T3 | Rust | Atom struct 新增两字段（含 AtomDe、构造函数） | `crates/lazynote_core/src/model/atom.rs` | ~30 min | T1 |
| T4 | Rust | atom_repo：SELECT SQL、parse_atom_row、create_atom、update_atom、ensure_connection_ready | `crates/lazynote_core/src/repo/atom_repo.rs` | ~1 hr | T3 |
| T5 | Rust | atom_repo：新增 update_atom_metadata trait 方法 + SqliteAtomRepository 实现 | `crates/lazynote_core/src/repo/atom_repo.rs` | ~1 hr | T4 |
| T6 | Rust | NoteRecord DTO 新增两字段 + note_repo SELECT + row 解析更新 | `crates/lazynote_core/src/repo/note_repo.rs` | ~45 min | T3 |
| T7 | Rust | AtomListItem 新增两字段 + to_atom_list_item_from_note + SectionAtomRow 路径更新 | `crates/lazynote_ffi/src/api.rs` | ~45 min | T4, T6 |
| T8 | Rust | 新增 atom_update_metadata FFI 函数 + AtomFfiError 适配 | `crates/lazynote_ffi/src/api.rs` | ~1 hr | T5, T7 |
| T9 | Rust | WorkspaceNodeItem 新增 atom_icon 字段 + workspace_list_children JOIN 扩展 + to_workspace_node_item 更新 | `crates/lazynote_ffi/src/api.rs` | ~1 hr | T4 |
| T10 | FFI | FRB 绑定重生成 | `scripts/gen_bindings.ps1`（执行脚本） | ~15 min | T7, T8, T9 |
| T11 | Rust | Migration 测试（0013 新装 + v12→v13 升级 + 字段读写验证） | `crates/lazynote_core/tests/migration_0013_test.rs` | ~1 hr | T1, T2 |
| T12 | Rust | atom_repo update_atom_metadata 集成测试（set/clear/留空三态） | `crates/lazynote_core/tests/atom_metadata_test.rs` | ~45 min | T5 |
| T13 | Dart | Explorer tree item 中 icon 渲染逻辑（emoji vs Material Icons vs default） | `apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart` | ~1 hr | T10 |
| T14 | Dart | Notes/Tasks/Calendar list card cover_image 优先级渲染（FileImage + errorBuilder 回退） | 目标 card widget 文件（待定位） | ~1 hr | T10 |
| T15 | Dart | Flutter widget 测试（icon 渲染逻辑、cover_image 优先级） | `apps/lazynote_flutter/test/features/notes/` | ~1 hr | T13, T14 |
| T16 | Docs | 更新 ffi-contracts.md（AtomListItem 扩展 + atom_update_metadata） | `docs/api/ffi-contracts.md` | ~30 min | T8, T9 |
| T17 | Docs | 更新 data-model.md（migration 0013 schema）、API_COMPATIBILITY.md | `docs/architecture/data-model.md`, `docs/governance/API_COMPATIBILITY.md` | ~20 min | T1 |

## Planned File Changes

- `[add]` crates/lazynote_core/src/db/migrations/0013_icon_cover_image.sql (migration 0013 SQL)
- `[edit]` crates/lazynote_core/src/db/migrations/mod.rs (注册 migration 13)
- `[edit]` crates/lazynote_core/src/model/atom.rs (Atom struct 新增 icon/cover_image，AtomDe、构造函数同步)
- `[edit]` crates/lazynote_core/src/repo/atom_repo.rs (SELECT SQL、parse_atom_row、create_atom、update_atom、ensure_connection_ready、AtomRepository trait 新增 update_atom_metadata、SqliteAtomRepository 实现)
- `[edit]` crates/lazynote_core/src/repo/note_repo.rs (NoteRecord 新增两字段、SELECT SQL + row 解析更新)
- `[edit]` crates/lazynote_ffi/src/api.rs (AtomListItem 新增两字段、WorkspaceNodeItem 新增 atom_icon、to_atom_list_item_from_note 更新、to_workspace_node_item 更新、workspace_list_children JOIN 扩展、新增 atom_update_metadata 函数)
- `[regen]` crates/lazynote_ffi/src/frb_generated.rs (FRB 自动生成)
- `[regen]` apps/lazynote_flutter/lib/core/bindings/ (FRB 自动生成)
- `[add]` crates/lazynote_core/tests/migration_0013_test.rs (migration 测试)
- `[add]` crates/lazynote_core/tests/atom_metadata_test.rs (update_atom_metadata 集成测试)
- `[edit]` apps/lazynote_flutter/lib/features/notes/explorer_tree_item.dart (icon 渲染逻辑)
- `[edit]` apps/lazynote_flutter/lib/features/notes/（notes list card widget 文件，待 T14 定位）(cover_image 优先级渲染)
- `[edit]` apps/lazynote_flutter/test/features/notes/（icon/cover 渲染 widget 测试，待定位）
- `[edit]` docs/api/ffi-contracts.md (AtomListItem 字段扩展、atom_update_metadata 函数契约)
- `[edit]` docs/architecture/data-model.md (migration 0013 schema 变更)
- `[edit]` docs/governance/API_COMPATIBILITY.md (breaking change：AtomListItem 新增字段 + WorkspaceNodeItem 新增字段)

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

### Structural verification

```bash
# 验证 migration 0013 文件存在且注册
grep -c "0013" crates/lazynote_core/src/db/migrations/mod.rs
# 预期：至少 1 匹配

# 验证 Atom struct 新增字段
grep -c "icon\|cover_image" crates/lazynote_core/src/model/atom.rs
# 预期：至少 4 匹配（struct 字段 x2 + doc comment x2）

# 验证 AtomListItem 携带新字段
grep -c "icon\|cover_image" crates/lazynote_ffi/src/api.rs
# 预期：若干匹配（struct 字段、mapping 函数、新 FFI 函数参数）

# 验证 atom_update_metadata 函数存在
grep -c "atom_update_metadata" crates/lazynote_ffi/src/api.rs
# 预期：至少 2 匹配（pub fn + 内部 impl fn）

# 验证 WorkspaceNodeItem 携带 atom_icon
grep -c "atom_icon" crates/lazynote_ffi/src/api.rs
# 预期：至少 2 匹配（struct 字段 + mapping）

# 验证 migration SQL 列名
grep -c "icon\|cover_image" crates/lazynote_core/src/db/migrations/0013_icon_cover_image.sql
# 预期：至少 2 匹配
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| `AtomListItem` 结构扩展使所有构造 `AtomListItem` 的地方产生编译错误 | MEDIUM | `cargo clippy --all -- -D warnings` 全量检查；T4 完成后立即修复所有构造路径 |
| `WorkspaceNodeItem` 新增 `atom_icon` 字段导致 Flutter 测试中硬编码构造的 mock 对象需更新 | LOW | `flutter analyze` 编译检查；Flutter 测试 mock 同步更新 |
| cover_image 为本地绝对路径，在 Windows 上路径分隔符 / 编码差异导致 `FileImage` 加载失败 | LOW | Flutter `errorBuilder` 已有回退逻辑；v0.5 迁移 managed attachments 时彻底解决 |
| workspace_list_children 的 SQL JOIN 在 atom_ref 节点 atom 被 soft-delete 后返回 NULL atom_icon | LOW | LEFT JOIN 已隐式处理 NULL（soft-deleted atom 的字段为 NULL = 使用默认图标） |
| FRB 对 `Option<Option<String>>` 的 Dart 端类型生成可能产生意外的 nullability 结构 | LOW | FRB 重生成后 `flutter analyze` 检查 + T15 widget 测试覆盖三态语义 |

## Acceptance Criteria

- [ ] Migration 0013 从空 DB 运行成功，`atoms.icon` 和 `atoms.cover_image` 列存在
- [ ] Migration 0013 从 v12 升级成功，现有 atom 行 `icon`/`cover_image` 值均为 NULL
- [ ] `Atom` struct 包含 `icon: Option<String>` 和 `cover_image: Option<String>` 字段
- [ ] `atom_update_metadata(atom_id, icon=Some(Some("📝")), cover_image=None)` 成功设置 icon，不修改 cover_image
- [ ] `atom_update_metadata(atom_id, icon=Some(None), cover_image=None)` 成功清空 icon
- [ ] `atom_update_metadata(atom_id, icon=None, cover_image=None)` 两字段均不变（幂等）
- [ ] `atom_update_metadata` 对不存在的 atom_id 返回 `error_code = "atom_not_found"`
- [ ] `AtomListItem` 包含 `icon` 和 `cover_image` 字段，notes_list/query_atoms/atom_get 返回的 item 中两字段正确填充
- [ ] `WorkspaceNodeItem` 包含 `atom_icon` 字段，`workspace_list_children` 对 atom_ref 节点正确填充 icon 值
- [ ] Explorer tree item：有 icon 的 atom_ref 节点渲染个性化图标（emoji 或 Material Icons）
- [ ] Explorer tree item：icon 为 NULL 的 atom_ref 节点渲染 view_hint 默认图标（无视觉回退 regression）
- [ ] Notes list card：`cover_image` 不为 NULL 时渲染 cover_image 指向的本地文件
- [ ] Notes list card：`cover_image` 为 NULL 但 `preview_image` 不为 NULL 时渲染 preview_image（优先级正确）
- [ ] Notes list card：`cover_image` 加载失败时回退到 `preview_image`（errorBuilder 生效）
- [ ] `cargo test --all` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] `flutter test` 全绿
- [ ] `flutter analyze` 零 warning
- [ ] `docs/api/ffi-contracts.md` 已更新（AtomListItem 字段 + atom_update_metadata 契约）
- [ ] `docs/architecture/data-model.md` 已更新（migration 0013）
- [ ] `docs/governance/API_COMPATIBILITY.md` 已更新（breaking change 记录）
- [ ] PR spec Status updated to Merged
