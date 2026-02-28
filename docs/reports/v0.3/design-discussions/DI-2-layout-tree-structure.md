# DI-2: 递归布局树节点结构 + 约束传播

| 项目 | 值 |
|------|-----|
| **状态** | OPEN |
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

## 待讨论

1. **D5**：sealed class / 可变树 / 不可变 rebuild — 各选项的权衡？
2. **D6**：约束传播方向 — min 200px 在嵌套场景下如何保证？
3. 树的不变量（invariants）应该是什么？
4. 与当前 PR-0301 spec 中的 `EditorGroup` leaf 概念如何对应？

---

## 关联

- → DI-3（布局持久化依赖 D5 节点结构）
- → DI-6（PR-0302 对 PR-0301B 的隐藏依赖）
- ← 01 审计报告 §2.3 + §4.2

---

*前序议题：[DI-1 EditorShellService 接口](DI-1-editor-shell-service.md)*
*下一个议题：[DI-3 布局持久化](DI-3-layout-persistence.md)*
