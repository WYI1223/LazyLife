# PR-RB-01: S8 DTO 统一

- Proposed title: `refactor(ffi): PR-RB-01 unify notes API to AtomListItem, deprecate NoteItem`
- Status: Merged

## Goal

将 Rust FFI notes API 的返回类型从 `NoteItem` / `NoteResponse` / `NotesListResponse` 统一到 `AtomListItem` / `AtomItemResponse` / `AtomListResponse`，消除 notes 专属 DTO 与通用 Atom DTO 的信息断裂。Flutter 侧移除全部手写 `NoteItem` 业务依赖。

前置条件：PR-RB-00（文档修复完成）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Ruling | `docs/architecture/rulings-legacy/S8-noteitem-unification.md` | 定义四条规则：Single DTO / Information completeness / UI-layer decision authority / EntrySearchItem preserved |
| Rebaseline | `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-01 | 定义 scope 和依赖 |
| Acceptance Report | `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md` §4.1-4.2 | S8 disposition：timeline corrected to v0.3 |
| DI-7 | `docs/reports/v0.3/design-discussions/DI-7-gates-perf-testing.md` | Gate A 验证项：手写代码 NoteItem 归零 |
| FFI Contracts | `docs/api/ffi-contracts.md` L378-382 | 已标注 migration note |
| API Compatibility | `docs/governance/API_COMPATIBILITY.md` L80-84 | 已标注 breaking change plan |

## 差距分析

### 类型对比

| 字段 | `NoteItem` (6 字段) | `AtomListItem` (10 字段) | 差异 |
|------|---------------------|--------------------------|------|
| `atom_id` | ✓ | ✓ | — |
| `content` | ✓ | ✓ | — |
| `preview_text` | ✓ | ✓ | — |
| `preview_image` | ✓ | ✓ | — |
| `updated_at` | ✓ | ✓ | — |
| `tags` | ✓ | ✓ | — |
| `kind` | **缺失** | ✓ | NoteItem 丢弃 |
| `start_at` | **缺失** | ✓ | NoteItem 丢弃 |
| `end_at` | **缺失** | ✓ | NoteItem 丢弃 |
| `task_status` | **缺失** | ✓ | NoteItem 丢弃 |

### 信息断裂根因

```
NoteService → NoteRecord (6 字段) → to_note_item() → NoteItem (6 字段)
                                     ↑ 丢弃 kind/start_at/end_at/task_status

TaskService → SectionAtom (全字段) → to_atom_list_item() → AtomListItem (10 字段)
                                     ↑ 保留全部
```

### 受影响 FFI 函数

| FFI 函数 | 当前返回类型 | 目标返回类型 |
|----------|------------|------------|
| `note_create` | `NoteResponse` (含 `NoteItem`) | `AtomItemResponse` (含 `AtomListItem`) |
| `note_update` | `NoteResponse` | `AtomItemResponse` |
| `note_get` | `NoteResponse` | `AtomItemResponse` |
| `note_set_tags` | `NoteResponse` | `AtomItemResponse` |
| `notes_list` | `NotesListResponse` (含 `Vec<NoteItem>`) | `AtomListResponse` (含 `Vec<AtomListItem>`) |

### 受影响 Flutter 文件

| 类别 | 文件数 | 说明 |
|------|--------|------|
| 手写生产代码 | 7 | `NoteItem` 类型引用（coordinator, managers, types） |
| 手写生产代码 | 5 | `NoteResponse`/`NotesListResponse` invoker typedefs |
| 自动生成绑定 | 3 | `lib/core/bindings/`（codegen 自动覆盖，无需手动改） |
| 测试文件 | 17 | `NoteItem(...)` / `NoteResponse(...)` mock 构造 |

## Scope

In scope:

- S8 四条规则的完整实现
- Core 层 `NoteRecord` 扩展（添加 4 个缺失字段）
- FFI 层类型替换 + 新增 `AtomItemResponse` 信封
- Flutter 侧全部手写 `NoteItem`/`NoteResponse`/`NotesListResponse` 引用替换
- 全部测试文件 mock 数据更新
- `architecture_check.dart` 添加 NoteItem 归零检查
- 相关文档更新

Out of scope:

- `EntrySearchItem` 保持不变（S8 规则 4：搜索结果是不同投影）
- Core 内部 `NoteRecord` 重命名（Core 内部类型不在 S8 范围内）
- `NoteRepository` trait 签名变更（仅扩展返回类型的字段）

## 设计方案

### Rust Core 层

扩展 `NoteRecord`（`src/repo/note_repo.rs:27`）添加 4 字段：

```rust
pub struct NoteRecord {
    pub atom_id: String,
    pub content: String,
    pub preview_text: Option<String>,
    pub preview_image: Option<String>,
    pub updated_at: i64,
    pub tags: Vec<String>,
    // S8: 新增字段
    pub kind: String,
    pub start_at: Option<i64>,
    pub end_at: Option<i64>,
    pub task_status: Option<String>,
}
```

SQL 查询已 SELECT 自 `atoms` 表，添加 `kind`、`start_at`、`end_at`、`task_status` 列即可。

### Rust FFI 层

1. 新增 `AtomItemResponse` 信封（替代 `NoteResponse`）：

```rust
pub struct AtomItemResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub item: Option<AtomListItem>,
}
```

2. 替换 `to_note_item()` → `to_atom_list_item_from_note()`：利用扩展后的 `NoteRecord` 字段直接构造 `AtomListItem`。

3. 删除 `NoteItem`、`NoteResponse`、`NotesListResponse` 三个 struct。

### Flutter 层

绑定 codegen 后自动产生新类型。手写代码中：

- `rust_api.NoteItem` → `rust_api.AtomListItem`
- `rust_api.NoteResponse` → `rust_api.AtomItemResponse`
- `rust_api.NotesListResponse` → `rust_api.AtomListResponse`
- `_withContent()` helper 需额外传入 `kind`/`start_at`/`end_at`/`task_status`（从原对象复制）

## Task Breakdown

### Phase 1: Rust Core（`NoteRecord` 扩展）

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T1 | `NoteRecord` 添加 `kind`/`start_at`/`end_at`/`task_status` 字段 | `crates/lazynote_core/src/repo/note_repo.rs:27` | 编辑 struct 定义 + SQL SELECT 子句 | — |
| T2 | 更新 `NoteRecord` 构造处（`from_row` 或类似 row mapping） | `crates/lazynote_core/src/repo/note_repo.rs` | 编辑 row mapping | T1 |
| T3 | 更新 `NoteService` 中使用 `NoteRecord` 构造的位置（如 `create_note` 返回值） | `crates/lazynote_core/src/service/note_service.rs` | 编辑返回值构造 | T1 |

### Phase 2: Rust FFI（类型替换）

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T4 | 新增 `AtomItemResponse` struct | `crates/lazynote_ffi/src/api.rs` | 新增 ~8 行 | — |
| T5 | 新增 `to_atom_list_item_from_note()` 转换函数 | `crates/lazynote_ffi/src/api.rs` | 新增 ~15 行 | T1 |
| T6 | `note_create`/`note_update`/`note_get`/`note_set_tags` 返回类型 → `AtomItemResponse` | `crates/lazynote_ffi/src/api.rs:709,737,764,837` | 编辑 4 个函数签名 + 返回值构造 | T4, T5 |
| T7 | `notes_list` 返回类型 → `AtomListResponse` | `crates/lazynote_ffi/src/api.rs:797` | 编辑函数签名 + 返回值构造 | T5 |
| T8 | 删除 `NoteItem`、`NoteResponse`、`NotesListResponse` struct 和 `to_note_item()` | `crates/lazynote_ffi/src/api.rs:317,334,347,1207` | 删除 ~40 行 | T6, T7 |

### Phase 3: Codegen

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T9 | 运行 `scripts/gen_bindings.ps1` 重新生成 Dart 绑定 | `lib/core/bindings/*.dart` | 自动生成 | T8 |

### Phase 4: Flutter 生产代码

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T10 | 更新 coordinator typedefs | `lib/features/notes/notes_coordinator_types.dart` | `NoteResponse` → `AtomItemResponse`，`NotesListResponse` → `AtomListResponse` | T9 |
| T11 | 更新 coordinator impl：default invokers + `_selectedNote` + `items` getter + `_withContent()` | `lib/features/notes/notes_coordinator_impl.dart` | `NoteItem` → `AtomListItem`，`NoteResponse` → `AtomItemResponse` | T9 |
| T12 | 更新 `note_list_manager.dart`：`_items` / `_noteCache` / typedefs | `lib/features/notes/managers/note_list_manager.dart` | `NoteItem` → `AtomListItem`，`NotesListResponse` → `AtomListResponse` | T9 |
| T13 | 更新 `note_draft_manager.dart`：typedefs + 调用签名 | `lib/features/notes/managers/note_draft_manager.dart` | `NoteItem` → `AtomListItem`，`NoteResponse` → `AtomItemResponse` | T9 |
| T14 | 更新 `note_tag_manager.dart` + `note_tag_manager_types.dart` | `lib/features/notes/managers/note_tag_manager*.dart` | `NoteItem` → `AtomListItem`，`NoteResponse` → `AtomItemResponse` | T9 |
| T15 | 更新 `workspace_tree_types.dart` + `workspace_tree_children_loader.dart` | `lib/features/notes/managers/workspace_tree_*.dart` | `NoteItem` → `AtomListItem` | T9 |

### Phase 5: Flutter 测试

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T16 | 更新全部 17 个测试文件中的 `NoteItem(...)` / `NoteResponse(...)` / `NotesListResponse(...)` mock 构造 | `test/*.dart`（17 files） | 每个构造添加 `kind`/`start_at`/`end_at`/`task_status` 参数 | T9 |

### Phase 6: CI 守卫 + 文档

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T17 | `architecture_check.dart` 添加 NoteItem 归零检查（扫描 `lib/` 排除 `bindings/`） | `tools/ci/architecture_check.dart` | 新增 ~15 行 check | T8 |
| T18 | 更新 `ffi-contracts.md`：移除 migration note，更新 notes API 返回类型 | `docs/api/ffi-contracts.md` | 编辑 | T8 |
| T19 | 更新 `API_COMPATIBILITY.md`：标注 migration completed | `docs/governance/API_COMPATIBILITY.md` | 编辑 | T8 |
| T20 | 更新 `CLAUDE.md` FFI API Surface：`NoteResponse`/`NotesListResponse` → `AtomItemResponse`/`AtomListResponse` | `CLAUDE.md` | 编辑 | T8 |
| T21 | 更新 `S8-noteitem-unification.md` 状态为 implemented | `docs/architecture/rulings-legacy/S8-noteitem-unification.md` | 编辑状态字段 | T8 |

### Critical Path

```
T1 → T2 → T3 → T5 → T6/T7 → T8 → T9 → T10~T16 (并行) → T17~T21 (并行)
T4 无依赖，可与 T1~T3 并行
```

## Planned File Changes

### Rust
- `[edit]` `crates/lazynote_core/src/repo/note_repo.rs`（NoteRecord 扩展 + SQL 更新）
- `[edit]` `crates/lazynote_core/src/service/note_service.rs`（返回值构造更新）
- `[edit]` `crates/lazynote_ffi/src/api.rs`（新增 AtomItemResponse，删除 NoteItem/NoteResponse/NotesListResponse，更新 5 个函数）

### Flutter（自动生成）
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/api.dart`
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/frb_generated.dart`
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/frb_generated.io.dart`

### Flutter（手写）
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_types.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/note_list_manager.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/note_draft_manager.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/note_tag_manager.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/note_tag_manager_types.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_types.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_children_loader.dart`

### Flutter（测试，17 files）
- `[edit]` `apps/lazynote_flutter/test/note_ffi_models_test.dart`
- `[edit]` `apps/lazynote_flutter/test/notes_controller_tabs_test.dart`
- `[edit]` `apps/lazynote_flutter/test/notes_page_c1_test.dart`
- `[edit]` 其余 14 个 test files（含 `NoteItem`/`NoteResponse` mock 构造的全部测试）

### CI / Docs
- `[edit]` `tools/ci/architecture_check.dart`
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `docs/governance/API_COMPATIBILITY.md`
- `[edit]` `CLAUDE.md`
- `[edit]` `docs/architecture/rulings-legacy/S8-noteitem-unification.md`

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
# NoteItem 在手写代码中归零
rg "NoteItem" apps/lazynote_flutter/lib/ --glob '!core/bindings/*'
# Expected: zero matches

# NoteResponse 在手写代码中归零
rg "NoteResponse" apps/lazynote_flutter/lib/ --glob '!core/bindings/*'
# Expected: zero matches

# NotesListResponse 在手写代码中归零
rg "NotesListResponse" apps/lazynote_flutter/lib/ --glob '!core/bindings/*'
# Expected: zero matches

# NoteItem 在 FFI crate 中归零
rg "NoteItem" crates/lazynote_ffi/src/api.rs
# Expected: zero matches

# AtomItemResponse 存在
rg "pub struct AtomItemResponse" crates/lazynote_ffi/src/api.rs
# Expected: 1 match
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| NoteRecord 扩展遗漏 SQL 列 | MEDIUM | T2 后运行 `cargo test -p lazynote_core` 验证所有 note repo 测试通过 |
| Flutter 侧 NoteItem 替换遗漏 | MEDIUM | T16 后运行 `rg NoteItem lib/`（排除 bindings），必须 zero matches |
| AtomListItem 构造需额外参数导致测试冗长 | LOW | 封装 test helper：`makeTestAtomListItem({required String atomId, ...})` 提供默认值 |
| codegen 产物与手写代码不兼容 | LOW | T9 后立即 `flutter analyze`，编译错误在 T10~T15 中逐一修复 |

## Test Baseline

Entry: PR-RB-00 exit count（预期 333 pass / 0 fail）
Exit: **≥ 333 pass / 0 fail**（测试数量不减少，mock 构造更新不删除用例）

## Manual Walkthrough

| # | 走查项 | 结果 | 备注 |
|---|--------|------|------|
| 1 | 启动应用，进入 Notes 视图 | PASS | 笔记列表正常加载 |
| 2 | 创建一条新笔记 | ISSUE | 底部"新建页面"与右键"New note"创建逻辑不一致。已提 [#44](https://github.com/WYI1223/LazyLife/issues/44)，**非本 PR 回归**，属 pre-existing |
| 3 | 编辑笔记内容，等待自动保存 | PASS | 保存状态指示器正常 |
| 4 | 给笔记添加/移除标签 | PASS | 标签操作成功 |
| 5 | 通过标签过滤切换 | DEFERRED | tag 功能整体正常，过滤视图待后续 PR 完成新过滤视图后再验证 |
| 6 | Workspace Tree 浏览 | PASS | 文件夹展开/折叠正常，note_ref 显示正确 |
| 7 | Uncategorized 文件夹 | PASS | 未分类笔记正确聚合 |
| 8 | 多标签页操作 | PASS | 多 tab 切换内容不串、保存状态独立 |
| 9 | 搜索笔记 | PASS (minor) | 整体正常，偶现未响应但不能稳定复现，**非本 PR 回归** |
| 10 | Tasks 视图中创建的条目在 Notes 视图显示 | PASS (manual) | 能正常显示，但需手动刷新一次。属 pre-existing 跨视图刷新行为 |

**结论**：无本 PR 引入的回归。#2 和 #10 为 pre-existing 问题（#2 已提 issue），#5 待后续 PR 补充验证，#9 偶发且不可复现。

## Acceptance Criteria

- [x] Rust FFI 中 `NoteItem`/`NoteResponse`/`NotesListResponse` 三个 struct 已删除
- [x] `AtomItemResponse` 新增并被 `note_create`/`note_update`/`note_get`/`note_set_tags` 使用
- [x] `notes_list` 返回 `AtomListResponse`
- [x] `NoteRecord` 包含 `kind`/`start_at`/`end_at`/`task_status` 字段
- [x] Flutter 手写代码中 `NoteItem` 引用归零（`lib/core/bindings/` 除外）
- [x] `architecture_check.dart` 包含 NoteItem 归零检查
- [x] 全部 Rust tests 通过（191 pass）
- [x] 全部 Flutter tests 通过（333 pass）
- [x] `ffi-contracts.md` 和 `API_COMPATIBILITY.md` 已更新
- [x] CI green（format + analyze + test + architecture check）
