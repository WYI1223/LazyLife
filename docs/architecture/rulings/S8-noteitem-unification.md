# S8: NoteItem → AtomListItem 类型统一

| 字段 | 值 |
|------|-----|
| 状态 | **Deferred** — v0.3 实现 |
| 裁决日期 | 2026-02-26 |
| 关联 PR | 新 ffi-type-unification PR（v0.3） |

---

## 决策

**统一为 AtomListItem，废弃 NoteItem。** AtomListItem 是 NoteItem 的严格超集，统一后消除 FFI 边界的信息丢弃问题。

---

## 规则

1. **单一 DTO**：所有 Atom 列表查询统一返回 `AtomListItem`
2. **信息完整性**：FFI 边界不主动丢弃 Atom 的任何可展示属性
3. **UI 层决策权**：由 UI 根据字段值决定渲染哪些元素，不由 DTO 类型限制
4. **EntrySearchItem 保留**：搜索结果是不同投影（snippet-based），不在统一范围内

---

## 核心问题

AtomListItem 是 NoteItem 的**严格超集**：

| 字段 | NoteItem | AtomListItem |
|------|----------|-------------|
| atom_id, content, preview_text, preview_image, updated_at, tags | ✓ | ✓ |
| kind（→ view_hint） | **✗** | ✓ |
| start_at | **✗** | ✓ |
| end_at | **✗** | ✓ |
| task_status | **✗** | ✓ |

NoteItem 缺失的 4 个字段恰好是 S1 Atom 统一容器模型的核心维度。当 Notes API 返回 NoteItem 时，消费者**无法知道**该 Atom 是否有 deadline 或 task_status。

### 信息断裂场景

1. 用户在 Notes 视图写一条笔记
2. 在 Tasks 视图给它加 deadline
3. 回到 Notes 视图 → NoteItem 不携带 `end_at` → 看不到 deadline 标识

统一为 AtomListItem 后，Notes 视图可在条目上显示 deadline 标签、checkbox 等。

---

## 迁移路径

| 当前 | 统一后 |
|------|--------|
| `note_create` → `NoteResponse(NoteItem)` | → 响应类型包装 `AtomListItem` |
| `note_update` → `NoteResponse(NoteItem)` | → 同上 |
| `note_get` → `NoteResponse(NoteItem)` | → 同上 |
| `notes_list` → `NotesListResponse(Vec<NoteItem>)` | → `AtomListResponse(Vec<AtomListItem>)` |

### S1 后续字段的收益

| S1 裁决 | 统一后影响 |
|---------|----------|
| R4 view_hint | `kind` 重命名为 `view_hint` — 只改一个 DTO |
| R8 title | 新增 `title` 字段 — 只加到一个 DTO |
| R9 content_type | 新增 `content_type` 字段 — 同上 |

统一后，S1 的所有新字段只需加到一处，消除两套 DTO 的同步维护成本。

---

## 理由

1. **信息完整性**：NoteItem 在 FFI 边界主动丢弃 time/status 字段，统一后所有消费者都能看到 Atom 的全部属性
2. **S1 一致性**：Atom 是统一容器，DTO 应反映这一模型 — 一个 Atom 的所有属性在任何 API 路径都可见
3. **维护成本降低**：一套 DTO 替代两套，S1 新字段只需加到一处
4. **渲染灵活性**：统一后 Notes 视图可选择性展示 deadline 标签等，UI 层按字段值决策
5. **超集关系无损**：迁移是纯加法，不丢失现有信息

---

## 实施状态

| 项目 | 状态 |
|------|------|
| 语义定义 | v0.2.5 已完成 |
| Rust FFI 返回类型变更 | v0.3 待实施 |
| Flutter 端 NoteItem 消费者迁移 | v0.3 待实施 |
| ffi-contracts.md 更新 | v0.3 随实施同步 |

---

## 开放设计项

- NoteItem 废弃的过渡策略（直接删除 vs deprecation period）
- Flutter 端消费者迁移的批量重构方案
