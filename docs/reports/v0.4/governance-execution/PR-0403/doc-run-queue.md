# PR-0403 Doc Run Queue

> Single-active-doc queue for `PR-0403`.
> This file is the only run-order fact source for replay work under the per-document model.

## Purpose and Boundaries

This queue controls document selection, disposition, and terminal state.

Boundary rules:

1. only one document may be `active` at a time;
2. `context_only` is terminal and does not require its own `02 -> 08` publish chain;
3. documents do not skip time order because of later governance examples;
4. a later document may not become `active` until the previous active document reaches a terminal state, including any required review sign-off.

## Trigger Conditions

The queue starts from the `PR-0401` inventory order and uses the earliest eligible decision source as the first active run.

## Required Roles

| Role | Responsibility |
|------|----------------|
| PR Executor | Updates queue state before and after each run |
| Review Lead | Confirms terminal-state legitimacy when a run parks or escalates |

## Workflow Overview

1. classify the earliest trigger-only document as `context_only` if it is not itself a publish target;
2. mark the earliest eligible decision source as `active`;
3. move it to `awaiting_signoff` after `02 -> 08` sync closes if review-lead sign-off is still pending;
4. promote it to `completed` only after the sign-off record is complete;
5. then advance the next chronological document to `ready_next`.

## Disposition Vocabulary

| Disposition | Terminal | Meaning |
|------|------|------|
| `ready_next` | No | Earliest eligible document for the next run |
| `active` | No | The only document currently allowed to move through `02 -> 08` |
| `awaiting_signoff` | No | Outputs are synced, but required review-lead sign-off has not yet been recorded |
| `completed` | Yes | Full replay chain closed with publish-complete outputs |
| `parked_later` | Yes | Not blocked forever, but intentionally deferred to a later run |
| `deferred` | Yes | Known non-current or intentionally deferred source |
| `escalate_to_governance` | Yes | Cannot proceed without governance intervention |
| `context_only` | Yes | Consumed as trigger/evidence only, without its own publish path |

## Gates and Sign-off

Queue changes require:

1. executor update in this file;
2. matching status in the relevant iteration or carry-forward record;
3. explicit reason whenever a document lands in a terminal state other than `completed`;
4. a `completed` transition only after review-lead sign-off is recorded when the active contract requires it.

## Run Queue

| Order | Doc ID | Source | Disposition | Reason / Evidence |
|------|------|------|------|------|
| 1 | `DOC-001` | `08a-audit-findings.md` | `context_only` | Consumed as the trigger/evidence source for `DOC-002`; does not itself justify a publish-complete ADR/ruling pair |
| 2 | `DOC-002` | `08b-semantic-decisions.md` | `completed` | Review-lead sign-off recorded in `iterations/DOC-002-08b-semantic-decisions/review-lead-signoff.md`; first published replay run is now closed |
| 3 | `DOC-003` | `08c-solution-proposals.md` | `completed` | Review-lead sign-off recorded in `iterations/DOC-003-08c-solution-proposals/review-lead-signoff.md`; append-only replay run is now closed |
| 4 | `DOC-004` | `08d-pr-replanning.md` | `completed` | Review-lead sign-off recorded in `iterations/DOC-004-08d-pr-replanning/review-lead-signoff.md`; append-only replay run is now closed |
| 5 | `DOC-005` | `09-acceptance-report.md` | `completed` | Review-lead sign-off recorded in `iterations/DOC-005-09-acceptance-report/review-lead-signoff.md`; append-only closure/handoff replay run is now closed |
| 6 | `DOC-006` | `PR-RB-00-doc-fixes.md` | `parked_later` | Review-lead sign-off is recorded in `iterations/DOC-006-pr-rb-00-doc-fixes/review-lead-signoff.md`; the run closes as an intentional no-publication governance-seed replay with four parked carry-forward bundles |
| 7 | `DOC-007` | `v0.3-release-evidence.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-007-v0-3-release-evidence/review-lead-signoff.md`; the append-only release-evidence replay is now closed |
| 8 | `DOC-008` | `DI-0-dual-tab-manager.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-008-di-0-dual-tab-manager/review-lead-signoff.md`; the DI-0 clarification replay is now fully closed |
| 9 | `DOC-009` | `DI-1-editor-shell-service.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-009-di-1-editor-shell-service/review-lead-signoff.md`; the mixed append + publish replay that updated `TH-001`, `TH-008`, and rebuilt `TH-011 / S9` is now closed |
| 10 | `DOC-010` | `DI-2-layout-tree-structure.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-010-di-2-layout-tree-structure/review-lead-signoff.md`; the new `TH-012 / ADR-0010 / S10` publication is now fully closed |
| 11 | `DOC-011` | `DI-3-layout-persistence.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-011-di-3-layout-persistence/review-lead-signoff.md`; the append-only DI-3 replay into `TH-012 / ADR-0010 / S10` is now fully closed |
| 12 | `DOC-012` | `DI-4-buffer-sync-model.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-012-di-4-buffer-sync-model/review-lead-signoff.md`; the DI-4 append replay into `TH-008 / ADR-0002 / S2` and `TH-012 / ADR-0010 / S10` is now fully closed |
| 13 | `DOC-013` | `DI-5-cursor-and-conflict.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-013-di-5-cursor-and-conflict/review-lead-signoff.md`; the DI-5 confirmatory append into `TH-008` is now fully closed |
| 14 | `DOC-014` | `DI-6-cross-track-dependencies.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-014-di-6-cross-track-dependencies/review-lead-signoff.md`; the append-only DI-6 replay into `TH-012 / ADR-0010 / S10` is now fully closed |
| 15 | `DOC-015` | `DI-7-gates-perf-testing.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-015-di-7-gates-perf-testing/review-lead-signoff.md`; the append-only DI-7 replay into `TH-012 / ADR-0010 / S10` is now fully closed |
| 16 | `DOC-016` | `DI-8-spi-verification.md` | `deferred` | Review-lead sign-off is recorded in `iterations/DOC-016-di-8-spi-verification/review-lead-signoff.md`; the run closes as an explicit no-publication deferred replay that preserves the SPI-verification question surface without fabricating a local provider-SPI closure |
| 17 | `DOC-017` | `DI-9 (missing slot)` | `deferred` | Explicit missing-slot record from `PR-0401` inventory; no source file exists, so no replay run can start for this position |
| 18 | `DOC-018` | `DI-10-editor-resolver-shell.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-018-di-10-editor-resolver-shell/review-lead-signoff.md`; the dual append replay into `TH-008` and `TH-011` is now fully closed |
| 19 | `DOC-019` | `DI-11-atomtype-rename-impact.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-019-di-11-atomtype-rename-impact/review-lead-signoff.md`; the `TH-001` naming-convergence append is now fully closed while the accepted-but-unlanded atom-first and Pending bundles remain explicitly parked |
| 20 | `DOC-020` | `DI-12-workspace-tree-single-root.md` | `parked_later` | Review-lead sign-off is recorded in `iterations/DOC-020-di-12-workspace-tree-single-root/review-lead-signoff.md`; the run closes as an explicit no-publication conceptual-parent replay, and the accepted-but-unlanded single-root workspace-topology bundle remains visible for later topology replay and audit work |
| 21 | `DOC-021` | `DI-13-calendar-range-limit-policy.md` | `escalate_to_governance` | Review-lead sign-off is recorded in `iterations/DOC-021-di-13-calendar-range-limit-policy/review-lead-signoff.md`; the run closes as an explicit no-publication governance-escalation replay that keeps the pending Calendar range-limit policy bundle visible rather than mispublishing it |
| 22 | `DOC-022` | `DI-14-workspace-tree-core-promotion.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-022-di-14-workspace-tree-core-promotion/review-lead-signoff.md`; the `TH-011 / ADR-0009 / S9` append run is now fully closed |
| 23 | `DOC-023` | `DI-15-rust-data-model-single-root.md` | `parked_later` | Review-lead sign-off is recorded in `iterations/DOC-023-di-15-rust-data-model-single-root/review-lead-signoff.md`; the run closes as an explicit no-publication topology replay that keeps superseded-history, accepted-but-unlanded multi-root model, migration/protection, and security bundles visible without premature carrier publication |
| 24 | `DOC-024` | `DI-16-rust-service-ffi-contract.md` | `parked_later` | Review-lead sign-off is recorded in `iterations/DOC-024-di-16-rust-service-ffi-contract/review-lead-signoff.md`; the run closes as an explicit no-publication service/FFI replay with five accepted-but-unlanded implementation bundles synchronized into later workflow and audit surfaces |
| 25 | `DOC-025` | `DI-17-flutter-thin-client.md` | `parked_later` | Review-lead sign-off is recorded in `iterations/DOC-025-di-17-flutter-thin-client/review-lead-signoff.md`; the run closes as an explicit no-publication Flutter thin-client replay with six accepted-but-unlanded implementation bundles synchronized into later implementation and audit surfaces |
| 26 | `DOC-026` | `DI-18-execution-plan.md` | `parked_later` | Review-lead sign-off is recorded in `iterations/DOC-026-di-18-execution-plan/review-lead-signoff.md`; the run closes as an explicit no-publication execution-plan replay with six accepted-but-unlanded downstream execution bundles synchronized into workflow and later PR specs |
| 27 | `DOC-027` | `DI-19-adr-governance.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-027-di-19-adr-governance/review-lead-signoff.md`; the governance-doc sync run is now fully closed without creating a separate governance carrier |
| 28 | `DOC-028` | `DI-20-governance-execution-plan.md` | `completed` | Review-lead sign-off is recorded in `iterations/DOC-028-di-20-governance-execution-plan/review-lead-signoff.md`; the governance-spec sync run is now fully closed without creating a separate governance ADR/ruling carrier |
| 29 | `DOC-029` | `DI-21-ci-duplication-detection.md` | `parked_later` | Review-lead sign-off is recorded in `iterations/DOC-029-di-21-ci-duplication-detection/review-lead-signoff.md`; the run closes as an explicit no-publication CI-governance replay with downstream handoff synchronized into `PR-0407` |

## Allowed Exceptions

1. `parked_later` may be used for queue-sequencing holds as long as the reason is explicit.
2. `deferred` should be used only when the source itself is non-current or intentionally out of scope.
3. `escalate_to_governance` is reserved for unresolved carrier or theme-boundary disputes.

## Reference Documents

- [`../PR-0401/document-inventory.md`](../PR-0401/document-inventory.md)
- [`README.md`](README.md)
- [`iterations/DOC-002-08b-semantic-decisions/review-lead-signoff.md`](iterations/DOC-002-08b-semantic-decisions/review-lead-signoff.md)
- [`iterations/DOC-006-pr-rb-00-doc-fixes/review-lead-signoff.md`](iterations/DOC-006-pr-rb-00-doc-fixes/review-lead-signoff.md)
- [`iterations/DOC-007-v0-3-release-evidence/review-lead-signoff.md`](iterations/DOC-007-v0-3-release-evidence/review-lead-signoff.md)
- [`iterations/DOC-008-di-0-dual-tab-manager/review-lead-signoff.md`](iterations/DOC-008-di-0-dual-tab-manager/review-lead-signoff.md)
- [`iterations/DOC-009-di-1-editor-shell-service/review-lead-signoff.md`](iterations/DOC-009-di-1-editor-shell-service/review-lead-signoff.md)
- [`iterations/DOC-010-di-2-layout-tree-structure/review-lead-signoff.md`](iterations/DOC-010-di-2-layout-tree-structure/review-lead-signoff.md)
- [`iterations/DOC-011-di-3-layout-persistence/review-lead-signoff.md`](iterations/DOC-011-di-3-layout-persistence/review-lead-signoff.md)
- [`iterations/DOC-012-di-4-buffer-sync-model/review-lead-signoff.md`](iterations/DOC-012-di-4-buffer-sync-model/review-lead-signoff.md)
- [`iterations/DOC-013-di-5-cursor-and-conflict/review-lead-signoff.md`](iterations/DOC-013-di-5-cursor-and-conflict/review-lead-signoff.md)
- [`iterations/DOC-014-di-6-cross-track-dependencies/review-lead-signoff.md`](iterations/DOC-014-di-6-cross-track-dependencies/review-lead-signoff.md)
- [`iterations/DOC-015-di-7-gates-perf-testing/review-lead-signoff.md`](iterations/DOC-015-di-7-gates-perf-testing/review-lead-signoff.md)
- [`iterations/DOC-016-di-8-spi-verification/review-lead-signoff.md`](iterations/DOC-016-di-8-spi-verification/review-lead-signoff.md)
- [`iterations/DOC-018-di-10-editor-resolver-shell/review-lead-signoff.md`](iterations/DOC-018-di-10-editor-resolver-shell/review-lead-signoff.md)
- [`iterations/DOC-019-di-11-atomtype-rename-impact/review-lead-signoff.md`](iterations/DOC-019-di-11-atomtype-rename-impact/review-lead-signoff.md)
- [`iterations/DOC-020-di-12-workspace-tree-single-root/review-lead-signoff.md`](iterations/DOC-020-di-12-workspace-tree-single-root/review-lead-signoff.md)
- [`iterations/DOC-021-di-13-calendar-range-limit-policy/review-lead-signoff.md`](iterations/DOC-021-di-13-calendar-range-limit-policy/review-lead-signoff.md)
- [`iterations/DOC-022-di-14-workspace-tree-core-promotion/review-lead-signoff.md`](iterations/DOC-022-di-14-workspace-tree-core-promotion/review-lead-signoff.md)
- [`iterations/DOC-023-di-15-rust-data-model-single-root/review-lead-signoff.md`](iterations/DOC-023-di-15-rust-data-model-single-root/review-lead-signoff.md)
- [`iterations/DOC-024-di-16-rust-service-ffi-contract/review-lead-signoff.md`](iterations/DOC-024-di-16-rust-service-ffi-contract/review-lead-signoff.md)
- [`iterations/DOC-025-di-17-flutter-thin-client/review-lead-signoff.md`](iterations/DOC-025-di-17-flutter-thin-client/review-lead-signoff.md)
- [`iterations/DOC-026-di-18-execution-plan/review-lead-signoff.md`](iterations/DOC-026-di-18-execution-plan/review-lead-signoff.md)
- [`iterations/DOC-027-di-19-adr-governance/review-lead-signoff.md`](iterations/DOC-027-di-19-adr-governance/review-lead-signoff.md)
- [`iterations/DOC-028-di-20-governance-execution-plan/review-lead-signoff.md`](iterations/DOC-028-di-20-governance-execution-plan/review-lead-signoff.md)
- [`iterations/DOC-029-di-21-ci-duplication-detection/review-lead-signoff.md`](iterations/DOC-029-di-21-ci-duplication-detection/review-lead-signoff.md)
