# PR-RB-00: 文档前置修复

- Proposed title: `docs(v0.3): PR-RB-00 fix stale paths and status descriptions before v0.3 dev`
- Status: Draft

## Goal

修复 `CLAUDE.md` 和 `overview.md` 中因 v0.2.5 后期 PR（PR-0258/PR-0259）执行后遗留的过时路径和状态描述，确保 v0.3 周期内 AI agent 和开发者获得正确的项目上下文。

前置条件：无（序列首个 PR）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| Acceptance Report | `docs/reports/v0.2.5/frontend-review/09-acceptance-report.md` §7.4 | 列出 3 项前置文档修复 |
| Acceptance Report | 同上 §5.1 | 完整过时引用清单（5 项） |
| Rebaseline | `docs/releases/v0.3/v0.3-pr-spec-rebaseline-2026-03-01.md` §4 PR-RB-00 | 定义 scope：CLAUDE.md + overview.md |

### §7.4 原始清单 vs 当前状态

| §7.4 项目 | 当前状态 | PR-RB-00 动作 |
|-----------|---------|---------------|
| CLAUDE.md `features/reminders/` → `core/reminders/` | **已修复**（L104 已是 `core/reminders/`） | 无需操作 |
| CLAUDE.md `features/tags/` → `shared/` | **未修复**（L99 仍为 `lib/features/tags/`） | T1 |
| overview.md L77 移除 "currently `features/reminders/`" | **已修复**（L78/L121 已是 `core/reminders/`） | 无需操作 |
| overview.md L138 PR-0258 改为已完成时态 | **已修复**（L157 已是过去时态） | 无需操作 |

### §7.4 之外发现的过时项（同属 §5.1 清单或逻辑延伸）

| 发现 | 文件:行 | 问题 | PR-RB-00 动作 |
|------|---------|------|---------------|
| 版本状态过时 | `CLAUDE.md:13` | "Post-v0.2 baseline"，应为 Post-v0.2.5 | T2 |
| 双状态描述未过去时 | `CLAUDE.md:370` | "is targeted for elimination in PR-0258"，PR-0258 已完成 | T3 |
| Rulings 计数过时 | `CLAUDE.md:429` | "S1-S8"，S9 已存在 | T4 |
| Tags 路径过时 | `overview.md:105` | `lib/features/tags/`，已迁移至 `lib/shared/` | T5 |

## Scope

In scope:

- §7.4 未修复项 + §5.1 范围内的 CLAUDE.md / overview.md 过时描述

Out of scope:

- `data-model.md` S1 R1-R4 字段补充（§5.1 标注为 MEDIUM，属 PR-RB-02 前置）
- overview.md 中 v0.3 前瞻性描述（L104 "v0.3: tab/draft/save..." / L109 "v0.3: replaced by..."）——这些是正确的规划标注，不是过时描述

## Task Breakdown

| Task | 内容 | 文件:行 | 变更 | 依赖 |
|------|------|---------|------|------|
| T1 | `features/tags/` → `shared/`：TagFilter + ui_tokens | `CLAUDE.md:99` | 改 1 行 | — |
| T2 | "Post-v0.2 baseline" → "Post-v0.2.5 baseline" + 补充 v0.2.5 成果摘要 | `CLAUDE.md:13` | 改 1 行 | — |
| T3 | 双状态描述改为已完成时态 | `CLAUDE.md:370` | 改 1 行 | — |
| T4 | "S1-S8" → "S1-S9" | `CLAUDE.md:429` | 改 1 行 | — |
| T5 | `features/tags/` → `shared/` | `overview.md:105` | 改 1 行 | — |

所有 task 相互独立，可并行执行。

## Planned File Changes

- `[edit]` `CLAUDE.md`（4 处单行修改：L99, L13, L370, L429）
- `[edit]` `docs/architecture/overview.md`（1 处单行修改：L105）

## Verification

### CI gates

```bash
# 文档 PR 无代码变更，CI 验证为格式检查
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
```

### Structural verification

```bash
# CLAUDE.md 不再包含 features/tags/ 路径
rg "features/tags/" CLAUDE.md
# Expected: zero matches

# CLAUDE.md 不再包含 "Post-v0.2 baseline"（应为 v0.2.5）
rg "Post-v0\.2 baseline" CLAUDE.md
# Expected: zero matches

# CLAUDE.md 不再包含 "targeted for elimination"
rg "targeted for elimination" CLAUDE.md
# Expected: zero matches

# CLAUDE.md rulings 引用为 S1-S9
rg "S1-S8" CLAUDE.md
# Expected: zero matches

# overview.md 不再包含 features/tags/
rg "features/tags/" docs/architecture/overview.md
# Expected: zero matches
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 遗漏其他过时引用 | LOW | §5.1 清单已完整扫描；v0.3 后续 PR 会在各自 scope 内更新相关文档 |

## Acceptance Criteria

- [ ] `CLAUDE.md` Flutter path table 中 `features/tags/` 替换为 `shared/` 并列出正确文件
- [ ] `CLAUDE.md` 项目状态为 "Post-v0.2.5 baseline"
- [ ] `CLAUDE.md` 双状态描述为已完成时态（past tense）
- [ ] `CLAUDE.md` 语义裁决引用为 "S1-S9"
- [ ] `overview.md` Flutter Features 中 tags 路径为 `lib/shared/`
- [ ] Structural verification 全部 zero matches
