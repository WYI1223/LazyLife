# DI-21: CI 跨 Feature 代码重复检测

| 项目 | 值 |
|------|-----|
| **状态** | RESOLVED |
| **关联决策点** | DI-17 Q3（触发上下文）、DI-18 Q5.2（需求识别）、Rule E（规范基础） |
| **影响范围** | `tools/ci/architecture_check.dart`、CI pipeline |
| **前置依赖** | DI-17 Q3 裁决（提取触发条件定义） |
| **目标版本** | v0.4 |
| **输出物** | `architecture_check.dart` 新 Check + 现有 Check 输出补强 |

---

## 背景

DI-17 Q3 裁决定义了共享树/picker UI 组件的提取触发条件：**>100 行重复 + 2 个活跃消费者**，提取目标为 `lib/shared/tree/`（UI 基础层）。Rule E（`architecture_check.dart` Check 1）阻止跨 feature import，但不阻止在另一个 feature 下重建功能相同的代码绕过提取。

DI-18 Q5 讨论中识别出现有缓解方案均存在失败模式：

| 缓解方案 | 失败模式 |
|----------|----------|
| PR spec 写明提取要求 | 执行者降级处理 |
| CLAUDE.md 规则 | AI agent 上下文可能忽略 |
| 文件名匹配检测 | 改名绕过 |
| **跨 feature 代码相似度检测（CI）** | **唯一可行的自动化强制方案** |

本 DI 是 DI-18 PR-0b 的设计依据。

---

## 讨论边界

### In Scope

1. `architecture_check.dart` 新增跨 feature 代码重复检测（Check N）
2. 检测参数（最小相似块、触发阈值、扫描范围、排除规则）
3. CI 失败输出格式（可操作的上下文：WHAT/WHY/HOW）
4. 现有 Check 1-3 输出补强（统一三层上下文标准）

### Out of Scope

1. 通用代码质量工具集成（linter、coverage）
2. 同 feature 内部重复检测
3. DI-17 Q3 提取触发条件本身的变更

---

## 规范定位

### 规范源

本 DI 是 **Rule E 的自然延伸**，自身为规范源。

Rule E 确立了"feature 间独立"原则，`architecture_check.dart` Check 1 已强制执行"禁止跨 feature import"。但 Rule E 只阻止了依赖路径（import），未阻止实质性重复（在另一个 feature 下重建功能相同的代码）。跨 feature 实质性重复违反 Rule E 的精神：

- 同一 bug 需要在多处修复，维护成本倍增
- 表明存在缺失的共享抽象
- 为绕过 Rule E 的 import 禁令提供了隐性路径

本 DI 将 Rule E 从"禁止 import"扩展到"禁止实质性重复"，补全 Rule E 的执行闭环。

### 与 DI-17 Q3 的关系

DI-17 Q3 是本 DI 的**触发上下文**（识别出执行缺口的来源），不是唯一规范源。DI-17 Q3 的具体参数（>100 行、树/picker 组件、`lib/shared/tree/`）适用于树组件场景；本 DI 的通用检测覆盖所有 feature 间重复，阈值沿用 DI-17 Q3 的 >100 行作为已验证的合理先例。

---

## 裁决

### Q1 裁决：B — 通用跨 feature 重复治理

**选择 B（通用治理）**，DI-21 自身为规范源。

**理由**：

- 路径 A（严格执行 DI-17 Q3，缩窄到树/picker 组件族）需要维护"组件族名单"，本质上把自动化检测的收益又打回了人工维护，违背了 DI-21 的初衷（"唯一可行的自动化强制方案"）。
- 路径 B 的规范论证成立：Rule E 已建立"feature 间独立"原则，从"禁止 import"到"禁止实质性重复"是自然延伸。
- 扫描范围简单明确（`lib/features/*/` 跨目录），无需人工维护组件族名单。

---

### Q2 裁决：行哈希序列匹配 + >100 行阈值 + allowlist

**算法：行哈希序列匹配**

| 方案 | 原理 | 复杂度 | 精度 | 结论 |
|------|------|--------|------|------|
| **行哈希序列匹配** | 每行去空白后哈希，找跨文件连续 N 行哈希匹配 | 低 | 中 | **选用** |
| Token 化匹配 | 词法分析后比较 token 序列 | 中 | 高 | 精度好但实现重 |
| AST 级别 | 解析语法树比较结构 | 高 | 最高 | 过度工程化 |

**选用理由**：`architecture_check.dart` 现有 Check 都是简单文本扫描（正则/字符串匹配），行哈希复杂度一致。跨 feature 重复的主要模式是大段复制粘贴，行哈希足以覆盖。变量改名绕过的场景极少——超过 100 行代码复制后逐一改名已属"重写"而非"重复"。

**检测参数**：

| 参数 | 值 | 理由 |
|------|-----|------|
| 最小连续匹配行数 | >100 行（101+） | 严格沿用 DI-17 Q3 的 >100 行先例 |
| 行预处理 | 去除前后空白 + 去除纯空行 + 去除纯注释行 | 减少格式差异导致的漏检/误报 |
| 匹配单位 | 跨 2 个不同 feature 目录的文件对 | 同 feature 内不检测（Out of Scope） |
| 扫描范围 | `lib/features/*/` 全部 `.dart` 文件 | Q1 裁决 B |

**排除规则**：

| 排除项 | 理由 |
|--------|------|
| `*.g.dart`、`*.freezed.dart` 等生成代码 | 非人工编写 |
| `test/` 目录 | 测试代码重复是常见模式（相似 test setup） |

**allowlist 机制**（实现自由度下放 PR-0b）：

DI-21 裁决 allowlist 的**存在性需求**：检测必须提供豁免路径，避免已知合理重复（如框架模式 boilerplate）误报阻塞 CI。allowlist 的具体位置、文件名、语法格式均为 PR-0b 的实现自由度，不在本 DI 裁决范围内。

**实现位置**：`architecture_check.dart` 内新增 Check（零外部依赖）。

---

### Q3 裁决：三层上下文输出 + Check 1-3 补强 + 硬编码链接

**新 Check 输出格式**：

```
=== Check N: Cross-feature code duplication ===

FAILURE: Cross-feature code duplication detected (Rule E extension: features must not contain substantive duplicates).

  File A: lib/features/notes/dialogs/create_folder_dialog.dart:15-120 (106 lines)
  File B: lib/features/tasks/dialogs/folder_picker.dart:8-113 (106 lines)
  Matching lines: 102 (after normalization)

ACTION REQUIRED:
  Extract shared code to lib/shared/ (UI components) or lib/core/ (data/state logic).
  Both consumers must import the extracted shared component.

REFERENCE DOCUMENTS:
  - Duplication policy: docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md
  - Cross-feature independence: docs/architecture/engineering-standards.md (Rule E)

RESOLUTION PATTERN:
  1. Identify the shared abstraction
  2. Extract to lib/shared/<component>/ or lib/core/<module>/
  3. Update imports in both features
  If this is a known acceptable duplication, add to the allowlist (see PR-0b implementation)
```

**设计决策**：

| 决策 | 理由 |
|------|------|
| REFERENCE 指向 DI-21 + Rule E | Q1 选 B，DI-21 自身为规范源 |
| HOW 用通用 `lib/shared/` 或 `lib/core/` | CI 无法判断组件类型，不指定具体子目录 |
| 包含 allowlist 提示 | 提供安全阀路径，具体机制由 PR-0b 实现 |

**三层上下文原则（通用化）**：

每个 Check 的失败输出必须包含三层信息：

| 层 | 内容 | 目的 |
|----|------|------|
| **WHAT** | 哪些文件、哪些行、什么类型的违规 | 定位问题 |
| **WHY** | 关联的架构规则编号 + 参考文档链接 | 理解为什么是问题 |
| **HOW** | 具体修复步骤 + 修复模式示例 | 指导修复，消除歧义 |

**现有 Check 补强（Check 1-3，Check 4 已足够）**：

| Check | 补强内容 |
|-------|----------|
| Check 1: Rule E 跨 feature import | + `REFERENCE: docs/architecture/engineering-standards.md (Rule E)` + `HOW: Move to lib/shared/ or lib/core/` |
| Check 2: 文件大小 | + `HOW: Split using coordinator -> manager pattern (ref: PR-0252)` |
| Check 3: 结构层违规 | + `REFERENCE: docs/architecture/engineering-standards.md (Rule A/B)` + `HOW: Inject invoker instead of direct FFI import` |

**文档链接：硬编码**。链接对应稳定的架构文档（`engineering-standards.md`、DI-21），不会频繁变动。配置化增加复杂度但无实际收益。

---

## 关联

- <- DI-17 Q3（触发上下文：提取触发条件定义，识别出执行缺口）
- <- DI-18 Q5.2（需求识别：CI 强制化是唯一可行方案）
- <- Rule E（规范基础：feature 间独立原则，本 DI 将其从"禁止 import"扩展到"禁止实质性重复"）
- -> PR-0b（本 DI 的执行 PR）

---

*前序议题：[DI-18 执行方案](DI-18-execution-plan.md)*
