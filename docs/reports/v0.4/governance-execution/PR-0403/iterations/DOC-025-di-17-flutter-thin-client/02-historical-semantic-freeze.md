# DOC-025 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the replay interpretation of `DI-17` before any carrier decision is attempted.

This stage must preserve three facts at the same time:

1. the file header says `RESOLVED`;
2. the source is a historical design-discussion landing contract for Flutter thin-client adoption, not a current-effective carrier by itself;
3. "resolved in source" still does not mean "already landed in current repo behavior."

## Frozen Source Facts

- Source file: `docs/reports/v0.3/design-discussions/DI-17-flutter-thin-client.md`
- Inventory status: `historical`
- Extracted DN range: `DN-458-DN-500`
- Upstream prerequisites explicitly consumed by the source:
  - `DI-14` migrated Flutter-side ownership for change notification, shared tree UI layering, and system-node resolution
  - `DI-16` Rust service and FFI contract direction
  - designated-folder and subtree-query topology baselines from `DI-15`
  - repository-wide no-dual-track migration intent that later lands in `DI-18`

## Semantic Freeze

| Surface | Freeze Result |
|------|------|
| Header status | Preserve as `historical/resolved source`; this run must not normalize the whole document into current-effective status |
| `背景`, `输入约束`, `In Scope`, `Out of Scope` | Preserve as explicit replay framing, dependency control, and execution boundaries |
| `Q1-Q6` plus subclauses | Preserve as locally resolved Flutter landing contracts that may be replayed only as accepted-but-unlanded bundles |
| `DI-14` migrated ownership edges | Preserve as hard handoff inputs rather than optional commentary |
| `DI-16` service/FFI dependency and no-dual-track migration direction | Preserve as execution constraint, not as proof that Flutter landing is already complete |

## Replay Constraint

`DOC-025` may classify clause bundles as accepted direction and sync them into later implementation PR specs, but it must not publish current ADR, ruling, or topic-map text unless the corresponding Flutter landing work is already present in repo behavior.

## References

- [`../../../PR-0401/surveys/DOC-025-survey.md`](../../../PR-0401/surveys/DOC-025-survey.md)
- [`../../../PR-0401/document-inventory.md`](../../../PR-0401/document-inventory.md)
- [`../../workspace-topology-carrier-promotion-workflow.md`](../../workspace-topology-carrier-promotion-workflow.md)
