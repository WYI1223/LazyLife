# DOC-020 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-12-workspace-tree-single-root.md`
- Title: `DI-12: Workspace Tree 单根化与系统语义锚点`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- The document has three layers, not just the visible `Q1-Q12` and `E1-E6` blocks:
  - a governance-level conceptual-parent declaration and problem/scope framing
  - the resolved semantic decision chain `Q1-Q12`
  - the downstream execution handoff `E1-E6` plus the final output-contract block
- The `Q*` section is the primary ruling surface; the `E*` section is the minimum execution-contract surface and should not be collapsed into a generic appendix.
- The conceptual-parent note and `讨论边界` matter because this DI explicitly hands execution detail off to `DI-15` through `DI-18`; later extraction should preserve that parent/child boundary.
- `方案输出要求` is also a distinct handoff anchor because it constrains what later execution documents are expected to produce.

## Candidate DN Anchors

- `治理说明：本文件为概念母题（Conceptual Parent）`
- `## 背景`
- `## 讨论边界 / ### In Scope`
- `## 讨论边界 / ### Out of Scope`
- `## 待裁决问题（Q1-Q12） / ### Q1. 树模型是否改为单根整树？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q2. 根级“未分类”如何表达？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q3. Tasks/Calendar 系统文件夹是否必须存在？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q4. 系统文件夹可执行哪些操作？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q5. 是否保留“重新指定映射”能力？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q6. 创建路由如何定义为结构事实？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q7. Calendar Pending 数据源口径？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q8. Tasks Pending/Inbox 数据源口径？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q9. “active”判定是否作为全局可见性约束？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q10. API 兼容策略（FFI）？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q11. 数据迁移策略？（RESOLVED）`
- `## 待裁决问题（Q1-Q12） / ### Q12. 删除策略与安全网？（RESOLVED）`
- `## 执行清单（v0.4 落地） / ### E1. Core：单根树与系统节点落地`
- `## 执行清单（v0.4 落地） / ### E2. FFI：兼容优先收敛`
- `## 执行清单（v0.4 落地） / ### E3. Flutter：Explorer/Tasks/Calendar 同源化`
- `## 执行清单（v0.4 落地） / ### E4. 一致性与巡检`
- `## 执行清单（v0.4 落地） / ### E5. 测试清单（最小）`
- `## 执行清单（v0.4 落地） / ### E6. 文档同步`
- `## 方案输出要求（本 DI 最终产物）`

## Notes

- `DI-12` is an important upstream for later workspace-governance lines; both the semantic `Q*` rulings and the execution `E*` handoff need to stay visible.
- The earlier survey was under-specified because it skipped the conceptual-parent declaration and the explicit in-scope/out-of-scope boundary that frame the later Q/E chains.
- The later `讨论顺序建议` is workflow guidance, not a primary extraction anchor.
