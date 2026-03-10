# PR-0416: Atom Overlays Sidecar + ViewMode Extension

- Proposed title: `feat(core): atom overlays sidecar with view mode and block reconciliation`
- Status: Draft

## Goal

实现 S1 R14（atom_overlays sidecar）+ S2 Phase 3 View Mode 扩展，为 Block WYSIWYG 编辑模式提供完整的持久化基础和编辑器分发路径。具体：在数据层新增 Migration #15（`content_rev` 列 + `atom_overlays` 表），实现 `OverlayRepository`、内容版本号自增逻辑、markdown AST 解析与 reconciliation 算法；在 FFI 层新增 `atom_get_overlay`/`atom_save_overlay`；在 Flutter 层实现 `ViewMode` 枚举、`EditorResolver.resolve(contentType, viewMode)` 扩展签名、`TabEntry.viewMode` 字段，并注册 `block`/`preview` 两个 pane 骨架。

**实现后效果**：用户可通过 Tab 菜单在 source / block / preview 三种模式间切换，切换时 reconciliation 在后台执行（100ms 超时），Block WYSIWYG pane 能持久化 block 元数据并在二次打开时恢复。

前置条件：PR-0415（migration 14 已落地，本 PR migration 15 接续）、PR-0414（migration 13）、PR-0413（新 FFI 体系 + Flutter thin client 已就位，`atom_update_content` / `atom_get` 可用）

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| S1 裁决（R14） | `docs/architecture/rulings/S1-atom-projection.md` §R14 | overlay 表结构、stale 判定、content_rev 约束、reconciliation 协议约束 |
| S2 裁决（Phase 3 扩展） | `docs/architecture/rulings/S2-tab-draft-save-ownership.md` §View Mode 扩展 | ViewMode 枚举定义、resolve 签名扩展、TabEntry.viewMode 字段 |
| DI-4 Q1 补充 | `docs/reports/v0.3/design-discussions/DI-4-buffer-sync-model.md` §Q1 补充 | Reconciliation 协议完整约束（多维匹配信号、orphan 处理、超时策略、三路 EditOp、运行时层级模型） |
| 模块规范 | `docs/architecture/modules/core-editor/editor-resolver.md` | View Mode 扩展的 Dart 侧接口规范 |
| 现有实现 | `apps/lazynote_flutter/lib/core/editor/editor_resolver.dart` | 需扩展：`resolve()` 签名 + 注册表结构 |
| 现有实现 | `apps/lazynote_flutter/lib/core/editor/editor_group_model.dart` | 需扩展：`TabEntry.viewMode` 字段 |
| 现有实现 | `apps/lazynote_flutter/lib/core/editor/layout_persistence.dart` | 需更新：`schema_version` 升级以持久化 viewMode |
| 现有实现 | `crates/lazynote_ffi/src/api.rs` | 需新增 FFI 函数 |
| 设计参考 | `docs/product/ideas/rich-block-editing-architecture.md` | 三层 Layer 模型、Block WYSIWYG 完整架构参考 |

---

## Scope

In scope:

**Rust Core（数据层）**
- Migration #15：`atoms.content_rev INTEGER NOT NULL DEFAULT 0` + `atom_overlays` 表
- `content_rev` 自增逻辑：所有写 `atoms.content` 的 repo 方法在同一事务内 `content_rev = content_rev + 1`
- `OverlayRepository` trait + `SqliteOverlayRepository`：`get_overlay(atom_uuid)` / `save_overlay(atom_uuid, block_meta)` / `delete_overlay(atom_uuid)`
- `ReconcileService`：markdown → block tree 对齐算法，使用 `pulldown-cmark` 解析 AST
- Reconciliation 约束遵循 DI-4 Q1 补充：多维匹配（block type + 内容指纹 + 相对顺序 LCS）、orphan 集合构建（不静默删除）、100ms 预算门
- Core 内部 stale 判定：`atom.content_rev > overlay.content_rev_at_sync`

**FFI 层**
- `atom_get_overlay(caller, atom_id)` → `AtomOverlayResponse { block_meta: Option<String>, is_stale: bool, overlay_rev: Option<i64> }`
- `atom_save_overlay(caller, atom_id, block_meta)` → `AtomOverlaySaveResponse { overlay_rev: i64 }`
- FRB 绑定重生成

**Flutter 层**
- `ViewMode` 枚举：`source | block | preview | inline`（`inline` 标记为 reserved，v0.4 不注册实现）
- `EditorResolver` 签名扩展：`resolve(contentType, {ViewMode viewMode = ViewMode.source})`；注册表 key 改为 `(contentType, viewMode)` 复合键
- `TabEntry.viewMode` 字段：`final ViewMode viewMode`，默认 `ViewMode.source`
- `LayoutPersistence.schema_version` 升级到 `2`（v1 可无损升级：无 viewMode 字段的 tab 默认 source）
- `BlockEditorPane` 骨架注册：`(markdown, block)` → 占位 widget（显示 block_meta JSON 调试视图，不实现完整 block WYSIWYG 渲染）
- `PreviewEditorPane`：`(markdown, preview)` → 只读 markdown 渲染（消费 `buffer.content`，内部 300ms 去抖）
- `OverlayService`（Flutter 层协调器）：`loadOverlay(atomId)` / `saveOverlay(atomId, blockMeta)` / `isStale(atomId)` — 封装 FFI 调用，由 `EditorShellService` 或 feature chrome 在模式切换时调用
- Tab context menu 新增"切换视图模式"选项（触发 `EditorShellService.setTabViewMode`）
- Migration 测试、Dart overlay 服务测试、reconcile 单元测试

Out of scope:

- 完整的 Block WYSIWYG 编辑器实现（`BlockEditorPane` 本 PR 仅为骨架）— 拆分到后续独立 PR
- Inline WYSIWYG（`ViewMode.inline`）实现 — 仅保留枚举占位
- Orphan blocks 的用户 UI（对话框/侧栏展示）— 本 PR 仅构建 orphan 集合并记录日志
- canvas / conversation content_type 的 ViewMode 注册 — 无关联 content_type
- Sync provider 集成（overlay 随 content 同步的协议）
- FTS5 索引修改（block_meta 不加入 FTS5）

---

## Design

### 1. Migration #15 — Schema

**文件**：`crates/lazynote_core/src/db/migrations/0015_atom_overlays.sql`

```sql
-- Step 1: 在 atoms 表新增 content_rev 列
ALTER TABLE atoms ADD COLUMN content_rev INTEGER NOT NULL DEFAULT 0;

-- Step 2: atom_overlays sidecar 表
CREATE TABLE atom_overlays (
    atom_uuid             TEXT NOT NULL PRIMARY KEY,
    block_meta            TEXT NOT NULL,
    overlay_rev           INTEGER NOT NULL DEFAULT 1,
    content_rev_at_sync   INTEGER NOT NULL DEFAULT 0,
    created_at            INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
    updated_at            INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
    FOREIGN KEY (atom_uuid) REFERENCES atoms(uuid) ON DELETE CASCADE
);

-- Step 3: 索引（按 atom_uuid 查已有主键，无需额外索引）
-- ON DELETE CASCADE 保证 atom soft/hard 删除时 overlay 自动清理
```

**约束说明**：
- `content_rev DEFAULT 0`：全量回填为 0，无已有 overlay，stale 判定不受影响
- `ON DELETE CASCADE`：仅在 hard-delete（vacuum/maintenance）时触发；业务路径的 soft-delete（`is_deleted = 1`）不触发。**Rule C 合规说明**：Rule C 要求业务路径删除使用 soft-delete；`atom_overlays` 是派生缓存（非独立业务实体），不含 `is_deleted` 列，其生命周期完全从属于宿主 Atom。当 Atom soft-delete 时 overlay 保留（CASCADE 不触发）；当 Atom hard-delete（仅 maintenance/vacuum 路径，已有 Ruling 授权）时 overlay 随之清理。此设计与 Rule C 不冲突。
- overlay 表不设 `is_deleted`：有损降级（丢失 overlay）安全，overlay 行可硬删除

### 2. content_rev 自增逻辑

**位置**：`crates/lazynote_core/src/repo/atom_repo.rs`

在 `SqliteAtomRepository` 的所有写 `content` 字段的方法中，在同一事务内执行 `content_rev = content_rev + 1`：

```sql
-- atom_update_content 内部（示例）
UPDATE atoms
   SET content      = :content,
       content_rev  = content_rev + 1,
       title        = :title,
       preview_text = :preview_text,
       updated_at   = :updated_at
 WHERE uuid = :atom_uuid
   AND is_deleted   = 0;
```

**规则**：
- 只有写 `content` 列时才自增，其他字段（tags、status、time fields）更新不触发
- Flutter 侧**不**感知 `content_rev` 数字；stale 判定完全在 Core 内部执行
- `atom_get_overlay` 返回的 `is_stale` 由 Core 计算：`atom.content_rev > overlay.content_rev_at_sync`

### 3. OverlayRepository

**文件**：`crates/lazynote_core/src/repo/overlay_repo.rs`

```rust
pub struct AtomOverlay {
    pub atom_uuid: AtomId,
    pub block_meta: String,          // JSON blob，Core 视为 opaque string
    pub overlay_rev: i64,
    pub content_rev_at_sync: i64,
}

pub trait OverlayRepository {
    /// 返回 overlay + stale 标志。atom 不存在或无 overlay 返回 Ok(None)。
    fn get_overlay(&self, atom_uuid: &AtomId) -> Result<Option<(AtomOverlay, bool)>>;

    /// 写入/更新 overlay，同步更新 content_rev_at_sync 到当前 atom.content_rev。
    /// overlay_rev 自增。返回新的 overlay_rev。
    fn save_overlay(&self, atom_uuid: &AtomId, block_meta: &str) -> Result<i64>;

    /// 删除 overlay（用于模式退出或清理）。
    fn delete_overlay(&self, atom_uuid: &AtomId) -> Result<()>;
}

pub struct SqliteOverlayRepository {
    pub conn: Arc<Mutex<Connection>>,
}
```

**stale 计算**（在 `get_overlay` 内部）：

```sql
SELECT o.block_meta, o.overlay_rev, o.content_rev_at_sync,
       a.content_rev
  FROM atom_overlays o
  JOIN atoms a ON a.uuid = o.atom_uuid
 WHERE o.atom_uuid = :atom_uuid
   AND a.is_deleted = 0;
-- is_stale = (a.content_rev > o.content_rev_at_sync)
```

**save_overlay 事务**（保证原子性）：

```sql
-- 在 save_overlay 事务内
INSERT INTO atom_overlays (atom_uuid, block_meta, overlay_rev, content_rev_at_sync, updated_at)
VALUES (:atom_uuid, :block_meta, 1,
        (SELECT content_rev FROM atoms WHERE uuid = :atom_uuid),
        :now)
ON CONFLICT(atom_uuid) DO UPDATE SET
    block_meta          = excluded.block_meta,
    overlay_rev         = overlay_rev + 1,
    content_rev_at_sync = (SELECT content_rev FROM atoms WHERE uuid = :atom_uuid),
    updated_at          = excluded.updated_at;
```

### 4. ReconcileService — Markdown AST 解析与对齐算法

**Rust crate 选型**：`pulldown-cmark`（已是 Rust markdown 生态标准，Apache-2.0 / MIT，无引入新依赖风险）

**文件**：`crates/lazynote_core/src/service/reconcile_service.rs`

```rust
/// 从 markdown 文本解析结构化 blocks。
pub fn parse_markdown_blocks(content: &str) -> Vec<MarkdownBlock>;

/// 核心 reconciliation：将旧 sidecar blocks 与新 markdown blocks 对齐。
///
/// 输出：
/// - matched: Vec<(old_block_id, new_block)> — 匹配成功，保留 block ID
/// - new_blocks: Vec<MarkdownBlock>         — 新增 block（无旧 ID）
/// - orphans: Vec<SidecarBlock>             — 未匹配旧块，进入 orphan 集合
pub fn reconcile(
    old_sidecar: &[SidecarBlock],
    new_blocks: &[MarkdownBlock],
) -> ReconcileResult;
```

**匹配算法（多维信号）**：

```
1. 结构相似度计算（per block pair）：
   score = w_type  * (block_type 一致 ? 1.0 : 0.0)      // 权重 0.4
         + w_content * content_fingerprint_similarity()   // 权重 0.4，Jaccard 词集
         + w_order * order_lcs_score()                    // 权重 0.2，LCS 归一化

2. 匈牙利算法（Hungarian）求最大权匹配
   阈值：score < 0.3 → 视为未匹配（进入 orphan 或 new）

3. 未匹配旧块 → orphans（ReconcileResult.orphans，不丢弃）
   未匹配新块 → 生成新 UUID block ID
```

**内容相似度**（`content_fingerprint_similarity`）：
- 取 block 的纯文本内容（去 markdown 语法），建词集
- Jaccard = |A ∩ B| / |A ∪ B|
- 空 block pair：type 一致给 0.5，不一致给 0

**100ms 超时策略**：
- reconciliation 在 Tokio task 中执行（`tokio::time::timeout(Duration::from_millis(100), ...)`）
- 超时 → 返回 `ReconcileResult::Timeout`，调用方展示 stale 指示，不阻塞 UI
- 后台继续完成（spawn 独立 task），完成后通过 FFI event 通知 Flutter（v0.4 暂用 polling 方案）
- **本 PR 超时后台实现简化**：超时返回 `Timeout` 枚举变体，不实际 spawn 后台（后台 spawn 留给后续 PR）

**ReconcileResult 结构**：

```rust
pub enum ReconcileResult {
    Ok {
        matched: Vec<MatchedBlock>,    // (old_block_id, new_markdown_block)
        new_blocks: Vec<MarkdownBlock>,
        orphans: Vec<SidecarBlock>,
        new_block_meta_json: String,   // 序列化后可直接送 save_overlay
    },
    Timeout,  // 本 PR 简化：超时即返回，不 spawn 后台
}
```

**SidecarBlock 内部结构**（block_meta JSON 的 Dart/Rust 共享约定）：

```json
{
  "schema_version": 1,
  "blocks": [
    {
      "id": "blk-uuid-v4",
      "type": "heading | paragraph | code_block | list_item | blockquote | thematic_break",
      "content_fingerprint": "sha256_first_8_bytes_hex",
      "attrs": { }
    }
  ]
}
```

- `content_fingerprint` 在每次 reconcile 后更新，用于快速判断是否需要完整相似度计算
- `attrs`：用户在 block 模式设置的额外属性（颜色、折叠态等），匹配成功时保留

### 5. FFI 新增函数

**文件**：`crates/lazynote_ffi/src/api.rs`

```rust
/// Response envelope for atom_get_overlay.
pub struct AtomOverlayResponse {
    pub ok: bool,
    pub error_code: String,
    pub message: String,
    pub block_meta: Option<String>,   // JSON string，无 overlay 时为 None
    pub is_stale: bool,               // content_rev > content_rev_at_sync
    pub overlay_rev: Option<i64>,
}

/// Response envelope for atom_save_overlay.
pub struct AtomOverlaySaveResponse {
    pub ok: bool,
    pub error_code: String,
    pub message: String,
    pub overlay_rev: i64,             // 新版本号（save 成功后）
}

/// 获取指定 atom 的 overlay 元数据。
///
/// Core 内部判定 stale（content_rev > content_rev_at_sync）。
/// Flutter 不需要感知 content_rev 数字，只读 is_stale 布尔值。
pub async fn atom_get_overlay(
    caller: CallerContext,
    atom_id: String,
) -> AtomOverlayResponse;

/// 持久化 block 元数据 sidecar。
///
/// block_meta: JSON string（SidecarBlock schema v1）。
/// 同一事务内同步 content_rev_at_sync 为当前 atom.content_rev。
pub async fn atom_save_overlay(
    caller: CallerContext,
    atom_id: String,
    block_meta: String,
) -> AtomOverlaySaveResponse;
```

### 6. ViewMode 枚举（Dart）

**文件**：`apps/lazynote_flutter/lib/core/editor/view_mode.dart`（新增）

```dart
/// Per-pane view mode for an editor tab.
///
/// Design source: S2 Phase 3 View Mode 扩展 + DI-4 Q1 补充（三种编辑范式）。
/// v0.4: source / block / preview 已注册实现。inline 保留占位，未注册。
enum ViewMode {
  /// Plain text markdown source editing (MarkdownEditorPane).
  source,

  /// Block WYSIWYG editing (BlockEditorPane). Requires atom_overlays sidecar.
  block,

  /// Read-only rendered markdown preview (PreviewEditorPane).
  preview,

  /// [Reserved] Inline WYSIWYG (Typora-style). Not implemented in v0.4.
  inline,
}
```

### 7. TabEntry.viewMode 字段扩展

**文件**：`apps/lazynote_flutter/lib/core/editor/editor_group_model.dart`

```dart
@immutable
class TabEntry {
  const TabEntry({
    required this.atomId,
    required this.title,
    this.viewMode = ViewMode.source,  // 新增字段，默认 source
  });

  final String atomId;
  final String title;
  final ViewMode viewMode;            // per-tab view mode

  TabEntry copyWith({String? atomId, String? title, ViewMode? viewMode}) {
    return TabEntry(
      atomId: atomId ?? this.atomId,
      title: title ?? this.title,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  // == 和 hashCode 需加入 viewMode
}
```

**序列化扩展**（`toJson` / `fromJson`）：
- `toJson`：增加 `'viewMode': viewMode.name`
- `fromJson`：`ViewMode.values.byName(json['viewMode'] ?? 'source')`（容错：未知值 fallback source）

### 8. EditorResolver 签名扩展

**文件**：`apps/lazynote_flutter/lib/core/editor/editor_resolver.dart`

```dart
// 注册表 key 改为复合 record (contentType, viewMode)
typedef _RegistryKey = (String contentType, ViewMode viewMode);

class EditorResolver {
  final Map<_RegistryKey, EditorPaneBuilder> _registry = {};

  /// Registers a builder for [contentType] + [viewMode] combination.
  void register(
    String contentType,
    EditorPaneBuilder builder, {
    ViewMode viewMode = ViewMode.source,
  });

  /// Resolves builder. Unknown combination → error placeholder (DI-10 Q3).
  EditorPaneBuilder resolve(
    String contentType, {
    ViewMode viewMode = ViewMode.source,
  });
}
```

**向后兼容**：`register(contentType, builder)` 无 viewMode 参数时默认 `ViewMode.source`，v0.3 注册调用无需修改。

**v0.4 注册表**（在 `EditorShellService` 构造函数内执行）：

```dart
// v0.3 已有
_resolver.register('markdown', markdownPaneBuilder);
// v0.4 新增
_resolver.register('markdown', blockEditorPaneBuilder, viewMode: ViewMode.block);
_resolver.register('markdown', previewEditorPaneBuilder, viewMode: ViewMode.preview);
// inline 保留占位，未注册（调用时返回 error placeholder）
```

### 9. LayoutPersistence schema_version 升级

**当前版本**：`_currentSchemaVersion = 1`
**升级到**：`_currentSchemaVersion = 2`

**升级策略（v1 → v2 兼容）**：
- v1 JSON 中 tab 对象无 `viewMode` 字段
- `fromJson` 时：`ViewMode.values.byName(json['viewMode'] ?? 'source')` — 无字段则 default source
- v2 JSON 写入新增 `viewMode` 字段
- v1 文件升级后 schema_version 字段更新为 2（下次写入）

**recovery 行为不变**：`schema_version > _currentSchemaVersion`（即 > 2）仍设 `_skipOverwrite = true`，回退默认单 pane。

### 10. OverlayService（Flutter 层）

**文件**：`apps/lazynote_flutter/lib/core/editor/overlay_service.dart`（新增）

封装 overlay FFI 调用，供 `EditorShellService` 在 view mode 切换时调用：

```dart
/// Coordinates overlay FFI calls for view mode transitions.
///
/// Injected into EditorShellService as a closure or thin service.
class OverlayService {
  OverlayService({
    required AtomGetOverlayInvoker getOverlayInvoker,
    required AtomSaveOverlayInvoker saveOverlayInvoker,
  });

  /// Loads overlay for [atomId]. Returns null if no overlay exists.
  /// is_stale from Core response → triggers reconcile before block mode entry.
  Future<OverlayData?> loadOverlay(String atomId);

  /// Saves [blockMeta] JSON for [atomId]. Returns new overlay_rev.
  Future<int> saveOverlay(String atomId, String blockMeta);
}

@immutable
class OverlayData {
  const OverlayData({
    required this.blockMeta,
    required this.isStale,
    required this.overlayRev,
  });
  final String blockMeta;     // JSON string
  final bool isStale;
  final int overlayRev;
}
```

**注入形式**（保持可测试性）：
- `AtomGetOverlayInvoker = Future<AtomOverlayResponse> Function({...})`（typedef）
- `AtomSaveOverlayInvoker = Future<AtomOverlaySaveResponse> Function({...})`（typedef）

### 11. EditorShellService.setTabViewMode

**文件**：`apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart`（扩展）

```dart
/// Switches the view mode for [atomId] in [groupId].
///
/// If switching to [ViewMode.block]:
///   1. Load overlay via OverlayService.loadOverlay(atomId)
///   2. If is_stale → trigger reconciliation (placeholder in this PR)
///   3. Update TabEntry.viewMode → notifyListeners
///
/// If switching to [ViewMode.source] from block:
///   1. Serialize block model → markdown → buffer.edit()  (normal save path)
///   2. Save overlay via OverlayService.saveOverlay(atomId, blockMeta)
///   3. Update TabEntry.viewMode → notifyListeners
void setTabViewMode(String groupId, String atomId, ViewMode viewMode);
```

**本 PR 的 reconciliation 占位**：`is_stale` 为 true 时，记录日志 + 在 BlockEditorPane 顶部显示 banner "内容已更新，正在重新对齐块..."，不执行完整 reconcile（留给后续实现 BlockEditorPane 时集成）。

### 12. BlockEditorPane 骨架

**文件**：`apps/lazynote_flutter/lib/core/editor/block_editor_pane.dart`（新增）

本 PR 仅为调试/骨架实现，展示 block_meta JSON 内容，验证数据流通路：

```dart
class BlockEditorPane extends StatefulWidget {
  const BlockEditorPane({super.key, required this.buffer, this.requestInitialFocus = false});
  final EditBuffer buffer;
  final bool requestInitialFocus;
  // ...
}
```

显示内容：
- 若无 overlay：提示"Block 数据不可用（无 overlay）"
- 若有 overlay + not stale：显示 block_meta JSON 的格式化调试视图
- 若 is_stale：显示 banner "内容已更新，块对齐待处理"

### 13. PreviewEditorPane 实现

**文件**：`apps/lazynote_flutter/lib/core/editor/preview_editor_pane.dart`（新增）

只读渲染，消费 `buffer.content`，不调用 `buffer.edit()`：

```dart
class PreviewEditorPane extends StatefulWidget {
  const PreviewEditorPane({super.key, required this.buffer});
  final EditBuffer buffer;
  // ...
}
```

- 内部去抖：`_debounceTimer`（300ms），收到 buffer 变更通知后去抖渲染（DI-4 Q1 高成本消费者策略）
- Markdown 渲染：使用 Flutter `flutter_markdown` package（已在项目中）
- 只读：widget 不设置 focus，不注册 `buffer.edit()` 回调

### 14. Block 编辑保存路径

Block 编辑的数据流（完整路径，本 PR 骨架中 T1 对应图）：

```
用户在 BlockEditorPane 中编辑 block
  → Block 操作序列化为 markdown 字符串（block → serializer → markdown）
  → buffer.edit(markdownString)                    ← 正常 content 保存路径
    → debounce → persistFn → atom_update_content   ← content_rev 自增
  → block 元数据（block IDs + attrs）序列化为 JSON
  → OverlayService.saveOverlay(atomId, blockMetaJson)  ← 独立 overlay 保存
    → atom_save_overlay FFI                        ← content_rev_at_sync 同步
```

**保存时机**：block edit 每次调用 `buffer.edit()` 走正常自动保存路径（1.5s debounce）；overlay 保存在用户停止编辑 3s 后（longer debounce，避免频繁写 overlay 表）。两路保存独立，不耦合。

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Rust | Migration #15 SQL（content_rev + atom_overlays） | `crates/lazynote_core/src/db/migrations/0015_atom_overlays.sql` | S | — |
| T2 | Rust | Migration 注册到 MIGRATIONS 数组 | `crates/lazynote_core/src/db/migrations/mod.rs` | S | T1 |
| T3 | Rust | content_rev 自增逻辑接入 atom_repo | `crates/lazynote_core/src/repo/atom_repo.rs` | M | T1 |
| T4 | Rust | OverlayRepository trait + SqliteOverlayRepository | `crates/lazynote_core/src/repo/overlay_repo.rs` | M | T1 |
| T5 | Rust | repo/mod.rs 导出 OverlayRepository | `crates/lazynote_core/src/repo/mod.rs` | S | T4 |
| T6 | Rust | pulldown-cmark 依赖引入 + MarkdownBlock 类型定义 | `crates/lazynote_core/Cargo.toml`, `src/service/reconcile_service.rs` | S | — |
| T7 | Rust | parse_markdown_blocks + SidecarBlock 类型 | `crates/lazynote_core/src/service/reconcile_service.rs` | M | T6 |
| T8 | Rust | reconcile 多维匹配算法（Hungarian + LCS + Jaccard） | `crates/lazynote_core/src/service/reconcile_service.rs` | L | T7 |
| T9 | Rust | ReconcileResult 枚举 + 100ms 超时占位 | `crates/lazynote_core/src/service/reconcile_service.rs` | S | T8 |
| T10 | Rust | lib.rs 导出 ReconcileService + OverlayRepository | `crates/lazynote_core/src/lib.rs` | S | T4 T9 |
| T11 | FFI | AtomOverlayResponse + AtomOverlaySaveResponse struct 定义 | `crates/lazynote_ffi/src/api.rs` | S | T4 |
| T12 | FFI | atom_get_overlay 实现 | `crates/lazynote_ffi/src/api.rs` | M | T4 T11 |
| T13 | FFI | atom_save_overlay 实现 | `crates/lazynote_ffi/src/api.rs` | M | T4 T11 |
| T14 | FFI | FRB 绑定重生成 | `scripts/gen_bindings.ps1` | S | T12 T13 |
| T15 | Rust | Migration 测试（全新安装 + v14 升级 + overlay CRUD） | `crates/lazynote_core/tests/migration_0015_test.rs` | M | T1 T4 |
| T16 | Rust | ReconcileService 单元测试（匹配、orphan、超时） | `crates/lazynote_core/tests/reconcile_service_test.rs` | M | T8 T9 |
| T17 | Dart | ViewMode 枚举 | `apps/lazynote_flutter/lib/core/editor/view_mode.dart` | S | — |
| T18 | Dart | TabEntry.viewMode 字段 + 序列化扩展 | `apps/lazynote_flutter/lib/core/editor/editor_group_model.dart` | S | T17 |
| T19 | Dart | LayoutPersistence schema_version 升级（1 → 2）+ v1 兼容读取 | `apps/lazynote_flutter/lib/core/editor/layout_persistence.dart` | S | T18 |
| T20 | Dart | EditorResolver 注册表复合 key + resolve 签名扩展 | `apps/lazynote_flutter/lib/core/editor/editor_resolver.dart` | M | T17 |
| T21 | Dart | OverlayService + 类型定义 invoker typedef | `apps/lazynote_flutter/lib/core/editor/overlay_service.dart` | M | T14 |
| T22 | Dart | PreviewEditorPane（只读渲染，300ms 去抖） | `apps/lazynote_flutter/lib/core/editor/preview_editor_pane.dart` | M | T20 |
| T23 | Dart | BlockEditorPane 骨架（调试视图） | `apps/lazynote_flutter/lib/core/editor/block_editor_pane.dart` | M | T20 T21 |
| T24 | Dart | EditorShellService.setTabViewMode + OverlayService 注入 | `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart` | M | T21 T22 T23 |
| T25 | Dart | EditorShellService 构造函数注册 block/preview pane | `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart` | S | T22 T23 |
| T26 | Dart | Tab context menu：切换视图模式选项 | `apps/lazynote_flutter/lib/features/notes/note_tab_strip.dart` | M | T24 |
| T27 | Dart | Dart 测试：OverlayService mock FFI 调用 | `apps/lazynote_flutter/test/core/editor/overlay_service_test.dart` | M | T21 |
| T28 | Dart | Dart 测试：TabEntry 序列化（含 viewMode v1/v2 兼容） | `apps/lazynote_flutter/test/core/editor/editor_group_model_test.dart` | S | T18 |
| T29 | Dart | Dart 测试：EditorResolver 复合 key + fallback | `apps/lazynote_flutter/test/core/editor/editor_resolver_test.dart` | S | T20 |
| T30 | Docs | 更新 ffi-contracts.md（新增 overlay 函数） | `docs/api/ffi-contracts.md` | S | T13 |
| T31 | Docs | 更新 API_COMPATIBILITY.md（非 breaking 新增） | `docs/governance/API_COMPATIBILITY.md` | S | T13 |

---

## Planned File Changes

**Rust Core**
- `[add]` crates/lazynote_core/src/db/migrations/0015_atom_overlays.sql (Migration #15)
- `[edit]` crates/lazynote_core/src/db/migrations/mod.rs (注册 migration 15)
- `[edit]` crates/lazynote_core/src/repo/atom_repo.rs (content_rev 自增逻辑)
- `[add]` crates/lazynote_core/src/repo/overlay_repo.rs (OverlayRepository trait + SqliteOverlayRepository)
- `[edit]` crates/lazynote_core/src/repo/mod.rs (导出 OverlayRepository)
- `[edit]` crates/lazynote_core/Cargo.toml (新增 pulldown-cmark 依赖)
- `[add]` crates/lazynote_core/src/service/reconcile_service.rs (ReconcileService)
- `[edit]` crates/lazynote_core/src/service/mod.rs (导出 ReconcileService)
- `[edit]` crates/lazynote_core/src/lib.rs (重导出 ReconcileService、OverlayRepository)
- `[add]` crates/lazynote_core/tests/migration_0015_test.rs
- `[add]` crates/lazynote_core/tests/reconcile_service_test.rs

**FFI**
- `[edit]` crates/lazynote_ffi/src/api.rs (新增 atom_get_overlay、atom_save_overlay + 两个 response struct)
- `[regen]` crates/lazynote_ffi/src/frb_generated.rs (FRB 自动生成)
- `[regen]` apps/lazynote_flutter/lib/core/bindings/ (FRB 自动生成)

**Flutter**
- `[add]` apps/lazynote_flutter/lib/core/editor/view_mode.dart (ViewMode 枚举)
- `[edit]` apps/lazynote_flutter/lib/core/editor/editor_group_model.dart (TabEntry.viewMode + 序列化)
- `[edit]` apps/lazynote_flutter/lib/core/editor/layout_persistence.dart (schema_version 2 + v1 兼容)
- `[edit]` apps/lazynote_flutter/lib/core/editor/editor_resolver.dart (复合 key 注册表 + resolve 签名扩展)
- `[add]` apps/lazynote_flutter/lib/core/editor/overlay_service.dart (OverlayService + invoker typedef)
- `[add]` apps/lazynote_flutter/lib/core/editor/preview_editor_pane.dart (PreviewEditorPane)
- `[add]` apps/lazynote_flutter/lib/core/editor/block_editor_pane.dart (BlockEditorPane 骨架)
- `[edit]` apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart (setTabViewMode + OverlayService 注入 + pane 注册)
- `[edit]` apps/lazynote_flutter/lib/features/notes/note_tab_strip.dart (切换视图模式 context menu 项)
- `[add]` apps/lazynote_flutter/test/core/editor/overlay_service_test.dart
- `[edit]` apps/lazynote_flutter/test/core/editor/editor_group_model_test.dart (viewMode 序列化测试)
- `[edit]` apps/lazynote_flutter/test/core/editor/editor_resolver_test.dart (复合 key + fallback 测试)

**Docs**
- `[edit]` docs/api/ffi-contracts.md (新增 atom_get_overlay、atom_save_overlay 契约)
- `[edit]` docs/governance/API_COMPATIBILITY.md (非 breaking 新增记录)

---

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
# 验证 Migration #15 已注册
grep -c "0015" crates/lazynote_core/src/db/migrations/mod.rs
# 预期：至少 1 匹配

# 验证 atom_overlays 表定义存在
grep -c "atom_overlays" crates/lazynote_core/src/db/migrations/0015_atom_overlays.sql
# 预期：至少 1 匹配

# 验证 content_rev 自增 SQL 在 atom_repo
grep -c "content_rev" crates/lazynote_core/src/repo/atom_repo.rs
# 预期：至少 1 匹配

# 验证 FFI 新函数已导出
grep -c "atom_get_overlay\|atom_save_overlay" crates/lazynote_ffi/src/api.rs
# 预期：至少 2 匹配

# 验证 ViewMode 枚举存在
grep -c "ViewMode" apps/lazynote_flutter/lib/core/editor/view_mode.dart
# 预期：至少 4 匹配（source/block/preview/inline）

# 验证 schema_version 已升级
grep -c "_currentSchemaVersion = 2" apps/lazynote_flutter/lib/core/editor/layout_persistence.dart
# 预期：1 匹配

# 验证 EditorResolver 使用复合 key
grep -c "ViewMode" apps/lazynote_flutter/lib/core/editor/editor_resolver.dart
# 预期：至少 2 匹配

# 验证 Rule E：block/preview pane 不引用 features/ 内部模块
grep -rn "lib/features/" apps/lazynote_flutter/lib/core/editor/block_editor_pane.dart
# 预期：零匹配
grep -rn "lib/features/" apps/lazynote_flutter/lib/core/editor/preview_editor_pane.dart
# 预期：零匹配
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| pulldown-cmark 解析行为与 Flutter markdown 渲染不一致，导致 block 边界漂移 | MEDIUM | reconcile 单元测试覆盖常见 markdown 结构（heading/list/code_block/paragraph）；骨架阶段不执行用户可见 block 渲染，降低用户影响 |
| content_rev 自增逻辑遗漏某个写 content 路径，导致 stale 判定失效 | MEDIUM | `grep -n "UPDATE atoms SET content"` 全量扫描 + migration 测试断言 stale 正确触发 |
| LayoutPersistence v1 → v2 升级导致现有用户 layout 丢失 | LOW | fromJson 明确 fallback source，layout 结构不变，仅 tab 新增字段，upgrading 测试覆盖 |
| EditorResolver 复合 key 重构破坏已有 markdown source pane | MEDIUM | 保持 register(contentType, builder) 默认 source 不变；EditorResolver 测试覆盖 v0.3 已有注册路径 |
| ON DELETE CASCADE 在 soft-delete 路径误删 overlay | LOW | soft-delete 写 `is_deleted=1`，不触发 CASCADE（Rule C 合规：overlay 是派生缓存，非独立业务实体）；测试断言 soft-delete 后 overlay 仍存在 |
| BlockEditorPane 骨架 + OverlayService FFI 路径端到端未验证 | LOW | integration smoke test：创建 atom → atom_get_overlay（无 overlay）→ atom_save_overlay → atom_get_overlay（has overlay, not stale）→ atom_update_content → atom_get_overlay（is_stale=true） |

---

## Acceptance Criteria

- [ ] Migration #15 从空 DB 执行成功：`atoms.content_rev` 列存在，`atom_overlays` 表存在
- [ ] Migration #15 从 v14 升级成功：现有 atom 的 `content_rev = 0`，无 overlay 行
- [ ] `atom_update_content` 调用后，对应 atom 的 `content_rev` 自增 1（DB 值验证）
- [ ] `atom_get_overlay` 返回：无 overlay 时 `block_meta = null, is_stale = false`
- [ ] `atom_save_overlay` 成功保存 block_meta，`content_rev_at_sync = 当前 atom.content_rev`，返回 `overlay_rev >= 1`
- [ ] `atom_update_content` 之后 `atom_get_overlay` 返回 `is_stale = true`
- [ ] `atom_save_overlay` 之后 `atom_get_overlay` 返回 `is_stale = false`
- [ ] ReconcileService 单元测试：100% heading/paragraph/code_block/list_item 正确匹配（无内容变更场景）
- [ ] ReconcileService 单元测试：40% 内容变更场景（段落替换）orphan 集合非空，匹配段落保留 block ID
- [ ] ReconcileService 单元测试：全量新增 markdown（旧 sidecar 为空）所有 block 生成新 UUID ID
- [ ] `ViewMode` 枚举包含 `source / block / preview / inline` 四个值
- [ ] `TabEntry.viewMode` 默认 `ViewMode.source`，序列化/反序列化正确
- [ ] `TabEntry` fromJson v1 格式（无 viewMode 字段）反序列化后 viewMode = source（容错测试）
- [ ] `LayoutPersistence._currentSchemaVersion == 2`，v1 layout 文件可无损升级加载
- [ ] `EditorResolver.resolve('markdown', viewMode: ViewMode.block)` 返回 BlockEditorPane builder
- [ ] `EditorResolver.resolve('markdown', viewMode: ViewMode.preview)` 返回 PreviewEditorPane builder
- [ ] `EditorResolver.resolve('markdown', viewMode: ViewMode.inline)` 返回 error placeholder（未注册）
- [ ] `EditorResolver.resolve('markdown')` 无 viewMode 参数时仍返回 MarkdownEditorPane（向后兼容）
- [ ] `BlockEditorPane` 显示 block_meta 调试内容（骨架验证），无 Rule E 违反（不引用 features/ 内部）
- [ ] `PreviewEditorPane` 正确渲染 buffer.content 为只读 markdown，不调用 buffer.edit()
- [ ] `EditorShellService.setTabViewMode` 调用后 group 中对应 tab 的 viewMode 更新
- [ ] Note tab strip 显示"切换视图模式"菜单项，点击可触发 source/block/preview 切换
- [ ] `cargo test --all` 全绿
- [ ] `flutter test` 全绿
- [ ] `cargo clippy --all -- -D warnings` 零 warning
- [ ] `flutter analyze` 零 warning
- [ ] `docs/api/ffi-contracts.md` 新增 atom_get_overlay / atom_save_overlay 契约
- [ ] PR spec Status updated to Merged
