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

| 值 | 含义 | 渲染引擎 |
|----|------|----------|
| `markdown` | 富文本/Markdown（当前默认） | 文本编辑器（MarkdownEditorPane） |
| `canvas` | 2D 画布（类 Miro，v0.4+） | 2D 渲染引擎（CanvasEditorPane） |
| `conversation` | 对话形式（LLM 载体，v0.4+） | 对话框渲染（ConversationEditorPane） |
| `plugin:<id>` | 插件定义格式（v0.4+） | 插件渲染器 |

`content_type` 决定**编辑器选择**，`view_hint` 决定**列表渲染形状**，两者正交。

**内容存储格式**（按 content_type 区分）：

| content_type | `Atom.content` 存储格式 | Core 层处理 |
|---|---|---|
| `markdown` | 纯文本 Markdown 字符串 | Opaque string，不解析 |
| `canvas` | JSON（Spatial Document Schema，见 R12） | Opaque string，不解析 |
| `conversation` | JSON（对话记录，见 R13） | Opaque string，不解析 |
| `plugin:<id>` | 插件定义格式 | Opaque string，不解析 |

Core 层统一将 `content` 视为 opaque string 存储，不区分格式。渲染解析完全在 Flutter 层（EditorResolver → 对应 EditorPane）。

**双结构策略**：v0.2.5–v0.4 期间，markdown 和 canvas 使用完全独立的内容结构，互不影响。v0.5+ 评估是否参考 AFFiNE/BlockSuite 统一为 block tree（markdown 块可选获得空间属性）。当前不做统一。

**content_type 扩展策略**：上述四项为当前正式枚举。新增 content_type（如未来可能的 `block_document` 等）须通过 ruling 或 ADR 注册到本枚举，并同步更新 EditorResolver 注册和 FFI 契约。各设计文档中以"如 `xxx`"形式出现的 content_type 均为占位命名，不构成正式定义。

### R3: view_hint 自动推导

`type`/`kind` 重命名为 `view_hint`，由 Core service 在创建/更新时自动推导。**task_status 优先**：

| 推导规则 | view_hint |
|---|---|
| 有 `task_status` | `task` |
| 无 `task_status` + 有 time fields | `event` |
| 无 `task_status` + 无 time fields | `note`（默认/N/A） |

- `note` 是默认值/N/A，只有 task 和 event 视图下 view_hint 才有独立语义
- 存储为 DB 字段用于索引和渲染优化（避免每次从 time fields + status 动态计算）
- API 保留显式设置端口，供 LLM / Single Entry 命令系统调用

**view_hint 用途限定**：

view_hint 是**渲染提示**，不是查询维度。

| 用途 | 使用 view_hint | 使用字段查询 |
|---|---|---|
| Explorer/搜索结果图标 | ✓ | — |
| 列表卡片渲染模板 | ✓ | — |
| Tasks 视图过滤 | — | `task_status IS NOT NULL` |
| Calendar 视图过滤 | — | `start_at IS NOT NULL AND end_at IS NOT NULL` |
| entry_search kind 过滤 | — | 字段查询（待 DI-9 设计） |

**查询一致性原则**：所有查询上下文（视图、搜索、tag）统一使用字段查询，不使用 view_hint 过滤。view_hint 仅供 UI 层决定渲染形状（图标、卡片模板）。这保证同一个 Atom 在不同查询入口的可见性一致。

### R4: 渲染行为矩阵

view_hint 作为快捷路径，但最终渲染行为由**实际字段组合**决定：

| time fields | task_status | view_hint | 用户感知 | 渲染行为 |
|---|---|---|---|---|
| 无 | null | note | 一条笔记 | 纯文本/内容卡片 |
| 无 | 有 | task | 一个待办 | checkbox 卡片 |
| 仅 end_at | 有 | task | 有截止的待办 | checkbox + deadline 标签 |
| start+end | null | event | 一个日程 | 时间条 |
| start+end | 有 | task | 可完成的日程 | 时间条 + checkbox |
| 仅 start_at | 有 | task | 已开始的任务 | checkbox + 进行中标签 |
| 有 time | null | event | 有时间的笔记 | 内容卡片 + 时间标注 |

核心原则：**view_hint 选择渲染模板，字段值决定模板内哪些元素可见**。view_hint 列的值由 R3 推导规则决定（task_status 优先）。

### R5: atom_ref 强制伴随

**核心规则**：Atom 创建必须同时产出至少一个 `atom_ref`。没有 atom_ref 的 Atom 是"坏死的原子"— 无法在 Explorer 中操作。

- 创建 API（`note_create`, `entry_create_note` 等）统一在 Core service 层同时创建 Atom + atom_ref
- atom_ref 落入位置由创建路径路由表决定（见 R6）
- 一个 Atom 可拥有多个 atom_ref（多引用，见 R7）
- 无明确文件夹上下文时 → atom_ref 落入根级别（`parent_uuid = NULL`）
- 删除非最后一个 ref → 仅移除该引用，Atom 和其他 ref 不受影响
- 删除最后一个 ref → atom_ref 回归根级别（`parent_uuid = NULL`），Atom 不会成为"孤儿"
- 当前 schema 已支持（`workspace_nodes` 无 `UNIQUE(atom_uuid)` 约束）

### R6: 指定默认路径模型

取消 Smart Folder（查询驱动虚拟视图），改为**指定默认路径文件夹**：所有文件夹在结构上平等。"Smart Folder" 不是查询驱动的虚拟视图，而是**指定了默认创建路径的普通文件夹** — 和用户手动创建的文件夹完全相同，支持重命名、移动。

**默认创建路径路由**：

| 创建上下文 | atom_ref 目标 | 附加行为 |
|---|---|---|
| 文件夹内右键创建 | 该文件夹 | — |
| Tasks 视图创建 | Tasks 指定文件夹 | 自动设置 `task_status` |
| Calendar 视图创建 | Calendar 指定文件夹 | 可选设置 time fields（未设置则进入待排期池） |
| 头部按钮（Tag 已选中） | 根级别 | 自动应用当前 tag |
| 头部按钮（无上下文） | 根级别 | — |
| Single Entry 命令 | 按命令类型路由到对应指定文件夹 | 按命令设置属性 |

创建路径的差异从"是否产出 atom_ref"变为"atom_ref 落在哪里 + 附加什么属性"。

**指定文件夹生命周期**：

| 操作 | 行为 |
|---|---|
| 首次指定 | 配置映射 `视图 → 文件夹`，后续该视图创建的 atom_ref 路由到此文件夹 |
| 重新指定 | 旧文件夹全部子节点移动到新文件夹（单步 `UPDATE parent_uuid`），旧文件夹变为空的普通文件夹 |
| 取消指定 | 解除映射，文件夹变为普通文件夹，内容不动 |
| 删除指定文件夹 | **禁止** — 仅允许重新指定或取消指定 |
| 不设指定文件夹 | 对应视图创建的 atom_ref 落到根级别（合法状态） |

- 重新指定 = 搬家，不区分 ref 来源，文件夹里所有内容全部移动
- 旧文件夹变空后，删除保护解除（不再是指定文件夹），用户可自行删除

**指定文件夹在视图中的呈现**：

指定文件夹中未匹配视图查询条件的 atom 不会"消失"，而是在视图内有对应的承接区域：

| 视图 | 未排期 atom 的呈现 | 排期操作 |
|---|---|---|
| Tasks | Inbox section 天然承接（`task_status IS NOT NULL` 但无时间字段） | 在 Atom 编辑器中设置时间 |
| Calendar | 左侧边栏「待排期池」（Calendar 文件夹中 `start_at IS NULL AND end_at IS NULL` 的子集） | 从侧边栏拖拽到周视图时间格，自动设置 `start_at`/`end_at` |

Calendar 待排期池布局：

```
┌──────────┬──────────────────────────┐
│ ◀ Feb ▶  │   Mon   Tue   Wed   ... │
│ [月历]    │   ┌───┐                 │
│           │   │会议│                 │
│           │   └───┘                 │
├──────────┤                          │
│ 📁 待排期 │                          │
│ ├ 📄 读书 │  ← 拖到右边周视图        │
│ ├ 📄 体检 │     自动设置 start/end   │
│ └ 📄 约饭 │                          │
└──────────┴──────────────────────────┘
```

- 待排期池数据源 = Calendar 指定文件夹中无时间字段的 atom_ref
- 拖拽到周视图 → atom 从待排期池消失，出现在对应时间格
- 入站时不自动推断属性 — 待排期池本身就是"和日程有关，但还没决定什么时候"的合法中间态

**"未分类" = 根级别**：根级别（`parent_uuid = NULL`）的 atom_ref 即为"未分类"。不需要单独的 Uncategorized 文件夹 — 根级别本身就是默认归属。

**所有操作统一走 atom_ref**：

| 操作 | 行为 |
|---|---|
| 拖拽到文件夹 | 移动 atom_ref（改 `parent_uuid`） |
| Ctrl+拖拽 / Duplicate | 创建新 atom_ref（同一 Atom 的新引用） |
| 删除 ref（非最后一个） | 删除该 atom_ref |
| 删除 ref（最后一个） | `parent_uuid = NULL`（回归根级别） |
| 删除 Atom | soft-delete Atom（`is_deleted = 1`）+ 所有 ref |

Atom 永远不会「消失」— 要么在文件夹里（有 parent），要么在根级别（`parent = NULL`），要么被 soft-delete。

**指定路径配置**：配置层存储视图 → 文件夹的映射关系（类似 app 指定缓存目录）。用户未来可更改指定路径（如将 Tasks 默认路径指向 `/Work/Tasks`）。

### R7: 多引用创建交互

一个 Atom 可有多个 atom_ref（出现在多个文件夹中）。所有引用平等，无"主引用"概念。

**主要方式 — Duplicate + 拖拽**：
- 右键 atom_ref → "Duplicate"（创建引用副本）→ 在同一文件夹内生成一个新 atom_ref 指向同一 Atom
- 用户将 duplicated ref 拖拽到目标文件夹
- 复用现有拖拽机制，不需要 Ctrl+拖拽修饰键逻辑
- 解决了「在当前文件夹创建同一 Atom 的第二个引用」的边界情况

**辅助方式**：
- 右键 atom_ref → "添加引用到..." → 弹出文件夹选择器 → 直接在目标位置创建 ref
- Single Entry 命令：`> link "React性能优化" to 工作/项目A`

**拖拽行为规则**：

| 操作 | 行为 |
|---|---|
| 拖拽 atom_ref 到另一个文件夹 | **移动** ref（改 `parent_uuid`） |
| 拖拽 atom_ref 到根级别 | **移动** ref（`parent_uuid = NULL`） |
| Duplicate + 拖拽到目标 | **创建引用**（新 atom_ref 指向同一 Atom） |

所有文件夹平等 — 包括指定默认路径文件夹（Tasks/Calendar）。拖拽操作不因文件夹类型而不同。UI 光标图标区分移动和创建引用两种状态。

### R8: title 字段

新增 `title TEXT NOT NULL DEFAULT ''`，应用语义层保证**永远非空，永远是纯文本**。

- **title 是"这个东西叫什么"** — Tab 栏、Explorer、Task 列表、Calendar 全部读同一个字段
- **preview_text 是"这个东西里面长什么样"** — 列表卡片的次级摘要区域，不再被当 title 使用

**title 写入策略**（按 content_type 区分，由 Rust Core 在创建/更新时执行）：

| content_type | title 来源 | content 更新时 |
|---|---|---|
| `markdown` | 自动推导：content 第一非空行，去 `#`，截取 50 字符 | 自动重新推导并覆盖 |
| `canvas` | 用户命名，默认 "Untitled"（canvas 中心不可删除的标题文本框） | 不自动更新（content 是 JSON） |
| `conversation` | 自动推导：第一条用户 prompt 截断 | 不自动更新（保持首次 prompt） |

- markdown 的 title 永远 = content 第一行的推导结果，不支持手动覆盖 Atom 本体的 title
- 用户想给引用起别名 → 使用 atom_ref 的 `display_name`（节点级别名，不影响 Atom 本体）
- title 推导逻辑从 Flutter 下沉到 Rust Core，在 `note_create` / `note_update` 时写入

### R9: icon 字段

保留为 v0.4+。用户可自定义 Atom 图标（emoji 或 icon name），覆盖 view_hint 的默认图标。

### R10: cover_image 字段

新增 `cover_image: Option<String>`，用户显式设置的封面图。保留为 v0.4+。

**`cover_image` vs `preview_image` 的区别**：

| | cover_image | preview_image |
|---|---|---|
| 来源 | 用户显式设置 | 自动推导（markdown 第一张图、canvas 缩略图等） |
| content_type 依赖 | 无，任何类型都能有封面 | 推导逻辑依赖 content_type |
| 用户可控 | 是（add image 操作） | 否（系统自动维护） |

**列表渲染优先级**：`cover_image`（用户设置）> `preview_image`（自动推导）> NULL

用户在列表视图点"add image"= 设置 `cover_image`，不修改 content。

### R11: comment 语义

**冻结** — 语义已定义，实现排入 v0.4+。

**目标语义**：Comment 是附加在 Atom 上的、有时间顺序的、独立于 content 主体的轻量注释流。

| view_hint | Comment 典型用途 |
|---|---|
| task | 进度记录："等 John 回复"、"第一步已完成" |
| event | 会议备注："改到 3 点"、"记得带文稿" |
| note | 较少使用，可能是自我批注 |

**目标实现**（方案 C — 独立关联实体）：

```sql
CREATE TABLE atom_comments (
    comment_id TEXT PRIMARY KEY,
    atom_uuid  TEXT NOT NULL REFERENCES atoms(uuid),
    content    TEXT NOT NULL,
    created_at INTEGER NOT NULL
);
```

**推迟理由**：
- 当前产品阶段 ROI 不高，v0.2.5/v0.3 有更紧迫的结构性工作
- 独立实体方案是最终正确答案：content_type 无关（canvas 也能加 comment）、可独立查询分页、未来可扩展协作
- 当前如有临时需求，可在 Flutter 层用追加 content 的方式过渡，但不作为正式设计

### R12: Spatial Canvas 预留框架

**冻结** — 语义已定义，实现排入 v0.3–v0.4+。

**两个使用场景，共享一个 Canvas 渲染引擎**：

| | 场景 A：Canvas Atom | 场景 B：Spatial Workspace View |
|---|---|---|
| 本质 | **内容创作** — 用户在画布上绘图/写作 | **导航组织** — 用户空间化管理文件 |
| 数据源 | `Atom.content` JSON 里的 elements | 文件夹的 atom_refs + 空间坐标 |
| 元素 | shape / text / image / code_block / table / connector | Atom 卡片 / 子文件夹 |
| 交互 | 绘图、连线、插入元素 | 拖拽归档、打开编辑、移动到其他文件夹 |
| 类比 | Miro / FigJam / PPT | macOS Finder 空间视图 / Windows 桌面 |

**场景 A：Canvas Atom（`content_type = 'canvas'`）**

Canvas Spatial Document Schema（v1 预留）：

```json
{
  "schema_version": 1,
  "viewport": { "x": 0, "y": 0, "zoom": 1.0 },
  "elements": [
    {
      "id": "elem-uuid",
      "type": "shape | text | image | code_block | table | connector | atom_embed | group",
      "xywh": [x, y, width, height],
      "rotation": 0,
      "z_index": 0,
      "props": { }
    }
  ]
}
```

基础元素类型（优先级排序）：

| 优先级 | Element type | 描述 | props 示例 |
|---|---|---|---|
| P0 | `text` | 文本框 | `{ content, font_size, color }` |
| P0 | `shape` | 矩形/椭圆/多边形 | `{ shape_type, fill, stroke, text }` |
| P0 | `image` | 图片 | `{ src, crop }` |
| P0 | `connector` | 连接线 | `{ source_id, target_id, path_type }` |
| P1 | `code_block` | 代码块 | `{ language, code }` |
| P1 | `table` | 结构表 | `{ rows, cols, cells }` |
| P2 | `atom_embed` | 嵌入的 Atom 卡片 | `{ atom_uuid }` |
| P2 | `group` | 元素分组 | `{ children: [elem_id, ...] }` |

`atom_embed` 与 atom_ref（R5）的区别：
- `atom_embed`：内容层的空间嵌入 — "这个画布上放了哪个 Atom，在什么位置"
- `atom_ref`：组织层的结构引用 — "这个 Atom 出现在哪些文件夹里"
- 两者独立，不互斥

**场景 B：Spatial Workspace View**

Explorer 树视图的空间化替代 — 文件夹内容以卡片形式在画布上空间布局。空间坐标存储：在 `workspace_nodes` 表上添加 nullable 的 `spatial_x REAL, spatial_y REAL` 列。仅当用户在 spatial view 中布局过才有值；NULL = 使用自动布局。

**反向查询预留**：`canvas_atom_embeds(canvas_atom_id, embedded_atom_id)` 派生索引表概念，在 canvas 保存时自动维护。此表在 canvas 实际实现时通过新 migration 创建。

**实施优先级**：

| 优先级 | 内容 | 版本 |
|---|---|---|
| 1 | Canvas 渲染引擎基础：viewport + 元素选择/移动/缩放 | v0.3–v0.4 |
| 2 | P0 基础元素：text / shape / image / connector | v0.3–v0.4 |
| 3 | P1 元素：code_block / table | v0.4 |
| 4 | Spatial Workspace View（复用引擎 + atom_ref 布局） | v0.4 |
| 5 | P2 元素：atom_embed / group | v0.4+ |
| 6 | 评估 markdown + canvas 统一为 block tree | v0.5+ |

**Flutter 模块预留结构**：

```
lib/features/canvas/              ← v0.3–v0.4 创建
├── canvas_editor_pane.dart       ← 注册到 EditorResolver（S2 Phase 3）
├── canvas_controller.dart        ← 画布状态管理
├── elements/                     ← 各元素渲染器
├── tools/                        ← 工具栏（选择、形状、文字、连线等）
└── viewport/                     ← 缩放、平移、viewport 管理

lib/features/workspace/
└── spatial_view.dart             ← 场景 B，复用 canvas 引擎
```

**Rust Core 预留**：Core 层不解析 canvas content（与 markdown 一致，视为 opaque string）。未来若需服务端渲染 canvas 缩略图（`preview_image`），可在 Core 添加轻量 JSON 解析。

### R13: Conversation 内容类型预留

**冻结** — 语义已定义，实现排入 v0.4+。依赖 S2 Phase 3（EditorResolver）和 extension kernel 运行时。

**定位**：`content_type = 'conversation'` — 用户在 LazyNote 内与 LLM 对话的载体。交互模式为**追加式**（发送消息），不同于 markdown（自由编辑）和 canvas（空间布局）。

**内容结构预留**：

```json
{
  "schema_version": 1,
  "messages": [
    {
      "id": "msg-uuid",
      "role": "user | assistant | system",
      "content": "markdown text",
      "timestamp": 1234567890
    }
  ]
}
```

**与 Atom 模型集成**（R8/S2 对接）：

| 维度 | 行为 |
|---|---|
| title | 自动推导：第一条 user message 截断 |
| preview_text | 最后一条消息摘要 |
| DraftManager | 不适用 — 消息发送即持久化，无"未保存草稿"概念 |
| EditorPane | ConversationPane — 消息气泡 + 底部输入框 |

**需解决的设计问题**（v0.4+ 设计时展开）：

1. **Atom 引用上下文** — 对话能引用其他 Atom 作为 LLM 上下文（"帮我总结这篇笔记"）`[待设计]`
2. **对话产生 Atom** — AI 建议创建 task/event，用户确认后自动生成 `[待设计]`
3. **长对话增长** — content JSON 无限增长的分页/归档策略 `[待设计]`
4. **Extension 集成** — LLM provider 作为 extension，对话通过 extension API 调用 `[待设计]`

---

## 理由

1. **产品愿景对齐**：「最小摩擦的个人第二大脑」要求用户不需要预先决定类型。Atom 容器模型 + 自动推导 view_hint 消除了「选错类型」的摩擦
2. **数据模型简洁**：六个独立维度（identity、carrier、scheduling、actionability、workspace、annotation）各自正交，组合完全合法，数据层不拒绝任何组合
3. **渲染层有确定性**：完整行为矩阵消除了 type × time × status 的未定义场景
4. **性能可保证**：view_hint、title 作为 materialized fields 存储在 DB 中，查询和渲染可利用索引，无需每次动态计算
5. **全局一致性**：title 作为唯一名称源，所有视图读同一个字段，消除了四套推导逻辑的不一致
6. **content_type 正交**：title、icon、cover_image 均独立于 content_type，canvas/conversation/plugin 类型的 Atom 也有完整的身份层
7. **未来可扩展**：content_type 预留了 canvas/conversation/plugin 载体；atom_ref 多引用支持知识网络；指定默认路径可由用户自定义配置；comment 语义已冻结待实现
8. **向后兼容**：当前 `type` 字段语义不变（重命名为 view_hint），现有数据无需迁移；新增字段均为 nullable 或有默认值
9. **Canvas 双场景复用**：Canvas Atom（内容创作）和 Spatial Workspace View（空间组织）共享同一渲染引擎，避免重复建设
10. **双结构务实**：markdown 和 canvas 保持独立内容结构（v0.5+ 评估统一），避免过早引入 block tree 抽象的复杂度

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
| R11 comment（独立实体方案） | v0.4+ |
| R12 Spatial Canvas（渲染引擎 + 元素系统） | v0.3–v0.4+ |
| R13 conversation content_type | v0.4+（依赖 S2 Phase 3 + extension kernel） |

---

## 开放设计项

- **R3**: entry_search kind 过滤从 view_hint 迁移为字段查询 — 待 DI-9 设计
- R11: Comment 的 UI/UX 可视化方案（展示位置、交互方式）
- R12: Canvas 渲染引擎技术选型（Flutter CustomPaint vs 第三方库）；block tree 统一评估（v0.5+）
- R13: Conversation content_type 的 4 个待设计项（Atom 引用上下文、对话产生 Atom、长对话增长、Extension 集成）
