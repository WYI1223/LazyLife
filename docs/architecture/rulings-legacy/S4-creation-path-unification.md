# S4: Note 创建入口统一

| 字段 | 值 |
|------|-----|
| 状态 | **Accepted** — v0.3 PR-RB-03 实现 |
| 引入版本 | v0.2.5 (PR-0256) |
| 废弃者 | — |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0301 前置 PR |

---

## 决策

采用 **atom_ref 强制伴随 + 指定默认路径文件夹**模型。所有创建路径统一为：`创建 Atom` + `创建 atom_ref（落到指定位置）`。不存在"只创建 Atom 不创建 ref"的路径。

核心内容已写入 S1 R5（强制伴随）和 S1 R6（指定默认路径模型）。S4 补充创建路径路由和操作模型。

---

## 规则

1. **atom_ref 强制伴随**：Atom 因 ref 而存在。没有 atom_ref 的 Atom 等于"坏死的原子"— 看得见但无法操作
2. **创建路径路由**：每条创建路径有明确的 atom_ref 落入位置（见 S1 R6 路由表）
3. **统一操作路径**：所有操作（移动、复制、删除）统一作用于 atom_ref，一套代码逻辑
4. **视图-文件夹正交**：视图（属性查询驱动）和文件夹（结构组织驱动）完全正交，指定默认路径仅影响创建路由，不引入运行时耦合

---

## 原始问题

### 两条创建路径的差异

| 路径 | 触发方式 | 当前行为 |
|------|---------|---------|
| A（头部按钮） | Notes 面板头部 "+" 按钮 | 创建空 Atom → 自动应用当前 tag → **不挂载到 tree** → 成为"未分类"笔记 |
| B（右键菜单） | Explorer 右键 "在文件夹中创建" | 创建空 Atom → 创建 note_ref 挂载到指定文件夹 → 不自动应用 tag |

### 更深层问题

1. **路径 A 不创建 atom_ref** → Atom 成为"组织孤儿"，无法在 Explorer 中操作
2. **Smart Folder 查询虚拟视图** → 虚拟视图中的 Atom 没有 atom_ref，需要两套操作逻辑
3. **"Uncategorized" 作为零 ref 查询** → 用户无法对 Uncategorized 中的 Atom 进行文件夹级操作

---

## 统一后的创建路径路由

| 创建路径 | atom_ref 落入位置 |
|---------|-----------------|
| `> task buy milk` | Tasks 指定文件夹 |
| `> schedule meeting` | Calendar 指定文件夹 |
| Notes 头部按钮 | 根级别（`parent_uuid = NULL`） |
| Explorer 右键"在文件夹中创建" | 指定的父文件夹 |

"未分类" = 根级别 atom_ref（`parent_uuid = NULL`），不是"没有 ref"。

---

## 视图-文件夹正交性

| | Tasks 视图 | Tasks 文件夹 |
|---|---|---|
| 驱动 | 属性查询（`task_status IS NOT NULL`） | 结构组织（atom_ref 的 `parent_uuid`） |
| 一个在、另一个不在 | 正常（用户可能把 task 移到了 /Work/） | 正常（文件夹里可以有非 task atom） |

视图和文件夹不保持同步。指定文件夹仅影响**创建时的默认路由**，不影响之后的查询和组织。

---

## 理由

1. **消除组织孤儿**：强制伴随保证每个 Atom 都有 tree 位置和完整操作能力
2. **统一操作路径**：所有操作统一作用于 atom_ref，避免 Atom 本体操作和 atom_ref 操作两套代码
3. **Smart Folder 简化**：从查询驱动虚拟视图改为普通文件夹，消除特殊操作逻辑
4. **最小摩擦**：用户无需理解 Atom 和 atom_ref 的区别，每个可见条目都有完整的操作能力
5. **与 S1 一致**：Atom 是容器，组织层（workspace）是容器的必备维度

---

## 实施状态

| 项目 | 状态 |
|------|------|
| 语义定义 | v0.2.5 已完成 |
| DB migration: `note_ref` → `atom_ref` (Migration 11) | v0.3 PR-RB-03 已完成 |
| `workspace_create_note_ref` → `workspace_create_atom_ref` FFI rename | v0.3 PR-RB-03 已完成 |
| `CreationService` 统一创建 + mandatory atom_ref | v0.3 PR-RB-03 已完成 |
| `EntryActionResponse.node_uuid` / `AtomItemResponse.node_uuid` 回传 | v0.3 PR-RB-03 已完成 |
| 路径 A 修正（自动创建根级别 atom_ref） | v0.3 PR-RB-03 已完成 |
| 指定默认路径文件夹配置 | v0.3 待实施 |

---

## 开放设计项

- 指定默认路径的持久化方式（settings.json vs 数据库配置表）
- 待排期池（`/Pending/`）的具体实现方案

---

## v0.4 Addendum（DI-11 / DI-12，规划态）

> 本节仅作为 v0.4 规划输入，不覆盖 v0.3 进行中的执行基线。

1. 创建入口收敛目标：以 `atom_create` 作为规范入口，`note_create` 与 `entry_create_*` 作为兼容包装层。
2. 创建事务内核不变：始终为 `insert atom` + `insert atom_ref`（同事务）。
3. 路由口径规划：显式 `parent_node_id` > 意图上下文（task/calendar）> 默认兜底节点。
4. DI-12 落地后，默认兜底与视图系统路由将从“root/null + designated mapping”收敛到“单根树 + 固定系统节点”。
