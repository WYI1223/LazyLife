# ADR-0006: Provider SPI Interaction

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-10 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S6-provider-spi-interaction.md`](../rulings/S6-provider-spi-interaction.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should Provider SPI stay separate from external mapping ownership, so that remote adapters remain replaceable while sync coordination keeps one local truth?
- Coverage Scope: Covers `08a -> 08b -> 08c -> 08d -> 09 -> v0.3 release evidence` for the provider/orchestrator/mapping split and the rebuilt current ruling published in `PR-0403`. Stops before a full sync orchestrator runtime is activated.
- Current Normative Source: [`../rulings/S6-provider-spi-interaction.md`](../rulings/S6-provider-spi-interaction.md)
- Source Corpus Summary: `08a` boundary ambiguity, `08b` S6 semantic freeze, `08c/08d` execution mapping, `09` closure/handoff, `v0.3 release evidence` verification/sign-off, and the legacy S6 ruling snapshot.

## Source Corpus

- Trigger Source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Decision Source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Execution / Closure Sources:
  [`../../reports/v0.2.5/frontend-review/08c-solution-proposals.md`](../../reports/v0.2.5/frontend-review/08c-solution-proposals.md),
  [`../../reports/v0.2.5/frontend-review/08d-pr-replanning.md`](../../reports/v0.2.5/frontend-review/08d-pr-replanning.md),
  [`../../reports/v0.2.5/frontend-review/09-acceptance-report.md`](../../reports/v0.2.5/frontend-review/09-acceptance-report.md),
  [`../../releases/v0.3/v0.3-release-evidence.md`](../../releases/v0.3/v0.3-release-evidence.md)
- Historical Normative Snapshot: [`../rulings-legacy/S6-provider-spi-interaction.md`](../rulings-legacy/S6-provider-spi-interaction.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | `DOC-001 / S6` | `present` | Early provider-versus-mapping ambiguity preserved |
| Decision Source | `DOC-002 / S6` | `present` | S6 semantic freeze consumed |
| Normative Source | legacy S6 + rebuilt S6 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `08c`, `08d`, `09`, `DOC-007 / v0.3 release evidence` | `present` | Includes sync planning, later handoff evidence, and release-time deferred-boundary confirmation |
| Superseded / Redirected Source | none | `not_applicable` | No later source redirected the line before replay publication |

## Journey Timeline / Phases

1. `08a` recorded that remote provider code, sync coordination, and mapping persistence were not yet separated clearly enough.
2. `08b` froze the line by assigning translation work to providers and mapping ownership to a local orchestrator path.
3. `08c` and `08d` translated that split into v0.3 execution lanes while keeping runtime delivery conditional.
4. `09` confirmed that declaration-only provider and schema infrastructure was an acceptable handoff state.
5. `PR-0403` rebuilt the line into current ADR and ruling carriers.

## Current State

Current architecture treats Provider SPI as a translation boundary and reserves `external_mappings` ownership for the local sync orchestration layer. The authoritative interpretation follows [`../rulings/S6-provider-spi-interaction.md`](../rulings/S6-provider-spi-interaction.md).

## Open Edges

- Full `SyncOrchestratorService` runtime remains a later append point.
- Cursor and delta-sync strategy remain later design detail.
- Conflict-resolution UI remains later follow-up rather than a blocker for this line.

## Revision Record

- 2026-03-10: Initial retrospective reconstruction ADR published in `PR-0403`.
- 2026-03-11: `DOC-005 / 09` replay appended closure and v0.3-handoff confirmation without changing the Provider-SPI line.
- 2026-03-11: `DOC-007 / v0.3-release-evidence` replay appended release-sign-off and deferred-boundary confirmation without creating a new provider-governance line.
