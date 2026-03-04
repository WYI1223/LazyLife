# PR-RB-09: S2 Phase 3 + EditorResolver

- Proposed title: `feat(editor): PR-RB-09 EditorResolver with MarkdownEditorPane extraction`
- Status: Ready for Implementation

## Goal

实现 `EditorResolver`：`content_type` → `EditorPaneBuilder` 映射注册。从当前 `NoteEditor` 提取 `MarkdownEditorPane` 并注册为 `markdown` content_type 的 editor。未知 `content_type` 显示错误占位符。

前置条件：PR-RB-08（EditBuffer + manual listener 已可用，已合并）+ PR-RB-02（`content_type` 字段已存在，已合并）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI-10 | `DI-10-editor-resolver-shell.md` Q1~Q4 | Resolver API + 三层分离 + error placeholder + bridging 模式 |
| Module Spec | `modules/core-editor/editor-resolver.md` | EditorResolver 完整规格 |
| Ruling | `rulings/S2-tab-draft-save-ownership.md` Phase 3 | Phase 3 = EditorResolver + MarkdownEditorPane |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-09 | Scope + 依赖 |

## 代码现状分析

### 编辑器已提取

DI-10 描述"当前 `NoteContentArea`（346 行）混合了 Feature Chrome 和 Editor Core"，但**代码已发生演进**：

| 文件 | 行数 | 内容 | 层 |
|------|------|------|-----|
| `note_content_area.dart` | 907 行 | loading/error 状态、breadcrumb、save banner/status、metadata chips、tags、title、action buttons | Feature Chrome（全部） |
| `note_editor.dart` | 157 行 | TextField + manual listener 三点生命周期 + string guard + focus 管理 | Editor Core（已独立） |

结论：Editor Core 已在独立文件 `note_editor.dart`，PR-RB-09 的工作是**移动/适配**（非从混合代码中拆分）。

### NoteEditor 当前接口（需适配）

```dart
class NoteEditor extends StatefulWidget {
  const NoteEditor({
    required this.content,         // ① legacy fallback — 需删除
    required this.focusRequestId,  // ② coordinator 专属 — 需迁移
    required this.onChanged,       // ③ 副作用入口 — 需迁移
    this.buffer,                   // ④ optional — 需改为 required
  });
}
```

适配目标：满足 DI-10 Q1 的 `EditorPaneBuilder = Widget Function(BuildContext, EditBuffer)` 接口。

### `updateActiveDraft` 副作用清单

`NoteEditor` 当前通过 `onChanged: controller.updateActiveDraft` 回调。`updateActiveDraft()` 执行：

| 操作 | 说明 | 迁移方案 |
|------|------|---------|
| `buffer.edit(content)` | 写入 EditBuffer | MarkdownEditorPane 内直接调用 |
| `pinPreviewTab(atomId)` | 编辑时将 preview tab 固定 | 迁移到 coordinator 的 buffer change listener |
| `upsertNote(updated)` | 更新 NoteListManager 缓存中的 title 投影 | 同上 |
| `updateTabTitle(atomId, ...)` | 更新 tab 显示标题 | 同上 |

迁移策略：coordinator 在 `_handleEditorShellChanged` 中检测 active buffer 内容变更，执行 pin + title 更新。具体实现见 Task T4。

### Feature 级依赖（需解耦）

`NoteEditor` 当前引用的 feature 级依赖：

| 依赖 | 来源 | 迁移方案 |
|------|------|---------|
| `kNotesPrimaryText` | `notes_style.dart`（features/notes/） | 改用 `Theme.of(context).textTheme.bodyLarge?.color` |
| `AppLocalizations` hint text | `l10n/app_localizations.dart` | `lib/l10n/` 是共享基础设施，非 feature 内部，`lib/core/editor/` 可直接导入 |

### `contentType` 获取路径

`AtomListItem.contentType` 已在 FFI 绑定中可用。NoteContentArea 可通过 `coordinator.selectedNote?.contentType ?? 'markdown'` 获取。

## 设计方案

### EditorResolver API

```dart
typedef EditorPaneBuilder = Widget Function(BuildContext context, EditBuffer buffer);

class EditorResolver {
  final Map<String, EditorPaneBuilder> _registry = {};

  void register(String contentType, EditorPaneBuilder builder);

  EditorPaneBuilder resolve(String contentType) {
    return _registry[contentType] ?? _unknownTypePlaceholder;
  }

  static Widget _unknownTypePlaceholder(BuildContext context, EditBuffer buffer) {
    return Center(child: Text('Unsupported content type'));
  }
}
```

### 三层分离

```
EditorShellService   — state（groups, buffers, layout）
       │ provides EditBuffer
EditorResolver       — selection（content_type → EditorPane widget）
       │ returns widget builder
Feature Chrome       — shell（loading/error/metadata，由 feature controller 管理）
```

**EditorPaneBuilder 接收**：`context`（theme, locale）+ `buffer`（content, edit(), atomId, saveState）。

**EditorPaneBuilder 不接收**：EditorGroupModel / Atom metadata / NotesCoordinator。

### MarkdownEditorPane 接口

```dart
/// Pure markdown editing surface. Depends only on EditBuffer.
/// Placed in lib/core/editor/ as workbench-level infrastructure.
class MarkdownEditorPane extends StatefulWidget {
  const MarkdownEditorPane({super.key, required this.buffer});

  final EditBuffer buffer;

  @override
  State<MarkdownEditorPane> createState() => _MarkdownEditorPaneState();
}
```

来源：`NoteEditor`（157 行），适配变更：

| 参数 | 变更 |
|------|------|
| `buffer` | `EditBuffer?` → `EditBuffer`（required） |
| `content` | 删除 — 从 `buffer.content` 读取 |
| `onChanged` | 删除 — 内部直接调用 `buffer.edit()` |
| `focusRequestId` | 删除 — focus 管理由外层 chrome 处理（见下文） |

### Focus 管理迁移

当前 `NoteEditor` 通过 `focusRequestId` 接收 coordinator 的 focus 请求。MarkdownEditorPane 不接收此参数。

**方案**：NoteContentArea（chrome）在调用 `resolver.resolve(contentType)(context, buffer)` 后，将返回的 widget 包裹在 `Focus` 管理层中。具体实现：

```dart
// NoteContentArea 中
final editorWidget = resolver.resolve(contentType)(context, buffer);
// 外层用 Focus/FocusScope 管理 focus 请求
```

focus 请求由 chrome 层在 tab 切换时通过 `FocusScope.of(context).requestFocus()` 触发，不经过 EditorPane。

### v0.3 注册

```dart
// EditorShellService 构造时内部注册
resolver.register('markdown', (context, buffer) => MarkdownEditorPane(buffer: buffer));
```

v0.3 仅此一个注册。`canvas`/`conversation`/`plugin:<id>` 留待 v0.4+。

### Error Placeholder（非 fallback）

未知 `content_type` 显示错误占位符而非 fallback 到 markdown。原因：canvas JSON 被 markdown editor 渲染会破坏结构化数据。

### EditorPane 生命周期约束

- EditorPane **仅在 EditBuffer phase == ready 时实例化**。loading/error 占位由外层 Feature Chrome 处理。
- Manual listener bridging（PR-RB-08 pattern）在 `MarkdownEditorPane` 内 inline 实现（~30 行）。

## Task Breakdown

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T1 | 实现 `EditorResolver`（register + resolve + unknown placeholder） | `lib/core/editor/editor_resolver.dart` | 新文件 ~40 行 | — |
| T2 | 从 `NoteEditor` 移动/适配为 `MarkdownEditorPane`：buffer required、删除 content/onChanged/focusRequestId、解耦 `notes_style.dart` 依赖 | `lib/core/editor/markdown_editor_pane.dart` | 新文件 ~120 行 | T1 |
| T3 | `NoteContentArea` 适配：替换 `NoteEditor` 为 `resolver.resolve(contentType)(context, buffer)`，focus 管理外置 | `note_content_area.dart` | 编辑 ~30 行 | T2 |
| T4 | `updateActiveDraft` 副作用迁移：coordinator 监听 buffer 内容变更，执行 pinPreviewTab + title 更新 | `notes_coordinator_impl.dart` | 编辑 ~40 行 | T2 |
| T5 | `EditorShellService` 持有 `EditorResolver` 实例 + 暴露 `resolver` getter | `editor_shell_service.dart` | 编辑 ~10 行 | T1 |
| T6 | `EditorShellService` 构造时注册 `markdown` → `MarkdownEditorPane` | `editor_shell_service.dart` | 含在 T5 | T2 |
| T7 | 删除 `note_editor.dart`（已被 `MarkdownEditorPane` 替代） | `note_editor.dart` | 删除文件 | T3 |
| T8 | 单元测试：resolve registered / resolve unknown / register override | `test/editor_resolver_test.dart` | 新文件 ~60 行 | T1 |
| T9 | Widget 测试：MarkdownEditorPane renders + buffer bridge + didUpdateWidget | `test/markdown_editor_pane_test.dart` | 新文件 ~100 行 | T2 |
| T10 | 文档更新 + DI-10 / S2 Phase 3 标注 implemented | docs | 编辑 | T6 |

## 设计决策

### D1：`updateActiveDraft` 迁移方案

**问题**：当前 `NoteEditor.onChanged` → `coordinator.updateActiveDraft()` 路径包含 4 个操作。MarkdownEditorPane 只调用 `buffer.edit()`，其余 3 个副作用需要新的触发机制。

**方案**：在 coordinator 的 `_handleEditorShellChanged` handler 中，检测 active buffer content 变更并执行副作用：

```dart
void _handleEditorShellChanged() {
  // 检测 active buffer 内容变更 → 执行 pin + title 更新
  final atomId = activeNoteId;
  if (atomId != null) {
    final buffer = _editorShellService.bufferFor(atomId);
    if (buffer != null && buffer.phase == BufferPhase.ready) {
      _editorShellService.activeGroup?.pinPreviewTab(atomId);
      _syncTitleProjection(atomId, buffer.content);
    }
  }
  notifyListeners();
}
```

**权衡**：此方案在每次 EditorShellService 变更时都检查（包括非编辑变更），但成本极低（string comparison + cache lookup）。相比引入额外的编辑事件通道，保持简单。

**优化**：可用 `_lastKnownContent` 字段缓存上次检测的内容，避免无变更时执行 title 投影。或者更精确地，在 `buffer.edit()` 时由 buffer 自身发出 `contentChanged` 通知 — 但这会改变 EditBuffer API，超出本 PR 范围。

### D2：Focus 管理

**问题**：当前 `focusRequestId` 是 coordinator → editor 的单向信号。MarkdownEditorPane 不接收此参数。

**方案**：Chrome 层直接管理 focus。NoteContentArea 使用 `FocusNode` + 在 tab 切换时（`editorFocusRequestId` 变更时）调用 `requestFocus()`。MarkdownEditorPane 内部仍持有自己的 `FocusNode` 用于 TextField，但不接收外部 focus 请求。

### D3：`NoteEditor` 删除时机

`NoteEditor` 被 `MarkdownEditorPane` 完全替代后删除。删除前确认无其他引用（当前仅 `NoteContentArea` 引用）。

## Planned File Changes

| # | 文件 | 变更 |
|---|------|------|
| 1 | `[add]` `apps/lazynote_flutter/lib/core/editor/editor_resolver.dart` | EditorResolver 实现（~40 行） |
| 2 | `[add]` `apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart` | 从 NoteEditor 适配（~120 行） |
| 3 | `[edit]` `apps/lazynote_flutter/lib/features/notes/note_content_area.dart` | 替换 NoteEditor → resolver.resolve()，focus 外置 |
| 4 | `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` | updateActiveDraft 副作用迁移到 buffer change listener |
| 5 | `[edit]` `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart` | 持有 EditorResolver + markdown 注册 |
| 6 | `[delete]` `apps/lazynote_flutter/lib/features/notes/note_editor.dart` | 已被 MarkdownEditorPane 替代 |
| 7 | `[add]` `apps/lazynote_flutter/test/editor_resolver_test.dart` | EditorResolver 单元测试 |
| 8 | `[add]` `apps/lazynote_flutter/test/markdown_editor_pane_test.dart` | MarkdownEditorPane widget 测试 |

**不变的文件**：

- `main.dart` — 注册在 EditorShellService 内部完成，不需要 main 参与
- `notes_coordinator.dart` — 公共 API 无签名变更（`updateActiveDraft` 保留为内部实现，不改签名）
- `EditBuffer` / `EditorGroupModel` / `GroupLayout` — 不改

## Verification

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

```bash
# EditorResolver 文件存在
test -f apps/lazynote_flutter/lib/core/editor/editor_resolver.dart

# MarkdownEditorPane 文件存在
test -f apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart

# NoteEditor 已删除
test ! -f apps/lazynote_flutter/lib/features/notes/note_editor.dart

# core/editor/ 目录包含 7 个文件
ls apps/lazynote_flutter/lib/core/editor/
# 预期：edit_buffer.dart editor_group_model.dart editor_resolver.dart
#       editor_shell_service.dart group_layout.dart layout_persistence.dart
#       markdown_editor_pane.dart
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| `updateActiveDraft` 迁移后 title 更新时序变化 | MEDIUM | 现有测试覆盖 title 投影；迁移后补充 buffer change → title 更新测试 |
| Focus 管理迁移导致 tab 切换后无焦点 | MEDIUM | Widget 测试覆盖 focus 场景；fallback 用 `autofocus: true` |
| MarkdownEditorPane 泄漏 feature 依赖（Rule E 违反） | LOW | `architecture_check.dart` CI 门禁 + 代码审查 |
| `_handleEditorShellChanged` 副作用执行过频 | LOW | 成本极低（string comparison）；可加 `_lastKnownContent` 优化 |

## Acceptance Criteria

- [ ] `EditorResolver` 实现 register + resolve
- [ ] `markdown` content_type → `MarkdownEditorPane`
- [ ] 未知 content_type → error placeholder（非 fallback）
- [ ] `MarkdownEditorPane` 仅依赖 `EditBuffer`（无 coordinator / notes feature 引用）
- [ ] `NoteEditor` 已删除，功能由 `MarkdownEditorPane` 替代
- [ ] `updateActiveDraft` 副作用正确迁移到 buffer change listener
- [ ] Focus 管理在 tab 切换后正常工作
- [ ] `lib/core/editor/` 包含 7 个文件（PR-RB-06 的 4 + PR-RB-07 的 1 + 本 PR 的 2）
- [ ] §Verification CI gates 全部通过（逐项执行并记录输出）
