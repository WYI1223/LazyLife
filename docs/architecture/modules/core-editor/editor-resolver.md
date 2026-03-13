# Module Spec: EditorResolver

> `lib/core/editor/editor_resolver.dart` + `lib/core/editor/markdown_editor_pane.dart`
>
> 设计来源：[DI-10](../../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md) · [S2 Phase 3](../../rulings/S2-tab-draft-save-ownership.md)

---

## 职责

根据 Atom 的 `content_type` 选择对应的 `EditorPane` widget builder。三层职责分离的中间层：

| 层 | 职责 | 组件 |
|---|------|------|
| 状态管理 | groups, buffers, layout | EditorShellService |
| **编辑器选择** | **content_type → EditorPane widget** | **EditorResolver** |
| 外壳展示 | loading/error/metadata/tags | Feature controller |

---

## 接口

```dart
typedef EditorPaneBuilder = Widget Function(
  BuildContext context,
  EditBuffer buffer, {
  bool requestInitialFocus,
});

class EditorResolver {
  final Map<String, EditorPaneBuilder> _registry = {};

  void register(String contentType, EditorPaneBuilder builder);
  EditorPaneBuilder resolve(String contentType);
}
```

### EditorPaneBuilder 参数

**提供**：
- `context` — Flutter theme, locale, MediaQuery
- `buffer.content` — opaque string（markdown 文本 / canvas JSON / conversation JSON）
- `buffer.edit(newContent)` — 写入变更
- `buffer.atomId` — atom 身份
- `buffer.saveState` — 保存状态指示
- `requestInitialFocus` — chrome 层控制首次构建是否请求键盘焦点（默认 `false`）

**不提供**：
- EditorGroupModel（pane 状态与编辑器无关）
- Atom metadata（title, tags）— 由 feature controller chrome 处理
- NotesCoordinator 或 feature 层（编辑器不感知容器）

---

## 注册协议

**v0.3 启动注册**：
```dart
resolver.register(
  'markdown',
  (context, buffer, {bool requestInitialFocus = false}) =>
      MarkdownEditorPane(buffer: buffer, requestInitialFocus: requestInitialFocus),
);
```

静态 Map + `register()` 方法。v0.3 仅注册 `markdown`。未来 `plugin:<id>` 动态注册时复用同一接口。

---

## Fallback 行为

**未知 content_type → 错误占位**（"不支持的内容类型"），**不 fallback 到 markdown**。

理由：canvas JSON 被 markdown 渲染器显示 = 结构破坏。错误占位比静默腐蚀安全。

---

## EditorPane 生命周期

1. EditorPane **仅在 EditBuffer 处于 `ready` 状态时实例化** — loading/error 占位由外壳 chrome 显示
2. Manual listener（`addListener`）监听 buffer 变化
3. String comparison guard 区分本地编辑和远程同步（D12）
4. `didUpdateWidget` 处理 tab 切换（buffer 引用比较）

---

## 渲染范式差异

各 EditorPane 内部完全封装：

| content_type | 范式 | 交互 | 格式 |
|---|---|---|---|
| `markdown` | 文本编辑器 | 键盘、选择、格式化 | 纯文本 markdown |
| `canvas` (v0.4+) | 2D 空间画布 | 拖拽、缩放、绘图 | JSON（元素 + 坐标） |
| `conversation` (v0.4+) | 消息列表 | 滚动、发送 | JSON（消息数组） |

每个 EditorPane：解析 `buffer.content` → 用自己的引擎渲染 → 序列化回字符串 → 调用 `buffer.edit()`。

---

## View Mode 扩展（v0.4+ 占位）

v0.3 签名不变：`resolve(contentType)`。v0.4+ 扩展为：

```dart
resolver.resolve('markdown', viewMode: ViewMode.source)    // → 源码编辑
resolver.resolve('markdown', viewMode: ViewMode.block)     // → Block WYSIWYG
resolver.resolve('markdown', viewMode: ViewMode.preview)   // → 只读预览
```

View Mode 是 per-pane 视图选择，不是 content_type 属性。配套需求：TabEntry 扩展 `viewMode` 字段（EditorGroupModel）。

---

## MarkdownEditorPane（v0.3 参考实现）

`lib/core/editor/markdown_editor_pane.dart` — v0.3 唯一的 EditorPane 实现。

```dart
class MarkdownEditorPane extends StatefulWidget {
  const MarkdownEditorPane({
    super.key,
    required this.buffer,
    this.requestInitialFocus = false,
  });
  final EditBuffer buffer;
  final bool requestInitialFocus;
}
```

**来源**：从 `lib/features/notes/note_editor.dart` 移动并适配。适配变更：

| 适配项 | 说明 |
|--------|------|
| `buffer` 改为 required | 不再接受 null（EditorPane 仅在 buffer ready 时实例化） |
| 删除 `content` 参数 | 从 `buffer.content` 读取 |
| 删除 `onChanged` 参数 | 内部直接调用 `buffer.edit()` |
| `focusRequestId` → `requestInitialFocus` | Chrome 层传入 bool 控制首次构建是否请求焦点（默认 `false`，仅活跃窗格为 `true`） |
| 解耦 `notes_style.dart` | 使用 `Theme.of(context)` 替代 feature 级颜色常量 |

**桥接模式**（DI-4 Q3 D12）inline 在 MarkdownEditorPane 内部实现（~30 行）：
- `initState` → `buffer.addListener(_onBufferChanged)`
- `didUpdateWidget` → swap listener on buffer reference change
- `dispose` → `buffer.removeListener(_onBufferChanged)`
- String guard → `buffer.content != controller.text` → NO-OP on local edit echo

---

## 约束

- v0.3 每个 content_type 单一 builder（无级联 fallback 链）
- 未注册的 content_type 渲染 error，不渲染损坏数据
- EditBuffer 必须通过构造参数注入
- EditorPane 不回调 feature controller（依赖反转）
- EditorPane 不引用 `lib/features/` 内部模块（Rule E）

---

## 实施状态

| 阶段 | 状态 | PR |
|------|------|-----|
| EditorResolver + MarkdownEditorPane | PR-RB-09 **已实施** | PR-RB-09（v0.3，DI-10） |

---

## 关联模块

- ← [EditorShellService](editor-shell-service.md) — EditorResolver 是 Service 成员
- ← [EditBuffer](edit-buffer.md) — EditorPaneBuilder 的唯一桥接参数
- → [S1 R2](../../rulings/S1-atom-projection.md) — content_type 枚举定义
- → [NoteTabStrip](../../rulings/S2-tab-draft-save-ownership.md) — UI widget，渲染 tab 条
