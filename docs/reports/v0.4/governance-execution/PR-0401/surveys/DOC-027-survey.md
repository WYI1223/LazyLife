# DOC-027 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md`
- Title: `DI-19: Architecture Decision Records 治理方案`
- Doc Class: Governance decision discussion
- Corpus Role: Governance decision source

## Structure Snapshot

- This document has two layers that must be kept separate at survey stage:
- `§2.1`, `§2.3`, and `§10-§15` are the current-effective governance revision payload.
- `§3-§9` are retained historical/superseded proposal blocks and still matter as replay evidence, but they are not the active rule surface.
- `§2.2` is also superseded and must not be treated as the active SSOT rule set even though it appears inside the high-level five-layer proposal section.

## Candidate DN Anchors

### Current-effective anchors

- `## 2. 方案：五层文档体系 / ### 2.1 完整文档层次`
- `## 2. 方案：五层文档体系 / ### 2.3 目录结构`
- `## 10. 修订后的 SSOT 规则与生效范围 / ### 10.1 规范源层级`
- `## 10. 修订后的 SSOT 规则与生效范围 / ### 10.2 本 DI 的治理修订例外`
- `## 10. 修订后的 SSOT 规则与生效范围 / ### 10.3 生效范围`
- `## 10. 修订后的 SSOT 规则与生效范围 / ### 10.4 append-only 的有效边界`
- `## 11. 历史补录 ADR 规范 / ### 11.1 文档分类`
- `## 11. 历史补录 ADR 规范 / ### 11.2 历史重演锚点`
- `## 11. 历史补录 ADR 规范 / ### 11.3 Source Corpus 要求`
- `## 11. 历史补录 ADR 规范 / ### 11.4 叙事约束`
- `## 11. 历史补录 ADR 规范 / ### 11.5 首批主题识别规则`
- `## 11. 历史补录 ADR 规范 / ### 11.6 建立 ADR 的判断条件`
- `## 11. 历史补录 ADR 规范 / ### 11.7 粒度原则：以“决策线”为单位`
- `## 12. PR 级文档影响与更新义务 / ### 12.1 文档影响矩阵`
- `## 12. PR 级文档影响与更新义务 / ### 12.2 必查对象`
- `## 12. PR 级文档影响与更新义务 / ### 12.3 阻断条件`
- `## 13. 一致性校验、回链与可追溯性要求 / ### 13.1 两层校验`
- `## 13. 一致性校验、回链与可追溯性要求 / ### 13.2 最低追溯要求`
- `## 13. 一致性校验、回链与可追溯性要求 / ### 13.3 自动化与人工校验边界`
- `## 14. 修订后的执行顺序 / ### 14.1 顺序原则`
- `## 14. 修订后的执行顺序 / ### 14.2 建议步骤`
- `## 14. 修订后的执行顺序 / ### 14.3 治理激活点`
- `## 15. 与 Release Lifecycle 的挂接要求`

### Historical / superseded anchors kept for replay

- `## 2. 方案：五层文档体系 / ### 2.2 核心 SSOT 规则`
- `## 3. ADR 模板 / ### 3.1 模板设计决策`
- `## 3. ADR 模板 / ### 3.2 内容边界规则`
- `## 4. ADR 创建触发条件 / ### 4.1 正向触发（满足任一即建）`
- `## 4. ADR 创建触发条件 / ### 4.2 反向约束（不建 ADR 的场景）`
- `## 4. ADR 创建触发条件 / ### 4.3 粒度原则`
- `## 4. ADR 创建触发条件 / ### 4.4 与现有文档生命周期的配合`
- `## 5. ADR README.md 规范 / ### SSOT 边界`
- `## 5. ADR README.md 规范 / ### 创建条件`
- `## 5. ADR README.md 规范 / ### 内容边界`
- `## 6. CI 检查 / ### 6.1 现有覆盖`
- `## 6. CI 检查 / ### 6.2 模板防断链约定`
- `## 6. CI 检查 / ### 6.3 暂不实施的检查（ADR 数量超 10 篇后评估）`
- `## 7. v0.4 执行清单 / ### 7.1 执行步骤`
- `## 7. v0.4 执行清单 / ### 7.2 首批 ADR 识别`
- `## 7. v0.4 执行清单 / ### 7.3 不建 ADR 的主题（当前不满足触发条件）`
- `## 8. Ruling README 更新规范`

## Notes

- DI-19 is a current-effective governance source, not just historical discussion.
- Survey stage must keep current-effective anchors and superseded anchors in separate buckets; otherwise later extraction will blur active rules with historical proposals.
- The earlier seed over-emphasized superseded `§4-§5` material; later extraction must realign the current-effective surface to `§10-§15`.
- `§4` and `§5` remain valid historical replay inputs even though the document itself marks them `SUPERSEDED`.
