# PR-0252 P2-4 — 测试批量迁移

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P2-4` |
| Phase | Phase 2 — 中等/多孔域 + Coordinator 切换 |
| Type | 测试 |
| Branch | `feat/pr-0252-p2-4-test-migration` |
| PR Title | `refactor(frontend): PR-0252 P2-4 migrate tests from NotesController to NotesCoordinator` |
| Estimated Effort | 0.5 person-day |
| Status | Planned |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 4.2, Section 5.5
- Test migration matrix: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 5.5

## Goal

将 16 个测试文件中的 `NotesController` 引用全部适配为 `NotesCoordinator`，确保测试基线不变。

**重要：** 此 PR 与 P2-3（Coordinator 创建）是耦合回滚单元，必须一起合并或一起 revert。

## Prerequisites

- `P2-3` NotesCoordinator 已创建

## Scope

In scope:

- 迁移 16 个测试文件中的 `NotesController` → `NotesCoordinator` 引用
- 59 处匹配需逐文件适配
- mock 对象需从 MockNotesController 迁移为 MockNotesCoordinator

Out of scope:

- 新增测试
- 测试框架升级

## Test Files to Migrate (from 03 Section 5.5)

1. `notes_page_c1_test.dart`
2. `notes_page_c2_test.dart`
3. `notes_page_c3_test.dart`
4. `notes_page_c4_test.dart`
5. `notes_controller_tabs_test.dart`
6. `notes_controller_workspace_bridge_test.dart`
7. `notes_controller_workspace_tree_guards_test.dart`
8. `note_explorer_tree_test.dart`
9. `note_explorer_workspace_delete_test.dart`
10. `notes_page_explorer_slot_wiring_test.dart`
11. `notes_ui_shell_alignment_test.dart`
12. `explorer_context_actions_test.dart`
13. `workspace_split_v1_test.dart`
14. `workspace_integration_flow_test.dart`
15. `tab_open_intent_migration_test.dart`
16. `cross_lane_workspace_extension_smoke_test.dart`

## Planned File Changes

- [edit] 上述 16 个测试文件中的 `NotesController` 引用 → `NotesCoordinator`

## Acceptance Criteria

- [ ] 16 个测试文件中的 `NotesController` 引用全部适配为 `NotesCoordinator`
- [ ] 312 pass / 1 known-fail 基线不变
- [ ] CI 全绿

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

## Regression

- CI 自动回归（**关键：** 312 pass / 1 known-fail 基线必须不变）
- 增量专项 HF-11（测试迁移完整性）

## Rollback

**耦合回滚单元：P2-3 + P2-4 必须一起 revert。** 不可单独回滚本 PR。
