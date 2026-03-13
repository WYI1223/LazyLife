# DOC-009 / 07 ADR Create Or Append

## Purpose and Boundary

Execute the carrier decisions from `06`.

For `DOC-009`, this stage must:

1. append DI-1 title-semantics evidence into the published Atom-projection ADR;
2. append DI-1 shell-detail evidence into the published shell-ownership ADR;
3. create a new retrospective ADR for the rebuilt `S9` placement line.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- published ADRs [`../../../../../../architecture/adr/ADR-0001-atom-projection-model.md`](../../../../../../architecture/adr/ADR-0001-atom-projection-model.md) and [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md)
- source doc [`../../../../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md`](../../../../../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md)
- legacy `S9` snapshot [`../../../../../../architecture/rulings-legacy/S9-cross-feature-infrastructure-placement.md`](../../../../../../architecture/rulings-legacy/S9-cross-feature-infrastructure-placement.md)

## ADR Actions

| ADR | Action | Result |
|------|------|------|
| `ADR-0001` | append | Added `DOC-009` evidence that tab carriers consume `atom.title` rather than per-ref `display_name`, keeping tab naming under the existing Atom-projection line |
| `ADR-0002` | append | Added `DOC-009` shell-detail evidence covering state partition, group lifecycle, unified `EditBuffer`, coordinator boundary, DI-4 handoff, and `PR-RB-06` landing |
| `ADR-0009` | create | Published the retrospective ADR for the rebuilt cross-feature infrastructure placement line that corresponds to legacy `S9` |

## ADR Asset Result

1. one new ADR filename was created: `ADR-0009-cross-feature-infrastructure-placement.md`;
2. `ADR-0001` and `ADR-0002` remain append-only updates;
3. all three touched ADR assets satisfy the minimum `PR-0402` skeleton.

## References

- [`08-ruling-update-and-sync.md`](08-ruling-update-and-sync.md)
