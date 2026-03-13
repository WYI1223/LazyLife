# PR-0408 Schema Migration 0012 Design

**Date:** 2026-03-13  
**Related PR:** `PR-0408`  
**Status:** approved-for-planning

## Goal

Land Migration `0012` as the schema foundation for the workspace-topology chain:

- add multi-root-capable workspace schema;
- migrate current data into one default workspace;
- add designated-folder metadata and protection triggers;
- add `atoms.origin_workspace_id`;
- leave downstream evidence for `PR-0409` through `PR-0413` without publishing carrier text.

## Decision Summary

`PR-0408` will use a reusable migration framework upgrade rather than a one-off special case.

Chosen approach:

1. upgrade the migration registry from SQL-only to `MigrationBody::{Sql, RustFn}`;
2. keep the executor transaction model, version ordering, logging, and `user_version` semantics unchanged;
3. implement `0012` as the first Rust-orchestrated migration consumer;
4. keep `0012` scoped to schema, migration/backfill, trigger protection, read-side workspace metadata access, and migration-focused tests.

Rejected alternatives:

- SQL-only `randomblob()` migration: smaller diff, but worse readability, weaker reuse, and harder assertions;
- hardcoded `if version == 12` branch in executor: fast now, but turns the migration framework into version-specific special cases.

## Migration Framework Design

### Registry Model

`crates/lazynote_core/src/db/migrations/mod.rs` will evolve from:

- `Migration { version, sql }`

to:

- `Migration { version, body }`
- `MigrationBody::Sql(&'static str)`
- `MigrationBody::RustFn(fn(&Transaction) -> DbResult<()>)`

### Executor Guarantees

The framework must preserve the current guarantees:

- migrations still run in strictly increasing version order;
- all pending migrations still run inside one SQLite transaction;
- `PRAGMA user_version` still advances only after one migration step succeeds;
- current logging shape and error propagation remain intact;
- existing SQL migrations remain unchanged and continue to use `MigrationBody::Sql`.

### `0012` Execution Model

`0012` will be the first `MigrationBody::RustFn` migration.

Its Rust orchestration is responsible for:

- generating runtime UUIDs for the default workspace root and three designated folders;
- executing static SQL fragments in deterministic order;
- binding UUIDs into parameterized SQL statements;
- running migration assertions before the step completes.

This keeps runtime-dependent work in Rust while leaving structural DDL and trigger definitions in static SQL.

## `0012` Schema And Backfill Design

### Schema Shape

`0012` lands a multi-root-capable schema, even though the migration creates only one default workspace for existing data.

The landed schema assumptions are:

- `workspace_nodes.kind` supports `folder | atom_ref | workspace`;
- `workspaces` stores workspace metadata;
- `designated_folders` stores `workspace_id + role + node_uuid`;
- `atoms.origin_workspace_id` exists and references `workspaces(workspace_id)`.

### Migration Result For Existing Databases

After migrating a current v11 database:

- exactly one default workspace root exists;
- exactly three designated folders exist for that workspace: `inbox`, `tasks`, `calendar`;
- all legacy root-level `workspace_nodes` are re-parented under the workspace root;
- all existing atoms are backfilled with `origin_workspace_id = <default workspace>`;
- workspace-root and designated-folder protection triggers are installed.

This means the schema is ready for later multi-workspace behavior, while current data is normalized into one default workspace.

### Trigger Boundary

`PR-0408` only lands schema-guard triggers, not service-routing behavior.

Planned triggers:

- `protect_workspace_root_reparent`
- `protect_workspace_root_kind`
- `protect_designated_folder_soft_delete`
- `protect_designated_folder_hard_delete`
- `validate_designated_folder_workspace`
- `validate_designated_folder_workspace_update`

The migration may also use assertion SQL to fail fast if expected post-migration invariants are missing.

## File Boundaries

### Migration Files

- `crates/lazynote_core/src/db/migrations/mod.rs`
  - framework upgrade and registry wiring for migration 12
- `crates/lazynote_core/src/db/migrations/migration_0012.rs`
  - Rust orchestration for migration 12
- `crates/lazynote_core/src/db/migrations/0012_workspace_single_root.sql`
  - static DDL, rebuild, index, trigger, and reusable SQL fragments

### Repository Files

- `crates/lazynote_core/src/repo/workspace_meta_repo.rs`
  - `WorkspaceMetaRepository` and SQLite implementation
- `crates/lazynote_core/src/repo/mod.rs`
  - export the new repository module

### Compatibility Touches

`crates/lazynote_core/src/repo/tree_repo.rs` needs narrow compatibility updates because latest-schema behavior changes after `0012`.

Required compatibility scope:

- add `WorkspaceNodeKind::Workspace`;
- parse persisted `kind = 'workspace'`;
- treat `workspace` as a container node similar to `folder` for read paths;
- preserve minimal root-level write compatibility by routing `create_folder(None)` and `create_atom_ref(None)` to the default workspace root.

Explicit non-goal:

- `PR-0408` does not implement designated-folder-aware creation routing. That stays with later workspace PRs.

## Downstream Contract For PR-0409 Through PR-0413

`PR-0408` must leave a short downstream contract that later workspace PRs can cite without restating the full migration design.

The post-0012 assumptions they may rely on are:

1. `workspace_nodes.kind` includes `workspace`;
2. `workspaces` exists and has one default workspace in migrated current data;
3. `designated_folders` exists and current migrated data has `inbox/tasks/calendar`;
4. `atoms.origin_workspace_id` exists and old rows are backfilled;
5. workspace roots cannot be re-parented or have kind changed;
6. designated folders cannot be deleted while designated;
7. `WorkspaceMetaRepository` is the read-side bridge for default workspace and designated-folder lookup.

This should be recorded in `PR-0408` documentation and referenced from later specs as a short dependency contract, not copied verbatim into every later PR.

## Test Strategy

### Dedicated Migration Tests

Add `crates/lazynote_core/tests/migration_0012_test.rs` for:

- fresh install to latest version;
- v11 -> v12 upgrade path;
- default workspace creation assertions;
- designated-folder creation and mapping assertions;
- `origin_workspace_id` backfill assertions;
- trigger negative tests;
- migration-step failure behavior when assertions fail.

### Existing Test Updates

- `crates/lazynote_core/tests/db_migrations.rs`
  - keep as broad smoke coverage, add latest-schema checks only where needed
- `crates/lazynote_core/tests/workspace_tree.rs`
  - update tests affected by the new workspace-root semantics

### Verification Commands

From `crates/`:

```bash
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
```

## Non-Goals

`PR-0408` does not include:

- scoped query semantics;
- TreeService or CreationService routing changes;
- FFI surface changes;
- Flutter workspace adoption;
- ADR / ruling / topic-map publication.

## Planning Guidance

The implementation plan should be built around four chunks:

1. migration framework upgrade;
2. migration 0012 schema/backfill implementation;
3. repository compatibility and workspace metadata access;
4. migration tests, workflow sync, and verification.
