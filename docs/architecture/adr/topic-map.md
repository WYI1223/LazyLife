# ADR Topic Map

> Mainline mapping surface for approved themes and published ADR assets.
> In `PR-0402`, this file is intentionally header-only: it establishes the field contract but does not publish any `TH-*` rows yet.

## Purpose

This file records only approved themes and their mapping to planned or published ADR assets.

Current scope in `PR-0402`:

1. lock the minimum field model required by `DI-20`;
2. keep `Current Normative Source`, `Planned ADR`, and `Published ADR` as explicit first-class columns;
3. provide a stable mainline shell for future publication work.

## Boundary

1. Candidate themes and unresolved split / merge decisions stay in execution-layer working copies until approved.
2. `PR-0403` may maintain a topic-map working copy under its own execution directory, but should not directly turn this mainline file into a mixed working document.
3. `Published ADR` remains empty or `pending` until a corresponding ADR is actually published.
4. This file must not silently drop unresolved themes; exclusions remain visible in execution-layer artifacts, not here.

## Minimum Field Model

| Theme ID | Decision Line Title | Stable Why-Question | Decision Subject | Governing Tension | Acceptance Semantics | Primary Upstream | Secondary Input Constraints | Relation Types | Supersedes / Redirected By | First Seen In Corpus | Current Status | Current Normative Source | Planned ADR | Published ADR | Owner | Notes |
|----------|---------------------|---------------------|------------------|-------------------|----------------------|------------------|-----------------------------|----------------|----------------------------|----------------------|----------------|----------------------------|-------------|---------------|-------|-------|

## Row Admission Rule

Only approved themes may be added as rows in this file.

Before a row is admitted:

1. the decision line must have passed the relevant classification / carrier checks;
2. `Current Normative Source` must contain an explicit backlink to the current-effective normative carrier; it must not be hidden inside `Notes` or overloaded into `Published ADR`;
3. `Planned ADR` must at least reach a stable placeholder or real filename state;
4. `Published ADR` must remain empty or `pending` unless a real ADR asset already exists in `docs/architecture/adr/`;
5. supersede / redirect edges must remain explicit instead of being implied by row deletion.

## References

- [`README.md`](README.md)
- [`../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`](../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)
- [`../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
