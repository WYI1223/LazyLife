# Module Spec: EditorShellService

> `lib/core/editor/editor_shell_service.dart`
>
> 设计来源：[S2 Phase 2](../../rulings/S2-tab-draft-save-ownership.md) · [DI-1](../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) · [S9](../../rulings/S9-cross-feature-infrastructure-placement.md)

---

## 职责

Workbench 级 singleton 服务，管理编辑器状态基础设施：

- `EditorGroupModel[]` — per-pane tab 列表与激活状态
- `EditBuffer` — per-atom 编辑缓冲区（跨 pane 共享）
- `GroupLayout` — 递归 pane 布局树

取代 v0.2.5 中分散在 `NotesCoordinator`（NoteTabStateManager / NoteDraftManager / NoteSaveTracker）和 `WorkspaceProvider` 中的状态管理。

---

## 状态字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `groups` | `Map<GroupId, EditorGroupModel>` | Per-pane tab 列表与激活指示器 |
| `activeGroupId` | `String` | 当前焦点 pane |
| `buffers` | `Map<AtomId, EditBuffer>` | Per-atom 内容 + 保存状态 |
| `layout` | `GroupLayout` | 递归 pane 分割树 |
| `_loadContentFn` | `Future<String> Function(AtomId)` | 闭包：如何加载 atom 内容 |
| `_persistFn` | `Future<bool> Function(AtomId, String)` | 闭包：如何持久化 atom 内容 |

---

## 公共 API

```dart
// Tab 操作
openTab(String groupId, String atomId, {String? initialContent, String? title})
closeTab(String groupId, String atomId)
switchTab(String groupId, String atomId)
updateTabTitle(String atomId, String newTitle)

// 保存操作
Future<void> flushBuffer(String atomId)
Future<void> flushAllDirtyBuffers()
bool get hasPendingSaveWork

// 布局操作（委托给 GroupLayout）
splitGroup(String groupId, Axis axis)
closeGroup(String groupId)
resizeAt(List<int> path, double newFraction)

// 查询
EditorGroupModel? get activeGroup
EditBuffer? bufferFor(String atomId)
LayoutResolveResult resolveLayout(Size containerSize)
```

---

## 通信模式

| 方向 | 模式 | 说明 |
|------|------|------|
| Coordinator → Service | 直接方法调用 | `openTab()`, `closeTab()`, `flushBuffer()` 等 |
| Service → FFI | 双闭包注入 | `_loadContentFn` + `_persistFn`，Service 控制 WHEN，Coordinator 提供 HOW |
| Service → Coordinator | 回调 | `onBufferSaved(atomId, content)` — 保存成功后通知 Coordinator 更新缓存 |

**Coordinator 定位**：接线员（wiring mediator），不是执行层。Coordinator 在构造时注入闭包，监听 Service 变化转发给 UI，但不参与加载/保存逻辑。

```dart
// Coordinator 注入示例
service = EditorShellService(
  loadContentFn: (atomId) async {
    final response = await _noteGetInvoker(atomId);
    return response.note!.content;
  },
  persistFn: (atomId, content) async {
    await _noteUpdateInvoker(atomId, content);
  },
);
```

---

## 生命周期

| 事件 | 行为 |
|------|------|
| 启动 | 注入闭包，从 `LayoutPersistence` 恢复布局，创建 primary group |
| openTab | 若 buffer 不存在 → 创建 `EditBuffer`（loading 状态），调用 `_loadContentFn` |
| closeTab | 从 group.tabs 移除；检查引用计数 → 无其他 group 引用 → flush + dispose buffer |
| split | 创建新 group，复制当前 activeTab |
| 退出前 | `flushAllDirtyBuffers()` |

**Buffer 引用计数**：无显式 `Map<AtomId, int>`，closeTab 时遍历所有 groups 检查 atomId 是否仍被引用。O(G×T) 成本可忽略（G≤8, T 通常 <20）。

---

## Coordinator 提取后结构

提取 tab/draft/save 后，NotesCoordinator 保留为 notes feature controller：

| 保留组件 | 职责 |
|---------|------|
| `NoteListManager` | 列表查询 + 缓存 |
| `NoteTagManager` | tag CRUD + 变更队列 |
| `selectedNote` / `detailLoading` | 详情面板 DTO + 加载状态 |
| `selectedTag` | 列表过滤条件 |

---

## 约束

- **单实例**：App 生命周期唯一 singleton
- **不知 FFI**：通过闭包注入隔离，对 FFI 细节无感知
- **泛型 Tab**：Tab 列表接受任意 Atom UUID，不限于 note 类型（S2 规则 3）
- **状态不双写**：禁止两个组件同时维护相同状态的副本（S2 规则 2）

---

## 实施状态 `[PR-RB-06 新增]`

| 阶段 | 状态 | PR |
|------|------|-----|
| Service + groups + buffers + layout 组合 | PR-RB-06 待实施 | PR-RB-06（v0.3） |
| Coordinator 提取（tab/draft/save → Service） | PR-RB-06 待实施 | PR-RB-06（v0.3） |
| 布局持久化集成（LayoutPersistence） | PR-RB-07 待实施 | PR-RB-07（v0.3，DI-3） |
| EditorResolver 集成 | PR-RB-09 待实施 | PR-RB-09（v0.3，DI-10） |

---

## 关联模块

- → [EditBuffer](edit-buffer.md) — per-atom 状态机
- → [EditorGroupModel](editor-group-model.md) — per-pane 视觉状态
- → [GroupLayout](group-layout.md) — 递归布局树
- → [LayoutPersistence](layout-persistence.md) — 布局持久化
- → [EditorResolver](editor-resolver.md) — content_type → EditorPane
