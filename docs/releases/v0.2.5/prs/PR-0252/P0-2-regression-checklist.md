# PR-0252 P0-2 — 编写回归清单 v1

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P0-2` |
| Phase | Phase 0 — 止血与执行基线 |
| Type | 回归 |
| Branch | `feat/pr-0252-p0-2-regression-checklist` |
| PR Title | `docs(frontend): PR-0252 P0-2 add regression checklist v1` |
| Estimated Effort | 0.5 person-day |
| Status | Ready for Review |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 5.2A (回归范围定义)
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`

## Goal

编写回归清单 v1，覆盖笔记核心主流程 8–10 步。此清单将在每个阶段结束时作为手工回归验证依据。

回归清单需覆盖 03 报告 Section 5.2A 定义的 10 个核心用例（REG-01 ~ REG-10）。

## Prerequisites

- 无前置任务（可与 P0-1、P0-3 并行）

## Scope

In scope:

- 编写 REG-01 ~ REG-10 的具体验证步骤和通过标准
- 定义执行方式（手工 / 自动化）
- TL 确认

Out of scope:

- 高风险模块专项验证（HF-XX，按阶段增量添加）
- 自动化测试开发

## Regression Checklist Content (from 03 Section 5.2A)

| 用例 ID | 用例名称 | 关联模块 |
|---------|---------|---------|
| REG-01 | 创建笔记并自动选中 | NotesController/Coordinator |
| REG-02 | 编辑笔记内容触发自动保存 | NoteDraftManager |
| REG-03 | 手动切换笔记触发保存守卫 | NoteTabManager + NoteDraftManager |
| REG-04 | 标签创建与筛选 | NoteTagManager |
| REG-05 | 工作区创建文件夹 | WorkspaceTreeManager |
| REG-06 | 工作区拖拽移动笔记 | WorkspaceTreeManager |
| REG-07 | 工作区删除文件夹（dissolve） | WorkspaceTreeManager |
| REG-08 | 搜索笔记并打开 | SingleEntryController |
| REG-09 | 窗口关闭保存守卫 | NotesPage + NoteDraftManager |
| REG-10 | Section 导航往返 | EntryShellPage |

## Planned File Changes

- [add] `docs/reports/v0.2.5/frontend-review/04-regression-checklist-v1.md`

## Acceptance Criteria

- [x] 覆盖笔记核心主流程 8–10 步（Section 5.2A，当前 10 步）
- [x] 每个用例有明确的操作步骤和预期结果
- [ ] TL 确认

## CI Gates

文档类 PR，CI 门禁仍需通过（确认无误改动）：

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Regression

- 本 PR 本身建立回归基线，无需对自身执行回归

## Rollback

纯文档，直接 revert 即可。
