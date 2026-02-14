# PR-0203-tree-ffi-contracts

- Proposed title: `feat(ffi): workspace tree API contracts and envelopes`
- Status: Planned

## Goal

Expose tree operations through stable FFI contracts for Flutter workspace UI.

## Scope (v0.2)

In scope:

- use-case-level tree APIs (no SQL internals)
- response envelopes with stable `ok/error_code/message`
- parent-based child listing for lazy explorer rendering
- contract docs and compatibility policy updates

Out of scope:

- streaming watch APIs
- sync-provider specific tree APIs

## Candidate API Set

- `workspace_list_children(parent_node_id?, limit?, cursor?)`
- `workspace_create_folder(parent_node_id?, name)`
- `workspace_create_note_ref(parent_node_id?, atom_id, display_name?)`
- `workspace_rename_node(node_id, new_name)`
- `workspace_move_node(node_id, new_parent_id?, target_order?)`

Rules:

- keep API names use-case oriented
- keep error codes stable and machine-branchable
- support lazy loading pagination contracts

## Step-by-Step

1. Implement FFI wrappers over core tree service.
2. Define typed DTOs in generated Dart bindings.
3. Add unit tests for error-code mapping.
4. Update `docs/api/*` and compatibility policy docs.
5. Regenerate FRB bindings.

## Planned File Changes

- [edit] `crates/lazynote_ffi/src/api.rs`
- [edit] `apps/lazynote_flutter/lib/core/bindings/api.dart` (generated)
- [edit] `apps/lazynote_flutter/lib/core/bindings/frb_generated.dart` (generated)
- [edit] `apps/lazynote_flutter/lib/core/bindings/frb_generated.io.dart` (generated)
- [edit] `docs/api/ffi-contracts.md`
- [add] `docs/api/workspace-tree-contract.md`
- [edit] `docs/api/error-codes.md`
- [edit] `docs/governance/API_COMPATIBILITY.md`

## Verification

- `cd crates && cargo check -p lazynote_ffi`
- `cd crates && cargo test -p lazynote_ffi`
- `cd apps/lazynote_flutter && flutter analyze`

## Acceptance Criteria

- [ ] Tree APIs are callable from Flutter with stable envelopes.
- [ ] Error codes are documented and test-covered.
- [ ] API docs guard passes with updated contracts.

