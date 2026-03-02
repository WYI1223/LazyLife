# PR-RB-10: S3 Phase A — Tag Results Independent Panel

- Proposed title: `feat(tags): PR-RB-10 independent tag results panel with atom_ref breadcrumbs`
- Status: Draft

## Goal

实现 S3 Phase A：选中 tag 时，在 tag 芯片栏与 Explorer 之间展开独立结果面板，显示匹配 Atom 的扁平列表，每条结果附 atom_ref 路径面包屑。Explorer 保持完整树，不受 tag 过滤影响。

前置条件：PR-RB-03（atom_ref 语义统一，所有 Atom 必有 atom_ref）+ PR-RB-05（core-workspace 提取，WorkspaceTreeService 可共享）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Ruling | `S3-tag-workspace-orthogonality.md` | 正交性原则 + Phase A 面板布局 + 面包屑格式 |
| Ruling | `S1-atom-projection.md` R5 | 所有 Atom 必有 atom_ref → 面包屑路径总是可构建 |
| Ruling | `S4-creation-path-unification.md` | atom_ref 创建保证 → 不存在无 ref 的 Atom |
| Ruling | `S8-noteitem-unification.md` | tag 查询返回 AtomListItem（统一 DTO） |
| Rebaseline | `v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-10 | Scope + 依赖 |

## 设计方案

### 面板布局（S3 Phase A）

```
┌─────────────────────┐
│ [Tag A] [Tag B] ... │  ← tag 芯片栏（已有 TagFilter widget）
├─────────────────────┤
│ Tag "Tag A" 结果     │  ← TagResultsPanel（新增，选中 tag 时展开）
│ ├── 📝 Atom X       │     icon（view_hint 驱动）+ title
│ │   📁 FolderA/Sub  │     atom_ref 路径面包屑
│ ├── ✅ Atom Y       │
│ │   📁 根目录       │     根级别 atom_ref 显示 "根目录"
│ └── 📅 Atom Z       │
│     📁 FolderC      │
├─────────────────────┤
│ Explorer             │  ← 被下推，仍完整可见
│ ├── 📁 Tasks/       │
│ └── ...              │
└─────────────────────┘
```

- Tag 取消选择 → 面板收起，Explorer 恢复完整高度
- Tag 结果面板和 Explorer 互不影响内部状态

### 面包屑路径构建

**数据流**：
1. 用户选中 tag → 调用 `notes_list(tag=selectedTag)` 获取匹配 Atom 列表
2. 对每个 Atom，通过 workspace tree 查找其 atom_ref 节点
3. 从 atom_ref 节点沿 `parent_uuid` 链向上遍历至根，收集各层 `display_name`
4. 拼接为面包屑路径：`FolderA / SubFolder`；根级别显示 "根目录"

**实现方式**：Flutter 侧构建面包屑。

理由：workspace_list_children 已可递归获取完整树结构，WorkspaceTreeService（PR-RB-05 提取后）已在 Flutter 侧持有树结构缓存（WorkspaceTreeManager 加载全树），直接从内存中查找 atom_ref 的祖先链即可，无需新增 FFI 函数。

```dart
/// 从已缓存的 workspace tree 中查找 atom 的面包屑路径
List<String> buildBreadcrumb(String atomId, List<TreeNode> flatNodes) {
  // 1. 找到该 atom 的 atom_ref 节点
  final refNode = flatNodes.firstWhereOrNull(
    (n) => n.kind == 'atom_ref' && n.atomUuid == atomId,
  );
  if (refNode == null) return ['根目录'];

  // 2. 沿 parent_uuid 向上收集路径
  final path = <String>[];
  TreeNode? current = _findParent(refNode, flatNodes);
  while (current != null) {
    path.insert(0, current.displayName);
    current = _findParent(current, flatNodes);
  }

  return path.isEmpty ? ['根目录'] : path;
}
```

### 开放设计决策（本 PR 内决策）

| 问题 | 决策 | 理由 |
|------|------|------|
| 面包屑路径格式 | 全路径 | S3 Phase A 目标是提供完整结构上下文 |
| 多 atom_ref 显示策略 | 显示第一个找到的 ref 路径 | v0.3 创建路径仅产生一个 atom_ref（S4），多 ref 是未来场景 |
| 结果排序 | `updated_at DESC` | 与 notes_list 现有排序一致 |
| 空结果状态 | 显示 "No matching atoms" | 与 SearchResultsView 模式一致 |

### TagResultsPanel Widget

```dart
class TagResultsPanel extends StatelessWidget {
  const TagResultsPanel({
    super.key,
    required this.tag,
    required this.items,
    required this.loading,
    required this.breadcrumbs, // Map<AtomId, List<String>>
    required this.onTapItem,
  });

  final String tag;
  final List<AtomListItem> items;
  final bool loading;
  final Map<String, List<String>> breadcrumbs;
  final ValueChanged<String> onTapItem; // atomId
}
```

**每条结果行**：
- Leading icon：由 `view_hint` 决定（note=📝, task=✅, event=📅）
- Title：`item.title`（S1 R8 保证非空）
- Subtitle：面包屑路径（📁 前缀 + `/` 分隔）
- 点击行为：`onTapItem(atomId)` → 在编辑器中打开该 Atom

### 集成点

**NoteTagManager 扩展**：

当前 `applyTagFilter()` 触发 note 列表过滤。PR-RB-10 需额外：
1. 查询匹配 Atom 列表（复用 `notes_list(tag=)` 或 PR-RB-01 后的统一 API）
2. 为每个结果构建面包屑路径（从 WorkspaceTreeService 缓存）
3. 暴露 `tagResults` + `tagBreadcrumbs` 给 UI

**布局集成**：

在 notes feature 的侧边栏布局中，TagFilter 下方插入条件渲染的 `TagResultsPanel`：

```dart
// notes sidebar layout
Column(
  children: [
    TagFilter(...),
    if (coordinator.selectedTag != null)
      TagResultsPanel(
        tag: coordinator.selectedTag!,
        items: coordinator.tagResults,
        loading: coordinator.tagResultsLoading,
        breadcrumbs: coordinator.tagBreadcrumbs,
        onTapItem: coordinator.openNote,
      ),
    Expanded(child: NoteExplorer(...)),
  ],
)
```

## Task Breakdown

| Task | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|
| T1 | 面包屑路径构建器 `breadcrumb_builder.dart` | `lib/shared/breadcrumb_builder.dart` | 新文件 ~40 行 | — |
| T2 | `TagResultsPanel` widget（loading/empty/error/results 四态 + 结果行 + 面包屑） | `lib/shared/tag_results_panel.dart` | 新文件 ~120 行 | T1 |
| T3 | `NoteTagManager` 扩展：tag 查询结果 + 面包屑状态管理 | `note_tag_manager.dart` | 编辑 ~+60 行 | T1 |
| T4 | `NotesCoordinator` 暴露 `tagResults` / `tagBreadcrumbs` / `tagResultsLoading` | coordinator 文件 | 编辑 ~+15 行 | T3 |
| T5 | Notes 侧边栏布局集成：TagFilter 下方插入 TagResultsPanel | notes explorer widget | 编辑 ~+20 行 | T2, T4 |
| T6 | 点击结果行 → openNote 跳转到编辑器 | coordinator / shell | 编辑 ~+5 行 | T5 |
| T7 | 单元测试：breadcrumb_builder | `test/breadcrumb_builder_test.dart` | 新文件 ~50 行 | T1 |
| T8 | Widget 测试：TagResultsPanel 四态渲染 + 点击 | `test/tag_results_panel_test.dart` | 新文件 ~80 行 | T2 |
| T9 | 集成测试：tag 选择 → 面板展开 → 面包屑显示 → 取消 → 面板收起 | `test/tag_panel_integration_test.dart` | 新文件 ~60 行 | T5 |
| T10 | 文档更新 + S3 Phase A 标注 implemented | docs | 编辑 | T6 |

## Planned File Changes

- `[add]` `apps/lazynote_flutter/lib/shared/breadcrumb_builder.dart` (~40 行)
- `[add]` `apps/lazynote_flutter/lib/shared/tag_results_panel.dart` (~120 行)
- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/note_tag_manager.dart` (~+60 行)
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` (~+15 行)
- `[edit]` notes explorer sidebar widget (~+20 行)
- `[add]` `apps/lazynote_flutter/test/breadcrumb_builder_test.dart` (~50 行)
- `[add]` `apps/lazynote_flutter/test/tag_results_panel_test.dart` (~80 行)
- `[add]` `apps/lazynote_flutter/test/tag_panel_integration_test.dart` (~60 行)

## Verification

```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run ../../tools/ci/architecture_check.dart
```

```bash
# 新文件存在
test -f apps/lazynote_flutter/lib/shared/breadcrumb_builder.dart
test -f apps/lazynote_flutter/lib/shared/tag_results_panel.dart

# breadcrumb_builder 不引用 features/ 内部（shared 模块规则）
! rg "features/" apps/lazynote_flutter/lib/shared/breadcrumb_builder.dart

# TagResultsPanel 不引用 features/ 内部
! rg "features/" apps/lazynote_flutter/lib/shared/tag_results_panel.dart
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| Workspace tree 未完整加载时面包屑缺失 | MEDIUM | 面包屑构建器对未找到的 ref 返回 `['根目录']` 作为安全默认值 |
| Tag 查询返回大量结果影响面板性能 | LOW | 复用 notes_list 分页机制（limit=50）；面板使用 ListView.builder 懒加载 |
| 面包屑路径过长溢出 | LOW | 使用 `TextOverflow.ellipsis` + 最大 1 行 |

## Acceptance Criteria

- [ ] 选中 tag 时，TagResultsPanel 在 tag 芯片栏下方展开
- [ ] 结果列表每条显示 icon + title + atom_ref 面包屑路径
- [ ] 根级别 atom_ref 的 Atom 面包屑显示 "根目录"
- [ ] 取消 tag 选择时面板收起，Explorer 恢复完整高度
- [ ] Explorer 树在 tag 过滤期间保持完整不变
- [ ] 点击结果行在编辑器中打开对应 Atom
- [ ] breadcrumb_builder 和 TagResultsPanel 位于 `lib/shared/`（不引用 features/ 内部）
- [ ] §Verification CI gates 全部通过（逐项执行并记录输出）
