# PR-0401 Template Extraction Backlog

> PR-0401 confirms the planning-stage template set for source-corpus intake and records newly discovered gaps.

| Artifact | Purpose | Planning Stage | Drafting Stage | Finalization Stage | Current Status | Notes |
|------|------|------|------|------|------|------|
| `governance-source-corpus-inventory-template.zh-CN.md` | Stable template for ordered source corpus inventory | `PR-0401` | `PR-0401` | `PR-0406` | `confirmed_planned` | Confirmed by `document-inventory.md` mainline execution |
| `governance-decision-node-ledger-template.zh-CN.md` | Stable template for extraction-phase DN ledger | `PR-0401` | `PR-0401` | `PR-0406` | `confirmed_planned` | Confirmed by `dn-ledger.md` seed structure |
| `governance-theme-map-template.zh-CN.md` | Stable template for first-pass / approved theme maps | `PR-0401` | `PR-0404` | `PR-0406` | `confirmed_planned` | Still depends on classification-stage validation |
| `document-structure-survey-template.zh-CN.md` | Stable per-document survey template for source-corpus intake | `PR-0401` | `PR-0401` | `PR-0406` | `new_gap_discovered` | Needed because PR-0401 outputs one survey per source document |
| `dn-extraction-sop-template.zh-CN.md` | Stable SOP template for extraction execution and handoff | `PR-0401` | `PR-0403` | `PR-0406` | `new_gap_discovered` | Needed because extraction is multi-pass and must preserve a repeatable process |

## Conclusion

1. The original three planned templates remain valid.
2. PR-0401 surfaced two additional process-template gaps: survey template and DN extraction SOP template.
3. None of these artifacts should be finalized into `docs/development/` before later governance PRs validate them through mainline execution.
