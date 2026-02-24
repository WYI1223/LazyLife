# PR-0252 P3-1 — 创建 SectionRegistry + 迁移 EntryShellPage

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P3-1` |
| Phase | Phase 3 — 收口固化 + EntryShellPage 解耦 |
| Type | 结构拆分 |
| Branch | `feat/pr-0252-p3-1-section-registry` |
| PR Title | `refactor(frontend): PR-0252 P3-1 create section registry and decouple entry shell` |
| Estimated Effort | 1.0 person-day |
| Status | Planned |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 3, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 4.2 E1
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md` (EntryShellPage 6 跨 feature import)

## Goal

创建 SectionRegistry，消除 EntryShellPage 的 6 个跨 feature import，对应 0255B E1（S7 策略）。

EntryShellPage 当前硬编码 import 了 notes/tasks/calendar/search/settings/diagnostics 6 个 feature 模块。通过 SectionRegistry，各 section 以 builder 方式注册，EntryShellPage 仅依赖 registry 接口。

## Prerequisites

- `P2-3` NotesCoordinator 已创建（EntryShellPage 需先完成 controller → coordinator 迁移）

## Scope

In scope:

- 创建 `lib/app/section_registry.dart`
- 各 section 通过 registry builder 注册
- EntryShellPage 零跨 feature import（仅 import `features/entry/` 内部文件）
- 注册点放在 app 层（如 `main.dart` 或 `app.dart`）

Out of scope:

- 各 feature section 内部改造
- 新 section 添加

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/app/section_registry.dart`
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [edit] `apps/lazynote_flutter/lib/main.dart` 或 `apps/lazynote_flutter/lib/app/app.dart`（注册各 section builder）

## Acceptance Criteria

- [ ] EntryShellPage 零跨 feature import
- [ ] 各 section 通过 registry builder 注册
- [ ] CI 全绿
- [ ] 测试基线不变（312 pass / 1 known-fail）

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
| Rule E | `rg -n "features/" apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart` | 仅匹配 `features/entry/` 内部 import |

## Regression

- CI 自动回归
- REG-10（Section 导航往返）— 确认所有 section 切换正常
- 增量专项 HF-12（SectionRegistry 各 section 注册）

## Rollback

独立 revert 即可。删除 `section_registry.dart`，回退 `entry_shell_page.dart` 为硬编码 import 方式。

## Risk Notes

SectionRegistry 改变了 section 注册方式，但不改变 section 的渲染逻辑。各 feature 的测试不需要改动（注册点在 app 层，不影响 feature 内部）。
