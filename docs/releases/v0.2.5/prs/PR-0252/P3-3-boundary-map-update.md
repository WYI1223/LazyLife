# PR-0252 P3-3 — 更新 As-is → To-be 边界图

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P3-3` |
| Phase | Phase 3 — 收口固化 + EntryShellPage 解耦 |
| Type | 文档 |
| Branch | `feat/pr-0252-p3-3-boundary-map-update` |
| PR Title | `docs(frontend): PR-0252 P3-3 update boundary map to reflect post-refactor state` |
| Estimated Effort | 0.5 person-day |
| Status | Planned |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 3, Section 4.2
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 3.1/3.2 (As-is/To-be 边界图)

## Goal

更新 0255B Section 3.1/3.2 的 As-is → To-be 边界图，使其反映拆分后的实际代码状态。

## Prerequisites

- `P2-3` NotesCoordinator 已创建（主要结构变化已完成）
- 可与 P3-1、P3-4 并行

## Scope

In scope:

- 更新 0255B 边界图反映拆分后实际状态
- 验证边界图与代码一致

Out of scope:

- 0255B 其他 section 更新
- 新架构设计

## Planned File Changes

- [edit] `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` (Section 3.1/3.2 边界图更新)

## Acceptance Criteria

- [ ] 0255B Section 3.1/3.2 边界图反映拆分后实际状态
- [ ] 边界图与代码一致

## CI Gates

文档类 PR，无 CI 门禁要求。

## Regression

- 无需回归（纯文档更新）

## Rollback

直接 revert 即可。
