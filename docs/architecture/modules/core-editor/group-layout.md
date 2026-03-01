# Module Spec: GroupLayout

> `lib/core/editor/group_layout.dart`
>
> 设计来源：[DI-1 Q1/Q2](../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) · [DI-3](../../../reports/v0.3/design-discussions/DI-3-layout-persistence.md) · [S2 Phase 2](../../rulings/S2-tab-draft-save-ownership.md)

---

## 职责

递归 pane 分割布局树。管理 pane 排列方式（水平/垂直分割）和空间分配比例。从 `WorkspaceProvider` 迁入。

---

## 数据结构

```dart
sealed class GroupLayoutNode {}

class LeafNode extends GroupLayoutNode {
  final String groupId;   // → EditorGroupModel
}

class SplitNode extends GroupLayoutNode {
  final Axis axis;                       // horizontal | vertical
  final List<GroupLayoutNode> children;  // 通常 2 个子节点
  final List<double> sizes;             // flex 比例（sum = 1.0）
}
```

---

## 树不变式

- LeafNode 引用实际 pane（EditorGroupModel）；SplitNode 是内部分支
- `SplitNode.children.length >= 2`
- `sizes.sum() == 1.0`（归一化）
- groupId 在树中唯一（不重复）
- 无环（单根 DAG）

---

## 关键操作

### Split

```
1. 在树中找到 groupId 对应的 LeafNode
2. 替换为 SplitNode(axis, [LeafNode(groupId), LeafNode(newGroupId)])
3. 新 group 初始化：复制源 group 的 activeTab
4. notifyListeners()
```

### Close

```
1. 在树中找到 groupId 对应的 LeafNode
2. 从父 SplitNode 的 children 移除
3. 若父 SplitNode 仅剩 1 个子节点 → 提升子节点取代 SplitNode
4. notifyListeners()
```

Note: 实际 pane 关闭由 closeTab() 清空 tabs 列表驱动，不是独立操作。

### Resize

```
1. 更新相邻 sibling 的 sizes 比例
2. 标记 dirty → LayoutPersistence 去抖持久化
```

---

## Pane 限制

- **最大 pane 数: 8**（DI-3 D9）
- **最小 pane 尺寸: 200×200**（resolve 后检查）
- **无显式深度限制** — pane 数量 ≤ 8 自然约束深度（极端 7 层）

```dart
bool canSplit(String groupId, Axis axis, Size containerSize) {
  if (allGroupIds.length >= 8) return false;           // O(1) 拒绝
  final candidateTree = split(groupId, axis);          // 试分割
  final result = candidateTree.resolve(containerSize);
  return allLeafs.every((l) => l.width >= 200 && l.height >= 200);
}
```

---

## 生命周期

| 阶段 | 状态 |
|------|------|
| 启动 | 单个 `LeafNode(primary_group_id)` 作为根 |
| Split | 父变为 SplitNode，原 group 成为第一个子节点 |
| Tab 驱动销毁 | 非 primary group 的 tabs 清空 → closeGroup() 移除节点 |
| 持久化 | 结构变化后去抖写入 JSON（DI-3） |

---

## 序列化

由 [LayoutPersistence](layout-persistence.md) 负责。GroupLayout 提供 `toJson()` / `fromJson()`。

序列化范围：树结构 + per-group tab 列表 + activeTab + previewTab + primaryGroupId。不序列化 draft 内容和 save 状态。

---

## 关联模块

- ← [EditorShellService](editor-shell-service.md) — 拥有 layout 实例
- → [EditorGroupModel](editor-group-model.md) — LeafNode.groupId 引用
- → [LayoutPersistence](layout-persistence.md) — 持久化与恢复
