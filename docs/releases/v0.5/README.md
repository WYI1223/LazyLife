# v0.5 Release Plan

## Positioning

v0.5 的定位是「延期能力接续 + 模型统一评估 + 性能稳定化」。

它承接两类事项：

1. rulings/modules 中明确标记为 `v0.5+` 的能力；
2. v0.4 交付后的增强项与开放设计项闭合。

## Authority Inputs

本规划仅使用以下来源：

- `docs/architecture/rulings/`（S1-S9）
- `docs/architecture/modules/`
- `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md`
- `docs/reports/v0.3/design-discussions/DI-0` 至 `DI-5`
- `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md`
- `docs/releases/v0.4/README.md`

## Carryover Matrix (v0.5+ Items)

### Rulings / DI Carryover

| 来源 | 条目 | v0.5 规划 |
|---|---|---|
| S6 | 真实同步运行时（OAuth + pull/push + mappings） | 完成基础闭环并进入可回归状态 |
| S7 | RRULE + 提醒提前量配置 | 完成规则增强与启动恢复语义 |
| S1 R12 | `atom_embed/group`（P2）+ 统一 block tree 评估 | 完成评估结论并决定实施路线 |
| S1 R13 | 4 个开放设计项（上下文引用、AI 生成 Atom、长对话增长、扩展集成） | 全部闭合为实现或明确延期 |
| S1 R14 | reconciliation 算法、orphan 集合 UX、失败回退策略强化 | 完整化并加入回归集 |
| S5 | third-party runtime bridge 未完成部分 | 收口为稳定边界 |
| S6（进阶） | 多 provider、冲突交互流程 | 统一冲突处理 UX 与策略 |
| DI-4 | LRU(N) 渲染缓存与资源生命周期优化 | 引入并验证性能收益 |
| DI-5 | Undo/Redo 架构占位 | 形成可执行实现与验收标准 |

### Module Carryover

| Module Spec | v0.5 规划 |
|---|---|
| `core-editor/edit-buffer` | LRU/eviction + 跨模式 op 降级稳定性 |
| `core-editor/layout-persistence` | 视图模式/光标等 schema 升级策略 |
| `core-editor/editor-resolver` | 多模式切换稳定性与回退一致性 |
| `core-workspace/workspace-tree-service` | Spatial 大规模节点性能与一致性 |
| `core-reminders/reminder-scheduler` | 时区、跨日、节假日边界策略 |

## Scope

In scope:

- S6 真实同步运行时闭环（Orchestrator + OAuth + pull/push + mapping lifecycle）
- S7 提醒规则增强（RRULE + offset + 启动恢复）
- 多编辑范式完整闭环（source/block/inline 的协议与一致性）
- R12/R13/R14 的高级项收口
- 冲突处理与恢复策略增强（本地 + provider）
- 渲染与内存优化（LRU 渲染缓存、内容加载策略）
- Undo/Redo 体系化落地（含跨 pane 行为定义）

Out of scope:

- 多人实时协作（OT/CRDT 线上协同）
- 全平台商业化分发策略（超出 v0.5 目标）

## Candidate PR Breakdown

- `PR-0501-sync-orchestrator-and-mapping-runtime`
- `PR-0502-google-calendar-oauth-and-bidirectional-sync`
- `PR-0503-reminder-rrule-and-offset-policy`
- `PR-0504-canvas-p2-and-embed-graph`
- `PR-0505-block-tree-unification-decision-and-implementation`
- `PR-0506-conversation-advanced-workflows`
- `PR-0507-overlay-reconciliation-hardening`
- `PR-0508-sync-conflict-ux-and-multi-provider-policy`
- `PR-0509-editor-runtime-lru-and-resource-lifecycle`
- `PR-0510-undo-redo-foundation`
- `PR-0511-layout-schema-v2-and-recovery-hardening`

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- 针对大文档与多 pane 的性能回归基线（必须可重放）

## Acceptance Criteria (Release-Level)

v0.5 完成标准：

1. R12/R13/R14 在 `v0.5+` 标注的核心开放项已闭合（实现或明确延期决策）。
2. S6 真实同步运行时可完成 OAuth、拉取、推送、映射更新闭环。
3. S7 提醒规则（RRULE + offset）在重启恢复后仍可正确调度。
4. 多内容、多 pane、长会话下的编辑一致性与恢复策略可重复验证。
5. 冲突处理与回退行为在本地编辑与 provider 同步场景下语义一致。
6. 渲染与内存策略升级后，不引入可感知交互退化。
7. Undo/Redo 行为在跨 pane 与跨模式切换中满足定义。

## Detailed Spec

- `docs/releases/v0.5/v0.5-pr-spec-2026-03-01.md`
