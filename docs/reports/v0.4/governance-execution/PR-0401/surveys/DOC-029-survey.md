# DOC-029 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-21-ci-duplication-detection.md`
- Title: `DI-21: CI 跨 Feature 代码重复检测`
- Doc Class: Governance decision discussion
- Corpus Role: Governance policy source

## Structure Snapshot

- The document establishes a normative extension of Rule E and resolves three explicit policy questions `Q1-Q3`.
- `规范定位` is part of the minimum anchor surface because it explains why DI-21 itself is treated as a policy source.
- `Q3` packages the operational output contract for CI failures and should remain separate from the detection-algorithm choice in `Q2`.

## Candidate DN Anchors

- `## 背景`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`
- `## 规范定位 / ### 规范源`
- `## 规范定位 / ### 与 DI-17 Q3 的关系`
- `## 裁决 / ### Q1 裁决：B — 通用跨 feature 重复治理`
- `## 裁决 / ### Q2 裁决：行哈希序列匹配 + >100 行阈值 + allowlist`
- `## 裁决 / ### Q2 裁决：行哈希序列匹配 + >100 行阈值 + allowlist / **算法：行哈希序列匹配**`
- `## 裁决 / ### Q2 裁决：行哈希序列匹配 + >100 行阈值 + allowlist / **检测参数**`
- `## 裁决 / ### Q2 裁决：行哈希序列匹配 + >100 行阈值 + allowlist / **allowlist 机制**`
- `## 裁决 / ### Q3 裁决：三层上下文输出 + Check 1-3 补强 + 硬编码链接`
- `## 裁决 / ### Q3 裁决：三层上下文输出 + Check 1-3 补强 + 硬编码链接 / **新 Check 输出格式**`
- `## 裁决 / ### Q3 裁决：三层上下文输出 + Check 1-3 补强 + 硬编码链接 / **三层上下文原则（通用化）**`
- `## 裁决 / ### Q3 裁决：三层上下文输出 + Check 1-3 补强 + 硬编码链接 / **现有 Check 补强（Check 1-3）**`
- `## 裁决 / ### Q3 裁决：三层上下文输出 + Check 1-3 补强 + 硬编码链接 / **文档链接：硬编码**`

## Notes

- `DI-21` is not only an implementation note for `architecture_check.dart`; it also acts as a governance/policy source.
- `Q2` and `Q3` answer different questions: detection mechanics vs. failure-report contract.
- Later extraction should treat `DI-21` as `current_effective`, not `historical`, because it explicitly declares itself a Rule E extension and normative source.
