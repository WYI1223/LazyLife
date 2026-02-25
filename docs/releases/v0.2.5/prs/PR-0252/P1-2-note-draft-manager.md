# PR-0252 P1-2 — 提取 NoteDraftManager

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P1-2` |
| Phase | Phase 1 — 清洁/中等缝隙提取 + Explorer 对话框 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p1-2-note-draft-manager` |
| PR Title | `refactor(frontend): PR-0252 P1-2 extract note draft manager` |
| Estimated Effort | 1.0 person-day |
| Status | In Progress |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 1, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 A4
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

提取 NoteDraftManager 为独立 ChangeNotifier，对应 0255B A4（清洁缝隙提取）。

提取来源行号（`notes_controller.dart`）：L1885–1921, L2348–2464。

NoteDraftManager 持有 noteUpdate invoker，管理自保存定时器逻辑。原 NotesController 保留 facade 转发。

## Prerequisites

- `P0-4` NoteSaveTracker 样板 PR 已合并（复用样板 PR 建立的 facade 模式）

## Scope

In scope:

- 创建 `lib/features/notes/managers/note_draft_manager.dart`
- 独立 ChangeNotifier，持有 noteUpdate invoker
- 自保存定时器（debounce timer）隔离到 NoteDraftManager 内部
- 原 NotesController 保留 facade 转发

Out of scope:

- NoteTabManager 提取（P2-1）
- 保存守卫逻辑变更

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/managers/note_draft_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart` (facade forwarding)

## Acceptance Criteria

- [ ] 独立 ChangeNotifier，持有 noteUpdate invoker
- [ ] <300 行
- [ ] 自保存定时器隔离
- [ ] CI 全绿
- [ ] 测试基线不变（316 pass / 0 known-fail）

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

## Regression

- CI 自动回归
- REG-02（编辑笔记内容触发自动保存）
- REG-03（手动切换笔记触发保存守卫）
- REG-09（窗口关闭保存守卫）
- 增量专项 HF-03（草稿自动保存定时器）

## Rollback

独立 revert 即可。删除 `note_draft_manager.dart`，回退 `notes_controller.dart` facade 改动。

