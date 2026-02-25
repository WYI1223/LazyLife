# PR-0252 P1-1 — 提取 WorkspaceTreeManager

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P1-1` |
| Phase | Phase 1 — 清洁/中等缝隙提取 + Explorer 对话框 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p1-1-workspace-tree-manager` |
| PR Title | `refactor(frontend): PR-0252 P1-1 extract workspace tree manager` |
| Estimated Effort | 2.0 person-day |
| Status | Ready for Review |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 1, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 A2
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

提取 WorkspaceTreeManager 为独立 ChangeNotifier。这是 Phase 1 中体量最大的提取（~700 行来源），对应 0255B A2（清洁缝隙提取）。

提取来源行号（`notes_controller.dart`）：L708–1185, L2699–2714, L2735–2933。

WorkspaceTreeManager 持有 workspace ×6 invoker + WorkspacePort（P0-1 产出）。原 NotesController 保留 facade，转发到 WorkspaceTreeManager。

## Prerequisites

- `P0-1` workspace_port.dart 已合并（WorkspaceTreeManager 依赖 WorkspacePort 接口）

## Scope

In scope:

- 创建 `lib/features/notes/managers/workspace_tree_manager.dart`
- 独立 ChangeNotifier，持有 workspace ×6 invoker + WorkspacePort
- 迁移 NotesController 中全部工作区树操作方法
- 原 NotesController 保留 facade 转发

Out of scope:

- WorkspacePortAdapter 实现（P2-3 NotesCoordinator 中实现）
- 消费者迁移（Phase 2）
- NotesController 删除（Phase 2 P2-3）

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_manager.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_children_loader.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_types.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/managers/workspace_tree_error_utils.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart` (facade forwarding)

## Acceptance Criteria

- [x] 独立 ChangeNotifier，持有 workspace ×6 invoker + WorkspacePort
- [x] <550 行（按物理行统计：`workspace_tree_manager.dart` 当前 533 行；非空行 499 行）
- [x] 原 NotesController facade 转发
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
| D7 | workspace_tree_manager 仅 import `workspace_port.dart`，不 import `features/workspace/` | 零 workspace import |

## Regression

- CI 自动回归
- REG-05（工作区创建文件夹）
- REG-06（工作区拖拽移动笔记）
- REG-07（工作区删除文件夹 dissolve）
- 增量专项 HF-02（WorkspaceTree CRUD）

## Rollback

独立 revert 即可。删除 `workspace_tree_manager.dart`，回退 `notes_controller.dart` facade 改动。

