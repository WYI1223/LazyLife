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

## v0.4 规范入口裁决草案（Atom Create）

> 本节用于固化 2026-03-01 讨论结果，作为 v0.4 实施基线。  
> 讨论前提：全部以 **v0.3 完成态** 为起点，不以当前未完成代码为约束。

### A. 总体立场（已确认）

1. **语义不妥协，迁移可分阶段**：`atom_create` 作为规范入口是目标，不再维持长期的 feature 创建分裂。
2. **monorepo 一体化落地**：Rust Core / FFI / Flutter / tests / docs 必须一次定义、分层实施，避免只改某一层导致语义漂移。
3. **统一的是“创建事务内核”，不是丢弃业务意图**：`note/task/event` 仍可作为意图输入存在，但不再绑定为不同创建 API。

### B. v0.3 完成态下 `note_create` 与 `entry_create_*` 的关系定位

在 v0.3 完成态语义中：

1. 四类创建入口（`note_create` / `entry_create_note` / `entry_create_task` / `entry_schedule`）应共享同一事务内核：`Atom + atom_ref` 原子创建。
2. 差异仅保留在“默认意图与路由策略”，不保留在“是否原子创建”。
3. 这意味着 v0.4 可将四者收敛为 `atom_create`，其余入口若保留，仅作为兼容包装层。

### C. `atom_create` 规范契约（草案）

### 请求模型（建议）

```text
atom_create(request)
```

`request` 字段建议：

1. `content: String`（必填）
2. `content_type: Option<String>`（默认 `markdown`）
3. `intent: Option<note|task|event>`（用于补默认值，不是强制覆盖）
4. `task_status: Option<String>`
5. `start_at: Option<i64>`
6. `end_at: Option<i64>`
7. `parent_node_id: Option<String>`（决定创建位置；`None` = root）
8. `tags: Option<Vec<String>>`（支持 Notes 上下文创建时一次性应用标签）

### 语义规则（必须）

1. **字段优先于 intent**：`intent` 只补默认值，不覆盖调用方显式字段。
2. **view_hint 最终由字段推导**：`task_status` > `start_at/end_at` > `note`（S1 R3）。
3. **组织与语义正交**：`parent_node_id` 只决定 ref 位置，不能隐式把 note 改写成 task/event（S4 正交原则）。
4. **强制伴随不变**：创建成功必须同时有有效 `atom_ref`（S1 R5）。

### 返回模型（建议统一）

`AtomCreateResponse`：

1. `ok`
2. `error_code`
3. `message`
4. `atom_id`
5. `node_uuid`
6. `item: Option<AtomListItem>`

说明：当前 `note_create`（偏 item）与 `entry_create_*`（偏 action）的返回差异属于历史分层产物，v0.4 应统一为单一创建返回契约。

### D. 场景映射（从 feature 入口到统一入口）

| 业务场景 | 统一调用语义 |
|---|---|
| Notes 头部“新建” | `atom_create(intent=note, parent_node_id=None)` |
| Explorer 在文件夹中创建 | `atom_create(intent=note, parent_node_id=Some(folder))` |
| Single Entry: `> note ...` | `atom_create(intent=note, parent_node_id=route(note))` |
| Single Entry: `> task ...` | `atom_create(intent=task, parent_node_id=route(task))` |
| Single Entry: `> schedule ...` | `atom_create(intent=event, start/end..., parent_node_id=route(calendar))` |
| Tasks inline create | `atom_create(intent=task, parent_node_id=route(task))`（禁止再走 note 入口） |

### E. monorepo 实施清单（v0.4）

### E1. Rust Core（`crates/lazynote_core`）

1. 引入统一创建服务（建议 `create_atom_with_ref` 或 `AtomCreationService`）。
2. 在单事务中完成：`insert atom` + `insert atom_ref`。
3. 将 `derive_title` / `derive_markdown_preview` / `derive_view_hint` 收敛到可复用位置，避免 `note_service` 私有逻辑扩散。
4. 提供 `atom_get` / `atom_update_content` 通用路径（`atom_update_content` 需定义字段重算规则）。
5. `note_service` 改为调用统一内核（若保留）。

### E2. FFI（`crates/lazynote_ffi/src/api.rs`）

1. 新增 `atom_create` / `atom_get` / `atom_update_content`。
2. 统一创建响应 envelope（`atom_id + node_uuid + item`）。
3. `note_create`、`entry_create_*` 改为薄包装或标记 deprecated。
4. 更新错误码映射与契约注释。

### E3. Flutter（`apps/lazynote_flutter`）

1. Notes 创建链路改调 `atomCreate`。
2. Entry controller 的 create note/task/schedule 全部改调 `atomCreate(intent=...)`。
3. Tasks inline create 改为 `intent=task`，禁止 `entryCreateNote` 路径。
4. Explorer 文件夹创建直接传 `parentNodeId` 给统一入口，移除“两次 FFI 调用”。
5. 统一 invoker typedef，减少 feature 级创建 API 分裂。

### E4. Tests + Docs

1. Rust：原子性、推导优先级、组织-语义正交、错误码回归。
2. Flutter：notes/entry/tasks/calendar 四入口创建回归一致性。
3. 文档同步：`S1`、`S4`、`ffi-contracts.md`、DI-11。

### F. 迁移策略（建议）

1. **阶段 1（引入）**：新增 `atom_create`，旧入口改为内部委托。
2. **阶段 2（切流）**：Flutter 全量改调 `atom_create`。
3. **阶段 3（收口）**：旧入口标记 deprecated（或按版本策略移除）。

### G. 待细化问题（下一轮讨论）

1. `atom_update_content` 是否允许同请求内更新 `content_type`。
2. `tags` 在 `atom_create` 中是同步写入还是后置异步补写。
3. `item` 返回是否必填（性能 vs 一次请求闭环）。
4. 旧 API 的弃用窗口长度与版本策略（v0.4.x 内是否保留）。

### H. Pending 语义统一（2026-03-01 新增共识）

为避免 Tasks 与 Calendar 的中间态心智割裂，新增统一口径：

1. **Pending 不是类型，而是视图中的中间状态容器**。
2. **字段决定可见性，`atom_ref` 决定组织位置**。
3. **Explorer 是两类 Pending 的共同桥梁**：通过 `atom_ref` 维持强链接与可追溯路径。

#### H1. Tasks Pending（对应当前 Tasks Inbox）

建议语义名：`Tasks Pending`（UI 可保留 `Inbox` 文案，文档层标注其语义）。

建议判定规则：

```sql
task_status IS NOT NULL
AND task_status NOT IN ('done', 'cancelled')
AND start_at IS NULL
AND end_at IS NULL
```

含义：活跃任务但尚未排入具体时间锚点。

#### H2. Calendar Pending（对应当前待排期池）

沿用 S1 既有定义：Calendar 工作域内、未设置时间锚点的条目进入待排期池。

建议判定规则（语义草案）：

```sql
in_calendar_designated_scope = true
AND start_at IS NULL
AND end_at IS NULL
```

说明：`in_calendar_designated_scope` 在实现层可由 designated folder 映射 + `atom_ref` 路径判定达成。

#### H3. 与 Archive 的边界

1. `Tasks Pending` 与 `Tasks Archive` 不同层级语义：前者是“待安排”，后者是“已结束历史”。
2. `Tasks Archive`（如后续显式化）建议由 `task_status IN ('done', 'cancelled')` 定义。
3. 不应将 `Calendar Pending` 与 `Tasks Archive` 合并为同一容器。

#### H4. 对 `atom_create` 的影响

1. 在 Tasks/Calendar 相关入口调用 `atom_create` 时，是否进入 Pending 由字段状态决定，不由 API 名称决定。
2. `parent_node_id` 仅承载组织路径，不承担语义类型推导职责。
3. 这与 S4“视图-文件夹正交”保持一致。

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
