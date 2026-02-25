# PR-0252 P1-3 — 提取 NoteTagManager

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P1-3` |
| Phase | Phase 1 — 清洁/中等缝隙提取 + Explorer 对话框 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p1-3-note-tag-manager` |
| PR Title | `refactor(frontend): PR-0252 P1-3 extract note tag manager` |
| Estimated Effort | 1.5 person-day |
| Status | Ready for Review |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 1, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 B1
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

提取 NoteTagManager 为独立 ChangeNotifier，对应 0255B B1（中等缝隙提取）。

提取来源行号（`notes_controller.dart`）：L1372–1467, L1588–1664, L2716–2733。

NoteTagManager 持有 noteSetTags + tagsList invoker，管理标签变更队列。中等缝隙意味着需要特别注意 filter→list 回调桥接，在 facade 过渡期临时保留于 NotesController 中（S4 策略）。

## Prerequisites

- 无硬性前置（可与 P1-1、P1-2 并行）
- 但建议在 P0-4 样板 PR 合并后开始，以复用已验证的提取模式

## Scope

In scope:

- 创建 `lib/features/notes/managers/note_tag_manager.dart`
- 独立 ChangeNotifier，持有 noteSetTags + tagsList invoker
- 标签变更队列独立
- 原 NotesController 保留 facade 转发
- 注意 filter→list 回调桥接（S4 facade 过渡期处理）

Out of scope:

- NoteListManager 提取（P2-2，依赖本 PR）
- TagFilter widget 迁移

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/managers/note_tag_manager.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/managers/note_tag_manager_types.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/managers/note_tag_mutation_queue.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart` (facade forwarding)

## Acceptance Criteria

- [x] 独立 ChangeNotifier，持有 noteSetTags + tagsList invoker
- [x] <350 行（`note_tag_manager.dart` 330 行）
- [x] 标签变更队列独立
- [x] CI 全绿
- [x] 测试基线不变（316 pass / 0 known-fail）

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
| D4 | 检查构造函数 | invoker 通过构造函数注入 |
| D5 | `rg -n "import.*flutter" apps/lazynote_flutter/lib/features/notes/managers/` | 仅 `foundation.dart` |
| D8 | `rg -n "notes_style" apps/lazynote_flutter/lib/features/tags/` | 允许 tag_filter.dart（临时豁免） |

## Regression

- CI 自动回归
- REG-04（标签创建与筛选）
- 增量专项 HF-04（标签变更队列）

## Rollback

独立 revert 即可。删除 `note_tag_manager.dart`，回退 `notes_controller.dart` facade 改动。

## Risk Notes

NoteTagManager 的 filter→list 回调桥接需在 NotesController facade 中临时保留（S4 策略）。此桥接在 P2-2（NoteListManager）+ P2-3（Coordinator）中最终清理。

`_noteSetTagsInvoker` 当前由 NotesController（createNote 的 tag-apply 路径）和 NoteTagManager（标签变更路径）共同持有，属于本阶段可接受的临时双归属。该双归属在 P2-2/P2-3 中随 createNote 编排迁移一起清理。
