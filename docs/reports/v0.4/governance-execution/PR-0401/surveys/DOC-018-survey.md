# DOC-018 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`
- Title: `DI-10: EditorResolver 壳设计`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- This source has four layers, not just a flat `Q1-Q4` ruling chain:
  - upstream intake and inherited context (`问题提取`)
  - shell-boundary framing (`设计原则：职责边界`)
  - the resolved v0.3 shell contract (`Q1-Q4`)
  - future and handoff placeholders (`开放设计项`)
- `Q1` is not just its three `###` subclauses; the top-level typedef signature is itself a stable contract anchor.
- The later `开放设计项` block is explicitly future-facing and should not be merged into the resolved v0.3 shell contract.
- `EditBuffer 桥接模式` is recorded here as a handoff anchor, but the actual governing decision remains DI-4 Q3.

## Candidate DN Anchors

### Intake / framing anchors

- `## 问题提取 / ### 来源 S2 Phase 3`
- `## 问题提取 / ### 来源 S1 R2 content_type`
- `## 问题提取 / ### v0.3 范围`
- `## 设计原则：职责边界 / ### 三层分离`
- `## 设计原则：职责边界 / ### 编辑核心提取`

### Resolved shell anchors

- `## Q1 裁决：EditorPane 接口`
- `## Q1 裁决：EditorPane 接口 / ### 参数说明`
- `## Q1 裁决：EditorPane 接口 / ### 不传入的参数`
- `## Q1 裁决：EditorPane 接口 / ### 不同 content_type 的渲染差异完全封装在 EditorPane 内部`
- `## Q2 裁决：注册协议 — 静态 Map + register()`
- `## Q3 裁决：Fallback — 错误占位，不 fallback 到 markdown`
- `## Q4 裁决：文件位置 — lib/core/editor/editor_resolver.dart`

### Future / handoff anchors

- `## 开放设计项 / ### View Mode 扩展（占位 — v0.4+ 多编辑范式）`
- `## 开放设计项 / ### EditBuffer 桥接模式（已由 DI-4 Q3 裁决 — D12）`

## Notes

- The resolved shell contract and the future `View Mode` expansion should remain in separate buckets during later extraction/classification.
- The earlier survey was under-specified: it omitted the shell-boundary framing layer and the top-level `Q1` typedef contract.
- `EditBuffer 桥接模式` should be preserved as a handoff boundary to DI-4 rather than re-extracted here as if DI-10 locally resolved it.
