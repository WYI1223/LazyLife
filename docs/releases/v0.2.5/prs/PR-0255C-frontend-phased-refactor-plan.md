# PR-0255C-frontend-phased-refactor-plan

- Proposed title: `docs(frontend): phased refactor plan with regression and PR gates`
- Status: Planned

## Goal

Define a staged (2-4 week) frontend refactor plan with explicit regression
validation and PR gate requirements.

Prerequisite:

- `PR-0255A` and `PR-0255B` are both accepted.

Primary reference template:

- `docs/development/report-templates/phased-refactor-plan-template.zh-CN.md`

## Scope

In scope:

- consume outputs from `PR-0255A` and `PR-0255B`
- define phased plan and milestone checks
- define regression suite and PR gate policy

Out of scope:

- runtime refactor implementation
- new product behavior scope

## Required Output

- `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md`

Plan must include:

1. phase breakdown (week-based)
2. per-phase scope and exit criteria
3. regression checks (must-run test/analyze/format sets)
4. PR gate checklist and rollback guidance

Output must follow the structure and terminology from the primary reference
template.

## Milestone-to-Template Mapping

1. `M1` maps to template sections `0`, `1`, `2`, and `3`.
2. `M2` maps to template sections `4`, `5`, and `6`.
3. `M3` maps to template sections `7`, `8`, `9`, `10`, and `11`.

## Milestones

### M1 - Phase Design (2-4 weeks)

Goal:

- define staged execution slices aligned to `0255B` split priorities

Deliverables:

- draft sections `0/1/2/3` in `03-phased-refactor-plan.md`

Exit Criteria:

- [ ] each phase has explicit scope and "out-of-scope"
- [ ] each phase has start/exit conditions

### M2 - Regression and Gate Matrix

Goal:

- lock must-run validation and PR gates per phase

Deliverables:

- draft sections `4/5/6` in `03-phased-refactor-plan.md`

Exit Criteria:

- [ ] regression matrix covers critical workspace/notes flows
- [ ] PR gates are checkable and reproducible

### M3 - Review, Risk Fallback, and Closure

Goal:

- finalize plan with rollback/fallback rules and ownership

Deliverables:

- completed sections `7/8/9/10/11` in `03-phased-refactor-plan.md`
- closure note in `PR-0255C`

Exit Criteria:

- [ ] rollback strategy is defined for each phase
- [ ] plan is approved as direct execution input for `PR-0252`

## Planned File Changes

- [add] `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md`
- [edit] `docs/releases/v0.2.5/README.md` (progress marker)
- [edit] `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md` (prerequisite sync)

## Acceptance Criteria

- [ ] 2-4 week phased plan is explicit and executable
- [ ] regression and PR gate requirements are unambiguous
- [ ] `PR-0252` prerequisites point to this plan
- [ ] milestone outputs (`M1`-`M3`) are complete and review-signed
