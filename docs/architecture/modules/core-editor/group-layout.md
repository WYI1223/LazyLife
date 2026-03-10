# Module Spec: GroupLayout

> `lib/core/editor/group_layout.dart`
>
> 设计来源：[DI-2 D5/D6](../../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md) · [DI-1 Q1/Q2](../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md) · [DI-3](../../../reports/v0.3/design-discussions/DI-3-layout-persistence.md) · [S2 Phase 2](../../rulings-legacy/S2-tab-draft-save-ownership.md)

---

## 职责

递归 pane 分割布局树。管理 pane 排列方式（水平/垂直混合嵌套分割）和空间分配比例。从 `WorkspaceProvider`（扁平列表模型）迁入并升级为 DI-2 D5 裁决的二叉树不可变模型。

---

## 数据结构 `[PR-RB-06 更新：从多子节点模型修正为 DI-2 D5 二叉树模型]`

```dart
sealed class LayoutNode {
  const LayoutNode();
}

@immutable
class SplitNode extends LayoutNode {
  const SplitNode({
    required this.first,
    required this.second,
    required this.axis,
    required this.fraction,
  });
  final LayoutNode first;      // 占 fraction 份额
  final LayoutNode second;     // 占 1 - fraction 份额
  final Axis axis;             // Axis.horizontal | Axis.vertical
  final double fraction;       // ∈ (0.0, 1.0)，不含边界
}

@immutable
class LeafNode extends LayoutNode {
  const LeafNode({required this.groupId});
  final String groupId;        // 对应 EditorGroupModel 的 key
}
```

### 封装层

```dart
@immutable
class GroupLayout {
  const GroupLayout({required this.root});
  final LayoutNode root;

  // 结构变更 → 返回新 GroupLayout（不可变 rebuild）
  (GroupLayout, String newGroupId) split(String groupId, Axis axis);
  GroupLayout closeGroup(String groupId);
  GroupLayout resizeAt(List<int> path, double newFraction);

  // 查询
  LayoutResolveResult resolve(Size containerSize);
  Set<String> get allGroupIds;
  bool canSplit(String groupId, Axis axis, Size containerSize);

  // 序列化（PR-RB-07 DI-3 前向兼容）
  Map<String, dynamic> toJson();
  static GroupLayout fromJson(Map<String, dynamic> json);
}

class LayoutResolveResult {
  final Map<String, Rect> leafRects;    // 每个 pane 的位置
  final List<DividerInfo> dividers;     // 每条分隔线的位置 + 对应 SplitNode 的树路径
}
```

---

## 树不变式（I1-I7）`[PR-RB-06 更新]`

| # | 不变式 | 强制方式 |
|---|--------|---------|
| I1 | **二叉**：SplitNode 恰好有 2 个子节点 | 类型系统（sealed class `first`/`second` 结构保证） |
| I2 | **Leaf ID 唯一**：LeafNode.groupId 全树唯一 | split/close 操作时检查 |
| I3 | **Fraction 有界**：fraction ∈ (0.0, 1.0)，不含边界 | SplitNode 构造函数 assert |
| I4 | **最小尺寸**：给定容器 Size，每个 leaf 的 resolved Rect ≥ 200×200 | 操作提交前 resolve + 验证 |
| I5 | **非空**：树至少有 1 个节点 | GroupLayout 保证 root 非 null |
| I6 | **双射**：leaf groupId 集合 = EditorShellService.groups key 集合 | service 级操作保证（split 同时创建 group + leaf，close 同时销毁） |
| I7 | **无重复兄弟**：SplitNode 的两个子 Leaf 不可有相同 groupId | split 操作生成新 groupId |

---

## 关键操作 `[PR-RB-06 更新：不可变 rebuild 模型]`

### Split

```
1. 在树中递归找到 groupId 对应的 LeafNode
2. 替换为 SplitNode(first: 原 LeafNode, second: 新 LeafNode(newGroupId), axis, fraction: 0.5)
3. 返回新 GroupLayout + newGroupId
4. 调用方（EditorShellService）负责创建新 EditorGroupModel 并同步 activeTab
```

**示例**：

```
初始:      LeafNode("g1")

Split("g1", horizontal):
           SplitNode(axis: H, fraction: 0.5)
           ├── LeafNode("g1")
           └── LeafNode("g2")    ← 新 group

再 Split("g2", vertical):
           SplitNode(axis: H, fraction: 0.5)
           ├── LeafNode("g1")
           └── SplitNode(axis: V, fraction: 0.5)
               ├── LeafNode("g2")
               └── LeafNode("g3")  ← 新 group
```

### Close

```
1. 在树中递归找到 groupId 对应的 LeafNode
2. 将该 LeafNode 的父 SplitNode 替换为兄弟节点（坍缩）
3. 返回新 GroupLayout
4. 调用方（EditorShellService）负责销毁对应 EditorGroupModel
```

**示例**（关闭 g3）：

```
关闭前:    SplitNode(axis: H, fraction: 0.5)
           ├── LeafNode("g1")
           └── SplitNode(axis: V, fraction: 0.5)
               ├── LeafNode("g2")
               └── LeafNode("g3")  ← 关闭

关闭后:    SplitNode(axis: H, fraction: 0.5)
           ├── LeafNode("g1")
           └── LeafNode("g2")     ← 父 SplitNode 坍缩为兄弟
```

Note: 实际 pane 关闭由 closeTab() 清空 tabs 列表驱动（`groups.length > 1` 时空 group auto-collapse），不是独立用户操作。唯一剩余 group 永远保留（`paneCount >= 1` 不变量）。

### Resize

```
1. 用 List<int> path（如 [0, 1]）定位目标 SplitNode
2. 更新 fraction 值，重建该路径上所有祖先节点
3. 返回新 GroupLayout
```

### Resolve（DI-2 D6：自顶向下）

```
resolve(node, availableRect) → LayoutResolveResult:
  if node is LeafNode:
    leafRects[node.groupId] = availableRect
  if node is SplitNode:
    (firstRect, secondRect) = splitRect(availableRect, node.axis, node.fraction)
    dividers.add(DividerInfo(rect: dividerRect, path: currentPath))
    resolve(node.first, firstRect)
    resolve(node.second, secondRect)
```

单次遍历产出所有 leaf 的 Rect + 分隔线信息。

---

## Pane 限制

- **最大 pane 数: 8**（DI-3 D9）
- **最小 pane 尺寸: 200×200**（resolve 后检查）
- **无显式深度限制** — pane 数量 ≤ 8 自然约束深度（极端 7 层）

```dart
bool canSplit(String groupId, Axis axis, Size containerSize) {
  if (allGroupIds.length >= 8) return false;           // O(1) 拒绝
  final (candidateLayout, _) = split(groupId, axis);   // 试分割
  final result = candidateLayout.resolve(containerSize);
  return result.leafRects.values.every(
    (rect) => rect.width >= 200 && rect.height >= 200,
  );
}
```

---

## 生命周期

| 阶段 | 状态 |
|------|------|
| 启动 | 单个 `LeafNode(_defaultGroupId)` 作为根 |
| Split | 目标 leaf 替换为 SplitNode，新 group 成为 second 子节点 |
| Tab 驱动销毁 | 空 group + `groups.length > 1` → closeGroup() 移除节点（父 SplitNode 坍缩为兄弟） |
| 持久化 | 结构变化后去抖写入 JSON（DI-3，PR-RB-07 实现；PR-RB-06 提供 toJson/fromJson） |

---

## 序列化

由 [LayoutPersistence](layout-persistence.md) 负责（PR-RB-07）。GroupLayout 提供 `toJson()` / `fromJson()`。

序列化范围：树结构 + per-group tab 列表 + activeTab + previewTab + activeGroupId。不序列化 draft 内容和 save 状态。

---

## 约束验证策略

| 场景 | 验证方式 |
|------|---------|
| Split 前 | 构造候选树 → resolve(候选树, containerSize) → 检查所有 Rect ≥ 200×200 |
| Resize 时 | 更新 fraction → resolve(新树, containerSize) → 检查所有 Rect ≥ 200×200 |
| 窗口缩小 | 数据层不处理，UI 层 overflow clip（DI-2 裁决） |

---

## 实施状态 `[PR-RB-06 新增]`

| 阶段 | 状态 | PR |
|------|------|-----|
| 二叉树结构 + resolve + I1-I7 | 已实施 | PR-RB-06（v0.3） |
| toJson/fromJson（前向兼容） | 已实施 | PR-RB-06（v0.3） |
| 文件 I/O + 去抖 + recovery | 已实施 | PR-RB-07（v0.3，DI-3） |

---

## 关联模块

- ← [EditorShellService](editor-shell-service.md) — 拥有 layout 实例
- → [EditorGroupModel](editor-group-model.md) — LeafNode.groupId 引用
- → [LayoutPersistence](layout-persistence.md) — 持久化与恢复（PR-RB-07）
