# DOC-024 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the replay interpretation of `DI-16` before any carrier decision is attempted.

This stage must preserve three facts at the same time:

1. the file header still says `IN PROGRESS`;
2. many clause-level anchors inside the body are already explicitly `RESOLVED`;
3. replay cannot silently turn "resolved in source" into "current-effective in repo".

## Frozen Source Facts

- Source file: `docs/reports/v0.3/design-discussions/DI-16-rust-service-ffi-contract.md`
- Inventory status: `pending`
- Extracted DN range: `DN-396-DN-457`
- Upstream prerequisites explicitly consumed by the source:
  - `DI-14` workspace-tree core-promotion direction
  - `DI-15` multi-root workspace model and `origin_workspace_id`
  - `S1` atom/view semantics
  - designated-folder and subtree-query baselines

## Semantic Freeze

| Surface | Freeze Result |
|------|------|
| Header status | Preserve as `pending/in-progress` at document level; this run must not normalize the whole document into current-effective status |
| `输入约束`, `In Scope`, `Out of Scope` | Preserve as explicit replay framing and dependency control |
| `A1-A12` | Preserve as inherited architecture prerequisites rather than newly published carriers |
| `Q1-Q6` plus subclauses | Preserve as locally resolved service/FFI contracts that may be replayed as accepted-but-unlanded bundles |
| Out-of-scope pointers to `DI-15`, `DI-17`, and `DI-18` | Preserve as hard replay boundaries, not editorial notes |

## Replay Constraint

`DOC-024` may classify clause bundles as accepted direction, but it must not publish current ADR, ruling, or topic-map text unless the corresponding workspace implementation slices are already landed in repo behavior.

## References

- [`../../../PR-0401/surveys/DOC-024-survey.md`](../../../PR-0401/surveys/DOC-024-survey.md)
- [`../../../PR-0401/document-inventory.md`](../../../PR-0401/document-inventory.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
