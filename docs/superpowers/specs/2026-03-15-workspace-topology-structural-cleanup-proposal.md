# Workspace Topology Structural Cleanup Proposal

> Superseded by formal release specs:
> `docs/releases/v0.4/prs/PR-0411A-ffi-structural-cleanup.md` and
> `docs/releases/v0.4/prs/PR-0413A-workspace-structural-cleanup.md`.

## Purpose

This note formalizes two follow-on cleanup sub-PRs that should stay outside the
current workspace-topology implementation chain. The goal is to reduce file
size and sharpen module boundaries without mixing structural refactors into the
behavioral PRs that land `PR-0411` through `PR-0413`.

## Why Separate Cleanup PRs

- Current landing PRs still carry behavior and contract risk. Mixing large file
  moves into them would make review noisier and make regressions harder to
  isolate.
- The current top-level project structure is still healthy. The structural debt
  is concentrated in a few hotspot files rather than in the repo layout as a
  whole.
- The cleanup work is valuable, but it should be held to a stricter "no
  behavioral change" standard than the feature PRs.

## Decision

Use dedicated cleanup sub-PRs after the corresponding behavioral milestones:

1. After `PR-0411` merges, land an FFI-focused cleanup sub-PR.
2. After `PR-0413` merges, land a Rust Core repo/test cleanup sub-PR.

These sub-PRs are allowed to reorganize files and directories, but they must
not introduce new product behavior, schema changes, or contract expansion.

## Sub-PR A: FFI Surface Modularization

**Trigger:** start only after `PR-0411` is merged.

**Primary target:** `crates/lazynote_ffi/src/api.rs`

**Problem statement:** `api.rs` now mixes public FRB entrypoints, error mapping,
service wiring, DTO conversion, and FFI tests in one file. That is the highest
value cleanup target in the current codebase.

**Target structure:**

- `crates/lazynote_ffi/src/api/mod.rs`
- `crates/lazynote_ffi/src/api/entry.rs`
- `crates/lazynote_ffi/src/api/notes.rs`
- `crates/lazynote_ffi/src/api/workspace.rs`
- `crates/lazynote_ffi/src/api/tasks.rs`
- `crates/lazynote_ffi/src/api/calendar.rs`
- `crates/lazynote_ffi/src/api/errors.rs`
- `crates/lazynote_ffi/src/api/mappers.rs`
- `crates/lazynote_ffi/src/api/support.rs`

**Boundary rules:**

- Keep public FRB function names and response shapes unchanged.
- Prefer moving internal helpers first: `*_impl`, `with_*_service`,
  `map_*_error`, `to_*`.
- Only after helper boundaries are stable should public entrypoints be split
  across feature modules.
- Keep generated files out of scope except for required binding regeneration.

**Out of scope:**

- New FFI endpoints
- Error-code redesign
- Guard semantics changes
- Flutter consumer updates beyond required compile fixes

## Sub-PR B: Workspace Repo/Test Decomposition

**Trigger:** start only after `PR-0413` is merged.

**Primary targets:**

- `crates/lazynote_core/src/repo/tree_repo.rs`
- `crates/lazynote_core/tests/workspace_tree.rs`

**Problem statement:** the workspace topology contracts are still settling
through `PR-0413`. Splitting repo and integration-test surfaces too early would
cause churn. Once feature consumers are stable, these files become the next best
cleanup targets.

**Target structure:**

- `crates/lazynote_core/src/repo/tree_repo/mod.rs`
- `crates/lazynote_core/src/repo/tree_repo/reads.rs`
- `crates/lazynote_core/src/repo/tree_repo/writes.rs`
- `crates/lazynote_core/src/repo/tree_repo/move_ops.rs`
- `crates/lazynote_core/src/repo/tree_repo/delete_ops.rs`
- `crates/lazynote_core/src/repo/tree_repo/path_ops.rs`
- `crates/lazynote_core/src/repo/tree_repo/parse.rs`

For integration tests, prefer multiple focused test crates plus shared helpers
instead of one large `workspace_tree.rs` file:

- `crates/lazynote_core/tests/workspace_tree_root_listing.rs`
- `crates/lazynote_core/tests/workspace_tree_move_guards.rs`
- `crates/lazynote_core/tests/workspace_tree_delete_guards.rs`
- `crates/lazynote_core/tests/workspace_tree_designated.rs`
- `crates/lazynote_core/tests/workspace_tree_ancestor_path.rs`
- `crates/lazynote_core/tests/workspace_tree_ordering.rs`
- `crates/lazynote_core/tests/support/workspace.rs`

**Boundary rules:**

- Keep `TreeRepository` trait behavior unchanged.
- Keep test assertions semantically identical unless a previously hidden gap is
  found and called out explicitly.
- Do not combine this cleanup with new workspace behavior or Flutter-side
  changes.

**Out of scope:**

- `0012` migration rewrites
- New workspace semantics
- Creation routing redesign
- AccessGuard or FFI behavior changes

## Directory Strategy

No repo-wide reorg is needed right now.

Recommended additions:

- Add `crates/lazynote_ffi/src/api/` in the FFI cleanup sub-PR.
- Add `crates/lazynote_core/src/repo/tree_repo/` in the post-`PR-0413` cleanup
  sub-PR.
- Add `crates/lazynote_core/tests/support/` for shared workspace integration
  fixtures when the large workspace test file is split.

Do not introduce new top-level architecture layers such as `domain/`,
`application/`, or `infrastructure/`. The existing top-level layout is still
good enough; the problem is local file concentration, not repo taxonomy.

## Execution Standard

Each cleanup sub-PR should follow these rules:

- Treat the work as structural refactor only.
- Use small commits and keep moves grouped by responsibility.
- Run full verification before merge:
  - `cargo fmt --all -- --check`
  - `cargo clippy --all -- -D warnings`
  - `cargo test --all`
  - `dart run tools/ci/architecture_check.dart`
- If FFI signatures move across files, regenerate bindings and verify the
  Flutter side still compiles.

## Ownership And Handoff

- `PR-0411` should leave the FFI surface ready for Sub-PR A.
- `PR-0413` should leave the workspace repo/test surface ready for Sub-PR B.
- These cleanup PRs are implementation-maintenance work only. They are not
  carrier-promotion PRs and should not update ADR, ruling, or topic-map
  surfaces.
