# Workspace Topology Carrier Promotion Workflow

- Owner: `PR-0403` replay output, consumed by `PR-0408` through `PR-0413`
- Status: active handoff contract
- Last Updated: 2026-03-12

## Purpose and Boundary

This document solves one specific handoff problem:

`DOC-023 / DI-15` resolved the multi-root workspace direction semantically, but `PR-0403` intentionally did not publish new ADR, ruling, or topic-map rows because the corresponding repo implementation is not landed yet.

This workflow tells the workspace implementation chain:

1. what `DI-15` bundle is already accepted;
2. what each workspace PR must update while landing it;
3. when mainline carrier publication is finally allowed.

This workflow must not be used to:

1. bypass `PR-0403` replay records;
2. silently publish current carrier text from implementation PRs without governance review;
3. hide partial landings by treating them as "close enough" to current-effective.

## Current Replay Decision

`DOC-023 / DI-15` ended with explicit no-publication handling:

| Bundle | Source | Current Replay Status | Carry-Forward ID |
|------|------|------|------|
| Superseded single-root history | `DN-368-DN-377` | `parked_later historical bundle` | `OI-030` |
| Active multi-root workspace model | `DN-378-DN-384` | `accepted-but-unlanded` | `OI-031` |
| Active multi-root migration and protection | `DN-385-DN-390` | `accepted-but-unlanded` | `OI-032` |
| Cross-workspace security model | `DN-391-DN-395` | `accepted-but-unlanded security bundle` | `OI-033` |

Authoritative references:

- [`iterations/DOC-023-di-15-rust-data-model-single-root/05-dn-classification-to-decision-line.md`](iterations/DOC-023-di-15-rust-data-model-single-root/05-dn-classification-to-decision-line.md)
- [`open-items.md`](open-items.md)
- [`dn-ledger-classification.md`](dn-ledger-classification.md)

## Supporting Replay Inputs From DOC-024

`DOC-024 / DI-16` did not publish current carriers either, but it did convert the service-and-FFI side of the workspace-topology lineage into implementation-facing bundles that later PRs must consume explicitly.

| Bundle | Source | Current Replay Status | Carry-Forward ID | Primary Slice IDs |
|------|------|------|------|------|
| Scoped query stack | `DN-411-DN-429` | `accepted-but-unlanded` | `OI-034` | `scoped-query` |
| Tree navigation | `DN-430-DN-434` | `accepted-but-unlanded` | `OI-035` | `service-routing`, `flutter-core`, `flutter-features` |
| Unified creation and TreeService evolution | `DN-435-DN-443` | `accepted-but-unlanded` | `OI-036` | `service-routing`, `flutter-core`, `flutter-features` |
| AccessGuard and origin read-path | `DN-444-DN-448` | `accepted-but-unlanded` | `OI-037` | `guarded-ffi`, `security-surface` |
| FFI surface and migration bridge | `DN-449-DN-457` | `accepted-but-unlanded` | `OI-038` | `guarded-ffi`, `flutter-core`, `flutter-features` |

Authoritative references:

- [`iterations/DOC-024-di-16-rust-service-ffi-contract/05-dn-classification-to-decision-line.md`](iterations/DOC-024-di-16-rust-service-ffi-contract/05-dn-classification-to-decision-line.md)
- [`open-items.md`](open-items.md)
- [`dn-ledger-classification.md`](dn-ledger-classification.md)

## Supporting Replay Inputs From DOC-025

`DOC-025 / DI-17` also did not publish current carriers, but it converted the Flutter thin-client side of the workspace-topology lineage into implementation-facing bundles that later PRs must consume explicitly.

| Bundle | Source | Current Replay Status | Carry-Forward ID | Primary Slice IDs |
|------|------|------|------|------|
| WorkspaceTreeService B+ shape, no-cache rule, and feature-side cache boundary | `DN-461-DN-465` | `accepted-but-unlanded` | `OI-039` | `flutter-core` |
| TreeMutationDelta and targeted-reload contract | `DN-466-DN-470` | `accepted-but-unlanded` | `OI-040` | `flutter-core`, `flutter-features` |
| Tree UI layering, extraction trigger, and Rule E boundary | `DN-471-DN-476` | `accepted-but-unlanded` | `OI-041` | `flutter-features` |
| System-node resolution ownership and synchronous consumer access | `DN-477-DN-484` | `accepted-but-unlanded` | `OI-042` | `flutter-core`, `flutter-features` |
| Tasks/Calendar controller adaptation and query-helper migration | `DN-485-DN-494` | `accepted-but-unlanded` | `OI-043` | `flutter-features` |
| Synthetic uncategorized removal and legacy-path cleanup | `DN-495-DN-500` | `accepted-but-unlanded` | `OI-044` | `flutter-features` |

Authoritative references:

- [`iterations/DOC-025-di-17-flutter-thin-client/05-dn-classification-to-decision-line.md`](iterations/DOC-025-di-17-flutter-thin-client/05-dn-classification-to-decision-line.md)
- [`open-items.md`](open-items.md)
- [`dn-ledger-classification.md`](dn-ledger-classification.md)

## Supporting Replay Inputs From DOC-026

`DOC-026 / DI-18` also did not publish current carriers, but it converted the workspace implementation chain's execution-plan, cleanup, documentation-ownership, and verification obligations into explicit bundles that later PRs must consume directly.

These bundles are not future ADR or ruling candidates. They are execution and audit obligations that later PRs must cite and update.

| Bundle | Source | Current Replay Status | Carry-Forward ID | Primary Slice IDs |
|------|------|------|------|------|
| Execution sequencing and dependency order | `DN-504-DN-509` | `accepted-but-unlanded execution bundle` | `OI-045` | `execution-order` |
| Expand-contract cutover and strict cleanup rules | `DN-511-DN-514` | `accepted-but-unlanded execution bundle` | `OI-046` | `cutover-cleanup` |
| API-doc ownership and ADR replay ownership split | `DN-516-DN-518` | `accepted-but-unlanded execution bundle` | `OI-047` | `api-doc-ownership` |
| Per-PR test matrix and cleanup verification | `DN-520-DN-526` | `accepted-but-unlanded execution bundle` | `OI-048` | `verification-gates` |
| No-move rule and `DI-21` CI extraction handoff | `DN-528-DN-530` | `accepted-but-unlanded execution bundle` | `OI-049` | `no-move-ci-enforcement` |
| Legacy FFI removal inventory | `DN-531` | `accepted-but-unlanded execution bundle` | `OI-050` | `legacy-ffi-removal` |

Authoritative references:

- [`iterations/DOC-026-di-18-execution-plan/05-dn-classification-to-decision-line.md`](iterations/DOC-026-di-18-execution-plan/05-dn-classification-to-decision-line.md)
- [`open-items.md`](open-items.md)
- [`dn-ledger-classification.md`](dn-ledger-classification.md)

## Rule for PR-0408 through PR-0413

`PR-0408` through `PR-0413` may land implementation slices of `DI-15`, but they must not directly publish or amend:

1. `docs/architecture/adr/*.md`
2. `docs/architecture/rulings/*.md`
3. mainline [`topic-map.md`](../../../../architecture/adr/topic-map.md)

unless the promotion gate in this document is fully satisfied.

Until then, these PRs must treat `DI-15` as:

- `accepted direction`
- `implementation in progress`
- `not yet current-effective carrier text`

They must also treat the `DOC-024 / DI-16` bundles listed above as:

- `accepted service-and-ffi contract direction`
- `implementation slices to land and report against`
- `not yet current-effective carrier text`

They must also treat the `DOC-025 / DI-17` bundles listed above as:

- `accepted Flutter thin-client landing direction`
- `implementation slices to land and report against`
- `not yet current-effective carrier text`

They must also treat the `DOC-026 / DI-18` bundles listed above as:

- `accepted execution and verification obligations`
- `required workflow and spec updates during landing`
- `not future ADR or ruling publication candidates from this source`

## Required Update Workflow

Every PR from `PR-0408` through `PR-0413` must do all three:

1. land its assigned implementation slice;
2. update the coverage ledger in this document;
3. reference the exact updated row in its PR spec or execution notes.

If a PR also consumes one of the `DOC-024 / DI-16` supporting bundles, it must explicitly cite the relevant `OI-034` through `OI-038` ID in its spec or execution notes.

If a PR also consumes one of the `DOC-025 / DI-17` supporting bundles, it must explicitly cite the relevant `OI-039` through `OI-044` ID in its spec or execution notes.

If a PR also consumes one of the `DOC-026 / DI-18` supporting bundles, it must explicitly cite the relevant `OI-045` through `OI-050` ID in its spec or execution notes.

If a PR lands code but does not update this ledger, the handoff is incomplete.

## Landing Coverage Ledger

| PR | Landing Surface | Carry-Forward Inputs | Required Update In This File | Carrier Effect |
|------|------|------|------|------|
| `PR-0408` | schema migration `0012`, `workspaces`, `designated_folders`, `origin_workspace_id`, DB protection triggers | `OI-031`, `OI-032`, `OI-045`, `OI-048` | mark schema, migration, execution-order, and verification coverage as landed or partial, with evidence path | no carrier publication |
| `PR-0409` | scoped query repository and subtree-query semantics | `OI-031`, `OI-034`, `OI-045`, `OI-048` | mark query, execution-order, and verification coverage as landed or partial, with evidence path | no carrier publication |
| `PR-0410` | TreeService, CreationService, reassign flow, origin write-path, protection rules | `OI-031`, `OI-032`, `OI-035`, `OI-036`, `OI-045`, `OI-048` | mark service, migration-protection, execution-order, and verification coverage as landed or partial, with evidence path | no carrier publication |
| `PR-0411` | guarded FFI surface and workspace-facing exported contracts | `OI-031`, `OI-032`, `OI-033`, `OI-037`, `OI-038`, `OI-045`, `OI-046`, `OI-047`, `OI-048` | mark FFI, guard, execution-order, cutover-cleanup, doc-ownership, and verification coverage as landed or partial, with evidence path | no carrier publication |
| `PR-0412` | Flutter core adoption of workspace and designated-folder model, WorkspaceTreeService shape, mutation-delta ownership, and system-node resolution | `OI-031`, `OI-035`, `OI-036`, `OI-038`, `OI-039`, `OI-040`, `OI-042`, `OI-045`, `OI-048` | mark core-consumer, execution-order, and verification coverage as landed or partial, with evidence path | no carrier publication |
| `PR-0413` | Flutter feature adoption, tree UI layering, controller migration, and legacy-path removal | `OI-031`, `OI-035`, `OI-036`, `OI-038`, `OI-040`, `OI-041`, `OI-042`, `OI-043`, `OI-044`, `OI-045`, `OI-046`, `OI-047`, `OI-048`, `OI-049`, `OI-050` | mark feature-consumer, execution-order, cutover-cleanup, doc-ownership, verification, no-move, and legacy-removal coverage as landed or partial, with evidence path | no carrier publication |

## Coverage Ledger Template

Each PR updates the relevant row(s) using this format:

| Slice ID | Owned By | Status | Evidence | Notes |
|------|------|------|------|------|
| `schema-model` | `PR-0408` | `pending` | `pending` | `workspaces`, `designated_folders`, `origin_workspace_id` not yet landed |
| `migration-protection` | `PR-0408`, `PR-0410` | `pending` | `pending` | migration flow plus runtime/service protection model |
| `scoped-query` | `PR-0409` | `pending` | `pending` | subtree-rooted queries and designated-folder-scoped reads |
| `service-routing` | `PR-0410` | `pending` | `pending` | creation routing, reassign, move/delete protection, origin write-path |
| `guarded-ffi` | `PR-0411` | `pending` | `pending` | guarded exported contracts and origin-aware access surface |
| `flutter-core` | `PR-0412` | `pending` | `pending` | core tree service, designated-folder consumption, WorkspaceTreeService B+ shape, mutation-delta ownership, and system-node resolution |
| `flutter-features` | `PR-0413` | `pending` | `pending` | feature adoption, targeted reload consumption, tree UI layering, controller migration, synthetic removal, and end-to-end workspace consumers |
| `security-surface` | `PR-0411` and later security work | `pending` | `pending` | only mark landed if actual origin-based gate or explicit security-stage work is implemented |
| `execution-order` | `PR-0408` through `PR-0413` | `pending` | `pending` | DI-18 sequencing and dependency-order obligations stay explicit until each implementation PR records compliant landing evidence |
| `cutover-cleanup` | `PR-0411` and `PR-0413` | `pending` | `pending` | expand-contract bridge plus strict cleanup rules and contract-stage deletion |
| `api-doc-ownership` | `PR-0411`, `PR-0413`, and governance audit | `pending` | `pending` | ownership of `ffi-contracts.md`, `API_COMPATIBILITY.md`, `error-codes.md`, and retrospective ADR replay boundaries |
| `verification-gates` | `PR-0408` through `PR-0413` | `pending` | `pending` | per-PR migration, service, FFI, Flutter, and cleanup verification obligations from `DI-18` |
| `no-move-ci-enforcement` | `PR-0413`, later `DOC-029 / DI-21`, and `PR-0404` | `pending` | `pending` | no additional file moves plus explicit DI-21 CI-enforcement handoff |
| `legacy-ffi-removal` | `PR-0413` | `pending` | `pending` | Appendix A zero-match removal inventory and cleanup evidence |

## Promotion Gate

ADR / ruling / topic-map publication for the `DI-15` active bundles is allowed only when all of the following are true:

1. `schema-model`, `migration-protection`, `scoped-query`, `service-routing`, `guarded-ffi`, `flutter-core`, and `flutter-features` are all marked `landed`;
2. `execution-order`, `cutover-cleanup`, `api-doc-ownership`, and `verification-gates` are all marked `landed`, and `no-move-ci-enforcement` plus `legacy-ffi-removal` are marked `landed` or explicitly `not_applicable` with evidence;
3. the relevant workspace tests and structural checks are green;
4. `PR-0404` audit confirms that current repo behavior now matches the active `DI-15` bundle rather than the older single-root parent bundle, and that the `DOC-026` execution bundles have been consumed consistently;
5. a governance PR explicitly performs the carrier promotion.

Until all four are satisfied:

- implementation PRs update this ledger only;
- governance PRs keep `OI-031`, `OI-032`, and `OI-033` explicit;
- mainline carrier publication remains blocked.

## Promotion Owner

The first PR allowed to publish or amend the mainline carrier is not automatically one of `PR-0408` through `PR-0413`.

Default rule:

1. workspace implementation PRs land behavior;
2. `PR-0404` verifies coverage and drift;
3. the governance closeout step performs the actual carrier update.

If the team later decides a specific workspace PR should also do the carrier update, that exception must be written here first.

## Reference Documents

- [`open-items.md`](open-items.md)
- [`dn-ledger-classification.md`](dn-ledger-classification.md)
- [`iterations/DOC-023-di-15-rust-data-model-single-root/05-dn-classification-to-decision-line.md`](iterations/DOC-023-di-15-rust-data-model-single-root/05-dn-classification-to-decision-line.md)
- [`iterations/DOC-026-di-18-execution-plan/05-dn-classification-to-decision-line.md`](iterations/DOC-026-di-18-execution-plan/05-dn-classification-to-decision-line.md)
- [`../../../../releases/v0.4/v0.4-kickoff.md`](../../../../releases/v0.4/v0.4-kickoff.md)
