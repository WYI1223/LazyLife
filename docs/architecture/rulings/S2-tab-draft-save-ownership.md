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
| 1 | 新建 `EditorShellService`（workbench 级），从 coordinator 提取 `NoteTabManager` → `EditorGroupModel[]`，提取 `NoteDraftManager` → `DraftManager`，提取 `NoteSaveTracker` → `SaveTracker` |
| 2 | WorkspaceProvider 的 pane 布局提取为 `GroupLayout`，合并入 `EditorShellService` |
| 3 | Tab 列表改为 per-group，直接支持多 pane |
| 4 | Tab 列表接受任意 Atom UUID，DraftManager/SaveTracker 同步泛化 |
| 5 | 删除 WorkspaceProvider（完全被 EditorShellService 取代） |

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
| Phase 2：EditorShellService | v0.3 待实施 |
| Phase 3：EditorResolver | v0.3 待实施 |

---

## 开放设计项

- Phase 2 的 `EditorGroupModel` 状态机细节（group 创建/销毁/合并生命周期）
- Phase 3 的 EditorResolver 注册协议（静态注册 vs 动态发现）
