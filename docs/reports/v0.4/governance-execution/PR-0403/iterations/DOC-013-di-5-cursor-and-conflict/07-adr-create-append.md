# DOC-013 / 07 ADR Create Or Append

## Purpose and Boundary

Execute the carrier decision from `06`.

For `DOC-013`, this stage must:

1. append confirmatory cursor/conflict evidence into the published shell-ownership ADR;
2. avoid creating any new ADR asset.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- published ADR [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md)
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md`](../../../../../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md)

## ADR Append Actions

| ADR | Action | Result |
|------|------|------|
| `ADR-0002` | append | Added `DOC-013` confirmatory evidence covering per-pane cursor independence, the absence of a dedicated local conflict subsystem, inherited sync-frequency context, and the explicit undo/redo follow-up boundary |

## ADR Asset Result

1. zero new ADR filenames were created;
2. `ADR-0002` remains the only touched carrier;
3. `DOC-013` is now reflected in the shell-ownership journey lineage.

## References

- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
