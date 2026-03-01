# Module Spec: EditorGroupModel

> `lib/core/editor/editor_group_model.dart`
>
> 设计来源：[DI-1 Q1/Q2](../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) · [S2 Phase 2](../../rulings/S2-tab-draft-save-ownership.md)

---

## 职责

Per-pane 视觉状态模型：管理一个编辑器窗格的 tab 列表、激活状态和预览 tab。纯逻辑模型，不包含内容或保存状态（这些属于 per-atom 的 EditBuffer）。

---

## 状态字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tabs` | `List<TabEntry>` | 窗格内打开的 tab 列表 |
| `activeAtomId` | `String?` | 窗格当前激活的 tab |
| `previewTabId` | `String?` | 窗格的预览 tab（**per-group**，非全局） |

### TabEntry

```dart
class TabEntry {
  final String atomId;    // Atom UUID
  final String title;     // 显示标题（来自 atom.title，S1 R8）
}
```

`title` 是存储值（非动态推导），Coordinator 在 buffer 保存后调用 `service.updateTabTitle(atomId, newTitle)` 更新。

---

## 与 EditBuffer 的正交关系

| | EditorGroupModel | EditBuffer |
|---|---|---|
| 维度 | Per-pane | Per-atom |
| 内容 | tab 列表、激活状态 | 内容、脏状态、保存状态 |
| 共享 | 每个 pane 独立 | 同一 atom 跨 pane 共享 |

Draft 内容和 save 状态**不属于** EditorGroupModel。

---

## Group 生命周期

| 事件 | 行为 |
|------|------|
| 启动 | 创建 1 个 primary group |
| Split | 创建新 group，复制当前 activeTab |
| 关闭 tab | 从 `group.tabs` 移除 |
| 关闭最后一个 tab（非 primary） | group 自动销毁，布局树节点移除 |
| 关闭最后一个 tab（primary） | group 保留，显示空状态 |
| 切换焦点 | 更新 `EditorShellService.activeGroupId` |

**无独立 "close pane" API** — pane 关闭完全由 tab 生命周期驱动。

---

## 预览 Tab 语义

- v0.2: `previewTabId` 是全局单例（NoteTabStateManager 级别）
- v0.3: **per-group** — 每个 group 有自己的 previewTab
- 预览 tab 行为：单击文件 → 替换当前预览 tab；双击/编辑 → 预览 tab 固化为普通 tab

---

## 约束

- Group 不直接引用 EditBuffer — 通过 `EditorShellService.buffers[atomId]` 间接访问
- TabEntry.title 更新由 Service 推送，Group 不主动查询
- Primary group 永远不被销毁（即使 tab 列表为空）

---

## 关联模块

- ← [EditorShellService](editor-shell-service.md) — 拥有 groups Map
- ← [GroupLayout](group-layout.md) — LeafNode 引用 groupId
- ↔ [EditBuffer](edit-buffer.md) — 引用计数通过遍历所有 group.tabs 确定
