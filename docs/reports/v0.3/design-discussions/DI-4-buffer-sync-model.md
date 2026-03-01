# DI-4: Buffer 同步模型 + 粒度

| 项目 | 值 |
|------|-----|
| **状态** | **RESOLVED** — D10、D11、D12 全部裁决完毕，Q4 四项细化全部完成 |
| **关联决策点** | D10、D11、D12 |
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
| Q2 | D11 同步粒度 | D11 | RESOLVED |
| Q3 | EditBuffer ↔ TextEditingController 桥接机制 | DI-1 细化4 遗留 | RESOLVED |
| Q4 | 阶段 2 内容加载策略 | DI-3 边界 | RESOLVED |
| Q5 | 方法论（是否需要原型） | §6.3 | RESOLVED |

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

DI-4 的 Q3 桥接机制已在下文裁决（D12）。

> 完整的多编辑范式架构方案见 `docs/product/idea_temp/rich-block-editing-architecture.md`。

---

## Q2: D11 同步粒度 — RESOLVED

### 当前代码实现

```
coordinator.updateActiveDraft(content):
  _draftContentByAtomId[atomId] = content;    // ← 全量字符串替换
```

NoteEditor → coordinator 传递的是完整 content 字符串（`TextEditingController.text`），不做 diff。

完整数据流（每次击键）：

```
用户击键
  → TextField.onChanged("完整文本")
  → coordinator.updateActiveDraft("完整文本")
      → _draftContentByAtomId[id] = "完整文本"     // 全量存储
      → previous == content? → return（字符串比较 guard）
      → _draftVersionByAtomId[id]++                 // 版本自增（→ 新模型中的 _rev）
      → _isDirty() = (draft != persisted)           // 全量字符串比较
      → _scheduleAutosave(version)                  // 1500ms debounce
      → notifyListeners()
          → NoteEditor.didUpdateWidget:
              widget.content != _textController.text?  // 全量字符串比较
              → 相等则 no-op，不等则 controller.text = 新内容

debounce 到期 (1500ms)
  → _performSaveDraft(version)
      → 双重 stale check（version 比对 — 调度时 vs 当前）
      → await FFI: note_update(atomId, 完整内容)     // 全量写入 SQLite
      → _persistedContentByAtomId[id] = content      // 全量更新基线
```

全链路特征：

| 层 | 粒度 | 机制 |
|---|------|------|
| UI → Buffer | 全量 string | `TextEditingController.text` |
| Buffer 内部 | 全量存储 + 版本号 | `Map<String, String>` + `Map<String, int>` |
| Buffer → UI（跨 pane） | 全量字符串比较 guard | `didUpdateWidget` 中 `==` |
| Buffer → SQLite | 全量 content 列 | `note_update(id, content)` FFI |
| SQLite → FTS5 | 全量重索引 | UPDATE trigger 整行替换 |

### 已有裁决约束

| 裁决 | 内容 | 对 D11 的约束 |
|------|------|--------------|
| DI-1 Q3 | `EditBuffer.content: String` — opaque string，不感知内部结构 | buffer 层不做 diff |
| DI-10 | EditorPane 自己负责解析 `buffer.content`（markdown / canvas JSON / 消息 JSON） | 内容格式差异大，通用 diff 不现实 |
| S2 Rule 1 | 单一状态源 | content 字符串是权威值 |
| Q1 补充 | `edit(String newContent, {EditOp? op})` — EditOp 是 advisory hint | hint 不是 source of truth |

### Q1 与 Q2 的关系澄清

Q1 裁决的是 **buffer 内存层的 source of truth 和通知机制**——`_content` 存全量字符串，`notifyListeners()` 每次击键触发。

Q2 问的是 **数据从 A 传到 B 时，传输和应用的粒度**——消费者收到通知后，怎么高效地更新自身状态。这是两个独立的问题。

Q1 裁决 source of truth = 全量字符串，但**不排除**消费者利用 EditOp hint 做增量应用以减少性能消耗。

### 三选项分析

| 选项 | 复杂度 | 适用场景 | v0.3 评估 |
|------|--------|---------|-----------|
| A: 全量替换 | 低 | 笔记 < 100KB | **匹配当前模式 + 足够** |
| B: 差分 patch | 高 | 协同编辑 / 超大文档 | 超出范围——本地单用户无协同需求 |
| C: 段落级 | 很高 | 实时多人协同 | 远超 v0.3 范围 |

**最终方案不是 A/B/C 任何单一选项，而是 "A 为真相 + B 为可选提示"。**

### 两层模型

```
┌─────────────────────────────────────────┐
│ Source of Truth 层（always present）      │
│  buffer._content: String  ← 完整字符串   │
│  buffer._rev: int         ← 单调版本号   │
│                                         │
│  edit() 无条件替换 _content + rev++       │
│  所有正确性保证基于此层                    │
└─────────────────────────────────────────┘
                    +
┌─────────────────────────────────────────┐
│ Hint 层（optional, advisory）            │
│  buffer._lastOp: EditOp?  ← 变更提示    │
│                                         │
│  仅供消费者优化使用，不影响正确性          │
│  消费者读不懂 → 忽略，回退到读 _content   │
└─────────────────────────────────────────┘
```

**hint 的设计约束**：EditOp 是 advisory hint，不是 authoritative delta。正确性检验方式——消费者忽略 `_lastOp`，只读 `_content`，行为仍然正确（只是可能多做一些不必要的 rebuild）。如果 EditOp 成为正确性依赖，系统就从 state replication 变成了 operation replication，复杂度急剧上升。

### 性能估算

**全量字符串操作（per-keystroke）：**

| 文档大小 | 字符串赋值 | 字符串比较（跨 pane） | 判定 |
|---------|----------|-------------------|------|
| 1KB（短笔记） | < 0.01ms | < 0.01ms | 可忽略 |
| 10KB（长笔记） | < 0.05ms | < 0.05ms | 可忽略 |
| 100KB（极长文档） | < 0.5ms | < 0.5ms | 可接受（16ms 帧预算的 6%） |
| 500KB（极端边界） | ~3ms | ~3ms | 边界——开始值得关注 |
| 1MB+（超大文档） | ~10ms | ~10ms | **需要演化方案** |

v0.3 目标文档 < 100KB，全量替换充足。性能瓶颈不在同步粒度（字符串操作），而在 widget 渲染层（全文 widget tree 构建）——后者由 EditorPane 内部 viewport rendering 解决，与同步模型无关。

### 消费者侧的 delta 应用路径

Q1 补充的 EditOp hint 为消费者提供增量应用的可能：

| 消费者 | v0.3 消费方式 | v0.4+ 消费方式（利用 EditOp hint） |
|--------|-------------|--------------------------------|
| 跨 pane 文本编辑器 | `controller.text = 全文`（字符串比较 guard） | 读 `TextDelta` → `controller.value` 精准插入/删除，保留光标相对位置 |
| Block 编辑器 | 不存在 | 读 `StructuredOp` → 直接应用 block 操作，避免全量 re-parse |
| 渲染预览 | 不存在 | 读 `TextDelta.offset` → 判断是否在 viewport 内，不在则跳过 rebuild |
| SQLite 持久化 | `UPDATE SET content = ?`（全列写入） | 不变——SQLite UPDATE 就是全列替换，delta 无法减少 I/O |
| FTS5 | trigger 全量重索引 | 不变——FTS5 UPDATE trigger 是全行替换语义 |

### 持久化粒度

| 层 | 粒度 | v0.3 行为 | 理由 |
|---|------|----------|------|
| FFI 接口 | 全量 content 写入 | `note_update(id, 完整content)` | SQLite UPDATE 是全列写入，delta 不减少 I/O |
| FTS5 更新 | 全量重索引 | UPDATE trigger | FTS5 trigger 是全行替换语义 |
| overlay 写入 | 不存在 | v0.4+ 新增 | Q1 补充已裁决 |

### 大文档演化路径

当文档大小超过全量字符串的性能边界（~500KB+）时，有两条互补的演化路径：

**路径 1：Transclusion（语义层 LOD）— 首选**

用户将大文档拆分为多个 Atom，通过 markdown 嵌入引用组合：

```markdown
# 我的巨著
![[chapter_1_atom_id]]
![[chapter_2_atom_id]]
```

- "目录 Atom" 的 content 只有几十字节，各章节 Atom 各自 < 100KB
- 每章 Atom 有独立 EditBuffer，编辑时只触发该章的 buffer 通知
- **与 Q1/Q2 完全兼容**——不改 Atom 模型、EditBuffer、FFI、持久化
- 仅需新增：`![[id]]` 语法解析（EditorPane 内）+ 引用 Atom 动态加载 + 嵌入渲染
- 已在 Obsidian / Logseq / Roam 充分验证的用户心智模型

**路径 2：Rope 数据结构（物理层优化）— 极端兜底**

Rust Core 层用 Rope 树替代 String，提供 O(log n) 编辑和范围查询：

- 适用场景：单个 Atom 无法逻辑拆分（如导入的外部大文件）
- **与 Q1 兼容但非透明**——需要扩展 EditBuffer API（新增 `getRange(start, end)` 等范围查询），EditorPane 需从读全文改为按 viewport 请求范围，FFI 需新增范围查询端点
- Q1 的 `edit()` + `content` 基础接口保留作为兼容 fallback

**路径 3：DocumentSession 中间层（chunk 分段）— 结构化方案**

在 EditBuffer 之上插入 DocumentSession 层，将文档拆为 chunks：

```
v0.3:  1 Atom → 1 EditBuffer → 1 EditorPane
v0.5+: 1 Atom → 1 DocumentSession → N EditBuffer(per chunk) → 1 EditorPane
```

- 每个 chunk EditBuffer 接口不变（存 chunk string，edit + notifyListeners）
- 编辑只触发受影响 chunk 的通知
- Atom.content 仍存全文（chunk 边界为运行时元数据，可存 overlay sidecar）
- **与 Q1 兼容**——EditBuffer 接口不变，scope 从整文档变为 chunk

**三路径关系**：Transclusion 覆盖 99% 场景（用户主动拆分），Rope/DocumentSession 是剩余 1% 的工程兜底（用户无法/不愿拆分）。三者与 Q2 全量字符串裁决均兼容。

### 裁决

**D11 = 全量字符串为 source of truth + EditOp 可选 advisory hint。**

1. buffer 层存储和传递全量字符串——`_content: String` 是唯一权威值
2. EditOp（`_lastOp`）是可选优化 hint，消费者可读可忽略，不影响正确性
3. v0.3 不使用 EditOp（调用方不传 `op`，等效全量替换 = 选项 A）
4. 持久化路径（FFI → SQLite → FTS5）全量写入，v0.3 无需改动
5. 大文档演化首选 Transclusion（语义层，Q1 完全兼容），Rope / DocumentSession 作为物理层兜底预留（需 API 扩展但不推翻 Q1）
6. 性能边界明确：100KB 内无感知，500KB 边界，1MB+ 需要演化方案

---

## Q3: EditBuffer ↔ TextEditingController 桥接机制 — RESOLVED

### 问题定义

DI-1 细化4 识别的核心问题：

> 编辑中的 pane 触发 `buffer.edit()` → `notifyListeners()` → **自身也会 rebuild** → 可能导致光标跳动或循环。需要区分"本地编辑"（不需要更新自身 TextEditingController）和"远程同步"（需要更新其他 pane 的 TextEditingController）。

### 当前实现分析

**NoteEditor 现状**（`lib/features/notes/note_editor.dart`，110 行）：

NoteEditor 是一个**纯展示 widget**（"dumb widget"），通过 props 接收状态：

```dart
class NoteEditor extends StatefulWidget {
  final String content;          // 从 coordinator 传入的全量 markdown
  final int focusRequestId;      // 焦点请求令牌
  final ValueChanged<String> onChanged;  // 编辑回调
}
```

桥接机制在 `didUpdateWidget` 中：

```dart
if (widget.content != _textController.text) {
  _textController.value = TextEditingValue(
    text: widget.content,
    selection: TextSelection.collapsed(offset: widget.content.length),
  );
}
```

build 方法中直接透传 `onChanged`：

```dart
TextField(
  controller: _textController,
  onChanged: widget.onChanged,  // → coordinator → draftManager
  ...
)
```

**数据流链路**：

```
当前（props-based bridge）：
  用户键入 → TextField.onChanged → widget.onChanged → coordinator.updateDraft()
                                                           → draftContent = newText
                                                           → notifyListeners()
                                                           → AnimatedBuilder rebuild
                                                           → NoteEditor(content: newText)
                                                           → didUpdateWidget: newText == controller.text → NO-OP ✓

  Tab 切换 → coordinator.selectNote()
           → draftContent = loadedContent
           → notifyListeners() → rebuild
           → NoteEditor(content: loadedContent)
           → didUpdateWidget: loadedContent != controller.text → 更新 controller ✓
```

### 目标架构：Manual Listener

Phase 2 中 NoteEditor 演化为 **MarkdownEditorPane**，直接持有 EditBuffer 引用，使用 manual listener 模式：

```dart
class MarkdownEditorPane extends StatefulWidget {
  final EditBuffer buffer;      // 直接引用，不再经 coordinator 中转

  @override
  State<MarkdownEditorPane> createState() => _MarkdownEditorPaneState();
}

class _MarkdownEditorPaneState extends State<MarkdownEditorPane> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.buffer.content);
    _focusNode = FocusNode();
    widget.buffer.addListener(_onBufferChanged);
  }

  @override
  void didUpdateWidget(covariant MarkdownEditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Buffer swap（tab 切换导致 EditorShellService 传入新 buffer）
    if (widget.buffer != oldWidget.buffer) {
      oldWidget.buffer.removeListener(_onBufferChanged);
      widget.buffer.addListener(_onBufferChanged);
      _textController.value = TextEditingValue(
        text: widget.buffer.content,
        selection: TextSelection.collapsed(offset: widget.buffer.content.length),
      );
    }
  }

  @override
  void dispose() {
    widget.buffer.removeListener(_onBufferChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Buffer 变更监听——字符串比较守卫防自循环
  void _onBufferChanged() {
    final bufferContent = widget.buffer.content;
    if (bufferContent != _textController.text) {
      // 远程同步（其他 pane 编辑、外部加载）→ 更新 controller
      _textController.value = TextEditingValue(
        text: bufferContent,
        selection: TextSelection.collapsed(offset: bufferContent.length),
      );
    }
    // 本地编辑 → controller.text 已等于 buffer.content → NO-OP
  }

  /// 用户键入回调
  void _onTextChanged(String newText) {
    widget.buffer.edit(newText);  // 直接写 buffer，不经 coordinator
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      onChanged: _onTextChanged,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      // ... styling
    );
  }
}
```

### 循环风险确认

**Flutter 行为验证**：`_textController.text = newContent` 或 `_textController.value = TextEditingValue(...)` **不会**触发 `TextField.onChanged` 回调。Flutter 的 `onChanged` 仅在**用户输入路径**（键盘输入、IME、粘贴等用户动作）触发，programmatic 赋值不触发。

因此 `_onBufferChanged` → 更新 controller → **不会**回调 `_onTextChanged` → **无循环风险**。

完整数据流（多 pane 场景）：

```
用户在 Pane A 键入 "x"
  → Pane A 的 TextEditingController.text 变为 "...x"（Flutter 内部更新，在 onChanged 之前）
  → TextField.onChanged("...x")
  → _onTextChanged("...x")
  → buffer.edit("...x")
      → buffer._content = "...x"
      → buffer._rev++
      → buffer.notifyListeners()
          // debounce timer 由 Service 层管理（细化3 裁决），不在 buffer 内
  → Pane A 的 _onBufferChanged():
      buffer.content = "...x"
      _textController.text = "...x"
      "...x" == "...x" → NO-OP ✓（光标不跳）
  → Pane B 的 _onBufferChanged():
      buffer.content = "...x"
      _textController.text = oldContent
      "...x" != oldContent → 更新 controller ✓
      光标位置重置（→ DI-5 范畴）
```

### 字符串比较守卫的通用性

**核心发现**：字符串比较守卫模式适用于**所有 content_type**，不仅限于 markdown。

差异仅在于"缓存字符串"的持有方式：

| content_type | 本地状态 | 缓存字符串位置 | 序列化/反序列化 |
|-------------|---------|--------------|---------------|
| markdown | `TextEditingController` | `_textController.text`（隐式） | 无需（纯文本直存） |
| canvas (JSON) | `CanvasModel` 对象 | `_lastSerializedContent`（显式缓存） | `CanvasModel.fromJson(buffer.content)` / `toJson()` |
| conversation | `MessageList` 对象 | `_lastSerializedContent`（显式缓存） | `MessageList.fromJson(buffer.content)` / `toJson()` |

**通用桥接模式**（v0.4+ 提取 mixin 时的目标接口）：

```dart
/// EditorPane 通用桥接 mixin（v0.3 不提取，v0.4+ 第二个 EditorPane 出现时提取）
mixin EditorBufferBridge<T extends StatefulWidget> on State<T> {
  EditBuffer get buffer;

  /// content_type 特定：将 buffer.content 应用到本地状态
  /// 返回 false 表示内容未变（等价于字符串比较守卫）
  bool applyContentToLocalState(String content);

  /// content_type 特定：将本地状态序列化为 string
  String serializeLocalState();

  void onBufferChanged() {
    final bufferContent = buffer.content;
    applyContentToLocalState(bufferContent);
    // 实现内部做字符串比较或语义比较
  }

  void onLocalEdit() {
    final serialized = serializeLocalState();
    buffer.edit(serialized);
  }
}
```

对于 markdown，`applyContentToLocalState` = 比较 `_textController.text`；对于 canvas，= 比较 `_lastSerializedContent` 并反序列化为 `CanvasModel`。桥接模式相同，仅序列化/反序列化层不同。

### 方案比较

| 方案 | 描述 | 优势 | 劣势 |
|------|------|------|------|
| **A: Props-based（当前）** | coordinator 中转，NoteEditor 通过 widget props 接收 content | 纯展示 widget，易测试 | 多一层中转；tab/draft 耦合在 coordinator |
| **B: AnimatedBuilder** | EditorPane 包裹 AnimatedBuilder(animation: buffer) | 与现有 controller 模式一致 | rebuild 整个 build()，无法细粒度控制 |
| **C: Manual listener（选定）** | EditorPane 直接 addListener/removeListener 到 buffer | 精确控制更新时机；无额外 rebuild；buffer swap 清晰 | 需手动管理生命周期 |
| **D: ValueListenableBuilder** | 包裹 ValueListenableBuilder | 自动管理生命周期 | EditBuffer 不是 ValueListenable；需额外适配 |

**选择 C（Manual listener）的理由**：

1. **精确控制**：`_onBufferChanged` 仅在 buffer 变更时执行字符串比较 + 条件更新，不触发 `setState` / rebuild
2. **无额外 rebuild**：内容更新通过 `_textController.value = ...` 直接注入 TextField，不经过 `build()`
3. **Buffer swap 清晰**：`didUpdateWidget` 中的 `buffer != oldBuffer` 引用比较处理 tab 切换
4. **生命周期可控**：`initState` add → `didUpdateWidget` swap → `dispose` remove，三点管理

### Buffer 加载阶段处理

EditorPane **不负责** buffer 的 loading 状态处理。loading/error 状态由**外壳 chrome 层**（feature controller 提供的 UI）处理：

```
EditorShellService 传入 buffer:
  buffer.state == loading → 外壳显示 loading 占位
  buffer.state == ready   → 渲染 EditorPane(buffer: buffer)
  buffer.state == error   → 外壳显示 error 占位
```

EditorPane 只在 `ready` 状态下被实例化，`initState` 中 `buffer.content` 一定有值。这与 DI-10 三层职责分离一致（外壳展示 = Feature controller 职责）。

> **注**：`error` 状态是对 DI-1 Q3 细化1 状态机的扩展（`loading → ready | error → disposing`）。DI-1 原始定义为 `loading → ready → disposing`，Q4 细化4 引入 `markError()` 后需在 DI-1 中同步更新状态机。

### Mixin 提取策略

| 阶段 | 做法 |
|------|------|
| v0.3 | 桥接逻辑直接 inline 在 `MarkdownEditorPane` 中（约 30 行） |
| v0.4+ | 当第二个 EditorPane（如 CanvasEditorPane）出现时，提取 `EditorBufferBridge` mixin |

提取触发条件：第二个 EditorPane 实现时发现桥接逻辑重复。不提前抽象——遵循"三次重复再提取"原则，两个 EditorPane 已足够明确模式。

### 裁决

**D12 = Manual listener + 字符串比较守卫，通用于所有 content_type。**

1. MarkdownEditorPane 直接持有 EditBuffer 引用，通过 `addListener`/`removeListener` 监听变更
2. `_onBufferChanged` 使用**字符串比较守卫**（`buffer.content != _textController.text`）区分本地编辑（NO-OP）和远程同步（更新 controller）
3. Flutter 行为保证：programmatic `_textController.value = ...` **不触发** `onChanged`，无循环风险
4. Buffer swap（tab 切换）通过 `didUpdateWidget` 中的**引用比较**（`widget.buffer != oldWidget.buffer`）处理
5. 字符串比较守卫是**通用桥接模式**，适用于所有 content_type——差异仅在序列化/反序列化层
6. v0.3 桥接逻辑 inline 在 MarkdownEditorPane；v0.4+ 第二个 EditorPane 出现时提取 `EditorBufferBridge` mixin
7. EditorPane 不处理 buffer loading 状态——由外壳 chrome 层负责（DI-10 三层分离）
8. Pane B 光标位置重置问题移交 DI-5 范畴

---

## Q4: 阶段 2 内容加载策略 — RESOLVED

### 问题定义

DI-3 两阶段恢复模型中，阶段 2 的入口条件已定义：

```
输入: 阶段 1 产出的 EditBuffer（loading 状态）+ atomId 列表
依赖: RustBridge + SQLite（FFI 调用）
产出: EditBuffer loading → ready（内容填充）
时机: Background Phase（DB 就绪后异步执行）
```

需要裁决：触发时序、调度策略、职责归属、失败处理。

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

启动时序：

```
main()
  ├─ [同步] LocalSettingsStore.ensureInitialized()     // 主题/语言
  ├─ [同步] runApp()                                    // 首帧渲染
  ├─ [异步] _bootstrapLocalRuntime()                    // RustBridge 初始化（非阻塞）
  │    └─ RustBridge.bootstrapLogging()
  │         └─ ensureEntryDbPathConfigured()             // DB 就绪
  └─ NotesPage.initState()
       └─ postFrameCallback → coordinator.loadNotes()
            └─ _prepare() → ensureEntryDbPathConfigured()  // 隐式等待 DB 就绪
```

当前 `_prepare()` 是所有 FFI 调用的隐式门控——内部调用 `RustBridge.ensureEntryDbPathConfigured()`，dedup 保证只初始化一次。

### 已有裁决约束

| 裁决 | 内容 | 对 Q4 的约束 |
|------|------|------------|
| DI-1 Q3 细化1 | EditBuffer 状态机 `loading → ready → disposing`；`loading` 阶段 `edit()/save()/flush()` 均为 no-op | 加载前 UI 安全 |
| DI-3 边界 | atomId 不存在 → 跳过 tab；非 primary group 清空 → 坍缩 | 失败处理已定义方向 |
| DI-3 边界 | 用户在 loading 阶段关闭 tab → 允许（结构操作） | 加载可中断 |
| S2 Phase 2 | Coordinator → Service（直接调用），Service → FFI（persistFn 闭包），Service → Coordinator（onBufferSaved 回调） | 通信模式已定义 |

### 细化议题

| 细化 | 议题 | 核心问题 | 状态 |
|------|------|---------|------|
| 细化1 | 触发时序 | 阶段 1 → 阶段 2 的衔接：DB 就绪信号怎么传递？谁发起加载？入口点在哪？ | RESOLVED |
| 细化2 | 优先级与调度 | P1（active tabs 并行）/ P2（按需）分层；去重策略；并行度控制 | RESOLVED |
| 细化3 | 加载职责归属 | Coordinator vs EditorShellService 的 FFI 调用边界——谁调 `note_get()`？闭包注入还是直接调用？ | RESOLVED |
| 细化4 | 失败处理与运行时统一 | atomId 不存在 / FFI 异常 / 用户中途操作的具体行为；启动恢复与运行时打开共用同一机制的验证 | RESOLVED |

讨论顺序：**细化1 → 细化3 → 细化2 → 细化4**（触发时序 → 职责归属 → 调度策略 → 异常兜底）。理由：触发时序和职责归属是架构骨架，确定后优先级和失败处理自然落位。

---

### 细化1: 触发时序 — RESOLVED

**问题**：阶段 1（纯 Dart 结构恢复）完成后，如何衔接阶段 2（FFI 内容加载）？DB 就绪信号如何传递到加载入口？

#### 用户体感分析

启动时间轴中用户关注三个时刻：

| 时刻 | 事件 | 用户看到 |
|------|------|---------|
| T1 | Flutter 首帧 | 窗口出现 |
| T2 | 布局骨架可见 | Pane 分栏 + tab 条 + loading 占位 |
| T3 | Active tab 内容出现 | 可以编辑 |

**T2 与 T1 的间隔决定是否有"空白闪烁"**。

#### 方案比较

| 方案 | Phase 1 时机 | T2 - T1 | 视觉跳变次数 | 首帧代价 |
|------|-------------|---------|-------------|---------|
| **α 同步（选定）** | `runApp()` 前，与 settings 同阶段 | **0ms**（首帧即布局） | 1 次（loading→content） | +10ms |
| β 异步 | `runApp()` 后 post-frame | ~16ms | 2 次（空→骨架→content） | 0 |
| γ 全等待 | 等 DB + FFI 全部完成 | 300-400ms | 1 次（splash→完整） | 0 |

**选择方案 α**：+10ms 首帧代价换取消除空白闪烁。与 `LocalSettingsStore.ensureInitialized()` 同步加载模式一致。

#### 耗时拆解

| 阶段 | 耗时 | 备注 |
|------|------|------|
| Layout JSON 文件读取 + 树构建 | <10ms | 纯 Dart，文件 <1KB |
| RustBridge 初始化（DLL + DB 配置） | 100-300ms | **唯一有感知的延迟** |
| `note_get()` FFI 调用 | 10-50ms/个 | 本地 SQLite |
| **总 loading 占位时长** | **~150-350ms** | 接近无感 |

#### 阶段 1 → 阶段 2 衔接

复用现有 `_prepare()` 隐式门控模式，不引入新信号原语：

```
main():
  [同步] LocalSettingsStore.ensureInitialized()     // 主题/语言
  [同步] LayoutPersistence.load()                    // ← 新增，Phase 1
  [同步] runApp()                                    // 首帧：完整布局骨架
  [异步] _bootstrapLocalRuntime()                    // RustBridge 初始化
  [异步] 发起 active tabs P1 加载
           → 每个加载 await _prepare()               // 首次等 DB，后续 fast-path
           → note_get() → buffer.initialize() → ready
```

`_prepare()` 内部调用 `RustBridge.ensureEntryDbPathConfigured()`，dedup 保证只初始化一次。Phase 2 加载只需在入口处 `await _prepare()` 即可自然等待 DB 就绪。

#### Layout 加载失败保护

Layout 是非关键数据（不涉及用户内容安全），保护策略从简：

```
LayoutPersistence.load():
  try:
    读取 workspace_layout.json → 解析 → 验证
  catch (解析失败 / schema 不匹配 / 结构不合法):
    1. rename 原文件 → workspace_layout.json.corrupt.{timestamp}
    2. 尝试 .tmp.* 残留文件恢复（原子写入中间态）
       ├─ 有且合法 → 使用 tmp 恢复
       └─ 无或也损坏 → fall back 默认单 pane
    3. 日志记录警告
  文件不存在:
    → 默认单 pane（首次启动，正常路径）
```

- 原文件保留为 `.corrupt` 备份，可人工诊断
- 不引入多版本备份或"抑制持久化"模式——用户下次变更布局时正常写入即可
- 所有笔记内容安全在 SQLite 中，用户只需重新打开 tab 和排列 pane

#### 裁决

1. Phase 1（Layout JSON）在 `runApp()` 前**同步执行**，与 `LocalSettingsStore` 同阶段，消除空白闪烁
2. Phase 2 通过 `_prepare()` 隐式等待 DB 就绪，**复用现有模式**，不引入 `dbReady` 等新原语
3. Layout 加载失败：rename → `.corrupt.{timestamp}` + try tmp recovery + fall back 默认单 pane
4. Layout 非关键数据，无需重量级恢复机制

---

### 细化3: 加载职责归属 — RESOLVED

**问题**：EditorShellService 是通用 tab/buffer 管理，不应耦合特定 content_type 的 FFI 调用。但加载内容需要 FFI。谁负责调 `note_get()`？

#### 当前实现

当前加载职责全在 NotesCoordinator：

```dart
// NotesCoordinator._loadSelectedDetail()
Future<void> _loadSelectedDetail({required String atomId}) async {
  _detailLoading = true;
  notifyListeners();

  await _prepare();
  final response = await _noteListManager.loadNoteDetail(atomId: atomId);
  // ↑ 内部调 noteGetInvoker(atomId)

  _selectedNote = response.note;
  _activeDraftContent = note.content;
  _detailLoading = false;
  notifyListeners();
}
```

Coordinator 持有 FFI invoker → 自己调用 → 自己注入结果。无 Service 层参与。

#### 方案比较

| 方案 | 描述 | Service 通用性 | 与 persistFn 对称 | 遗忘风险 |
|------|------|--------------|-----------------|---------|
| A: Service 直接持有 FFI | Service 内部调 `note_get()` | **破坏**（耦合 FFI） | 不对称 | 无 |
| **B: 闭包注入（选定）** | Service 通过 `loadContentFn` 闭包 | **保持** | **对称** | **无** |
| C: Coordinator 主动加载 | Coordinator 调 FFI → `service.initializeBuffer()` | 保持 | 不对称 | **有**（openTab 后忘记跟进） |

#### Coordinator 作为接线员原则

Coordinator 是**中间人 / 接线员**，负责把各方连接起来，不亲自实现细节：

```
Coordinator 的角色：
  ✓ 构造时注入闭包（loadContentFn / persistFn）——"告诉 Service 怎么联系 FFI"
  ✓ 监听 Service 变更，转发到 UI 层——"传话"
  ✗ 不自己调 note_get() 然后塞回 Service——"不亲自跑腿"
```

这与 PR-0252 coordinator + manager 分解理念一致：Coordinator 做接线，不做实现。

#### Service 双闭包对称设计

```dart
class EditorShellService {
  /// 加载路径：Service 决定时机，闭包提供实现
  final Future<String> Function(String atomId) _loadContentFn;

  /// 保存路径：Service 决定时机，闭包提供实现（S2 已定义）
  final Future<void> Function(String atomId, String content) _persistFn;

  // ...
}

// Coordinator 构造时注入：
service = EditorShellService(
  loadContentFn: (atomId) async {
    await _prepare();
    final response = await _noteGetInvoker(atomId);
    return response.note!.content;
  },
  persistFn: (atomId, content) async {
    await _prepare();
    await _noteUpdateInvoker(atomId, content);
  },
);
```

两条路径对称：

| 路径 | 时机控制 | 实现提供 | 模式 |
|------|---------|---------|------|
| 加载 | Service（启动 P1 / openTab） | Coordinator 闭包 | `loadContentFn` |
| 保存 | Service（debounce / flush） | Coordinator 闭包 | `persistFn` |

#### content_type 扩展性

未来新增 content_type 时，Coordinator 只需换闭包实现，Service 代码零改动：

```dart
// 未来 CanvasCoordinator 注入不同闭包：
service = EditorShellService(
  loadContentFn: (atomId) async {
    await _prepare();
    return _canvasGetInvoker(atomId);  // 不同 FFI 函数
  },
  // ...
);
```

#### 裁决

1. Service 通过 **`loadContentFn` 闭包**加载内容，与 `persistFn` 保存路径对称
2. Service 控制**何时**加载（启动恢复 P1、运行时 openTab），Coordinator 提供**怎么**加载
3. Coordinator 是**接线员**——构造时注入闭包，不亲自调用 FFI 再塞回 Service
4. 加载失败由 Service 内部处理（移除 tab / 坍缩 group），与 Service 已有的结构管理职责一致
5. content_type 扩展时只需换闭包实现，Service 零改动

---

### 细化2: 优先级与调度 — RESOLVED

**问题**：阶段 2 可能面对 N 个 group × M 个 tab 的加载需求。如何分层调度？并行度？去重？

#### 内存估算

| 场景 | Tab 数 | 平均单篇 | 内容内存 |
|------|--------|---------|---------|
| 典型用户 | 10-20 tabs | 5-10KB | 100-200KB |
| 重度用户 | 30-40 tabs（8 pane 满载） | 10-50KB | 300KB-2MB |
| 极端场景 | 40 tabs × 大文档 | 100KB | 4MB |

对桌面应用而言均可忽略。且 P2 按需加载下，未点击的 tab buffer 保持 `loading` 状态，不持有 content 字符串。

#### 调度策略

**P1 — Active Tabs 并行 fire-and-forget**：

```dart
void _loadActiveBuffers() {
  final activeAtomIds = _groups.values
      .map((g) => g.activeAtomId)
      .whereType<String>()
      .toSet();                              // Set 自然去重

  for (final atomId in activeAtomIds) {
    final buffer = _buffers[atomId];
    if (buffer != null && buffer.state == BufferState.loading) {
      _loadSingleBuffer(atomId);             // fire-and-forget，不 await
    }
  }
}

Future<void> _loadSingleBuffer(String atomId) async {
  try {
    final content = await _loadContentFn(atomId);  // 闭包内含 _prepare()
    _buffers[atomId]?.initialize(content);          // loading → ready
  } catch (e) {
    _handleLoadFailure(atomId, e);                  // 细化4 范畴
  }
}
```

为什么 fire-and-forget 而不是 `Future.wait()`：
- 每个 buffer 独立 `loading → ready`，UI 独立响应 `notifyListeners()`
- 一个加载失败不阻塞其他 buffer
- 不需要"全部 P1 完成"的统一信号

去重是自然的：EditBuffer per-atomId 共享（DI-1 引用计数），收集 activeAtomIds 用 Set 即去重。

**P2 — Non-Active Tabs 按需触发**：

```dart
void switchTab(String groupId, String atomId) {
  _groups[groupId]!.activeAtomId = atomId;
  final buffer = _buffers[atomId];
  if (buffer != null && buffer.state == BufferState.loading) {
    _loadSingleBuffer(atomId);               // 复用同一加载函数
  }
  notifyListeners();
}
```

P1 和 P2 共用 `_loadSingleBuffer`，区别仅在触发时机。

**P3 — 后台预加载：不需要**。本地 SQLite < 50ms，按需加载已无感知延迟。未来云同步引入高延迟时再考虑。

**并行度控制：不需要**。P1 最多 8 个并行读（DI-9 pane 上限），SQLite WAL 模式读并发无锁竞争。

#### 资源生命周期架构预留

加载和渲染是**一体两面**——都是资源生命周期管理：

| 层级 | 资源 | 占用量级 | 恢复成本 |
|------|------|---------|---------|
| L1 渲染层 | Widget tree + TextEditingController + 文本布局缓存 | **MB 级**（真正的内存大户） | 零 FFI，从内存 buffer.content rebuild |
| L2 内容层 | buffer.content 字符串 | KB 级 | 一次 `note_get()` < 50ms |

**L1 已在 Q3 架构中自然实现**——EditorPane 只在 active tab 实例化，非 active tab 无 widget tree。切换 tab 时 dispose 旧 EditorPane，渲染资源立即释放。

**L2 v0.3 不实现**，但架构兼容：
- `switchTab()` 切换前调用 `flushPendingSave()`，非 active buffer 永远是 clean 的——**dirty buffer 不可驱逐是伪命题**
- 未来 LRU / sliding window 驱逐策略只需将 clean buffer 从 `ready` 退回 `loading`，用户再次访问时自动触发 `_loadSingleBuffer` 重新加载
- EditBuffer 状态机可扩展（`loading → ready → evicted → ready → disposing`），不推翻现有设计
- 渲染层和内容层可**独立驱逐**：优先驱逐渲染（L1，已实现），内存仍不足时再驱逐内容（L2，未来）

未来关键场景：rich text / canvas 编辑器的渲染状态远大于 markdown，L1 驱逐（仅 active tab 持有 EditorPane）将成为关键性能保障。当前 Q3 的 "EditorPane 只在 ready + active 时实例化" 架构已为此预留空间。

#### 裁决

1. P1（active tabs）并行 fire-and-forget，Set 自然去重
2. P2（non-active tabs）按需触发，复用 `_loadSingleBuffer`
3. 不需要 P3（后台预加载）和并行度控制
4. v0.3 内存无压力（极端 4MB），不实现驱逐机制
5. 架构预留两层驱逐（L1 渲染 / L2 内容），L1 已由 Q3 EditorPane 生命周期自然实现，L2 未来通过 LRU / sliding window 加入，不推翻现有设计

#### 补充：渲染策略前瞻

**问题**：v0.3 的 "Only Active" 渲染策略（Q3 裁决）意味着每次 tab 切换 dispose + rebuild EditorPane。对 markdown（TextField rebuild 几乎无成本）足够，但对未来 rich text / canvas 编辑器（rebuild 可能 50-200ms），频繁切换 tab 的用户会感知卡顿。

**LRU(N) 渲染缓存方案**：

| 策略 | 保活 EditorPane 数 | 内存 | 切换速度 |
|------|-------------------|------|---------|
| OnlyActive = LRU(1)（v0.3） | 1 | 最小 | 每次 rebuild |
| LRU(N)（未来） | 最近 N 个 | 中等 | 最近 N 个 tab：instant |
| AllAlive（IndexedStack） | 全部 | 最大 | 全部 instant |

LRU 优于 sliding window：tab 切换是**随机访问**模式（A→C→A→E），不是顺序浏览。Sliding window 适合连续内容（长文档分页），LRU 适合离散资源（tab 缓存）。

**实现思路**：多个 EditorPane 实例并存，非 active 的用 `Offstage` 隐藏但保持 widget tree + listener 活跃。Cached EditorPane 持续接收 buffer 变更通知（manual listener 保持 attached），切换回来时内容已是最新。

**与 Q3 的兼容性**：

- Q3 的 manual listener 模式在 LRU 下更优——cached EditorPane 保持同步，切换 instant
- `didUpdateWidget` buffer swap 只在 LRU 驱逐后重建新 EditorPane 时触发
- v0.3 的 OnlyActive 是 LRU(1) 特例，未来放宽 N 值是**放宽**不是**推翻**
- 对所有已有裁决（Q1-Q3、DI-1、S2）零结构性冲突

**v0.3 不实现**。当第二种 content_type EditorPane 出现且 rebuild 成本可感知时，升级 OnlyActive → LRU(N)。

---

### 细化4: 失败处理与运行时统一 — RESOLVED

**问题**：加载失败的具体行为？启动恢复与运行时打开是否共用同一机制？

#### 失败信号设计

`loadContentFn` 通过**异常类型**区分失败原因（方式 2）：

```dart
Future<void> _loadSingleBuffer(String atomId) async {
  try {
    final content = await _loadContentFn(atomId);
    _buffers[atomId]?.initialize(content);            // loading → ready
  } on AtomNotFoundException {
    _removeTabFromAllGroups(atomId);                   // 数据不存在 → 移除 tab
  } catch (e) {
    _buffers[atomId]?.markError(e);                    // 调用异常 → 错误占位
  }
}
```

选择异常区分而非返回值（`String?`）的理由：
- "数据不存在"与"调用失败"是不同性质的错误，语义清晰
- 返回值方式容易遗漏 null 判断
- try-catch 在正常路径（加载成功）零性能开销；异常路径（~10-100μs）相比 FFI 调用（10-50ms）小三个数量级，可忽略
- "atomId 不存在"是极低频事件（外部删除数据时才发生），不是热路径

#### 失败场景处理

| 场景 | 异常类型 | Service 行为 | 用户看到 |
|------|---------|-------------|---------|
| atomId 在 DB 中不存在 | `AtomNotFoundException` | 从所有 group 移除该 tab → 非 primary group 清空则坍缩（DI-3） | Tab 消失，其余 tab 正常 |
| FFI 调用异常（DB 锁定、I/O 错误） | 通用异常 | buffer 标记 `error` 状态 → UI 显示错误占位 + retry 按钮 | 错误提示，可点击重试 |
| 用户在 loading 中关闭 tab | — | 允许关闭（DI-3）→ 忽略后续 load 结果 → dispose buffer | Tab 关闭，符合预期 |
| 用户在 loading 中切换 tab | — | 旧 tab 加载继续（fire-and-forget）→ 新 tab 触发 P2 加载 | 新 tab 显示 loading → content |

对 buffer 已 dispose 后返回的加载结果，`_loadSingleBuffer` 中 `_buffers[atomId]?.initialize(content)` 的 `?.` 安全忽略（buffer 已从 map 移除）。

#### 运行时统一

三种触发场景**完全统一**——同一个 `_loadSingleBuffer`，同一套错误处理：

```
启动恢复（P1）：
  _loadActiveBuffers()
    → 遍历 active tabs → _loadSingleBuffer(atomId)   // fire-and-forget

运行时打开新笔记：
  service.openTab(groupId, atomId)
    → 创建 EditBuffer(loading)
    → _loadSingleBuffer(atomId)                        // 复用

运行时切换到未加载 tab（P2）：
  service.switchTab(groupId, atomId)
    → buffer.state == loading?
    → _loadSingleBuffer(atomId)                        // 复用
```

区别仅在触发入口，加载逻辑和失败处理完全一致。

#### 裁决

1. `loadContentFn` 失败通过**异常类型区分**：`AtomNotFoundException`（移除 tab）vs 通用异常（错误占位 + retry）
2. 性能无影响：正常路径 try-catch 零开销；异常路径微秒级，远小于 FFI 调用
3. buffer dispose 后的延迟返回通过 `?.` 安全忽略
4. 启动恢复（P1）、运行时打开、运行时切换（P2）**三场景统一** `_loadSingleBuffer`，零代码分歧

---

## Q5: 方法论 — RESOLVED

### 审计报告建议

§6.3 建议"方案 B（文档 + 原型）"，理由：

> 多实例 TextEditingController 同步在 Flutter 中缺少成熟先例。共享 controller 是否可行？事件广播的延迟特性？

### §6.3 原始顾虑解消状态

| 原始不确定性 | 解消方式 | 对应裁决 |
|------------|---------|---------|
| 共享 controller 是否可行？ | 分析排除——Q3 选择 manual listener，每个 pane 独立 controller | D12 |
| 事件广播延迟？ | Flutter `notifyListeners()` 是同步广播，已确认 | D10 |
| 多 pane 循环/光标跳动？ | Flutter 行为确认：programmatic `controller.text = ...` 不触发 `onChanged` | D12 |
| 同步粒度性能？ | 性能估算 + 现有实现验证：100KB 内无感知 | D11 |
| 内容加载时序？ | 复用现有 `_prepare()` 模式 + fire-and-forget 并行 | Q4 细化1-4 |

### 裁决：方案 A（仅文档）

**不需要原型验证，DI-4 裁决完成后直接进入 PR 实现。**

理由：

1. **§6.3 的全部原始顾虑已通过分析解消**——不需要原型验证已知结论
2. **所有裁决基于现有代码模式的组合**——`ChangeNotifier` / `addListener` / 字符串比较守卫 / `_prepare()` 门控 / 闭包注入，全是当前代码中已验证的模式
3. **Q3 核心桥接机制已在生产代码运行**——`NoteEditor.didUpdateWidget` 字符串比较守卫是当前实际行为，不是理论推演
4. **原型反馈周期与直接实现相当**——本地 Flutter 开发，编译运行即验证，无需单独原型阶段
5. **DI-4 讨论深度已超过原型验证范围**——Q1-Q4 覆盖了数据流、状态机、并发、失败处理、资源生命周期，比最小原型能验证的更广

---

## 关联

- ← DI-1（D1/D2 确定 EditorShellService 接口和 buffer 归属；Q3 细化4 识别桥接问题）
- ← DI-3（两阶段恢复模型——Q4 接收阶段 2 入口约定）
- ← DI-10（EditorPaneBuilder 接口——EditBuffer 是唯一桥接参数）
- → DI-5（光标/冲突处理建立在同步模型之上；Pane B 光标重置问题移交）
- → DI-7（性能基线与同步粒度相关）
- → S2（Q4 细化3 扩展了 persistFn 闭包模式，新增 loadContentFn 对称路径）
- → S1 R14（Q1 补充裁决的 atom_overlays sidecar 模型，由 S1 R14 冻结预留）
- ← 01 审计报告 §4.3 + §6.3

---

*前序议题：[DI-3 布局持久化](DI-3-layout-persistence.md)（RESOLVED）*
*下一个议题：[DI-5 光标独立性 + 冲突处理](DI-5-cursor-and-conflict.md)*
