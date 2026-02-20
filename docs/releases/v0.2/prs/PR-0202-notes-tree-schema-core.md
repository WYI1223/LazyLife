# PR-0202-notes-tree-schema-core

- Proposed title: `feat(core): hierarchical notes tree schema and services`
- Status: Completed (baseline landed; delete semantics refined by `PR-0221`)

## Goal

Introduce a core-owned hierarchical tree model that supports folders and note placement.

## Scope (v0.2)

In scope:

- new tree schema for folder/note nodes
- parent-child relationships with deterministic ordering
- create/rename/move/list children core use-cases
- cycle and invalid-parent guards

Out of scope:

- provider sync mapping for tree structure
- advanced permissions/ACL model

## Data Model

New table (name can be finalized in implementation):

- `workspace_nodes`
  - `node_uuid` (stable id)
  - `kind` (`folder | note_ref`)
  - `parent_uuid` (nullable for root)
  - `atom_uuid` (nullable, required for `note_ref`)
  - `display_name`
  - `sort_order`
  - `is_deleted`
  - `created_at`, `updated_at`

Invariants:

1. `note_ref.atom_uuid` must reference an active note atom on create/update.
2. `folder` nodes must not carry `atom_uuid`.
3. parent link must not create cycles.
4. delete defaults to soft-delete behavior.

Follow-up note:

- `PR-0221` updates delete-policy semantics: note delete may leave dangling
  `note_ref` rows, and read paths filter/restore visibility by atom state.
- This is an intentional policy extension on top of the schema/service baseline
  introduced by `PR-0202`.

## Step-by-Step

1. Add migration and indexes.
2. Add repository contract for tree operations.
3. Add service layer validation/invariants.
4. Add integration tests for hierarchy operations and failure paths.
5. Update architecture docs (`data-model`, `note-schema`).

## Planned File Changes

- [add] `crates/lazynote_core/src/db/migrations/0007_workspace_tree.sql`
- [edit] `crates/lazynote_core/src/db/migrations/mod.rs`
- [add] `crates/lazynote_core/src/repo/tree_repo.rs`
- [edit] `crates/lazynote_core/src/repo/mod.rs`
- [add] `crates/lazynote_core/src/service/tree_service.rs`
- [edit] `crates/lazynote_core/src/service/mod.rs`
- [add] `crates/lazynote_core/tests/workspace_tree.rs`
- [edit] `docs/architecture/data-model.md`
- [edit] `docs/architecture/note-schema.md`

## Verification

- `cd crates && cargo fmt --all -- --check`
- `cd crates && cargo clippy --all -- -D warnings`
- `cd crates && cargo test --all`
- `cd crates && cargo test -p lazynote_core --test workspace_tree`

## Status Calibration Evidence

- migration and registration landed:
  - `crates/lazynote_core/src/db/migrations/0007_workspace_tree.sql`
  - `crates/lazynote_core/src/db/migrations/mod.rs`
- repo/service landed:
  - `crates/lazynote_core/src/repo/tree_repo.rs`
  - `crates/lazynote_core/src/service/tree_service.rs`
- integration tests landed:
  - `crates/lazynote_core/tests/workspace_tree.rs`
- architecture docs landed:
  - `docs/architecture/data-model.md`
  - `docs/architecture/note-schema.md`
- regression replay (2026-02-20):
  - `cargo test -p lazynote_core --test workspace_tree` passed (13/13)

## Acceptance Criteria

- [x] Tree schema is migration-safe and deterministic.
- [x] Core rejects invalid parent/cycle operations.
- [x] Folder + note_ref hierarchy can be queried by parent id.
- [x] Docs reflect new tree model and invariants.
