# report

WorkspaceProvider 是什么
workspace_provider.dart 是一个 665 行的 ChangeNotifier，它是 v0.2 “分屏编辑器”功能的运行时状态中心。它管理：

1. 多 Pane 布局状态

┌─────────────┬─────────────┐
│ Pane A │ Pane B │ ← splitActivePane() 创建
│ (note-1) │ (note-3) │ ← closeActivePane() 合并
│ (note-2) │ │
└─────────────┴─────────────┘
_layoutState: pane 排列顺序、各 pane 宽度比例、分割方向
_activePaneId: 当前焦点所在的 pane
splitActivePane() / closeActivePane(): 分屏/合屏操作
2. 每 Pane 的 Tab 状态
_openTabsByPane: 每个 pane 里打开了哪些 note tab
_activeTabByPane: 每个 pane 当前激活的 tab
openNote() / activateNote() / closeNote(): tab 的增删切换
3. 每 Note 的编辑缓冲区
_buffersByNoteId: 每个打开的 note 的 WorkspaceNoteBuffer（persisted content + draft content + version）
_saveStateByNoteId: clean / dirty / saving / saveError
updateDraft(): 更新草稿 → 标记 dirty → 触发 autosave
flushNote(): 立即持久化（带重试）
4. Autosave 管线
_saveDebounceByNoteId: 每个 note 的防抖 timer
_saveInFlightByNoteId: 正在飞行中的保存 Future
_saveDraftVersion(): 实际调用 FFI 保存
一句话总结：WorkspaceProvider 是”编辑器运行时”——它知道你开了几个窗格、每个窗格里有哪些 tab、每个 tab 的草稿内容和保存状态。

历史背景：为什么会有两套状态
PR-0252 之前，架构是这样的：

NotesController (3,160 行, 已删除)
├── 管 note 列表
├── 管 tag 过滤
├── 管 tab 开关
├── 管 draft 内容
└── 管 autosave

WorkspaceProvider (665 行, 仍存在)
├── 管 pane 分屏布局
├── 管 per-pane tab 列表
├── 管 per-note buffer
└── 管 per-note autosave
两者有 大量职责重叠：tab 状态、draft 内容、保存状态——NotesController 和 WorkspaceProvider 各管一份。这是因为：

NotesController 先出现（v0.1），管单 pane 的 note 列表 + 编辑
WorkspaceProvider 后出现（v0.2），为支持多 pane 分屏而新建
两者没有合并，而是用 同步桥 让 NotesController 的状态投影到 WorkspaceProvider
PR-0252 把 NotesController 拆成了 NotesCoordinator + 6 个 manager，但 没有消除这个双状态问题——WorkspaceProvider 和 coordinator 仍然各管一套 tab/draft/save 状态，靠桥同步。

WP Bridge 是什么
“WP bridge”（WorkspaceProvider bridge）是 notes_coordinator_impl.dart 里约 260 行的代码，它的唯一职责是：把 coordinator 内部的 tab/draft/save 状态同步到 WorkspaceProvider 上。

核心方法
_syncWorkspaceFromControllerState()（L1509–L1577, ~70 行）：

每当 coordinator 状态变化时调用，执行：

读取 WorkspaceProvider 当前的 pane 布局
resetAll() 清空 WorkspaceProvider 全部 tab/buffer
遍历 coordinator 的 openNoteIds，逐个调用 syncExternalNote() 把 coordinator 的状态推送过去
用 beginBatchSync() / endBatchSync() 包裹，避免中间状态触发 UI 重绘
_syncWorkspaceActiveSnapshot()（L1495–L1507）：

仅同步当前激活 note 的 draft/save 状态到 WorkspaceProvider。

_WorkspaceProviderPort（L1608–L1692, ~85 行）：

一个 adapter 类，实现 WorkspacePort 接口，把 coordinator 对 workspace 的调用（用 string 类型的 saveState）翻译成 WorkspaceProvider 的 enum 类型。

辅助方法（~100 行）：

_mapSaveStateToWorkspace() — NoteSaveState → WorkspaceSaveState
_workspaceSaveStateForNote() — 查询某个 note 的 save 状态
_workspacePersistedContentFor() / _workspaceDraftContentFor() — 查询内容
数据流示意

用户编辑 note
│
▼
NotesCoordinator.updateActiveDraft(content)
│
├──► NoteDraftManager: 更新 draftContent (真正的状态源)
├──► NoteSaveTracker: 标记 dirty, 调度 autosave
│
└──► _syncWorkspaceFromControllerState() ◄── 这就是 WP Bridge
│
▼
WorkspaceProvider.syncExternalNote(…)
│
▼
NotesPage 的 AnimatedBuilder(animation: workspaceProvider)
│
▼
UI 重绘（显示分屏布局、tab 高亮、保存状态图标）
问题在于：coordinator 的 6 个 manager 已经是 tab/draft/save 的真正状态源（source of truth），但 UI 层（NotesPage）仍然读的是 WorkspaceProvider。所以每次 coordinator 状态变化，都要通过 bridge 把状态”抄”一份到 WorkspaceProvider，WorkspaceProvider 发出 notifyListeners()，UI 才能看到。

谁在消费 WorkspaceProvider
消费方 读什么 位置
app.dart workspaceProvider 作为 SectionRegistry 的 listenable L58, L71
notes_page.dart layoutState.paneOrder 决定渲染几个 pane L378
notes_page.dart openTabsByPane / activeTabByPane 渲染每个 pane 的 tab 栏 L409, L438
notes_page.dart splitActivePane() / closeActivePane() 分屏操作 L309, L351
notes_page.dart maxPaneCount / minPaneExtent 静态常量 L327, L337
注意 note_content_area.dart 已经 不直接使用 WorkspaceProvider——它通过 coordinator 的 getter 获取 draft content。

为什么 v0.3 应该删除 Bridge 而不是提取
当前的架构问题不是”bridge 代码放在哪里”，而是”存在两套重复的 tab/draft/save 状态”：

```
              ┌────────────────────┐
              │ NotesCoordinator   │
              状态源 A ──────► │ NoteTabManager │ tab 状态
							│ NoteDraftManager │ draft 状态
							│ NoteSaveTracker │ save 状态
							└────────┬───────────┘
							│ WP Bridge（同步抄写）
							┌────────▼───────────┐
							│ WorkspaceProvider │
							状态副本 B ────► │ _openTabsByPane │ tab 状态（副本）
							│ _buffersByNoteId │ draft 状态（副本）
							│ _saveStateByNoteId│ save 状态（副本）
							└────────┬───────────┘
							│ notifyListeners()
							┌────────▼───────────┐
							│ NotesPage UI │
							└────────────────────┘
```

正确的 v0.3 做法是：

```
              ┌────────────────────┐
              │ NotesCoordinator   │
              唯一状态源 ────► │ NoteTabManager │ tab 状态
							│ NoteDraftManager │ draft 状态
							│ NoteSaveTracker │ save 状态
							│ (pane layout) │ ← 从 WP 合并进来
							└────────┬───────────┘
							│ notifyListeners()（直接）
							┌────────▼───────────┐
							│ NotesPage UI │
							└────────────────────┘
```

```
              WorkspaceProvider → 删除或仅保留 pane 布局常量
              WP Bridge → 删除（无需同步，因为只有一套状态）
```

这就是报告里说的”减法优于提取”——不是把 bridge 代码挪到新文件，而是让它没有存在的必要。