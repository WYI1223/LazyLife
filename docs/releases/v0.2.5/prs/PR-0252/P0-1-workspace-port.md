# PR-0252 P0-1 — 创建 workspace_port.dart 抽象接口

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P0-1` |
| Phase | Phase 0 — 止血与执行基线 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p0-1-workspace-port` |
| PR Title | `refactor(frontend): PR-0252 P0-1 add workspace port abstraction` |
| Estimated Effort | 0.5 person-day |
| Status | Planned |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 0, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 3.3.2 D7
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

创建 `workspace_port.dart` 抽象接口，定义 notes 模块与 workspace 模块之间的抽象边界。

这是 0255B D7 规则（跨 feature 禁止直接 import）的基础设施。notes 模块内定义 `WorkspacePort`（抽象类/接口），声明 `WorkspaceTreeManager` 所需的全部工作区操作签名。后续 app 层负责构造 `WorkspacePortAdapter implements WorkspacePort`（内部持有 `WorkspaceProvider`），并注入 `NotesCoordinator` 构造函数。

此文件为纯接口声明，不含实现逻辑，为 P1-1（WorkspaceTreeManager 提取）的前置。

## Prerequisites

- 无前置任务（Phase 0 起始任务）
- Section 2.3 前置条件全部满足（0255A/B 签字、flutter analyze 零警告、测试基线 312/1）

## Scope

In scope:

- 在 `lib/features/notes/` 下创建 `workspace_port.dart`
- 声明 WorkspaceTreeManager 所需的全部方法签名（约 8–10 个）
- 方法签名来源：当前 `notes_controller.dart` 中所有调用 `WorkspaceProvider` 的方法

Out of scope:

- WorkspacePortAdapter 实现（P1-1 或 P2-3 中实现）
- WorkspaceTreeManager 提取（P1-1）
- 任何 import `features/workspace/` 的代码

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/workspace_port.dart`

## Acceptance Criteria

- [ ] 接口声明 WorkspaceTreeManager 所需的全部方法签名（约 8–10 个）
- [ ] `flutter analyze` 零警告
- [ ] 文件 <30 行
- [ ] 文件内零 `features/workspace/` import

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

Baseline: 312 pass / 1 known-fail (CalendarPage L67 overflow)

## Dependency Rules

| Rule | Check |
|------|-------|
| D7 | `workspace_port.dart` 定义在 notes 内部，不 import `features/workspace/` |

## Regression

- CI 自动回归（flutter test 基线不变）
- 无需手工回归（纯新增文件，不修改现有代码）

## Rollback

独立 revert 即可，无其他 PR 依赖此文件（P1-1 尚未开始）。
