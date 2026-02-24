# PR-0252 P3-5 — TL 阶段验收 + 计划收口签字

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P3-5` |
| Phase | Phase 3 — 收口固化 + EntryShellPage 解耦 |
| Type | 验收 |
| Branch | `feat/pr-0252-p3-5-tl-acceptance` |
| PR Title | `docs(frontend): PR-0252 P3-5 TL stage acceptance and closure sign-off` |
| Estimated Effort | 0.5 person-day |
| Status | Planned |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 3 Phase 3, Section 11
- Code health report: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md`

## Goal

TL 执行最终阶段验收，确认全部 DoD 达成，完成计划收口签字。

## Prerequisites

- `P3-4` 复盘文档已完成

## Scope

In scope:

- TL 验收全部阶段 DoD（Phase 0–3）
- 验收 PR-0252 Acceptance Criteria
- 确认 D1–D8 结构合规性
- 确认测试基线不变
- 确认复盘文档完整
- 签字收口

Out of scope:

- 新任务创建
- PR-0253 启动

## Acceptance Checklist (TL to verify)

### PR-0252 Level

- [ ] 全部任务 `P0-1..P3-5` 完成或有明确 scope-cut
- [ ] `notes_controller.dart` 已删除，由 `NotesCoordinator + managers` 替代
- [ ] EntryShellPage 零跨 feature import
- [ ] D1–D8 检查通过
- [ ] 测试基线 312 pass / 1 known-fail 不变
- [ ] 无 Rust/FFI 签名变更

### Per-Phase DoD (from 03 Section 3)

**Phase 0 DoD:**
- [ ] `workspace_port.dart` 已合并
- [ ] NoteSaveTracker 样板 PR 已合并
- [ ] 回归清单 v1 已确认
- [ ] PR 门禁规则文档化

**Phase 1 DoD:**
- [ ] WorkspaceTreeManager 已合并（P1-1），<500 行
- [ ] NoteDraftManager 已合并（P1-2），<300 行
- [ ] NoteTagManager 已合并（P1-3），<350 行
- [ ] 4 个对话框已合并（P1-4~7），各 <200 行
- [ ] ExplorerTreeBuilder 已合并（P1-8），<400 行
- [ ] NotesController 保留为 facade，原 public API 不变

**Phase 2 DoD:**
- [ ] 原 `notes_controller.dart` 删除
- [ ] `notes_coordinator.dart` <300 行
- [ ] 全部消费者已迁移
- [ ] 无新增 P0 缺陷

**Phase 3 DoD:**
- [ ] EntryShellPage 零跨 feature import
- [ ] 复盘文档完成
- [ ] 边界图更新反映 To-be 实际状态
- [ ] 剩余技术债进入 Debt Log

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

## Regression

**里程碑全量回归：**
- 回归清单 v1 全量（REG-01 ~ REG-10）
- 高风险专项全量（HF-01 ~ HF-12）
- 非功能验证（启动速度、页面切换、异常日志、内存泄漏观察）
- 端到端走查

## Required Reviewer

- **TL — 必须签字**
