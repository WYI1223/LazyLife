# Governance ADR README Skeleton

> Kickoff prep skeleton for the future `docs/architecture/adr/README.md`.
> This file is a handoff input only. It is not the formal ADR directory entry page.

---

## Purpose

This skeleton captures the minimum structure and boundary statements that the future
`docs/architecture/adr/README.md` must contain once `v0.4 kickoff` promotes ADR assets
into the mainline.

Current scope is limited to:

1. documenting the future README structure;
2. preserving the authority boundary agreed in `DI-19` / `DI-20`;
3. providing a stable handoff artifact for kickoff PR spec organization.

It does not create or activate the formal `docs/architecture/adr/` directory.

---

## Required Sections

The future ADR README should contain at least:

1. `Purpose and Boundaries`
2. `Authority Boundary`
3. `ADR Classes and Statuses`
4. `Directory Contents`
5. `Reading Guide`
6. `Maintenance Rules`
7. `Reference Documents`

---

## Required Boundary Statements

The future ADR README must explicitly state:

1. `Ruling` remains the normative source for current architecture constraints.
2. `ADR` is the journey layer for cross-version decision lines; it is not the normative layer.
3. `Retrospective Reconstruction ADR` and `Native ADR` are distinct document classes.
4. append-only applies only after governance activation and only to `Native ADR`, unless later governance decisions explicitly extend or revise that rule.
5. the formal `docs/architecture/adr/` directory stores published ADR assets only, not scratchpads, candidate theme maps, or execution-phase notes.

---

## Required Directory References

The future ADR README should link to:

1. `topic-map.md`
2. published `ADR-XXXX-*.md` files
3. relevant `Ruling` or governance activation references
4. the current governance playbook / lifecycle references once they are stabilized

---

## Handoff Notes

Before this skeleton is promoted into `docs/architecture/adr/README.md`, kickoff work must:

1. reconcile this skeleton with the finalized topic-map structure;
2. ensure all status terms match the active governance rules;
3. replace prep-only wording with mainline ADR directory wording;
4. verify that all linked assets already exist in the promoted destination.

---

## References

- `docs/reports/v0.3/design-discussions/DI-19-adr-governance.md`
- `docs/reports/v0.3/design-discussions/DI-20-governance-execution-plan.md`
- `docs/reports/v0.3/governance-kickoff-prep/governance-adr-metadata-contract.md`
- `docs/reports/v0.3/governance-kickoff-prep/governance-theme-map-first-pass.md`
