# Governance ADR Topic Map Skeleton

> Kickoff prep skeleton for the future `docs/architecture/adr/topic-map.md`.
> This file is a handoff input only. It is not the formal approved topic map.

---

## Purpose

This skeleton defines the minimum structure that the future formal ADR topic map must carry
after `v0.4 kickoff` selects approved themes for mainline promotion.

Current scope is limited to:

1. preserving the minimum field model agreed in `DI-20`;
2. showing how approved themes will be represented;
3. separating prep-layer first-pass theme inventory from the future formal topic map.

Candidate themes and unresolved split/merge decisions remain in
`governance-theme-map-first-pass.md` until kickoff confirms them.

---

## Minimum Field Model

| Field | Purpose |
|------|---------|
| `Theme ID` | Stable theme identifier |
| `Decision Line Title` | Decision-line display title |
| `Stable Why-Question` | Standardized core question |
| `Decision Subject` | Core decision subject |
| `Governing Tension` | Long-running design tension |
| `Acceptance Semantics` | What counts as solved |
| `Primary Upstream` | Document-level primary upstream |
| `Secondary Input Constraints` | Clause-level upstream constraints |
| `Relation Types` | `upstream dependency` / `inherited context` / `superseding dependency` / `co-occurrence only` |
| `Supersedes / Redirected By` | Redirect or supersede edges |
| `First Seen In Corpus` | Earliest source-corpus appearance |
| `Current Status` | `planned`, `published`, `superseded`, `redirected`, etc. |
| `Planned ADR` | Planned ADR slot or filename |
| `Published ADR` | Published ADR target once promoted to mainline |
| `Owner` | Theme owner |
| `Notes` | Additional constraints or comments |

---

## Approved Theme Rows

The formal topic map should only include approved themes.

Until kickoff confirms them, themes remain in prep-layer form. A future promoted row should
look like:

| Theme ID | Decision Line Title | Stable Why-Question | Decision Subject | Governing Tension | Acceptance Semantics | Primary Upstream | Secondary Input Constraints | Relation Types | Supersedes / Redirected By | First Seen In Corpus | Current Status | Planned ADR | Published ADR | Owner | Notes |
|----------|---------------------|---------------------|------------------|-------------------|----------------------|------------------|-----------------------------|----------------|----------------------------|----------------------|----------------|-------------|---------------|-------|-------|
| `T?` | `...` | `...` | `...` | `...` | `...` | `...` | `...` | `...` | `...` | `...` | `planned` | `ADR-000X-...` | `pending` | `...` | `...` |

---

## Boundary Rules

1. unresolved candidate themes stay in `governance-theme-map-first-pass.md`, not in the formal topic map;
2. `Planned ADR` may contain slot placeholders before mainline naming is finalized;
3. `Published ADR` must remain empty or `pending` until the corresponding ADR is actually promoted and published;
4. the formal topic map must not silently drop unresolved themes; if a theme is excluded from the first batch, the reason must remain visible in prep-layer documents.

---

## Handoff Notes

Before this skeleton is promoted into `docs/architecture/adr/topic-map.md`, kickoff work must:

1. confirm which themes are approved for mainline mapping;
2. assign precise ADR filenames and numbering;
3. reconcile `Planned ADR` slots with real published assets;
4. ensure the formal topic map no longer contains prep-only notes that belong in first-pass inventory.

---

## References

- `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`
- `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md`
- `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md`
