# PR-0411A: FFI Structural Cleanup

- Proposed title: `refactor(ffi): split guarded FFI surface into focused modules`
- Status: Merged

## Implementation Snapshot (2026-03-19)

Current branch state for `PR-0411A`:

- the monolithic `crates/lazynote_ffi/src/api.rs` surface is now replaced by a
  directory-backed `crates/lazynote_ffi/src/api/` module tree
- public guarded exports are explicitly assigned to focused production modules:
  - `query_atoms` -> `query.rs`
  - `atom_create` -> `creation.rs`
  - legacy entry / notes / tasks / calendar / workspace exports remain grouped
    by domain module
- shared FFI responsibilities are now separated into:
  - `errors.rs`
  - `mappers.rs`
  - `support.rs`
  - `mod.rs` for shared DTOs / enums / bootstrap exports
- workspace-local action mapping remains in `workspace.rs`, preserving the
  landed `PR-0411` audit boundary
- the inline `api.rs` test inventory is now decomposed into `api/tests/` plus
  `test_support.rs`, while preserving:
  - legacy wrapper parity filters
  - per-test DB isolation
  - guard-injection test support
- generated bindings were not hand-edited; this cleanup stayed within the Rust
  FFI source layer

## Verification Snapshot (2026-03-19)

Closeout verification executed on this branch:

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `cd apps/lazynote_flutter && dart format --output=none --set-exit-if-changed .`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`
- `dart run tools/ci/architecture_check.dart`

Key targeted regressions that remained green after the split:

- `cargo test -p lazynote_ffi legacy_wrapper_ -- --nocapture`
- `cargo test -p lazynote_ffi workspace_ -- --nocapture`
- `cargo test -p lazynote_ffi api::tests::query_atoms_returns_scoped_items -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::atom_create_routes_task_to_designated_folder -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::tasks_list_today_keeps_root_scoped_refs_visible_before_pr_0410 -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::workspace_list_filters_to_readable_subset_under_guard -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::legacy_wrapper_entry_search_preserves_fts_snippet_and_order -- --exact --nocapture`

Non-blocking validation note:

- `architecture_check` still reports the existing size warning on generated
  `apps/lazynote_flutter/lib/core/bindings/api.dart`; this warning pre-existed
  `PR-0411A` and was not introduced by this cleanup.

## Goal

After `PR-0411` merges, split `crates/lazynote_ffi/src/api.rs` into a focused
module tree without changing the public FFI contract, runtime behavior, or
guard semantics.

## Execution Plan

Detailed execution plan: [2026-03-19-pr-0411a-ffi-structural-cleanup.md](../../../superpowers/plans/2026-03-19-pr-0411a-ffi-structural-cleanup.md)

## Synchronization From PR-0411 (2026-03-19)

`PR-0411` has now landed more internal FFI structure than the original
`PR-0411A` draft assumed. This cleanup PR must preserve those landed internals
while only reorganizing them:

- guarded export implementations now commonly follow:
  - `*_impl`
  - `*_impl_with_noop_guard`
  - `*_impl_inner`
- shared guarded wiring now includes:
  - `with_guarded_*_using_guard(...)`
  - `with_guarded_tree_service_raw_using_guard(...)`
- workspace-facing actions now include local action-specific error mapping
  helpers in addition to shared `map_guarded_service_error(...)`
- FFI tests now rely on per-test database isolation and guard-injection helpers
  that were introduced during `PR-0411` closeout

Implication for this PR:

- `PR-0411A` must reorganize that structure cleanly
- `PR-0411A` must not collapse those layers back together in ways that obscure
  runtime-vs-test guard boundaries
- `PR-0411A` must keep the test-support wiring explicit enough that guarded
  parity and denial-path tests remain easy to audit

## Why This Is A Separate PR

`PR-0411` is a behavioral landing PR: it introduces guarded FFI contracts,
compatibility wrappers, and error-surface changes. The large `api.rs` split is
useful, but it would add review noise and make behavioral regressions harder to
isolate if it were mixed into the same review stream.

This PR exists to hold that structural responsibility explicitly as a follow-on
cleanup sub-PR.

## Preconditions

- `PR-0411` is merged.
- No unresolved review findings remain on the guarded FFI behavior.
- If downstream work is still actively editing `crates/lazynote_ffi/src/api.rs`,
  prefer waiting until that churn settles before opening this PR.

## Scope

### In Scope

- Split `crates/lazynote_ffi/src/api.rs` into `crates/lazynote_ffi/src/api/`
  modules.
- Keep public FRB function names, signatures, sync/async attributes, and
  response envelopes unchanged.
- Move internal helpers into focused modules:
  - `*_impl`
  - `*_impl_with_noop_guard`
  - `*_impl_inner`
  - `with_*_service`
  - `with_*_using_guard`
  - `map_*_error`
  - DTO/response mapping helpers
- Reorganize FFI tests to match the new module structure.
- Move shared FFI test helpers into a support location that preserves:
  - per-test DB-path isolation
  - guard-injection helpers
  - common fixture/setup code
- Preserve the landed `PR-0411` workspace-facing behavior during the split:
  - `workspace_list` returns the readable subset under guard, not all-or-nothing
  - `workspace_reassign_designated` continues to route through
    `GuardedTreeService`
  - local workspace action error mapping remains behavior-equivalent after the
    move
- Regenerate bindings if the module move requires it.

### Out Of Scope

- New FFI endpoints
- Error-code redesign
- Guard rule changes
- Rust Core behavior changes
- Flutter consumer migration beyond any required compile-validation work

## Target Structure

- `crates/lazynote_ffi/src/api/mod.rs`
- `crates/lazynote_ffi/src/api/entry.rs`
- `crates/lazynote_ffi/src/api/notes.rs`
- `crates/lazynote_ffi/src/api/query.rs`
- `crates/lazynote_ffi/src/api/creation.rs`
- `crates/lazynote_ffi/src/api/workspace.rs`
- `crates/lazynote_ffi/src/api/tasks.rs`
- `crates/lazynote_ffi/src/api/calendar.rs`
- `crates/lazynote_ffi/src/api/errors.rs`
- `crates/lazynote_ffi/src/api/mappers.rs`
- `crates/lazynote_ffi/src/api/support.rs`
- `crates/lazynote_ffi/src/api/test_support.rs`
- `crates/lazynote_ffi/src/api/tests/mod.rs`
- `crates/lazynote_ffi/src/api/tests/legacy.rs`
- `crates/lazynote_ffi/src/api/tests/workspace.rs`
- `crates/lazynote_ffi/src/api/tests/query_and_creation.rs`
- `crates/lazynote_ffi/src/api/tests/entry_notes_tasks_calendar.rs`

Module responsibility guidance:

- `mod.rs`
  - owns shared public FFI DTOs/enums/constants
  - keeps the small diagnostics/bootstrap exports that do not justify a
    dedicated domain file:
    - `ping`
    - `core_version`
    - `init_logging`
    - `configure_entry_db_path`
    - `log_dart_event`
  - declares the submodule tree and `#[cfg(test)]` test modules
- `query.rs`
  - owns the public guarded query export `query_atoms`
  - owns query-specific request normalization, failure builders, and guarded
    query glue that should not be mixed into feature-specific wrappers
- `creation.rs`
  - owns the public guarded creation export `atom_create`
  - owns creation-specific request normalization, failure builders, and guarded
    creation glue that should not be mixed into legacy note/task/calendar entry
    wrappers
- `workspace.rs`
  - owns guarded workspace exports and wrappers
  - owns workspace-facing local error mapping helpers that are not global FFI
    error translation
  - preserves the split between workspace metadata reads and tree-routed
    designated reassignment
- `support.rs`
  - owns shared guarded wiring helpers and common setup utilities
  - owns shared test support or re-exports the dedicated test-support location
    used by the moduleized FFI tests
- `test_support.rs`
  - owns per-test DB-path isolation, guard-injection helpers, and legacy
    compatibility fixtures
- `errors.rs`
  - owns reusable global FFI error translation only
  - must not absorb workspace-specific action mapping that would blur behavior
    ownership
- `tests/*.rs`
  - split the current giant inline `api.rs` test module by surface while
    preserving the landed test-filter conventions:
    - `legacy_wrapper_`
    - `workspace_`
    - focused `api::tests::*` targeted regressions

## Planned File Changes

- `[delete/replace]` `crates/lazynote_ffi/src/api.rs`
- `[add]` `crates/lazynote_ffi/src/api/mod.rs`
- `[add]` `crates/lazynote_ffi/src/api/entry.rs`
- `[add]` `crates/lazynote_ffi/src/api/notes.rs`
- `[add]` `crates/lazynote_ffi/src/api/query.rs`
- `[add]` `crates/lazynote_ffi/src/api/creation.rs`
- `[add]` `crates/lazynote_ffi/src/api/workspace.rs`
- `[add]` `crates/lazynote_ffi/src/api/tasks.rs`
- `[add]` `crates/lazynote_ffi/src/api/calendar.rs`
- `[add]` `crates/lazynote_ffi/src/api/errors.rs`
- `[add]` `crates/lazynote_ffi/src/api/mappers.rs`
- `[add]` `crates/lazynote_ffi/src/api/support.rs`
- `[add]` `crates/lazynote_ffi/src/api/test_support.rs`
- `[add]` `crates/lazynote_ffi/src/api/tests/mod.rs`
- `[add]` `crates/lazynote_ffi/src/api/tests/legacy.rs`
- `[add]` `crates/lazynote_ffi/src/api/tests/workspace.rs`
- `[add]` `crates/lazynote_ffi/src/api/tests/query_and_creation.rs`
- `[add]` `crates/lazynote_ffi/src/api/tests/entry_notes_tasks_calendar.rs`
- `[conditional regen]` `crates/lazynote_ffi/src/frb_generated.rs`
- `[conditional regen]` `apps/lazynote_flutter/lib/core/bindings/`

## Executable Plan

### Chunk 1: Replace the single-file module with a directory-backed shell

- Move the current `crates/lazynote_ffi/src/api.rs` body into
  `crates/lazynote_ffi/src/api/mod.rs` mechanically first.
- Create `errors.rs`, `mappers.rs`, and `support.rs` before touching domain
  exports so shared ownership is explicit.
- Exit criteria:
  - `cargo test -p lazynote_ffi api::tests::ping_returns_pong -- --exact --nocapture`
  - `cargo test -p lazynote_ffi api::tests::legacy_wrapper_bodies_delegate_to_approved_surfaces -- --exact --nocapture`

### Chunk 2: Split entry, notes, tasks, and calendar surfaces

- Move `query_atoms` into `query.rs` and `atom_create` into `creation.rs`
  before splitting legacy feature wrappers, so the two public guarded exports
  have an explicit production home.
- Move entry/notes exports first, then tasks/calendar exports.
- Preserve:
  - public guarded query/create exports remain easy to audit
  - legacy wrapper parity
  - FTS compatibility for `entry_search`
  - legacy root-scoped task visibility before `PR-0410`
  - notes tag preservation
- Exit criteria:
  - `cargo test -p lazynote_ffi api::tests::query_atoms_returns_scoped_items -- --exact --nocapture`
  - `cargo test -p lazynote_ffi api::tests::atom_create_routes_task_to_designated_folder -- --exact --nocapture`
  - `cargo test -p lazynote_ffi api::tests::legacy_wrapper_entry_search_preserves_fts_snippet_and_order -- --exact --nocapture`
  - `cargo test -p lazynote_ffi api::tests::legacy_wrapper_notes_list_preserves_tags -- --exact --nocapture`
  - `cargo test -p lazynote_ffi api::tests::tasks_list_today_keeps_root_scoped_refs_visible_before_pr_0410 -- --exact --nocapture`

### Chunk 3: Split workspace exports and keep local action mapping local

- Move both legacy workspace tree exports and guarded workspace exports into
  `workspace.rs`.
- Keep workspace-specific local error mapping in `workspace.rs`, not in global
  `errors.rs`.
- Preserve:
  - `workspace_list` readable-subset behavior
  - `workspace_resolve_designated` miss-path distinction
  - `workspace_reassign_designated` tree-routed behavior
- Exit criteria:
  - `cargo test -p lazynote_ffi workspace_ -- --nocapture`
  - `cargo test -p lazynote_ffi api::tests::workspace_list_filters_to_readable_subset_under_guard -- --exact --nocapture`
  - `cargo test -p lazynote_ffi api::tests::workspace_reassign_designated_returns_workspace_not_found_for_unknown_workspace -- --exact --nocapture`

### Chunk 4: Split tests and shared test support

- Move shared fixtures into `test_support.rs`.
- Split the inline test block into `tests/` modules while preserving current
  test name filters and auditability.
- Exit criteria:
  - `cargo test -p lazynote_ffi legacy_wrapper_ -- --nocapture`
  - `cargo test -p lazynote_ffi workspace_ -- --nocapture`

### Chunk 5: Full verification and structural closeout

- Run FRB codegen only as a mechanical check; do not hand-edit generated files.
- Run full Rust, Flutter, and architecture verification.
- Sync the `PR-0411A` spec with the final landed module map and verification
  snapshot.
- Exit criteria:
  - `cargo fmt --all -- --check`
  - `cargo clippy --all -- -D warnings`
  - `cargo test --all`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1`
  - `cd apps/lazynote_flutter && dart format --output=none --set-exit-if-changed .`
  - `cd apps/lazynote_flutter && flutter analyze`
  - `cd apps/lazynote_flutter && flutter test`
  - `dart run tools/ci/architecture_check.dart`

## Verification

```bash
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1
cd apps/lazynote_flutter
flutter analyze
flutter test
cd ../..
dart run tools/ci/architecture_check.dart
```

Targeted regression checks that must still be green after the split:

```bash
cargo test -p lazynote_ffi legacy_wrapper_ -- --nocapture
cargo test -p lazynote_ffi workspace_ -- --nocapture
cargo test -p lazynote_ffi api::tests::query_atoms_returns_scoped_items -- --exact --nocapture
cargo test -p lazynote_ffi api::tests::atom_create_routes_task_to_designated_folder -- --exact --nocapture
cargo test -p lazynote_ffi api::tests::tasks_list_today_keeps_root_scoped_refs_visible_before_pr_0410 -- --exact --nocapture
cargo test -p lazynote_ffi api::tests::workspace_list_filters_to_readable_subset_under_guard -- --exact --nocapture
cargo test -p lazynote_ffi api::tests::legacy_wrapper_entry_search_preserves_fts_snippet_and_order -- --exact --nocapture
```

## Acceptance Criteria

- `api.rs` is decomposed into the target module tree.
- Public FFI contract is unchanged.
- `query_atoms` and `atom_create` are assigned to explicit production modules
  rather than left as implicit `mod.rs` leftovers.
- The landed `PR-0411` internal layering remains explicit:
  - runtime `NoopGuard` paths are still easy to distinguish from
    test-only/custom-guard paths
  - workspace-specific action mapping remains locally owned and auditable
- The landed `PR-0411` workspace-facing behavior is preserved:
  - `workspace_list` filters to readable workspaces
  - `workspace_reassign_designated` remains tree-routed
  - per-test DB isolation continues to protect FFI regression tests from
    cross-test contamination
- The current `api.rs` test inventory is decomposed into `api/tests/` without
  losing the landed filterable regression names or auditability.
- Generated bindings remain valid.
- Rust and Flutter verification gates pass.
- No ADR, ruling, topic-map, or workspace carrier-promotion surfaces are updated
  by this cleanup PR.
