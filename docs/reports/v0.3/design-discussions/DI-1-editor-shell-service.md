# DI-1: EditorShellService 接口设计 + 状态归属

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** — Q1-Q5 全部裁决完毕 |
| **关联决策点** | D1、D2、D3 |
| **阻塞 PR** | PR-0301B（直接）、PR-0303、PR-0304、PR-0311（间接） |
| **前置依赖** | DI-0（D4 已 RESOLVED） |
| **来源** | 01-design-readiness-audit.md §4.1 |

---

## 问题提取

### 来源 §4.1 设计空白详析

> EditorShellService 是 §9 结构重审的核心新增（PR-0301B），是 S2 Phase 2 裁决的落地载体。但目前：
>
> - `EditorGroupModel` 在代码库中 **完全不存在**（grep 零匹配）
> - 目标提取源是 coordinator 内部的 3 个 manager，其接口从未设计为 "可对外暴露"

### 审计报告原始决策点

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D1 | Service 形态 | A: 组合现有 manager / B: 新建 EditorGroupModel / C: Facade 读取接口 | 全部 Track B PR |
| D2 | 状态归属 | Tab 状态、draft buffer、save tracker 的归属点 | PR-0303 buffer sync |
| D3 | Coordinator 残留职责 | 提取后 coordinator 还管什么？ | R1 风险缓解效果 |

---

## S2 裁决已定义的方向

S2（`docs/architecture/rulings/S2-tab-draft-save-ownership.md`）Phase 2 已定义：

| S2 步骤 | 内容 |
|---------|------|
| 1 | 新建 `EditorShellService`，提取 `NoteTabManager → EditorGroupModel[]`，`NoteDraftManager → DraftManager`，`NoteSaveTracker → SaveTracker` |
| 2 | WorkspaceProvider 的 pane 布局提取为 `GroupLayout`，合并入 EditorShellService |
| 3 | Tab 列表改为 per-group，直接支持多 pane |
| 4 | Tab 列表接受任意 Atom UUID，DraftManager/SaveTracker 同步泛化 |
| 5 | **删除 WorkspaceProvider**（完全被 EditorShellService 取代） |

S2 4 条规则：单一状态源、状态不双写、泛型 Tab（任意 Atom UUID）、Pane 隔离。

S2 参考架构：VSCode `EditorGroupsService` → `EditorShellService`，VSCode `EditorGroup` → `EditorGroupModel`。

**结论：D1 由 S2 已回答 — 选项 B（新建 EditorGroupModel）。**

S2 的开放设计项：

> 1. ~~Phase 2 的 `EditorGroupModel` 状态机细节（group 创建/销毁/合并生命周期）~~ — **已由 Q1+Q2 回答**
> 2. Phase 3 的 EditorResolver 注册协议（静态注册 vs 动态发现） — 待 DI-10

---

## Q1: EditorGroupModel 拥有什么状态？ — RESOLVED

### 设计原则

从用户视角推导出两个正交维度：

| 维度 | 用户感知 | 粒度 |
|------|---------|------|
| **"我在哪里看"** | 窗格 A 打开了 3 个 tab，窗格 B 打开了 2 个 tab | **per-pane** |
| **"内容是什么"** | 这篇笔记的文字、是否有未保存修改 | **per-atom** |

**视觉安排是 per-pane 的，内容真相是 per-atom 的。** 这是唯一不违反 S2"状态不双写"规则的设计。

### 裁决

**EditorGroupModel（per-pane 视觉状态）：**

| 状态 | 当前来源 | 说明 |
|------|---------|------|
| `tabs: List<TabEntry>` | `NoteTabStateManager._openNoteIdsByPane[paneId]` | 这个窗格打开了哪些 tab（`TabEntry { atomId, title }`，见 Q4 细化1） |
| `activeAtomId: String?` | `coordinator._activeNoteIdByPane[paneId]` | 这个窗格当前看的是哪个 |
| `previewTabId: String?` | `NoteTabStateManager._previewTabId`（当前全局单一） | **改为 per-group** |

**不属于 EditorGroupModel 的状态（per-atom，归 service 级 EditBuffer，见 Q3）：**

- draft 内容 — 同一笔记在两个窗格中编辑时是同一份 EditBuffer
- save 状态 — 同一笔记在两个窗格中都应显示一致的 dirty/clean

---

## Q2: EditorGroupModel 生命周期 — RESOLVED

### 核心规则

**Group 存在 ↔ Group 有 tab（或是 primary group）。** 无显式"关闭窗格"操作。

参考：VS Code / IntelliJ / Sublime 均无独立的"关闭窗格"按钮，pane 生命周期完全由 tab 驱动。

### 生命周期事件

| 事件 | 行为 |
|------|------|
| **启动** | 创建 1 个 primary group |
| **Split** | 创建新 group，`tabs = [原 activeTab]`，`activeAtomId = 原 activeAtomId`，`previewTabId = null`。原 group 不变。 |
| **关闭 tab** | 从 group.tabs 移除 |
| **关闭最后一个 tab（非 primary group）** | group 自动销毁，空间归还相邻 group |
| **关闭最后一个 tab（primary group）** | group 保留，显示空状态 |
| **Switch** | 切换 EditorShellService.activeGroupId 指针 |

如需快速清空一个窗格，提供"Close All Tabs in Group"批量操作（关闭 tab → 最后一个关完 → group 自然消失）。

---

## Q3: Draft/Save 状态统一 — 方案已确定，待细化

### 问题

S2 原文描述的提取路径是 `NoteDraftManager → DraftManager` + `NoteSaveTracker → SaveTracker`，即机械搬运两个组件。但深入分析发现当前双组件设计本身存在结构性问题。

### 当前设计的三个问题

**问题 1：SaveTracker 与 DraftManager 存在状态双写（违反 S2 Rule 2）**

| 信息 | DraftManager 知道吗？ | SaveTracker 知道吗？ | 双写？ |
|------|---|---|---|
| 是否 dirty | `draft != persisted` ✓ | `_noteSaveState == dirty` ✓ | **是** |
| 是否正在保存 | `saveFutureByAtomId.containsKey(id)` ✓ | `_noteSaveState == saving` ✓ | **是** |
| 是否 clean | `!isDirty && !hasFuture` ✓ | `_noteSaveState == clean` ✓ | **是** |
| 保存失败 | save future 返回 false | `_noteSaveState == error` | SaveTracker 独有 |

SaveTracker 唯一新增信息是 `error` 状态和 `errorMessage`，其余全是 DraftManager 已有信息的冗余投影。

**问题 2：DraftManager 使用并行 Map（代码异味）**

```
Map<AtomId, String>        _draftContentByAtomId
Map<AtomId, String>        _persistedContentByAtomId
Map<AtomId, int>           _draftVersionByAtomId
Map<AtomId, Future<bool>>  _saveFutureByAtomId
Map<AtomId, bool>          _saveQueuedByAtomId
```

5 个 Map 用同一个 key，描述同一个 atom 的不同方面。创建/销毁时必须手动保证 5 个 Map 一致，任何遗漏都是 bug。

**问题 3：SaveTracker 是全局单一的，不支持多 pane**

全局单一 `NoteSaveState` 在多 pane 下无法正确工作（Pane A 的 saving 和 Pane B 的 dirty 无法同时显示）。

### 方案 1：统一为 EditBuffer

**核心思路**：DraftManager 和 SaveTracker 都不需要作为独立组件存在。用单一的 per-atom `EditBuffer` 取代两者。

S2 提取的意图是**移交所有权**（从 coordinator 到 workbench 级），不是**复制实现结构**。移出后可以（也应该）用更好的抽象重新组织。

```
EditBuffer (per-atom, 自包含)
├── atomId: AtomId
├── _phase: BufferPhase              ← loading | ready | disposing（状态机）
├── content: String                  ← 当前内容（loading 期间为空，但 UI 不显示）
├── lastSavedContent: String         ← 上次保存时的内容
├── _editVersion: int                ← 防陈旧保存
├── _saveFuture: Future?             ← 当前 in-flight
├── _saveQueued: bool                ← 排队重试
├── _debounceTimer: Timer?           ← 本 buffer 的自动保存去抖
├── _errorMessage: String?           ← 保存失败信息
├── _persistFn: Future<bool> Function(String atomId, String content)
│
│ 派生属性（getter，不存储）：
├── isDirty → content != lastSavedContent
├── saveState →
│     _phase == loading     → loading
│     _saveFuture != null   → saving
│     _errorMessage != null → error
│     isDirty                → dirty
│     else                   → clean
│
│ 操作（loading 阶段 edit/save/flush 均为 no-op）：
├── initialize(String loadedContent)  ← 加载完成后调用，phase → ready
├── edit(String newContent)           ← phase != ready → no-op
├── flush() → Future<void>           ← phase != ready → 立即返回
└── dispose()                         ← phase → disposing，取消 timer
```

**消除对照表：**

| 旧结构 | EditBuffer 中 | 消除方式 |
|--------|---|---|
| `_draftContentByAtomId[id]` | `buffer.content` | 对象字段 |
| `_persistedContentByAtomId[id]` | `buffer.lastSavedContent` | 对象字段 |
| `_draftVersionByAtomId[id]` | `buffer._editVersion` | 对象字段 |
| `_saveFutureByAtomId[id]` | `buffer._saveFuture` | 对象字段 |
| `_saveQueuedByAtomId[id]` | `buffer._saveQueued` | 对象字段 |
| SaveTracker 全局状态 | `buffer.saveState` getter | 派生，不存储 |
| SaveTracker badge 计时器 | widget 层动画 | 移出数据模型 |
| coordinator 中的同步代码 | 无 | 自包含，无需同步 |

**"Saved" badge**：saveState 的 `saving → clean` 转换由 widget 层监听并启动 3 秒动画。这是展示逻辑，不属于数据模型。

**聚合查询**：`EditorShellService` 提供计算属性 `bool get hasPendingSaveWork → buffers.values.any((b) => b.saveState != clean)`，用于 `flushPendingSave` 等编排操作。

### 对 S2 原文的修正

S2 Phase 2 步骤 1 原文：

> 提取 `NoteDraftManager → DraftManager`，`NoteSaveTracker → SaveTracker`

修正为：

> 提取 `NoteDraftManager` + `NoteSaveTracker` → 统一为 `EditBuffer`（per-atom）

S2 的 4 条规则全部满足：

| 规则 | 合规性 |
|------|--------|
| 单一状态源 | ✓ 每个 atom 唯一一个 EditBuffer |
| 状态不双写 | ✓ saveState 是 getter，不存储 |
| 泛型 Tab | ✓ EditBuffer 以 AtomId 为 key，不限 note |
| Pane 隔离 | ✓ EditBuffer 是 per-atom，各 pane 读同一个 buffer |

### Undo（Ctrl+Z）兼容性

Undo 由 Flutter `TextEditingController` 内置 undo 栈在 widget 层处理。EditBuffer 只通过 `onChanged` 接收结果内容，undo 和普通编辑对 EditBuffer 无区别。

`isDirty` 采用字符串比较（`content != lastSavedContent`）而非纯版本号，因此 undo 回退到已保存内容时 `isDirty` 正确归 false。`_editVersion` 仅用于防陈旧保存（debounce timer 触发时检查 version 是否仍为调度时的值），不参与 dirty 判定。

### 细化分析

#### 细化 1：EditBuffer 生命周期 — RESOLVED

**当前实现的问题**：

- 创建：`_loadSelectedDetail()` → `_syncPersistedSnapshot()` 向 5 个并行 Map 插入
- 销毁（删除）：`_evictNoteState()` 从 5 个 Map 移除
- 销毁（会话重置）：`_resetSessionForReload()` 全 clear
- 关闭 tab：只从 tab 列表移除，**不清理 draft Map**（状态泄漏）

**状态机设计**（DI-4 Q4 细化4 扩展：增加 `error` 状态）：

```
  loading ──┬──→ ready ──→ disposing
            │                  ↑
            └──→ error ────────┘
                  │
                  └── retry() → 重新触发 _loadSingleBuffer → loading
```

| 阶段 | 允许的操作 | UI 表现 |
|------|-----------|---------|
| `loading` | `initialize(loadedContent)` 或 `markError(e)` | 编辑器显示 loading 占位，不可交互 |
| `ready` | `edit()`, `flush()`, `dispose()` | 编辑器正常交互 |
| `error` | `retry()`（回到 `loading` 重新加载），`dispose()` | 错误占位 + retry 按钮 |
| `disposing` | 无 | buffer 即将销毁 |

> **注**：`error` 状态由 DI-4 Q4 细化4 引入。`AtomNotFoundException` 不进入 `error`（直接移除 tab），仅 FFI 通用异常（DB 锁定、I/O 错误等可恢复故障）使用 `markError()`。

**loading 阶段为什么必须阻止所有变更操作**：

如果允许在 loading 期间编辑或保存，空内容可能被自动保存写入 SQLite，**覆盖原有数据**。
当前实现也有此隐患（`_syncPersistedSnapshot` 依赖 `wasDirty` 判断是否覆盖，而 persisted 为 null 时 `isDirty` 返回 false），
只是因为本地 SQLite 加载极快（< 50ms）未暴露。loading 阶段的显式保护消除了这个隐患。

**创建与加载**（DI-4 Q4 细化3 修正：`loadContentFn` 闭包注入替代 `initializeBuffer` 外部调用）：

```
service.openTab(groupId, atomId, {initialContent?, title?}):
  1. group.tabs.add(TabEntry(atomId, title))
  2. 若 buffers[atomId] 不存在：
     a. 创建 EditBuffer(atomId, phase: loading)
     b. 若 initialContent != null → buffer.initialize(initialContent) → phase = ready
     c. 否则 → _loadSingleBuffer(atomId)（fire-and-forget，内部调用 _loadContentFn 闭包）
  3. 若 buffers[atomId] 已存在（其他 pane 已打开）：
     → 直接复用，无需加载
```

**加载职责**（DI-4 Q4 细化3 裁决）：Service 通过 `_loadContentFn` 闭包加载内容，与 `_persistFn` 保存路径**对称**。Service 控制**何时**加载，Coordinator 提供**怎么**加载（闭包内封装 FFI 调用）。Coordinator 是接线员——构造时注入闭包，不亲自调 FFI 再塞回 Service。这保证了 EditorShellService 的通用性 — 它不知道数据从哪里来（FFI / 网络 / 内存）。

**销毁与引用计数**：

```
service.closeTab(groupId, atomId):
  1. group.tabs.removeWhere((t) => t.atomId == atomId)
  2. 检查：atomId 是否还在任何 group 的 tabs 中？
     - 是 → 不销毁（其他 pane 还在用）
     - 否 → await buffer.flush() → buffer.dispose() → buffers.remove(atomId)
```

引用计数不需要显式 `Map<AtomId, int>`。每次 closeTab 遍历所有 group 检查即可 — group 数量极少（通常 1-3 个），成本可忽略。

**用户视角下的完整场景**：

| 场景 | 用户体验 | buffer 行为 |
|------|---------|------------|
| 点击笔记打开 | tab 出现 → 短暂 loading → 内容可编辑 | 创建 → loading → initialize → ready |
| 编辑 → 自动保存 | dirty 圆点出现 → 1.5s 后自动保存 → "已保存" 徽章 | edit → dirty → debounce → save → clean |
| 关闭 tab（唯一引用） | flush → tab 消失 | flush → dispose → 移除 |
| 关闭 tab（其他 pane 仍有） | tab 消失，其他 pane 不受影响 | 仅 group 更新，buffer 保留 |
| Split 同一笔记 | 两个 pane 显示相同内容和 dirty 状态 | 复用同一 buffer |
| 快速连续点击 A→B→C | 三个 tab 打开，各自独立加载 | 三个独立 buffer，无 stale 问题 |
| flush 失败时关闭 tab | tab 不关闭，显示错误提示 | buffer 保留，saveState = error |
| 会话重置 | 所有 tab 清空 | 所有 buffer dispose + clear |

**与业界对比**：

| 产品 | Buffer 模型 | 关闭行为 | 加载方式 |
|------|------------|---------|---------|
| VS Code | `TextModel` per file, 引用计数 | Save/Don't Save/Cancel 对话框 | 异步，loading 期间不可编辑 |
| IntelliJ | `Document` per file | 自动保存，无对话框 | 异步 |
| Obsidian | Per-file buffer, 自动保存 | 直接关闭 | 异步 |
| **LazyNote** | **EditBuffer per atom, 自动保存** | **flush → 关闭（失败则阻止）** | **异步，loading 阶段阻止变更** |

定位最接近 Obsidian/Notion（自动保存优先），close 行为比 VS Code 更简单（无三选对话框）。

#### 细化 2：edit() 与 save() 完整时序 — RESOLVED

**当前实现**：

```
用户键入 → coordinator.updateActiveDraft(content)
  ├── _draftContentByAtomId[atomId] = content
  ├── version++
  ├── _setSaveState(dirty)           ← SaveTracker 手动同步
  └── _scheduleAutosave(1500ms)
        └── timer → saveDraft(atomId, version)
              ├── 若有 inflight → 标记 queued，返回现有 future
              └── _performSaveDraft()
                    ├── version 陈旧检查
                    ├── _setSaveState(saving)    ← 手动同步
                    ├── FFI: note_update(atomId, content)
                    ├── 成功 → _syncPersistedSnapshot + _setSaveState(clean, badge)
                    └── 失败 → _setSaveState(error)
```

**目标方案**：

```
用户键入 → buffer.edit(content)      ← phase != ready → no-op
  ├── content = newContent, _editVersion++
  ├── isDirty → true (自动), saveState → dirty (自动)
  ├── notifyListeners()
  └── 重启 _debounceTimer(1500ms)
        └── timer → buffer._executeSave()
              ├── 若有 _saveFuture → _saveQueued = true, return
              └── 执行保存
                    ├── version 陈旧检查（当前 version != 调度时 version → abort）
                    ├── _saveFuture = persistFn(atomId, content)
                    ├── saveState → saving (自动，因 _saveFuture != null)
                    ├── notifyListeners()
                    ├── result = await _saveFuture
                    ├── _saveFuture = null
                    ├── 成功：
                    │     lastSavedContent = content
                    │     _errorMessage = null
                    │     saveState → clean (自动)
                    │     notifyListeners()
                    │     _onSaved?.call(atomId, content)    ← 通知外部缓存更新
                    └── 失败：
                          _errorMessage = error.toString()
                          saveState → error (自动)
                          notifyListeners()
              └── whenComplete:
                    若 _saveQueued → _saveQueued = false → 重新调度 _executeSave()
```

**关键简化**：所有 `_setSaveState()` 手动调用消失，状态从字段自然派生。

**回调注入**：EditBuffer 构造时接收两个回调：
- `_persistFn: Future<bool> Function(String atomId, String content)` — 执行 FFI 保存
- `_onSaved: void Function(String atomId, String content)?` — 保存成功后通知外部（如 NoteListManager 缓存更新）

#### 细化 3：与 Coordinator 的交互边界 — RESOLVED

**Coordinator 的本质角色：中介者（Mediator）**

Coordinator 是 notes feature 的中介者，负责协调多个子系统之间的通信。提取 EditorShellService 后，它从"拥有全部状态"变为"编排各方协作"。这与 VS Code 的 `EditorService`（编辑器状态管理）+ `WorkbenchContribution`（feature 级编排）分层一致。

**七项职责归属划分**：

| # | 职责 | 归属 | 理由 |
|---|------|------|------|
| 1 | Tab 状态（open/close/active） | → EditorShellService (EditorGroupModel) | per-pane 视觉状态，跨 feature 通用 |
| 2 | Draft 内容管理 | → EditorShellService (EditBuffer) | per-atom 编辑状态，跨 feature 通用 |
| 3 | Save 状态 + 自动保存 | → EditorShellService (EditBuffer) | 与 draft 不可分割，一体化 |
| 4 | 笔记详情加载（selectedNote / detailLoading） | **保留** Coordinator | feature-level DTO（含 tags、metadata）|
| 5 | 笔记列表查询 + 缓存 | **保留** Coordinator (NoteListManager) | feature-specific 数据查询 |
| 6 | Tag 管理 | **保留** Coordinator (NoteTagManager) | feature-specific 业务逻辑 |
| 7 | 创建/删除等多方编排 | **保留** Coordinator | 涉及 FFI + list + tab + tag 多方协调 |

**三种通信模式**：

| 方向 | 机制 | 说明 |
|------|------|------|
| Coordinator → Service | 直接方法调用 | `service.openTab()`, `service.flushBuffer()`, `service.closeTab()` |
| Service → FFI（加载） | 闭包（Coordinator 注入的 `loadContentFn`） | Service 内部调用 `_loadContentFn(atomId)`，不知道 FFI 的存在（DI-4 Q4 细化3） |
| Service → FFI（保存） | 闭包（Coordinator 注入的 `persistFn`） | EditBuffer 调用 `_persistFn(atomId, content)`，不知道 FFI 的存在 |
| Service → Coordinator | 回调（`onBufferSaved`） | 保存成功后通知外部更新缓存 |

**双闭包注入模式（关键设计，DI-4 Q4 细化3 扩展）**：

Coordinator 在构造 Service 时注入 `loadContentFn` + `persistFn` 双闭包，加载和保存路径对称。以下为 `persistFn` 闭包示例（`loadContentFn` 见 DI-4 Q4 细化3）：

```
persistFn = (atomId, content) async {
  final response = await noteUpdateInvoker(atomId, content);   // FFI 调用
  if (response.success) {
    noteListManager.upsertNote(response.noteItem);              // 缓存更新（S8 后为 response.atomListItem）
    return true;
  }
  return false;
};
```

EditBuffer 只看到 `Future<bool> Function(String atomId, String content)` — 不知道 NoteItem、NoteListManager 或 FFI 的存在。这保证了 EditorShellService 完全通用，不依赖 notes feature 的任何类型。

**onBufferSaved 回调**：

保存成功后 EditBuffer 调用 `_onSaved(atomId, content)`，Coordinator 在此回调中：
- 更新 `selectedNote`（如果是当前查看的笔记）的 preview 等字段
- 触发 `notifyListeners()` 刷新详情面板 UI

**五个核心场景的数据流**：

**场景 1：用户点击笔记打开**（DI-4 Q4 细化3 修正：loadContentFn 替代 initializeBuffer）

```
Coordinator.selectNote(atomId):
  1. detailLoading = true, notifyListeners()
  2. FFI note_get(atomId) → NoteItem {content, tags, preview, ...}
  3. selectedNote = noteItem                            ← metadata 留在 coordinator
  4. service.openTab(activeGroupId, atomId, title: noteItem.title)
     → 创建 EditBuffer(phase: loading)
     → 加入 group.tabs
     → 内部触发 _loadContentFn(atomId) → buffer.initialize(content) → phase = ready
  5. detailLoading = false, notifyListeners()
```

关键：Coordinator 调 FFI 获取 metadata（tags、preview 等 feature-level 数据），content 加载由 Service 通过 `_loadContentFn` 闭包自主完成。Coordinator 在构造 Service 时注入闭包，不亲自调 FFI 再塞回 Service（DI-4 Q4 细化3 "接线员原则"）。

**场景 2：用户编辑内容**

```
NoteEditor widget → buffer.edit(newContent)
  → EditBuffer 内部自治完成：
     debounce 1.5s → _executeSave()
     → _persistFn(atomId, content)       ← 闭包内: FFI + cache update
     → _onSaved(atomId, content)         ← 通知 coordinator 刷新
```

Coordinator 不参与编辑-保存循环。整个流程在 EditBuffer 内部闭环完成。

**场景 3：用户创建新笔记**

```
Coordinator.createNote():
  1. FFI note_create('') → NoteItem {atomId, content, ...}    （S8 后为 AtomListItem）
  2. noteListManager.upsertNote(newNoteItem)                    （S8 后为 newAtomListItem）
  3. service.openTab(activeGroupId, atomId, initialContent: content, title: newNoteItem.title)
     → 创建 EditBuffer → initialContent 已提供 → 跳过 loading → 直接 ready
  4. tag apply（如需）
```

新建笔记内容已知，通过 `initialContent` 参数跳过 loading 阶段。

**场景 4：保存冲刷（flushPendingSave）**

```
Coordinator.flushPendingSave(atomId):
  1. await noteTagManager.waitForAtomTagMutations(atomId)  ← tag 必须先完成
  2. await service.flushBuffer(atomId)                      ← 然后 flush 内容
```

tag-before-buffer 顺序不可逆 — tag mutation 可能影响保存结果的一致性。

**场景 5：关闭 tab**

```
service.closeTab(groupId, atomId):
  1. group.tabs.removeWhere((t) => t.atomId == atomId)
  2. atomId 还在其他 group 的 tabs 中？→ 是：保留 buffer
  3. 否 → await buffer.flush() → buffer.dispose() → buffers.remove(atomId)
```

Service 自治完成，不需要 Coordinator 参与。

**`selectedNote` / `detailLoading` 不迁移的理由**：

`selectedNote` 是 `NoteItem` DTO（包含 tags、preview_text、preview_image 等 EditBuffer 不关心的字段）。它是 notes feature 的 detail panel 数据源，不是编辑器状态。将其放入 EditorShellService 会让通用 service 依赖 notes feature 的 DTO 类型，违反泛型原则。

#### 细化 4：多 Pane 并发编辑同一 Buffer — 边界确认，详见 DI-4

**场景**：同一笔记在 Pane A 和 Pane B 同时打开，两个 NoteEditor widget 各有独立 `TextEditingController`。

**DI-1 层面确认的原则**：

- EditBuffer 是单一真相源，per-atom，跨 pane 共享
- EditBuffer 为 ChangeNotifier，内容变化时 `notifyListeners()`
- 每个 pane 的编辑器 widget 监听 buffer 变化，rebuild 时更新 TextEditingController
- 光标各 pane 独立（DI-5 范畴）

**需要在 DI-4 解决的问题**：

编辑中的 pane 触发 `buffer.edit()` → `notifyListeners()` → **自身也会 rebuild** → 可能导致光标跳动或循环。
需要区分"本地编辑"（不需要更新自身 TextEditingController）和"远程同步"（需要更新其他 pane 的 TextEditingController）。
具体机制（如 edit source tag、widget-level guard）属于 DI-4 Buffer 同步模型的范畴。

---

## Q4: Coordinator 残留职责（D3） — 部分由 Q3 细化3 覆盖

### Q3 细化3 已裁决的部分（直接沿用）

以下结论在 Q3 细化3 中已通过交互讨论确定，此处不再重复论证：

- **七项职责归属表**：3 迁移（tab / draft / save → EditorShellService）+ 4 保留
- **`selectedNote` / `detailLoading`** 保留在 coordinator — feature-level DTO，不迁移
- **`flushPendingSave`** 编排模式 — tag-before-buffer 顺序
- **`createNote` / `selectNote`** 数据流 — coordinator 做 FFI 调用，拆分结果
- **persistFn / onBufferSaved** 通信模式 — 闭包注入 + 回调通知

### 增量裁决点

#### 细化 1：Tab 标题机制 — RESOLVED

**S1 R8 裁决已回答此问题**（`08b-semantic-decisions.md` R8）：

> 新增 `title: String` 字段，存储在 Atom 上，永远非空，永远是纯文本。
> **title 是"这个东西叫什么"** — Tab 栏、Explorer、Task 列表、Calendar **全部读同一个字段**。

**裁决**：Tab 显示 `atom.title`，不使用独立的 displayName 概念。

**当前实现的问题**：四个视图各自用不同逻辑推导"名字"（S1 R8 原文），Flutter 端 `_titleFromContent()` 是其中之一。S1 R8 将推导逻辑下沉到 Rust Core（`note_create` / `note_update` 时自动推导并写入 `title` 字段），Flutter 端 `_titleFromContent()` **废弃**。

**Tab 标题数据流**：

```
FFI note_create / note_get → AtomListItem.title
  → coordinator 传入 service: openTab(..., title: atom.title)
FFI note_update (save) → 新的 AtomListItem.title
  → coordinator 在 onBufferSaved 中调: service.updateTabTitle(atomId, newTitle)
```

**`atom.title` 与 `display_name` 的关系**：

| 概念 | 层级 | 语义 | Tab 是否使用 |
|------|------|------|-------------|
| `atom.title` | Atom 身份层 | "这个东西叫什么" — 对 markdown 永远 = content 第一行推导 | **是** |
| `display_name` | workspace_node 节点层 | "这个引用在这个位置叫什么" — 用户手动设置的别名 | **否** |

**Tab 不跟 display_name 同步的理由**：

1. **维度不匹配**：Tab 是 per-atom 的（一个 Atom 一个 tab），display_name 是 per-ref 的（同一 Atom 可有多个 atom_ref，各有不同 display_name）。若 Tab 跟 display_name 走，多引用场景下无法自洽
2. **S1 R8 明确定义**：Tab 栏消费规则 = `atom.title`
3. **默认情况无困惑**：display_name 未设置（大多数情况）时，Explorer 也显示 atom.title → 与 Tab 自然一致
4. **display_name 设置后的残余困惑**：用户在 Explorer 看到别名 "Q1会议纪要" 但 Tab 显示本名 "Meeting Notes" — 可通过 UI 层缓解手段解决（见 `ideas/tab-explorer-name-consistency.md`）

**EditorGroupModel 对应调整**：

```
TabEntry { atomId: String, title: String }
EditorGroupModel.tabs: List<TabEntry>    ← 替代原 openNoteIds: List<String>
```

**新增 API**：

```
openTab(groupId, atomId, {initialContent?, title?})
service.updateTabTitle(atomId, newTitle)
```

#### 细化 2：Coordinator 提取后的结构定义 — RESOLVED

**问题**：提取 3 个 manager + 大量胶水代码后，coordinator 的身份和结构是什么？

**提取前后对比**：

| 维度 | 提取前 | 提取后 |
|------|--------|--------|
| 身份 | God object（拥有全部笔记状态） | Feature controller（数据查询 + 视图状态 + 编排） |
| 管理的 manager | 6 个 | 2 个（NoteListManager, NoteTagManager）— WorkspaceTreeManager 独立提取，见细化 3 |
| 直接状态 | tab + draft + save + selected + tag | selected + tag（仅 feature 视图状态） |
| 胶水代码 | ~400 行（5 个并行 Map 同步、_setSaveState 等） | ~0 行（EditBuffer 自包含，无需手动同步） |
| 估计代码量 | ~1400 行 | ~300-500 行 |

**提取后的 coordinator 结构**：

```
NotesCoordinator (feature controller, ChangeNotifier)
├── 数据管理器
│   ├── NoteListManager      — 列表查询 + 缓存 + upsertNote
│   └── NoteTagManager       — tag CRUD + 变更队列 + waitForMutations
├── 视图状态
│   ├── selectedNote: NoteItem?     — 当前详情 DTO
│   ├── detailLoading: bool         — 详情加载中
│   └── selectedTag: String?        — 列表过滤条件
├── 编排方法
│   ├── selectNote(atomId)          — FFI + openTab + initializeBuffer
│   ├── createNote()                — FFI + list upsert + openTab
│   └── flushPendingSave(atomId)    — tag wait + flushBuffer
├── 回调桥接（注入给 EditorShellService）
│   ├── persistFn                   — FFI note_update + cache upsert
│   └── onBufferSaved              — 刷新 selectedNote + notifyListeners
├── editorShellService → 注入引用
└── workspaceTreeService → 注入引用（独立 service，见细化 3）
```

**`selectedTag` 归属确认**：保留在 coordinator。`selectedTag` 是 NoteListManager 的列表过滤条件，纯 feature-level 视图状态，与编辑器无关。

**Coordinator 作为单一类保留的理由**：
- 它是中介者 — 需要同时访问 NoteListManager + NoteTagManager + EditorShellService
- 编排方法需要跨 manager 协调（createNote 涉及 list + tag + service 三方）
- 它是 UI widget 监听的 ChangeNotifier — 拆分会增加 widget 层复杂度
- 提取后 ~300-500 行是合理的单文件大小，无需进一步拆分

#### 细化 3：WorkspaceTreeManager 独立提取 — RESOLVED

**语义裁决依据**：

- **S1 R6**（指定默认路径模型）：workspace tree 管理所有类型 Atom 的 atom_ref — Tasks 视图创建 → atom_ref 落入 Tasks 指定文件夹，Calendar 视图创建 → atom_ref 落入 Calendar 指定文件夹。workspace tree 是**跨 feature 的组织基础设施**，不是 notes 的内部组件
- **S3**（Tag × Workspace Tree 正交性）：workspace tree 是独立的"结构归档"维度，与任何单一 feature 无关

**裁决**：v0.3 提取 WorkspaceTreeManager 为独立 service。**结构先行，功能可后移。**

**提取路径**：

| 项目 | 内容 |
|------|------|
| 来源 | `lib/features/notes/managers/workspace_tree_manager.dart` |
| 目标 | `lib/core/workspace/workspace_tree_service.dart`（按 S7 先例放入 `core/`） |
| 性质 | 跨 feature 基础设施，与 EditorShellService 平级 |
| 消费者 | NotesCoordinator（注入引用）、未来 TasksController / CalendarController |
| 工作量 | 低 — WorkspaceTreeManager 已是独立 manager 类，FFI invoker 已注入。主要工作是搬位置 + 调整注入关系 |

**与 EditorShellService 提取的对比**：

| 维度 | EditorShellService | WorkspaceTreeService |
|------|-------------------|---------------------|
| 设计复杂度 | 高（EditBuffer 状态机、persistFn 闭包、多 pane 同步） | 低（直接 FFI CRUD 封装） |
| 接口重设计 | 是（统一 DraftManager + SaveTracker → EditBuffer） | 否（现有接口基本可用） |
| 代码量变化 | 大（新建 ~600 行） | 小（搬移 ~500 行，接口微调） |

**提取后的文件结构**：

```
lib/core/workspace/
├── workspace_tree_service.dart    ← 从 notes/managers/ 搬入
└── workspace_models.dart          ← 已存在于 features/workspace/（需一并迁移）
```

---

## Q5: 文件位置 — RESOLVED

### 裁决

**`lib/core/editor/`**

### 分析

**排除 `lib/features/`**：EditorShellService 被 NotesCoordinator 引用，未来也被 TasksController、CalendarController 引用。放在任何 feature 下都违反 Rule E。

**`lib/shared/` vs `lib/core/`**：

| 目录 | 定位 | 已有居民 |
|------|------|---------|
| `lib/core/` | 平台/系统基础设施 | RustBridge、Settings、Reminders、Bindings |
| `lib/shared/` | 跨 feature UI 原语 | ui_tokens.dart、tag_filter.dart |

EditorShellService 管理编辑器状态机（EditBuffer 生命周期、Tab 模型、pane 布局），是应用的 workbench 骨架，不是 UI 原语。按 S7 先例（Reminders 从 `features/` → `core/`，理由："平台基础设施，与 RustBridge、LocalSettingsStore 同级"），EditorShellService 归入 `core/`。

### 文件结构

```
lib/core/editor/
├── editor_shell_service.dart     ← 主 service（singleton）
├── editor_group_model.dart       ← EditorGroupModel + TabEntry
├── edit_buffer.dart              ← EditBuffer（per-atom 状态机）
├── group_layout.dart             ← GroupLayout（递归布局树，从 WorkspaceProvider 迁入）
├── layout_persistence.dart       ← 布局文件 I/O + 去抖 + atomic write（DI-3）
└── editor_resolver.dart          ← content_type → EditorPane（DI-10）
```

与其他 `core/` 模块形成对称：

```
lib/core/
├── editor/                       ← EditorShellService（编辑器基础设施）
├── workspace/                    ← WorkspaceTreeService（组织结构基础设施）
├── reminders/                    ← ReminderScheduler（通知基础设施）
├── settings/                     ← LocalSettingsStore（配置基础设施）
└── ...
```

---

## 整体架构图（方案）

```
EditorShellService (singleton, lib/core/editor/)
├── _loadContentFn (注入: FFI 加载回调，DI-4 Q4 细化3)
├── _persistFn (注入: FFI 保存回调)
├── groups: Map<GroupId, EditorGroupModel>
│   └── EditorGroupModel (per-pane)
│       ├── tabs: List<TabEntry>        ← TabEntry { atomId, title }
│       ├── activeAtomId: String?
│       └── previewTabId: String?
├── activeGroupId: String
├── buffers: Map<AtomId, EditBuffer> (per-atom, 统一 draft+save)
│   └── EditBuffer (ChangeNotifier)
│       ├── _phase: loading | ready | error | disposing（DI-4 Q4 细化4 扩展）
│       ├── content / lastSavedContent
│       ├── _rev: int（DI-4 Q1 补充，统一 _editVersion）
│       ├── saveState (getter: loading/clean/dirty/saving/error)
│       ├── _onSaved (注入: 保存成功通知回调)
│       ├── initialize() / edit({EditOp? op}) / flush() / dispose() / markError() / retry()
│       └── loading/error 阶段: edit/save/flush 均为 no-op
├── layout: GroupLayout (递归树，原 WorkspaceProvider)
│
├── openTab(groupId, atomId, {initialContent?, title?})
├── updateTabTitle(atomId, newTitle)
├── closeTab(groupId, atomId)
├── switchTab(groupId, atomId)
├── flushBuffer(atomId) / flushAllDirtyBuffers()
└── hasPendingSaveWork (getter)

WorkspaceTreeService (singleton, lib/core/workspace/)  ← 从 notes coordinator 独立提取
├── workspace tree CRUD (FFI 封装)
├── 消费者: NotesCoordinator, 未来 TasksController / CalendarController

NotesCoordinator (feature controller, lib/features/notes/)
├── NoteListManager      ← 监听 buffer._onSaved 更新列表缓存
├── NoteTagManager
├── selectedNote / detailLoading  ← 保留在 coordinator（feature-level 详情 DTO）
├── selectedTag                   ← 列表过滤条件
├── editorShellService → 注入引用
├── workspaceTreeService → 注入引用
└── 编排方法: createNote(), selectNote(), flushPendingSave()
```

---

## 关联

- ← DI-0（D4 已 RESOLVED：提取源 = `NoteTabStateManager` → `EditorGroupModel`）
- ← S2 裁决（`docs/architecture/rulings/S2-tab-draft-save-ownership.md`）
- ← S1 R8（Q4 细化1：Tab 显示 `atom.title`）
- ← S1 R6 + S3（Q4 细化3：WorkspaceTreeManager 独立提取依据）
- → DI-4（Buffer 同步模型依赖 D2 状态归属结论）
- → DI-5（光标/冲突依赖 D1 结论）
- ← 01 审计报告 §4.1

---

*前序议题：[DI-0 双版本 NoteTabManager](DI-0-dual-tab-manager.md)（RESOLVED）*
*下一个议题：[DI-2 布局树节点结构](DI-2-layout-tree-structure.md)*

---

## 实施关联 `[PR-RB-06 新增]`

Q1~Q5 全部裁决由 PR-RB-06 实施。EditorShellService + EditorGroupModel + EditBuffer 首次落地。

See: `docs/releases/v0.3/prs/PR-RB-06-core-editor-foundation.md`
