# PR-0407: CI 跨 Feature 代码重复检测 + Check 输出补强

- Proposed title: `feat(ci): cross-feature duplication detection and check output enhancement`
- Status: Draft

## Goal

在代码 PR（PR-0408~0413）开始之前，增强 `architecture_check.dart`：

1. 新增跨 feature 代码重复检测（Check N）；
2. 将现有 Check 1-3 的失败输出补强为统一的 WHAT / WHY / REFERENCE / HOW 上下文格式；
3. 为 `CPR-002` 提供足够的落地证据，但不因代码落地本身直接宣告最终 promotion。

前置条件：无（Phase 0，可立即执行）。

## Current Baseline

截至 2026-03-13，当前仓库基线状态如下：

- `dart run tools/ci/architecture_check.dart` 在现状代码库中通过；
- 当前 `architecture_check.dart` 已包含 Check 1-5，但**尚无**跨 feature 重复检测 Check；
- `tools/ci/duplication_allowlist.yaml` 尚不存在；
- `docs/architecture/engineering-standards.md` 的 Rule E 仍停留在“禁止跨 feature 直接依赖”，尚未同步 DI-21 的“禁止跨 feature 实质性重复”执行延伸；
- `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md` 中 `governance-rule-surface`、`detector-and-allowlist`、`output-contract` 三个 slice 仍为 `pending`。

本 PR 的任务不是修复当前 CI 失败，而是在**当前全绿基线之上**补齐新的检测能力与输出合同，并确保首轮落地后仓库仍保持全绿。

## Execution Contract (Canonical Inputs)

Shared promotion register:

- `docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md`
- This PR must leave evidence sufficient for `CPR-002`, but may not claim final promotion by code landing alone.

| 类型 | 引用 | 与本 PR 的关系 |
|------|------|---------------|
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md` Q1-Q3 | 检测范围、算法、阈值、输出格式的完整设计依据 |
| DI 裁决 | `docs/reports/v0.3/design-discussions/DI-18-execution-plan.md` Q1（PR-0407 行） | PR 定位与先后顺序要求 |
| 规范源 | `docs/architecture/engineering-standards.md` Rule E | 本 Check 是 Rule E 的执行延伸 |
| 现有实现 | `tools/ci/architecture_check.dart` | 需修改的主目标文件 |
| 交接工作流 | `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md` | 必须更新 coverage ledger，完成 DI-21 handoff |

## Current Handoff From PR-0403 / DOC-029

`DOC-029 / DI-21` 已完成 replay，并明确记录了 no-publication handoff：当前仓库仍缺少已落地的 duplication detector、allowlist surface 与 CI output contract。

本 PR 必须直接消费下列三个 carry-forward bundle：

| Bundle | Carry-Forward ID | Source DN IDs | Required Landing Surface |
|------|------|------|------|
| Rule E extension and general-governance path | `OI-051` | `DN-604-DN-606` | `docs/architecture/engineering-standards.md` + 本 PR 的落地证据 |
| Detector, threshold, scan boundary, and allowlist contract | `OI-052` | `DN-607-DN-610` | `tools/ci/architecture_check.dart` + landed allowlist surface |
| Three-layer output contract and check 1-3 reinforcement | `OI-053` | `DN-611-DN-615` | `tools/ci/architecture_check.dart` + 本 PR 的落地证据 |

Mandatory downstream references:

- `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md`
- `docs/reports/v0.4/governance-execution/PR-0403/open-items.md`
- `docs/reports/v0.4/governance-execution/PR-0403/iterations/DOC-029-di-21-ci-duplication-detection/05-dn-classification-to-decision-line.md`

如果本 PR 落地代码但未更新 workflow ledger，则 `DOC-029` handoff 仍视为未完成。

## Scope

### In Scope

- 新增 Check N：跨 feature 代码重复检测；
- 检测阈值：连续 `>=101` 条 normalized code lines；
- 扫描范围：`apps/lazynote_flutter/lib/features/**/*.dart`，且仅比较**不同顶层 feature 目录**之间的文件对；
- 排除生成代码与测试代码；
- 引入 duplication allowlist 机制；
- 补强 Check 1（Rule E import）失败输出：增加 `REFERENCE` 与 `HOW`；
- 补强 Check 2（文件大小）失败输出：增加 `HOW`；
- 补强 Check 3（结构层违规）失败输出：增加 `REFERENCE` 与 `HOW`；
- 更新 Rule E 当前文档表述，使其与已落地 CI 行为一致；
- 更新 `ci-duplication-policy-promotion-workflow.md` coverage ledger。

### Out of Scope

- 同 feature 内部重复检测；
- 通用代码质量工具集成（linter、coverage、dead code tooling 等）；
- AST 级、token 级高级相似度检测；
- Check 4（Docs links）输出补强；
- Check 5（NoteItem deprecation）语义变更；
- 通过提高阈值或扩大排除面来“压掉”首轮真实命中。

## Implementation Strategy

### 选定方案

本 PR 采用“执行合同 + 实施切片 + 验证矩阵”方式推进，而不是只写算法描述。

原因：

- 仅补算法细节不足以约束 workflow ledger 与 current-doc sync 的落地顺序；
- 直接把 TDD 级执行步骤塞进 PR spec 又会过重，并与后续实现计划重复；
- 当前最需要的是一份能直接指导落地、又不会与 implementation plan 冲突的中等粒度合同。

### 核心原则

1. **保持脚本零新增外部运行时依赖**：`tools/ci/architecture_check.dart` 必须继续可通过 `dart run tools/ci/architecture_check.dart` 从 repo root 直接运行。
2. **先落地行为，再同步当前文档**：`engineering-standards.md` 只能在 detector 和 output contract 已实际存在后同步。
3. **允许精确豁免，不允许模糊放行**：如果首轮命中合理重复，应通过窄 allowlist 处理，而不是放宽阈值或扩大 ignore 范围。
4. **输出必须可操作**：失败信息必须让后续 PR 执行者知道“哪里错、为什么错、怎么修”。

## Design

### 1. Check 插入位置

Check N 放在 Check 3（Structural layer）之后、Check 4（Docs cross-reference）之前。

原因：

- 它与 Check 1-3 同属架构/分层治理面；
- 在 docs link check 之前失败，更符合“代码结构问题优先于文档引用问题”的调试顺序；
- 不改动 Check 5 的位置与语义，避免无关 diff。

### 2. 扫描边界与文件发现规则

候选文件必须同时满足：

- 位于 `apps/lazynote_flutter/lib/features/` 下；
- 扩展名为 `.dart`；
- 不匹配 `*.g.dart`、`*.freezed.dart`；
- 路径中不包含 `/test/`；
- 顶层 feature 目录名可被稳定解析。

只比较来自**不同** feature 顶层目录的文件对。也就是说：

- `features/notes/...` vs `features/tasks/...`：检测；
- `features/notes/a.dart` vs `features/notes/b.dart`：不检测。

### 3. Normalization Contract

Detector 以“normalized code lines”作为比较单位。每条原始行按以下规则处理：

1. `trim()` 去除首尾空白；
2. 若结果为空字符串，则跳过；
3. 若结果是纯注释行，则跳过；
4. 其余行保留原始文本内容与原始行号映射。

本 PR 中“纯注释行”定义为 `trim()` 后以下前缀之一：

- `//`
- `///`
- `/*`
- `*`
- `*/`

非目标行为：

- 不尝试解析 Dart 语法；
- 不移除代码尾部 inline comment；
- 不识别字符串字面量内部的注释样式文本；
- 不处理 block comment 的完整词法配对。

这是一个刻意保守的 v1 规则：简单、确定、可在无解析器前提下运行。

### 4. Matching Contract

检测单位是“两个文件之间的最大连续相等 normalized line run”。

实现合同：

- 只报告 **maximal run**，不报告被更大 run 完全覆盖的子区间；
- 只有 run 长度 `>=101` 才构成 violation candidate；
- 输出必须能回溯到双方原始文件中的起止行号；
- 多个 candidate 结果按 `fileA -> fileB -> startA -> startB` 排序，保证稳定输出。

备注：

- DI-21 使用“行哈希序列匹配”描述检测思路；本 PR 的行为目标是“对 normalized line sequence 做确定性连续匹配”。
- 在当前仓库规模下，可以通过 normalized string sequence 直接比较或使用内联确定性哈希实现；无论采用哪种内部实现，**不得**为此引入额外 pub 依赖。

### 5. Allowlist Contract

新增文件：`tools/ci/duplication_allowlist.yaml`

推荐 v1 schema：

```yaml
- fileA: "lib/features/notes/dialogs/create_folder_dialog.dart"
  fileB: "lib/features/tasks/dialogs/folder_picker.dart"
  reason: "Tree/picker boilerplate accepted until PR-0412 extraction"
```

匹配合同：

- allowlist 以**文件对**为粒度，不以行区间为粒度；
- `fileA` / `fileB` 顺序无关，脚本内部应 canonicalize pair；
- `reason` 必填，用于审计；
- allowlist 命中时，该 pair 的 candidate 不计为 failure，但应计入 summary 的 allowlisted 数；
- v1 不支持 glob，不支持 feature 级通配，避免豁免面过宽。

### 6. 首轮命中处置策略

首次启用 detector 后，若当前仓库出现 `>=101` 行命中，只允许三种处置方式：

1. **直接提取共享代码**，如果提取工作量足够小且不越界；
2. **添加窄 allowlist**，如果该重复已被明确接受并由后续 PR 承接；
3. **暂停合并并回到 spec/implementation 复核**，如果命中既非误报也不应豁免。

明确禁止：

- 提高阈值来规避真实命中；
- 用更大的目录排除面隐藏真实命中；
- 在 workflow ledger 或 current docs 中宣称 detector 已落地，但实际仍依赖人工忽略结果。

### 7. Output Contract

#### Check N

Check N 的失败输出必须包含：

- `WHAT`: 哪两个文件、哪两个区间、匹配了多少 normalized lines；
- `WHY`: Rule E extension 的治理原因；
- `REFERENCE`: 指向 `engineering-standards.md (Rule E)`；
- `HOW`: 指向 `lib/shared/` 或 `lib/core/` 抽取路径，必要时提示 allowlist。

推荐输出模板：

```text
VIOLATION: Cross-feature code duplication detected (Rule E extension).
  File A: lib/features/notes/dialogs/create_folder_dialog.dart:15-120
  File B: lib/features/tasks/dialogs/folder_picker.dart:8-113
WHAT: 102 matching normalized lines (threshold: >=101).
WHY: Cross-feature substantive duplication creates hidden shared logic while bypassing Rule E import boundaries.
REFERENCE: docs/architecture/engineering-standards.md (Rule E)
HOW: Extract shared code to lib/shared/ (UI) or lib/core/ (logic); if the duplication is explicitly accepted for a later PR, add a narrow entry to tools/ci/duplication_allowlist.yaml.
```

#### Check 1-3 Reinforcement

本 PR 将现有输出补强为下列合同：

| Check | 必须新增的输出层 |
|------|----------------|
| Check 1: Rule E 跨 feature import | `REFERENCE` + `HOW` |
| Check 2: 文件大小 | `HOW` |
| Check 3: 结构层违规 | `REFERENCE` + `HOW` |

推荐固定修复指引：

- Check 1 `HOW`: move shared capability to `lib/shared/` or `lib/core/`
- Check 2 `HOW`: split by responsibility, prefer coordinator -> manager or service extraction
- Check 3 `HOW`: inject invoker / facade instead of importing raw FRB or UI layer directly

### 8. Docs / Workflow Sync Order

本 PR 的落地顺序必须是：

1. 修改 `architecture_check.dart` 与 `duplication_allowlist.yaml`；
2. 在当前代码库上跑通验证，确认新 Check 不引入误报；
3. 同步 `docs/architecture/engineering-standards.md` 的 Rule E 执行延伸；
4. 更新 `ci-duplication-policy-promotion-workflow.md` 的 coverage ledger；
5. 仅在以上全部完成后，才允许在 PR spec / closeout 语境中把对应 slice 标记为 landed。

如果步骤 1-2 未完成，则步骤 3-4 不得先行。

## Detailed Task Breakdown

| Task | Lane | 内容 | 文件 | 完成定义 | 依赖 |
|------|------|------|------|---------|------|
| T0 | CI | 基线确认与命中面预判 | `tools/ci/architecture_check.dart`、当前仓库 | 记录“当前全绿、无 Check N、无 duplication allowlist”的进入状态 | — |
| T1 | CI | 候选文件发现与 normalized line 数据模型 | `tools/ci/architecture_check.dart` | 能稳定枚举候选文件，并保留 normalized text + original line 映射 | T0 |
| T2 | CI | 最大连续匹配 run 检测 | `tools/ci/architecture_check.dart` | 能在跨 feature 文件对中找出 `>=101` 行的 maximal run | T1 |
| T3 | CI | allowlist 加载与 pair canonicalization | `tools/ci/architecture_check.dart`、`tools/ci/duplication_allowlist.yaml` | file-pair 级豁免生效，summary 可见 allowlisted 数 | T2 |
| T4 | CI | Check N 输出合同 + Check 1-3 补强 | `tools/ci/architecture_check.dart` | Check 1-3/N 全部具备 WHAT/WHY/REFERENCE/HOW 或其约定子集 | T1-T3 |
| T5 | Docs | Rule E 当前文档同步 | `docs/architecture/engineering-standards.md` | Rule E 增加“禁止跨 feature 实质性重复”的当前行为描述 | T4 |
| T6 | Governance | workflow ledger 更新 | `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md` | `governance-rule-surface`、`detector-and-allowlist`、`output-contract` 更新为 landed 或显式 partial，并附 evidence | T4-T5 |
| T7 | Verification | 全量验证与 spec 状态收尾 | PR-0407 spec + repo commands | `dart analyze` 与 `architecture_check.dart` 通过，spec 可进入 merged 收尾 | T4-T6 |

## Planned File Changes

| 文件 | 类型 | 责任 |
|------|------|------|
| `tools/ci/architecture_check.dart` | edit | 新增 Check N、allowlist loader、normalized line / match result 数据结构、Check 1-3 输出补强 |
| `tools/ci/duplication_allowlist.yaml` | add | 窄 file-pair 级豁免清单，必须带审计理由 |
| `docs/architecture/engineering-standards.md` | edit | 同步 Rule E 当前执行延伸，但只能在行为落地后修改 |
| `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md` | edit | 更新 coverage ledger，给 `CPR-002` 留下可审计证据 |
| `docs/releases/v0.4/prs/PR-0407-ci-duplication-detection.md` | edit | 反映 implementation reality、verification result 与最终状态 |

## Verification

### CI Gates

```powershell
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
dart analyze
dart run ../../tools/ci/architecture_check.dart
```

### Repo-Root Verification

```powershell
dart run tools/ci/architecture_check.dart
```

### Structural Verification

```powershell
rg -n "_checkCrossFeatureDuplication|DuplicationMatch|DuplicationResult" tools/ci/architecture_check.dart
Test-Path tools/ci/duplication_allowlist.yaml
rg -n "REFERENCE:|HOW:" tools/ci/architecture_check.dart
```

### Governance Sync Verification

```powershell
rg -n "governance-rule-surface|detector-and-allowlist|output-contract" docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md
rg -n "Rule E" docs/architecture/engineering-standards.md
```

### Expected Verification Outcome

- `dart analyze`: 0 warning
- `dart run tools/ci/architecture_check.dart`: exit 0
- `duplication_allowlist.yaml`: exists
- `architecture_check.dart`: contains Check N implementation and output-contract strings
- workflow ledger: relevant rows no longer remain implicit `pending`

## Risk

| 风险 | 严重度 | 缓解 |
|------|--------|------|
| 首轮出现真实命中，导致基线不再全绿 | MEDIUM | 用“提取 / 窄 allowlist / 暂停复核”三选一处置，不通过改阈值规避 |
| 纯文本归一化漏掉复杂注释形态 | LOW | 明确 v1 只处理纯注释行前缀，不引入解析器；行为写入 spec |
| O(n²) 文件对扫描在后续规模增大后变慢 | LOW | 当前 `lib/features/` 规模有限；v1 先保证正确性与稳定性 |
| 引入外部依赖破坏 standalone `dart run` | MEDIUM | 规定 detector 只能使用 SDK 能力或内联实现 |
| code landed but docs/workflow 未同步 | MEDIUM | 在 spec 中把 sync order 写成硬门禁，T6/T7 必须完成 |

## Acceptance Criteria

- [ ] `architecture_check.dart` 包含跨 feature 重复检测 Check（Check N）
- [ ] Check N 以 `>=101` 条 normalized lines 为 failure threshold
- [ ] 检测只扫描 `apps/lazynote_flutter/lib/features/**/*.dart` 中跨顶层 feature 的文件对
- [ ] 检测排除 `*.g.dart`、`*.freezed.dart` 与 `test/` 路径
- [ ] allowlist 机制存在，且为 file-pair 粒度、带 `reason`
- [ ] Check N 只报告 maximal run，不重复报告被覆盖的子区间
- [ ] Check 1 输出包含 `REFERENCE` 与 `HOW`
- [ ] Check 2 输出包含 `HOW`
- [ ] Check 3 输出包含 `REFERENCE` 与 `HOW`
- [ ] `docs/architecture/engineering-standards.md` 已在行为落地后同步 Rule E 延伸
- [ ] `ci-duplication-policy-promotion-workflow.md` 的相关 ledger row 已更新为 landed 或显式 partial，并附 evidence
- [ ] `dart analyze` 零 warning
- [ ] `dart run tools/ci/architecture_check.dart` 在当前代码库运行全绿（无误报）
- [ ] PR spec Status updated to `Merged` after landing
