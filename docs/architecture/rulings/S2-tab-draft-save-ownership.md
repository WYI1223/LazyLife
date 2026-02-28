# S2: Tab/Draft/Save 状态归属

| 字段 | 值 |
|------|-----|
| 状态 | **Phase 1 Landed** (v0.2.5 PR-0258) — Phase 2/3 Deferred to v0.3 |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0258（已完成）、PR-0301（递归布局）、PR-0303（buffer 同步）、PR-0304（tab 模型） |

---

## 决策

Tab/Draft/Save 状态**不属于 Notes feature**，而是 workbench 级基础设施。通过三阶段渐进迁移，从 notes coordinator 内部提升到独立的 EditorShellService。

---

## 规则

1. **单一状态源**：Tab 打开列表、草稿缓冲区、保存状态在任何时刻只有一个权威持有者
2. **状态不双写**：禁止两个组件同时维护相同状态的副本（WP Bridge 模式已在 Phase 1 删除）
3. **泛型 Tab**：Tab 列表接受任意 Atom UUID，不仅限于 note 类型
4. **Pane 隔离**：多 pane 模式下，每个 pane 维护独立的 tab 列表（PR-0257 已实现 `Map<String, List<String>>`）

---

## 三阶段实施

### Phase 1 — v0.2.5：消除双状态（已完成）

| 步骤 | 内容 | 结果 |
|------|------|------|
| 1 | 迁移 NotesPage 消费点从读 WP 改为读 coordinator | 已完成 |
| 2 | 删除 `_syncWorkspaceFromControllerState()` 等 bridge 同步代码 | 已删除 ~260 行 |
| 3 | 删除 `_WorkspaceProviderPort` adapter | 已删除 |
| 4 | WorkspaceProvider 缩减到仅 pane 布局 | 664 → 166 行 |

**Phase 1 成果**：NotesCoordinator 是唯一 tab/draft/save 状态源。WorkspaceProvider 仅管 pane 布局（`splitActivePane` / `closeActivePane` / `layoutState`）。

### Phase 2 — v0.3 PR-0301：提升到 workbench 级

| 步骤 | 内容 |
|------|------|
| 1 | 新建 `EditorShellService`（workbench 级），从 coordinator 提取 `NoteTabManager` → `EditorGroupModel[]`，提取 `NoteDraftManager` + `NoteSaveTracker` → 统一为 `EditBuffer`（per-atom）（DI-1 Q3 修正：双组件存在状态双写，统一为自包含状态机） |
| 2 | WorkspaceProvider 的 pane 布局提取为 `GroupLayout`，合并入 `EditorShellService` |
| 3 | Tab 列表改为 per-group，直接支持多 pane |
| 4 | Tab 列表接受任意 Atom UUID，EditBuffer 同步泛化（DI-1 Q3：DraftManager/SaveTracker 已统一为 EditBuffer） |
| 5 | 删除 WorkspaceProvider（完全被 EditorShellService 取代） |

#### Phase 2 设计规则（DI-1 裁决）

> 完整分析见 `docs/reports/v0.3/design-discussions/DI-1-editor-shell-service.md`。以下为关键裁决摘要。

**EditorGroupModel（per-pane 视觉状态）**：

| 状态 | 说明 |
|------|------|
| `tabs: List<TabEntry>` | 窗格内打开的 tab 列表。`TabEntry { atomId: String, title: String }`，title 来源为 `atom.title`（S1 R8） |
| `activeAtomId: String?` | 窗格当前激活的 tab |
| `previewTabId: String?` | 窗格的预览 tab（per-group，非全局） |

Draft 内容和 save 状态**不属于** EditorGroupModel — 它们是 per-atom 的 EditBuffer 状态，跨 pane 共享。

**Group 生命周期**：

| 事件 | 行为 |
|------|------|
| 启动 | 创建 1 个 primary group |
| Split | 创建新 group，复制当前 activeTab |
| 关闭 tab | 从 group.tabs 移除 |
| 关闭最后一个 tab（非 primary） | group 自动销毁 |
| 关闭最后一个 tab（primary） | group 保留，显示空状态 |

**EditBuffer（per-atom 自包含状态机）**：

- 统一原 `NoteDraftManager` + `NoteSaveTracker`，消除状态双写
- 三阶段状态机：`loading → ready → disposing`
- `saveState` 为 getter（从字段派生），不存储
- `persistFn` 闭包注入：Coordinator 提供 FFI 保存回调，EditBuffer 不知道 FFI 的存在
- 引用计数：closeTab 时检查 atomId 是否还在其他 group 中，无则 flush + dispose

**NoteTabStrip（UI widget）**：

渲染 tab 条的 StatefulWidget（`lib/features/notes/note_tab_strip.dart`），负责 tab chip 显示、点击、右键菜单、滚轮交互。与 `EditorGroupModel`（纯逻辑状态管理）是正交的两个组件。

**Coordinator 提取后结构**：

提取 tab/draft/save 后，NotesCoordinator 保留为 notes feature controller：

| 保留组件 | 职责 |
|---------|------|
| `NoteListManager` | 列表查询 + 缓存 |
| `NoteTagManager` | tag CRUD + 变更队列 |
| `selectedNote` / `detailLoading` | 详情面板 DTO + 加载状态 |
| `selectedTag` | 列表过滤条件 |

通信模式：Coordinator → Service（直接调用）、Service → FFI（persistFn 闭包）、Service → Coordinator（onBufferSaved 回调）。

### Phase 3 — v0.3 PR-0301+：EditorResolver

| 步骤 | 内容 |
|------|------|
| 1 | 新建 `EditorResolver`，根据 Atom 的 `content_type` 选择 `EditorPane` |
| 2 | 当前 `NoteContentArea` 重命名为 `MarkdownEditorPane`，注册为 `markdown` 渲染器 |
| 3 | 未来 canvas/conversation/plugin 各注册自己的 `EditorPane` |

---

## 参考架构

VSCode EditorService 三层分离验证了此模型：

| VSCode | LazyNote 对应 |
|--------|--------------|
| `EditorGroupsService` | `EditorShellService`（Phase 2） |
| `EditorGroup` | `EditorGroupModel`（per-pane tab 列表） |
| `EditorService` | `EditorResolver`（Phase 3，content_type → EditorPane） |

---

## 理由

1. **S1 对齐**：S1 R1 定义 Atom 是泛型容器，任何 Atom 都可打开编辑。tab/draft/save 住在 notes feature 与此矛盾
2. **Phase 1 独立有收益**：删除 bridge 消除 ~260 行同步代码和双状态 bug 风险，无需等待后续 phase
3. **渐进可验证**：每个 phase 结束后系统都可运行、可测试，不需要一次性大爆炸重写
4. **Phase 1 是 Phase 2 的正确起点**：coordinator 单源状态是提取 EditorShellService 的前提

---

## 实施状态

| 项目 | 状态 |
|------|------|
| Phase 1：消除双状态 | **已完成** — PR-0258，WP 664→166 行 |
| Phase 2：EditorShellService | v0.3 待实施（**设计完成** — DI-1 Q1-Q5 RESOLVED） |
| Phase 3：EditorResolver | v0.3 待实施 |

---

## 开放设计项

- ~~Phase 2 的 `EditorGroupModel` 状态机细节（group 创建/销毁/合并生命周期）~~ — **已由 DI-1 Q1+Q2 回答**
- Phase 3 的 EditorResolver 注册协议（静态注册 vs 动态发现） — 待 DI-3
