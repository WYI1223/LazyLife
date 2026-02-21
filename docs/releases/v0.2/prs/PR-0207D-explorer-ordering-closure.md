# PR-0207D-explorer-ordering-closure

- Proposed title: `chore(workspace-tree): ordering/move closure, contract sync, and QA replay`
- Status: Planned (depends on PR-0207B + PR-0207C)

## Goal

Finalize and lock the new explorer ordering/move policy after implementation.

This closure PR is the release guard to ensure:

1. docs/contracts exactly match shipped behavior
2. migration/backfill is verified in replay
3. obsolete reorder/sort_order UI paths are safely removed
4. QA checklist and regression entrypoints are reproducible

## Scope

In scope:

- synchronize all related docs and PR statuses
- safely delete obsolete same-parent reorder code paths and tests
- safely delete explorer note preview rendering leftovers
- add/refresh QA checklist with executable commands
- replay migration and runtime regression bundles
- capture known limitations explicitly (if any)

Out of scope:

- new feature work
- schema shape expansion beyond `PR-0207C`

## Closure Checklist

1. Contract sync:
   - `docs/api/ffi-contracts.md`
   - `docs/api/workspace-tree-contract.md`
   - `docs/architecture/data-model.md`
2. Release plan sync:
   - `docs/releases/v0.2/README.md`
   - `docs/releases/v0.2/prs/PR-0207*.md`
3. Verification replay:
   - Rust migration/tree tests
   - Flutter analyze + explorer suites
   - full Flutter test sweep
4. Safe deletion audit:
   - remove reorder-only dead code from explorer drag/controller paths
   - remove reorder-only assertions/tests that no longer match contract
   - ensure `sort_order` stays as backend compatibility field only
5. QA notes:
   - nested folder move reachability
   - ordering snapshots (root/folder/uncategorized)
   - title-only explorer row behavior (no preview line)
   - legacy note visibility/movability after backfill

## Planned File Changes

- [edit] `docs/releases/v0.2/README.md`
- [edit] `docs/releases/v0.2/prs/PR-0207-explorer-context-actions-dnd-baseline.md`
- [edit] `docs/releases/v0.2/prs/PR-0207B-explorer-ordering-contract-freeze.md`
- [edit] `docs/releases/v0.2/prs/PR-0207C-explorer-ordering-and-backfill-implementation.md`
- [edit] `docs/api/ffi-contracts.md`
- [edit] `docs/api/workspace-tree-contract.md`
- [edit] `docs/architecture/data-model.md`

## Verification

- `cd crates && cargo test -p lazynote_core --test db_migrations`
- `cd crates && cargo test -p lazynote_core --test workspace_tree`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test test/explorer_drag_controller_test.dart test/note_explorer_tree_test.dart test/notes_controller_workspace_tree_guards_test.dart`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Docs/contracts/release plan have zero drift.
- [ ] Migration replay confirms idempotent legacy backfill behavior.
- [ ] Obsolete reorder/sort_order UI code and tests are removed without regression.
- [ ] Explorer note rows are verified title-only in QA replay.
- [ ] QA checklist is executable and recorded.
- [ ] PR-0207 lane can be marked fully closed with new semantics.
