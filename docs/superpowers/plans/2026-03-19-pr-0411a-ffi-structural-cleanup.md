# PR-0411A FFI Structural Cleanup Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `crates/lazynote_ffi/src/api.rs` into a focused module tree after `PR-0411` without changing any public FFI contract, runtime behavior, guard semantics, or expand-stage compatibility behavior.

**Architecture:** Convert the current single-file `api.rs` into `crates/lazynote_ffi/src/api/` with a thin `mod.rs` root that keeps public DTOs and small diagnostics exports, plus focused submodules for entry, notes, tasks, calendar, workspace, shared error mapping, DTO mappers, service wiring, and test support. The split is purely structural: `workspace_list` must still filter readable workspaces, `workspace_reassign_designated` must still route through `GuardedTreeService`, legacy wrappers must remain thin delegates, and generated FRB bindings must only change if codegen mechanically rewrites them.

**Tech Stack:** Rust, Flutter Rust Bridge, `rusqlite`, Markdown spec/plan docs, Cargo test/lint pipeline, Flutter analyze/test validation

---

## File Responsibility Map

- `crates/lazynote_ffi/src/api/mod.rs`
  - Own public FFI DTOs/enums/constants shared across domains.
  - Keep small diagnostics/bootstrap exports that do not justify their own domain module:
    - `ping`
    - `core_version`
    - `init_logging`
    - `configure_entry_db_path`
    - `log_dart_event`
  - Declare submodules and `#[cfg(test)]` test modules.
- `crates/lazynote_ffi/src/api/entry.rs`
  - Own `entry_search`, `entry_create_note`, `entry_create_task`, `entry_schedule`.
  - Keep `entry_search` on the documented FTS compatibility bridge.
- `crates/lazynote_ffi/src/api/notes.rs`
  - Own `note_create`, `note_update`, `note_get`, `notes_list`, `note_set_tags`, `tags_list`.
  - Keep legacy wrapper parity and tags preservation behavior intact.
- `crates/lazynote_ffi/src/api/query.rs`
  - Own the public guarded query export `query_atoms`.
  - Keep query-specific request normalization, failure builders, and guarded query glue out of `mod.rs`.
- `crates/lazynote_ffi/src/api/creation.rs`
  - Own the public guarded creation export `atom_create`.
  - Keep creation-specific request normalization, failure builders, and guarded creation glue out of `mod.rs`.
- `crates/lazynote_ffi/src/api/tasks.rs`
  - Own `tasks_list_inbox`, `tasks_list_today`, `tasks_list_upcoming`, `atom_update_status`, `atoms_list_timed`, `atom_get`.
  - Preserve the pre-`PR-0410` root-scoped compatibility bridge.
- `crates/lazynote_ffi/src/api/calendar.rs`
  - Own `calendar_list_by_range`, `calendar_update_event`.
- `crates/lazynote_ffi/src/api/workspace.rs`
  - Own workspace exports and wrappers:
    - legacy tree mutations/listing
    - guarded workspace exports
    - local workspace action error mapping helpers
  - Preserve `workspace_list` readable-subset behavior.
  - Preserve `workspace_reassign_designated` routing through `GuardedTreeService`.
- `crates/lazynote_ffi/src/api/errors.rs`
  - Own reusable FFI error enums and global error translation helpers only.
  - Must not absorb workspace-specific action mapping that belongs in `workspace.rs`.
- `crates/lazynote_ffi/src/api/mappers.rs`
  - Own DTO/response conversion helpers such as `to_scoped_atom_item`, `to_atom_list_item_from_scoped`, `to_workspace_info`, and `to_entry_search_item_from_hit`.
- `crates/lazynote_ffi/src/api/support.rs`
  - Own shared DB/service wiring helpers:
    - `resolve_entry_db_path`
    - `legacy_default_caller`
    - `with_guarded_*`
    - `with_note_service`
    - `with_tree_service`
  - Keep runtime `NoopGuard` and test-injected custom-guard paths explicit.
- `crates/lazynote_ffi/src/api/test_support.rs`
  - Own shared FFI test fixtures:
    - per-test DB-path isolation
    - guard injection helpers
    - legacy compatibility data builders
- `crates/lazynote_ffi/src/api/tests/`
  - Split the current `api.rs` test block by responsibility:
    - `legacy.rs`
    - `workspace.rs`
    - `query_and_creation.rs`
    - `entry_notes_tasks_calendar.rs`

## Chunk 1: Mechanical Module Shell Without Behavior Change

### Task 1: Move `api.rs` into `api/mod.rs` mechanically

**Files:**
- Create: `crates/lazynote_ffi/src/api/mod.rs`
- Modify: `crates/lazynote_ffi/src/lib.rs`
- Delete/replace: `crates/lazynote_ffi/src/api.rs`
- Test: `crates/lazynote_ffi/src/api/mod.rs`

- [ ] **Step 1: Create `crates/lazynote_ffi/src/api/` and move the current file body into `mod.rs`**

Keep the file logically identical first. Do not start extracting helpers during the same step.

- [ ] **Step 2: Update `crates/lazynote_ffi/src/lib.rs` only as needed for the directory-backed module**

The public module path must remain `lazynote_ffi::api`.

- [ ] **Step 3: Run a small compile-smoke test**

Run: `cargo test -p lazynote_ffi api::tests::ping_returns_pong -- --exact --nocapture`

Expected: PASS, proving the directory-backed module compiles before deeper extraction begins.

### Task 2: Carve out shared modules first

**Files:**
- Create: `crates/lazynote_ffi/src/api/errors.rs`
- Create: `crates/lazynote_ffi/src/api/mappers.rs`
- Create: `crates/lazynote_ffi/src/api/support.rs`
- Modify: `crates/lazynote_ffi/src/api/mod.rs`
- Test: `crates/lazynote_ffi/src/api/mod.rs`

- [ ] **Step 1: Move global error enums and reusable mapping helpers into `errors.rs`**

Target helpers include:
- `GuardedFfiError`
- `NotesFfiError`
- `AtomFfiError`
- shared `map_*_error` helpers that are not workspace-local

- [ ] **Step 2: Move DTO/response translators into `mappers.rs`**

Target helpers include:
- `to_scoped_atom_item`
- `to_atom_list_item_from_scoped`
- `to_entry_search_item_from_hit`
- `to_workspace_info`

- [ ] **Step 3: Move shared service wiring and compatibility helpers into `support.rs`**

Target helpers include:
- `legacy_default_caller`
- `legacy_root_scoped_query`
- `with_guarded_*`
- `with_note_service`
- `with_tree_service`

- [ ] **Step 4: Run focused regressions**

Run:
- `cargo test -p lazynote_ffi api::tests::legacy_wrapper_bodies_delegate_to_approved_surfaces -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::workspace_resolve_designated_returns_workspace_not_found_for_unknown_workspace -- --exact --nocapture`

Expected: PASS, proving shared extraction did not drift wrapper or guarded mapping behavior.

## Chunk 2: Split Entry, Notes, Tasks, And Calendar Surfaces

### Task 3: Move entry and notes exports into domain modules

**Files:**
- Create: `crates/lazynote_ffi/src/api/query.rs`
- Create: `crates/lazynote_ffi/src/api/creation.rs`
- Create: `crates/lazynote_ffi/src/api/entry.rs`
- Create: `crates/lazynote_ffi/src/api/notes.rs`
- Modify: `crates/lazynote_ffi/src/api/mod.rs`
- Test: `crates/lazynote_ffi/src/api/tests/entry_notes_tasks_calendar.rs`

- [ ] **Step 1: Move `query_atoms` and `atom_create` into `query.rs` / `creation.rs`**

Keep the public guarded exports in explicit production modules before touching the legacy feature wrappers.

- [ ] **Step 2: Move entry exports and their inner helpers into `entry.rs`**

Keep `entry_search` on the FTS compatibility path and preserve all existing response envelopes.

- [ ] **Step 3: Move notes exports and their local failure builders into `notes.rs`**

Preserve:
- tag round-trip behavior
- legacy `notes_list` compatibility semantics
- `note_create(..., None)` designated-folder routing

- [ ] **Step 4: Run query/create and entry/notes targeted regressions**

Run:
- `cargo test -p lazynote_ffi api::tests::query_atoms_returns_scoped_items -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::atom_create_routes_task_to_designated_folder -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::legacy_wrapper_entry_search_preserves_fts_snippet_and_order -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::legacy_wrapper_notes_list_preserves_tags -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::note_create_without_parent_routes_atom_ref_to_inbox_designated_folder -- --exact --nocapture`

Expected: PASS

### Task 4: Move tasks and calendar exports into domain modules

**Files:**
- Create: `crates/lazynote_ffi/src/api/tasks.rs`
- Create: `crates/lazynote_ffi/src/api/calendar.rs`
- Modify: `crates/lazynote_ffi/src/api/mod.rs`
- Test: `crates/lazynote_ffi/src/api/tests/entry_notes_tasks_calendar.rs`

- [ ] **Step 1: Move tasks exports into `tasks.rs`**

Preserve:
- `tasks_list_inbox`
- `tasks_list_today`
- `tasks_list_upcoming`
- `atoms_list_timed`
- root-scoped legacy visibility bridge

- [ ] **Step 2: Move calendar exports into `calendar.rs`**

Keep calendar update/list behavior unchanged and preserve envelope/error mapping contracts.

- [ ] **Step 3: Run tasks/calendar targeted regressions**

Run:
- `cargo test -p lazynote_ffi api::tests::tasks_list_today_keeps_root_scoped_refs_visible_before_pr_0410 -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::legacy_wrapper_tasks_list_today_preserves_contract -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::legacy_wrapper_calendar_list_by_range_preserves_contract -- --exact --nocapture`

Expected: PASS

## Chunk 3: Split Workspace Surface And Reorganize Test Support

### Task 5: Move workspace exports and local mapping into `workspace.rs`

**Files:**
- Create: `crates/lazynote_ffi/src/api/workspace.rs`
- Modify: `crates/lazynote_ffi/src/api/mod.rs`
- Test: `crates/lazynote_ffi/src/api/tests/workspace.rs`

- [ ] **Step 1: Move legacy workspace tree exports into `workspace.rs`**

Preserve existing public names and response envelopes for:
- `workspace_list_children`
- `workspace_create_folder`
- `workspace_create_atom_ref`
- `workspace_rename_node`
- `workspace_move_node`
- `workspace_delete_folder`
- legacy `workspace_ancestor_path`

- [ ] **Step 2: Move guarded workspace exports and local action mapping into `workspace.rs`**

Preserve:
- `workspace_list` readable-subset behavior
- `workspace_resolve_designated` distinction between `workspace_not_found` and `designated_role_not_found`
- `workspace_reassign_designated` routing through `GuardedTreeService`
- `workspace_get_ancestor_path`
- `workspace_list_atom_refs_for_atom`

- [ ] **Step 3: Run workspace-focused regressions**

Run:
- `cargo test -p lazynote_ffi workspace_ -- --nocapture`
- `cargo test -p lazynote_ffi api::tests::workspace_list_filters_to_readable_subset_under_guard -- --exact --nocapture`
- `cargo test -p lazynote_ffi api::tests::workspace_reassign_designated_returns_workspace_not_found_for_unknown_workspace -- --exact --nocapture`

Expected: PASS

### Task 6: Split the giant inline test module into focused test modules

**Files:**
- Create: `crates/lazynote_ffi/src/api/test_support.rs`
- Create: `crates/lazynote_ffi/src/api/tests/mod.rs`
- Create: `crates/lazynote_ffi/src/api/tests/legacy.rs`
- Create: `crates/lazynote_ffi/src/api/tests/workspace.rs`
- Create: `crates/lazynote_ffi/src/api/tests/query_and_creation.rs`
- Create: `crates/lazynote_ffi/src/api/tests/entry_notes_tasks_calendar.rs`
- Modify: `crates/lazynote_ffi/src/api/mod.rs`

- [ ] **Step 1: Move shared fixtures into `test_support.rs`**

Keep explicit helpers for:
- per-test DB-path isolation
- custom guard injection
- legacy root-scoped data builders

- [ ] **Step 2: Split tests by behavioral surface**

Keep names stable where practical so existing `cargo test -p lazynote_ffi legacy_wrapper_` and `workspace_` filters still work.

- [ ] **Step 3: Run the split test suites**

Run:
- `cargo test -p lazynote_ffi legacy_wrapper_ -- --nocapture`
- `cargo test -p lazynote_ffi workspace_ -- --nocapture`
- `cargo test -p lazynote_ffi query_atoms_returns_scoped_items -- --nocapture`

Expected: PASS

## Chunk 4: Full Verification, Codegen Check, And Spec Closeout

### Task 7: Regenerate bindings only if module movement changes codegen outputs

**Files:**
- Conditional modify: `crates/lazynote_ffi/src/frb_generated.rs`
- Conditional modify: `apps/lazynote_flutter/lib/core/bindings/`

- [ ] **Step 1: Run FRB codegen**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen_bindings.ps1`

Expected: either no diff or codegen-only diff. Do not hand-edit generated files.

- [ ] **Step 2: Review any generated diff for structural-only impact**

If output changes, confirm it is mechanical and does not alter public surface.

### Task 8: Run full verification and sync closeout docs

**Files:**
- Modify: `docs/releases/v0.4/prs/PR-0411A-ffi-structural-cleanup.md`
- Modify: `docs/superpowers/plans/2026-03-19-pr-0411a-ffi-structural-cleanup.md`
- Test: repo root, `crates/`, `apps/lazynote_flutter/`

- [x] **Step 1: Run Rust verification**

Run:
- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`

- [x] **Step 2: Run Flutter validation**

Run from `apps/lazynote_flutter`:
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

- [x] **Step 3: Run repository architecture validation**

Run from repo root:
- `dart run tools/ci/architecture_check.dart`

Expected: `PASSED — no architecture violations.` A size warning on generated binding files is non-blocking unless it upgrades to failure.

- [x] **Step 4: Sync spec closeout snapshot**

Update the `PR-0411A` spec with:
- implementation snapshot
- verification snapshot
- any final target-structure refinements actually chosen during landing

- [ ] **Step 5: Commit**

```bash
git add -A crates/lazynote_ffi/src/api.rs crates/lazynote_ffi/src/api crates/lazynote_ffi/src/lib.rs crates/lazynote_ffi/src/frb_generated.rs apps/lazynote_flutter/lib/core/bindings docs/releases/v0.4/prs/PR-0411A-ffi-structural-cleanup.md docs/superpowers/plans/2026-03-19-pr-0411a-ffi-structural-cleanup.md
git commit -m "refactor(ffi): split guarded api surface into modules"
```

## Exit Criteria

- `crates/lazynote_ffi/src/api.rs` is fully replaced by a directory-backed `api/` module tree.
- Public FRB function names, signatures, sync/async attributes, and response envelopes remain unchanged.
- `query_atoms` and `atom_create` live in explicit production modules instead of being implicit leftovers in `mod.rs`.
- `workspace_list` still returns the readable subset under guard.
- `workspace_reassign_designated` still routes through `GuardedTreeService`.
- `entry_search` remains on the documented FTS compatibility bridge.
- Per-test DB isolation and guard-injection helpers remain explicit and easy to audit.
- Generated bindings are either unchanged or updated only by codegen.
- Rust, Flutter, and architecture verification gates all pass.
