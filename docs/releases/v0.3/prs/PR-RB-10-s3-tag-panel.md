# PR-RB-10: S3 Phase A — Tag Results Independent Panel

- Proposed title: `feat(tags): PR-RB-10 independent tag results panel with atom_ref breadcrumbs`
- Status: Ready for Implementation

## Goal

实现 S3 Phase A：选中 tag 时，在 tag 芯片栏与 Explorer 之间展开独立结果面板，显示匹配 Atom 的扁平列表，每条结果附 atom_ref 路径面包屑。Explorer 保持完整树，不受 tag 过滤影响。

前置条件：PR-RB-03（atom_ref 语义统一，所有 Atom 必有 atom_ref）+ PR-RB-05（core-workspace 提取，WorkspaceTreeService 可共享）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Ruling | `S3-tag-workspace-orthogonality.md` | 正交性原则 + Phase A 面板布局 + 面包屑格式 |
| Ruling | `S1-atom-projection.md` R5 | 所有 Atom 必有 atom_ref → 面包屑路径总是可构建 |
| Ruling | `S4-creation-path-unification.md` | atom_ref 创建保证 → 不存在无 ref 的 Atom |
| Ruling | `S8-noteitem-unification.md` | tag 查询返回 AtomListItem（统一 DTO） |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-10 | Scope + 依赖 |

## 设计方案

### 面板布局（S3 Phase A）

```
┌─────────────────────┐
│ [Tag A] [Tag B] ... │  ← tag 芯片栏（已有 TagFilter widget）
├─────────────────────┤
│ Tag "Tag A" 结果     │  ← TagResultsPanel（新增，选中 tag 时展开）
│ ├── 📝 Atom X       │     icon（view_hint 驱动）+ title
│ │   📁 FolderA/Sub  │     atom_ref 路径面包屑
│ ├── ✅ Atom Y       │
│ │   📁 根目录       │     根级别 atom_ref 显示 "根目录"
│ └── 📅 Atom Z       │
│     📁 FolderC      │
├─────────────────────┤
│ Explorer             │  ← 被下推，仍完整可见
│ ├── 📁 Tasks/       │
│ └── ...              │
└─────────────────────┘
```

- Tag 取消选择 → 面板收起，Explorer 恢复完整高度
- Tag 结果面板和 Explorer 互不影响内部状态

### 面包屑路径构建

**数据流**：
1. 用户选中 tag → 调用 `notes_list(tag=selectedTag)` 获取匹配 Atom 列表
2. 对每个 Atom，调用 `workspace_ancestor_path(atom_id)` FFI 函数获取祖先路径
3. FFI 返回有序 `List<String>`（从根到直接父级的 `display_name` 列表）
4. Flutter 侧拼接为面包屑显示：`FolderA / SubFolder`；空列表显示 "根目录"

**实现方式**：Rust 侧 SQL 递归 CTE 查询 + 新增 FFI 函数。

理由：WorkspaceTreeService（PR-RB-05）采用 per-parent lazy-load 模式，**不持有全树缓存**。Flutter 侧无法直接查找 atom_ref 节点或遍历祖先链。若在 Flutter 侧实现需 BFS 整棵树（N+1 次 FFI 调用），性能差且复杂。Rust 侧用 SQL 递归 CTE 单次查询完成，O(depth) 复杂度，符合 Rule A（路径解析属于领域操作）。

### Rust 层：`workspace_ancestor_path` 实现

**Repo 层** — `TreeRepository` trait 新增方法：

```rust
/// Returns ancestor folder display_names from root to direct parent
/// for the first active atom_ref of the given atom.
fn ancestor_path(&self, atom_uuid: AtomId) -> TreeRepoResult<Vec<String>>;
```

**SQL 递归 CTE**：

```sql
WITH RECURSIVE ancestors(node_uuid, display_name, parent_uuid, depth) AS (
  -- Base: find the atom_ref node's parent folder
  -- ORDER BY sort_order ASC ensures deterministic pick when multiple atom_refs exist
  SELECT f.node_uuid, f.display_name, f.parent_uuid, 0
  FROM workspace_nodes r
  JOIN workspace_nodes f ON f.node_uuid = r.parent_uuid
  WHERE r.atom_uuid = ?1
    AND r.kind = 'atom_ref'
    AND r.is_deleted = 0
    AND f.is_deleted = 0
  ORDER BY r.sort_order ASC, r.node_uuid ASC
  LIMIT 1
  UNION ALL
  -- Recursive: walk up parent chain
  SELECT w.node_uuid, w.display_name, w.parent_uuid, a.depth + 1
  FROM workspace_nodes w
  JOIN ancestors a ON w.node_uuid = a.parent_uuid
  WHERE w.is_deleted = 0
)
SELECT display_name FROM ancestors ORDER BY depth DESC;
```

返回值：`Vec<String>` — 从根到直接父级的有序路径段。根级别 atom_ref（`parent_uuid IS NULL`）返回空 `Vec`。

**Service 层** — `TreeService` 透传：

```rust
pub fn ancestor_path(&self, atom_uuid: AtomId) -> Result<Vec<String>, TreeServiceError> {
    self.repo.ancestor_path(atom_uuid).map_err(TreeServiceError::Repo)
}
```

**FFI 层** — 新增导出函数：

```rust
pub async fn workspace_ancestor_path(atom_id: String) -> WorkspaceAncestorPathResponse {
    // parse atom_id → AtomId, call tree_service.ancestor_path()
    // return { ok: true, path: [...] } or { ok: false, error_code, message }
}
```

**响应信封**（沿用 `ok/error_code/message` 统一风格，与 `WorkspaceActionResponse` 等一致）：

```rust
pub struct WorkspaceAncestorPathResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
    /// Ancestor folder display_names from root to direct parent (empty = root-level atom_ref).
    pub path: Vec<String>,
}
```

### Flutter 侧面包屑适配

面包屑构建从 FFI 响应直接映射，无需本地树遍历：

```dart
/// 从 FFI 响应构建面包屑显示文本
String formatBreadcrumb(List<String> ancestorPath) {
  if (ancestorPath.isEmpty) return '根目录';
  return ancestorPath.join(' / ');
}
```

`breadcrumb_builder.dart` 简化为格式化工具（~15 行），不再包含树遍历逻辑。

### 开放设计决策（本 PR 内决策）

| 问题 | 决策 | 理由 |
|------|------|------|
| 面包屑路径格式 | 全路径 | S3 Phase A 目标是提供完整结构上下文 |
| 多 atom_ref 显示策略 | 显示 `sort_order ASC, node_uuid ASC` 最小的 ref 路径 | v0.3 创建路径仅产生一个 atom_ref（S4），多 ref 是未来场景；确定性排序避免同一 Atom 面包屑抖动 |
| 结果排序 | `updated_at DESC` | 与 notes_list 现有排序一致 |
| 空结果状态 | 显示 "No matching atoms" | 与 SearchResultsView 模式一致 |

### TagResultsPanel Widget

```dart
class TagResultsPanel extends StatelessWidget {
  const TagResultsPanel({
    super.key,
    required this.tag,
    required this.items,
    required this.loading,
    required this.breadcrumbs, // Map<AtomId, List<String>>
    required this.onTapItem,
  });

  final String tag;
  final List<AtomListItem> items;
  final bool loading;
  final Map<String, List<String>> breadcrumbs;
  final ValueChanged<String> onTapItem; // atomId
}
```

**每条结果行**：
- Leading icon：由 `view_hint` 决定（note=📝, task=✅, event=📅）
- Title：`item.title`（S1 R8 保证非空）
- Subtitle：面包屑路径（📁 前缀 + `/` 分隔）
- 点击行为：`onTapItem(atomId)` → 在编辑器中打开该 Atom

### 集成点

**NoteTagManager 职责不变**（仅管理 tag 状态与写入队列）。

**NotesCoordinator 编排 tag 结果聚合**：

当 `NoteTagManager.selectedTag` 变更时，Coordinator 负责：
1. 查询匹配 Atom 列表（复用 `notes_list(tag=)` 或 PR-RB-01 后的统一 API）
2. 对每个结果调用 `workspace_ancestor_path(atomId)` FFI 获取面包屑路径
3. 暴露 `tagResults` + `tagBreadcrumbs` + `tagResultsLoading` 给 UI

理由：breadcrumb 聚合涉及 tag 查询 + workspace 路径两个域，属于跨域编排，由 Coordinator 承担。`NoteTagManager` 继续只管 tag CRUD 和选中态，避免 manager 变为跨域编排点。

**布局集成**：

在 notes feature 的侧边栏布局中，TagFilter 下方插入条件渲染的 `TagResultsPanel`：

```dart
// notes sidebar layout
Column(
  children: [
    TagFilter(...),
    if (coordinator.selectedTag != null)
      TagResultsPanel(
        tag: coordinator.selectedTag!,
        items: coordinator.tagResults,
        loading: coordinator.tagResultsLoading,
        breadcrumbs: coordinator.tagBreadcrumbs,
        onTapItem: coordinator.openNote,
      ),
    Expanded(child: NoteExplorer(...)),
  ],
)
```

## Task Breakdown

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T1 | Rust repo 层：`ancestor_path()` 递归 CTE 查询 | `crates/lazynote_core/src/repo/tree_repo.rs` | 编辑 ~+40 行 | — |
| T2 | Rust service 层：`ancestor_path()` 透传 | `crates/lazynote_core/src/service/tree_service.rs` | 编辑 ~+10 行 | T1 |
| T3 | Rust 单元测试：ancestor_path（根级/嵌套/不存在/已删除） | `crates/lazynote_core/tests/` | 新文件或编辑 ~+60 行 | T2 |
| T4 | FFI 层：`workspace_ancestor_path()` 导出 + `WorkspaceAncestorPathResponse` | `crates/lazynote_ffi/src/api.rs` | 编辑 ~+30 行 | T2 |
| T5 | FRB codegen：`scripts/gen_bindings.ps1` 重新生成 Dart 绑定 | auto-generated | — | T4 |
| T6 | Flutter 面包屑格式化工具 `breadcrumb_builder.dart` | `lib/shared/breadcrumb_builder.dart` | 新文件 ~15 行 | T5 |
| T7 | `TagResultsPanel` widget（loading/empty/error/results 四态 + 结果行 + 面包屑） | `lib/shared/tag_results_panel.dart` | 新文件 ~120 行 | T6 |
| T8 | `NotesCoordinator` tag 结果聚合：tag 变更监听 → `notes_list` 查询 + `workspace_ancestor_path` 批量调用 + 状态管理 | coordinator 文件 | 编辑 ~+70 行 | T6 |
| T9 | `NotesCoordinator` 公共 API：暴露 `tagResults` / `tagBreadcrumbs` / `tagResultsLoading` | coordinator 抽象类 + impl | 编辑 ~+10 行 | T8 |
| T10 | Notes 侧边栏布局集成：TagFilter 下方插入 TagResultsPanel | notes explorer widget | 编辑 ~+20 行 | T7, T9 |
| T11 | 点击结果行 → openNote 跳转到编辑器 | coordinator / shell | 编辑 ~+5 行 | T10 |
| T12 | Flutter 单元测试：breadcrumb_builder 格式化 | `test/breadcrumb_builder_test.dart` | 新文件 ~30 行 | T6 |
| T13 | Widget 测试：TagResultsPanel 四态渲染 + 点击 | `test/tag_results_panel_test.dart` | 新文件 ~80 行 | T7 |
| T14 | 集成测试：tag 选择 → 面板展开 → 面包屑显示 → 取消 → 面板收起 | `test/tag_panel_integration_test.dart` | 新文件 ~60 行 | T10 |
| T15 | 文档更新 + S3 Phase A 标注 implemented | docs | 编辑 | T11 |

## Planned File Changes

### Rust 层

- `[edit]` `crates/lazynote_core/src/repo/tree_repo.rs` (~+40 行：`ancestor_path()` trait 方法 + SQLite 实现)
- `[edit]` `crates/lazynote_core/src/service/tree_service.rs` (~+10 行：透传)
- `[add/edit]` `crates/lazynote_core/tests/tree_ancestor_path_test.rs` (~60 行：根级/嵌套/不存在/已删除)
- `[edit]` `crates/lazynote_ffi/src/api.rs` (~+30 行：`workspace_ancestor_path()` + `WorkspaceAncestorPathResponse`)

### Flutter 层

- `[add]` `apps/lazynote_flutter/lib/shared/breadcrumb_builder.dart` (~15 行：格式化工具)
- `[add]` `apps/lazynote_flutter/lib/shared/tag_results_panel.dart` (~120 行)
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` (~+70 行：tag 结果聚合)
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator.dart` (~+10 行：公共 API)
- `[edit]` notes explorer sidebar widget (~+20 行)
- `[add]` `apps/lazynote_flutter/test/breadcrumb_builder_test.dart` (~30 行)
- `[add]` `apps/lazynote_flutter/test/tag_results_panel_test.dart` (~80 行)
- `[add]` `apps/lazynote_flutter/test/tag_panel_integration_test.dart` (~60 行)

### 自动生成（不手动编辑）

- `[regen]` `crates/lazynote_ffi/src/frb_generated.rs`
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/*.dart`

## Verification

```bash
# Rust CI gates
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
```

```bash
# Flutter CI gates
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

```bash
# 结构验证
# 新文件存在
test -f apps/lazynote_flutter/lib/shared/breadcrumb_builder.dart
test -f apps/lazynote_flutter/lib/shared/tag_results_panel.dart

# breadcrumb_builder 不引用 features/ 内部（shared 模块规则）
! rg "features/" apps/lazynote_flutter/lib/shared/breadcrumb_builder.dart

# TagResultsPanel 不引用 features/ 内部
! rg "features/" apps/lazynote_flutter/lib/shared/tag_results_panel.dart

# FFI 新函数存在
rg "workspace_ancestor_path" crates/lazynote_ffi/src/api.rs
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Atom 无 atom_ref 时 ancestor_path 返回空 | LOW | S4 ruling 保证所有 Atom 创建时必有 atom_ref；FFI 返回空 `Vec` 作为安全默认值，Flutter 显示 "根目录" |
| Tag 查询返回大量结果时批量 ancestor_path 调用慢 | MEDIUM | 每个 atom_id 独立 FFI 调用（SQLite 递归 CTE 单次 O(depth)）；结果数受 notes_list 分页机制限制（limit=50）；可并行调用 |
| Tag 查询返回大量结果影响面板性能 | LOW | 复用 notes_list 分页机制（limit=50）；面板使用 ListView.builder 懒加载 |
| 面包屑路径过长溢出 | LOW | 使用 `TextOverflow.ellipsis` + 最大 1 行 |

## Acceptance Criteria

- [ ] Rust：`TreeRepository::ancestor_path()` 递归 CTE 正确返回祖先路径（根级返回空 Vec，嵌套返回有序路径段）
- [ ] Rust：`workspace_ancestor_path` FFI 函数可通过 Dart 绑定调用
- [ ] Rust：ancestor_path 单元测试覆盖根级/嵌套/不存在/已删除场景
- [ ] 选中 tag 时，TagResultsPanel 在 tag 芯片栏下方展开
- [ ] 结果列表每条显示 icon + title + atom_ref 面包屑路径
- [ ] 根级别 atom_ref 的 Atom 面包屑显示 "根目录"
- [ ] 取消 tag 选择时面板收起，Explorer 恢复完整高度
- [ ] Explorer 树在 tag 过滤期间保持完整不变
- [ ] 点击结果行在编辑器中打开对应 Atom
- [ ] breadcrumb_builder 和 TagResultsPanel 位于 `lib/shared/`（不引用 features/ 内部）
- [ ] §Verification CI gates 全部通过（Rust + Flutter 逐项执行并记录输出）
