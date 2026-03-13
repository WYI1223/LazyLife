# DOC-010 / 07 ADR Create Or Append

## Purpose and Boundary

Execute the carrier decision from `06`.

For `DOC-010`, this stage must:

1. create one new retrospective ADR for the layout-tree line;
2. preserve the explicit fact that no prior legacy ruling snapshot existed for this carrier;
3. satisfy the minimum `PR-0402` ADR skeleton.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md`](../../../../../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md)
- current mainline ADR registry state

## ADR Actions

| ADR | Action | Result |
|------|------|------|
| `ADR-0010` | create | Published the retrospective ADR for the new layout-tree structure and resolve line derived directly from `DI-2` |

## ADR Asset Result

1. one new ADR filename was created: `ADR-0010-layout-tree-structure-and-resolve.md`;
2. the asset carries an explicit `Reconstruction Notice`;
3. the asset explicitly states that no separate legacy ruling snapshot existed before this replay;
4. the asset satisfies the minimum `PR-0402` skeleton.

## References

- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
