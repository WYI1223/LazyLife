# S1: Atom Projection

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S1-atom-projection.md`](../rulings-legacy/S1-atom-projection.md) |
| Current ADR | [`../adr/ADR-0001-atom-projection-model.md`](../adr/ADR-0001-atom-projection-model.md) |

## Decision

Atom is the unified semantic container for note, task, and calendar projections. Current architecture must interpret projection, routing, and naming semantics from Atom fields rather than from a user-chosen type flag.

## Normative Rules

1. `content_type` selects the content carrier and editor family.
2. `view_hint` is a derived rendering hint, not a user-owned semantic type.
3. Rendering semantics follow real fields such as time fields and `task_status`; query logic must not depend on `view_hint` alone.
4. Every creation path must materialize `Atom + atom_ref`; zero-ref atoms are invalid organizational state.
5. Designated default folders are ordinary folders used for routing, not privileged smart-folder carriers.
6. `title` is the cross-view naming source of truth; `preview_text` and per-ref display names do not replace it.
7. Future-facing extensions such as comments, canvas, conversation, and overlay sidecar remain explicit tracked edges rather than implicit semantic rewrites.
8. Any stack surface that represents the derived rendering hint must align on `ViewHint / view_hint`; legacy `AtomType` or `kind` naming must not be used to imply a second semantic type system.

## Current Interpretation

- The v0.3 baseline landed the core container, routing, `content_type`, `view_hint`, and `title` direction.
- `DI-11` then made the naming consequence explicit: the enum, field, and helper vocabulary that carries the rendering hint should converge on `ViewHint / view_hint` rather than preserving `AtomType / kind` aliases.
- Later fields and carrier extensions remain explicit follow-up edges, not reasons to reinterpret the line.

## Open Edges

- Comment stream semantics
- Canvas carrier and spatial follow-up
- Conversation carrier
- Overlay sidecar follow-up

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Later detail source: [`../../reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md`](../../reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md)
- Trigger source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Journey record: [`../adr/ADR-0001-atom-projection-model.md`](../adr/ADR-0001-atom-projection-model.md)
