# PR-0421: Editor Pane Fixes — Overflow, Cursor, Scroll, Tab Switch

- Proposed title: `fix(editor): pane overflow, cursor position, scroll and tab switch polish`
- Status: Draft

## Goal

修复四个编辑器 pane 问题：(#50) detail Column 在窄 pane（~186px）时触发 RenderFlex overflow；(#49) 点击 pane 时 TextEditingController 因 buffer 变更重置 selection 导致光标跳至末尾；(#48) 非焦点 pane 无法通过鼠标滚轮滚动；(#47) 前台 split 模式下 tab 切换时无论 buffer 是否已在内存中都重走 FFI，造成可感知的延迟。四个修复均为纯 Flutter 层变更，不涉及 Rust Core 或 FFI 协议。

前置条件：无（均为独立 Flutter UI/逻辑修复，不依赖 v0.4 其他 PR）

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| 现有实现 | `apps/lazynote_flutter/lib/features/notes/note_content_area.dart` | #50 根因：detail Column 未限制高度，fixed-height 子元素在窄 pane 下溢出 |
| 现有实现 | `apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart` | #49 根因：`_onBufferChanged` 在远端变更时调用 `TextEditingValue(text: ...)` 丢失 selection；#48 修复：需在 TextField 外包裹 scroll 事件拦截 |
| 现有实现 | `apps/lazynote_flutter/lib/core/editor/edit_buffer.dart` | #47 参考：`BufferPhase` 枚举 + `phase` accessor，用于在 switch 前检查 buffer 是否已 ready |
| 现有实现 | `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` | #47 根因：`selectNote` 每次调用 `_loadSelectedDetail`，即使 buffer 已 ready 也执行完整 FFI note_get |

---

## Scope

In scope:

- **#50**：`NoteContentArea` detail Column 主体对窄 pane 的响应式处理——元数据区域（Wrap chip 行、tags 行、标题行）用 `Flexible` / `ConstrainedBox` 保护，保证在极窄 pane 下 overflow 不发生，必要时折叠次要元素
- **#49**：`MarkdownEditorPane._onBufferChanged` 精确区分本地 echo 与远端同步：远端同步时保留当前 `TextSelection`，仅在 buffer 首次初始化（loading → ready）时将游标置于末尾
- **#48**：在 `MarkdownEditorPane` build 返回的 widget 外层包裹 `Listener`，拦截 `PointerScrollEvent` 并将其转发给内部 `ScrollController`，使非焦点 pane 也可响应鼠标滚轮
- **#47**：`selectNote` 在调用 `_loadSelectedDetail` 之前检查对应 `EditBuffer` 的 `phase`：若 `phase == BufferPhase.ready` 且 `_detailLoadedAtomId == atomId`，则跳过 FFI note_get，仅执行 `_syncActiveNoteState` + `notifyListeners`
- 上述四处修复对应的单元 / widget 测试补充或更新

Out of scope:

- `MarkdownEditorPane` 增加完整 `ScrollController` API 暴露（非本 PR 设计目标，scroll 拦截方案已足够）
- 多 pane 间拖拽改变宽度的 overflow 修复（属于 layout resize 相关问题，另立 issue）
- Buffer 预加载策略整体重设计（#47 修复仅针对 `selectNote` 路径，不重构 `loadActiveBuffers` 策略）
- FFI 协议或 Rust Core 变更
- 新增 l10n 字符串（修复不涉及新 UI 文案）

---

## Design

### Fix #50 — RenderFlex overflow in detail Column

**根因**：`note_content_area.dart` 中 `_buildContent` 返回的 `Column` 包含若干固定高度/自适应高度的子 widget，最后一个 `Expanded(child: ...)` 是编辑器主体。当 pane 宽度约 186px 时，`LayoutBuilder` 之内的 `Row` + `_TopActionCluster` 仍正常工作（`compactActions` 阈值 520px 生效），但 `Wrap`（metadata chips）、`Row`（title icon + text）以及 `_NoteTagsSection` 的 `Wrap` 在多行折叠后累计高度可能超出 `Column` 的可用高度，导致 `Expanded` 内的 `TextField` 被推出边界。

**修复方案**：

1. 将 metadata chips `Wrap` 包裹在 `AnimatedSize` + 高度限制保护内，或在 `LayoutBuilder` 中检测 `constraints.maxWidth < 240`，隐藏 metadata chip 行（保留 title + tags + editor）。
2. 将 `_NoteTagsSection` 在极窄模式（`< 240px`）下改为 `maxLines: 1` / `Clip.hardEdge` 保护，防止无限 wrap 增高。
3. 确保整个 detail `Column` 本身带有 `ClipRect` 或外层 `Column` 使用 `mainAxisSize: MainAxisSize.max` + `Flexible` 而非直接 `Expanded` 包裹 metadata 区段，使其在高度不足时优先压缩而非溢出。

**具体实现**（文件：`note_content_area.dart`）：

```dart
// ── 在 _buildContent 内，metadata 区段外层包裹 ──
// 原有 Wrap（metadata chips）改为：
LayoutBuilder(
  builder: (context, constraints) {
    // Why: 在极窄 pane（< 240px）下隐藏次要 metadata chip 行，
    // 防止 Wrap 多行折叠后累计高度导致 Column overflow (#50)。
    if (constraints.maxWidth < 240) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [ /* 原有 chips */ ],
    );
  },
),

// ── tags section 极窄保护 ──
// 替换原有 _NoteTagsSection 为带高度保护的版本：
ConstrainedBox(
  constraints: const BoxConstraints(maxHeight: 56),
  child: ClipRect(
    child: _NoteTagsSection( /* ... */ ),
  ),
),
```

> 注：`Expanded(child: editor)` 保持不变，是 Column 弹性占满剩余空间的正确写法。overflow 根源在 metadata 区段未限高，而非 Expanded 本身。

---

### Fix #49 — Cursor jumps to end on buffer change

**根因**：`markdown_editor_pane.dart` 中 `_onBufferChanged`（buffer 变更监听）对远端 sync（非本地 echo）执行：

```dart
// 现有代码（行 102）
_textController.value = TextEditingValue(text: widget.buffer.content);
```

`TextEditingValue(text: ...)` 不携带 `selection`，默认 `TextSelection.collapsed(offset: -1)` 或 `offset: text.length`（Flutter 实现细节），实际效果是将游标重置到末尾。在 split 模式下，另一 pane 的编辑会触发共享 buffer 的 `notifyListeners`，此 listener 被无 selection 的 `value =` 覆盖，导致本 pane 光标跳位。

同样地，`didUpdateWidget` 中 buffer 切换时也有同样问题（行 76-79）。

**修复方案**：

保留当前 `TextSelection`，仅在 buffer 完成 loading→ready 首次初始化时（用户尚未 interact）将游标置于末尾；后续的远端 sync 一律保留原始 selection：

```dart
// ── _onBufferChanged 修复 ──
void _onBufferChanged() {
  final newText = widget.buffer.content;
  if (newText == _textController.text) return; // 本地 echo：string guard 已处理
  // 远端 sync：保留当前光标位置
  final oldSel = _textController.selection;
  final clampedOffset = oldSel.extentOffset.clamp(0, newText.length);
  _textController.value = TextEditingValue(
    text: newText,
    // Why: 保留光标位置；若原位置超出新内容长度则 clamp (#49)
    selection: TextSelection.collapsed(offset: clampedOffset),
  );
}

// ── didUpdateWidget buffer 切换修复 ──
// 切换 buffer 时（不同 atom），重置游标到末尾是合理行为（新文档）。
// 但对同一 buffer 的更新走 _onBufferChanged，不再需要 didUpdateWidget 中的覆写。
// 保持 didUpdateWidget 逻辑，仅确保 selection 合法：
if (newContent != _textController.text) {
  _textController.value = TextEditingValue(
    text: newContent,
    selection: TextSelection.collapsed(offset: newContent.length), // 新 buffer：末尾合理
  );
}
```

**补充**：`initState` 中的初始化同理：buffer 刚 loaded（`loading → ready`）时可置于末尾，这是唯一合理的"重置到末尾"时机。

---

### Fix #48 — Non-focused pane cannot scroll via mouse wheel

**根因**：Flutter `TextField`（和底层 `EditableText`）只在 focus 获取后才处理 `PointerScrollEvent`。非活动 pane 的 `TextField` 无 focus，鼠标滚轮事件被忽略。

**修复方案**：

在 `MarkdownEditorPane` 的 `State` 中持有一个 `ScrollController`，并将 TextField 的 `scrollController` 属性绑定（Flutter TextField 支持 `scrollController` 参数）。在外层加 `Listener` 拦截 `PointerScrollEvent`，手动调用 `scrollController.jumpTo` / `animateTo`：

```dart
// ── State 扩展 ──
late final ScrollController _scrollController;

@override
void initState() {
  super.initState();
  _scrollController = ScrollController();
  // ... 其余初始化不变
}

@override
void dispose() {
  _scrollController.dispose();
  // ... 其余 dispose 不变
  super.dispose();
}

// ── build 修复 ──
@override
Widget build(BuildContext context) {
  return Listener(
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) {
        // Why: 拦截鼠标滚轮，转发给 ScrollController，
        // 使非焦点 pane 也可滚动 (#48)
        final newOffset = (_scrollController.offset + event.scrollDelta.dy)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(newOffset);
      }
    },
    child: TextField(
      key: const Key('markdown_editor_field'),
      controller: _textController,
      focusNode: _focusNode,
      scrollController: _scrollController, // 新增绑定
      onChanged: (text) => widget.buffer.edit(text),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
      decoration: InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        hintText: _l10nText(
          fallback: 'Start writing...',
          pick: (l10n) => l10n.notesEditorHintText,
        ),
      ),
    ),
  );
}
```

> 注：`ScrollController` 需在 `_scrollController.hasClients` 为 true 后才可读 `position`。`onPointerSignal` 中需加 `_scrollController.hasClients` guard。

---

### Fix #47 — Tab switching triggers FFI re-read when buffer is already in memory

**根因**：`notes_coordinator_impl.dart` 中 `selectNote` 每次调用 `_loadSelectedDetail(atomId: atomId)`，该方法总是调用 `_noteListManager.loadNoteDetail(atomId: atomId)` 即 FFI `note_get`。即使该 atom 的 `EditBuffer` 已经处于 `BufferPhase.ready`（内容在内存中），也会重走网络/IO 路径，造成可见的 loading 指示器闪烁和延迟。

**修复方案**：

在 `selectNote` 调用 `_loadSelectedDetail` 前，先检查 buffer state：

```dart
Future<bool> selectNote(String atomId) async {
  if (activeNoteId == atomId &&
      _detailLoadedAtomId == atomId &&
      !_detailLoading &&
      _detailErrorMessage == null) {
    return true; // 现有快路径：完全无变化
  }
  if (activeNoteId case final currentId? when currentId != atomId) {
    final flushed = await flushPendingSave();
    if (!flushed) return false;
  }
  _openAndActivateTab(atomId);
  notifyListeners();

  // Why: 若 EditBuffer 已处于 ready 阶段且 metadata 已加载，
  // 跳过 FFI re-read，直接 sync 状态 (#47)。
  // 仅在 buffer 尚在 loading/error 或首次打开时走完整加载路径。
  final buffer = _editorShellService.bufferFor(atomId);
  final noteMetaLoaded = noteById(atomId) != null;
  if (buffer != null &&
      buffer.phase == BufferPhase.ready &&
      noteMetaLoaded &&
      _detailErrorMessage == null) {
    _detailLoadedAtomId = atomId;
    _syncActiveNoteState();
    notifyListeners();
    return true;
  }

  await _loadSelectedDetail(atomId: atomId);
  return true;
}
```

**约束**：
- `noteById(atomId) != null` 保证 note metadata（title、tags、updatedAt 等）已在列表中，避免 detail 显示空白
- `_detailErrorMessage` 有值时仍走完整加载（支持用户手动 refresh 恢复）
- 该优化仅作用于 `selectNote` 路径（tab 切换）；首次打开 tab（buffer 在 `loading` 阶段）、`refreshSelectedDetail`、`createNote` 路径不受影响

---

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Dart | #50：极窄 pane metadata chip 行响应式隐藏（< 240px LayoutBuilder guard） | `apps/lazynote_flutter/lib/features/notes/note_content_area.dart` | S | — |
| T2 | Dart | #50：tags section ConstrainedBox + ClipRect 高度保护（maxHeight: 56） | `apps/lazynote_flutter/lib/features/notes/note_content_area.dart` | S | T1 |
| T3 | Dart | #49：`_onBufferChanged` 保留 TextSelection（clamp offset 到新文本长度） | `apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart` | S | — |
| T4 | Dart | #48：State 添加 ScrollController；build 外层包 Listener 拦截 PointerScrollEvent | `apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart` | S | T3 |
| T5 | Dart | #47：`selectNote` 添加 buffer-ready 快路径，跳过 FFI note_get | `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` | S | — |
| T6 | Dart | 测试：#50 overflow guard widget test（pane 宽 186px 断言无 overflow） | `apps/lazynote_flutter/test/notes_page_c3_test.dart` | M | T1 T2 |
| T7 | Dart | 测试：#49 cursor preservation unit test（MarkdownEditorPane buffer sync 不重置 selection） | `apps/lazynote_flutter/test/markdown_editor_pane_test.dart` | M | T3 |
| T8 | Dart | 测试：#47 tab switch skip-FFI unit test（buffer ready 时 selectNote 不调用 note_get invoker） | `apps/lazynote_flutter/test/notes_controller_tabs_test.dart` | M | T5 |

---

## Planned File Changes

- `[edit]` apps/lazynote_flutter/lib/features/notes/note_content_area.dart (#50 overflow guard + #50 tags section 高度限制)
- `[edit]` apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart (#49 cursor preservation + #48 scroll forwarding)
- `[edit]` apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart (#47 buffer-ready fast path in selectNote)
- `[edit]` apps/lazynote_flutter/test/notes_page_c3_test.dart (#50 overflow regression test)
- `[edit]` apps/lazynote_flutter/test/markdown_editor_pane_test.dart (#49 cursor 保留测试 + #48 scroll listener 存在性测试)
- `[edit]` apps/lazynote_flutter/test/notes_controller_tabs_test.dart (#47 tab switch 跳过 FFI 测试)

---

## Verification

### CI gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# 验证 #50：overflow guard LayoutBuilder 已写入 note_content_area.dart
grep -c "constraints.maxWidth < 240" apps/lazynote_flutter/lib/features/notes/note_content_area.dart
# 预期：至少 1 匹配

# 验证 #50：tags section 高度保护已写入
grep -c "maxHeight: 56" apps/lazynote_flutter/lib/features/notes/note_content_area.dart
# 预期：至少 1 匹配

# 验证 #49：_onBufferChanged 保留 selection（clamp 关键词）
grep -c "clamp" apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart
# 预期：至少 1 匹配

# 验证 #48：PointerScrollEvent 拦截已写入
grep -c "PointerScrollEvent" apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart
# 预期：至少 1 匹配

# 验证 #48：ScrollController 绑定到 TextField
grep -c "scrollController" apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart
# 预期：至少 2 匹配（声明 + 绑定）

# 验证 #47：buffer ready 快路径已写入
grep -c "BufferPhase.ready" apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart
# 预期：至少 1 匹配

# 验证 Rule E：note_content_area.dart 不引入新的 features/ 跨模块导入
grep -n "import.*features/" apps/lazynote_flutter/lib/features/notes/note_content_area.dart
# 预期：仅已有的 notes_coordinator.dart 导入，无新增其他 feature 模块

# 验证 Rule E：markdown_editor_pane.dart 不引入 features/ 内部模块
grep -n "import.*features/" apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart
# 预期：零匹配
```

---

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| #49 fix：clamp selection offset 后若编辑内容大幅缩短，光标位置仍可能在语义上不理想（如原本在段落中间，clamp 到末尾）| LOW | 这是边界情况；clamp 保证不崩溃，且只发生在远端 pane 删除大量内容时；后续可升级为最近行 heuristic |
| #48 fix：`_scrollController.hasClients` guard 漏写导致 StateError | LOW | T4 实现时需显式 guard；`markdown_editor_pane_test.dart` 中覆盖 scroll 调用路径 |
| #48 fix：TextField 同时持有 ScrollController + Listener，可能与 Flutter 内部 scroll 行为冲突（如触摸板手势） | LOW | Windows 平台优先，触摸板行为次要；如出现双重滚动，可通过 `PointerDeviceKind.mouse` filter 限制仅拦截鼠标设备 |
| #47 fix：buffer ready 快路径跳过 FFI 后，note metadata（tags、updatedAt）可能与 DB 真实值有微小差异 | LOW | 仅在已有 list 数据的情况下生效（`noteById != null`）；list 本身有自己的刷新逻辑；如需强制刷新，`refreshSelectedDetail` 始终走完整路径 |
| #50 fix：极窄 pane 隐藏 metadata chips 后，用户找不到入口添加 icon/image | LOW | metadata chips 当前均为未实现的占位按钮（`TODO(PR-0205A)`），隐藏无功能损失；待 PR-0205A 实现前不需要可访问 |

---

## Acceptance Criteria

- [ ] 在 pane 宽度约 186px 时，`notes_detail_editor` Column 不触发 RenderFlex overflow（flutter test 及手动验证均无红色 overflow banner）
- [ ] pane 宽度 < 240px 时，metadata chip 行（Add icon / Add image / Add comment）不渲染（widget test 断言 `notes_detail_add_icon_button` 不存在于树中）
- [ ] pane 宽度 >= 240px 时，metadata chip 行正常渲染（widget test 断言 `notes_detail_add_icon_button` 存在）
- [ ] split 模式下，在一个 pane 中编辑内容，另一个 pane 的 `MarkdownEditorPane` 光标位置不被重置到末尾（unit test：mock buffer notify，断言 `_textController.selection.extentOffset` 保持原值）
- [ ] `_onBufferChanged` 在远端内容比当前选区短时，offset clamp 到新内容长度而非越界（unit test）
- [ ] buffer 首次从 loading → ready（`initialize` 被调用）时，光标置于末尾（unit test：首次 init 后断言 `selection.extentOffset == content.length`）
- [ ] 非活动 pane（无 focus）的 `MarkdownEditorPane` 可响应鼠标滚轮（widget test：向 `Listener` 注入 `PointerScrollEvent`，断言 `ScrollController.offset` 变化）
- [ ] 鼠标滚轮在 `_scrollController.hasClients == false` 时不抛出 StateError
- [ ] tab 切换到已打开且 buffer 处于 `BufferPhase.ready` 的 note 时，`note_get` FFI invoker 不被调用（unit test：spy invoker call count == 0）
- [ ] tab 切换到首次打开（buffer 处于 `BufferPhase.loading`）的 note 时，仍调用 `note_get` FFI invoker（现有行为不退化）
- [ ] `refreshSelectedDetail` 调用时始终走 FFI 路径，不受 #47 快路径影响
- [ ] `flutter analyze` 零 warning
- [ ] `dart format --output=none --set-exit-if-changed .` 通过
- [ ] `flutter test` 全绿（含现有 54 个测试文件及本 PR 新增/修改的测试）
- [ ] `dart run ../../tools/ci/architecture_check.dart` 通过（Rule E 无新增违反）
- [ ] PR spec Status updated to Merged
