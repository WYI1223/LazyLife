# PR-0408 Schema Migration 0012 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land Migration `0012` as the schema foundation for the workspace-topology chain by upgrading the migration framework, adding workspace metadata tables and guards, backfilling current data into one default workspace, and leaving downstream contract evidence for `PR-0409` through `PR-0413`.

**Architecture:** Upgrade the Rust migration registry to support both SQL and Rust-backed steps while preserving the current transaction and `user_version` semantics. Implement `0012` as the first Rust-orchestrated migration that drives static SQL fragments, runtime UUID generation, assertions, and compatibility updates for latest-schema workspace consumers.

**Tech Stack:** Rust, `rusqlite`, SQLite migrations, repository-layer compatibility updates, Markdown governance docs

---

## Chunk 1: Red Tests For Migration 0012

### Task 1: Add failing migration-0012 coverage

**Files:**
- Create: `crates/lazynote_core/tests/migration_0012_test.rs`
- Modify: `crates/lazynote_core/tests/db_migrations.rs`
- Test: `crates/lazynote_core/tests/migration_0012_test.rs`

- [ ] **Step 1: Write the failing fresh-install test**

Create `fresh_install_creates_default_workspace_and_designated_folders()` that:
- opens an in-memory DB through `open_db_in_memory()`;
- asserts schema version is `12`;
- asserts `workspaces` and `designated_folders` tables exist;
- asserts exactly one default workspace root plus three designated folders exist;
- asserts `atoms.origin_workspace_id` exists.

- [ ] **Step 2: Run the targeted fresh-install test to verify RED**

Run: `cargo test --test migration_0012_test fresh_install_creates_default_workspace_and_designated_folders -- --exact`
Expected: FAIL because migration 12 is not implemented yet.

- [ ] **Step 3: Write the failing v11-upgrade/backfill test**

Create `upgrade_from_v11_backfills_default_workspace_and_origin_workspace_id()` that:
- builds a v11 schema fixture;
- inserts root-level folders and atom refs plus atom rows;
- runs `apply_migrations()`;
- asserts legacy root-level nodes are re-parented under the new workspace root;
- asserts every atom now has `origin_workspace_id`.

- [ ] **Step 4: Run the targeted upgrade test to verify RED**

Run: `cargo test --test migration_0012_test upgrade_from_v11_backfills_default_workspace_and_origin_workspace_id -- --exact`
Expected: FAIL because migration 12 is not registered yet.

- [ ] **Step 5: Write the failing trigger-guard tests**

Add tests that expect migration 12 to reject:
- re-parenting a workspace root;
- changing workspace-root kind;
- soft-deleting a designated folder;
- hard-deleting a designated folder;
- assigning a designated folder from another workspace.

- [ ] **Step 6: Run the targeted trigger tests to verify RED**

Run: `cargo test --test migration_0012_test workspace_root_and_designated_folder_guards_reject_invalid_mutations -- --exact`
Expected: FAIL because the trigger surface does not exist yet.

## Chunk 2: Migration Framework Upgrade

### Task 2: Upgrade the migration registry to support Rust-backed steps

**Files:**
- Modify: `crates/lazynote_core/src/db/migrations/mod.rs`
- Test: `crates/lazynote_core/tests/db_migrations.rs`

- [ ] **Step 1: Introduce `MigrationBody` in the registry**

Refactor the migration registry from:
- `Migration { version, sql }`

to:
- `Migration { version, body }`
- `MigrationBody::Sql(&'static str)`
- `MigrationBody::RustFn(fn(&Transaction) -> DbResult<()>)`

- [ ] **Step 2: Convert existing migrations without changing behavior**

Wrap versions `1` through `11` with `MigrationBody::Sql(...)` so the current SQL migrations stay byte-for-byte unchanged.

- [ ] **Step 3: Dispatch migration bodies inside the existing transaction loop**

Update `apply_migrations()` so each step:
- executes either SQL or Rust body;
- preserves the current logging/error handling shape;
- updates `PRAGMA user_version` only after that migration step succeeds.

- [ ] **Step 4: Run migration smoke tests after the framework refactor**

Run: `cargo test --test db_migrations open_db_in_memory_applies_all_migrations -- --exact`
Expected: PASS for existing migrations, while migration-0012 tests remain RED.

## Chunk 3: Implement Migration 0012

### Task 3: Add the Rust-orchestrated migration 12 body

**Files:**
- Add: `crates/lazynote_core/src/db/migrations/migration_0012.rs`
- Add: `crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql`
- Modify: `crates/lazynote_core/src/db/migrations/mod.rs`
- Test: `crates/lazynote_core/tests/migration_0012_test.rs`

- [ ] **Step 1: Add the static SQL fragments for migration 12**

Define SQL fragments for:
- `workspaces` and `designated_folders` creation;
- `atoms.origin_workspace_id` add-column step;
- `workspace_nodes` rebuild with `kind IN ('folder', 'atom_ref', 'workspace')`;
- trigger creation;
- post-migration assertions.

- [ ] **Step 2: Implement runtime UUID orchestration**

In `migration_0012.rs`, generate UUIDs for:
- default workspace root;
- `inbox`;
- `tasks`;
- `calendar`.

Execute the static SQL fragments in order and bind the generated UUIDs into:
- workspace-root inserts;
- designated-folder inserts;
- re-parent/backfill statements;
- assertion queries.

- [ ] **Step 3: Register migration 12 as `MigrationBody::RustFn`**

Wire version `12` into `MIGRATIONS` as the first Rust-backed migration step.

- [ ] **Step 4: Run the targeted migration tests to verify GREEN**

Run: `cargo test --test migration_0012_test -- --nocapture`
Expected: the fresh-install, upgrade, and trigger-guard tests pass.

## Chunk 4: Repository Compatibility And Metadata Access

### Task 4: Add `WorkspaceMetaRepository`

**Files:**
- Add: `crates/lazynote_core/src/repo/workspace_meta_repo.rs`
- Modify: `crates/lazynote_core/src/repo/mod.rs`
- Test: `crates/lazynote_core/tests/migration_0012_test.rs`

- [ ] **Step 1: Define the repository contract**

Add the read-side API:
- `get_default_workspace()`
- `list_workspaces()`
- `resolve_designated(workspace_id, role)`

- [ ] **Step 2: Implement the SQLite repository**

Query from:
- `workspaces`
- `workspace_nodes`
- `designated_folders`

and validate that returned workspace ids resolve to `kind = 'workspace'` rows.

- [ ] **Step 3: Add repository-focused tests**

Extend `migration_0012_test.rs` to prove:
- the default workspace is readable;
- all three designated roles resolve correctly.

- [ ] **Step 4: Run the targeted repository tests**

Run: `cargo test --test migration_0012_test workspace_meta_repository_reads_default_workspace_and_designated_roles -- --exact`
Expected: PASS.

### Task 5: Add latest-schema compatibility for workspace-root semantics

**Files:**
- Modify: `crates/lazynote_core/src/repo/tree_repo.rs`
- Modify: `crates/lazynote_core/tests/workspace_tree.rs`
- Test: `crates/lazynote_core/tests/workspace_tree.rs`

- [ ] **Step 1: Add `WorkspaceNodeKind::Workspace` parsing**

Update the read model and row parsing so persisted `kind = 'workspace'` is supported.

- [ ] **Step 2: Preserve minimal root-level write compatibility**

Update the root-level creation paths so:
- `create_folder(None, ...)` routes to the default workspace root;
- `create_atom_ref(None, ...)` routes to the default workspace root.

Do not implement designated-folder-aware creation routing in this PR.

- [ ] **Step 3: Update workspace-tree tests for latest-schema semantics**

Adjust affected tests so they assert:
- `list_children(None)` returns workspace roots;
- root-level writes land under the default workspace root;
- workspace roots behave as container nodes.

- [ ] **Step 4: Run the targeted workspace-tree tests**

Run: `cargo test --test workspace_tree -- --nocapture`
Expected: PASS with the new workspace-root semantics.

## Chunk 5: Workflow Sync And Full Verification

### Task 6: Sync governance/workflow docs and PR-0408 spec

**Files:**
- Modify: `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`
- Modify: `docs/releases/v0.4/prs/PR-0408-schema-migration.md`
- Verify: `docs/superpowers/specs/2026-03-13-pr-0408-schema-migration-design.md`

- [ ] **Step 1: Update the workspace-topology workflow ledger rows**

Mark `schema-model` as landed or explicit partial based on implementation reality, and update:
- schema-side `migration-protection`
- `execution-order`
- PR-0408-owned `verification-gates`

with evidence paths into the code/tests landed by this PR.

- [ ] **Step 2: Sync the PR-0408 spec to the approved design**

Update the spec so it records:
- reusable `MigrationBody::{Sql, RustFn}` direction;
- multi-root-capable schema with default-workspace backfill;
- `tree_repo` compatibility boundary;
- downstream contract for `PR-0409` through `PR-0413`.

- [ ] **Step 3: Keep carrier publication boundaries intact**

Verify that the PR does not directly amend:
- `docs/architecture/adr/*.md`
- `docs/architecture/rulings/*.md`
- `docs/architecture/adr/topic-map.md`

### Task 7: Run the final verification suite

**Files:**
- Verify: `crates/lazynote_core/src/db/migrations/mod.rs`
- Verify: `crates/lazynote_core/src/db/migrations/migration_0012.rs`
- Verify: `crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql`
- Verify: `crates/lazynote_core/src/repo/workspace_meta_repo.rs`
- Verify: `crates/lazynote_core/src/repo/tree_repo.rs`
- Verify: `crates/lazynote_core/tests/migration_0012_test.rs`
- Verify: `crates/lazynote_core/tests/workspace_tree.rs`
- Verify: `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`
- Verify: `docs/releases/v0.4/prs/PR-0408-schema-migration.md`

- [ ] **Step 1: Run formatting**

Run: `cargo fmt --all -- --check`
Expected: PASS

- [ ] **Step 2: Run linting**

Run: `cargo clippy --all -- -D warnings`
Expected: PASS

- [ ] **Step 3: Run the full Rust test suite**

Run: `cargo test --all`
Expected: PASS

- [ ] **Step 4: Inspect the final diff**

Run: `git diff -- crates/lazynote_core/src/db/migrations/mod.rs crates/lazynote_core/src/db/migrations/migration_0012.rs crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql crates/lazynote_core/src/repo/workspace_meta_repo.rs crates/lazynote_core/src/repo/mod.rs crates/lazynote_core/src/repo/tree_repo.rs crates/lazynote_core/tests/migration_0012_test.rs crates/lazynote_core/tests/workspace_tree.rs docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md docs/releases/v0.4/prs/PR-0408-schema-migration.md`
Expected: only PR-0408-related changes
