# PR-0252 P0-3 — 确认 PR 门禁规则

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P0-3` |
| Phase | Phase 0 — 止血与执行基线 |
| Type | 门禁/规范 |
| Branch | `feat/pr-0252-p0-3-pr-gate-rules` |
| PR Title | `docs(frontend): PR-0252 P0-3 lock PR gate rules` |
| Estimated Effort | 0.5 person-day |
| Status | Ready for Review |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 6 (PR 门禁与合并策略)
- Module split blueprint: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md` Section 3.3 D1–D8, Section 8 S1–S7

## Goal

确认并文档化 PR 门禁规则，确保后续所有重构 PR 有统一的合规检查标准。

需文档化的内容：
1. 0255B D1–D8 依赖规则（落地为可执行检查命令）
2. 0255B S1–S7 风险控制策略
3. 03 报告 Section 6 的 PR 分类、必填内容、审核门禁

## Prerequisites

- 无前置任务（可与 P0-1、P0-2 并行）
- 本任务是 P0-4（样板 PR）的前置：样板 PR 必须按门禁规则提交

## Scope

In scope:

- 确认 D1–D8 依赖规则的 `rg` 检查命令可执行
- 确认 S1–S7 风险控制策略适用性
- 确认 PR 分类（Type A/B/C）和必填内容（Section 6.2）
- 确认合并 checklist（Section 6.3.3）
- TL 确认

Out of scope:

- CI 自动化集成（本轮仅人工检查）
- 新增门禁规则

## Key Rules to Confirm

### D1–D8 Dependency Rules (from 03 Section 6.4)

| Rule | Check Command / Method | Expected |
|------|----------------------|----------|
| D1 | 检查 Page/Explorer 的 import 列表 | 仅 import coordinator，不 import manager |
| D2 | `rg -n "import.*managers/" apps/lazynote_flutter/lib/features/notes/notes_page.dart apps/lazynote_flutter/lib/features/notes/note_content_area.dart apps/lazynote_flutter/lib/features/notes/note_explorer.dart` | 零匹配 |
| D3 | 检查 manager 文件的构造函数参数 | 仅通过构造函数注入，无自行构造其他 manager |
| D4 | 检查 manager 的 import 和构造函数 | invoker 通过构造函数注入 |
| D5 | `if (Test-Path "apps/lazynote_flutter/lib/features/notes/managers") { rg -n "import.*flutter" apps/lazynote_flutter/lib/features/notes/managers/ } else { Write-Output "[skip] managers/ not created yet" }` | 目录存在时仅 `foundation.dart`；目录不存在时输出 skip |
| D6 | `if (Test-Path "apps/lazynote_flutter/lib/features/notes/dialogs") { rg -n "import.*(coordinator|manager)" apps/lazynote_flutter/lib/features/notes/dialogs/ } else { Write-Output "[skip] dialogs/ not created yet" }` | 目录存在时零匹配；目录不存在时输出 skip |
| D7 | `rg -n "features/workspace" apps/lazynote_flutter/lib/features/notes/` | 分阶段目标（Phase 0–1 允许残留；Phase 2 P2-3 后零匹配；Phase 3 零匹配） |
| D8 | `rg -n "notes_style" apps/lazynote_flutter/lib/features/tags/` | 允许 tag_filter.dart（临时豁免） |

### S1–S7 Risk Control Strategies (from 0255B Section 8.2)

- S1: 每 PR 仅提取一个 manager
- S2: Coordinator 初始化时聚合 manager，各 manager 构造函数注入 invoker
- S3: 按 NotesController 原始方法逐一迁移到 manager
- S4: 保留 facade 过渡期（Phase 0–1）
- S5: `notifyListeners()` 时序保持与原 controller 一致
- S6: 对话框通过回调参数通信
- S7: SectionRegistry 替代硬编码 import

## Planned File Changes

- [edit] `docs/releases/v0.2.5/prs/PR-0252/P0-3-pr-gate-rules.md`
- [edit] `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`（任务看板状态同步）
- [edit] `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md`（阶段/任务状态同步）

## Acceptance Criteria

- [x] 0255B D1–D8 + S1–S7 规则文档化（Section 6 落地）
- [x] 全部 `rg` 检查命令可在当前环境执行（含 Phase 0 目录未创建时 skip 处理）
- [ ] TL 确认

## Verification Snapshot (2026-02-24)

| Rule | Baseline Result | Conclusion |
|------|-----------------|------------|
| D2 | `[ok] D2 zero matches` | 命令可执行，结果符合预期 |
| D5 | `[skip] managers/ not created yet` | 命令可执行，Phase 0 合理 skip |
| D6 | `[skip] dialogs/ not created yet` | 命令可执行，Phase 0 合理 skip |
| D7 | `notes/` 下 4 处 `features/workspace` 匹配（`notes_page.dart` ×2，`notes_controller.dart` ×2） | Phase 0–1 允许残留，符合分阶段口径 |
| D8 | `tag_filter.dart` 1 处匹配 `notes_style.dart` | 符合 D8 临时豁免口径 |

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Regression

- 纯文档/确认类任务，无代码变更，无需回归

## Rollback

纯文档，直接 revert 即可。
