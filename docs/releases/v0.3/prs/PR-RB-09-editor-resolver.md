# PR-RB-09: S2 Phase 3 + EditorResolver

- Proposed title: `feat(editor): PR-RB-09 EditorResolver with MarkdownEditorPane extraction`
- Status: Draft

## Goal

实现 `EditorResolver`：`content_type` → `EditorPaneBuilder` 映射注册。从当前 `NoteContentArea` 提取 `MarkdownEditorPane` 并注册为 `markdown` content_type 的 editor。未知 `content_type` 显示错误占位符。

前置条件：PR-RB-08（EditBuffer + manual listener 已可用）+ PR-RB-02（`content_type` 字段已存在）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI-10 | `DI-10-editor-resolver-shell.md` Q1~Q4 | Resolver API + 三层分离 + error placeholder + bridging 模式 |
| Module Spec | `modules/core-editor/editor-resolver.md` | EditorResolver 完整规格 |
| Ruling | `rulings/S2-tab-draft-save-ownership.md` Phase 3 | Phase 3 = EditorResolver + MarkdownEditorPane |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-09 | Scope + 依赖 |

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

### MarkdownEditorPane 提取

当前 `NoteContentArea`（~346 行）混合了 Feature Chrome 和 Editor Core：

| 层 | 内容 | 目标 |
|----|------|------|
| Feature Chrome | loading/error state, breadcrumb, save banner, metadata chips, tags | 保留在 notes feature |
| Editor Core | markdown editing (TextField + formatting) | 提取为 `MarkdownEditorPane` |

`MarkdownEditorPane` 实现 manual listener pattern（PR-RB-08），通过 `buffer.edit()` 写回内容。

### v0.3 注册

```dart
// app startup 或 EditorShellService 初始化时
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
| T2 | 从 `NoteContentArea` 提取 `MarkdownEditorPane` | `lib/core/editor/markdown_editor_pane.dart` | 新文件 ~150 行 | T1 |
| T3 | `NoteContentArea` 瘦身：移除 editor core，保留 Feature Chrome + 委托到 `resolver.resolve(contentType)` | notes feature 文件 | 编辑 ~-150 行 | T2 |
| T4 | `EditorShellService` 持有 `EditorResolver` 实例 | `editor_shell_service.dart` | 编辑 ~5 行 | T1 |
| T5 | App 启动注册 `markdown` → `MarkdownEditorPane` | `main.dart` 或 service 初始化 | 编辑 ~3 行 | T1, T2 |
| T6 | 单元测试：resolve registered / resolve unknown / register override | `test/editor_resolver_test.dart` | 新文件 ~60 行 | T1 |
| T7 | Widget 测试：MarkdownEditorPane renders + buffer bridge | `test/markdown_editor_pane_test.dart` | 新文件 ~80 行 | T2 |
| T8 | 文档更新 + DI-10 / S2 Phase 3 标注 implemented | docs | 编辑 | T5 |

## Planned File Changes

- `[add]` `apps/lazynote_flutter/lib/core/editor/editor_resolver.dart` (~40 行)
- `[add]` `apps/lazynote_flutter/lib/core/editor/markdown_editor_pane.dart` (~150 行)
- `[edit]` notes feature editor widget（瘦身 ~-150 行）
- `[edit]` `apps/lazynote_flutter/lib/core/editor/editor_shell_service.dart`
- `[edit]` `apps/lazynote_flutter/lib/main.dart`
- `[add]` `apps/lazynote_flutter/test/editor_resolver_test.dart`
- `[add]` `apps/lazynote_flutter/test/markdown_editor_pane_test.dart`

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

# core/editor/ 目录包含 6 个文件（PR-RB-06 的 4 + PR-RB-07 的 1 + 本 PR 的 1~2）
ls apps/lazynote_flutter/lib/core/editor/
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| NoteContentArea 拆分边界不清 | MEDIUM | Feature Chrome vs Editor Core 分界明确（DI-10 Q4 三层分离） |
| MarkdownEditorPane 依赖 notes feature 内部 | LOW | 提取时确保仅依赖 EditBuffer，不引入 coordinator 引用 |

## Acceptance Criteria

- [ ] `EditorResolver` 实现 register + resolve
- [ ] `markdown` content_type → `MarkdownEditorPane`
- [ ] 未知 content_type → error placeholder（非 fallback）
- [ ] `MarkdownEditorPane` 仅依赖 `EditBuffer`（无 coordinator 引用）
- [ ] `lib/core/editor/` 完整包含 v0.3 全部 6 个模块文件
- [ ] CI green
