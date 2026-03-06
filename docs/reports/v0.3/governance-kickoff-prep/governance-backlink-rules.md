# Governance Backlink Rules

> Prep-layer backlink rules for governance documents.
> These rules define traceability expectations before any stable automated checks are finalized.

---

## Purpose

This document defines the minimum traceability rules between:

1. theme maps and ADR materials;
2. governance PR specs and covered themes;
3. closure audit / activation outputs and their inputs;
4. future promoted mainline assets and their prep-layer predecessors.

---

## Node Types

The governance graph currently includes these node classes:

| Node Type | Examples |
|------|---------|
| Theme map node | `TH-001`, `TH-006`, `TH-007` in prep theme map |
| Governance theme node | `T1-T8` |
| PR spec | `PR-GOV-01 ~ PR-GOV-06` |
| ADR draft | prep-layer `adr-drafts/*.md` |
| Prep skeleton | ADR README / topic-map skeleton |
| Closure artifact | closure audit output / activation draft |
| Future mainline asset | promoted ADR, promoted topic-map, playbook, lifecycle backfill |

---

## Required Backlink Rules

### 1. Theme Map ↔ ADR Draft

1. every ADR draft must correspond to one explicit theme-map row;
2. every theme selected for first-batch ADR drafting must carry a non-empty `Planned ADR`;
3. future `Published ADR` may remain `pending` in prep, but the field must still exist;
4. unresolved themes must remain visible in prep-layer theme documents rather than disappearing.

### 2. PR Spec ↔ Governance Themes

1. every `PR-GOV-*` spec must declare `Covered Themes`;
2. every covered theme must have a row-level delta;
3. if a spec claims secondary coverage, that secondary theme should be discoverable from the spec body.

### 3. Closure / Activation ↔ Inputs

1. closure audit output must point back to the check model and relevant prep outputs;
2. activation draft must point back to closure audit output and active governance boundary documents;
3. activation draft must not claim active status unless promoted during future mainline kickoff.

### 4. Prep ↔ Future Mainline

1. prep skeletons must explicitly state their future mainline target path;
2. prep drafts must not masquerade as already-promoted mainline assets;
3. once future mainline promotion happens, promoted assets should retain an obvious backlink to their prep-layer source or handoff record.

---

## Graph Invariants

The following graph invariants should hold:

1. no orphan governance theme in `T1-T8`;
2. no orphan candidate theme selected for ADR drafting;
3. no ADR draft without a discoverable planned slot;
4. no activation draft without closure audit input;
5. no stable template or playbook backfill without a validated execution source.

---

## Automation Boundary

These rules are suitable for future structural / graph automation:

1. missing target file references;
2. missing `Theme ID` or `Planned ADR`;
3. missing `Covered Themes` or row-level deltas;
4. missing closure / activation input references.

These rules still require human review:

1. whether a backlink points to the correct semantic decision line;
2. whether a split / merge judgment is actually valid;
3. whether a theme should remain pending or be promoted.

---

## Current Prep Conclusion

1. Backlink rules now exist as a standalone prep-layer document.
2. They are strong enough for review and future check design.
3. Final automation policy remains deferred until future mainline execution validates them.
