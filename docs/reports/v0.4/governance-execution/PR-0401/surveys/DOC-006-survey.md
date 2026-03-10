# DOC-006 Survey

- Source: `docs/releases/v0.3/prs/PR-RB-00-doc-fixes.md`
- Title: `PR-RB-00: 文档前置修复与基础设施`
- Doc Class: PR spec / doc governance
- Corpus Role: Governance source

## Structure Snapshot

- The document is lane-organized, but the minimum survey anchors are the lane subclauses rather than the lane headers.
- `Lane B` and `Lane E` contain the strongest governance-bearing clauses; `Lane D` is secondary but still carries explicit historical-disposition decisions.
- `Lane A` and most of `Lane C` are mainly repair/execution instructions and are lower-value extraction candidates unless later themes need them as trigger evidence.

## Candidate DN Anchors

### Primary governance anchors

- `## Lane B / ### B1: Ruling 生命周期 Header 标准化`
- `## Lane B / ### B2: ADR 废弃，职责并入 Ruling 体系`
- `## Lane B / ### B3: Docs 交叉引用 Linter（Check 4）`
- `## Lane E / ### E1: 版本生命周期模板`
- `## Lane E / ### E2: PR Spec 模板`

### Secondary historical / disposition anchors

- `## Lane D: 孤儿文件清理`
- `## Lane C / ### C1: `docs/index.md``
- `## Lane C / ### C2: `docs/product/milestones.md``
- `## Lane C / ### C3: `docs/product/roadmap.md``

## Notes

- This is the earliest explicit source for the ADR -> Ruling transition fact pattern used by later governance replay.
- Survey stage should keep `B1/B2/B3/E1/E2` separate; they answer different governance questions and should not be merged into a single “doc infra” node.
- `Lane D` is not just cleanup bookkeeping: it also records historical retention vs deletion policy and may later matter for source-corpus provenance.
