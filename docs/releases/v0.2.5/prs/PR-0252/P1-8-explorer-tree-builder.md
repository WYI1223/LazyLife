# PR-0252 P1-8 — 提取 ExplorerTreeBuilder

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P1-8` |
| Phase | Phase 1 — 清洁/中等缝隙提取 + Explorer 对话框 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p1-8-explorer-tree-builder` |
| PR Title | `refactor(frontend): PR-0252 P1-8 extract explorer tree builder` |
| Estimated Effort | 1.0 person-day |
| Status | Merged |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 1, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 D2

## Goal

提取 ExplorerTreeBuilder 为独立辅助类，对应 0255B D2。

提取来源行号（`note_explorer.dart`）：L1193–1567。

ExplorerTreeBuilder 是纯输入→输出的辅助类，负责将工作区树数据转换为 UI 树节点。不持有状态，不是 ChangeNotifier。

## Prerequisites

- `P1-4` ~ `P1-7` 全部对话框提取完成（ExplorerTreeBuilder 的代码区域紧邻对话框代码，需先提取对话框避免行号偏移）

## Scope

In scope:

- 创建 `lib/features/notes/explorer_tree_builder.dart`
- 独立辅助类，<400 行
- 纯输入→输出（接收树数据，返回 UI 节点列表）

Out of scope:

- NoteExplorer state 管理变更
- ChangeNotifier 改造（此类不需要）

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/explorer_tree_builder.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_tree_builder_types.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart` (import extracted builder)

## Acceptance Criteria

- [x] 独立辅助类，<400 行（`explorer_tree_builder.dart` 物理行 391）
- [x] 纯输入→输出
- [x] CI 全绿
- [x] 测试基线不变（主干 333 pass / 0 known-fail；本分支 333 pass / 0 known-fail）

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

## Dependency Rules

无特定 D 规则约束（ExplorerTreeBuilder 不是 manager 或 dialog）。但需确保：
- 不 import `features/workspace/` 内部文件（D7 精神）
- 不 import coordinator/manager（非 UI 组件不应持有 controller 引用）

## Verification Snapshot (2026-02-25)

- `dart format apps/lazynote_flutter/lib/features/notes/explorer_tree_builder.dart apps/lazynote_flutter/lib/features/notes/explorer_tree_builder_types.dart apps/lazynote_flutter/lib/features/notes/note_explorer.dart`：通过
- `flutter analyze`：通过（No issues found）
- `flutter test test/note_explorer_tree_test.dart test/note_explorer_workspace_delete_test.dart test/explorer_context_actions_test.dart test/notes_page_explorer_slot_wiring_test.dart`：通过
- `flutter test`：通过（333 pass，基线不变）
- `flutter build windows --debug`：通过
- 依赖边界检查：`features/workspace` 零匹配；`coordinator|manager` import 零匹配

## Regression

- CI 自动回归
- 增量专项 HF-06（TreeBuilder 渲染）
- REG-05 ~ REG-07（工作区树相关操作）

## Rollback

独立 revert 即可。删除 `explorer_tree_builder.dart`，回退 `note_explorer.dart` 的 import 改动。
