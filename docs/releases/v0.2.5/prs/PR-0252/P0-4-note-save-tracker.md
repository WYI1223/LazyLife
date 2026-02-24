# PR-0252 P0-4 — 样板 PR：提取 NoteSaveTracker

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P0-4` |
| Phase | Phase 0 — 止血与执行基线 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p0-4-note-save-tracker` |
| PR Title | `refactor(frontend): PR-0252 P0-4 extract note save tracker` |
| Estimated Effort | 1.0 person-day |
| Status | Ready for Review |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 0, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 A3
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

作为整个重构的**样板 PR**，提取 NoteSaveTracker 为独立 ChangeNotifier。

NoteSaveTracker 是最简 manager（纯状态枚举，无 invoker），用于验证拆分流程、门禁规则和 facade 过渡策略是否可行。此 PR 的流程将作为后续所有 manager 提取的模板。

对应 0255B A3（低风险/清洁缝隙提取）。

## Prerequisites

- `P0-3` PR 门禁规则已确认（本 PR 必须按门禁规则提交）

## Scope

In scope:

- 创建 `lib/features/notes/managers/note_save_tracker.dart`
- NoteSaveTracker 为独立 ChangeNotifier，纯状态枚举，无 FFI invoker
- 原 `notes_controller.dart` 保留 facade，转发到 NoteSaveTracker
- <250 行

Out of scope:

- 其他 manager 提取
- NotesController public API 签名变更

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/managers/note_save_tracker.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart` (facade forwarding)
- [add] `apps/lazynote_flutter/test/note_save_tracker_test.dart` (independent instantiation coverage)

## Acceptance Criteria

- [x] NoteSaveTracker 为独立 ChangeNotifier，<250 行（当前 94 行）
- [x] 可独立实例化测试
- [x] 原 NotesController facade 转发到 NoteSaveTracker
- [x] CI 全绿（`flutter analyze` / `flutter test` / `flutter build windows --debug`）
- [x] 测试无回归失败（main 基线 313 pass / 0 known-fail；当前 316 pass / 0 known-fail，新增 3 个 tracker 测试）

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

Baseline (main before this PR): 313 pass / 0 known-fail

## Dependency Rules

| Rule | Check | Expected |
|------|-------|----------|
| D5 | `rg -n "import.*flutter" apps/lazynote_flutter/lib/features/notes/managers/` | 仅 `foundation.dart` |

> Note: D5 检查目标目录 `managers/` 在本 PR 中首次创建。

## Regression

- CI 自动回归（`flutter test` 通过，无新增失败）
- REG-02（编辑笔记触发自动保存）— 确认保存状态追踪仍正常
- REG-09（窗口关闭保存守卫）— 确认保存守卫仍正常

## Rollback

独立 revert 即可。删除 `managers/note_save_tracker.dart`，回退 `notes_controller.dart` 的 facade 改动。

## Notes for Reviewer

这是整个重构的第一个代码 PR，请特别关注：
1. facade 转发模式是否清晰（后续 PR 将复用此模式）
2. ChangeNotifier 初始化和 dispose 是否正确
3. 门禁规则 D5 是否通过

