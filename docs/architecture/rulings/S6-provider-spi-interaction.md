# S6: Provider SPI Interaction

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S6-provider-spi-interaction.md`](../rulings-legacy/S6-provider-spi-interaction.md) |
| Current ADR | [`../adr/ADR-0006-provider-spi-interaction.md`](../adr/ADR-0006-provider-spi-interaction.md) |

## Decision

Provider SPI is a translation boundary, while ownership of `external_mappings` and sync flow coordination belongs to the local orchestration layer.

## Normative Rules

1. Provider implementations translate remote API concepts and must not directly read or write `external_mappings`.
2. The local sync orchestration layer is the only owner of mapping lookup, creation, and update flow.
3. `external_mappings` is an Atom-level mapping surface, not an `atom_ref`-level mapping surface.
4. Remote pull-created items must follow the same current creation invariants as local items, including `Atom + atom_ref` pairing and derived rendering semantics.
5. Declaration-only provider contracts remain acceptable until the orchestration runtime is activated.

## Current Interpretation

- Provider replaceability depends on keeping remote adapters unaware of local mapping persistence.
- Runtime completion of sync orchestration may append detail, but it should not collapse the separation between provider and mapping ownership.

## Open Edges

- Full sync orchestrator runtime
- Cursor and delta-sync strategy
- Conflict-resolution UI and merge policy

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Trigger source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Journey record: [`../adr/ADR-0006-provider-spi-interaction.md`](../adr/ADR-0006-provider-spi-interaction.md)
