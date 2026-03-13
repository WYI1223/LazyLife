# PR-0404: Theme Delta Contract and Consistency Audit

| Field | Value |
|------|-----|
| **Status** | Merged |
| **Theme Coverage** | `T5`, `T6` |
| **Dependencies** | `PR-0402`, `PR-0403` |
| **Related Decision** | [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md) |

---

## Purpose

PR-0404 is currently in its initialization pass. This pass turns the landed PR-0403 replay pattern into an auditable scaffold and prepares the first repo-wide consistency audit across the governance surfaces produced by PR-0401 through PR-0403.

This PR does not publish new retrospective ADR content. It does four narrower things:

1. initialize the minimum `Theme Delta Contract` scaffold that later governance PRs will finalize and follow;
2. prepare the structural, graph, policy, and semantic audit surfaces across the current governance outputs;
3. establish one shared decision point for accepted-but-unlanded bundle families so later implementation PRs know exactly what still blocks carrier promotion;
4. produce scaffolded handoff artifacts for later PR-0405 closeout and PR-0407 through PR-0413 implementation work.

The new shared decision point is [carrier-promotion-decision-register.md](../../../reports/v0.4/governance-execution/carrier-promotion-decision-register.md). PR-0404 initializes and later updates that register. PR-0405 must consume it during final closure only after PR-0404 has produced finalized audit outputs. Later implementation PRs must leave evidence that keeps the relevant register row auditable.

---

## Current Landed Interpretation

`DOC-028 / DI-20` confirms the current landed audit interpretation for this PR:

1. `Theme Delta Contract` has a PR-level header and a separate row-level schema; both are mandatory.
2. The T6 governance closure stack is `Structural Checks -> Graph Checks -> Policy Checks -> Semantic Review -> Closure Audit Output`.
3. Automation may cover structure, graph, and part of policy validation, but semantic closure still requires accountable human review.
4. PR-0404 is the explicit consumer of governance-spec handoff from `DOC-028`, including the audit decision on whether any accepted-but-unlanded bundle family is still blocked or is ready for later carrier promotion.

---

## Scope

### In Scope

1. Initialize the executable `Theme Delta Contract` scaffold from PR-0403 execution evidence.
2. Initialize the repo-wide structural, graph, policy, and semantic consistency audit scaffold over PR-0401 through PR-0403 outputs.
3. Initialize and maintain the shared carrier-promotion decision point for later implementation PRs.
4. Produce scaffolded index-sync and template-audit artifacts needed by PR-0405 and PR-0406.

### Out of Scope

1. Publishing new retrospective ADR text or reopening PR-0403 replay.
2. Governance activation itself. That belongs to PR-0405.
3. Template finalization inside `docs/development/`. That belongs to PR-0406.
4. Workspace implementation landing. That belongs to PR-0407 through PR-0413.

---

## Actions

### Action 1: Initialize Theme Delta Contract Scaffold

Use PR-0403's actual execution history to initialize the minimum contract scaffold for:

- PR-level delta header fields
- row-level delta schema
- operation catalog coverage
- anti-downgrade hooks
- published-surface versus execution-surface boundaries

Primary inputs:

- [governance-theme-delta-contract-model.md](../../../reports/v0.3/governance-kickoff-prep/governance-theme-delta-contract-model.md)
- [PR-0403/README.md](../../../reports/v0.4/governance-execution/PR-0403/README.md)
- PR-0403 iteration records and topic-map working copy

### Action 2: Initialize Repo-wide Consistency Audit Scaffold

Prepare the audit structure for PR-0401 through PR-0403 outputs using the landed DI-20 stack:

1. `Structural Checks`
2. `Graph Checks`
3. `Policy Checks`
4. `Semantic Review`

When the full audit content is filled in later in PR-0404, its scope must cover at least:

- PR-0401 extraction artifacts
- PR-0403 classification artifacts
- current published ADR, ruling, and topic-map surfaces
- PR-0403 workflow ledgers for accepted-but-unlanded bundles

### Action 3: Maintain Shared Carrier Promotion Decision Point

Initialize and update the shared register:

- [carrier-promotion-decision-register.md](../../../reports/v0.4/governance-execution/carrier-promotion-decision-register.md)

This action must:

1. record the current audit decision for workspace-topology carrier promotion;
2. record the current audit decision for CI-duplication policy promotion;
3. define the blocking conditions, downstream owners, and final promotion owner for each family;
4. leave PR-0405 with one clean closeout surface instead of forcing it to reconstruct decisions from multiple workflow files.

### Action 4: Initialize Index and Template Audit Artifacts

Produce:

- index sync strategy
- consistency audit report
- template audit confirmation

These scaffolds should make later PR-0405 closeout and PR-0406 template backfill mechanical rather than interpretive.

---

## Deliverables

All outputs live under `docs/reports/v0.4/governance-execution/PR-0404/`.

| Action | Deliverable | Purpose |
|------|------|------|
| 1 | `theme-delta-contract.md` | Initialized contract scaffold to be filled and finalized inside PR-0404 |
| 2 | `consistency-audit-report.md` | Initialized repo-wide audit scaffold for structural, graph, policy, and semantic sections |
| 3 | shared register update | Initialized governance decision point recorded in `carrier-promotion-decision-register.md` |
| 4 | `index-sync-strategy.md` | Initialized execution-rule scaffold for later published-index synchronization |
| 4 | `template-audit-confirmation.md` | Initialized template-audit scaffold and PR-0406 handoff surface |

---

## Planned File Changes

- `[edit]` `docs/releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md`
- `[edit]` `docs/reports/v0.4/governance-execution/PR-0404/README.md`
- `[add]` `docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0404/theme-delta-contract.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0404/consistency-audit-report.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0404/index-sync-strategy.md`
- `[add]` `docs/reports/v0.4/governance-execution/PR-0404/template-audit-confirmation.md`
- `[edit]` `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`
- `[edit]` `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0407-ci-duplication-detection.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0408-schema-migration.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0409-scoped-query-repository.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0410-tree-service-creation-service.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0411-guard-ffi.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0412-flutter-core.md`
- `[edit]` `docs/releases/v0.4/prs/PR-0413-flutter-features.md`
- `[edit]` `docs/releases/v0.4/README.md`
- `[edit]` `docs/reports/v0.4/governance-execution/README.md`
- `[edit]` `docs/releases/v0.4/v0.4-kickoff.md`

---

## Verification

Minimum verification for this planning-and-contract pass:

1. shared register is referenced by PR-0404, PR-0405, both PR-0403 workflow files, and PR-0407 through PR-0413 specs;
2. PR-0404 artifacts exist and are linked from the execution README;
3. status surfaces mark PR-0404 as active work;
4. `dart run tools/ci/architecture_check.dart` passes after the doc updates.

---

## Exit Gate

- [ ] `theme-delta-contract.md` initialized and linked from PR-0404 execution README
- [ ] repo-wide audit report scaffold initialized
- [ ] shared carrier-promotion decision register initialized
- [ ] workspace-topology and CI-duplication workflow documents reference the shared register
- [ ] PR-0405 explicitly consumes the shared register for closeout
- [ ] PR-0407 through PR-0413 explicitly cite the shared register as a downstream audit surface
- [ ] PR-0404 status synced to active planning surfaces
- [ ] `dart run tools/ci/architecture_check.dart` passes

---

## References

- [DI-20-governance-execution-plan.md](../../../reports/v0.3/design-discussions/DI-20-governance-execution-plan.md)
- [PR-0403-per-adr-serial-execution.md](PR-0403-per-adr-serial-execution.md)
- [PR-0405-closure-audit-and-governance-activation.md](PR-0405-closure-audit-and-governance-activation.md)
- [workspace-topology-carrier-promotion-workflow.md](../../../reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md)
- [ci-duplication-policy-promotion-workflow.md](../../../reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md)
- [carrier-promotion-decision-register.md](../../../reports/v0.4/governance-execution/carrier-promotion-decision-register.md)
