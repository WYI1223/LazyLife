# S8: NoteItem Unification

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S8-noteitem-unification.md`](../rulings-legacy/S8-noteitem-unification.md) |
| Current ADR | [`../adr/ADR-0008-noteitem-unification.md`](../adr/ADR-0008-noteitem-unification.md) |

## Decision

List-oriented FFI responses converge on `AtomListItem` rather than maintaining a parallel `NoteItem` lineage as the primary boundary type.

## Normative Rules

1. List-oriented Atom and note retrieval paths use `AtomListItem` as the current superset DTO boundary.
2. The FFI boundary must not drop displayable Atom fields simply because a caller originated from a note-oriented surface.
3. UI layers decide what to render from the returned fields; DTO type choice must not pre-hide valid Atom data.
4. Search-specific snippet projections may remain separate when they represent a genuinely different projection contract.

## Current Interpretation

- The note-specific list DTO is no longer the preferred primary carrier for current list-oriented FFI surfaces.
- Later consumer cleanup may remove older compatibility seams without redefining this decision line.

## Open Edges

- Legacy consumer cleanup and deprecation mechanics
- Search snippet projection remains intentionally separate

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Trigger source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Journey record: [`../adr/ADR-0008-noteitem-unification.md`](../adr/ADR-0008-noteitem-unification.md)
