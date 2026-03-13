# S3: Tag Workspace Orthogonality

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S3-tag-workspace-orthogonality.md`](../rulings-legacy/S3-tag-workspace-orthogonality.md) |
| Current ADR | [`../adr/ADR-0003-tag-workspace-orthogonality.md`](../adr/ADR-0003-tag-workspace-orthogonality.md) |

## Decision

Tag filtering and workspace-tree structure are orthogonal dimensions. Tag queries may add semantic views, but they must not redefine or mutate the workspace tree itself.

## Normative Rules

1. Tag filtering affects query results, not the explorer tree structure.
2. Explorer always remains a structural view of workspace organization.
3. Tag-result surfaces must preserve explicit path context back into the tree.
4. Designated default folders remain ordinary folders inside explorer semantics.
5. Future list or spatial explorer modes must preserve the same orthogonality rule.

## Current Interpretation

- Later rollout phases may change UI presentation, but not the underlying invariant.
- Current architecture should treat any tag-driven tree mutation as a violation of this ruling.

## Open Edges

- Later list / spatial explorer modes

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Journey record: [`../adr/ADR-0003-tag-workspace-orthogonality.md`](../adr/ADR-0003-tag-workspace-orthogonality.md)
