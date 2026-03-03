# DI-2: 递归布局树节点结构 + 约束传播

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** — D5、D6 全部裁决完毕 |
| **关联决策点** | D5、D6 |
| **阻塞 PR** | PR-0301（直接）、PR-0302（间接） |
| **前置依赖** | 无（可与 DI-1 并行） |
| **来源** | 01-design-readiness-audit.md §4.2 |

---

## 问题提取

### 来源 §1 执行摘要

> **递归布局树数据模型未确定**（阻塞 PR-0301/0302 spec）— 当前 `WorkspaceLayoutState` 是有意设计的扁平模型（最多 4 pane），递归二叉树的节点结构、约束传播、序列化格式需从零设计。

### 来源 §2.3 当前布局模型

> ```
> WorkspaceLayoutState（不可变）
> ├── paneOrder: List<String>        — 有序 pane ID 列表
> ├── paneFractions: List<double>    — 每个 pane 的相对尺寸
> └── splitDirection: horizontal/vertical — 仅支持根级方向
> ```
>
> 关键约束：
> - 硬编码最多 4 pane
> - 最小 200px
> - **非递归** — 有意设计为 v0.2 基线验证用

### 来源 §4.2 设计空白详析

> PR-0301 要替换为递归二叉树（kickoff §9.3 L1a），但树的具体设计未定义。

### 设计决策（审计报告原文）

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D5 | 树节点结构 | A: Dart sealed class (Internal/Leaf) / B: 可变树 + ChangeNotifier / C: 不可变 + rebuild | PR-0301 核心实现 |
| D6 | 约束传播 | A: 自顶向下尺寸分配 / B: 自底向上约束求解 / C: Flutter LayoutDelegate | PR-0301 + PR-0302 |

### 审计报告列出的 PR-0301 具体设计问题

> 1. **树节点数据结构**：采用 `sealed class LayoutNode { case Internal(left, right, splitAxis, fraction); case Leaf(paneId); }` 还是其他模型？
> 2. **约束传播**：min 200px 如何在嵌套树上传播？父节点 fraction 变化时子节点如何响应？

---

## 设计方法论

采用**自顶向下推导**：用户视觉状态 → 用户交互 → 约束 → 操作集 → 数据结构。

布局是用户直接可见的功能，因此从用户视角出发推导数据模型，而非从数据结构反推 UI。

---

## 第一层：视觉状态

用户在编辑区看到的所有布局形态：

**单窗格（默认）**：

```
┌──────────────────────────┐
│         Pane A           │
│    [tab1] [tab2]         │
│    ┌──────────────────┐  │
│    │   editor content  │  │
│    └──────────────────┘  │
└──────────────────────────┘
```

**水平二分**：

```
┌─────────────┬────────────┐
│   Pane A    │   Pane B   │
│  [tab1][t2] │  [tab3]    │
│  ┌────────┐ │ ┌────────┐ │
│  │ editor │ │ │ editor │ │
│  └────────┘ │ └────────┘ │
└─────────────┴────────────┘
```

**混合嵌套（v0.2 不支持，v0.3 目标）**：

```
┌─────────────┬────────────┐
│             │   Pane B   │
│   Pane A    ├────────────┤
│             │   Pane C   │
└─────────────┴────────────┘
```

```
┌──────┬──────┬────────────┐
│  A   │  B   │            │
│      │      │     D      │
├──────┴──────┤            │
│      C      │            │
└─────────────┴────────────┘
```

---

## 第二层：用户交互

| # | 交互 | 触发方式 | 视觉效果 |
|---|------|---------|---------|
| 1 | **Split** | 菜单/快捷键（PR-0301）、拖拽（PR-0302） | 当前 pane 一分为二，新 pane 出现 |
| 2 | **Resize** | 拖拽分隔线 | 相邻 pane 的比例变化 |
| 3 | **Close pane** | 关闭最后一个 tab（DI-1 Q2） | pane 消失，空间归还兄弟 |
| 4 | **Switch focus** | 点击 pane | 活跃 pane 指示变化 |

---

## 第三层：约束

### 最小尺寸

任何 pane 在两个轴上均不小于 200px。Split 操作在不满足时被拒绝，Resize 操作在到达阈值时停止。

### Primary pane 不可消失

DI-1 Q2 裁决：关闭 primary group 的最后一个 tab → group 保留，显示空状态。最后一个 atom 可以关闭，最后一个 pane 不消失。

### 窗口缩小 → UI 层 overflow clip

采用 VS Code 方案：编辑器区域有最小尺寸（由当前树结构决定），窗口缩小到阈值以下时，编辑器区域不再缩小，而是被窗口边框裁切。

| 条件 | 行为 |
|------|------|
| 窗口可用区域 ≥ 树最小尺寸 | 正常 resolve，所有 pane 按比例分配 |
| 窗口可用区域 < 树最小尺寸 | 编辑器区域保持最小尺寸，overflow clip |

**关键影响**：布局树引擎（数据层）完全不需要处理"容器不够大"的场景——那是 Flutter widget 层的 `ConstrainedBox` / `OverflowBox` 责任。数据模型保持干净。

---

## 第四层：操作集

从用户交互和约束反推出布局树需要提供的操作。

### 结构变更操作

| # | 操作 | 输入 | 输出 | 触发场景 |
|---|------|------|------|---------|
| O1 | **Split** | 目标 groupId + 分割方向 | 新树 + 新 groupId | 菜单/快捷键/拖拽 |
| O2 | **Close** | 目标 groupId | 新树（目标 leaf 消失，父节点坍缩为兄弟节点） | 关闭最后一个 tab |
| O3 | **Resize** | 目标分隔线（路径寻址）+ 新 fraction | 新树（仅一个 SplitNode 的 fraction 变化） | 拖拽分隔线 |

### 查询操作

| # | 操作 | 输入 | 输出 | 用途 |
|---|------|------|------|------|
| Q1 | **Resolve** | 树 + 容器 Size | `Map<GroupId, Rect>` + 分隔线信息 | Flutter 渲染 + 分隔线交互 |
| Q2 | **CanSplit** | 目标 groupId + 方向 + 容器 Size | bool | Split 前预判 |
| Q3 | **AllGroupIds** | 树 | `Set<GroupId>` | 与 EditorShellService.groups 做双射校验 |

### Resize 的分隔线寻址

用户拖拽的是屏幕上的一条分隔线，数据模型需要定位到对应的 SplitNode。

策略：Q1 Resolve 同时产出分隔线描述信息：

```
resolve(tree, containerSize) → LayoutResolveResult {
  leafRects: Map<GroupId, Rect>,       // 每个 pane 的位置
  dividers: List<DividerInfo>,         // 每条分隔线的位置 + 对应 SplitNode 的树路径
}
```

UI 层渲染分隔线 → 用户拖拽 → 匹配到 `DividerInfo` → 用路径定位 SplitNode → 更新 fraction → rebuild 新树。

SplitNode 不需要分配独立 ID。树最多十几个节点，用树内路径（如 `root → first → second`）定位即可。

### 约束验证策略

| 场景 | 验证方式 |
|------|---------|
| Split 前 | 构造候选树 → resolve(候选树, containerSize) → 检查所有 Rect ≥ 200×200 |
| Resize 时 | 更新 fraction → resolve(新树, containerSize) → 检查所有 Rect ≥ 200×200 |
| 窗口缩小 | 数据层不处理，UI 层 overflow clip |

统一算法：所有验证归结为 `resolve + 检查 leaf Rect`，单一代码路径。

---

## 第五层：数据结构

### D5 裁决：Sealed class + 不可变 rebuild

从操作集推导：

| 需求 | 推导 |
|------|------|
| O1 Split：找到 leaf → 替换为 split + 2 leaf | 按 groupId 遍历找 leaf，替换后生成新树 |
| O2 Close：找到 leaf → 删除 + 坍缩父 split | rebuild 时处理（父节点替换为兄弟节点） |
| O3 Resize：找到特定 SplitNode → 改 fraction | 路径寻址 + rebuild |
| Q1 Resolve：递归分配空间 | 自顶向下遍历，天然需要递归结构 |
| 不可变 rebuild | 每次操作返回新树根，EditorShellService 替换引用并 notify |

**排除 B（可变树 + ChangeNotifier）的理由**：

| 维度 | B: 可变 + ChangeNotifier | A+C: Sealed + 不可变 |
|------|------------------------|---------------------|
| 一致性 | 部分变更可能导致树暂时不一致 | 每次 rebuild 后树始终一致 |
| 测试 | 需要 mock listener、验证副作用 | 纯函数，输入→输出 |
| 序列化（DI-3） | 需遍历可变树，可能与并发变更冲突 | 随时安全序列化（不可变快照） |
| Undo/Redo（未来） | 需深拷贝保存历史状态 | 直接保留旧树引用 |
| 通知模型 | 每个节点发通知，listener 管理复杂 | 单一 owner（EditorShellService）发通知 |
| 代码库惯例 | 不匹配 | ✓ 匹配 — WorkspaceLayoutState 就是不可变 + copyWith |
| 树深度 | 深树 fine-grained 通知有优势 | 深树 rebuild 有 GC 压力 |

**树深度不是问题**：实际使用中 4 pane = 最多 7 节点，8 pane = 最多 15 节点。rebuild 整棵树的开销可忽略。

### 节点定义

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

  // 结构变更 → 返回新 GroupLayout
  (GroupLayout, String newGroupId) split(String groupId, Axis axis);
  GroupLayout closeGroup(String groupId);
  GroupLayout resizeAt(List<int> path, double newFraction);

  // 查询
  LayoutResolveResult resolve(Size containerSize);
  Set<String> get allGroupIds;
  bool canSplit(String groupId, Axis axis, Size containerSize);
}
```

### D6 裁决：自顶向下 resolve

**核心算法**（一次遍历产出所有 leaf 的 Rect + 分隔线信息）：

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

**排除其他选项的理由**：

| 选项 | 适用场景 | 不选原因 |
|------|---------|---------|
| B: 自底向上约束求解 | 窗口缩放时全树校验 | min-size 公式依赖 fraction，复杂度高；窗口缩放已交由 UI 层 clip 处理 |
| C: Flutter LayoutDelegate | 渲染层布局 | 约束验证必须在操作提交前完成（数据层），不能依赖 Flutter build cycle |

---

## 树不变量（Invariants）

| # | 不变量 | 强制方式 |
|---|--------|---------|
| I1 | **二叉**：SplitNode 恰好有 2 个子节点 | 类型系统（sealed class 结构保证） |
| I2 | **Leaf ID 唯一**：LeafNode.groupId 全树唯一 | split/close 操作时检查 |
| I3 | **Fraction 有界**：fraction ∈ (0.0, 1.0)，不含边界 | SplitNode 构造函数 assert |
| I4 | **最小尺寸**：给定容器 Size，每个 leaf 的 resolved Rect ≥ 200×200 | 操作提交前 resolve + 验证 |
| I5 | **非空**：树至少有 1 个节点 | GroupLayout 保证 root 非 null |
| I6 | **双射**：leaf groupId 集合 = EditorShellService.groups key 集合 | service 级操作保证（split 同时创建 group + leaf，close 同时销毁） |
| I7 | **无重复兄弟**：SplitNode 的两个子 Leaf 不可有相同 groupId | split 操作生成新 groupId |

---

## EditorGroupModel ↔ Leaf 对应关系

DI-1 Q2 生命周期事件在布局树上的映射：

| DI-1 生命周期事件 | EditorGroupModel | 布局树 |
|-------------------|-----------------|--------|
| **启动** | 创建 primary group | 树 = `LeafNode(primaryGroupId)` |
| **Split** | 创建新 group（tabs = [原 activeTab]） | 将目标 leaf 替换为 `SplitNode(原leaf, 新leaf, axis, 0.5)` |
| **关闭最后 tab（非 primary）** | group 销毁 | 将该 leaf 的父 SplitNode 替换为兄弟节点（坍缩） |
| **关闭最后 tab（primary）** | group 保留（空状态） | leaf 保留 |

**Split 示例**：

```
初始状态:      LeafNode("g1")

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

**Close 示例**（关闭 g3）：

```
关闭前:        SplitNode(axis: H, fraction: 0.5)
               ├── LeafNode("g1")
               └── SplitNode(axis: V, fraction: 0.5)
                   ├── LeafNode("g2")
                   └── LeafNode("g3")  ← 关闭

关闭后:        SplitNode(axis: H, fraction: 0.5)
               ├── LeafNode("g1")
               └── LeafNode("g2")     ← 父 SplitNode 坍缩为兄弟
```

---

## 开放设计项

1. ~~**Pane 上限**：v0.2 硬编码 4。递归树后建议保留软上限（如 8），防止无限分割导致 pane 不可用。具体数值待 PR-0301 实施时确认。~~ — **已由 DI-3 D9 裁决**：Pane 数上限 = 8，无深度限制。
2. **分隔线宽度**：resolve 算法需要扣除分隔线像素（如 4-8px）再分配剩余空间。具体值待 PR-0301 实施时确认。
3. ~~**序列化格式**：DI-3 范围。sealed class 结构天然映射到 JSON（`{"type": "split", ...}` / `{"type": "leaf", ...}`）。~~ — **已由 DI-3 D7 裁决**：JSON 持久化 + 独立文件 `workspace_layout.json` + 1 秒去抖写入。

---

## 关联

- → DI-3（布局持久化依赖 D5 节点结构 — sealed class JSON 序列化）
- → DI-6（PR-0302 对 PR-0301B 的隐藏依赖）
- ← DI-1 Q2（EditorGroupModel 生命周期 → 布局树 split/close 映射）
- ← DI-1 Q5（文件位置 `lib/core/editor/group_layout.dart`）
- ← 01 审计报告 §2.3 + §4.2

---

*前序议题：[DI-1 EditorShellService 接口](DI-1-editor-shell-service.md)（RESOLVED）*
*下一个议题：[DI-3 布局持久化](DI-3-layout-persistence.md)*

---

## 实施关联 `[PR-RB-06 新增]`

D5/D6 裁决由 PR-RB-06 实施。GroupLayout sealed class 二叉树 + top-down resolve 首次落地。

See: `docs/releases/v0.3/prs/PR-RB-06-core-editor-foundation.md`
