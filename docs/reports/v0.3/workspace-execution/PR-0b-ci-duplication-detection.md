# PR-0b: CI 跨 Feature 代码重复检测 + Check 输出补强

- Proposed title: `feat(ci): cross-feature duplication detection and check output enhancement`
- Status: Draft

## Goal

在代码 PR（PR-1~6）开始之前，增强 `architecture_check.dart`：新增跨 feature 代码重复检测（Check N），并补强现有 Check 1-3 输出为 WHAT/WHY/HOW 三层上下文格式。

前置条件：无（Phase 0，可立即执行）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md` Q1-Q3 | 检测范围、算法、阈值、输出格式的完整设计依据 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0b 行） | PR 定位与 CI 要求 |
| 规范源 | `docs/architecture/engineering-standards.md` Rule E | 本 Check 是 Rule E 的执行延伸 |
| 现有实现 | `tools/ci/architecture_check.dart` | 需修改的目标文件 |

## Scope

In scope:
- 新增 Check N：跨 feature 代码重复检测（行哈希序列匹配，>100 行阈值）
- 行预处理：去除前后空白 + 去除纯空行 + 去除纯注释行
- 扫描范围：`lib/features/*/` 全部 `.dart` 文件（跨 2 个不同 feature 目录的文件对）
- 排除规则：`*.g.dart`、`*.freezed.dart` 等生成代码；`test/` 目录
- allowlist 机制：提供豁免路径（具体位置/文件名/语法为本 PR 实现自由度）
- 补强 Check 1（Rule E 跨 feature import）：+ REFERENCE + HOW
- 补强 Check 2（文件大小）：+ HOW
- 补强 Check 3（结构层违规）：+ REFERENCE + HOW
- 新 Check 输出格式遵循 DI-21 Q3 模板

Out of scope:
- 同 feature 内部重复检测（DI-21 Out of Scope）
- 通用代码质量工具集成（linter、coverage）
- Check 4 补强（DI-21 裁决已足够）

## Design

TBD — kickoff 阶段细化。

核心算法参考 DI-21 Q2：每行去空白后哈希，找跨文件连续 N 行（N > 100）哈希匹配。零外部依赖，在 `architecture_check.dart` 内实现。

## Task Breakdown

| Task | Lane | 内容 | 文件 | 估算 | 依赖 |
|------|------|------|------|------|------|
| T1 | CI | 行哈希序列匹配算法实现 | `tools/ci/architecture_check.dart` | TBD | — |
| T2 | CI | 扫描范围 + 排除规则 + allowlist | `tools/ci/architecture_check.dart` | TBD | T1 |
| T3 | CI | Check N 输出格式（WHAT/WHY/HOW） | `tools/ci/architecture_check.dart` | TBD | T1 |
| T4 | CI | Check 1-3 输出补强 | `tools/ci/architecture_check.dart` | TBD | — |
| T5 | CI | 自测验证 | — | TBD | T1-T4 |

## Planned File Changes

- `[edit]` tools/ci/architecture_check.dart (新增 Check N + 补强 Check 1-3 输出)
- `[add]` allowlist 文件（位置与文件名由实现决定）

## Verification

### CI gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
dart analyze
dart run ../../tools/ci/architecture_check.dart
```

### Structural verification

```bash
# 验证新 Check 可检测到故意引入的重复（手动测试）
# 验证 Check 1-3 输出包含 REFERENCE 和 HOW 字段
dart run tools/ci/architecture_check.dart 2>&1 | grep -c "REFERENCE"
# 预期：至少出现在 Check 1/3 的输出模板中
```

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 行哈希误报（格式差异导致漏检） | LOW | 预处理去空白 + 去空行 + 去注释行 |
| 大量文件扫描性能问题 | LOW | 当前 `lib/features/` 文件数有限，行哈希 O(n) 复杂度 |

## Acceptance Criteria

- [ ] `architecture_check.dart` 包含跨 feature 重复检测 Check（Check N）
- [ ] Check N 阈值为 >100 行（101+）
- [ ] 检测排除 `*.g.dart`、`*.freezed.dart`、`test/` 目录
- [ ] allowlist 机制存在且可豁免已知合理重复
- [ ] Check 1 输出包含 REFERENCE（Rule E 引用）
- [ ] Check 1 输出包含 HOW（Move to `lib/shared/` or `lib/core/`）
- [ ] Check 2 输出包含 HOW（Split using coordinator → manager pattern）
- [ ] Check 3 输出包含 REFERENCE（Rule A/B 引用）
- [ ] Check 3 输出包含 HOW（Inject invoker）
- [ ] `dart analyze` 零 warning
- [ ] `architecture_check.dart` 在当前代码库运行全绿（无误报）
- [ ] PR spec Status updated to Merged
