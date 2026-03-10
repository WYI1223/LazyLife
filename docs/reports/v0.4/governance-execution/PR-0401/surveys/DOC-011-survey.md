# DOC-011 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-3-layout-persistence.md`
- Title: `DI-3: 布局持久化、迁移策略、深度限制`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- Built around three explicit rulings `D7-D9`, followed by a DI-3/DI-4 boundary definition.
- The stable extraction units are those four blocks; the lower `###` headings inside them are support material for the same ruling line.
- Extraction should preserve the distinction between storage design, migration strategy, size limits, and stage-boundary rules.

## Candidate DN Anchors

- `## D7 裁决：JSON 持久化 + 独立文件 + 去抖写入`
- `## D8 裁决：一次性替换（Option B）`
- `## D9 裁决：Pane 数上限 8，无深度限制`
- `## DI-3 ↔ DI-4 边界：两阶段恢复模型`

## Notes

- This document contributes both direct decisions and a cross-DI boundary contract.
- The DI-3/DI-4 section should likely remain a separate extraction node from the three `D*` rulings.
