# PR-0403 Iterations Index

> Playbook-style index for per-document replay runs.

## Purpose and Boundaries

Each iteration folder records one document group's `02 -> 08` replay chain.

Boundary rules:

1. one folder equals one `DOC-xxx` run;
2. each stage file records a real gate or decision, not a placeholder;
3. later documents do not write into earlier iteration folders.

## Workflow Overview

Expected stage order per active document:

1. `02-historical-semantic-freeze.md`
2. `03-retrospective-override-review.md`
3. `04-impact-cone-review.md`
4. `05-dn-classification-to-decision-line.md`
5. `06-adr-carrier-check.md`
6. `07-adr-create-append.md`
7. `08-ruling-update-and-sync.md`

## Required Artifacts

| Iteration | Source | State | Notes |
|------|------|------|------|
| `DOC-002-08b-semantic-decisions/` | `DOC-002 / 08b` | complete | First full publish-complete run in `PR-0403`; review-lead sign-off is recorded |
| `DOC-003-08c-solution-proposals/` | `DOC-003 / 08c` | complete | `02 -> 08` complete; append-only ADR updates landed and review-lead sign-off is recorded |
| `DOC-004-08d-pr-replanning/` | `DOC-004 / 08d` | complete | `02 -> 08` complete; append-only ADR update closed and review-lead sign-off is recorded |
| `DOC-005-09-acceptance-report/` | `DOC-005 / 09` | complete | `02 -> 08` complete; eight append-only ADR updates are closed and review-lead sign-off is recorded |
| `DOC-006-pr-rb-00-doc-fixes/` | `DOC-006 / PR-RB-00` | complete | `02 -> 08` complete; no-publication governance/provenance run is now terminal `parked_later` with recorded review-lead sign-off |
| `DOC-007-v0-3-release-evidence/` | `DOC-007 / v0.3 release evidence` | complete | `02 -> 08` complete; append-only release-evidence replay is closed with recorded review-lead sign-off |
| `DOC-008-di-0-dual-tab-manager/` | `DOC-008 / DI-0` | complete | `02 -> 08` complete; DI-0 clarification is appended into the published shell-ownership ADR carrier, PR-spec traceability remains explicit as `context_only`, and review-lead sign-off is recorded |
| `DOC-009-di-1-editor-shell-service/` | `DOC-009 / DI-1` | complete | `02 -> 08` complete; DI-1 appended shell-detail and title-semantics evidence, rebuilt the current-effective S9 placement line, and review-lead sign-off is recorded |
| `DOC-010-di-2-layout-tree-structure/` | `DOC-010 / DI-2` | complete | `02 -> 08` complete; DI-2 published the first layout-tree ADR/ruling pair and review-lead sign-off is recorded |
| `DOC-011-di-3-layout-persistence/` | `DOC-011 / DI-3` | complete | `02 -> 08` complete; DI-3 appended persistence, one-shot replacement, pane-cap, and staged-restore-boundary detail into the published `TH-012 / ADR-0010 / S10` line and review-lead sign-off is recorded |
| `DOC-012-di-4-buffer-sync-model/` | `DOC-012 / DI-4` | complete | `02 -> 08` complete; DI-4 appended shell-buffer detail into the published `TH-008 / ADR-0002 / S2` line, appended stage-2 loading detail into `TH-012 / ADR-0010 / S10`, and review-lead sign-off is recorded |
| `DOC-013-di-5-cursor-and-conflict/` | `DOC-013 / DI-5` | complete | `02 -> 08` complete; DI-5 appended confirmatory cursor/conflict detail into the published `TH-008 / ADR-0002 / S2` line and review-lead sign-off is recorded |
| `DOC-014-di-6-cross-track-dependencies/` | `DOC-014 / DI-6` | complete | `02 -> 08` complete; DI-6 appended failed-track diagnosis plus gate/dependency framing into the published `TH-012 / ADR-0010 / S10` line and recorded review-lead sign-off |
| `DOC-015-di-7-gates-perf-testing/` | `DOC-015 / DI-7` | complete | `02 -> 08` complete; DI-7 appended line-specific Gate B precision, benchmark-definition, SLA/verification semantics, and the no-benchmark-CI decision into the published `TH-012 / ADR-0010 / S10` line, while the broader gate/test policy bundle remains explicitly parked and review-lead sign-off is recorded |
| `DOC-016-di-8-spi-verification/` | `DOC-016 / DI-8` | complete | `02 -> 08` complete; DI-8 is closed as terminal `deferred` after review-lead sign-off accepted the no-publication SPI-verification outcome |
| `DOC-018-di-10-editor-resolver-shell/` | `DOC-018 / DI-10` | complete | `02 -> 08` complete; DI-10 appended resolver-shell detail into `TH-008`, appended editor-resolver placement detail into `TH-011`, preserved the future `View Mode` edge explicitly, and review-lead sign-off is now recorded |
| `DOC-019-di-11-atomtype-rename-impact/` | `DOC-019 / DI-11` | complete | `02 -> 08` complete; DI-11 appended the resolved `ViewHint` naming-convergence line into `TH-001`, kept the accepted-but-unlanded `atom_create` contract and the parked Pending-semantics bundle explicit, and review-lead sign-off is now recorded |
| `DOC-020-di-12-workspace-tree-single-root/` | `DOC-020 / DI-12` | complete | `02 -> 08` complete; DI-12 is now terminal `parked_later` after review-lead sign-off accepted the no-publication conceptual-parent outcome |
| `DOC-021-di-13-calendar-range-limit-policy/` | `DOC-021 / DI-13` | complete | `02 -> 08` complete; DI-13 is now terminal `escalate_to_governance` after review-lead sign-off accepted the no-publication governance-escalation outcome |
| `DOC-022-di-14-workspace-tree-core-promotion/` | `DOC-022 / DI-14` | complete | `02 -> 08` complete; DI-14 appended workspace-tree core-promotion and shared query-surface detail into `TH-011 / ADR-0009 / S9`, kept the migrated `DI-17` follow-up boundary explicit, and review-lead sign-off is now recorded |
| `DOC-023-di-15-rust-data-model-single-root/` | `DOC-023 / DI-15` | complete | `02 -> 08` complete; DI-15 preserved the architecture pivot trace, the superseded single-root history bundle, the accepted-but-unlanded active multi-root data-model and migration bundles, and the explicit security-model bundle without publishing a premature current workspace-topology carrier; review-lead sign-off is now recorded |
| `DOC-024-di-16-rust-service-ffi-contract/` | `DOC-024 / DI-16` | complete | `02 -> 08` complete; DI-16 preserved the accepted-but-unlanded scoped-query, tree-navigation, creation/tree-service, access-guard, and FFI-surface bundles without publishing a premature current service/FFI carrier, and review-lead sign-off is now recorded |
| `DOC-025-di-17-flutter-thin-client/` | `DOC-025 / DI-17` | complete | `02 -> 08` complete; DI-17 preserved the accepted-but-unlanded WorkspaceTreeService B+ shape, mutation-delta, tree-UI-layering, system-node-resolution, controller-adaptation, and synthetic-removal bundles without publishing premature current Flutter carrier text, and review-lead sign-off is now recorded |
| `DOC-026-di-18-execution-plan/` | `DOC-026 / DI-18` | complete | `02 -> 08` complete; DI-18 is now terminal `parked_later` after review-lead sign-off accepted the explicit no-publication execution-plan outcome and downstream-spec handoff sync |
| `DOC-027-di-19-adr-governance/` | `DOC-027 / DI-19` | complete | `02 -> 08` complete; DI-19 synchronized the current-effective governance model, ADR admission gate, and SSOT boundary into already-landed governance docs without creating a separate governance ADR/ruling carrier, and review-lead sign-off is now recorded |
| `DOC-028-di-20-governance-execution-plan/` | `DOC-028 / DI-20` | complete | `02 -> 08` complete; DI-20 synchronized the landed governance execution rules, Theme Delta / gate-stack shape, and template/activation boundary into already-landed governance specs without creating a separate governance ADR/ruling carrier, and review-lead sign-off is now recorded |
| `DOC-029-di-21-ci-duplication-detection/` | `DOC-029 / DI-21` | complete | `02 -> 08` complete; DI-21 preserved the accepted-but-unlanded Rule E extension, detector contract, and CI output-contract bundles, synchronized the downstream handoff into `PR-0407`, and review-lead sign-off is now recorded so the run is terminal `parked_later` |

## Gates and Sign-off

An iteration is considered complete only when:

1. `02 -> 08` all exist;
2. `06` has a terminal carrier decision;
3. `07` and `08` match the published ADR / ruling outputs and topic-map sync;
4. any required review-lead sign-off record is present and approved.

## Reference Documents

- [`../doc-run-queue.md`](../doc-run-queue.md)
- [`../README.md`](../README.md)
- [`DOC-002-08b-semantic-decisions/review-lead-signoff.md`](DOC-002-08b-semantic-decisions/review-lead-signoff.md)
- [`DOC-003-08c-solution-proposals/review-lead-signoff.md`](DOC-003-08c-solution-proposals/review-lead-signoff.md)
- [`DOC-004-08d-pr-replanning/review-lead-signoff.md`](DOC-004-08d-pr-replanning/review-lead-signoff.md)
- [`DOC-005-09-acceptance-report/review-lead-signoff.md`](DOC-005-09-acceptance-report/review-lead-signoff.md)
- [`DOC-006-pr-rb-00-doc-fixes/review-lead-signoff.md`](DOC-006-pr-rb-00-doc-fixes/review-lead-signoff.md)
- [`DOC-007-v0-3-release-evidence/review-lead-signoff.md`](DOC-007-v0-3-release-evidence/review-lead-signoff.md)
- [`DOC-008-di-0-dual-tab-manager/review-lead-signoff.md`](DOC-008-di-0-dual-tab-manager/review-lead-signoff.md)
- [`DOC-009-di-1-editor-shell-service/review-lead-signoff.md`](DOC-009-di-1-editor-shell-service/review-lead-signoff.md)
- [`DOC-010-di-2-layout-tree-structure/review-lead-signoff.md`](DOC-010-di-2-layout-tree-structure/review-lead-signoff.md)
- [`DOC-011-di-3-layout-persistence/review-lead-signoff.md`](DOC-011-di-3-layout-persistence/review-lead-signoff.md)
- [`DOC-012-di-4-buffer-sync-model/review-lead-signoff.md`](DOC-012-di-4-buffer-sync-model/review-lead-signoff.md)
- [`DOC-013-di-5-cursor-and-conflict/review-lead-signoff.md`](DOC-013-di-5-cursor-and-conflict/review-lead-signoff.md)
- [`DOC-014-di-6-cross-track-dependencies/review-lead-signoff.md`](DOC-014-di-6-cross-track-dependencies/review-lead-signoff.md)
- [`DOC-015-di-7-gates-perf-testing/review-lead-signoff.md`](DOC-015-di-7-gates-perf-testing/review-lead-signoff.md)
- [`DOC-016-di-8-spi-verification/review-lead-signoff.md`](DOC-016-di-8-spi-verification/review-lead-signoff.md)
- [`DOC-018-di-10-editor-resolver-shell/review-lead-signoff.md`](DOC-018-di-10-editor-resolver-shell/review-lead-signoff.md)
- [`DOC-019-di-11-atomtype-rename-impact/review-lead-signoff.md`](DOC-019-di-11-atomtype-rename-impact/review-lead-signoff.md)
- [`DOC-020-di-12-workspace-tree-single-root/review-lead-signoff.md`](DOC-020-di-12-workspace-tree-single-root/review-lead-signoff.md)
- [`DOC-021-di-13-calendar-range-limit-policy/review-lead-signoff.md`](DOC-021-di-13-calendar-range-limit-policy/review-lead-signoff.md)
- [`DOC-022-di-14-workspace-tree-core-promotion/review-lead-signoff.md`](DOC-022-di-14-workspace-tree-core-promotion/review-lead-signoff.md)
- [`DOC-023-di-15-rust-data-model-single-root/review-lead-signoff.md`](DOC-023-di-15-rust-data-model-single-root/review-lead-signoff.md)
- [`DOC-024-di-16-rust-service-ffi-contract/review-lead-signoff.md`](DOC-024-di-16-rust-service-ffi-contract/review-lead-signoff.md)
- [`DOC-025-di-17-flutter-thin-client/review-lead-signoff.md`](DOC-025-di-17-flutter-thin-client/review-lead-signoff.md)
- [`DOC-026-di-18-execution-plan/review-lead-signoff.md`](DOC-026-di-18-execution-plan/review-lead-signoff.md)
- [`DOC-027-di-19-adr-governance/review-lead-signoff.md`](DOC-027-di-19-adr-governance/review-lead-signoff.md)
- [`DOC-028-di-20-governance-execution-plan/review-lead-signoff.md`](DOC-028-di-20-governance-execution-plan/review-lead-signoff.md)
- [`DOC-029-di-21-ci-duplication-detection/review-lead-signoff.md`](DOC-029-di-21-ci-duplication-detection/review-lead-signoff.md)
