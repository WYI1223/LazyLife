# PR-RB-02: S1 核心字段落地

- Proposed title: `feat(core): PR-RB-02 add title/content_type/view_hint fields with auto-derivation`
- Status: Merged

## Goal

在 `atoms` 表新增 `title`、`content_type` 列并将 `type` 重命名为 `view_hint`（Migration 0010）。在 Core service 层实现 `title` 自动推导和 `view_hint` 自动推导。FFI 层 `AtomListItem` 新增字段并 `kind` → `view_hint` 重命名。Dart 贯通。

前置条件：PR-RB-01（S8 DTO 统一完成，`AtomListItem` 已成为唯一 notes DTO）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Ruling | `docs/architecture/rulings/S1-atom-projection.md` R2/R3/R8 | 定义 `content_type`/`view_hint`/`title` 语义和推导规则 |
| Ruling | 同上 R4 | 定义渲染行为矩阵（Flutter 层参考，无 Core 代码变更） |
| Rebaseline | `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-02 | 定义 scope：migration 0010 + Core 推导 + FFI/Dart 贯通 |
| Data Model | `docs/architecture/data-model.md` | 当前 schema 参考 + 需更新 |
| DI-9 | DEFERRED v0.4 | `entry_search kind` 参数保持不变，不在本 PR 范围 |

## S1 R2/R3/R8 要求摘要

### R8: title 字段

- 类型：`TEXT NOT NULL DEFAULT ''`
- 推导规则（按 `content_type`）：
  - `markdown`：取内容首个非空行，去除 `#` 前缀，trim，截断 50 字符。**创建和更新时自动重新推导**。
  - `canvas`/`conversation`（v0.4+）：用户命名，不自动更新。
- 所有视图（tab bar、explorer、task list、calendar）读同一个 `title` 字段，取代目前从 `preview_text` 或 `content.split('\n').first` 推导的做法。

### R2: content_type 字段

- 类型：`TEXT DEFAULT 'markdown'`
- 值域：`markdown`（v0.3 唯一值）、`canvas`/`conversation`/`plugin:<id>`（v0.4+）
- Core 将 `content` 视为 opaque string，不依据 `content_type` 解释内容。
- `content_type` 决定编辑器选择（v0.3 只有 markdown editor）。

### R3: view_hint 自动推导

- 替代原 `type`/`kind` 字段的语义。
- 自动推导规则：
  - 有 `task_status` → `task`
  - 无 `task_status` + 有 `start_at` 或 `end_at` → `event`
  - 无 `task_status` + 无时间字段 → `note`（默认值 / N/A）
- `view_hint` 仅用于渲染形态决定（checkbox / text / time bar），**不用于查询过滤**。
- API 保留显式设置端口（供 LLM / Single Entry commands 使用）。

## 差距分析

### DB Schema

| 要求 | 当前状态 | 差距 |
|------|---------|------|
| `title TEXT NOT NULL DEFAULT ''` | 不存在 | Migration 0010 新增 |
| `content_type TEXT DEFAULT 'markdown'` | 不存在 | Migration 0010 新增 |
| `type` → `view_hint` | 列名为 `type`，CHECK 约束 `('note','task','event')` | Migration 0010 RENAME COLUMN |
| FTS5 索引 `title` | `atoms_fts` 仅索引 `content` | Migration 0010 重建 FTS + 触发器 |
| 现有数据 `title` 回填 | N/A | Migration 0010 SQL 回填 |

### Rust Core

| 要求 | 当前状态 | 差距 |
|------|---------|------|
| `Atom.title: String` | 不存在 | 添加字段 |
| `Atom.content_type: String` | 不存在 | 添加字段，默认 `"markdown"` |
| `Atom.kind` → `Atom.view_hint` | `kind: AtomType` enum | 字段重命名 + 枚举 `AtomType` → `ViewHint`（D1） |
| `derive_title()` 函数 | 不存在 | 新增 |
| `derive_view_hint()` 函数 | 隐式存在于各 `create_*` 方法 | 显式提取 |
| `title` 自动推导（create/update） | 不存在 | `AtomService`/`NoteService` 创建和更新路径 |
| FTS `SearchHit.title` | 不存在 | `fts.rs` 更新查询和 struct |

### FFI 层

| 要求 | 当前状态 | 差距 |
|------|---------|------|
| `AtomListItem.title` | 不存在 | 添加字段 |
| `AtomListItem.content_type` | 不存在 | 添加字段 |
| `AtomListItem.kind` → `.view_hint` | `kind: String` | 重命名 |
| `EntrySearchItem.title` | 不存在 | 添加字段 |
| `EntrySearchItem.kind` → `.view_hint` | `kind: String` | 重命名 |
| `entry_search` 函数 `kind` 参数 | 按 `type` 列过滤 | 内部改为按 `view_hint` 列过滤，参数名保持 `kind`（DI-9 v0.4 重设计） |

## Design Decisions

以下决策在实施前确认，来源为 S1 ruling 文档和人工裁定：

| # | 决策 | 结论 | 来源 |
|---|------|------|------|
| D1 | `AtomType` 枚举重命名 | `AtomType` → `ViewHint`，与字段名 `view_hint`、DB 列名 `view_hint` 保持一致。影响面见 [DI-11](../../../reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md) | 人工裁定 |
| D2 | `preview_text` 与 `title` 关系 | 并存。`title` = "叫什么"（标题），`preview_text` = "长什么样"（摘要）。本 PR 不变更 `preview_text` | S1 R8 |
| D3 | CHECK 约束处理 | 信任 SQLite 3.25+ `RENAME COLUMN` 自动更新 CHECK 约束。补 Rust 测试断言非法 `view_hint` 被拒绝 | 人工裁定 |
| D4 | `SearchHit.kind` 重命名 | 同步重命名为 `SearchHit.view_hint`，全局一致 | S1 R3 |

## Scope

In scope:

- Migration 0010：`title`/`content_type` 新增 + `type` → `view_hint` 重命名 + FTS 重建 + 数据回填
- Rust Core `Atom` model 字段变更
- `derive_title()`/`derive_view_hint()` 函数实现
- `AtomRepository` SQL 更新
- `AtomService`/`NoteService` 创建/更新路径集成推导
- `fts.rs` 更新（`SearchHit` 含 `title`，FTS 查询含 `title`）
- FFI 层 `AtomListItem`/`EntrySearchItem` 字段更新 + codegen
- Flutter 层消费新字段（`title` 替代 `content.split('\n').first`）
- 文档更新

Out of scope:

- `entry_search` 参数从 `kind` 改为字段过滤（DI-9 v0.4）
- `content_type` 非 `markdown` 的创建路径（v0.4+）
- R5/R6/R7 `atom_ref` 相关（PR-RB-03）
- R4 渲染行为矩阵的 Flutter 实现（Flutter 层可读取 `view_hint`，但视图切换不在本 PR）

## Migration 0010 设计

```sql
-- 1. 新增列
ALTER TABLE atoms ADD COLUMN title TEXT NOT NULL DEFAULT '';
ALTER TABLE atoms ADD COLUMN content_type TEXT DEFAULT 'markdown';

-- 2. 重命名 type → view_hint（SQLite 3.25+）
ALTER TABLE atoms RENAME COLUMN type TO view_hint;

-- 3. 回填 title（从 content 首个非空行推导，截断 50 字符）
UPDATE atoms SET title = SUBSTR(
  TRIM(REPLACE(
    SUBSTR(content, 1, INSTR(content || X'0A', X'0A') - 1),
    '#', ''
  )),
  1, 50
) WHERE content != '' AND title = '';

-- 4. 删除旧 FTS 表和触发器
DROP TRIGGER IF EXISTS atoms_ai_fts;
DROP TRIGGER IF EXISTS atoms_ad_fts;
DROP TRIGGER IF EXISTS atoms_au_fts;
DROP TABLE IF EXISTS atoms_fts;

-- 5. 重建 FTS5（新增 title 索引列）
CREATE VIRTUAL TABLE atoms_fts USING fts5(
  content,
  title,
  uuid UNINDEXED,
  view_hint UNINDEXED,
  content=atoms,
  content_rowid=rowid
);

-- 6. 回填 FTS 数据
INSERT INTO atoms_fts(rowid, content, title, uuid, view_hint)
  SELECT rowid, content, title, uuid, view_hint FROM atoms WHERE is_deleted = 0;

-- 7. 重建触发器（引用 view_hint）
CREATE TRIGGER atoms_ai_fts AFTER INSERT ON atoms
WHEN NEW.is_deleted = 0
BEGIN
  INSERT INTO atoms_fts(rowid, content, title, uuid, view_hint)
    VALUES (NEW.rowid, NEW.content, NEW.title, NEW.uuid, NEW.view_hint);
END;

CREATE TRIGGER atoms_ad_fts AFTER DELETE ON atoms
BEGIN
  INSERT INTO atoms_fts(atoms_fts, rowid, content, title, uuid, view_hint)
    VALUES ('delete', OLD.rowid, OLD.content, OLD.title, OLD.uuid, OLD.view_hint);
END;

CREATE TRIGGER atoms_au_fts AFTER UPDATE ON atoms
BEGIN
  INSERT INTO atoms_fts(atoms_fts, rowid, content, title, uuid, view_hint)
    VALUES ('delete', OLD.rowid, OLD.content, OLD.title, OLD.uuid, OLD.view_hint);
  INSERT INTO atoms_fts(rowid, content, title, uuid, view_hint)
    SELECT NEW.rowid, NEW.content, NEW.title, NEW.uuid, NEW.view_hint
    WHERE NEW.is_deleted = 0;
END;
```

## Core 推导逻辑

### derive_title

```rust
/// Derive title from content based on content_type.
/// For markdown: first non-empty line, strip leading '#', trim, max 50 chars.
fn derive_title(content: &str, content_type: &str) -> String {
    match content_type {
        "markdown" => content
            .lines()
            .find(|line| !line.trim().is_empty())
            .map(|line| {
                let stripped = line.trim_start_matches('#').trim();
                stripped.chars().take(50).collect::<String>()
            })
            .unwrap_or_default(),
        _ => String::new(), // Non-markdown: not auto-derived
    }
}
```

### derive_view_hint

```rust
/// Auto-derive view_hint from atom fields.
fn derive_view_hint(
    task_status: Option<&TaskStatus>,
    start_at: Option<i64>,
    end_at: Option<i64>,
) -> AtomType {
    if task_status.is_some() {
        AtomType::Task
    } else if start_at.is_some() || end_at.is_some() {
        AtomType::Event
    } else {
        AtomType::Note
    }
}
```

## Task Breakdown

### Phase 1: Migration

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T1 | 创建 migration 0010 SQL | `crates/lazynote_core/src/db/migrations/0010_s1_core_fields.sql` | 新文件 ~50 行 | — |
| T2 | 注册 migration 0010 | `crates/lazynote_core/src/db/migrations/mod.rs` | MIGRATIONS 数组追加 | T1 |

### Phase 2: Rust Core Model + Repo

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T3 | `Atom` struct：添加 `title`/`content_type`，`kind` → `view_hint` | `crates/lazynote_core/src/model/atom.rs` | 编辑 struct + `AtomDe` + 构造函数 + validate | T1 |
| T4 | `AtomRepository` SQL 更新：SELECT/INSERT/UPDATE 引用 `title`/`content_type`/`view_hint` | `crates/lazynote_core/src/repo/atom_repo.rs` | 编辑 SQL 常量 + `parse_atom_row()` + `ensure_connection_ready()` | T3 |
| T5 | `NoteRepository` SQL 更新：SELECT 添加 `title`/`content_type`/`view_hint`（若 PR-RB-01 已扩展 NoteRecord） | `crates/lazynote_core/src/repo/note_repo.rs` | 编辑 SQL + row mapping | T3 |

### Phase 3: Core Service 推导

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T6 | 实现 `derive_title()` 和 `derive_view_hint()` | `crates/lazynote_core/src/service/atom_service.rs` | 新增 ~30 行函数 | — |
| T7 | `AtomService` 创建路径集成：`create_note`/`create_task`/`schedule_event` 调用推导 | `crates/lazynote_core/src/service/atom_service.rs` | 编辑创建方法 | T6 |
| T8 | `NoteService` 创建/更新路径集成：`create_note`/`update_note` 调用 `derive_title` | `crates/lazynote_core/src/service/note_service.rs` | 编辑 | T6 |
| T9 | `fts.rs` 更新：`SearchHit` 添加 `title`，`search_all()` 查询返回 `title` | `crates/lazynote_core/src/search/fts.rs` | 编辑 struct + SQL | T4 |

### Phase 4: FFI 层

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T10 | `AtomListItem`：添加 `title`/`content_type`，`kind` → `view_hint` | `crates/lazynote_ffi/src/api.rs` | 编辑 struct | T3 |
| T11 | `EntrySearchItem`：添加 `title`，`kind` → `view_hint` | `crates/lazynote_ffi/src/api.rs` | 编辑 struct | T9 |
| T12 | 转换函数更新：`to_atom_list_item()`/`to_entry_search_item()` 传递新字段 | `crates/lazynote_ffi/src/api.rs` | 编辑 | T10, T11 |
| T13 | `entry_search` 内部过滤：`type` → `view_hint` 列名（参数名 `kind` 不变） | `crates/lazynote_ffi/src/api.rs` | 编辑 SQL WHERE 子句 | T10 |

### Phase 5: Codegen + Flutter

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T14 | 运行 `scripts/gen_bindings.ps1` | `lib/core/bindings/*.dart` | 自动生成 | T13 |
| T15 | Flutter 侧 `kind` → `viewHint` 引用更新 | `lib/features/` 各文件 | 编辑（搜索 `.kind` 引用） | T14 |
| T16 | Flutter 侧使用 `title` 字段替代 `content.split('\n').first` | `lib/features/` + `lib/core/reminders/` | 编辑 | T14 |

### Phase 6: Rust Tests + Flutter Tests

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T17 | Rust Core 单元/集成测试更新：Atom 构造添加新字段，FTS 测试 title 索引 | `crates/lazynote_core/tests/` | 编辑 | T9 |
| T18 | Flutter 测试 mock 数据更新：`AtomListItem` 构造添加 `title`/`contentType`/`viewHint` | `test/*.dart` | 编辑 | T14 |

### Phase 7: 文档

| Task | 内容 | 文件 | 变更 | 依赖 |
|------|------|------|------|------|
| T19 | 更新 `data-model.md`：schema + 字段说明 + migration 0010 | `docs/architecture/data-model.md` | 编辑 | T1 |
| T20 | 更新 `ffi-contracts.md`：`AtomListItem`/`EntrySearchItem` 字段 | `docs/api/ffi-contracts.md` | 编辑 | T10 |
| T21 | 更新 `CLAUDE.md`：Atom struct 说明 + FFI API Surface | `CLAUDE.md` | 编辑 | T10 |
| T22 | 更新 `S1-atom-projection.md`：R2/R3/R8 标注为 implemented | `docs/architecture/rulings/S1-atom-projection.md` | 编辑 | T13 |

### Critical Path

```
T1 → T2 → T3 → T4/T5 → T7/T8/T9 → T10/T11 → T12/T13 → T14 → T15/T16 → T17/T18
T6 无依赖，可与 T1~T5 并行
```

## Planned File Changes

### Rust Core
- `[add]` `crates/lazynote_core/src/db/migrations/0010_s1_core_fields.sql`
- `[edit]` `crates/lazynote_core/src/db/migrations/mod.rs`
- `[edit]` `crates/lazynote_core/src/model/atom.rs`
- `[edit]` `crates/lazynote_core/src/repo/atom_repo.rs`
- `[edit]` `crates/lazynote_core/src/repo/note_repo.rs`
- `[edit]` `crates/lazynote_core/src/service/atom_service.rs`
- `[edit]` `crates/lazynote_core/src/service/note_service.rs`
- `[edit]` `crates/lazynote_core/src/search/fts.rs`

### Rust FFI
- `[edit]` `crates/lazynote_ffi/src/api.rs`

### Flutter（自动生成）
- `[regen]` `apps/lazynote_flutter/lib/core/bindings/*.dart`

### Flutter（手写）
- `[edit]` 涉及 `.kind` 引用和 `content.split('\n').first` 模式的文件（具体清单在执行时通过 `rg` 确定）

### 文档
- `[edit]` `docs/architecture/data-model.md`
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `CLAUDE.md`
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
# DB 列名已变更（Rust 测试中验证 migration）
cargo test -p lazynote_core -- migration

# FFI 层无 NoteItem 残留（PR-RB-01 已清理）
rg "NoteItem" crates/lazynote_ffi/src/api.rs
# Expected: zero matches

# AtomListItem 包含新字段
rg "view_hint" crates/lazynote_ffi/src/api.rs
# Expected: ≥ 1 match (struct field)

rg "title.*String" crates/lazynote_ffi/src/api.rs
# Expected: ≥ 1 match (struct field)

rg "content_type" crates/lazynote_ffi/src/api.rs
# Expected: ≥ 1 match (struct field)

# Flutter 侧不再有 .kind 引用（应为 .viewHint）
rg "\.kind" apps/lazynote_flutter/lib/ --glob '!core/bindings/*' --type dart
# Expected: zero matches (或仅在 entry_search 参数构造处)
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Migration 0010 SQL 回填 title 不精确 | MEDIUM | SQL SUBSTR/TRIM 只做粗粒度提取；Core service 层在下次 update 时会用精确 Rust 逻辑覆写 |
| `type` → `view_hint` 重命名破坏 FTS 触发器 | HIGH | Migration 先 DROP 旧触发器再 CREATE 新触发器；`cargo test` 验证 FTS 功能 |
| SQLite < 3.25 不支持 RENAME COLUMN | LOW | Windows SQLite bundled by Flutter 已 >= 3.25；CI 验证通过即可 |
| Flutter `.kind` → `.viewHint` 遗漏 | MEDIUM | `rg "\.kind"` 扫描；`flutter analyze` 编译错误自动暴露 |

## Test Baseline

Entry: PR-RB-01 exit count
Exit: **≥ PR-RB-01 count**（测试数量不减少；可能新增 `derive_title` / `derive_view_hint` 单元测试）

## Acceptance Criteria

- [x] Migration 0010 成功执行：`title`/`content_type` 列存在，`type` 已重命名为 `view_hint`
- [x] 现有数据 `title` 回填完成（非空 content 的 atom 有非空 title）
- [x] FTS5 索引 `title`，搜索标题可命中
- [x] `derive_title()` 函数实现：markdown 内容自动提取首行标题
- [x] `derive_view_hint()` 函数实现：基于 task_status + 时间字段自动推导
- [x] 创建/更新路径自动调用推导（不需要调用方显式传入 title/view_hint）
- [x] `AtomListItem` 包含 `title`/`content_type`/`view_hint` 字段
- [x] `EntrySearchItem` 包含 `title`/`view_hint` 字段
- [x] Flutter 侧使用 `title` 字段显示标题
- [x] 全部 Rust tests 通过（204 passed）
- [x] 全部 Flutter tests 通过（333 passed）
- [x] CI green（fmt + clippy + analyze clean）
