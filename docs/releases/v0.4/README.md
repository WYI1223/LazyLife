# v0.4 Release Plan

## Positioning

v0.4 以四条并行工作流推进：**ADR 治理基础设施**、**Workspace 单根树执行**、**Feature 扩展（icon/cover/comments/overlays）** 与 **Issue 修复**。

核心主题：

- ADR 治理框架从零建立（DR-0400~0406），为后续所有架构裁决提供规范载体
- Workspace 单根树落地（PR-0407~0413）：基于 DI-15~DI-18 裁决，完成 schema migration、scoped query、guard+FFI、Flutter thin client 全链路
- S1 Feature 扩展（PR-0414~0416）：icon/cover_image/atom_comments/overlays+viewmode 基础落地
- Issue 修复（PR-0421~0423）：编辑器 pane 四项 UI 修复、FFI 测试 DB 隔离、跨 feature 刷新

Canvas、Conversation、Spatial Workspace 整体延期至 v0.5。

## Authority Inputs

本规划仅使用以下来源：

- `docs/architecture/rulings-legacy/`（legacy snapshot: S1-S9 + E1）
- `docs/architecture/modules/`
- `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md`
- `docs/reports/v0.3/design-discussions/DI-0` 至 `DI-5`
- `docs/reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md`
- `docs/reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md`
- `docs/reports/v0.3/design-discussions/DI-15-rust-data-model-single-root.md`
- `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md`
- `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md`
- `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md`
- `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md`
- `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`
- `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md`
- `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md`

## Carryover Matrix (Not Planned in v0.3)

### Rulings Carryover

| 来源 | 条目 | v0.3 状态 | v0.4 规划 | v0.5 规划 |
|---|---|---|---|---|
| S1 | R9 `icon` | 延期 | 落地（PR-0414） | — |
| S1 | R10 `cover_image` | 延期 | 落地（PR-0414） | — |
| S1 | R11 `comment` 独立实体 | 延期 | 落地 MVP（PR-0415） | 协作/高级检索增强 |
| S1 | R12 Canvas 引擎 P0/P1 + Spatial Workspace | 未纳入 v0.3 rebaseline | 延期至 v0.5 | 落地 + P2 元素与统一模型评估 |
| S1 | R13 `conversation` content_type | 延期 | 延期至 v0.5 | 落地 MVP + 4 个开放设计项收口 |
| S1 | R14 `atom_overlays` sidecar | 延期 | 落地基础协议（PR-0416） | reconciliation 强化 |
| S2 | ViewMode per-pane 扩展 | v0.3 未纳入 | source/block/preview 基础落地（PR-0416） | 持久化与跨模式优化 |
| S3 | Phase B（Tag 结果替换 Explorer 区）+ Spatial 模式 | v0.3 仅 Phase A | 延期至 v0.5 | 体验与性能增强 |
| S5 | third-party runtime bridge | declaration-only | 延期至 v0.5 | 若未做则转 Must |
| S6 | Google Calendar 真实 runtime（OAuth + pull/push） | 已确认延期 | 延期至 v0.5 | 多 provider 与冲突体验增强 |
| S7 | RRULE + 提前提醒配置 | v0.3 未纳入 | 延期至 v0.5 | 高级策略增强 |

### Module Carryover

| Module Spec | v0.3 状态 | v0.4 规划 | v0.5 规划 |
|---|---|---|---|
| `core-editor/editor-resolver` | 仅 `resolve(contentType)` | 增加 `viewMode` 维度（PR-0416） | 模式切换持久化与兼容迁移 |
| `core-editor/edit-buffer` | `SnapshotReplace` 主路径 | 延期至 v0.5 | 引入 `TextDelta`/`StructuredOp` 通道 |
| `core-workspace/workspace-tree-service` | 仅 tree/list 基线 | 单根树 B+ 改造（PR-0412） | 大规模结构性能与一致性强化 |
| `core-reminders/reminder-scheduler` | 基础提醒 | 延期至 v0.5 | 时区/假期策略增强 |

## Scope

In scope:

- ADR 治理基础设施：legacy rulings 归档、ADR 目录结构、首批 retrospective ADR、metadata contract、closure audit、template playbook
- CI 跨 feature 代码重复检测（Check N）+ 现有 Check 输出补强（WHAT/WHY/HOW）
- Workspace 单根树 schema migration（0012）+ ScopedQueryRepository + TreeService/CreationService 增强 + Guard+FFI 全量 + Flutter thin client 适配
- `icon`/`cover_image` Atom 元数据字段（S1 R9/R10）
- `comment` 独立注释流实体 MVP（S1 R11）
- `atom_overlays` sidecar + ViewMode source/block/preview 基础（S1 R14 + S2）
- Editor pane 修复（#47~#50）、FFI 测试 DB 隔离（#46）、跨 feature 数据刷新（#45）

Deferred to v0.5:

- Canvas（P0/P1/P2）与 Spatial Workspace
- Conversation content_type MVP
- Tag Phase B 与 Explorer Spatial 模式
- S5 third-party runtime bridge
- S6 Google Calendar 真实 runtime（OAuth + pull/push）
- S7 RRULE + 提醒提前量配置
- Markdown + Canvas 统一 block tree 最终定案与迁移
- `core-editor/edit-buffer` TextDelta/StructuredOp 通道

## PR Breakdown

### Governance（PR-0400~0406）

| PR | 标题 | 状态 |
|---|---|---|
| PR-0400 | Legacy Rulings 归档 | Merged |
| PR-0401 | Source Corpus + DN Extraction | Merged |
| PR-0402 | ADR Infrastructure + Metadata Contract | Merged |
| PR-0403 | Per-ADR Serial Execution（首批 retrospective ADR） | Merged |
| PR-0404 | Theme Delta Contract + Consistency Audit | Ready for Review |
| PR-0405 | Closure Audit + Governance Activation | Draft |
| PR-0406 | Template Playbook + Lifecycle Backfill | Draft |

### Workspace Execution（PR-0407~0413）

| PR | 标题 | 来源 |
|---|---|---|
| PR-0407 | CI 跨 Feature 代码重复检测 + Check 输出补强 | DI-21 |
| PR-0408 | Schema Migration 0012（单根树 + Workspace 元数据） | DI-15 |
| PR-0409 | ScopedAtomQuery + ScopedQueryRepository | DI-16 Q1 |
| PR-0410 | TreeService 增强 + CreationService 路由 | DI-16 Q2-Q4 |
| PR-0411 | Guard+FFI 全量（AccessGuard + 新 FFI + FRB 重生成） | DI-16 Q5-Q6 |
| PR-0412 | Flutter Core 适配（WorkspaceTreeService B+） | DI-17 Q1-Q4 |
| PR-0413 | Flutter Features 适配 + 旧 FFI 移除（Contract 阶段） | DI-17 Q3/Q5-Q6 |

### Feature Extensions（PR-0414~0416）

| PR | 标题 | 来源 |
|---|---|---|
| PR-0414 | Atom Icon + Cover Image 元数据字段 | S1 R9/R10 |
| PR-0415 | Atom Comments — 独立注释流实体 | S1 R11 |
| PR-0416 | Atom Overlays Sidecar + ViewMode Extension | S1 R14 + S2 |

### Issue Fixes（PR-0421~0423）

| PR | 标题 | 关联 |
|---|---|---|
| PR-0421 | Editor Pane 修复（Overflow/Cursor/Scroll/Tab Switch） | #47~#50 |
| PR-0422 | FFI 测试 DB 隔离（每次运行独立 DB） | #46 |
| PR-0423 | Cross-Feature Data Refresh on Section Switch | #45 |

### Pending（PR-0424）

| PR | 标题 | 状态 |
|---|---|---|
| PR-0424 | UI/UX 补强 | 待定（kickoff 后按需纳入） |

### Deferred to v0.5（PR-0417~0419）

| PR | 标题 | 延期原因 |
|---|---|---|
| PR-0417 | Canvas 编辑器 P0/P1 | 范围过大，整体延期 |
| PR-0418 | Conversation Content Type MVP | 范围过大，整体延期 |
| PR-0419 | Spatial Workspace 视图 | 范围过大，整体延期 |

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `dart run ../../tools/ci/architecture_check.dart`（Rule E / 文件大小 / 结构层 / 跨 feature 重复检测）

## Acceptance Criteria (Release-Level)

v0.4 完成标准：

1. ADR 治理基础设施就位：legacy rulings 已归档，`docs/architecture/adrs/` 目录包含首批 retrospective ADR，metadata contract 与 backlink 规则生效，template playbook 可直接用于新 ADR 起草。
2. Workspace 单根树落地：Migration 0012 通过 CI 全绿，ScopedQueryRepository 替代直查路径，Flutter thin client 迁移完成，旧 15 个 FFI 函数已移除，`architecture_check.dart` 无 Rule E 或重复检测告警。
3. S1 Feature 扩展可运行：icon/cover_image 在 Explorer 列表卡片中可见；comment panel 支持追加与软删除；overlay sidecar 与 ViewMode source/block/preview 切换可稳定工作。
4. 已知 Issue 修复：#45~#50、#46 全部回归测试绿灯。
5. Canvas、Conversation、Spatial Workspace 确认延期至 v0.5，不阻塞本次发布。

## Detailed Spec

每个 PR 的详细规格见 `docs/releases/v0.4/prs/` 目录：

- 治理 PR：`PR-0400-legacy-rulings-archive.md` 至 `PR-0406-template-playbook-and-lifecycle-backfill.md`
- Workspace 执行：`PR-0407-ci-duplication-detection.md` 至 `PR-0413-flutter-features.md`
- Feature 扩展：`PR-0414-icon-cover-image.md`、`PR-0415-atom-comments.md`、`PR-0416-overlays-viewmode.md`
- Issue 修复：`PR-0421-editor-fixes.md`、`PR-0422-ffi-test-isolation.md`、`PR-0423-cross-feature-refresh.md`
