# S4: Creation Path Unification

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S4-creation-path-unification.md`](../rulings-legacy/S4-creation-path-unification.md) |
| Current ADR | [`../adr/ADR-0004-creation-path-unification.md`](../adr/ADR-0004-creation-path-unification.md) |

## Decision

All creation paths must converge on one storage invariant: create the Atom and create at least one `atom_ref` in the same semantic operation.

## Normative Rules

1. Zero-ref atoms are invalid organizational state.
2. Creation-path differences may affect route placement, not object semantics.
3. Operations such as move, duplicate, and delete act on `atom_ref` semantics consistently.
4. View semantics and folder semantics remain orthogonal even when routing uses designated folders.

## Current Interpretation

- Current architecture should read all creation entries as route variants over one invariant.
- Later atom-first or single-root work may append implementation detail without replacing this invariant.

## Open Edges

- Later atom-first follow-up
- Later single-root routing follow-up

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Journey record: [`../adr/ADR-0004-creation-path-unification.md`](../adr/ADR-0004-creation-path-unification.md)
