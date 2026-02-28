# S1: Atom 投影语义

| 字段 | 值 |
|------|-----|
| 状态 | **Deferred** — v0.3 实现 |
| 裁决日期 | 2026-02-26 |
| 关联 PR | PR-0301（递归布局）、PR-0308（task-calendar 投影） |

---

## 决策

Atom 是**泛型容器**，所有投影行为（渲染形状、列表分区、编辑器选择）由属性字段驱动，不由 `kind` 枚举硬编码。

---

## 规则（R1–R13）

### R1: Atom 统一容器模型

Atom 不是"笔记/任务/事件"三种实体的联合类型，而是一个**六层容器**：

| 层 | 字段 | 职责 |
|----|------|------|
| 身份 | `uuid` | 全局唯一标识，不可变 |
| 内容 | `content`, `content_type`（待加） | 承载体 + 格式声明 |
| 投影 | `view_hint`（当前为 `kind`/`type`）, `task_status` | 渲染提示 |
| 时间 | `start_at`, `end_at`, `recurrence_rule` | 时间维度 |
| 元数据 | `title`（待加）, `preview_text`, `preview_image`, `tags` | 索引与展示 |
| 组织 | `atom_ref[]`（workspace tree） | 结构归档 |

任何 Atom 都可以同时拥有时间字段和 task_status。`view_hint` 是渲染建议，不是类型约束。

### R2: content_type 字段

新增 `content_type TEXT DEFAULT 'markdown'`，声明内容格式：

| 值 | 含义 | 编辑器 |
|----|------|--------|
| `markdown` | Markdown 文本（默认） | MarkdownEditorPane |
| `canvas` | 空间画布（v0.4+） | CanvasEditorPane |
| `conversation` | 对话记录（v0.4+） | ConversationEditorPane |

`content_type` 决定**编辑器选择**，`view_hint` 决定**列表渲染形状**，两者正交。

### R3: view_hint 自动推导

`type`/`kind` 重命名为 `view_hint`，由 Core service 在创建/更新时自动推导：

| start_at | end_at | task_status | → view_hint |
|----------|--------|-------------|-------------|
| NULL | NULL | NULL | `note` |
| NULL | NULL | 非 NULL | `task` |
| 有值 | 有值 | — | `event` |
| 其他 | 其他 | — | `task`（有时间 + 无配对 = deadline/ongoing task） |

用户可手动覆盖。自动推导仅在字段为 NULL 时触发。

### R4: 渲染行为矩阵

| view_hint | 列表图标 | 可否勾选 | 时间显示 | 进入编辑器 |
|-----------|---------|----------|---------|-----------|
| `note` | 文档图标 | 仅当 task_status 非 NULL | 仅当 start_at/end_at 非 NULL | ✓ |
| `task` | Checkbox | ✓ | 仅当 start_at/end_at 非 NULL | ✓ |
| `event` | 日历图标 | 仅当 task_status 非 NULL | ✓ | ✓ |

核心原则：**view_hint 选择渲染模板，字段值决定模板内哪些元素可见**。

### R5: atom_ref 强制伴随

**核心规则**：Atom 创建必须同时产出至少一个 `atom_ref`。没有 atom_ref 的 Atom 是"坏死的原子"— 无法在 Explorer 中操作。

- 创建 API（`note_create`, `entry_create_note` 等）统一在 Core service 层同时创建 Atom + atom_ref
- atom_ref 落入位置由创建路径路由表决定（见 R6）
- 一个 Atom 可拥有多个 atom_ref（多引用，见 R7）

### R6: 指定默认路径模型

取消 Smart Folder（查询驱动虚拟视图），改为**指定默认路径文件夹**：

| 创建路径 | atom_ref 落入位置 |
|---------|-----------------|
| `> task buy milk` | Tasks 指定文件夹（`/Tasks/`） |
| `> schedule meeting` | Calendar 指定文件夹（`/Calendar/`） |
| Notes 头部按钮 | 根级别（`parent_uuid = NULL`） |
| Explorer 右键"在文件夹中创建" | 指定的父文件夹 |

指定文件夹是**普通文件夹**，在 Explorer 中平等显示，不享有特殊权限。

### R7: 多引用创建

一个 Atom 可有多个 atom_ref（出现在多个文件夹中）。通过 Explorer 右键"添加引用到..."创建额外 atom_ref。所有引用平等，无"主引用"概念。

### R8: title 字段

新增 `title TEXT`（可选）。当前 `preview_text` 从 content 自动派生，`title` 为用户显式设定的标题。列表优先显示 `title`，回退到 `preview_text`。

### R9: icon 字段

保留为 v0.4+。用户可自定义 Atom 图标（emoji 或 icon name），覆盖 view_hint 的默认图标。

### R10: cover_image 字段

保留为 v0.4+。Atom 封面图片，用于卡片视图或画廊模式。

### R11: comment 语义

**冻结**。Comment 作为独立 Atom（`content_type = 'comment'`）通过 atom_ref 挂载到父 Atom。UI/UX 细节待 v0.4+ 设计。

### R12: Block Tree 统一框架

**冻结**。当前 content 是纯 Markdown 文本。v0.5+ 考虑 block tree（结构化内容模型），统一 markdown/canvas/conversation 的底层表示。

### R13: conversation content_type

**冻结**。`content_type = 'conversation'` 的 4 个待设计项：消息结构、参与者模型、引用机制、渲染规则。v0.4+ 设计。

---

## 理由

1. **S1 统一模型消除了类型硬编码**：用户不必在创建时决定"这是笔记还是任务"，可以随时添加 deadline 或 status
2. **view_hint 自动推导减少用户认知负担**：系统根据字段组合自动选择最佳渲染形状
3. **atom_ref 强制伴随消除组织孤儿**：每个 Atom 在 Explorer 中都有位置，可被移动、复制、操作
4. **content_type 与 view_hint 正交**：内容格式（怎么编辑）和展示形状（怎么在列表中显示）互不干扰

---

## 实施状态

| 项目 | 状态 |
|------|------|
| 语义定义（R1-R13） | v0.2.5 已完成 |
| view_hint 重命名 + 自动推导 | v0.3 待实施 |
| title 字段 | v0.3 待实施 |
| content_type 字段 | v0.3 待实施 |
| atom_ref 强制伴随 | v0.3 待实施（S4 前置） |
| 指定默认路径模型 | v0.3 待实施 |
| R9 icon / R10 cover_image | v0.4+ |
| R11 comment / R12 block tree / R13 conversation | v0.4+–v0.5+ |

---

## 开放设计项

- R11: Comment 的 UI/UX 可视化方案未定义
- R12: Block tree 与当前纯 Markdown content 的迁移路径未规划
- R13: Conversation content_type 的消息结构、参与者模型、引用机制、渲染规则均为 `[待设计]`
