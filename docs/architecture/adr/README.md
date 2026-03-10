# Architecture Decision Records (ADR)

> Mainline registry for published Architecture Decision Records.
> This directory is the journey layer for cross-version decision lines, not the current normative rule layer.

## Purpose and Boundaries

`docs/architecture/adr/` exists to publish stable ADR assets that explain how a decision line evolved across versions and why the current architecture should be read the way it is.

Current scope:

1. provide a mainline home for formally published ADR assets;
2. provide a stable `topic-map.md` entry point for approved themes and published ADR mappings;
3. preserve the boundary between historical reconstruction documents and future native ADR workflow.

This directory does not hold:

1. scratchpads, execution-phase notes, or candidate-theme inventories;
2. first-pass working copies used during `PR-0403` execution;
3. the current-effective normative rule set itself.

## Authority Boundary

1. `Ruling` remains the normative source for current architecture constraints.
2. `ADR` is the journey layer that reconstructs or records the evolution of a decision line across time.
3. When `ADR` and `Ruling` are both present, the current normative interpretation follows the linked `Ruling`, not the ADR narrative.
4. Historical documents may still cite `docs/architecture/rulings-legacy/` while governance replay is in progress.

## ADR Classes and Statuses

### Document Classes

- `Retrospective Reconstruction ADR`
  Used to reconstruct a past decision line from an already-known source corpus. It must explicitly state that it is a future-perspective reconstruction, not a contemporaneous original record.
- `Native ADR`
  Used only after governance activation for newly made architecture decisions created inside the active governance workflow.

### Publication Statuses

- `draft`
  A prepared ADR asset that is not yet the stable published journey record.
- `active`
  The currently published journey record for a decision line.
- `superseded`
  A published ADR whose journey role has been replaced by a newer ADR or redirected carrier.
- `deprecated`
  A published ADR that remains historically visible but should no longer be used as the preferred journey entry point.

### Append-Only Boundary

1. append-only does not automatically apply to `Retrospective Reconstruction ADR`.
2. append-only begins only after governance activation and only for `Native ADR`, unless later governance decisions revise that rule.
3. Historical reconstruction ADRs enter a "frozen but correctable" state after governance activation: corrections and late source recovery remain allowed, but silent narrative rewrites do not.

## Directory Contents

| Asset | Purpose | Current State |
|------|---------|---------------|
| `README.md` | ADR directory entry point and authority boundary | published |
| `topic-map.md` | Mainline mapping surface for approved themes and published ADR references | header-only bootstrap |
| `ADR-000X-<slug>.md` | Published ADR assets | not yet created in `PR-0402` |

## Reading Guide

1. Read [`../rulings/README.md`](../rulings/README.md) first if you need the current normative source set.
2. Read [`topic-map.md`](topic-map.md) next if you need to see which approved themes map to which ADR assets.
3. Open a specific `ADR-000X-<slug>.md` only after the topic map or a ruling/reference path points you there.
4. Use governance execution records under `docs/reports/v0.4/governance-execution/` for in-flight process evidence, not this directory.

## Maintenance Rules

1. Only published ADR assets belong in this directory.
2. New ADR files must follow the active governance contract and lifecycle rules at the time they are published.
3. `topic-map.md` should not absorb candidate themes, unresolved split/merge debates, or execution-only working notes.
4. If a published ADR needs a material boundary change, the change must be justified by the active governance workflow instead of being silently rewritten in place.
5. Backlinks from ADR to current normative sources must remain explicit.

## Reference Documents

- [`../rulings/README.md`](../rulings/README.md)
- [`../rulings-legacy/README.md`](../rulings-legacy/README.md)
- [`../../reports/v0.3/design-discussions/DI-19-adr-governance.md`](../../reports/v0.3/design-discussions/DI-19-adr-governance.md)
- [`../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`](../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)
- [`../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
