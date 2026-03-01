# S2: Tab/Draft/Save 状态归属

| 字段 | 值 |
|------|-----|
| 状态 | **Phase 1 Landed** (v0.2.5 PR-0258) — Phase 2/3 Deferred to v0.3 |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0258（已完成）、PR-0301（递归布局）、PR-0303（buffer 同步）、PR-0304（tab 模型）、PR-0305（间接 — buffer 同步性能） |
| 关联 DI | DI-1（RESOLVED）、DI-2（RESOLVED）、DI-3（RESOLVED）、DI-4（Q1+Q1补充 RESOLVED，Q2-Q5 OPEN）、DI-10（RESOLVED） |

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
- `_rev: int`：单调递增版本号（DI-4 Q1 补充裁决）。**统一 DI-1 的 `_editVersion`**——两者均在每次 `edit()` 时自增，语义等价，合并为 `_rev`。用途：(1) 防陈旧保存（debounce timer 触发时检查）；(2) 同步协议版本（EditOp.baseRev）；(3) overlay stale 判定
- `edit(String newContent, {EditOp? op})`：v0.3 调用方不传 `op`（等效全量替换）。接口预留三路 EditOp 通道：`SnapshotReplace` / `TextDelta` / `StructuredOp`（详见 DI-4 Q1 补充裁决）

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

#### Phase 2 布局持久化（DI-3 裁决）

> 完整分析见 `docs/reports/v0.3/design-discussions/DI-3-layout-persistence.md`。以下为关键裁决摘要。

GroupLayout 和 EditorGroupModel tab 列表**联合持久化**到独立文件：

- **文件路径**：`%APPDATA%/LazyLife/workspace_layout.json`（独立于 `settings.json`，避免频繁写入干扰设置文件）
- **序列化范围**：树结构（SplitNode/LeafNode）+ per-group tab 列表 + activeTab + previewTab + primaryGroupId。不序列化 draft 内容和 save 状态（分别由 DB 重加载和 getter 派生）
- **写入策略**：1 秒去抖（debounce），复用 `LocalSettingsStore` 三阶段 atomic write
- **Recovery**：文件不存在/损坏/schema 版本不匹配 → 默认单 pane
- **Pane 上限**：8（DI-3 D9），无深度限制

**两阶段恢复模型**（DI-3 ↔ DI-4 边界）：

| 阶段 | 范畴 | 依赖 | 产出 |
|------|------|------|------|
| 1 — 结构恢复 | DI-3 | 纯 Dart（无 FFI） | GroupLayout 树 + EditorGroupModel（EditBuffer 均为 `loading`） |
| 2 — 内容加载 | DI-4 | RustBridge + SQLite | EditBuffer `loading` → `ready` |

**序列化方法归属**：`GroupLayout.toJson()`/`fromJson()` 在 `group_layout.dart` 内；文件 I/O + 去抖 + recovery 在独立的 `LayoutPersistence`（`lib/core/editor/layout_persistence.dart`）。

### Phase 3 — v0.3 PR-0301+：EditorResolver

> 完整分析见 `docs/reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`。以下为关键裁决摘要。

| 步骤 | 内容 |
|------|------|
| 1 | 新建 `EditorResolver`，根据 Atom 的 `content_type` 选择 `EditorPane` |
| 2 | 当前 `NoteContentArea` 拆分：编辑核心提取为 `MarkdownEditorPane`，注册为 `markdown` 渲染器；外壳 chrome（loading/error/metadata/tags）保留在 notes feature |
| 3 | 未来 canvas/conversation/plugin 各注册自己的 `EditorPane` |

#### Phase 3 设计规则（DI-10 裁决）

**EditorPane 接口**：

```dart
typedef EditorPaneBuilder = Widget Function(BuildContext context, EditBuffer buffer);
```

EditBuffer 提供 `content`（opaque string）、`edit()`、`atomId`、`saveState`。每个 EditorPane 自己负责按 content_type 解析内容、渲染、序列化回写。不传入 EditorGroupModel 或 feature-level 状态。

**注册协议**：静态 Map + `register()` 方法。v0.3 只注册 `markdown`；`plugin:<id>` 动态注册时复用同一接口。

```dart
class EditorResolver {
  final Map<String, EditorPaneBuilder> _registry = {};
  void register(String contentType, EditorPaneBuilder builder);
  EditorPaneBuilder resolve(String contentType);
}
```

**Fallback 行为**：未知 content_type → 错误占位（"不支持的内容类型"），不 fallback 到 markdown。避免结构化数据（canvas JSON / conversation JSON）被文本编辑器渲染导致数据破坏。

**文件位置**：`lib/core/editor/editor_resolver.dart`，与 EditorShellService 同目录。

**View Mode 扩展（v0.4+ 占位）**：同一 content_type 可有多种编辑视图（source / block WYSIWYG / inline WYSIWYG / preview）。编辑模式是 per-pane 视图选择，不是 content_type 属性。v0.3 不实现——`resolve(contentType)` 签名不变，仅源码编辑。v0.4+ 扩展为 `resolve(contentType, viewMode: ViewMode.source)`。配套需求：TabEntry 扩展 `viewMode` 字段（EditorGroupModel）。详见 DI-10 开放设计项、DI-4 Q1 补充裁决。

**三层职责分离**：

| 层 | 职责 | 组件 |
|---|------|------|
| 状态管理 | groups, buffers, layout | EditorShellService |
| 编辑器选择 | content_type → EditorPane widget | EditorResolver |
| 外壳展示 | loading/error/metadata/tags | Feature controller（notes/tasks/...） |

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
| Phase 2：EditorShellService | v0.3 待实施（**设计完成** — DI-1 Q1-Q5 RESOLVED，DI-4 Q1 RESOLVED + Q1 补充 RESOLVED） |
| Phase 3：EditorResolver | v0.3 待实施（**设计完成** — DI-10 RESOLVED，含 View Mode 占位） |

---

## 开放设计项

- ~~Phase 2 的 `EditorGroupModel` 状态机细节（group 创建/销毁/合并生命周期）~~ — **已由 DI-1 Q1+Q2 回答**
- ~~Phase 3 的 EditorResolver 注册协议（静态注册 vs 动态发现）~~ — **已由 DI-10 回答**（静态 Map + register()）
- ~~DI-1 `_editVersion` 与 DI-4 `_rev` 统一~~ — **已统一为 `_rev`**（本文 EditBuffer 节已更新；DI-1 后续实现时同步重命名）
- Phase 3 的 EditBuffer 桥接模式（EditorPane 共享的 buffer 监听/同步逻辑） — DI-4 Q3 OPEN（桥接机制初步建议已出，待细化裁决）
- 多编辑范式（source / block WYSIWYG / inline WYSIWYG）架构预留 — DI-4 Q1 补充已裁决协议层；实现延后至 v0.4+。完整方案见 `docs/product/idea_temp/rich-block-editing-architecture.md`
- View Mode per-pane 选择 + DI-3 布局持久化 viewMode 字段 — v0.4+ schema_version 升级时处理
