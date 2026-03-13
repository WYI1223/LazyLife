# DOC-022 / 07 ADR Create Or Append

## Purpose and Boundary

Execute the carrier decisions from `06`.

For `DOC-022`, this stage must:

1. append workspace-tree core-promotion and shared query-surface detail into the published placement ADR;
2. avoid creating any new ADR asset;
3. keep the `DI-17` migration boundary explicit rather than silently folding it into the append text.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- published ADR [`../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md`](../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md)
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md`](../../../../../../reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md)

## ADR Append Actions

| ADR | Action | Result |
|------|------|------|
| `ADR-0009` | append | Added `DOC-022` evidence covering workspace-tree promotion into `lib/core/workspace/`, the shared capability split, caller-scoped subtree-root semantics, `listChildren` plus `listSubtreeAtomRefs`, the supporting query set, the completeness rule, the Rust-side subtree-collection requirement, and the explicit `DI-17` migration boundary for change notification, tree-UI sharing, and system-node-resolution ownership |

## ADR Asset Result

1. zero new ADR filenames were created;
2. `ADR-0009` is the only touched carrier;
3. `DOC-022` is now reflected in the placement journey lineage.

## References

- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
