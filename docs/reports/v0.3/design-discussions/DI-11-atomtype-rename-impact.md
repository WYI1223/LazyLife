# DI-11: AtomType → ViewHint 枚举重命名影响分析

| 字段 | 值 |
|------|-----|
| 状态 | **RESOLVED** |
| 关联裁决 | S1 R3 (view_hint 自动推导) |
| 关联 PR | PR-RB-02 (S1 核心字段落地) |
| 决策日期 | 2026-03-01 |

---

## 背景

S1 R3 裁定 `type`/`kind` 字段重命名为 `view_hint`。PR-RB-02 实施该重命名时，需决定 Rust 枚举 `pub enum AtomType { Note, Task, Event }` 是否同步重命名为 `ViewHint`。

`AtomType` 目前在 atom 架构中扎根很深——从模型层、仓库层、服务层到 FFI 层和测试文件，共约 90+ 处引用。

## 问题

1. 如果只改字段名 `kind` → `view_hint` 而保留枚举名 `AtomType`，语义不一致：字段叫 `view_hint`，类型却叫 `AtomType`
2. 如果同步改枚举名 `AtomType` → `ViewHint`，改动面大，但一次性对齐全部命名

## 现状补充（2026-03-01 讨论）

### Notes 专用 API 入口约束（当前实现）

当前 `note_*` API 是 Notes feature 的专用用例入口，而不是 Atom 通用入口：

- FFI：`note_create` / `note_update` / `note_get` / `notes_list` / `note_set_tags` / `tags_list`
- Core：`NoteRepository` 和 `NoteService` 路径对 `view_hint='note'` 有显式约束

这意味着 `view_hint = task/event` 的 Atom **不能**通过 `note_*` 路径读取或更新内容。

### 用户心智模型暴露的问题

S1 R1 的目标是 Atom 统一容器模型，但当前用例入口仍以 feature 分割，导致：

1. 领域模型已经统一，入口能力仍不统一
2. 缺少“按 AtomId 直接读取/更新内容”的通用路径

### DI-11 范围判定

DI-11 本身聚焦命名与语义收敛（`AtomType` → `ViewHint`），但需要在本文记录一个后续缺口：

- 需补充 Atom 通用入口（后续讨论）：
  - `atom_get(atom_id)`
  - `atom_update_content(atom_id, content)`

该缺口不改变 DI-11 的主裁决（命名统一仍是必须项），但影响后续“Atom 统一心智模型”在 API 层的闭环完整性。

## 讨论基线与已确认条件（2026-03-01）

### 讨论基线

本议题后续细化以 **v0.3 目标完成态** 为基线，而不是只看当前已落地代码。语义参考以下规划与裁决：

- v0.3 rebaseline：`PR-RB-00 ~ PR-RB-11` 序列
- PR-RB-03：`atom_ref` 统一与创建路径统一
- PR-RB-06/07/08/09：`EditorShellService` / `GroupLayout` / `EditBuffer` / `EditorResolver`
- DI-1/DI-4/DI-10：编辑器基础设施与 buffer 同步模型裁决

### 已确认条件

1. **DI-11 主裁决保持不变**：`AtomType` → `ViewHint` 的命名与语义收敛是已确定项。
2. **优化窗口放在 v0.4**：本轮讨论形成的入口统一与语义优化，不回改 v0.3 收口范围。
3. **采用 Atom-first API 基准**：实体读写以 `atom_*` 作为规范入口，`note_*` 视为 feature 兼容包装层（迁移期保留）。
4. **保留 feature 查询入口**：`tasks_list_*` / `calendar_list_by_range` 等投影视图查询继续作为 feature 语义入口存在。
5. **语义正交保持不变**：`content_type` 负责编辑器选择，`view_hint` 负责渲染提示，两者不互相替代。

### 后续讨论清单（按顺序细化）

1. `atom_create`：请求字段、默认路由、与 `atom_ref` 的原子创建契约。
2. `atom_get`：通用读取 DTO 边界（必须字段、可选字段、兼容字段）。
3. `atom_update_content`：仅内容更新语义、字段影响面、错误码与并发语义。
4. `note_*` 迁移策略：包装层保留周期、调用链收敛路径、弃用节奏。
5. API 兼容策略：v0.3/v0.4 过渡期的调用方稳定性与文档口径。

## 影响面统计

| 层 | 影响项 | 估计处数 |
|----|--------|---------|
| `model/atom.rs` | 枚举定义、`Atom` struct 字段类型、构造函数参数、doc comments | ~15 |
| `repo/atom_repo.rs` | `AtomListQuery.kind` 类型、`atom_type_to_db()`、`parse_atom_type()`、row mapping | ~12 |
| `repo/note_repo.rs` | `AtomType::Note` 类型守卫 | ~3 |
| `repo/tree_repo.rs` | `atom_kind()` 返回类型、match 分支 | ~5 |
| `service/atom_service.rs` | `AtomType::Note/Task/Event` 构造 | ~6 |
| `service/note_service.rs` | `AtomType::Note` 构造 | ~2 |
| `service/tree_service.rs` | `AtomType::Note` 类型守卫 | ~3 |
| `search/fts.rs` | `SearchHit.kind` 类型、`SearchQuery.kind`、序列化函数 | ~8 |
| `lib.rs` | pub use 导出 | ~1 |
| `lazynote_ffi/api.rs` | import、`atom_type_label()`、`parse_entry_search_kind()` | ~12 |
| 集成测试 (6 files) | `AtomType::Note/Task/Event` 构造、断言 | ~40+ |
| **合计** | | **~107** |

## 重命名策略

### 枚举重命名

```
AtomType        → ViewHint
AtomType::Note  → ViewHint::Note
AtomType::Task  → ViewHint::Task
AtomType::Event → ViewHint::Event
```

### 字段重命名

```
Atom.kind             → Atom.view_hint
SearchHit.kind        → SearchHit.view_hint
SearchQuery.kind      → SearchQuery.view_hint
AtomListQuery.kind    → AtomListQuery.view_hint
NoteRecord.kind       → NoteRecord.view_hint
AtomListItem.kind     → AtomListItem.view_hint
EntrySearchItem.kind  → EntrySearchItem.view_hint
```

### 函数重命名

```
atom_type_to_db()       → view_hint_to_db()
parse_atom_type()       → parse_view_hint()
atom_type_label()       → view_hint_label()      (FFI)
parse_entry_search_kind() → 保持不变 (参数名 kind 不变, DI-9 v0.4)
atom_kind()             → atom_view_hint()        (TreeRepo)
```

## 决策

**重命名 `AtomType` → `ViewHint`**。理由：

1. **一致性**：DB 列 `view_hint`、Rust 字段 `view_hint`、Rust 类型 `ViewHint`、FFI 字段 `view_hint`、Dart 字段 `viewHint` 全部对齐
2. **语义准确**：S1 R3 明确 view_hint 是"渲染提示"，不是"类型"。`AtomType` 暗示 Atom 有不同类型，与 S1 R1 "Atom 是泛型容器"的核心理念矛盾
3. **一次性成本**：在 PR-RB-02 中和 `kind` → `view_hint` 字段重命名一起做，增量成本可控。如果留到后续，每个新文件都在积累 `AtomType` 引用

## 执行方式

在 PR-RB-02 Phase 2 (Rust Core Model) 中执行：

1. `model/atom.rs`：`pub enum AtomType` → `pub enum ViewHint`，字段 `kind` → `view_hint`
2. `lib.rs`：导出 `ViewHint` 替代 `AtomType`
3. 全 crate `replace_all`：`AtomType` → `ViewHint`
4. 函数重命名：`atom_type_to_db` → `view_hint_to_db` 等
5. 测试文件批量替换

使用编辑器 `replace_all` 可高效完成，`cargo test` 验证无遗漏。
