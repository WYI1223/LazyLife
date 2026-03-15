# PR-0409 Scoped Query Repository Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land `ScopedQueryRepository` as the canonical subtree-query engine, migrate current section reads onto it without changing the public FFI surface, and record the temporary pre-`PR-0410` compatibility bridge so later service-routing work has an explicit handoff.

**Architecture:** Add a dedicated read-only repository for subtree-scoped atom queries, with a strongly typed descriptor and a recursive-CTE execution pipeline. Keep `TaskService` as the consumer-facing service facade, but switch its read methods from `AtomRepository` section SQL to the new query repo plus `WorkspaceMetaRepository`, while preserving current root-scoped visibility through a documented transitional bridge until `PR-0410` lands creation routing.

**Tech Stack:** Rust, `rusqlite`, SQLite recursive CTEs, core repository/service layering, Markdown workflow/spec docs

---

## Chunk 1: Red Tests For Query Contract And Service Semantics

### Task 1: Add failing scoped-query repository coverage

**Files:**
- Create: `crates/lazynote_core/tests/scoped_query_repo.rs`
- Modify: `crates/lazynote_core/tests/time_matrix.rs`
- Test: `crates/lazynote_core/tests/scoped_query_repo.rs`

- [x] **Step 1: Write the failing subtree-scope tests**

Add tests that create workspace folders/refs and prove:
- querying one subtree only returns refs inside that subtree;
- querying the workspace root can see descendants from multiple folders;
- querying sibling subtrees does not leak atoms across branches.

- [x] **Step 2: Run the targeted subtree test to verify RED**

Run: `cargo test --test scoped_query_repo subtree_scope_only_returns_descendants -- --exact`
Expected: FAIL because `ScopedQueryRepository` does not exist yet.

- [x] **Step 3: Write the failing projection-mode tests**

Add tests for:
- `ProjectionMode::Atom` deduping duplicate refs for the same atom;
- `ProjectionMode::Ref` returning every atom_ref separately;
- `include_path = true` populating a stable path for `Ref` projection.

- [x] **Step 4: Run the projection test to verify RED**

Run: `cargo test --test scoped_query_repo atom_projection_dedups_duplicate_refs -- --exact`
Expected: FAIL because the query pipeline does not exist yet.

- [x] **Step 5: Write the failing time-filter truth-table tests**

Add tests for:
- `Timeless` returning only atoms with both time fields null;
- `Range(start, Some(end))` using overlap semantics;
- `Range(start, None)` using anchor-forward semantics;
- `include_overdue_deadlines = true` rejecting invalid non-range combinations.

- [x] **Step 6: Run the truth-table test to verify RED**

Run: `cargo test --test scoped_query_repo invalid_overdue_descriptor_is_rejected -- --exact`
Expected: FAIL because descriptor validation is not implemented.

### Task 2: Add failing service-regression tests for the transition bridge

**Files:**
- Modify: `crates/lazynote_core/tests/time_matrix.rs`
- Test: `crates/lazynote_core/tests/time_matrix.rs`

- [x] **Step 1: Rewrite time-matrix fixtures to create tree refs explicitly**

Update test helpers so they:
- create atoms through `SqliteAtomRepository`;
- create folders/refs through tree services/repos;
- place refs either under the default workspace root or under explicit folders as needed.

- [x] **Step 2: Write the failing bridge regression test**

Create one test proving current service-consumed section reads still surface a root-scoped task/event ref before `PR-0410` routing is implemented.

- [x] **Step 3: Run the targeted regression test to verify RED**

Run: `cargo test --test time_matrix fetch_today_keeps_root_scoped_visibility_before_pr_0410 -- --exact`
Expected: FAIL because the new bridge path is not implemented yet.

## Chunk 2: Add The Scoped Query Repository

### Task 3: Define the query contract and repository module

**Files:**
- Add: `crates/lazynote_core/src/repo/scoped_query_repo.rs`
- Modify: `crates/lazynote_core/src/repo/mod.rs`
- Modify: `crates/lazynote_core/src/lib.rs`
- Test: `crates/lazynote_core/tests/scoped_query_repo.rs`

- [x] **Step 1: Define the descriptor and result types**

Add:
- `ScopedAtomQuery`
- `TimeFilter`
- `TimeShapeFilter`
- `StatusFilter`
- `SortSpec`
- `ProjectionMode`
- `ScopedAtomResult`
- `ScopedQueryError`

- [x] **Step 2: Define the repository trait and SQLite implementation shell**

Add:
- `ScopedQueryRepository`
- `SqliteScopedQueryRepository::try_new(&Connection)`
- descriptor validation helpers.

- [x] **Step 3: Run the descriptor-focused test to confirm it still fails for missing behavior**

Run: `cargo test --test scoped_query_repo invalid_overdue_descriptor_is_rejected -- --exact`
Expected: FAIL at repository behavior, not missing types.

### Task 4: Implement the recursive-CTE query pipeline

**Files:**
- Modify: `crates/lazynote_core/src/repo/scoped_query_repo.rs`
- Modify: `crates/lazynote_core/src/repo/atom_repo.rs`
- Test: `crates/lazynote_core/tests/scoped_query_repo.rs`

- [x] **Step 1: Reuse atom parsing helpers without duplicating persisted-row decoding**

Expose the minimum `pub(crate)` helpers from `atom_repo.rs` needed to parse atoms and status/view-hint values in the new repo.

- [x] **Step 2: Implement scope expansion and filter building**

Implement:
- recursive subtree expansion from `folder_id`;
- time-filter and time-shape filtering;
- status, view-hint, tag, and text-query filtering;
- optional overdue-deadline union for valid Today descriptors only.

- [x] **Step 3: Implement projection, dedup, sort, and paging**

Support:
- `ProjectionMode::Atom` dedup by atom id;
- `ProjectionMode::Ref` pass-through of every ref;
- `SortSpec::UpdatedAtDesc`, `SortSpec::StartAtAsc`, `SortSpec::TitleAsc`;
- `include_path` filling `ScopedAtomResult.path`.

- [x] **Step 4: Run the scoped-query integration tests to verify GREEN**

Run: `cargo test --test scoped_query_repo -- --nocapture`
Expected: PASS for subtree, projection, descriptor, and overdue cases.

## Chunk 3: Migrate TaskService To The New Query Repo

### Task 5: Refactor TaskService dependencies and query translation

**Files:**
- Modify: `crates/lazynote_core/src/service/task_service.rs`
- Modify: `crates/lazynote_core/tests/time_matrix.rs`
- Test: `crates/lazynote_core/tests/time_matrix.rs`

- [x] **Step 1: Change TaskService to depend on atom writes plus scoped/workspace reads**

Refactor `TaskService` so it holds:
- `AtomRepository` for status/time updates and direct atom reads;
- `WorkspaceMetaRepository` for workspace/designated lookup;
- `ScopedQueryRepository` for section read paths;
- `&Connection` for tag enrichment.

- [x] **Step 2: Translate service methods into ScopedAtomQuery descriptors**

Implement descriptor builders for:
- inbox
- today
- upcoming
- by-time-range
- timed

Keep service method names and return shapes unchanged.

- [x] **Step 3: Add the documented transitional compatibility bridge**

For current FFI-consumed section reads, preserve pre-`PR-0410` visibility of root-scoped refs through an explicit compatibility path. The bridge must be isolated in named helpers and covered by tests.

- [x] **Step 4: Run the time-matrix suite to verify GREEN**

Run: `cargo test --test time_matrix -- --nocapture`
Expected: PASS with old section semantics preserved and new repo delegation in place.

## Chunk 4: Keep FFI Surface Stable While Rewiring Internals

### Task 6: Rewire internal service construction without adding new FFI endpoints

**Files:**
- Modify: `crates/lazynote_ffi/src/api.rs`
- Test: `crates/lazynote_ffi/src/api.rs`

- [x] **Step 1: Update `with_task_service` to build the new dependencies**

Construct:
- `SqliteAtomRepository`
- `SqliteWorkspaceMetaRepository`
- `SqliteScopedQueryRepository`
- `TaskService`

while keeping the public FFI functions unchanged.

- [x] **Step 2: Add or adjust FFI tests for bridge behavior**

Cover at least:
- existing `tasks_list_*` and `calendar_list_by_range` paths still return expected rows;
- root-scoped refs remain visible before `PR-0410`.

- [x] **Step 3: Run the targeted FFI tests**

Run: `cargo test -p lazynote_ffi calendar_list_by_range_returns_overlapping_events workspace_create_folder_returns_node_payload`
Expected: PASS for unchanged public contracts plus the new internal wiring.

## Chunk 5: Sync Docs And Verify End To End

### Task 7: Update PR specs and workflow ledger for the compatibility bridge

**Files:**
- Modify: `docs/releases/v0.4/prs/PR-0409-scoped-query-repository.md`
- Modify: `docs/releases/v0.4/prs/PR-0410-tree-service-creation-service.md`
- Modify: `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`
- Verify: `docs/superpowers/plans/2026-03-14-pr-0409-scoped-query-repository.md`

- [x] **Step 1: Record the landed bridge semantics in PR-0409**

Document:
- what the transitional bridge preserves;
- why it exists;
- that `ScopedQueryRepository` remains canonical despite the bridge.

- [x] **Step 2: Record the bridge-consumption responsibility in PR-0410**

Document:
- that `PR-0410` owns the service-routing cutover;
- whether the bridge must be removed, narrowed, or kept explicit after creation routing lands.

- [x] **Step 3: Update workflow ledger evidence**

Mark `scoped-query`, plus related `execution-order` / `verification-gates`, with evidence paths that mention the bridge and the new repository/tests.

### Task 8: Run full verification

**Files:**
- Verify: `crates/lazynote_core/src/repo/scoped_query_repo.rs`
- Verify: `crates/lazynote_core/src/service/task_service.rs`
- Verify: `crates/lazynote_ffi/src/api.rs`
- Verify: `crates/lazynote_core/tests/scoped_query_repo.rs`
- Verify: `crates/lazynote_core/tests/time_matrix.rs`
- Verify: `docs/releases/v0.4/prs/PR-0409-scoped-query-repository.md`

- [x] **Step 1: Run formatting and linting**

Run:
- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`

Expected: both PASS.

- [x] **Step 2: Run full Rust tests**

Run: `cargo test --all`
Expected: PASS, including the new scoped-query suite and updated time-matrix / FFI coverage.

- [x] **Step 3: Run structural verification**

Run: `dart run tools/ci/architecture_check.dart`
Expected: `PASSED — no architecture violations.`
