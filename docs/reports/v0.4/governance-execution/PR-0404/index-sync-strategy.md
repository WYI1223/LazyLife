# Index Sync Strategy

- Status: finalized
- Owner: PR-0404
- Last Updated: 2026-03-12

## Purpose

This document defines how governance indices stay aligned after PR-0403 replay and PR-0404 audit.

The goal is to keep:

1. mainline published registries clean;
2. execution-layer carry-forward ledgers explicit;
3. downstream implementation handoff mechanical rather than interpretive.

## Surface Classes

| Surface Class | Source of Truth | Examples | Allowed Content |
|------|------|------|------|
| Mainline published registry | current published architecture docs | `docs/architecture/adr/topic-map.md`, `docs/architecture/adr/README.md`, `docs/architecture/rulings/README.md` | publish-complete rows and current carrier backlinks only |
| Execution replay registry | PR-0403 execution artifacts | `doc-run-queue.md`, `dn-ledger-classification.md`, `open-items.md`, `topic-map-working-copy.md` | completed, parked, deferred, escalated, and context-only replay outcomes |
| Workflow handoff ledger | PR-0403 workflow files | workspace-topology workflow, CI duplication workflow | accepted-but-unlanded bundle coverage and downstream landing evidence |
| Shared promotion decision sink | governance audit / closeout chain | `carrier-promotion-decision-register.md` | audited current decision for each bundle family |
| Release / governance status surface | release and execution indexes | `docs/releases/v0.4/README.md`, `docs/reports/v0.4/governance-execution/README.md`, `docs/releases/v0.4/v0.4-kickoff.md` | PR-level implementation status only |

## Sync Rules

1. Only publish-complete rows may sync from execution artifacts into mainline `topic-map.md`.
2. `parked_later`, `deferred`, `escalate_to_governance`, and `context_only` outcomes stay in execution artifacts and must not appear as published rows.
3. Accepted-but-unlanded bundle families sync into workflow ledgers and the shared register, not into ADR/ruling/topic-map carriers.
4. Downstream implementation PRs update workflow ledgers first; governance PRs update the shared register after audit; closeout PRs decide promotion or carry-forward.
5. Status surfaces (`README`, kickoff, governance index) mirror PR status, not per-document replay states.

## Sync Matrix

| Target Surface | Updated By | Trigger | Blockers |
|------|------|------|------|
| `docs/architecture/adr/topic-map.md` | replay PR or later governance PR | publish-complete row reaches carrier check + sync close | blocked if row is parked, deferred, escalated, or accepted-but-unlanded only |
| `docs/architecture/adr/*.md` | replay PR or later governance PR | real ADR carrier publish or append is justified by classification and carrier checks | blocked for implementation-only bundles |
| `docs/architecture/rulings/*.md` | replay PR or later governance PR | current-effective rule text is justified and landed | blocked for implementation-only bundles |
| `PR-0403` working-copy artifacts | PR-0403 only, then audit references | replay run changes local execution state | frozen as historical execution evidence after PR-0403 merge |
| workflow ledgers | downstream implementation PRs | implementation slice lands or partially lands | blocked if PR omits evidence row update |
| shared register | PR-0404, then PR-0405 | audit or closeout decision changes current bundle-family state | blocked if workflow evidence is absent |
| status surfaces | active PR owner | PR status transitions (`In Progress`, `Ready for Review`, `Merged`) | blocked if spec and execution README disagree |

## No-Sync Rules

The following must never be synchronized into mainline published carrier surfaces directly from implementation PRs:

1. `OI-031` through `OI-050` workspace-topology families;
2. `OI-051` through `OI-053` CI duplication-policy families;
3. any row that exists only as a parked, deferred, escalated, or context-only replay outcome.

## PR-0405 Consumption Rule

PR-0405 consumes:

1. finalized PR-0404 audit outputs;
2. the shared register as the closeout decision sink;
3. workflow ledgers only as evidence sources, not as independent closeout authorities.

## PR-0406 Handoff Rule

PR-0406 extracts stable templates and playbook/lifecycle material only from:

1. finalized PR-0404 contract and audit outputs;
2. finalized PR-0405 activation and closeout results where required.
