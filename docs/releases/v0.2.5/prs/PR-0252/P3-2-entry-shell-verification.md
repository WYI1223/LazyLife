# PR-0252 P3-2 — 验证 EntryShellPage 零跨 feature import

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P3-2` |
| Phase | Phase 3 — 收口固化 + EntryShellPage 解耦 |
| Type | 回归 |
| Branch | `feat/pr-0252-p3-2-entry-shell-verification` |
| PR Title | `docs(frontend): PR-0252 P3-2 verify entry shell zero cross-feature import` |
| Estimated Effort | 0.5 person-day |
| Status | Planned |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 3, Section 4.2

## Goal

验证 P3-1 完成后 EntryShellPage 达到零跨 feature import 目标，并记录验证结果。

## Prerequisites

- `P3-1` SectionRegistry 已创建并部署

## Scope

In scope:

- 执行验证命令
- 记录验证结果

Out of scope:

- 代码修改

## Verification Command

```bash
rg -n "features/" apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart
```

**预期结果：** 仅匹配 `features/entry/` 内部 import，不匹配 `features/notes/`、`features/tasks/`、`features/calendar/`、`features/search/`、`features/settings/`、`features/diagnostics/`。

## Acceptance Criteria

- [ ] `rg -n "features/" apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart` 仅匹配 `features/entry/` 内部 import
- [ ] 验证结果已记录

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Regression

- CI 自动回归
- REG-10（Section 导航往返）

## Rollback

纯验证任务，无需回滚。
