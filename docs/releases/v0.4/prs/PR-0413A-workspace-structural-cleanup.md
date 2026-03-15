# PR-0413A: Workspace Structural Cleanup

- Proposed title: `refactor(core): split workspace repo and integration tests`
- Status: Draft

## Goal

After `PR-0413` merges, split the large workspace topology hotspot files into
focused modules and test files without changing workspace behavior, schema
semantics, or Flutter-visible contracts.

## Why This Is A Separate PR

`PR-0413` is the end of the workspace-topology implementation chain and already
absorbs a broad Flutter-feature cutover. The follow-on cleanup of
`tree_repo.rs` and `workspace_tree.rs` is valuable, but it should be reviewed as
refactor-only work instead of being mixed into the behavioral cutover.

This PR exists to give that structural cleanup a clear owner and explicit scope.

## Preconditions

- `PR-0413` is merged.
- Workspace topology behavior is already green end-to-end.
- No in-flight workspace feature PR is still depending on the old file layout.

## Scope

### In Scope

- Split `crates/lazynote_core/src/repo/tree_repo.rs` into a
  `crates/lazynote_core/src/repo/tree_repo/` module tree.
- Split `crates/lazynote_core/tests/workspace_tree.rs` into focused integration
  test files with shared helpers.
- Preserve `TreeRepository` behavior and existing workspace assertions.
- Add a shared workspace-test support module if needed.

### Out Of Scope

- New workspace behavior
- Migration rewrites
- Creation-routing redesign
- AccessGuard / FFI behavior changes
- Flutter feature changes

## Target Structure

- `crates/lazynote_core/src/repo/tree_repo/mod.rs`
- `crates/lazynote_core/src/repo/tree_repo/reads.rs`
- `crates/lazynote_core/src/repo/tree_repo/writes.rs`
- `crates/lazynote_core/src/repo/tree_repo/move_ops.rs`
- `crates/lazynote_core/src/repo/tree_repo/delete_ops.rs`
- `crates/lazynote_core/src/repo/tree_repo/path_ops.rs`
- `crates/lazynote_core/src/repo/tree_repo/parse.rs`
- `crates/lazynote_core/tests/support/workspace.rs`
- `crates/lazynote_core/tests/workspace_tree_root_listing.rs`
- `crates/lazynote_core/tests/workspace_tree_move_guards.rs`
- `crates/lazynote_core/tests/workspace_tree_delete_guards.rs`
- `crates/lazynote_core/tests/workspace_tree_designated.rs`
- `crates/lazynote_core/tests/workspace_tree_ancestor_path.rs`
- `crates/lazynote_core/tests/workspace_tree_ordering.rs`

## Planned File Changes

- `[delete/replace]` `crates/lazynote_core/src/repo/tree_repo.rs`
- `[add]` `crates/lazynote_core/src/repo/tree_repo/mod.rs`
- `[add]` `crates/lazynote_core/src/repo/tree_repo/reads.rs`
- `[add]` `crates/lazynote_core/src/repo/tree_repo/writes.rs`
- `[add]` `crates/lazynote_core/src/repo/tree_repo/move_ops.rs`
- `[add]` `crates/lazynote_core/src/repo/tree_repo/delete_ops.rs`
- `[add]` `crates/lazynote_core/src/repo/tree_repo/path_ops.rs`
- `[add]` `crates/lazynote_core/src/repo/tree_repo/parse.rs`
- `[delete/replace]` `crates/lazynote_core/tests/workspace_tree.rs`
- `[add]` `crates/lazynote_core/tests/support/workspace.rs`
- `[add]` focused `workspace_tree_*` integration test files

## Verification

```bash
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
dart run tools/ci/architecture_check.dart
```

## Acceptance Criteria

- `tree_repo.rs` is decomposed into focused internal modules.
- `workspace_tree.rs` is decomposed into focused integration test files.
- Runtime workspace behavior is unchanged.
- Rust verification gates and architecture checks pass.
- This cleanup PR does not update ADR, ruling, topic-map, or workspace carrier
  promotion surfaces.
