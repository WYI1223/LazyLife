# Current-Effective Rulings Registry

> Canonical home for rulings rebuilt by the v0.4 governance workflow.
> This directory now contains the first current-effective rebuilt ruling set published from `DOC-002` replay in `PR-0403`.

## Status

- Current-effective rebuilt rulings: `S1-S10`
- Legacy snapshot: [`../rulings-legacy/README.md`](../rulings-legacy/README.md)
- Next governance path: `PR-0404 / PR-0405`

## Published Current-Effective Set

| Code | Title | Current ADR | Status | Notes |
|------|-------|-------------|--------|-------|
| `S1` | Atom Projection | [`ADR-0001-atom-projection-model.md`](../adr/ADR-0001-atom-projection-model.md) | `active` | Rebuilt from `DOC-002 / S1` |
| `S2` | Tab Draft Save Ownership | [`ADR-0002-editor-shell-ownership.md`](../adr/ADR-0002-editor-shell-ownership.md) | `active` | Rebuilt from `DOC-002 / S2` |
| `S3` | Tag Workspace Orthogonality | [`ADR-0003-tag-workspace-orthogonality.md`](../adr/ADR-0003-tag-workspace-orthogonality.md) | `active` | Rebuilt from `DOC-002 / S3` |
| `S4` | Creation Path Unification | [`ADR-0004-creation-path-unification.md`](../adr/ADR-0004-creation-path-unification.md) | `active` | Rebuilt from `DOC-002 / S4` |
| `S5` | Extension Kernel Boundary | [`ADR-0005-extension-kernel-boundary.md`](../adr/ADR-0005-extension-kernel-boundary.md) | `active` | Rebuilt from `DOC-002 / S5` |
| `S6` | Provider SPI Interaction | [`ADR-0006-provider-spi-interaction.md`](../adr/ADR-0006-provider-spi-interaction.md) | `active` | Rebuilt from `DOC-002 / S6` |
| `S7` | Reminders Infrastructure | [`ADR-0007-reminders-infrastructure.md`](../adr/ADR-0007-reminders-infrastructure.md) | `active` | Rebuilt from `DOC-002 / S7` |
| `S8` | NoteItem Unification | [`ADR-0008-noteitem-unification.md`](../adr/ADR-0008-noteitem-unification.md) | `active` | Rebuilt from `DOC-002 / S8` |
| `S9` | Cross-Feature Infrastructure Placement | [`ADR-0009-cross-feature-infrastructure-placement.md`](../adr/ADR-0009-cross-feature-infrastructure-placement.md) | `active` | Rebuilt from `DOC-009 / DI-1 Q4.3, Q5` |
| `S10` | Layout Tree Structure and Resolve | [`ADR-0010-layout-tree-structure-and-resolve.md`](../adr/ADR-0010-layout-tree-structure-and-resolve.md) | `active` | First published from `DOC-010 / DI-2 D5-D6` |

## Remaining Legacy-Only Carriers

These lines remain historical-only until later replay runs or activation steps rebuild them:

- `E1`

## Boundary

1. `docs/architecture/rulings/` contains only rulings rebuilt and re-activated through the ADR governance workflow.
2. `docs/architecture/rulings-legacy/` preserves the historical S1-S9/E1 snapshot for replay, audit, and source-corpus extraction.
3. Historical documents may continue to cite `rulings-legacy/`, while current architecture docs should cite rebuilt current rulings when available.
4. New or changed binding rules must land in this directory, not in `rulings-legacy/`.

## Maintenance Rules

1. Every rebuilt ruling must keep an explicit backlink to its published ADR.
2. Current architecture docs should update backlinks to rebuilt rulings once the corresponding line is published here.
3. Historical replay evidence should not be mass-rewritten to hide which legacy snapshot it originally used.

## Next Activation Steps

1. Run repo-wide closure audit in `PR-0404`
2. Complete governance activation in `PR-0405`
