# 08b — 语义裁决记录

> 逐项语义裁决：背景 → 选项 → 裁决 → 理由。
> 本文为 [08-reassessment-and-replanning.md](08-reassessment-and-replanning.md) 的第二部分。
> 标记 `[待讨论]` 的项通过 TL 对话逐项裁决。

| 字段 | 值 |
|------|-----|
| 日期 | 2026-02-26 |
| 议题来源 | [08a-audit-findings.md](08a-audit-findings.md) §1.3 语义模糊地带清单 |
| 状态 | **草稿 — 讨论中** |

---

## S1: Atom 投影语义

### 背景

产品愿景定义「Notes、Tasks、Events 是同一个 Atom 的不同投影」。当前实现中：
- `type` 字段（Note/Task/Event）控制渲染形状（纯文本/checkbox/时间条）
- `start_at`/`end_at` 控制 section 归属（Inbox/Today/Upcoming）
- `task_status` 对所有 type 生效（event 也可以标记 done/cancelled）

**未定义的场景**：
1. `type=note` 但设了 `start_at`+`end_at` → 出现在 Today/Upcoming，但渲染为纯文本而非时间条？
2. `type=event` 但 `start_at`=NULL, `end_at`=NULL → 出现在 Inbox，但渲染为时间条而无时间？
3. `type=event` + `task_status=done` → 日历视图中如何展示？
4. `type=task` + `start_at`+`end_at` 都设了 → 是 deadline 任务还是时间块？

**更深层问题**：`type` 字段最初是为兼容而存在，当前位置不自然。产品愿景追求的自然流是「用户不需要预先选择类型，Atom 在不同维度获得属性后自然呈现不同形态」。

### 选项

**A. 严格正交（当前隐含方向）**：`type` 仅控制渲染，time fields 仅控制 section，`task_status` 仅控制完成态。三者完全独立，所有组合都合法。

**B. 约束矩阵**：定义合法组合白名单，非法组合在 `Atom::validate()` 中拒绝。例如 `type=note` 时不允许设 `task_status`。

**C. 渐进收敛**：当前保持正交，但定义 UI 层的「优雅降级」规则 — 每种 type × time × status 组合都有明确的渲染行为，即使是「奇怪」的组合。

### 裁决

**采用 C 的细化版本，并重新定义 Atom 模型的核心语义。** 具体裁决 13 点：

#### R1. Atom 是容器，不是类型

Note/Task/Event 不是三种不同的东西，是同一个 Atom 在不同维度获得属性后的渲染呈现。Atom 的核心结构：

```
Atom（容器）
├── 身份层（identity）: title + icon + cover_image → 决定「它叫什么、长什么样」
├── 内容层（carrier）: content + content_type → 决定「用什么渲染引擎」
├── 时间层（scheduling）: start_at / end_at → 决定「什么时候」
├── 行为层（actionability）: task_status → 决定「要不要做」
├── 组织层（workspace）: atom_ref(s) → 决定「放在哪里」
└── 附注层（annotation）: comments → 决定「补充了什么」（未来独立实体）
```

#### R2. 新增 `content_type` 字段

标识内容载体格式，决定使用哪个渲染引擎：

| content_type | 含义 | 渲染引擎 |
|---|---|---|
| `markdown` | 富文本/Markdown（当前默认） | 文本编辑器 |
| `canvas` | 2D 画布（类 Miro，未来） | 2D 渲染引擎 |
| `conversation` | 对话形式（LLM 载体，未来） | 对话框渲染 |
| `plugin:<id>` | 插件定义格式（未来） | 插件渲染器 |

**内容存储格式**（按 content_type 区分）：

| content_type | `Atom.content` 存储格式 | Core 层处理 |
|---|---|---|
| `markdown` | 纯文本 Markdown 字符串 | Opaque string，不解析 |
| `canvas` | JSON（Spatial Document Schema，见 R12） | Opaque string，不解析 |
| `conversation` | JSON（对话记录，未来定义） | Opaque string，不解析 |
| `plugin:<id>` | 插件定义格式 | Opaque string，不解析 |

Core 层统一将 `content` 视为 opaque string 存储，不区分格式。渲染解析完全在 Flutter 层（EditorResolver → 对应 EditorPane）。

**双结构策略**：v0.2.5–v0.4 期间，markdown 和 canvas 使用完全独立的内容结构，互不影响。v0.5+ 评估是否参考 AFFiNE/BlockSuite 统一为 block tree（markdown 块可选获得空间属性）。当前不做统一。

`content_type` 字段在当前版本中默认为 `markdown`，为未来扩展预留。

#### R3. `type` 重命名为 `view_hint`，改为自动推导

`view_hint` 是存储层的**派生字段（materialized hint）**，不是用户输入。由 time fields + task_status 在 Atom 创建/更新时自动推导并写入：

| 推导规则 | view_hint |
|---|---|
| 有 `task_status` | `task` |
| 无 `task_status` + 有 time fields | `event` |
| 无 `task_status` + 无 time fields | `note`（默认/N/A） |

- `note` 是默认值/N/A，只有 task 和 event 视图下 view_hint 才有独立语义
- 存储为 DB 字段用于索引和查询优化（避免每次从 time fields + status 动态计算）
- API 保留显式设置端口，供 LLM / Single Entry 命令系统调用

#### R4. 渲染行为矩阵由 time fields + task_status 驱动

view_hint 作为快捷路径，但最终渲染行为由实际字段组合决定：

| time fields | task_status | view_hint | 用户感知 | 渲染行为 |
|---|---|---|---|---|
| 无 | null | note | 一条笔记 | 纯文本/内容卡片 |
| 无 | 有 | task | 一个待办 | checkbox 卡片 |
| 仅 end_at | 有 | task | 有截止的待办 | checkbox + deadline 标签 |
| start+end | null | event | 一个日程 | 时间条 |
| start+end | 有 | task | 可完成的日程 | 时间条 + checkbox |
| 仅 start_at | 有 | task | 已开始的任务 | checkbox + 进行中标签 |
| 有 time | null | event | 有时间的笔记 | 内容卡片 + 时间标注 |

#### R5. note_ref 扩展为 atom_ref，强制伴随 Atom 创建

- Workspace tree 可挂载**任何 Atom**，不限于 note 类型
- **atom_ref 强制伴随 Atom 创建** — 任何创建路径都必须产出至少一个 atom_ref
- 一个 Atom 可以有 **1 个或多个** atom_ref（同一 Atom 出现在多个文件夹中）
- 无明确文件夹上下文时 → atom_ref 落入根级别（`parent_uuid = NULL`）
- 编辑任意位置 → 修改同一个 Atom，所有引用处自动同步
- 删除非最后一个 ref → 仅移除该引用，Atom 和其他 ref 不受影响
- 删除最后一个 ref → atom_ref 回归根级别（`parent_uuid = NULL`），Atom 不会成为"孤儿"
- 当前 schema 已支持（`workspace_nodes` 无 `UNIQUE(atom_uuid)` 约束）

#### R6. Workspace Explorer 采用指定默认路径模型

**核心原则**：所有文件夹在结构上平等。"Smart Folder" 不是查询驱动的虚拟视图，而是**指定了默认创建路径的普通文件夹** — 和用户手动创建的文件夹完全相同，支持重命名、移动、删除。

```
Workspace Explorer
├── 📁 Tasks/           ← 指定为 Tasks 视图的默认路径（普通文件夹）
│   ├── 📄 Buy milk     ← 在 Tasks 视图创建 → atom_ref 落入此处
│   └── 📄 Fix bug
├── 📁 Calendar/        ← 指定为 Calendar 视图的默认路径（普通文件夹）
│   └── 📄 Weekly meeting
├── 📄 Random note      ← atom_ref, parent=NULL（根级别 = "未分类"）
├── 📁 Work/            ← 用户文件夹
│   ├── 📁 子项目/
│   │   └── 📄 Atom X   ← atom_ref_1
│   └── ...
└── 📁 Personal/        ← 用户文件夹
    └── 📄 Atom X       ← atom_ref_2（同一个 Atom 的第二个引用）
```

**默认创建路径路由**：

| 创建上下文 | atom_ref 目标 |
|---|---|
| 文件夹内右键创建 | 该文件夹 |
| Tasks 视图创建 | Tasks 指定文件夹 |
| Calendar 视图创建 | Calendar 指定文件夹 |
| 头部按钮 / Single Entry（无上下文） | 根级别（`parent_uuid = NULL`） |

**指定路径配置**：配置层存储视图 → 文件夹的映射关系（类似 app 指定缓存目录）。用户未来可更改指定路径（如将 Tasks 默认路径指向 `/Work/Tasks`）。

**指定文件夹删除行为**：
- 删除指定文件夹 → 内部 atom_ref 全部回归根级别（`parent_uuid = NULL`）+ 清除该指定路径配置
- 后续创建 → atom_ref 落到根级别，直到用户重新指定
- 重新指定新文件夹 → 根级别中匹配属性的 atom_ref 一次性迁移到新文件夹（不动用户已手动归档到其他文件夹的 atom）

**"未分类" = 根级别**：根级别（`parent_uuid = NULL`）的 atom_ref 即为"未分类"。不需要单独的 Uncategorized 文件夹 — 根级别本身就是默认归属。

**所有操作统一走 atom_ref**：

| 操作 | 行为 |
|---|---|
| 拖拽到文件夹 | 移动 atom_ref（改 `parent_uuid`） |
| Ctrl+拖拽 / Duplicate | 创建新 atom_ref（同一 Atom 的新引用） |
| 删除 ref（非最后一个） | 删除该 atom_ref |
| 删除 ref（最后一个） | `parent_uuid = NULL`（回归根级别） |
| 删除 Atom | soft-delete Atom（`is_deleted = 1`）+ 所有 ref |

- Atom 永远不会「消失」— 要么在文件夹里（有 parent），要么在根级别（`parent = NULL`），要么被 soft-delete
- 不存在"无 atom_ref 的 Atom" — R5 保证创建时强制伴随

#### R7. 多引用创建交互

创建同一 Atom 的多个引用的交互方式：

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

#### R8. `title` 作为 Atom 一等公民字段，统一所有视图的名称显示

**问题**：当前 Atom 没有 `title` 字段，四个视图各自从不同字段用不同逻辑推导"名字"：

| 视图 | 读什么 | 推导逻辑 | 问题 |
|---|---|---|---|
| Tab 栏 / Editor 标题 | `content` | 第一非空行，去 `#` 前缀 | 忽略 `preview_text` |
| Explorer note ref | `content`（优先） | 同上，`display_name` 仅后备 | `display_name` 形同虚设 |
| Task 列表 | `preview_text`（优先） | 有就用，否则 content 第一行去 `#` | preview_text 是摘要不是标题 |
| Calendar 事件块 | `preview_text`（优先） | 有就用，否则 `content.split('\n').first` | **不去 `#`、不跳空行** |

同一个 Atom 在不同视图显示不同的"名字"，用户无法建立一致的心智模型。

**裁决**：

新增 `title: String` 字段，存储在 Atom 上，永远非空，永远是纯文本。

- **title 是"这个东西叫什么"** — Tab 栏、Explorer、Task 列表、Calendar 全部读同一个字段
- **preview_text 是"这个东西里面长什么样"** — 列表卡片的次级摘要区域，灰色小字

**title 写入策略**（按 content_type 区分）：

| content_type | title 来源 | content 更新时 |
|---|---|---|
| `markdown` | 自动推导：content 第一非空行，去 `#`，截取 50 字符 | 自动重新推导并覆盖 |
| `canvas` | 用户命名，默认 "Untitled" | 不自动更新（content 是 JSON） |
| `conversation` | 自动推导：第一条用户 prompt 截断 | 不自动更新（保持首次 prompt） |
| `plugin:<id>` | 插件提供 | 插件决定 |

- markdown 的 title 永远 = content 第一行的推导结果，不支持手动覆盖 Atom 本体的 title
- 用户想给引用起别名 → 使用 atom_ref 的 `display_name`（节点级别名，不影响 Atom 本体）
- title 推导逻辑从 Flutter 下沉到 Rust Core，在 `note_create` / `note_update` 时写入

**各视图消费规则**：

| 视图 | 显示什么 | 次级信息 |
|---|---|---|
| Tab 栏 | `atom.title` | — |
| Editor 标题 | `atom.title` | — |
| Explorer atom_ref | `display_name`（如用户设置）否则 `atom.title` | — |
| Explorer folder | `display_name`（用户设置） | — |
| Task 列表 | `atom.title` | 时间标签（deadline/进行中） |
| Calendar 事件块 | `atom.title` | `preview_text`（摘要） |
| Note 列表卡片 | `atom.title` | `preview_text` + `preview_image` |

**`preview_text` 回归本职**：仅作为列表摘要（灰色次级文本），不再被当 title 使用。

#### R9. 新增 `icon` 字段

新增 `icon: Option<String>` 字段，存储 emoji 或图标标识符。

- 纯视觉元数据，跟 content / content_type 无关
- 所有视图的 title 旁显示（Explorer、Tab 栏、Task 列表、Calendar）
- NULL = 无 icon，使用 view_hint 默认图标
- 用户通过列表项的快捷操作设置，无需打开 Editor

#### R10. 新增 `cover_image` 字段，与 `preview_image` 分离

新增 `cover_image: Option<String>` 字段，用户显式设置的封面图。

**`cover_image` vs `preview_image` 的区别**：

| | cover_image | preview_image |
|---|---|---|
| 来源 | 用户显式设置 | 自动推导（markdown 第一张图、canvas 缩略图等） |
| content_type 依赖 | 无，任何类型都能有封面 | 推导逻辑依赖 content_type |
| 用户可控 | 是（add image 操作） | 否（系统自动维护） |

**列表渲染优先级**：`cover_image`（用户设置）> `preview_image`（自动推导）> NULL

用户在列表视图点"add image"= 设置 `cover_image`，不修改 content。

#### R11. Comment 语义冻结，实现推迟

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
- 独立实体方案（方案 C）是最终正确答案：content_type 无关（canvas 也能加 comment）、可独立查询分页、未来可扩展协作
- 当前如有临时需求，可在 Flutter 层用追加 content 的方式过渡，但不作为正式设计

**冻结**：语义已定义，实现排入 v0.4+。

#### R12. Spatial Canvas 预留框架

**借鉴来源**：AFFiNE/BlockSuite edgeless mode — 同一引擎支持文档和画布两种模式。

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

`atom_embed` 是画布的一种高级元素类型 — 在画布上嵌入另一个 Atom 的预览卡片。与 atom_ref（R5）的区别：

- `atom_embed`：内容层的空间嵌入 — "这个画布上放了哪个 Atom，在什么位置"
- `atom_ref`：组织层的结构引用 — "这个 Atom 出现在哪些文件夹里"
- 两者独立，不互斥。同一个 Atom 可以同时在文件夹里（atom_ref）和画布上（atom_embed）

**场景 B：Spatial Workspace View**

Explorer 树视图的空间化替代 — 文件夹内容以卡片形式在画布上空间布局，支持直觉式拖拽操作。

空间坐标存储：在 `workspace_nodes` 表上添加 nullable 的 `spatial_x REAL, spatial_y REAL` 列。仅当用户在 spatial view 中布局过才有值；NULL = 使用自动布局。

与场景 A 的关系：复用同一个 Canvas 渲染引擎（viewport 缩放平移、元素定位），但数据源不同 — 场景 A 读 Atom.content JSON，场景 B 读文件夹的 atom_refs 并渲染为 Atom 卡片。

**反向查询预留**：

场景 A 的 atom_embed 需要反向索引（"哪些画布包含了这个 Atom？"）。预留 `canvas_atom_embeds(canvas_atom_id, embedded_atom_id)` 派生索引表概念，在 canvas 保存时自动维护。此表在 canvas 实际实现时通过新 migration 创建。

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

#### R13. Conversation 内容类型预留

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

**需解决的设计问题**（留占位，v0.4+ 设计时展开）：

1. **Atom 引用上下文** — 对话能引用其他 Atom 作为 LLM 上下文（"帮我总结这篇笔记"）`[待设计]`
2. **对话产生 Atom** — AI 建议创建 task/event，用户确认后自动生成 `[待设计]`
3. **长对话增长** — content JSON 无限增长的分页/归档策略 `[待设计]`
4. **Extension 集成** — LLM provider 作为 extension，对话通过 extension API 调用 `[待设计]`

**实施排期**：v0.4+，依赖 S2 Phase 3（EditorResolver）和 extension kernel 运行时。

### 理由

1. **产品愿景对齐**：「最小摩擦的个人第二大脑」要求用户不需要预先决定类型。Atom 容器模型 + 自动推导 view_hint 消除了「选错类型」的摩擦
2. **数据模型简洁**：六个独立维度（identity、carrier、scheduling、actionability、workspace、annotation）各自正交，组合完全合法，数据层不拒绝任何组合
3. **渲染层有确定性**：完整行为矩阵消除了 type × time × status 的未定义场景
4. **性能可保证**：view_hint、title 作为 materialized fields 存储在 DB 中，查询和渲染可利用索引，无需每次动态计算
5. **全局一致性**：title 作为唯一名称源，所有视图读同一个字段，消除了四套推导逻辑的不一致
6. **content_type 正交**：title、icon、cover_image 均独立于 content_type，canvas/conversation/plugin 类型的 Atom 也有完整的身份层
7. **未来可扩展**：content_type 预留了 canvas/conversation/plugin 载体；atom_ref 多引用支持知识网络；指定默认路径可由用户自定义配置；comment 语义已冻结待实现
8. **向后兼容**：当前 `type` 字段语义不变（重命名为 view_hint），现有数据无需迁移（现有 type 值即为合法的 view_hint 值）；新增字段均为 nullable 或有默认值
9. **Canvas 双场景复用**：Canvas Atom（内容创作）和 Spatial Workspace View（空间组织）共享同一渲染引擎，避免重复建设；基础元素优先（shape/text/image/connector），atom_embed 等高级功能按需迭代
10. **双结构务实**：markdown 和 canvas 保持独立内容结构（v0.5+ 评估统一），避免过早引入 block tree 抽象的复杂度；Core 层统一视为 opaque string，零改动成本

---

## S2: Tab/Draft/Save 状态归属

### 背景

#### 当前双状态问题

存在两套重叠的状态系统，通过 ~260 行的 WP Bridge 代码同步：

```
NotesCoordinator (source of truth)          WorkspaceProvider (legacy copy)
├── NoteTabManager: tab 状态                ├── _openTabsByPane: tab 状态（副本）
├── NoteDraftManager: draft 状态            ├── _buffersByNoteId: draft 状态（副本）
├── NoteSaveTracker: save 状态              ├── _saveStateByNoteId: save 状态（副本）
└──── WP Bridge（~260行）同步 ─────────►   └── notifyListeners() → UI
```

**各状态的用户可见效果**：

| 状态 | 用户看到什么 | Coordinator 侧 | WorkspaceProvider 侧（副本） |
|---|---|---|---|
| **Tab 列表** | 顶部标签栏里有哪些标签、哪个高亮 | `NoteTabManager._openNoteIds`（扁平列表） | `_openTabsByPane`（按 pane 分组）+ `_activeTabByPane` |
| **Draft 缓冲区** | 编辑器里实时显示的文字内容 | `NoteDraftManager._draftContentByAtomId` + `_persistedContentByAtomId` | `WorkspaceNoteBuffer { persistedContent, draftContent, version }` |
| **Save 状态** | 保存指示器：● Unsaved / ↻ Saving / ✓ Saved / ✗ Failed | `NoteSaveTracker._noteSaveState`（仅 active note） | `_saveStateByNoteId`（所有 note） |
| **Pane 布局** | 分了几个窗格、各占多宽 | 不管（委托 WP） | `_layoutState { paneOrder, paneFractions, splitDirection }` |

UI 层（`NotesPage`）读 WorkspaceProvider，不读 coordinator/managers。`note_content_area.dart` 已迁移为直接读 coordinator。

Report 07 方案：迁移 NotesPage 等消费者直接读 coordinator → 删除 WP bridge → 删除或缩减 WorkspaceProvider 至仅保留 pane 布局常量。

#### 更深层的架构问题

Report 07 方案仅解决双状态问题，但 S1 裁决暴露了一个更根本的问题：**tab/draft/save 管理不应该住在 `features/notes/` 里。**

S1 R1 定义 Atom 是泛型容器：Task（有 markdown content）、Event（有 markdown content）、Canvas Atom、Conversation Atom 都应该能打开在 tab 里编辑。让 `features/notes/` 的 coordinator 管全局编辑器状态，违反了 VSCode 验证的正确分层：

```
VSCode 编辑器架构（参考）:

┌─────────────────────────────────────────────────────┐
│ Workbench Layout (SerializableGrid)                 │  ← 纯布局层
│  ┌──────────────────┐  ┌──────────────────┐         │
│  │ EditorGroup A    │  │ EditorGroup B    │         │  ← 分组层：每个 group 独立管 tab
│  │ ┌──┬──┬──┐       │  │ ┌──┐             │         │
│  │ │T1│T2│T3│       │  │ │T4│             │         │
│  │ └──┴──┴──┘       │  │ └──┘             │         │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │         │
│  │ │ EditorPane   │ │  │ │ EditorPane   │ │         │  ← 编辑器层：按 input 类型选渲染器
│  │ └──────────────┘ │  │ └──────────────┘ │         │
│  └──────────────────┘  └──────────────────┘         │
└─────────────────────────────────────────────────────┘

关键设计原则：
1. EditorService 是 workbench 级全局服务，不属于任何 feature
2. EditorInput 是泛型的（.ts / .png / diff / settings 都是 EditorInput）
3. Dirty/save 状态跟 EditorInput 走，不跟 group 走
4. EditorResolverService 根据 input 类型匹配渲染器
```

**LazyNote 当前 vs VSCode 对标**：

| VSCode | LazyNote 当前 | 差距 |
|---|---|---|
| `EditorService`（workbench 级） | 不存在，散落在 coordinator + WP | 缺少顶层协调 |
| `EditorGroupsService` | `WorkspaceProvider`（部分） | 混杂了 tab/buffer/save |
| `EditorGroupModel` | `_openTabsByPane`（WP 内部） | 无独立抽象 |
| `EditorInput`（泛型） | `NoteItem`（仅 notes） | 不支持 task/event/canvas |
| `EditorPane`（按类型选渲染器） | `NoteContentArea`（仅 markdown） | 无动态选择 |
| `EditorResolverService` | 不存在 | 无 content_type → 渲染器映射 |

### 选项

**A. 仅执行 Report 07 方案**：删 WP bridge，coordinator 成为唯一源，WorkspaceProvider 缩减到仅 pane 布局。不考虑 S1 带来的泛型需求。

**B. 完整目标架构 + 分阶段实施**：定义对标 VSCode 的 EditorShellService 目标架构，v0.2.5 做第一步（消除双状态），v0.3 做第二步（提升到 workbench 级 + 泛型 EditorInput）。

**C. 保持现状，全部推迟到 v0.3**：接受双重状态，v0.3 一步到位重写。

### 裁决

**采用 B — 完整目标架构 + 分阶段实施。**

#### 目标架构（v0.3 完成）

```
┌──────────────────────────────────────────────────────┐
│ EditorShellService（workbench 级，lib/core/ 或         │
│                     lib/features/editor_shell/）      │
│                                                      │
│ ┌─ GroupLayout ────────────────────────────────────┐  │
│ │ pane 空间排列、分割、缩放                          │  │  ← 从 WorkspaceProvider 提取
│ │ paneOrder, paneFractions, splitDirection          │  │
│ └──────────────────────────────────────────────────┘  │
│                                                      │
│ ┌─ EditorGroupModel[] ────────────────────────────┐  │
│ │ 每个 pane 的 tab 列表 + active tab + preview tab  │  │  ← 从 WP._openTabsByPane +
│ │ 独立于 pane 布局，可序列化                         │  │     NoteTabManager 合并提取
│ └──────────────────────────────────────────────────┘  │
│                                                      │
│ ┌─ DraftManager ──────────────────────────────────┐  │
│ │ 所有打开 Atom 的缓冲区                             │  │  ← 从 NoteDraftManager 提升
│ │ { atomId → { draftContent, persistedContent,     │  │     不再局限于 notes
│ │              version } }                         │  │
│ └──────────────────────────────────────────────────┘  │
│                                                      │
│ ┌─ SaveTracker ───────────────────────────────────┐  │
│ │ 所有打开 Atom 的保存状态                           │  │  ← 从 NoteSaveTracker 提升
│ │ { atomId → clean | dirty | saving | error }     │  │     + per-atom 防抖 timer
│ └──────────────────────────────────────────────────┘  │
│                                                      │
│ ┌─ EditorResolver ────────────────────────────────┐  │
│ │ content_type → EditorPane 映射                    │  │  ← 新建
│ │ markdown → MarkdownEditorPane                    │  │
│ │ canvas   → CanvasEditorPane（未来）               │  │
│ │ conversation → ConversationPane（未来）           │  │
│ │ plugin:* → PluginEditorPane（未来）               │  │
│ └──────────────────────────────────────────────────┘  │
│                                                      │
│ notifyListeners() ─────────────────────────────────► UI
└──────────────────────────────────────────────────────┘

features/notes/ 缩减为：
├── note 列表查询 + 过滤
├── note 创建
├── note explorer tree
└── 不再管 tab、draft、save
```

#### 分阶段实施

**Phase 1 — v0.2.5：消除双状态（PR-0257 范围内）**

| 步骤 | 内容 | 删除量 |
|---|---|---|
| 1 | 迁移 `NotesPage` 的 ~5 个消费点从读 WP 改为读 coordinator | 改 ~30 行 |
| 2 | 删除 `_syncWorkspaceFromControllerState()` + `_syncWorkspaceActiveSnapshot()` | 删 ~70 行 |
| 3 | 删除 `_WorkspaceProviderPort` adapter | 删 ~85 行 |
| 4 | 删除辅助映射方法 | 删 ~100 行 |
| 5 | WorkspaceProvider 缩减到仅保留 pane 布局（`splitActivePane` / `closeActivePane` / `layoutState`） | WP 从 665 行缩至 ~200 行 |

Phase 1 结束后：coordinator 是唯一状态源，WP Bridge 完全删除，WorkspaceProvider 仅管 pane 布局。

**Phase 2 — v0.3 PR-0301：提升到 workbench 级**

| 步骤 | 内容 |
|---|---|
| 1 | 新建 `EditorShellService`（workbench 级），从 coordinator 提取 `NoteTabManager` → `EditorGroupModel[]`，从 coordinator 提取 `NoteDraftManager` → `DraftManager`，从 coordinator 提取 `NoteSaveTracker` → `SaveTracker` |
| 2 | WorkspaceProvider 的 pane 布局提取为 `GroupLayout`，合并入 `EditorShellService` |
| 3 | `NoteTabManager._openNoteIds`（扁平列表）改为 per-group tab 列表，直接支持多 pane |
| 4 | Tab 列表改为接受任意 Atom UUID（不仅 note），DraftManager/SaveTracker 同步泛化 |
| 5 | 删除 WorkspaceProvider（完全被 EditorShellService 取代） |

**Phase 3 — v0.3 PR-0301+：EditorResolver**

| 步骤 | 内容 |
|---|---|
| 1 | 新建 `EditorResolver`，根据 Atom 的 `content_type` 选择 `EditorPane` |
| 2 | 当前 `NoteContentArea` 重命名为 `MarkdownEditorPane`，注册为 `markdown` 的渲染器 |
| 3 | 未来 canvas/conversation/plugin 各注册自己的 `EditorPane` |

### 理由

1. **S1 对齐**：S1 R1 定义 Atom 是泛型容器，任何 Atom 都可打开编辑。tab/draft/save 住在 `features/notes/` 里与此矛盾
2. **参考验证**：VSCode 的 EditorService/EditorGroupsService 分层经过大规模验证，三层职责（布局/分组/编辑器）分离清晰
3. **v0.2.5 有实际收益**：Phase 1 删除 bridge 消除 ~260 行同步代码和双状态 bug 风险，独立于后续 phase 有价值
4. **v0.3 不需要重做**：Phase 1 的 coordinator 单源状态是 Phase 2 提取的正确起点，不存在"先做再拆"的浪费
5. **渐进可验证**：每个 phase 结束后系统都可运行、可测试，不需要一次性大爆炸重写

---

## S3: Tag × Workspace Tree 交互

### 背景

当前 NoteExplorer 面板同时展示：
- **TagFilter**：tag 芯片列表，选中 tag 后过滤扁平笔记列表
- **Workspace Tree**：文件夹/note_ref 层级结构

两者**独立工作** — 选中 tag 不会过滤 tree 中的 note_ref。用户可能预期一致行为。

Tag 挂在 Atom 上，note_ref 引用 Atom。理论上可以通过 note_ref → atom_id → atom tags 实现 tree 过滤，但当前 `WorkspaceTreeChildrenLoader` 无此逻辑。

### 选项

**A. 保持独立（明确声明）**：Tag 过滤仅影响扁平列表视图。Tree 视图始终展示完整结构。在 UI 上通过视觉区分（如 tab/toggle 切换列表视图和树视图）消除歧义。

**B. Tree 响应 tag 过滤**：选中 tag 后，tree 中不含该 tag 的 note_ref 被灰显或隐藏。需要新增 tree 过滤逻辑。

**C. 分离面板**：Tag 过滤和 Workspace Tree 不在同一面板中，彻底避免交互歧义。

### 裁决

**Tag 与 Explorer（Workspace Tree）完全独立，渐进式合并视图。**

#### 核心语义：两个正交维度

| 维度 | Tag | Explorer（Workspace Tree） |
|---|---|---|
| 本质 | **语义分类**（查询驱动） | **结构归档**（用户组织） |
| 数据源 | `atom_tags` 表（Atom × Tag 多对多） | `workspace_nodes` 表（atom_ref 层级结构） |
| 结果 | 符合条件的 Atom 扁平列表 | 用户手动组织的层级树 |
| 操作 | 过滤、排序、聚合 | 拖拽、移动、重命名、嵌套 |
| 类比 | Gmail 标签 / Obsidian 标签搜索 | macOS Finder 文件夹 / Obsidian 文件树 |

Tag 不影响 Explorer tree 的完整性。Explorer 始终展示用户组织的全部结构。

#### 指定默认文件夹与 Explorer 的关系

指定默认路径文件夹（S1 R6 修订）是**普通文件夹**，与用户手动创建的文件夹在 Explorer 中平等显示：

```
Explorer（Workspace Tree）
├── 📁 Tasks/           ← 指定为 Tasks 视图默认路径（普通文件夹）
│   └── 📄 ...
├── 📁 Calendar/        ← 指定为 Calendar 视图默认路径（普通文件夹）
│   └── 📄 ...
├── 📄 未归档 Atom      ← atom_ref, parent=NULL（根级别 = "未分类"）
├── 📁 用户文件夹 A/
│   └── ...
└── 📁 用户文件夹 B/
    └── ...
```

所有文件夹**不受 tag 选择影响**。Tag 过滤只影响 tag 自身的查询结果面板。

#### Tag 查询结果展示

Tag 选择后展示独立的 Atom 列表，每个条目显示：

```
[icon] Atom.title
       📁 文件夹A / 子文件夹B          ← atom_ref 路径面包屑
```

- 面包屑来自该 Atom 的 atom_ref 路径（如有多个 ref，显示主引用或全部）
- 根级别 atom_ref 的 Atom 显示 "根目录"（所有 Atom 必有 atom_ref，见 S1 R5 修订）
- 列表支持点击直接打开 Atom 编辑

#### 渐进实施方案：Phase A → Phase B

**Phase A — 独立面板（v0.2.5 语义定义，v0.3 实现）**

Tag 查询结果作为独立面板，展开后将 Explorer 下推：

```
┌─────────────────────┐
│ [Tag A] [Tag B] ... │  ← tag 芯片栏
├─────────────────────┤
│ Tag "Tag A" 结果     │  ← 独立结果面板（选中 tag 时展开）
│ ├── Atom X  📁A/B   │
│ ├── Atom Y  📁根目录 │
│ └── Atom Z  📁C     │
├─────────────────────┤
│ Explorer             │  ← 被下推，仍完整可见（可折叠）
│ ├── 📁 Tasks/       │
│ ├── 📁 文件夹A/     │
│ └── ...              │
└─────────────────────┘
```

- Tag 取消选择 → 结果面板收起，Explorer 恢复完整高度
- Tag 结果面板和 Explorer 互不影响内部状态

**Phase B — 视图替换（v0.3+ 优化）**

Phase A 稳定后，Tag 查询结果直接替换 Explorer 视图区域：

```
┌─────────────────────┐
│ [Tag A] [Tag B] ... │  ← tag 芯片栏
├─────────────────────┤
│ Tag "Tag A" 结果     │  ← 替换 Explorer 视图（选中 tag 时）
│ ├── Atom X  📁A/B   │
│ ├── Atom Y  📁根目录 │
│ └── Atom Z  📁C     │
│                     │
│ （Explorer 被替换）  │
└─────────────────────┘
```

- 取消 tag 选择 → 恢复 Explorer 视图
- 本质是 Phase A 的 UI 优化：结果面板从"下推"变为"替换"，逻辑不变

Phase B 是 Phase A 的自然进阶，不需要架构变更，仅调整布局行为。

#### 未来：三种 Explorer 视图模式

| 模式 | 触发 | 内容 |
|---|---|---|
| **Tree**（默认） | 无 tag 选中 | 完整 workspace tree（文件夹 + atom_ref） |
| **List**（Tag 查询） | 选中 tag | 扁平 Atom 列表 + 目录面包屑 |
| **Spatial**（R12 场景 B） | 用户切换视图模式 | 文件夹内容空间化布局（v0.4+） |

三种模式共享同一面板区域，互斥切换。

#### v0.2.5 范围

**仅定义语义**，不改动代码。当前 tag filter + explorer 独立工作的行为**符合目标语义**（Phase A 的前置状态）。v0.3 实现 Phase A 的 tag 查询结果面板和面包屑。

### 理由

1. **正交性**：Tag（语义分类）和 Explorer（结构归档）是两个独立维度。让 tag 过滤 tree 会混淆两种组织模型，Apple Notes 和 Obsidian 均验证了分离方案的正确性
2. **文件夹独立性**：所有文件夹（包括指定默认路径文件夹）都不受 tag 选择影响。tag 查询和 Explorer 结构是完全正交的维度
3. **目录面包屑**：tag 查询结果附带 atom_ref 路径面包屑，让用户在 tag 视图中也能看到结构位置，弥补了扁平列表缺乏上下文的问题
4. **渐进实施低风险**：Phase A（独立面板）→ Phase B（视图替换）是 UI 布局的渐进优化，不涉及架构变更。Phase A 本身就是完整可用的方案
5. **未来三视图扩展**：tree/list/spatial 三种视图模式的框架为 R12 Spatial Workspace View 预留了自然集成点

---

## S4: Note 创建入口语义

### 背景

#### 原始问题：两条创建路径

- **路径 A（头部按钮）**：创建空 Atom → 自动应用当前 tag → 不挂载到 tree → 成为"未分类"笔记
- **路径 B（右键菜单 "在文件夹中创建"）**：创建空 Atom → 创建 note_ref 挂载到指定文件夹 → 不自动应用 tag

两条路径使用相同的 `note_create` FFI 调用，差异在 Flutter 层的后续操作（是否创建 workspace tree 链接、是否应用 tag）。

#### 更深层问题：atom_ref 强制性与 Smart Folder 本质

讨论中发现原始问题的根源不是"两条路径语义不同"，而是三个更根本的架构问题：

1. **路径 A 不创建 atom_ref** → Atom 成为"组织孤儿"，无法在 Explorer 中操作（右键、拖拽、移动均不可用）
2. **Smart Folder 作为查询虚拟视图的模型** → 虚拟视图中的 Atom 没有 atom_ref，导致需要两套操作逻辑（atom_ref 操作 vs Atom 本体操作）
3. **"Uncategorized"作为零 ref 查询** → 用户无法对 Uncategorized 中的 Atom 进行文件夹级操作

### 选项

**A. 保持当前设计（明确文档化）**：两条路径代表不同的用户意图 — 快速记录 vs 有组织归档。在语义文档中明确声明差异和理由。

**B. 统一为双步骤**：任何创建都先创建 Atom，然后提供可选的「归档到文件夹」和「应用 tag」步骤。

**C. 自动推断**：如果当前聚焦在某个文件夹上，头部创建也自动挂载到该文件夹。

**D. atom_ref 强制伴随 + Smart Folder 重定义**：所有创建路径必须产出 atom_ref，Smart Folder 从查询虚拟视图改为指定默认路径的普通文件夹。

### 裁决

**采用 D — atom_ref 强制伴随 Atom 创建，Smart Folder 重定义为指定默认路径文件夹。**

此裁决的核心内容已写入 S1 R5（强制伴随）和 S1 R6（指定默认路径模型）修订中。S4 补充创建路径路由和操作模型。

#### atom_ref 强制伴随

**核心规则**：Atom 因 ref 而存在。没有 atom_ref 的 Atom 等于"坏死的原子" — 看得见但无法操作、无法转移。

所有创建路径统一为：`创建 Atom` + `创建 atom_ref（落到指定位置）`。不存在"只创建 Atom 不创建 ref"的路径。

#### 创建路径路由

| 创建上下文 | atom_ref 目标 | 附加行为 |
|---|---|---|
| 文件夹内右键创建 | 该文件夹 | — |
| Tasks 视图创建 | Tasks 指定文件夹 | 自动设置 `task_status` |
| Calendar 视图创建 | Calendar 指定文件夹 | 自动设置 time fields |
| 头部按钮（Tag 已选中） | 根级别 | 自动应用当前 tag |
| 头部按钮（无上下文） | 根级别 | — |
| Single Entry 命令 | 按命令类型路由到对应指定文件夹 | 按命令设置属性 |

创建路径的差异从"是否产出 atom_ref"变为"atom_ref 落在哪里 + 附加什么属性"。

#### Smart Folder → 指定默认路径文件夹

**重定义**（同步修订 S1 R6）：

- Smart Folder **不是**查询驱动的虚拟视图，**是**指定了默认创建路径的普通文件夹
- 与用户手动创建的文件夹在结构上完全相同，支持重命名、移动、删除
- "Smart" 的含义仅在于：它被指定为某个视图的默认落地路径
- 指定关系是配置层映射（类似 app 指定缓存目录），不是文件夹本身的特殊属性

**视图与文件夹的正交性**：

| | Tasks 视图 | Tasks 文件夹 |
|---|---|---|
| 驱动 | 属性查询（`task_status IS NOT NULL`） | 结构组织（atom_ref 的 `parent_uuid`） |
| 一个在、另一个不在 | 正常（用户可能把 task 移到了 /Work/） | 正常（文件夹里可以有非 task atom） |

视图和文件夹不保持同步。指定文件夹仅影响**创建时的默认路由**，不影响之后的查询和组织。

#### 指定文件夹生命周期

- **删除指定文件夹** → 内部 atom_ref 回归根级别 + 清除指定配置 + 后续创建落到根级别
- **重新指定文件夹** → 根级别中匹配属性的 atom_ref 一次性迁移到新文件夹（不动用户已手动归档到其他文件夹的 atom）
- **不设指定文件夹** → 对应视图创建的 atom 落到根级别（合法状态）

#### "未分类" = 根级别

`parent_uuid = NULL` 的 atom_ref 即为"未分类"。不需要单独的 Uncategorized 文件夹或 Smart Folder — 根级别本身就是默认归属地。

#### v0.2.5 范围

**语义定义 + S1 R5/R6 修订**。不改动创建路径代码。当前路径 A（不创建 atom_ref）的行为在 v0.3 修正为自动创建根级别 atom_ref。

### 理由

1. **消除组织孤儿**：无 atom_ref 的 Atom 无法在 Explorer 中被看到和操作，等同于"坏死的原子"。强制伴随保证每个 Atom 都有 tree 位置和完整操作能力
2. **统一操作路径**：所有操作（移动、复制、删除）统一作用于 atom_ref，一套代码逻辑。避免 Atom 本体操作和 atom_ref 操作两套代码的维护成本
3. **Smart Folder 简化**：从查询驱动虚拟视图改为普通文件夹 + 指定路径配置。消除了"虚拟视图需要特殊操作逻辑"的复杂度
4. **最小摩擦**：用户无需理解"Atom"和"atom_ref"的区别。每个可见条目都有完整的右键菜单和拖拽能力，无论出现在哪个视图
5. **与 S1 一致**：S1 R1 定义 Atom 是容器，组织层（workspace）是容器的必备维度。没有组织位置的容器是不完整的
6. **视图-文件夹正交**：视图（属性查询驱动）和文件夹（结构组织驱动）完全正交。指定默认路径仅影响创建路由，不引入运行时耦合

---

## S5: Extension Kernel → Flutter 命令系统桥接

### 背景

Rust Core 的 Extension Kernel 定义了四种集成能力：
- `command` — 命令注册
- `parser` — 输入解析
- `provider` — 同步提供者
- `ui_slot` — UI 扩展槽

Flutter 端现有的命令基础设施：
- `CommandParser`：解析 `> ` 前缀的命令文本
- `CommandRouter`：路由已解析的命令到处理器
- `CommandRegistry`：注册可用命令

两套系统之间**无任何文档化的映射关系**。v0.3 PR-0310 要求将 first-party 命令/解析器迁移为注册式插件形态，需要这个桥接定义。

### 选项

**A. Flutter 命令系统作为 Extension Kernel `command`/`parser` 能力的 runtime host**：Flutter 的 CommandRegistry 就是 extension kernel 的 command 能力的运行时载体。PR-0310 将现有命令注册迁移为基于 manifest 的注册。

**B. 双层模型**：Extension Kernel 的能力声明留在 Rust Core（manifest 验证、权限守卫），Flutter 的命令系统作为独立的 UI 层命令分发。两者通过 FFI 桥接特定操作。

**C. 推迟定义到 v0.3 PR-0310 实现时**：当前仅记录问题存在，具体桥接方案在 PR-0310 设计阶段决定。

### 裁决

`[待讨论]`

### 理由

（待填充）

---

## S6: Provider SPI → external_mappings 交互

### 背景

- `ProviderSpi` trait 定义了 `auth`/`pull`/`push`/`conflict_map` 四个操作
- `external_mappings` 表（Migration 3）存储 `provider_id`/`external_id`/`atom_uuid` 映射
- 两者各自存在但**交互路径未指定** — provider 实现如何读写 external_mappings 表没有文档

v0.3 PR-0309（Google Calendar Provider）是第一个真实实现，需要这个交互规范。

### 选项

**A. Provider 通过 repo 层访问 external_mappings**：定义 `ExternalMappingRepository` 接口，provider 实现注入该 repo 来读写映射。

**B. external_mappings 操作内嵌在 pull/push 流程中**：`pull` 返回的数据自动更新 mappings，`push` 时自动查询 mappings。provider 实现不直接接触 mappings 表。

**C. 推迟到 v0.3 PR-0309 设计阶段**：当前仅记录问题，PR-0309 的设计文档中详细定义。

### 裁决

`[待讨论]`

### 理由

（待填充）

---

## S7: Reminders 模块定位

### 背景

`features/reminders/` 包含 `ReminderScheduler` 和 `ReminderService`，提供本地通知调度能力。当前被 `calendar_controller.dart` 和 `tasks_controller.dart` 直接导入（2 处 Rule E 违规）。

Reminders 的使用模式更接近 **cross-cutting infrastructure**（类似 logging、l10n）而非 **feature-to-feature business dependency**。

### 选项

**A. 声明为基础设施模块，Rule E 豁免（推荐）**：将 reminders 从 `features/` 迁移到 `lib/shared/` 或 `lib/core/`，正式声明为基础设施。或在 `features/` 中保留但在 engineering-standards.md 中添加 Rule E 豁免条款。

**B. 抽象为接口注入**：定义 `ReminderPort` 接口，calendar/tasks 通过构造器注入接收实现，消除直接导入。

**C. 通过 Core API 暴露**：将提醒调度逻辑下沉到 Rust Core（如果平台 API 允许），通过 FFI 调用。

### 裁决

`[待讨论]`

### 理由

（待填充）

---

## S8: NoteItem / AtomListItem 类型统一

### 背景

`ffi-contracts.md` 中记录：
- `NoteItem` / `NotesListResponse` — 笔记相关查询返回
- `AtomListItem` / `AtomListResponse` — 任务/日历相关查询返回

文档标注「两套类型共存直到 v0.2 统一」。v0.2 已过（当前 v0.2.5），需确认统一是否完成。

### 选项

**A. 已完成统一（仅需更新文档）**：如果实际代码中 NoteItem 已被替换或两者已对齐，更新 ffi-contracts.md 即可。

**B. 尚未统一，在 v0.2.5 执行**：合并两套类型为统一的 Atom 响应类型。可能涉及 FFI 签名变更。

**C. 保持共存，明确各自职责**：两套类型服务不同查询场景（note 查询返回 tags/preview，atom 查询不含 tags），文档化差异并移除「统一」标注。

### 裁决

`[待讨论]`

### 理由

（待填充）
