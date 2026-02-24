# PR-0252 P1-4 — 提取 CreateFolderDialog

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P1-4` |
| Phase | Phase 1 — 清洁/中等缝隙提取 + Explorer 对话框 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p1-4-create-folder-dialog` |
| PR Title | `refactor(frontend): PR-0252 P1-4 extract create folder dialog` |
| Estimated Effort | 0.5 person-day |
| Status | Planned |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 1, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 D1

## Goal

提取 CreateFolderDialog 为独立 StatefulWidget，对应 0255B D1（Explorer 对话框提取）。

提取来源行号（`note_explorer.dart`）：L1573–1696。

对话框通过回调参数（`onConfirm`, `onCancel`）通信，不持有 controller/coordinator 引用（D6 规则）。

## Prerequisites

- 无前置任务（可与 P1-1~P1-3 manager 提取并行执行）

## Scope

In scope:

- 创建 `lib/features/notes/dialogs/create_folder_dialog.dart`
- 独立 StatefulWidget，~130 行
- 接收回调参数通信

Out of scope:

- 其他对话框提取（P1-5~P1-7）
- ExplorerTreeBuilder 提取（P1-8，依赖全部对话框提取完成）

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/dialogs/create_folder_dialog.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart` (import extracted dialog)

## Acceptance Criteria

- [ ] 独立 StatefulWidget，~130 行
- [ ] 接收回调参数（`onConfirm`, `onCancel`）
- [ ] 可独立 widget test
- [ ] CI 全绿
- [ ] 测试基线不变（313 pass / 0 known-fail）

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

> Note: D6 检查目标目录 `dialogs/` 在本 PR 中首次创建。

## Regression

- CI 自动回归
- REG-05（工作区创建文件夹）
- 增量专项 HF-05（对话框交互）

## Rollback

独立 revert 即可。删除 `create_folder_dialog.dart`，回退 `note_explorer.dart` 的 import 改动。

