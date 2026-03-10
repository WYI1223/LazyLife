# DOC-001 Survey

- Source: `docs/reports/v0.2.5/frontend-review/08a-audit-findings.md`
- Title: `08a — 审计发现（事实基础）`
- Doc Class: Audit report
- Corpus Role: Trigger source

## Structure Snapshot

- `## 1.1` is already split into ten stable finding units `D1-D10`; those are the minimum trigger anchors for the technical-debt portion.
- `## 1.3` and `## 1.4` are table-driven inventories; row IDs `S1-S8` and `F1-F8` are the actual minimum extraction anchors, not just the section headers.
- `## 1.2` is a synthesis section that aggregates Rule E violations and severity buckets; it is useful as cross-cutting evidence but should not swallow the lower-level `D*` anchors.

## Candidate DN Anchors

### Finding anchors

- `## 1.1 / ### D1: `notes_style.dart` 跨 feature import`
- `## 1.1 / ### D2: `search_results_view.dart` 跨 feature import`
- `## 1.1 / ### D3: NoteExplorer 仍为大文件`
- `## 1.1 / ### D4: notes → workspace 跨 feature import`
- `## 1.1 / ### D5: P2 模块未拆分`
- `## 1.1 / ### D6: smoke_test overflow`
- `## 1.1 / ### D7: Tag 语义不一致（note vs note_ref）`
- `## 1.1 / ### D8: Note 创建入口语义差异`
- `## 1.1 / ### D9: NotesCoordinator 实现层超出规模目标`
- `## 1.1 / ### D10: calendar/tasks → reminders 跨 feature import`

### Synthesis anchors

- `## 1.2 Rule E 违规全景`
- `## 1.2 / 严重度分层`

### Semantic ambiguity anchors

- `## 1.3 / S1`
- `## 1.3 / S2`
- `## 1.3 / S3`
- `## 1.3 / S4`
- `## 1.3 / S5`
- `## 1.3 / S6`
- `## 1.3 / S7`
- `## 1.3 / S8`

### Document drift anchors

- `## 1.4 / F1`
- `## 1.4 / F2`
- `## 1.4 / F3`
- `## 1.4 / F4`
- `## 1.4 / F5`
- `## 1.4 / F6`
- `## 1.4 / F7`
- `## 1.4 / F8`

## Notes

- This is an upstream fact source, not a current-effective governance source.
- Table-row IDs in `1.3` and `1.4` must be preserved as source anchors; they are the only stable clause identifiers for those inventories.
- Individual `D*`, `S*`, and `F*` rows may later serve as ADR narrative evidence rather than direct binding rules.
