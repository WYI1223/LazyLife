# S3: Tag × Workspace Tree 正交性

| 字段 | 值 |
|------|-----|
| 状态 | **Deferred** — v0.3 实现 |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0304（tab 模型）、PR-0307（launcher） |

---

## 决策

Tag（语义分类）与 Explorer / Workspace Tree（结构归档）是**完全正交的两个维度**。Tag 过滤不影响 Explorer tree 的完整性。

---

## 规则

1. **正交性**：Tag 过滤仅影响 tag 查询结果面板，不影响 Explorer tree 视图
2. **Explorer 完整性**：Explorer 始终展示用户组织的全部结构，不受 tag 选择影响
3. **指定文件夹平等**：所有文件夹（包括 S1 R6 指定默认路径文件夹）在 Explorer 中平等显示
4. **面包屑导航**：Tag 查询结果附带 atom_ref 路径面包屑，提供结构上下文

---

## 两个正交维度

| 维度 | Tag | Explorer（Workspace Tree） |
|------|-----|---------------------------|
| 本质 | **语义分类**（查询驱动） | **结构归档**（用户组织） |
| 数据源 | `atom_tags` 表（Atom × Tag 多对多） | `workspace_nodes` 表（atom_ref 层级结构） |
| 结果 | 符合条件的 Atom 扁平列表 | 用户手动组织的层级树 |
| 操作 | 过滤、排序、聚合 | 拖拽、移动、重命名、嵌套 |
| 类比 | Gmail 标签 / Obsidian 标签搜索 | macOS Finder 文件夹 / Obsidian 文件树 |

---

## 渐进实施方案

### Phase A — 独立面板（v0.3 实现）

Tag 查询结果作为独立面板，选中 tag 时展开，将 Explorer 下推：

```
┌─────────────────────┐
│ [Tag A] [Tag B] ... │  ← tag 芯片栏
├─────────────────────┤
│ Tag "Tag A" 结果     │  ← 独立结果面板（选中 tag 时展开）
│ ├── Atom X  📁A/B   │     每条目附 atom_ref 路径面包屑
│ ├── Atom Y  📁根目录 │
│ └── Atom Z  📁C     │
├─────────────────────┤
│ Explorer             │  ← 被下推，仍完整可见（可折叠）
│ ├── 📁 Tasks/       │
│ ├── 📁 文件夹A/     │
│ └── ...              │
└─────────────────────┘
```

### Phase B — 视图替换（v0.3+ 优化）

Phase A 稳定后，Tag 结果直接替换 Explorer 视图区域。取消 tag 选择恢复 Explorer。本质是 Phase A 的 UI 布局优化，不涉及架构变更。

### 未来：三种 Explorer 视图模式

| 模式 | 触发 | 内容 |
|------|------|------|
| **Tree**（默认） | 无 tag 选中 | 完整 workspace tree |
| **List**（Tag 查询） | 选中 tag | 扁平 Atom 列表 + 目录面包屑 |
| **Spatial**（S1 R12） | 用户切换 | 文件夹内容空间化布局（v0.4+） |

---

## 理由

1. **正交性**：Tag 和 Explorer 是两个独立维度，让 tag 过滤 tree 会混淆两种组织模型
2. **面包屑弥补上下文**：tag 查询结果附带 atom_ref 路径，弥补扁平列表缺乏上下文的问题
3. **渐进低风险**：Phase A→B 是 UI 布局的渐进优化，不涉及架构变更
4. **三视图扩展**：tree/list/spatial 框架为 S1 R12 Spatial Workspace View 预留自然集成点

---

## 实施状态

| 项目 | 状态 |
|------|------|
| 语义定义 | v0.2.5 已完成 |
| 当前行为符合目标语义 | ✓（tag filter + explorer 独立工作是 Phase A 的前置状态） |
| Phase A：独立面板 | v0.3 待实施 |
| Phase B：视图替换 | v0.3+ 待实施 |
| Spatial 视图模式 | v0.4+ |

---

## 开放设计项

- Phase A 的面包屑路径格式（全路径 vs 最近两级）
- 多 atom_ref 场景的面包屑显示策略（显示全部 vs 仅主引用）
