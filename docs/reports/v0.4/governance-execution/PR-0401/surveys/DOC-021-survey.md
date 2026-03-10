# DOC-021 Survey

- Source: `docs/reports/v0.3/design-discussions/DI-13-calendar-range-limit-policy.md`
- Title: `DI-13: Calendar Range 查询默认 Limit 策略`
- Doc Class: Design discussion
- Corpus Role: Design discussion source

## Structure Snapshot

- This is a pending issue document with three explicit open question anchors `Q1-Q3`.
- The document also has an explicit `讨论边界` section; for a pending DI, those in-scope/out-of-scope lines are part of the minimum contract surface and should not be skipped.
- There is no resolved ruling block yet, so the candidate surface is the open-question set plus the evidence section that motivated the discussion.
- The background section matters because it records the Tasks-vs-Calendar semantics split that triggered the issue.

## Candidate DN Anchors

- `## 背景`
- `## 讨论边界 / ### In scope`
- `## 讨论边界 / ### Out of scope`
- `## 待裁决问题 / ### Q1. calendar_list_by_range 是否应取消默认 limit=50？`
- `## 待裁决问题 / ### Q2. 如果放开 limit，是否需要安全上限？`
- `## 待裁决问题 / ### Q3. API contract 文档更新策略`
- `## 相关证据`

## Notes

- This row remains `pending`; later extraction should treat these as open discussion anchors, not settled decision lines.
- The problem is contract semantics, not only implementation behavior, so the background/evidence anchors are part of the minimum survey surface.
- The earlier survey was under-specified because it skipped the explicit scope boundary that determines what this pending DI is and is not trying to decide.
