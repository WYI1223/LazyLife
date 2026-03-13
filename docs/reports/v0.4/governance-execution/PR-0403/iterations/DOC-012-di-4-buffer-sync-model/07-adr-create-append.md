# DOC-012 / 07 ADR Create Or Append

## Purpose and Boundary

Execute the carrier decision from `06`.

For `DOC-012`, this stage must:

1. append DI-4 shell/buffer detail into the published shell-ownership ADR;
2. append DI-4 stage-2 loading detail into the published layout-tree/staged-restore ADR;
3. avoid creating any new ADR asset.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- published ADRs [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md) and [`../../../../../../architecture/adr/ADR-0010-layout-tree-structure-and-resolve.md`](../../../../../../architecture/adr/ADR-0010-layout-tree-structure-and-resolve.md)
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md`](../../../../../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md)

## ADR Append Actions

| ADR | Action | Result |
|------|------|------|
| `ADR-0002` | append | Added `DOC-012` shell-buffer detail covering D10/D11/D12, future-mode protocol reservations, bridge rules, and the shell-side loading boundary into the shell-ownership journey carrier |
| `ADR-0010` | append | Added `DOC-012` phase-2 loading timing, ownership, scheduling, failure, and unified runtime-path detail into the staged-restore journey carrier |

## ADR Asset Result

1. zero new ADR filenames were created;
2. `ADR-0002` and `ADR-0010` remain the only touched carriers;
3. `DOC-012` is now reflected in both the shell-ownership and staged-restore journey lineages;
4. no ADR drop or rename was required.

## References

- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
