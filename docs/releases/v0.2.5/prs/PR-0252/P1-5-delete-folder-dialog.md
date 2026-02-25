# PR-0252 P1-5 — 提取 DeleteFolderDialog

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P1-5` |
| Phase | Phase 1 — 清洁/中等缝隙提取 + Explorer 对话框 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p1-5-delete-folder-dialog` |
| PR Title | `refactor(frontend): PR-0252 P1-5 extract delete folder dialog` |
| Estimated Effort | 0.5 person-day |
| Status | Ready for Review |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 1, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 D1

## Goal

提取 DeleteFolderDialog 为独立 StatefulWidget，对应 0255B D1。

提取来源行号（`note_explorer.dart`）：L1698–1841。

包含 dissolve/delete-all 两种删除模式选择。通过回调参数通信（D6 规则）。

## Prerequisites

- 无前置任务（可与 P1-4、P1-6、P1-7 并行）

## Scope

In scope:

- 创建 `lib/features/notes/dialogs/delete_folder_dialog.dart`
- 独立 StatefulWidget，~150 行
- 含 dissolve/delete-all 选择

Out of scope:

- 其他对话框提取

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/dialogs/delete_folder_dialog.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [add] `apps/lazynote_flutter/test/delete_folder_dialog_test.dart`

## Acceptance Criteria

- [x] 独立 StatefulWidget，~150 行
- [x] 含 dissolve/delete-all 选择
- [x] CI 全绿
- [x] 测试基线符合预期（主干 324 pass / 0 known-fail；本分支 327 pass / 0 known-fail，新增 3 个对话框测试）

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

## Dependency Rules

| Rule | Check | Expected |
|------|-------|----------|
| D6 | `rg -n "import.*(coordinator|manager)" apps/lazynote_flutter/lib/features/notes/dialogs/` | 零匹配 |

## Verification Snapshot (2026-02-25)

- `flutter analyze`：通过（No issues found）
- `flutter test test/delete_folder_dialog_test.dart test/note_explorer_tree_test.dart test/note_explorer_workspace_delete_test.dart`：通过
- `flutter test`：通过（327 pass；相对主干 324 pass 增加 3 个对话框测试）
- `flutter build windows --debug`：通过
- D6：`rg -n "import.*(coordinator|manager)" apps/lazynote_flutter/lib/features/notes/dialogs/` 零匹配

## Regression

- CI 自动回归
- REG-07（工作区删除文件夹 dissolve）
- 增量专项 HF-05（对话框交互）

## Rollback

独立 revert 即可。
