# PR-0407: CI 跨 Feature 代码重复检测 + Check 输出补强

- Proposed title: `feat(ci): cross-feature duplication detection and check output enhancement`
- Status: Draft

## Goal

在代码 PR（PR-0408~0413）开始之前，增强 `architecture_check.dart`：新增跨 feature 代码重复检测（Check N），并补强现有 Check 1-3 输出为 WHAT/WHY/HOW 三层上下文格式。

前置条件：无（Phase 0，可立即执行）

## Execution Contract (Canonical Inputs)

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md` Q1-Q3 | 检测范围、算法、阈值、输出格式的完整设计依据 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0407 行） | PR 定位与 CI 要求 |
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

### 算法：行哈希序列匹配（DI-21 Q2）

1. **行预处理**：去除前后空白 → 跳过纯空行 → 跳过纯注释行（`//` 开头）
2. **哈希计算**：每行 normalize 后 → SHA256 前 8 字符
3. **匹配窗口**：扫描不同 feature 目录的文件对，找连续 ≥101 行哈希匹配
4. **复杂度**：O(n²) 文件对 × O(L) 行扫描；当前 `lib/features/` 规模（~35 文件）可接受

### 集成点：architecture_check.dart

新增 `_checkCrossFeatureDuplication()` 函数，位于 Check 3（结构层）之后：

```dart
class _DuplicationMatch {
  final String fileA, fileB;
  final int startA, endA, startB, endB;
  final int normalizedLines;
}

class _DuplicationResult {
  int failures = 0;
  int allowlistedCount = 0;
  List<_DuplicationMatch> matches = [];
  bool get hasFailure => failures > 0;
}
```

### Allowlist 机制

**文件**：`tools/ci/duplication_allowlist.yaml`

```yaml
- fileA: "lib/features/notes/dialogs/create_folder_dialog.dart"
  fileB: "lib/features/tasks/dialogs/folder_picker.dart"
  reason: "Tree/picker widget boilerplate (extraction tracked in PR-0412)"
```

匹配规则：fileA + fileB 任意顺序命中即豁免。

### 输出格式（DI-21 Q3 三层上下文）

```
VIOLATION: Cross-feature code duplication detected (Rule E extension).
  File A: lib/features/notes/dialogs/create_folder_dialog.dart:15–120
  File B: lib/features/tasks/dialogs/folder_picker.dart:8–113
WHAT: 102 matching lines (threshold: >100).
WHY: Rule E mandates cross-feature independence.
REFERENCE: docs/architecture/engineering-standards.md (Rule E)
HOW: Extract to lib/shared/ (UI) or lib/core/ (logic).
```

### 与现有 Check 的关系

| Check | 检查内容 | 本 PR 变更 |
|-------|---------|-----------|
| 1 (Rule E import) | 跨 feature import | + REFERENCE + HOW |
| 2 (File size) | 文件行数 | + HOW |
| 3 (Structural layer) | 层级违规 | + REFERENCE + HOW |
| **N (Duplication)** | **跨 feature 代码重复** | **新增** |
| 4 (Docs links) | 文档交叉引用 | 不变 |

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
- `[add]` tools/ci/duplication_allowlist.yaml (跨 feature 重复豁免清单)

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
cd apps/lazynote_flutter

# 验证 Check N 函数存在
grep -n "crossFeatureDuplication\|_checkCrossFeatureDuplication" ../../tools/ci/architecture_check.dart
# 预期：至少 1 匹配（函数定义）

# 验证 allowlist 文件存在
test -f ../../tools/ci/duplication_allowlist.yaml && echo "PASS" || echo "FAIL"

# 验证 REFERENCE 字段存在于 Check 输出模板
grep -c "REFERENCE:" ../../tools/ci/architecture_check.dart
# 预期：至少 3 匹配（Check 1 + Check 3 + Check N）

# 验证 HOW 字段存在于 Check 输出模板
grep -c "HOW:" ../../tools/ci/architecture_check.dart
# 预期：至少 4 匹配（Check 1 + Check 2 + Check 3 + Check N）

# 验证当前代码库无误报
dart run ../../tools/ci/architecture_check.dart
# 预期：exit 0
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
