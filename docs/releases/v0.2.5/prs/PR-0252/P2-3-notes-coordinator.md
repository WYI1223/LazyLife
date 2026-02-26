# PR-0252 P2-3 — 创建 NotesCoordinator + 消费者迁移

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P2-3` |
| Phase | Phase 2 — 中等/多孔域 + Coordinator 切换 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p2-3-notes-coordinator` |
| PR Title | `refactor(frontend): PR-0252 P2-3 create notes coordinator and migrate consumers` |
| Estimated Effort | 1.5 person-day |
| Status | Ready for Review |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 2, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 C2
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

创建 NotesCoordinator 替换 NotesController，完成消费者迁移。**这是本轮重构的唯一 breaking point。**

对应 0255B C2（Coordinator 创建）。

NotesCoordinator 入口文件 <300 行，持有全部 6 个 manager（NoteSaveTracker, WorkspaceTreeManager, NoteDraftManager, NoteTagManager, NoteTabManager, NoteListManager）。

6 个消费者文件全部从 `_controller` 迁移到 `_coordinator`。迁移完成后，`notes_controller.dart` 先保留为 deprecated typedef 兼容层（在 P2-4 收口移除）。

**重要：** 此 PR 必须与 P2-4（测试迁移）作为耦合回滚单元。

## Prerequisites

- `P2-1` NoteTabManager 已提取
- `P2-2` NoteListManager 已提取
- （隐含：P0-4 NoteSaveTracker, P1-1 WorkspaceTreeManager, P1-2 NoteDraftManager, P1-3 NoteTagManager 全部完成）

## Scope

In scope:

- 创建 `lib/features/notes/notes_coordinator.dart`
- 创建 `lib/features/notes/notes_coordinator_impl.dart`（承载按原样迁移的实现）
- Coordinator 入口文件 <300 行，持有全部 6 个 manager
- 迁移 6 个消费者文件：
  1. `notes_page.dart` — `_controller` → `_coordinator`
  2. `note_content_area.dart` — `_controller` → `_coordinator`
  3. `note_explorer.dart` — `_controller` → `_coordinator`
  4. `note_tab_manager.dart` (UI层) — `_controller` → `_coordinator`
  5. `first_party_ui_slots.dart` — `_controller` → `_coordinator`
  6. `entry_shell_page.dart` — `_controller` → `_coordinator`
- `notes_controller.dart` 转为 deprecated typedef 兼容层（P2-4 移除）
- 实现 WorkspacePortAdapter（implements WorkspacePort，内部持有 WorkspaceProvider），在 app 层注入 Coordinator
- `createNote` 现有 92 行编排逻辑按原样迁移到 Coordinator，不重构内部流程
- 承接 `P2-1` review 的低优先级清理：简化 `NoteTabStateManager.activateOpenNote()` 的冗余分支（行为不变）

Out of scope:

- 测试文件迁移（P2-4 单独处理）
- SectionRegistry（Phase 3 P3-1）
- createNote 内部流程重构

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/notes_coordinator.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`（deprecated typedef 兼容层）
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_content_area.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_tab_manager.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/managers/note_tab_manager.dart`（清理 `activateOpenNote()` 冗余分支）
- [edit] `apps/lazynote_flutter/lib/app/ui_slots/first_party_ui_slots.dart`
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`

## Acceptance Criteria

- [x] Coordinator 入口文件 <300 行（`notes_coordinator.dart` 53 行）；实现按原样迁移至 `notes_coordinator_impl.dart`
- [x] 持有全部 6 个 manager
- [x] 6 个消费者文件全部从 `_controller` 迁移到 `_coordinator`
- [x] `notes_controller.dart` 转为 deprecated typedef 兼容层（将在 P2-4 移除）
- [x] CI 全绿
- [x] 测试基线不变（333 pass / 0 known-fail）— 本分支已验证，P2-4 再次复核
- [x] `NoteTabStateManager.activateOpenNote()` 冗余分支已清理（无行为变更）

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
| D1 | 检查 Page/Explorer 的 import 列表 | 仅 import coordinator，不 import manager |
| D2 | `rg -n "import.*managers/" apps/lazynote_flutter/lib/features/notes/notes_page.dart apps/lazynote_flutter/lib/features/notes/note_content_area.dart apps/lazynote_flutter/lib/features/notes/note_explorer.dart` | 零匹配 |
| D7 | `rg -n "features/workspace" apps/lazynote_flutter/lib/features/notes/managers/` | 零匹配 |

## Regression

- CI 自动回归
- **全量回归清单 v1**（REG-01 ~ REG-10）— 这是 breaking point，需全量走查
- 增量专项 HF-09（Coordinator createNote 全编排）
- 增量专项 HF-10（分屏操作）

## Rollback

**耦合回滚单元：P2-3 + P2-4 必须一起 revert。**

回滚步骤：
1. Revert P2-4（测试迁移）
2. Revert P2-3（Coordinator + 消费者迁移）
3. 回退后 `notes_controller.dart` 恢复为 facade 模式（Phase 1 结束状态）

## Required Reviewer

- **TL review 必须** — 这是唯一 breaking point，需 TL 确认 Coordinator 结构合规。

## Risk Notes

**本阶段最高风险 PR。** 关键风险：

1. **R2 createNote 编排遗漏**：92 行跨域编排迁移时可能遗漏副作用 → 按原样迁移，不重构
2. **R1 异步时序变化**：manager 分离后 `notifyListeners()` 触发顺序可能改变 → Coordinator 内时序保持与原 controller 一致（S5 策略）
3. **R3 测试 mock 断裂**：16 个测试文件需适配 → P2-4 单独处理
