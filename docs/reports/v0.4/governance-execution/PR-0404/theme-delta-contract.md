# Theme Delta Contract

- Status: finalized
- Owner: PR-0404
- Last Updated: 2026-03-12

## Purpose and Boundary

PR-0404 is a governance audit PR. It does not publish or amend mainline `TH-*` rows, retrospective ADR files, or current rulings.

Its theme-delta responsibility is narrower:

1. finalize the PR-level and row-level `Theme Delta Contract` shape that DI-20 requires;
2. audit the already-published governance and carrier surfaces created by PR-0401 through PR-0403;
3. record whether any accepted-but-unlanded bundle family is eligible for later carrier promotion;
4. keep parked, deferred, and implementation-only material out of mainline published surfaces.

## Finalized PR-Level Header

| Field | Content |
|------|------|
| Source Doc Group | `PR-0404 / Theme Delta Contract + Consistency Audit` |
| Covered Themes | `none (governance audit only; no new or amended mainline theme rows)` |
| Theme Operations | `audit_existing_published_surfaces`, `audit_workflow_handoff`, `update_shared_register`, `finalize_sync_strategy`, `confirm_template_boundary`, `no_new_theme_row`, `no_carrier_publication` |
| Primary Theme Owner | `PR-0404` executor |
| PR Executor | `PR-0404` executor |
| Secondary Coverage | `PR-0405`, `PR-0406`, `PR-0407`, `PR-0408`, `PR-0409`, `PR-0410`, `PR-0411`, `PR-0412`, `PR-0413` |
| Out of Scope | publishing or amending `TH-*` rows, publishing new ADR/ruling carriers, reopening PR-0403 replay classification |
| Must Preserve | mainline published surfaces contain only publish-complete rows; parked/deferred/escalated bundles remain in execution-layer artifacts; carrier promotion remains blocked until implementation evidence and governance audit both pass |
| Allowed Simplifications | governance audit may operate on bundle families and governance surfaces instead of forcing every outcome into a theme-row mutation |
| Escalation Required If Violated | any attempt to publish accepted-but-unlanded bundles as current carriers, or to sync parked execution material into mainline registries |
| Accepted Debt | `CPR-001`, `CPR-002` remain `blocked_pending_landing` after audit |
| Output Docs | `theme-delta-contract.md`, `consistency-audit-report.md`, `index-sync-strategy.md`, `template-audit-confirmation.md`, `carrier-promotion-decision-register.md` |
| Verification | `PR-0403` queue/classification/workflow evidence + `architecture_check.dart` |
| Required Sign-off | review leader approval before promoting PR-0404 from `In Progress` to `Ready for Review` |

## Finalized Row-Level Schema

Every PR-0404 theme-delta row must keep the following columns:

| Column | Required | Meaning |
|------|------|------|
| `Line / Bundle ID` | yes | Stable audit target name for the row or bundle family being checked |
| `Operation` | yes | What PR-0404 is doing to that target |
| `Before Status` | yes | State before PR-0404 audit touched it |
| `After Status` | yes | State after PR-0404 audit concluded |
| `Docs Touched` | yes | Audited or updated docs that carry the result |
| `Must Preserve` | yes | Boundary that cannot be silently downgraded while applying the row |
| `Verification` | yes | Evidence surface that makes the row mechanically auditable |
| `Downstream Consumer` | yes | Later PR that must consume the row's result |
| `Notes` | optional | Any clarifying constraint that should stay explicit |

## No Theme Delta Justification

PR-0404 has no publish-time `Theme Delta` against mainline carrier rows.

Reason:

1. PR-0403 already published every current row it was allowed to publish;
2. PR-0404 is auditing those rows and the accepted-but-unlanded handoff families, not creating a new decision line;
3. the only allowed state transitions here are audit-state, register-state, and workflow-consumption state changes.

## PR-0404 Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification | Downstream Consumer | Notes |
|------|------|------|------|------|------|------|------|------|
| `published_registry_consistency_audit` | `audit_existing_published_surfaces` | `published_surface_present` | `audited_no_blocking_registry_drift` | `docs/architecture/adr/topic-map.md`, `docs/architecture/adr/README.md`, `docs/architecture/rulings/README.md`, `PR-0403/README.md` | parked, deferred, and context-only material stays out of mainline published rows | `consistency-audit-report.md` structural + graph checks, `architecture_check.dart` | `PR-0405` | Covers the current published registry only; no carrier mutation is implied |
| `workspace_topology_promotion_audit` | `audit_workflow_handoff + update_shared_register` | `blocked_pending_landing` | `blocked_pending_landing_confirmed` | `workspace-topology-carrier-promotion-workflow.md`, `carrier-promotion-decision-register.md`, `PR-0408` through `PR-0413` specs | no ADR/ruling/topic-map promotion before schema, service, Flutter, and audit coverage all land | `consistency-audit-report.md` semantic review + shared register row `CPR-001` | `PR-0405`, `PR-0408`-`PR-0413` | PR-0404 confirms the block; it does not clear it |
| `ci_duplication_promotion_audit` | `audit_workflow_handoff + update_shared_register` | `blocked_pending_landing` | `blocked_pending_landing_confirmed` | `ci-duplication-policy-promotion-workflow.md`, `carrier-promotion-decision-register.md`, `PR-0407` spec | no current CI-governance sync before detector, allowlist, and output contract are landed | `consistency-audit-report.md` semantic review + shared register row `CPR-002` | `PR-0405`, `PR-0407` | No ADR/ruling publication is expected for this family |
| `index_sync_rule_finalization` | `finalize_sync_strategy` | `scaffold_initialized` | `finalized` | `index-sync-strategy.md`, `theme-delta-contract.md`, `consistency-audit-report.md` | published registries and execution-layer ledgers remain separate surfaces with explicit sync triggers | finalized sync strategy + audit report | `PR-0405`, later governance maintenance | This row defines how later PRs keep mainline and execution artifacts aligned |
| `template_boundary_audit` | `confirm_template_boundary` | `scaffold_initialized` | `finalized` | `template-audit-confirmation.md`, `PR-0406-template-playbook-and-lifecycle-backfill.md` | PR-0406 only extracts sections already validated by PR-0403 and PR-0404, and waits for PR-0405 where required | template audit confirmation + PR-0406 handoff | `PR-0405`, `PR-0406` | This row locks the template/playbook boundary before extraction work starts |

## Result

PR-0404 closes with:

1. zero new or amended mainline theme rows;
2. one finalized governance audit contract for later PRs to consume mechanically;
3. two shared carrier-promotion register rows explicitly audited and still blocked;
4. finalized sync and template-boundary rules for PR-0405 and PR-0406.
