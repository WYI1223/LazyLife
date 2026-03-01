# DI-10: EditorResolver 壳设计

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** |
| **关联决策点** | S2 Phase 3 |
| **阻塞 PR** | PR-0301B（间接）、PR-0311（间接） |
| **前置依赖** | DI-1（EditorShellService 接口已 RESOLVED） |
| **来源** | S2 Phase 3 + S1 R2 content_type 体系 |

---

## 问题提取

### 来源 S2 Phase 3

> 1. 新建 `EditorResolver`，根据 Atom 的 `content_type` 选择 `EditorPane`
> 2. 当前 `NoteContentArea` 重命名为 `MarkdownEditorPane`，注册为 `markdown` 渲染器
> 3. 未来 canvas/conversation/plugin 各注册自己的 `EditorPane`

### 来源 S1 R2 content_type

> content_type 定义了 Atom 的存储格式：`markdown`（默认）、`canvas`、`conversation`、`plugin:<id>`。
> Core 按 opaque string 存取，UI 按 content_type 选择编辑器和渲染器。

### v0.3 范围

v0.3 只有 `markdown` 一种 content_type 有实际实现。EditorResolver 在 v0.3 中的职责是：

1. 建立 `contentType → EditorPane` 注册机制
2. 注册 `MarkdownEditorPane` 作为唯一实现
3. 为 v0.4+ 的 canvas/conversation/plugin 预留扩展点

---

## 设计原则：职责边界

### 三层分离

```
EditorShellService    — 状态管理 (groups, buffers, layout)
        ↓ 提供 EditBuffer
EditorResolver        — 编辑器选择 (content_type → EditorPane widget)
        ↓ 返回 widget builder
Feature Chrome        — 外壳展示 (loading/error/metadata 由 feature controller 处理)
```

EditorResolver **只负责中间层**：给定一个 EditBuffer，返回正确的编辑器 widget。它不管 chrome（loading 占位、error 横幅、breadcrumb、save 状态、tags 等），chrome 留在 feature controller 层。

### 当前 NoteContentArea 的拆分

当前 `NoteContentArea`（346 行）实际做了两层事情：

| 层 | 内容 | 归属 |
|---|------|------|
| Feature Chrome | loading/error 状态、breadcrumb、save 横幅、metadata chips、tags | 保留在 notes feature |
| 编辑核心 | NoteEditor（markdown 编辑） | 提取为 `MarkdownEditorPane`，注册到 EditorResolver |

---

## Q1 裁决：EditorPane 接口

```dart
typedef EditorPaneBuilder = Widget Function(
  BuildContext context,
  EditBuffer buffer,
);
```

### 参数说明

| 参数 | 提供的信息 |
|------|----------|
| `context` | Flutter 主题、locale、MediaQuery 等 |
| `buffer.content` | 当前内容（opaque string，由 EditorPane 按自己的格式解析） |
| `buffer.edit(newContent)` | 写入变更 |
| `buffer.atomId` | Atom 身份标识 |
| `buffer.saveState` | 保存状态（编辑器可选择展示保存指示） |

### 不传入的参数

| 不传入 | 理由 |
|--------|------|
| `EditorGroupModel` | pane 状态，编辑器不关心自己在哪个 pane |
| atom metadata（title, tags） | chrome 层的事，由 feature controller 处理 |
| `NotesCoordinator` | 编辑器应对 feature 层无感知 |

### 不同 content_type 的渲染差异完全封装在 EditorPane 内部

| content_type | 渲染范式 | 交互模型 | 内容格式 |
|---|---|---|---|
| markdown | 文本编辑器 — 单一文本流 + 格式化 | 键入、选中文本、格式快捷键 | 纯 markdown 文本 |
| canvas | 空间画布 — 2D 平面上的定位元素 | 拖拽、缩放、绘制、框选 | JSON（元素 + 坐标） |
| conversation | 消息列表 — 顺序消息 + 输入框 | 滚动、发送、编辑/删除 | JSON（消息数组） |

每个 EditorPane 自己负责：

1. 解析 `buffer.content`（按自己的格式：markdown 文本 / canvas JSON / 消息 JSON）
2. 用自己的渲染引擎展示（TextField / CustomPainter / ListView）
3. 用户变更时序列化回 string，调用 `buffer.edit()`

三种引擎之间几乎没有共享渲染逻辑（undo 机制、工具栏、选区模型均不同），差异由 EditorPane 内部封装，不泄漏到 Resolver 接口。

---

## Q2 裁决：注册协议 — 静态 Map + register()

```dart
class EditorResolver {
  final Map<String, EditorPaneBuilder> _registry = {};

  void register(String contentType, EditorPaneBuilder builder) {
    _registry[contentType] = builder;
  }

  EditorPaneBuilder resolve(String contentType) {
    return _registry[contentType] ?? _unknownTypePlaceholder;
  }
}
```

v0.3 启动时：

```dart
resolver.register('markdown', (context, buffer) => MarkdownEditorPane(buffer: buffer));
```

### 理由

- v0.3 只需静态注册，够用
- `plugin:<id>` 动态注册时，同一个 `register()` 接口自然支持
- 不需要 Flutter Provider pattern — EditorResolver 是 EditorShellService 的成员，不需要独立注入

---

## Q3 裁决：Fallback — 错误占位，不 fallback 到 markdown

```dart
static Widget _unknownTypePlaceholder(BuildContext context, EditBuffer buffer) {
  return Center(child: Text('Unsupported content type'));
}
```

### 理由

如果 canvas 的 JSON 内容被 markdown 编辑器渲染，用户看到原始 JSON 并可能编辑，**破坏结构化数据**。错误占位（"不支持的内容类型"）比静默渲染错误格式安全得多。

---

## Q4 裁决：文件位置 — `lib/core/editor/editor_resolver.dart`

```
lib/core/editor/
├── editor_shell_service.dart     ← 状态管理 (DI-1)
├── editor_group_model.dart       ← per-pane 模型 (DI-1)
├── edit_buffer.dart              ← per-atom 状态机 (DI-1)
├── group_layout.dart             ← 递归布局树 (DI-2)
└── editor_resolver.dart          ← content_type → EditorPane (DI-10)
```

EditorResolver 与 EditorShellService 同属 workbench 级编辑器基础设施，放在同一目录下。

---

## 开放设计项

### View Mode 扩展（占位 — v0.4+ 多编辑范式）

> 来源：DI-4 Q1 补充讨论（编辑范式兼容性）。完整方案见 `docs/product/idea_temp/rich-block-editing-architecture.md`。

当前 `resolve(contentType)` 返回唯一 builder。多编辑范式（源码 / Block WYSIWYG / Inline WYSIWYG / 渲染预览）意味着同一 content_type 可有多种视图：

```dart
// v0.4+ 扩展方向
resolver.resolve('markdown', viewMode: ViewMode.source)   // → MarkdownSourceEditor
resolver.resolve('markdown', viewMode: ViewMode.block)    // → MarkdownBlockEditor
resolver.resolve('markdown', viewMode: ViewMode.inline)   // → MarkdownInlineEditor
resolver.resolve('markdown', viewMode: ViewMode.preview)  // → MarkdownPreviewPane (只读)
```

配套需求：

- `TabEntry` 扩展 `viewMode` 字段（EditorGroupModel / DI-1）
- 编辑模式是 per-pane 视图选择，不是 content_type 属性
- v0.3 不实现——`resolve(contentType)` 签名不变，只有 source editor

### EditBuffer 桥接模式（已由 DI-4 Q3 裁决 — D12）

> **裁决摘要**：Manual listener + 字符串比较守卫。完整裁决见 DI-4 Q3。

所有 EditorPane（无论 markdown / canvas / conversation）都需要处理同一个问题：**与 EditBuffer 的桥接**。

| 关注点 | DI-4 Q3 裁决 |
|--------|-------------|
| 初始内容加载 | EditorPane 创建时从 `buffer.content` 读取初始内容；仅在 `ready` 状态实例化（外壳 chrome 处理 loading/error） |
| 外部变更同步 | Manual listener (`addListener`) 监听 buffer 变更 → 字符串比较守卫区分本地/远程 |
| 自身编辑回写 | `buffer.edit()` → `notifyListeners()` → 自身 listener 触发 → 字符串比较 = 相等 → NO-OP（无循环） |
| Buffer swap | `didUpdateWidget` 中引用比较 (`widget.buffer != oldWidget.buffer`) 处理 tab 切换 |

通用桥接 mixin 方向（v0.4+ 提取）：

```dart
// v0.4+ 第二个 EditorPane 出现时提取
mixin EditorBufferBridge<T extends StatefulWidget> on State<T> {
  EditBuffer get buffer;
  bool applyContentToLocalState(String content);  // content_type 特定
  String serializeLocalState();                     // content_type 特定
}
```

**v0.3 不提取此 mixin**——只有 markdown 一种 EditorPane，桥接逻辑直接 inline 在 MarkdownEditorPane 内部（约 30 行）。当 v0.4+ 出现第二种 EditorPane 时，再提取共性。

具体的同步机制（如何区分"本地编辑"和"远程同步"以避免循环更新）**已由 DI-4 Q3 裁决**（D12：Manual listener + 字符串比较守卫）。

---

## 关联

- ← DI-1（EditorShellService 接口 — EditorResolver 是其渲染层伙伴）
- ← S2 Phase 3（EditorResolver 的实施阶段定义）
- ← S1 R2（content_type 类型体系）
- ← S1 R12（canvas content_type，v0.4+）
- ← S1 R13（conversation content_type，v0.4+）
- ← DI-4 Q3（EditBuffer 桥接模式 — D12 已裁决：Manual listener + 字符串比较守卫）
- → PR-0301B（EditorShellService 提取时可同步建立 resolver 壳）

---

*前序议题：[DI-2 递归布局树](DI-2-layout-tree-structure.md)（RESOLVED）*
