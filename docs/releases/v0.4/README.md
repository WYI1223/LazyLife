# v0.4 Release Plan

## Positioning

v0.4 的目标是承接 v0.3 rebaseline 明确延期或未纳入的能力，完成「多内容形态 + 同步运行时 + 组织视图扩展」三条主线。

核心主题：

- S1 延期能力落地（R9-R14 的 v0.4 子集）
- S6 从 schema/SPI 走到真实 provider runtime
- core-editor / core-workspace / core-reminders 的后续模块能力补齐

## Authority Inputs

本规划仅使用以下来源：

- `docs/architecture/rulings/`（S1-S9）
- `docs/architecture/modules/`
- `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md`
- `docs/reports/v0.3/design-discussions/DI-0` 至 `DI-5`
- `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md`

## Carryover Matrix (Not Planned in v0.3)

### Rulings Carryover

| 来源 | 条目 | v0.3 状态 | v0.4 规划 | v0.5 规划 |
|---|---|---|---|---|
| S1 | R9 `icon` | 延期 | 落地 | — |
| S1 | R10 `cover_image` | 延期 | 落地 | — |
| S1 | R11 `comment` 独立实体 | 延期 | 落地 MVP | 协作/高级检索增强 |
| S1 | R12 Canvas 引擎 P0/P1 + Spatial Workspace | 未纳入 v0.3 rebaseline | 落地 | P2 元素与统一模型评估 |
| S1 | R13 `conversation` content_type | 延期 | 落地 MVP | 4 个开放设计项收口 |
| S1 | R14 `atom_overlays` sidecar | 延期 | 落地基础协议 | reconciliation 强化 |
| S2 | ViewMode per-pane 扩展 | v0.3 未纳入 | source/block/preview 基础落地 | 持久化与跨模式优化 |
| S3 | Phase B（Tag 结果替换 Explorer 区）+ Spatial 模式 | v0.3 仅 Phase A | 落地 | 体验与性能增强 |
| S5 | third-party runtime bridge | declaration-only | Conditional（需求驱动） | 若未做则转 v0.5 Must |
| S6 | Google Calendar 真实 runtime（OAuth + pull/push） | 已确认延期 | 落地 | 多 provider 与冲突体验增强 |
| S7 | RRULE + 提前提醒配置 | v0.3 未纳入 | 落地 | 高级策略增强 |

### Module Carryover

| Module Spec | v0.3 状态 | v0.4 规划 | v0.5 规划 |
|---|---|---|---|
| `core-editor/editor-resolver` | 仅 `resolve(contentType)` | 增加 `viewMode` 维度 | 模式切换持久化与兼容迁移 |
| `core-editor/edit-buffer` | `SnapshotReplace` 主路径 | 引入 `TextDelta`/`StructuredOp` 通道 | LRU 渲染缓存与内容驱逐策略 |
| `core-workspace/workspace-tree-service` | 仅 tree/list 基线 | Spatial Workspace 读写路径 | 大规模结构性能与一致性强化 |
| `core-reminders/reminder-scheduler` | 基础提醒 | RRULE + 提前 N 分钟配置 | 时区/假期策略增强 |

## Scope

In scope:

- `icon/cover_image/comment` 的 Atom 元数据补齐
- Markdown sidecar overlay 与多编辑模式基础（source/block/preview）
- Canvas（P0/P1）与 Spatial Workspace 首版
- Conversation 内容类型 MVP
- Google Calendar 真实同步运行时
- Tag Phase B 与 Explorer 视图模式切换
- Reminder 规则增强（RRULE + offset）

Conditional:

- S5 third-party runtime bridge（仅在首个真实 third-party 插件需求成立时纳入）

Out of scope:

- Markdown + Canvas 统一 block tree 的最终定案与迁移
- Conversation 高级能力（跨 Atom 上下文、长对话归档、AI 建议生成 Atom）
- 多 provider 深度冲突工作流

## Candidate PR Breakdown

- `PR-0401-sync-orchestrator-and-mapping-runtime`
- `PR-0402-google-calendar-oauth-and-bidirectional-sync`
- `PR-0403-atom-icon-and-cover-image`
- `PR-0404-atom-comments-entity-and-panel`
- `PR-0405-markdown-overlay-and-viewmode-foundation`
- `PR-0406-canvas-editor-p0-p1`
- `PR-0407-spatial-workspace-view`
- `PR-0408-conversation-content-type-mvp`
- `PR-0409-tag-query-phase-b-and-explorer-mode-switch`
- `PR-0410-reminder-rrule-and-offset-policy`
- `PR-0411-third-party-runtime-bridge` (Conditional)

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- architecture checks（Rule E / 文件大小 / 结构层）

## Acceptance Criteria (Release-Level)

v0.4 完成标准：

1. 延期到 v0.4 的 S1 能力（R9-R14 中 v0.4 子集）均可运行并有回归测试。
2. Google Calendar 真实 runtime 可完成 OAuth、拉取、推送、映射更新闭环。
3. 编辑器支持至少两种以上内容形态（markdown + canvas 或 conversation）并可稳定切换。
4. Tag 与 Explorer 的正交性在 Tree/List/Spatial 三模式下保持一致。
5. Reminder 能处理 RRULE 与可配置提前提醒。

## Detailed Spec

- `docs/releases/v0.4/v0.4-pr-spec-2026-03-01.md`
