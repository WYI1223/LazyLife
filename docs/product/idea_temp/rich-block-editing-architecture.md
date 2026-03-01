# Idea: Rich Block 编辑架构（多编辑范式兼容方案）

| 项目 | 值 |
|------|-----|
| **来源** | DI-4 Q1 补充讨论（Buffer 同步模型 + 编辑范式兼容性） |
| **优先级** | v0.4+ 规划参考 |
| **关联** | DI-4（Buffer 同步）、DI-10（EditorResolver）、S1 R2（content_type）、S1 R14（Sidecar Overlay 冻结预留）、S2 Phase 3（EditorResolver） |

---

## 背景

在 DI-4 的 Buffer 同步模型讨论中，分析了三种 markdown 编辑范式对架构的影响。结论：v0.3 只实现源码编辑，但架构必须预留全部三种范式的兼容路径，且支持用户在编辑模式之间无缝切换。

本文档是完整的架构方案记录，供未来版本升级与适配参考。

---

## 1. 三种编辑范式

### 1.1 源码编辑 + 渲染预览（Obsidian Source Mode / VSCode）

**用户体感**：左边纯文本编辑器显示原始 markdown 语法，右边渲染效果预览。两 pane 实时同步。

```
┌──────────────────────┬──────────────────────┐
│  # My Title          │  My Title            │
│                      │  ─────────           │
│  Some **bold** text  │  Some bold text      │
│  - item 1            │  • item 1            │
│  - item 2            │  • item 2            │
│                      │                      │
│  [编辑器 - 纯文本]     │  [预览 - 只读渲染]     │
└──────────────────────┴──────────────────────┘
```

**架构影响**：

| 组件 | 影响 |
|------|------|
| EditBuffer | 无 — `content` 就是 markdown string |
| Editor Widget | 标准 TextField |
| Preview Widget | 只读渲染，消费 `buffer.content`，不调用 `edit()` |
| EditorResolver | 需要区分 edit / preview 两种 view mode |

### 1.2 Block WYSIWYG（Notion / Jupyter）

**用户体感**：无"源码/预览"区分。每个段落/标题是独立的可编辑块，所见即所得。

```
┌──────────────────────────────────────────────┐
│  My Title              ← h1 块，大号字直接显示  │
│  ─────────                                    │
│  Some bold text        ← paragraph 块         │
│  • item 1              ← list 块              │
│  • item 2                                     │
│  ┌─────────────────┐                          │
│  │ code block      │   ← code 块，独立编辑框   │
│  │ console.log()   │                          │
│  └─────────────────┘                          │
│                                               │
│  [每个块独立编辑，所见即所得]                      │
└──────────────────────────────────────────────┘
```

**架构影响**：

| 组件 | 影响 |
|------|------|
| EditBuffer | 需要审视 — block 编辑器操作单个 block，但 `buffer.content` 是完整 markdown |
| Editor Widget | 完全不同 — block list，每个 block 有独立渲染和编辑逻辑 |
| 数据模型 | block 编辑器内部维护 block tree（parsed AST），与 content（字符串）之间有解析/序列化开销 |
| 持久化 | block 元数据（ID、属性、折叠态）需要独立存储 |

### 1.3 Inline WYSIWYG（Typora）

**用户体感**：单一编辑视图，输入 markdown 语法后自动渲染。光标处显示原始语法，离开后渲染。

```
┌──────────────────────────────────────────────┐
│  My Title              ← 已渲染为 h1          │
│                                               │
│  Some **bold|** text   ← 光标在此，显示语法     │
│                                               │
│  • item 1              ← 已渲染               │
│  • item 2                                     │
│                                               │
│  [单一视图，光标处显示源码，离开后渲染]              │
└──────────────────────────────────────────────┘
```

**架构影响**：

| 组件 | 影响 |
|------|------|
| EditBuffer | 无 — `content` 依然是完整 markdown string |
| Editor Widget | 非常复杂 — 自定义 RichText 编辑器，per-line 渲染/源码模式切换 |
| AST 需求 | 需要实时 AST 支持光标节点定位（"光标在哪个 AST 节点里"） |

---

## 2. 核心设计决策

### 2.1 编辑模式 ≠ content_type

**裁决**：编辑模式是 per-pane 的视图选择，不是 Atom 的 content_type 属性。

- `content_type` 描述内容格式（markdown / canvas / conversation）— S1 R2 已定义
- 编辑模式描述如何编辑同一格式的内容（源码 / block / inline）
- 同一 markdown 文档可以在不同 pane 用不同编辑器打开

这意味着 EditorResolver 的选择维度从 `content_type` 扩展为 `content_type × editor_preference`。

### 2.2 持久化模型：Markdown + Sidecar Overlay

**核心原则**：`Atom.content`（markdown 字符串）始终是持久化层的 source of truth。Block 元数据以独立 overlay 形式存储。

```
Atom
├── content: String           ← markdown 文本（所有场景的基底）
├── content_type: "markdown"  ← S1 R2
└── [atom_overlays 表]        ← JSON sidecar（仅使用过 rich block 时存在）
```

**为什么不用 block tree 作为 source of truth**：

1. 文本编辑零开销要求——用户在纯文本模式下不应有任何 block 层面的性能负担
2. FTS5 索引直接使用 content 字符串，无需额外派生
3. AI 模型对接只需 `Atom.content`（纯 markdown），不需理解 block_meta
4. 从未用过 block 模式的文档没有任何额外存储

**为什么 overlay 独立表不放 atoms 主列**：

1. 读路径隔离——普通 markdown 查询不加载 block JSON
2. 写频率分离——content（高频，每次保存）vs overlay（低频，模式切换/block 编辑时）
3. 从未用过 block 的 atom 在 overlay 表中无行——比 NULL 列更干净

### 2.3 运行时三层模型

```
┌─────────────────────────────────────────────────────────┐
│  Layer 0: Content String                                │
│  ─────────────────────                                  │
│  Atom.content: String (markdown 文本)                    │
│  始终存在 · 持久化到 SQLite · FTS5 索引 · 所有场景的基底    │
│  性能: 存取 O(1)，无解析开销                               │
└────────────────────────┬────────────────────────────────┘
                         │ 按需解析（Inline 编辑 / 大纲提取时）
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Parsed AST (可选)                              │
│  ─────────────────────────                              │
│  markdown string → AST (heading, paragraph, list, ...)  │
│  支持: 节点定位(offset→node)、增量更新(delta→AST patch)    │
│  宿主: 先定协议再定宿主（Rust 增量解析 vs Dart 简单场景）    │
│  服务于: Inline 编辑(光标节点查询)、大纲提取、链接解析        │
│  性能: 首次 parse O(n)，增量更新 O(delta)                  │
└────────────────────────┬────────────────────────────────┘
                         │ 按需构建（进入 block 模式时）
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 2: Block Model (可选)                             │
│  ─────────────────────────                              │
│  AST → editable blocks (每个 block 有独立编辑状态)         │
│  支持: block CRUD、block 拖拽排序、block 级元数据           │
│  宿主: Dart (UI 交互密集)                                 │
│  服务于: Block WYSIWYG 编辑                               │
│  性能: 从 AST 构建 O(n)，编辑单 block O(1)                │
└─────────────────────────────────────────────────────────┘
```

**按需加载原则**：

| 编辑模式 | 加载到 | 额外开销（vs 纯文本） |
|---------|--------|-------------------|
| 源码编辑 | Layer 0 only | **零** |
| 渲染预览 | Layer 0 + 消费者内部 debounce parse | 消费者层 parse，不影响编辑 |
| Inline WYSIWYG | Layer 0 + Layer 1 | AST 增量更新 ~0.01ms/edit |
| Block WYSIWYG | Layer 0 + Layer 1 + Layer 2 | block 映射 O(log b) + serialize O(n) |

---

## 3. Sidecar Overlay 详细设计

### 3.1 数据库 Schema

需要两个 schema 变更（同一 migration，v0.4+）：

```sql
-- 1. atoms 表新增 content_rev 列
ALTER TABLE atoms ADD COLUMN content_rev INTEGER NOT NULL DEFAULT 0;

-- 2. 新建 overlay 表
CREATE TABLE atom_overlays (
  atom_uuid TEXT PRIMARY KEY,
  block_meta TEXT NOT NULL,               -- JSON block 元数据
  overlay_rev INTEGER NOT NULL DEFAULT 0, -- overlay 版本号
  content_rev_at_sync INTEGER NOT NULL,   -- overlay 上次与 content 同步时的 content_rev
  FOREIGN KEY (atom_uuid) REFERENCES atoms(uuid)
);
```

注意：`content_rev` 在当前 schema（migration 1-9）中不存在。v0.3 的 EditBuffer 使用内存 `_rev` 字段（不持久化），v0.4+ 引入持久化 rev 时通过新 migration 添加。

### 3.2 Sidecar JSON 结构

```json
{
  "schemaVersion": 1,
  "blocks": [
    {
      "id": "abc123",
      "type": "heading",
      "level": 1,
      "fingerprint": { "firstChars": "# Title", "length": 7 },
      "attrs": { "collapsed": true }
    },
    {
      "id": "def456",
      "type": "blockquote",
      "fingerprint": { "firstChars": "> important note", "length": 16 },
      "attrs": { "color": "blue", "callout": true }
    },
    {
      "id": "ghi789",
      "type": "paragraph",
      "fingerprint": { "firstChars": "some text", "length": 9 },
      "attrs": {}
    }
  ]
}
```

`fingerprint` 用于 reconciliation 匹配，不存完整内容（content 已在 markdown 中）。

### 3.3 Stale 判定

```
atom.content_rev > overlay.content_rev_at_sync → stale → 需要 reconciliation
atom.content_rev == overlay.content_rev_at_sync → 同步 → 直接使用
```

不使用内存 `is_stale` 布尔——两个 rev 的比较就是 stale 判定，天然持久化。

### 3.4 原子事务

```sql
-- 文本编辑保存
BEGIN;
  UPDATE atoms SET content = ?, content_rev = content_rev + 1 WHERE uuid = ?;
  -- overlay 不动，content_rev 自然增长 → stale
COMMIT;

-- Block 编辑保存（两步：先更新 atoms，再 upsert overlay）
BEGIN;
  UPDATE atoms SET content = ?1, content_rev = content_rev + 1 WHERE uuid = ?2;
  -- ?3 = block_meta JSON, ?4 = 上一步更新后的 content_rev（由应用层读取或计算后绑定）
  INSERT INTO atom_overlays (atom_uuid, block_meta, overlay_rev, content_rev_at_sync)
    VALUES (?2, ?3, 1, ?4)
  ON CONFLICT(atom_uuid) DO UPDATE SET
    block_meta = excluded.block_meta,
    overlay_rev = overlay_rev + 1,
    content_rev_at_sync = excluded.content_rev_at_sync;
COMMIT;
```

---

## 4. Reconciliation 协议

### 4.1 触发时机

- 用户从文本模式切换到 block 模式（主触发）
- 跨 pane 文本→block 的 300-500ms 节流窗口到期（延迟触发）
- 应用启动时检测到 stale overlay（自动触发）

### 4.2 算法要求

```
输入：当前 markdown 文本 + 旧 block_meta sidecar
输出：对齐后的 block tree + 更新后的 sidecar

步骤：
1. Parse markdown → structural blocks（heading, paragraph, list, code, ...）
2. 对齐旧 sidecar blocks 和新 structural blocks
3. 产出匹配结果
```

**匹配信号优先级**：

| 信号 | 权重 | 说明 |
|------|------|------|
| Block type | 高 | heading vs paragraph vs list — type 不匹配直接排除 |
| 内容相似度 | 高 | fingerprint 比较 + fuzzy matching，容忍小幅修改 |
| 相对顺序 | 中 | LCS（最长公共子序列）保持顺序稳定性 |
| 行号/位置 | 低 | 仅作 tie-break，不作主信号（行号在编辑后漂移） |

**匹配结果分类**：

| 结果 | 处理 |
|------|------|
| 匹配成功 | 保留 block ID + attrs，更新 content 指纹 |
| 新增（markdown 中有，sidecar 中无） | 生成新 block ID，默认 attrs |
| 未匹配旧块 | **进入 orphan/preserved 集合 + 提示用户，不静默删除** |

### 4.3 性能预算

| 文档大小 | Block 数 | 预计耗时 | 用户感知 |
|---------|---------|---------|---------|
| 1KB | ~5 | < 0.1ms | 无感 |
| 10KB | ~50 | < 1ms | 无感 |
| 100KB | ~500 | < 10ms | 无感（低于按钮动画时间） |
| 500KB | ~2500 | ~50ms | 微感，可接受 |

**超时策略**：超过预算（如 100ms）→ 后台 isolate 继续，UI 显示 stale 指示，不阻塞输入。

### 4.4 用户场景验证

```
T1: 用户在 rich block 模式创建文档
    heading (id:abc, collapsed:true) — "# Title"
    callout (id:def, color:blue) — "> important note"
    paragraph (id:ghi) — "some text"
    → 保存: content = markdown 文本, overlay = block_meta JSON

T2: 用户切换到纯文本模式
    → 显示纯 markdown 文本，overlay 不加载
    → 编辑: 修改 "some text" → "some modified text"
    → 添加新段落 "new paragraph"
    → 保存: content_rev++, overlay 自动 stale

T3: 用户切换回 rich block 模式
    → 检测 stale → 触发 reconciliation
    → 匹配结果:
      heading (id:abc) — type=heading 匹配 ✓, content ~= ✓ → 保留 collapsed:true
      callout (id:def) — type=blockquote 匹配 ✓, content ~= ✓ → 保留 color:blue
      paragraph (id:ghi) — type=paragraph 匹配 ✓, content 相似 → 保留 ID, 更新 content
      paragraph (id:NEW) — 新段落 → 生成新 ID
    → 用户看到所有 rich block 元数据保留 ✓
```

---

## 5. 同步协议

### 5.1 三路 EditOp

```dart
sealed class EditOp {
  final int baseRev;
}

/// 路径 1：全量快照替换（降级兜底）
class SnapshotReplace extends EditOp {
  final String content;
}

/// 路径 2：字符级增量（源码/Inline 编辑）
class TextDelta extends EditOp {
  final int offset;
  final int deleteCount;
  final String insertText;
}

/// 路径 3：结构化操作（Block 编辑）
class StructuredOp extends EditOp {
  final String opType;     // "moveBlock", "deleteBlock", "mergeBlock", ...
  final Map<String, dynamic> payload;
}
```

### 5.2 降级规则

```
StructuredOp 消费者不理解
  → 降级为 SnapshotReplace（全量替换，始终可用）

TextDelta 的 baseRev ≠ 当前 rev
  → 降级为 SnapshotReplace

任何 op 导致内容不一致
  → 回退到 op 应用前的 buffer.content 快照（latest consistent snapshot）
    + 标记冲突 + 通知用户（不回退到 lastSavedSnapshot，避免丢失未保存编辑）
```

### 5.3 跨模式同步 SLA

| 同步路径 | 延迟目标 | 说明 |
|---------|---------|------|
| 文本 → 文本 | **实时**（每次击键） | 字符串比较 guard |
| Block → 文本 | **50-150ms 去抖** | block 编辑 → serialize markdown → edit() |
| 文本 → Block（跨 pane） | **300-500ms 节流** + 切模式时强制对齐 | throttled 增量 reconcile |

**不对称性说明**：

文本→block 方向不实时是文本编辑零开销的必要代价。用户在纯文本模式下每次击键不产生任何 block 层面的开销。block→文本方向可实时因为 markdown serialize 成本低（string concat）。

在大部分使用场景下，用户不会同时打开文本和 block 两种编辑器看同一文档。Rich block 编辑器本身就是所见即所得，不需要额外的"预览 pane"。多 pane 场景主要用于对照编辑同一文档的不同位置。

### 5.4 EditBuffer 接口

```dart
class EditBuffer extends ChangeNotifier {
  String _content;
  int _rev;                     // 单调递增版本号
  EditOp? _lastOp;              // 最近一次操作

  String get content => _content;
  int get rev => _rev;
  EditOp? get lastOp => _lastOp;

  void edit(String newContent, {EditOp? op}) {
    _content = newContent;
    _rev++;
    _lastOp = op;               // null → SnapshotReplace 语义
    notifyListeners();
  }
}
```

---

## 6. Block 能力分级

### 6.1 两级能力模型

| 级别 | content_type | 存储 | 可降级到源码编辑？ | 适用场景 |
|------|-------------|------|-----------------|---------|
| Markdown-compatible block | `markdown` | 纯 markdown + overlay sidecar | **是**（overlay 丢失时有损降级） | 标题、段落、列表、代码块、引用块 |
| Rich block | 独立 content_type（如 `block_document`——占位命名，正式注册遵循 S1 R2 协议） | JSON block tree | **有损**（丢失 block ID、嵌套属性） | 嵌套 callout、database view、toggle block、Kanban |

### 6.2 Markdown-compatible block 的范围

以下 block 类型可以在 markdown round-trip 中存活（结构信息保留），仅丢失 block 元数据：

| Block 类型 | Markdown 表示 | Round-trip 安全？ |
|-----------|---------------|-----------------|
| Heading | `# / ## / ###` | 是 |
| Paragraph | 纯文本 | 是 |
| List (ordered/unordered) | `- / 1.` | 是 |
| Code block | ` ``` ` | 是 |
| Blockquote | `>` | 是 |
| Table | `\|` 语法 | 是 |
| Image | `![](url)` | 是 |
| Horizontal rule | `---` | 是 |

以下 block 类型在 markdown 中**无原生表示**，需要独立 content_type：

| Block 类型 | 问题 | 建议 |
|-----------|------|------|
| Callout with color | markdown 无 callout 语义 | v0.4+ 评估是否用 `>` + overlay 近似 |
| Toggle / Collapsible | markdown 无折叠语义 | overlay `collapsed` attr 可支持 |
| Database view / Kanban | 无 markdown 对应 | 必须独立 content_type |
| Embedded widget | 无 markdown 对应 | 必须独立 content_type |

### 6.3 与 S1 R2 的关系

S1 R2 已定义 content_type 体系：

> v0.5+ 评估是否参考 AFFiNE/BlockSuite 统一为 block tree（markdown 块可选获得空间属性）。当前不做统一。

本方案与 S1 R2 兼容：

- `markdown` content_type 保持纯 markdown 存储，通过 sidecar 提供 block 元数据
- Rich block（超出 markdown 表达能力的 block）使用独立 content_type
- v0.5+ 如果统一为 block tree，sidecar 模型可平滑过渡——将 overlay 合并为主存储格式

---

## 7. EditorResolver 扩展方向

### 7.1 View Mode 支持

当前 DI-10 的 `resolve(contentType)` 返回唯一 builder。多编辑范式需要扩展：

```dart
// 当前 DI-10
resolver.resolve('markdown')  // → MarkdownEditorPane

// 扩展后（v0.4+）
resolver.resolve('markdown', viewMode: ViewMode.source)   // → MarkdownSourceEditor
resolver.resolve('markdown', viewMode: ViewMode.block)    // → MarkdownBlockEditor
resolver.resolve('markdown', viewMode: ViewMode.inline)   // → MarkdownInlineEditor
resolver.resolve('markdown', viewMode: ViewMode.preview)  // → MarkdownPreviewPane
```

### 7.2 EditorGroupModel 扩展

per-pane 的 tab 需要记录当前编辑模式：

```dart
class TabEntry {
  final String atomId;
  final String title;
  final ViewMode viewMode;  // v0.4+ 新增
}
```

---

## 8. Layer 1 AST 宿主决策（延后）

### 8.1 Rust vs Dart

| 维度 | Rust | Dart |
|------|------|------|
| 解析性能 | 高（tree-sitter 级 ~0.01ms/edit） | 中等（1-5ms for 100KB full parse） |
| 增量解析 | 天然支持（tree-sitter） | 需要自行实现 |
| FFI 开销 | 每次 AST 查询需过 FFI | 无 |
| 复杂度 | 高（Rust Core 职责扩展） | 低（Dart 包丰富） |
| 共享能力 | AST 可服务于 FTS5 增强、大纲、链接解析 | 仅服务于 UI 层 |

### 8.2 决策原则

**"先定协议再定宿主"**——在 Layer 1 的接口协议（parse / apply delta / query node）稳定之前，不锁定实现语言。v0.3 不实现 Layer 1。

### 8.3 Rule A 兼容性分析

如果 Rust 维护 AST：

> Rule A: Invariants, validation, persistence, indexing, sync → Rust Core.

AST 可视为"内容索引"（类似 FTS5），服务于大纲提取、链接解析、搜索高亮定位。这属于 Rule A 的 indexing 范畴，不违反。

但 AST 也服务于 UI 渲染（Inline 编辑的光标节点定位）。这是 display-derived state。

**结论**：AST 是双重用途。如果主要目的是索引+结构查询，放 Rust 合理。如果主要目的是 UI 渲染辅助，放 Dart 合理。按使用场景判断，不强制归类。

---

## 9. 消费者分层设计原则

**通知无条件，消费有策略。**

EditBuffer 的 `edit()` 每次调用 `notifyListeners()`，不区分消费者。每个消费者自行决定响应策略：

| 消费者类型 | 更新成本 | 推荐策略 | 示例 |
|-----------|---------|---------|------|
| 编辑器 pane（文本） | 极低 | 同步响应 | 另一个文本 pane |
| 状态指示器 | 极低 | 同步响应 | dirty 圆点、字数 |
| 渲染预览 | 高 | widget 层 debounce（~300ms） | Obsidian 式预览 |
| Block 编辑器 pane | 中-高 | 300-500ms throttle | 跨 pane block 更新 |
| 大纲/TOC | 中等 | widget 层 debounce（~500ms） | 侧边栏大纲 |

**去抖/节流在消费者层实现，不在 EditBuffer 层**：

1. EditBuffer 是 content_type 无关的（DI-10）
2. 不同消费者的 debounce 时间不同
3. 去抖策略是 UI 展示决策，不是数据模型决策

---

## 10. 实施路线（建议）

### v0.3 — 基础协议预留

| 项 | 实现 |
|---|------|
| EditBuffer | `content: String` + `rev: int` + `edit(String, {EditOp? op})` |
| EditOp 体系 | sealed class 定义（SnapshotReplace / TextDelta / StructuredOp） |
| overlay 表 | 不创建（schema 设计已确定） |
| 编辑模式 | 仅源码编辑 |

### v0.4 — Block 编辑 + Sidecar

| 项 | 实现 |
|---|------|
| atom_overlays 表 | 新增 migration |
| Reconciliation | 基础实现（结构指纹 + LCS 对齐） |
| MarkdownBlockEditor | EditorPane 注册 |
| EditorResolver view mode | `resolve(contentType, viewMode)` |
| TextDelta | 源码编辑产出 delta |
| StructuredOp | Block 编辑产出 structured op |

### v0.5 — Inline 编辑 + AST

| 项 | 实现 |
|---|------|
| Layer 1 AST | 宿主确定（基于 v0.4 性能基准） |
| MarkdownInlineEditor | EditorPane 注册 |
| AST 共享 | 大纲、链接解析复用 AST |

### v0.5+ — 统一 Block Tree 评估

| 项 | 评估 |
|---|------|
| AFFiNE/BlockSuite 模式 | 评估是否统一为 block tree 存储（S1 R2 已预留） |
| Sidecar → Primary | 评估 overlay 模型是否升级为主存储 |

---

## 11. 与其他设计决策的关系

| 设计项 | 关系 |
|--------|------|
| DI-4 Q1 | 本方案是 Q1 补充裁决的完整展开 |
| DI-4 Q2 | D11 修正为"全量 string + 可选 EditOp"，与本方案一致 |
| DI-4 Q3 | 桥接机制需适配 TextDelta（有 delta 时可精确更新 controller 而不重置光标） |
| DI-5 | 光标独立性 + 冲突处理建立在 rev 协议之上 |
| DI-10 | EditorResolver 扩展 view mode 归属 DI-10 |
| S1 R2 | content_type 体系不变，sidecar 是 markdown content_type 的补充 |
| S2 Phase 3 | EditorResolver 注册多编辑器归属 Phase 3 |

---

*来源：DI-4 Q1 补充讨论（2026-02-28）*
