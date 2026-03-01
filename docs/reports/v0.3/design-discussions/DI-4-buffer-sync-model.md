# DI-4: Buffer 同步模型 + 粒度

| 项目 | 值 |
|------|-----|
| **状态** | OPEN |
| **关联决策点** | D10、D11 |
| **阻塞 PR** | PR-0303（直接）、PR-0305（间接） |
| **前置依赖** | DI-1（D1/D2 确定 buffer 放在哪）、DI-3（两阶段恢复模型边界） |
| **来源** | 01-design-readiness-audit.md §4.3 + §6.3 |

---

## 问题提取

### 来源 §1 执行摘要

> **Buffer 同步架构未决定**（阻塞 PR-0303/0305 spec）— 当前 `NoteEditor` 使用 per-instance `TextEditingController`，无跨实例同步。同步模型的选型（共享 buffer / 事件驱动 / 集中式 store）直接决定 spec 内容。

### 来源 §4.3 设计空白详析

> ```dart
> // note_editor.dart L1-110（当前实现）
> class NoteEditor extends StatefulWidget {
>   final String content;
>   final ValueChanged<String> onChanged;
>   // per-instance TextEditingController — 无跨实例同步
> }
> ```
>
> 每个 editor widget 实例拥有独立的 `TextEditingController`。对于同一笔记在多个 pane 中打开的场景，当前代码 **无任何同步机制**。

### 设计决策（审计报告原文）

| # | 决策点 | 选项 | 影响范围 |
|---|--------|------|---------|
| D10 | 同步模型 | A: 共享 Controller / B: 事件广播 / C: 集中式 BufferStore | PR-0303 核心实现 |
| D11 | 同步粒度 | A: 全量替换 / B: 差分 patch / C: 按段（段落级） | PR-0303 + PR-0305 性能 |

### 审计报告 §6.3 — 执行方法论评估

> DI-3 Buffer 同步 → **方案 B（文档 + 原型）**
>
> 理由：多实例 TextEditingController 同步在 Flutter 中缺少成熟先例。共享 controller 是否可行？事件广播的延迟特性？需要原型验证。
>
> 建议在独立分支上编写最小原型（2 个 pane + 同一 note 的 TextEditingController 同步），验证同步模型后再固化到设计文档。原型代码不需要合入 main，仅作为设计证据。

### DI-3 边界约定（阶段 2 入口）

DI-3 两阶段恢复模型定义了 DI-4 的入口条件：

- GroupLayout 树已重建，所有 LeafNode 的 groupId 有效
- 每个 EditorGroupModel 的 tab 列表已填充（atomId 数组）
- 每个 tab 对应的 EditBuffer 已创建，处于 `loading` 状态
- DI-4 负责定义：如何将这些 `loading` 状态的 EditBuffer 加载为 `ready`（加载顺序、并行策略、失败处理）

---

## 讨论大纲

| 编号 | 议题 | 关联决策点 | 状态 |
|------|------|-----------|------|
| Q1 | D10 同步模型选型 | D10 | RESOLVED |
| Q2 | D11 同步粒度 | D11 | OPEN |
| Q3 | EditBuffer ↔ TextEditingController 桥接机制 | DI-1 细化4 遗留 | OPEN |
| Q4 | 阶段 2 内容加载策略 | DI-3 边界 | OPEN |
| Q5 | 方法论（是否需要原型） | §6.3 | OPEN |

讨论顺序：Q1 → Q2 → Q3 → Q4 → Q5（Q1/Q2 前提确认 → Q3 核心设计 → Q4 DI-3 接口履行 → Q5 收尾）

---

## Q1: D10 同步模型选型 — RESOLVED

### 当前代码实现

```dart
// note_editor.dart — 当前模式
class NoteEditor extends StatefulWidget {
  final String content;                    // ← 从 coordinator 单向传入
  final ValueChanged<String> onChanged;    // ← 编辑回调
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _textController;

  @override
  void initState() {
    _textController = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(NoteEditor oldWidget) {
    if (widget.content != _textController.text) {   // ← 字符串比较守卫
      _textController.text = widget.content;         // ← 外部内容变化时更新
    }
  }
}
```

数据流：`coordinator._draftContentByAtomId` → prop `content` → `TextEditingController`。
单向传递，无跨 pane 同步。每个 NoteEditor 实例拥有独立的 TextEditingController。

当前实现本质上已经是"集中式 buffer"模式——coordinator 的 `_draftContentByAtomId` 是中央存储，只是粒度在 coordinator 级（全局 `notifyListeners()`），而非 per-atom 级。

### 已有裁决约束

| 裁决 | 内容 | 对 D10 的约束 |
|------|------|--------------|
| DI-1 Q1 | EditBuffer 是 per-atom ChangeNotifier，跨 pane 共享同一实例 | 排除 per-pane buffer |
| DI-1 Q3 | EditBuffer 统一 draft + save，`content` 字段是单一真相源 | buffer 层模型已确定 |
| DI-1 细化4 | 多 pane 并发编辑需区分"本地编辑"和"远程同步"以避免循环 rebuild | 桥接层必须解决 |
| S2 Rule 2 | 状态不双写 | TextEditingController.text 和 buffer.content 的关系必须明确 |

### 三选项分析

**选项 A：共享 TextEditingController**

一个 TextEditingController 实例绑定到多个 NoteEditor widget。

| 维度 | 评估 |
|------|------|
| 可行性 | **不可行** |
| 原因 1 | TextEditingController 包含 `selection`（光标 + 选区），共享 = 所有 pane 光标位置锁定 |
| 原因 2 | Flutter framework 不支持多 widget 绑定同一 EditableText controller（rebuild 行为未定义） |
| 原因 3 | 违反 DI-5 前提——光标必须各 pane 独立 |

**结论：排除。**

**选项 B：事件广播**

每个 pane 有独立 TextEditingController，编辑事件通过中央总线广播。

| 维度 | 评估 |
|------|------|
| 可行性 | 可行但多余 |
| 原因 | EditBuffer 作为 ChangeNotifier 已经是事件广播——`notifyListeners()` 就是广播。引入额外 event bus 增加复杂度但无新增能力 |

**结论：EditBuffer 的 ChangeNotifier 已覆盖此模式，无需额外抽象。**

**选项 C：集中式 BufferStore（EditBuffer）**

EditBuffer（per-atom ChangeNotifier）作为集中式 buffer，多个 pane widget 监听同一实例。

| 维度 | 评估 |
|------|------|
| 可行性 | **已由 DI-1 裁决** |
| 模型 | EditorShellService.buffers: `Map<AtomId, EditBuffer>` |
| 通知机制 | `buffer.edit(content)` → `notifyListeners()` → 所有监听 widget rebuild |
| 剩余问题 | 桥接机制——widget 如何区分"自己的编辑"和"其他 pane 的编辑"（→ Q3） |

### 同步时机：为什么必须实时（per-keystroke）

三种候选时机：

| 时机 | 描述 | Pane B 在编辑期间的表现 |
|------|------|----------------------|
| 模型 1：每次击键（实时） | `buffer.edit()` 每次调用 `notifyListeners()` | 逐字更新，始终与 Pane A 一致 |
| 模型 2：焦点切换时（懒同步） | `edit()` 不通知，切换焦点时同步 | **显示旧内容**，切换瞬间跳变 |
| 模型 3：保存时 | `edit()` 不通知，保存成功后同步 | **延迟 1.5s+**，显示上一次保存的版本 |

**裁决：模型 1（实时同步）。**

理由——用户可以同时看到两个 pane：

用户 split 同一笔记的核心场景是**对照编辑**（看第 1 段写第 10 段）和**参考引用**（一边看一边写）。两个 pane 在屏幕上同时可见。如果 Pane B 显示旧内容，用户会困惑："我刚改了这段，为什么那边还是旧的？"

模型 2/3 在用户不看 Pane B 时节省了 rebuild 开销，但在用户**能看到**两个 pane 时产生了不一致——而"能看到"是 split 的默认状态。

**光标行为**：只有焦点 pane 显示光标（Flutter 默认行为），非焦点 pane 只显示文本。用户任何时刻只在一个 pane 内编辑。

**未保存编辑是否同步**：是。`buffer.content` = 当前 draft（含未保存编辑），不是 DB 中的版本。同一笔记在两个 pane 不应有两份不同的未保存 draft——这是"两个视图"而非"两个分支"。

### 性能分析

每次击键的同步开销：

| 操作 | 成本 |
|------|------|
| `buffer.edit()` | O(1) 赋值 |
| `notifyListeners()` | O(k)，k = 监听 pane 数（通常 1-3） |
| Pane A 字符串比较 | O(n)，n = 文档长度。结果 = 相等 → no-op |
| Pane B 字符串比较 + controller update | O(n)。结果 = 不等 → 更新 |

| 文档大小 | 每次击键总开销 | 判定 |
|---------|-------------|------|
| 1KB | < 0.02ms | 可忽略 |
| 10KB | < 0.1ms | 可忽略 |
| 100KB | < 1ms | 可接受（16ms 帧预算的 6%） |

真正的性能瓶颈不在字符串比较，而在 widget 重建——但这是 Flutter 框架层面的事，与同步模型无关。

### 消费者分层设计原则

EditBuffer 的消费者不只是编辑器 pane。不同消费者的更新成本差异巨大：

| 消费者类型 | 更新成本 | 推荐更新策略 | 示例 |
|-----------|---------|------------|------|
| 编辑器 pane | 极低（字符串比较 + no-op 或 controller 赋值） | 同步响应（每次击键） | 另一个编辑器 pane |
| 状态指示器 | 极低 | 同步响应 | dirty 圆点、字数统计 |
| 渲染预览 | **高**（markdown parse + widget tree 重建） | **消费者内部去抖**（如 300ms） | Obsidian 式 markdown 预览 |
| 大纲/TOC | 中等（标题提取） | 消费者内部去抖 | 侧边栏大纲 |
| 链接图谱 | 中等（链接提取） | 消费者内部去抖 | backlink 面板 |

**设计原则：通知无条件，消费有策略。**

`buffer.edit()` 每次调用 `notifyListeners()`——无条件，不区分消费者。每个消费者自行决定响应策略：

- 低成本消费者（编辑器、状态指示器）：同步响应，立即 rebuild
- 高成本消费者（渲染预览、大纲提取）：在 **widget 层** 自行去抖

```dart
// 高成本消费者的去抖模式（widget 层实现，非 EditBuffer 层）
class MarkdownPreviewPane extends StatefulWidget {
  final EditBuffer buffer;
  // ...
}

class _MarkdownPreviewPaneState extends State<MarkdownPreviewPane> {
  Timer? _debounceTimer;
  String _renderedContent = '';

  void _onBufferChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      setState(() { _renderedContent = parseMarkdown(widget.buffer.content); });
    });
  }
}
```

**为什么去抖在消费者层而非 EditBuffer 层**：

1. EditBuffer 是 content_type 无关的（DI-10 裁决）——它不知道消费者是编辑器还是预览
2. 不同消费者的去抖时间不同——预览 300ms，大纲 500ms，编辑器 0ms
3. 去抖策略是 **UI 展示决策**，不是 **数据模型决策**

### 与 EditorResolver 的关系

DI-10 定义的 `EditorPaneBuilder = Widget Function(BuildContext context, EditBuffer buffer)`。

编辑 + 预览分离场景下：

| Pane | Widget | 对 EditBuffer 的操作 | 通过 EditorResolver？ |
|------|--------|-------------------|---------------------|
| 编辑器 | MarkdownEditorPane | 读 `content` + 写 `edit()` | 是（注册为 `markdown`） |
| 渲染预览 | MarkdownPreviewPane | **只读** `content`，不调用 `edit()` | v0.3 范围外——待 v0.4+ 决定 |

v0.3 只有编辑器，没有独立预览模式。但 DI-4 的同步模型（`notifyListeners()` + 消费者自控更新策略）天然支持预览场景——无需 EditBuffer 或 EditorShellService 做任何修改。

预览 pane 的 EditorResolver 注册方式（同一 content_type 的编辑/预览是否分开注册）属于 DI-10 的扩展范畴，记录为开放设计项，不在 DI-4 裁决。

### 裁决

**D10 = 选项 C（集中式 BufferStore / EditBuffer），实时同步（per-keystroke `notifyListeners()`）。**

同步模型由 DI-1 Q3 隐式裁决（EditBuffer 为 per-atom ChangeNotifier）。DI-4 Q1 确认：

1. 选项 A/B 排除，选项 C 是唯一可行模型
2. 同步时机 = 实时（用户可同时看到多个 pane，内容必须一致）
3. 未保存编辑必须同步（`buffer.content` = 当前 draft，不是两个独立分支）
4. 消费者分层：通知无条件，消费有策略（去抖在消费者层，非 buffer 层）

---

### Q1 补充：编辑范式兼容与同步协议

> 以下裁决扩展 Q1，覆盖多编辑范式（源码 / Block WYSIWYG / Inline WYSIWYG）的兼容性和同步协议设计。

#### 三种编辑范式

| 范式 | 代表产品 | 用户体感 | 对 buffer 层的需求 |
|------|---------|---------|------------------|
| 源码编辑 + 渲染预览 | Obsidian Source / VSCode | 左编辑原始 markdown，右渲染预览 | content = 纯 markdown string，无结构化需求 |
| Block WYSIWYG | Notion / Jupyter | 每个段落/标题/代码是独立可编辑块，所见即所得 | 需要 block 元数据持久化（block ID、属性、折叠态） |
| Inline WYSIWYG | Typora | 单一视图，光标处显示源码，离开后渲染 | 需要 AST 支持光标节点定位 |

**裁决：架构必须兼容全部三种范式，用户可选择编辑模式。编辑模式是 per-pane 的视图选择，不是 content_type 属性（content_type 描述内容格式，不描述编辑方式）。**

#### 持久化模型：Markdown + Sidecar Overlay

**核心原则**：`Atom.content`（markdown 字符串）始终是持久化层的 source of truth。Block 元数据以独立 overlay 形式存储，不侵入主 content。

```
Atom
├── content: String           ← markdown 文本（所有场景的基底）
├── content_type: "markdown"  ← 不变（S1 R2）
└── [atom_overlays 表]        ← JSON sidecar（仅使用过 rich block 时存在）
```

**overlay 独立表（不放 atoms 主列）**：

```sql
CREATE TABLE atom_overlays (
  atom_uuid TEXT PRIMARY KEY,
  block_meta TEXT NOT NULL,        -- JSON block 元数据
  overlay_rev INTEGER NOT NULL,    -- overlay 版本号
  content_rev_at_sync INTEGER NOT NULL,  -- overlay 上次与 content 同步时的 content_rev
  FOREIGN KEY (atom_uuid) REFERENCES atoms(uuid)
);
```

理由：
- 读路径隔离：普通 markdown 查询不加载 block JSON
- 写频率分离：content（高频，每次保存）vs overlay（低频，模式切换/block 编辑时）
- 从未用过 block 模式的 atom 在 overlay 表中不存在任何行——零开销

**Stale 判定**：`atom.content_rev > overlay.content_rev_at_sync` → 需要 reconciliation。持久化到数据库，不仅在内存。

**原子事务**：

| 编辑场景 | 事务内容 |
|---------|---------|
| 文本编辑保存 | `UPDATE atoms SET content = ?, content_rev = content_rev + 1` — overlay 不动，content_rev 增长自动导致 stale |
| Block 编辑保存 | `UPDATE atoms SET content = ? ...` + `INSERT OR REPLACE atom_overlays ...` — 同一事务 |

#### Block 能力分级

| 级别 | content_type | 存储 | 可降级到源码编辑？ | 覆盖范围 |
|------|-------------|------|-----------------|---------|
| Markdown-compatible block | `markdown` | 纯 markdown 文本 + overlay sidecar | **是**（overlay 丢失时有损降级） | 标题、段落、列表、代码块、引用块 |
| Rich block（v0.4+） | 独立 content_type（如 `block_document`——占位命名，正式注册遵循 S1 R2 协议） | JSON block tree | **有损**（丢失 block ID、嵌套属性） | 嵌套 callout、database view、toggle block |

**无缝转换要求**：用户在 rich block 模式创建内容 → 切到纯文本 markdown 编辑 → 切回 rich block → 应看到之前的 block 元数据（ID、属性）保留。这通过 sidecar + reconciliation 实现。

#### Reconciliation 协议

用户从文本模式切换到 block 模式（或跨 pane 文本→block 延迟对齐）时触发：

```
输入：当前 markdown 文本 + 旧 block_meta sidecar
输出：新的 block tree（用于 block 编辑器渲染）+ 更新后的 sidecar

算法要求：
1. Parse markdown → structural blocks
2. 对齐旧 sidecar blocks 和新 structural blocks
   匹配信号：结构指纹（block type）+ 内容相似度 + 相对顺序（LCS）+ 稳定 tie-break
   !! 不能只靠行号（行号在编辑后漂移）
3. 匹配成功 → 保留 block ID + attrs，更新 content
4. 新增（markdown 中有，sidecar 中无）→ 生成新 block ID
5. 未匹配旧块 → 进入 orphan/preserved 集合，提示用户
   !! 不能静默丢块（用户核心信任依赖）
```

**Reconciliation 约束**：

| 约束 | 要求 |
|------|------|
| 预算 | 超时（如 100ms）→ 后台继续，UI 显示 stale 指示，不阻塞输入 |
| 匹配质量 | 多维信号（type + 内容相似度 + 相对顺序），不依赖单一行号 |
| 数据安全 | 未匹配旧块进入 orphan 集合 + 用户提示，不静默删除 |
| AI 兼容 | AI 模型只需 `Atom.content`（纯 markdown），不需理解 block_meta |

#### 同步协议：三路 EditOp

```dart
sealed class EditOp {
  final int baseRev;    // 基于哪个版本产生
}

/// 路径 1：全量快照替换（降级兜底，任何失败的终点）
class SnapshotReplace extends EditOp { final String content; }

/// 路径 2：字符级增量（源码/Inline 编辑的自然产出）
class TextDelta extends EditOp {
  final int offset;
  final int deleteCount;
  final String insertText;
}

/// 路径 3：结构化操作（Block 编辑的自然产出，v0.4+）
class StructuredOp extends EditOp {
  final String opType;     // "moveBlock", "deleteBlock", "mergeBlock", ...
  final Map<String, dynamic> payload;
}
```

**降级规则**：
- StructuredOp 消费者不理解 → 降级为 SnapshotReplace
- TextDelta 的 baseRev ≠ 当前 rev → 降级为 SnapshotReplace
- 任何 op 导致内容不一致 → 回退到 op 应用前的 buffer.content 快照（latest consistent snapshot）+ 标记冲突 + 通知用户（不回退到 lastSavedSnapshot，避免丢失未保存编辑）

**EditBuffer 接口修正**：

```dart
class EditBuffer extends ChangeNotifier {
  String _content;
  int _rev;                     // 单调递增版本号
  EditOp? _lastOp;              // 最近一次操作（消费者可选读取）

  void edit(String newContent, {EditOp? op}) {
    _content = newContent;
    _rev++;
    _lastOp = op;               // null = SnapshotReplace 语义
    notifyListeners();
  }
}
```

v0.3：调用方不传 `op`，等效全量替换。接口预留 delta + structured op 通道。

#### 跨模式同步 SLA

**与 Q1 主裁决的关系**：Q1 裁决 "D10 = per-keystroke 实时同步" 指的是 **buffer 通知层**——`edit()` → `notifyListeners()` 每次击键无条件触发，所有消费者均收到通知。下表的 SLA 指的是 **消费者侧响应延迟**——不同类型的消费者收到通知后按自身成本选择响应策略（Q1 消费者分层原则："通知无条件，消费有策略"）。两者不矛盾。

| 同步路径 | 延迟目标 | 实现方式 |
|---------|---------|---------|
| 文本 → 文本（跨 pane） | **实时**（每次击键） | Q1 主裁决，字符串比较 guard |
| Block → 文本（跨 pane） | **实时或轻去抖**（50-150ms） | block 编辑 → serialize markdown → edit() → 文本 pane 同步 |
| 文本 → Block（跨 pane） | **300-500ms 节流** + 切模式时强制对齐 | 不每次击键 reconcile；throttle 后增量 reconcile（定位 delta 影响的 block） |

不对称性说明：文本→block 方向不实时是文本编辑零开销的必要代价。block→文本方向可实时因为 serialize 成本低。

#### 运行时层级模型

```
Layer 0: Content String — 始终存在，持久化到 SQLite，FTS5 索引
         性能: 存取 O(1)，无解析开销
         所有编辑模式都读写此层

Layer 1: Parsed AST（可选，按需加载）
         从 Layer 0 解析，支持节点定位/增量更新
         服务于: Inline 编辑、大纲提取、链接解析
         宿主: v0.3 不决定（先定协议再定宿主）

Layer 2: Block Model（可选，按需加载）
         从 Layer 1 构建，每个 block 有独立编辑状态
         服务于: Block WYSIWYG 编辑
         宿主: Dart（UI 交互密集）
```

**按需加载原则**：源码编辑只用 Layer 0（零额外开销）。Inline 加载 Layer 1。Block 加载 Layer 1 + 2。任何时候可降级回源码模式（丢弃 Layer 1/2）。

#### v0.3 实现 vs 预留

| 项 | v0.3 实现 | v0.3 接口预留 |
|---|----------|-------------|
| EditBuffer | `content: String` + `rev: int` | `edit(String, {EditOp? op})` — op 参数存在，调用方不传 |
| EditOp | `SnapshotReplace` 类定义 | `TextDelta` + `StructuredOp` 类定义（不使用） |
| overlay 表 | 不创建 | schema 设计已确定，v0.4+ 新增 migration |
| Reconciliation | 不实现 | 协议约束已定义 |
| Layer 1/2 | 不加载 | 接口形态确定，宿主延后 |
| 编辑模式选择 | 仅源码编辑 | EditorGroupModel 概念上支持 viewMode |

DI-4 的核心剩余工作在 Q3（桥接机制实现）。

> 完整的多编辑范式架构方案见 `docs/product/idea_temp/rich-block-editing-architecture.md`。

---

## Q2: D11 同步粒度 — OPEN

### 当前代码实现

```
coordinator.updateActiveDraft(content):
  _draftContentByAtomId[atomId] = content;    // ← 全量字符串替换
```

NoteEditor → coordinator 传递的是完整 content 字符串（`TextEditingController.text`），不做 diff。

### 已有裁决约束

| 裁决 | 内容 | 对 D11 的约束 |
|------|------|--------------|
| DI-1 Q3 | `EditBuffer.content: String` — opaque string，不感知内部结构 | buffer 层不做 diff |
| DI-10 | EditorPane 自己负责解析 `buffer.content`（markdown / canvas JSON / 消息 JSON） | 内容格式差异大，通用 diff 不现实 |
| S2 Rule 1 | 单一状态源 | content 字符串是权威值 |

### 三选项分析

| 选项 | 复杂度 | 适用场景 | v0.3 评估 |
|------|--------|---------|-----------|
| A: 全量替换 | 低 | 笔记 < 100KB | **匹配当前模式 + 足够** |
| B: 差分 patch | 高 | 协同编辑 / 超大文档 | 超出范围——本地单用户无协同需求 |
| C: 段落级 | 很高 | 实时多人协同 | 远超 v0.3 范围 |

**性能估算（全量替换）：**

| 文档大小 | 字符串比较耗时 | 判定 |
|---------|-------------|------|
| 1KB（短笔记） | < 0.01ms | 可忽略 |
| 10KB（长笔记） | < 0.05ms | 可忽略 |
| 100KB（极长文档） | < 0.5ms | 可接受（低于 1 帧 16ms 预算） |

**为什么不提前做 diff：**

1. `EditBuffer.content` 是 opaque string（DI-10 裁决）——buffer 层不知道内容是 markdown / JSON / 其他格式
2. 不同 content_type 的 diff 语义完全不同——markdown 按行 diff ≠ canvas JSON 按元素 diff
3. v0.3 仅有 markdown 一种类型，引入 diff 机制是为尚不存在的场景优化

### 初步建议（Q1 补充后修正）

**D11 = 全量字符串为 source of truth + 可选 EditOp 提示。**

v0.3 实现全量替换（等效选项 A）。接口预留三路 EditOp 通道（SnapshotReplace / TextDelta / StructuredOp），供 v0.4+ 的 Block 编辑和 Inline 编辑使用。

修正理由：字符级 delta 无法覆盖 block 级操作（如 block 拖拽排序），需要 StructuredOp 路径。三路并存 + 降级兜底是完整方案（详见 Q1 补充裁决）。

---

## Q3: EditBuffer ↔ TextEditingController 桥接机制 — OPEN

### 问题定义

DI-1 细化4 识别的核心问题：

> 编辑中的 pane 触发 `buffer.edit()` → `notifyListeners()` → **自身也会 rebuild** → 可能导致光标跳动或循环。需要区分"本地编辑"（不需要更新自身 TextEditingController）和"远程同步"（需要更新其他 pane 的 TextEditingController）。

### 当前代码中已存在的模式

NoteEditor 的 `didUpdateWidget` 已使用**内容字符串比较**作为守卫：

```dart
if (widget.content != _textController.text) {
  _textController.text = widget.content;
}
```

这个比较在多 pane 场景下的行为：

| 场景 | widget.content | _textController.text | 相等？ | 行为 |
|------|---------------|---------------------|--------|------|
| 本地编辑后 rebuild（Pane A 自身） | newContent（来自 buffer） | newContent（用户刚键入） | **是** | no-op ✓ |
| 远程同步 rebuild（Pane B） | newContent（来自 buffer） | oldContent（Pane B 未编辑） | **否** | 更新 controller ✓ |

### 目标架构数据流

```
用户在 Pane A 键入 "x"
  → Pane A 的 TextEditingController.text 变为 "...x"（Flutter 内部更新，在 onChanged 之前）
  → NoteEditor.onChanged("...x")
  → buffer.edit("...x")
      → buffer.content = "...x"
      → buffer._rev++
      → buffer 重启 debounce timer
      → buffer.notifyListeners()
  → Pane A rebuild:
      widget receives buffer.content = "...x"
      didUpdateWidget: "...x" == _textController.text ("...x") → NO-OP
      光标位置不受影响 ✓
  → Pane B rebuild:
      widget receives buffer.content = "...x"
      didUpdateWidget: "...x" != _textController.text (old) → 更新 controller
      内容同步 ✓，光标位置重置（→ DI-5 范畴）
```

### 初步建议

**内容字符串比较守卫**——复用当前 NoteEditor 已有的 `didUpdateWidget` 模式。

理由：
1. 模式已在当前代码中验证（单 pane 场景下 content prop 变化时正确工作）
2. 无需引入 edit source tag、widget-level guard 或额外原语
3. 字符串比较成本在 D11 全量替换方案下可接受（与 Q2 一致）

待讨论：
- Pane B 的光标位置重置问题——移交 DI-5
- `_textController.text = newContent` 是否会触发 NoteEditor 自身的 `onChanged` 回调导致循环？——需确认 Flutter 行为

---

## Q4: 阶段 2 内容加载策略 — OPEN

### 问题定义

DI-3 两阶段恢复模型中，阶段 2 的入口条件已定义：

```
输入: 阶段 1 产出的 EditBuffer（loading 状态）+ atomId 列表
依赖: RustBridge + SQLite（FFI 调用）
产出: EditBuffer loading → ready（内容填充）
时机: Background Phase（DB 就绪后异步执行）
```

需要裁决：加载顺序、并行策略、失败处理。

### 当前代码实现

```dart
// 当前 selectNote 的加载模式（coordinator）
selectNote(atomId):
  detailLoading = true
  noteItem = await noteGetInvoker(atomId)    // FFI 单次调用
  selectedNote = noteItem
  // ... 设置 draft content
  detailLoading = false
```

当前是**按需加载**——用户点击某笔记时才加载。无预加载、无批量加载。

### 已有裁决约束

| 裁决 | 内容 | 对 Q4 的约束 |
|------|------|------------|
| DI-1 Q3 细化1 | EditBuffer 状态机 `loading → ready → disposing`；`loading` 阶段 `edit()/save()/flush()` 均为 no-op | 加载前 UI 安全 |
| DI-3 边界 | atomId 不存在 → 跳过 tab；非 primary group 清空 → 坍缩 | 失败处理已定义方向 |
| DI-3 边界 | 用户在 loading 阶段关闭 tab → 允许（结构操作） | 加载可中断 |

### 初步建议

**优先级分层 + 按需加载：**

```
优先级 1 — 立即加载（启动时）:
  各 group 的 activeTab → 并行发起 FFI note_get()
  理由：用户只看到 active tab，这些必须最先出现

优先级 2 — 按需加载（用户触发）:
  非活跃 tab → 用户点击切换到该 tab 时才加载
  理由：不可见的 tab 提前加载浪费资源；本地 SQLite < 50ms，用户感知不到延迟
```

**失败处理：**

| 场景 | 行为 |
|------|------|
| atomId 在 DB 中不存在 | 从所有 group 移除该 tab → 非 primary group 清空则坍缩 |
| FFI 调用失败（DB 错误） | EditBuffer 保持 `loading` → UI 显示错误占位 → 可重试 |
| 用户在 loading 中关闭 tab | 允许——取消该 buffer 的加载请求，dispose buffer |

**运行时按需加载（非恢复场景）：**

与启动恢复共用同一机制。用户点击笔记 → `service.openTab()` → 创建 `loading` EditBuffer → coordinator FFI 加载 → `service.initializeBuffer()` → `ready`。DI-1 Q3 细化1 已定义此流程。

---

## Q5: 方法论 — OPEN

### 审计报告建议

§6.3 建议"方案 B（文档 + 原型）"，理由：

> 多实例 TextEditingController 同步在 Flutter 中缺少成熟先例。共享 controller 是否可行？事件广播的延迟特性？

### 初步建议

**降级为方案 A（仅文档）。** 理由：

1. 选项 A（共享 controller）已通过分析排除——不需要原型验证不可行的方案
2. Q3 桥接机制（字符串比较守卫）已在当前 NoteEditor `didUpdateWidget` 中存在——不是新模式
3. D11 全量替换匹配现有实现——无性能不确定性
4. 无新 Flutter 框架原语——全是标准 ChangeNotifier + StatefulWidget 模式

§6.3 的原始顾虑（"缺少成熟先例"）已通过 DI-1 的 EditBuffer 设计和 Q3 的现有代码模式分析化解。

---

## 关联

- ← DI-1（D1/D2 确定 EditorShellService 接口和 buffer 归属；Q3 细化4 识别桥接问题）
- ← DI-3（两阶段恢复模型——Q4 接收阶段 2 入口约定）
- ← DI-10（EditorPaneBuilder 接口——EditBuffer 是唯一桥接参数）
- → DI-5（光标/冲突处理建立在同步模型之上；Pane B 光标重置问题移交）
- → DI-7（性能基线与同步粒度相关）
- ← 01 审计报告 §4.3 + §6.3

---

*前序议题：[DI-3 布局持久化](DI-3-layout-persistence.md)（RESOLVED）*
*下一个议题：[DI-5 光标独立性 + 冲突处理](DI-5-cursor-and-conflict.md)*
