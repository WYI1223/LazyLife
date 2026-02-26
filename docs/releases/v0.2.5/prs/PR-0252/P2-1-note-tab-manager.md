# PR-0252 P2-1 — 提取 NoteTabManager

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P2-1` |
| Phase | Phase 2 — 中等/多孔域 + Coordinator 切换 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p2-1-note-tab-manager` |
| PR Title | `refactor(frontend): PR-0252 P2-1 extract note tab manager` |
| Estimated Effort | 1.5 person-day |
| Status | Merged |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 2, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 B2
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

提取 NoteTabManager 为独立 ChangeNotifier，对应 0255B B2（中等缝隙提取）。

提取来源行号（`notes_controller.dart`）：L597–667, L1676–1879。

需整合现有 `note_tab_manager.dart`（431 行 UI 层）+ controller 中的 Tab 逻辑，产出 <400 行的状态层 manager。原 NotesController 保留 facade 转发。

## Prerequisites

- `P0-4` NoteSaveTracker 样板 PR 已合并
- `P1-2` NoteDraftManager 已提取（Tab 切换时需触发保存守卫，依赖 Draft 逻辑已分离）

## Scope

In scope:

- 创建 `lib/features/notes/managers/note_tab_manager.dart`（状态层）
- 整合现有 `note_tab_manager.dart` 的 UI 层 Tab 逻辑
- 独立 ChangeNotifier，<400 行状态层
- 原 NotesController 保留 facade 转发

Out of scope:

- NoteListManager 提取（P2-2）
- NotesCoordinator 创建（P2-3）

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/managers/note_tab_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart` (facade forwarding)
- [edit] `apps/lazynote_flutter/lib/features/notes/note_tab_manager.dart` (可能需要调整 UI 层引用)

## Acceptance Criteria

- [x] 独立 ChangeNotifier，整合现有 `note_tab_manager.dart` (431行 UI) + controller Tab 逻辑
- [x] <400 行状态层（`managers/note_tab_manager.dart` 360 行）
- [x] CI 全绿
- [x] 测试基线不变（333 pass / 0 known-fail）

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
| D3 | 检查构造函数 | 如需引用 NoteDraftManager，通过构造函数注入 |
| D4 | 检查构造函数 | invoker 通过构造函数注入 |
| D5 | `rg -n "import.*flutter" apps/lazynote_flutter/lib/features/notes/managers/` | 仅 `foundation.dart` |

## Regression

- CI 自动回归
- REG-01（创建笔记并自动选中）
- REG-03（手动切换笔记触发保存守卫）
- 增量专项 HF-07（NoteTabManager 完整生命周期）

## Rollback

独立 revert 即可。删除 `managers/note_tab_manager.dart`，回退 `notes_controller.dart` facade 改动。

## Risk Notes

Tab 逻辑跨越 UI 层和状态层，需要清晰界定哪些留在 UI、哪些下沉到 manager。关键判断：Tab 的选中/切换/关闭状态属于 manager，Tab 的视觉渲染属于 UI。

## Verification Snapshot (2026-02-26)

- `dart format lib/features/notes/managers/note_tab_manager.dart lib/features/notes/notes_controller.dart`：通过
- `flutter analyze`：通过（No issues found）
- `flutter test test/notes_page_c3_test.dart test/note_explorer_tree_test.dart test/note_explorer_workspace_delete_test.dart`：通过
- `flutter test`：通过（333 pass）
- `flutter build windows --debug`：通过
