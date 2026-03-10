# PR-0400: Legacy Rulings 归档

- Proposed title: `docs(governance): archive legacy rulings and bootstrap governance execution workspace`
- Execution status: Merged
- Spec review status: Review-clean (`docs/releases/v0.4/pr-spec-review-resolution.md`)

| 项目 | 值 |
|------|-----|
| **执行状态** | MERGED |
| **规格评审状态** | Review-clean |
| **主题覆盖** | `T0` |
| **依赖** | 无 |
| **关联** | [governance-rulings-migration-and-rebuild.md](../../../reports/v0.4/governance-execution/PR-0400/governance-rulings-migration-and-rebuild.md) |

---

## Purpose

把 `docs/architecture/rulings/` 中的全部现有文件整体归档为 `legacy normative snapshot`，
清空 canonical `rulings/` 作为 per-ADR workflow 重建的空集起点，消除后续所有治理阶段的
规范锚点歧义。

---

## Scope

### In Scope

1. 创建 `docs/architecture/rulings-legacy/` 目录
2. 移动 `docs/architecture/rulings/` 全部现有文件至 `rulings-legacy/`
3. 在 `docs/architecture/rulings/` 创建新 README：
   - 说明初始为空集
   - 说明只承载 per-ADR workflow 重建出的 current-effective 规则
   - 说明 legacy rulings 已归档至 `rulings-legacy/`
4. 所有对具体 ruling 文件的引用统一改指 `rulings-legacy/`（含代码样式路径与非 Markdown 文本路径）
5. 创建 `docs/reports/v0.4/governance-execution/` 目录结构：
   - `v0.4/README.md`
   - `governance-execution/README.md`（执行总索引）
   - `PR-0400/` ~ `PR-0406/` 子目录骨架
6. 验证 Gate A 通过 + CI 通过（`architecture_check.dart` 无悬挂链接）

### Out of Scope

1. 创建任何新 ruling
2. 进入 source corpus 盘点或 DN extraction
3. 判断哪些 ruling 将被重建或重建优先级
4. 修改治理 workflow 文档

---

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| 治理执行裁决 | `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md` | 定义 T0、Gate A、legacy/current-effective 边界 |
| kickoff 结论 | `docs/releases/v0.4/v0.4-kickoff.md` | 明确 PR-0400 为 v0.4 第一条治理工作流、状态 PREP READY |
| 当前规范源 | `docs/architecture/rulings/` | 现有 S1-S9/E1 文件集合，需整体迁移为 legacy snapshot |
| 文档入口 | `docs/index.md`、`CLAUDE.md` | 需要在索引层声明 rulings 与 rulings-legacy 的新职责分工 |

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | Docs | 将现有 `rulings/` 全量迁移到 `rulings-legacy/`，保留文件名不变 | `docs/architecture/rulings/` -> `docs/architecture/rulings-legacy/` | TBD | — |
| T2 | Docs | 创建新的 canonical `rulings/README.md`，写清 current-effective 空集起点与 legacy 边界 | `docs/architecture/rulings/README.md` | TBD | T1 |
| T3 | Docs | 修复仓库内所有对具体 ruling 文件的引用，使其指向 `rulings-legacy/` | `docs/`, `CLAUDE.md` 等 | TBD | T1 |
| T4 | Docs | 初始化 `docs/reports/v0.4/README.md` 与 `governance-execution/` 总索引、PR-0400~0406 目录骨架 | `docs/reports/v0.4/` | TBD | T1 |
| T5 | Docs | 写入 PR-0400 执行记录，记录归档动作、链接迁移与 Gate A 结论 | `docs/reports/v0.4/governance-execution/PR-0400/` | TBD | T1-T4 |
| T6 | Verify | 运行结构检查，确认无悬挂 ruling 链接 | `tools/ci/architecture_check.dart` | TBD | T2-T5 |

## Planned File Changes

- `[move]` `docs/architecture/rulings/README.md` -> `docs/architecture/rulings-legacy/README.md`
- `[move]` `docs/architecture/rulings/E1-release-and-versioning.md` -> `docs/architecture/rulings-legacy/E1-release-and-versioning.md`
- `[move]` `docs/architecture/rulings/S1-atom-projection.md` -> `docs/architecture/rulings-legacy/S1-atom-projection.md`
- `[move]` `docs/architecture/rulings/S2-tab-draft-save-ownership.md` -> `docs/architecture/rulings-legacy/S2-tab-draft-save-ownership.md`
- `[move]` `docs/architecture/rulings/S3-tag-workspace-orthogonality.md` -> `docs/architecture/rulings-legacy/S3-tag-workspace-orthogonality.md`
- `[move]` `docs/architecture/rulings/S4-creation-path-unification.md` -> `docs/architecture/rulings-legacy/S4-creation-path-unification.md`
- `[move]` `docs/architecture/rulings/S5-extension-kernel-boundary.md` -> `docs/architecture/rulings-legacy/S5-extension-kernel-boundary.md`
- `[move]` `docs/architecture/rulings/S6-provider-spi-interaction.md` -> `docs/architecture/rulings-legacy/S6-provider-spi-interaction.md`
- `[move]` `docs/architecture/rulings/S7-reminders-infrastructure.md` -> `docs/architecture/rulings-legacy/S7-reminders-infrastructure.md`
- `[move]` `docs/architecture/rulings/S8-noteitem-unification.md` -> `docs/architecture/rulings-legacy/S8-noteitem-unification.md`
- `[move]` `docs/architecture/rulings/S9-cross-feature-infrastructure-placement.md` -> `docs/architecture/rulings-legacy/S9-cross-feature-infrastructure-placement.md`
- `[add]` `docs/architecture/rulings/README.md`
- `[add]` `docs/reports/v0.4/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0400/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0401/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0402/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0403/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0404/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0405/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0406/README.md`
- `[edit]` `docs/index.md`
- `[edit]` `CLAUDE.md`
- `[edit]` concrete ruling references under `docs/architecture/`, `docs/releases/`, `docs/reports/`

## Verification

### CI gates

```bash
cd apps/lazynote_flutter/
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# rulings/ 目录只保留新的 README
find docs/architecture/rulings -maxdepth 1 -type f
# 预期：仅 README.md

# legacy 目录包含原始 11 个文件
find docs/architecture/rulings-legacy -maxdepth 1 -type f | wc -l
# 预期：11

# 仓库内不再引用已迁移的具体 ruling 旧路径
# 排除本 PR 自身的 move inventory，避免把迁移清单误判为残留引用
rg -n "docs/architecture/rulings/(S[1-9]|E1)-.*\\.md|[./]rulings/(S[1-9]|E1)-.*\\.md" docs CLAUDE.md -g '!docs/releases/v0.4/prs/PR-0400-legacy-rulings-archive.md'
# 预期：0 匹配
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 历史文档中残留具体 ruling 旧路径，导致 link-check 失败 | MEDIUM | 批量扫描 `docs/` 与顶层文档，迁移后立即跑 `architecture_check.dart` |
| `docs/index.md` / `CLAUDE.md` 仍把 `rulings/README.md` 描述成 S1-S9 registry | MEDIUM | 同步补充 `rulings-legacy/` 与新的 canonical `rulings/` 职责说明 |
| 后续 PR 仍继续引用 legacy rulings 作为 current-effective | LOW | 在新 `rulings/README.md` 中明确 current-effective 仅来自后续 per-ADR rebuild |

## Exit Gate

- [x] `docs/architecture/rulings-legacy/` 包含全部原始 ruling 文件
- [x] `docs/architecture/rulings/` 仅含新建 README
- [x] 全部对具体 ruling 文件的引用已更新为指向 `rulings-legacy/`（不含本 PR 的 move inventory）
- [x] `docs/reports/v0.4/governance-execution/` 目录结构已创建（含 README 与 PR-0400~06 子目录）
- [x] `architecture_check.dart` 无悬挂链接
- [x] [`governance-rulings-migration-and-rebuild.md`](../../../reports/v0.4/governance-execution/PR-0400/governance-rulings-migration-and-rebuild.md) Gate A（Archive Ready）条件满足：
  - 归档路径和命名规则已确定
  - legacy / rebuilt 的职责边界已写清
  - 历史 replay 不再消费 current rulings

---

## Reference

- [governance-rulings-migration-and-rebuild.md](../../../reports/v0.4/governance-execution/PR-0400/governance-rulings-migration-and-rebuild.md)（迁移原则与 Gate A 记录）
- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)（T0 定义与 PR-0400 gate）
