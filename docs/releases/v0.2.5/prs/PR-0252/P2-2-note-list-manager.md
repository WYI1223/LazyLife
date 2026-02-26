# PR-0252 P2-2 — 提取 NoteListManager

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P2-2` |
| Phase | Phase 2 — 中等/多孔域 + Coordinator 切换 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p2-2-note-list-manager` |
| PR Title | `refactor(frontend): PR-0252 P2-2 extract note list manager` |
| Estimated Effort | 1.5 person-day |
| Status | Merged |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 2, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 C1
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

提取 NoteListManager 为独立 ChangeNotifier，对应 0255B C1（多孔域提取）。

提取来源行号（`notes_controller.dart`）：L1923–2148, L521–543。

NoteListManager 持有 notesList + noteGet invoker，管理笔记列表状态和筛选。原 NotesController 保留 facade 转发。

## Prerequisites

- `P1-3` NoteTagManager 已提取（列表筛选依赖标签 manager）
- `P2-1` NoteTabManager 已提取（列表选中联动 Tab 状态）

## Scope

In scope:

- 创建 `lib/features/notes/managers/note_list_manager.dart`
- 独立 ChangeNotifier，持有 notesList + noteGet invoker
- <400 行
- 原 NotesController 保留 facade 转发

Out of scope:

- NotesCoordinator 创建（P2-3）

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/managers/note_list_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart` (facade forwarding)

## Acceptance Criteria

- [x] 独立 ChangeNotifier，持有 notesList + noteGet invoker
- [x] <400 行（`managers/note_list_manager.dart` 228 行）
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
| D3 | 检查构造函数 | 如需引用 NoteTagManager，通过构造函数注入 |
| D4 | 检查构造函数 | invoker 通过构造函数注入 |
| D5 | `rg -n "import.*flutter" apps/lazynote_flutter/lib/features/notes/managers/` | 仅 `foundation.dart` |

## Regression

- CI 自动回归
- REG-01（创建笔记并自动选中）
- REG-04（标签创建与筛选 — 筛选联动列表）
- 增量专项 HF-08（NoteListManager 列表筛选）

## Rollback

独立 revert 即可。删除 `note_list_manager.dart`，回退 `notes_controller.dart` facade 改动。

## Verification Snapshot (2026-02-26)

- `dart format lib/features/notes/managers/note_list_manager.dart lib/features/notes/notes_controller.dart`：通过
- `flutter analyze`：通过（No issues found）
- `flutter test`：通过（333 pass）
- `flutter build windows --debug`：通过
