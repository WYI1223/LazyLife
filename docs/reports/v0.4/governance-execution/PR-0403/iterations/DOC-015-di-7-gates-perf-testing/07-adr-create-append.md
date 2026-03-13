# DOC-015 / 07 ADR Create Or Append

## Purpose and Boundary

Execute the carrier decision from `06`.

For `DOC-015`, this stage must:

1. append DI-7 Gate B precision, benchmark-definition, SLA, and verification-method detail into the published layout-tree ADR;
2. avoid creating any new ADR asset;
3. keep the broader Gate A / Release Gate / test-migration policy bundle out of the current ADR carrier.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- published ADR [`../../../../../../architecture/adr/ADR-0010-layout-tree-structure-and-resolve.md`](../../../../../../architecture/adr/ADR-0010-layout-tree-structure-and-resolve.md)
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md`](../../../../../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md)

## ADR Append Actions

| ADR | Action | Result |
|------|------|------|
| `ADR-0010` | append | Added DI-7 Gate B precision, inherited baseline SLA, benchmark dimensions, v0.3 SLA table, two-layer verification method, and the explicit no-benchmark-CI decision into the existing layout/editor-infrastructure journey carrier |

## ADR Asset Result

1. zero new ADR filenames were created;
2. `ADR-0010` remains the only touched carrier;
3. `DOC-015` is now reflected in the published layout/editor-infrastructure journey lineage;
4. the broader repo-wide gate/test policy bundle remains explicit in execution artifacts only.

## References

- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
