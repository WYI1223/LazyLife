# PR-0208-workspace-hardening-doc-closure

- Proposed title: `chore(workspace): hardening, regression coverage, and doc closure`
- Status: Planned

## Goal

Close v0.2 with reliability polish, regression tests, and documentation synchronization.

## Scope (v0.2)

In scope:

- race-condition hardening around pane/tab/buffer transitions
- recovery behavior for FFI `db_error` and stale async responses
- integration tests for explorer + split + editor interaction
- docs closure for architecture and API changes

Out of scope:

- recursive split UX (v0.3)
- long-document performance gate (v0.3)

## Step-by-Step

1. Audit async state races in workspace provider.
2. Add integration tests for:
   - pane switching during save
   - tree refresh during open tabs
   - move/rename under active note
3. Harden error recovery UX (`SnackBar + Retry` paths).
4. Update release and architecture docs.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/workspace/*`
- [edit] `apps/lazynote_flutter/lib/features/notes/*`
- [add] `apps/lazynote_flutter/test/workspace_integration_flow_test.dart`
- [edit] `docs/architecture/overview.md`
- [edit] `docs/architecture/note-schema.md`
- [edit] `docs/api/*` (if contract deltas exist)
- [edit] `docs/releases/v0.2/README.md`

## Verification

- `cd crates && cargo test --all`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`
- manual Windows smoke for split/explorer/error-retry paths

## Acceptance Criteria

- [ ] Core workspace interactions are regression-covered.
- [ ] Error handling is actionable and non-destructive.
- [ ] Release docs and API docs match shipped behavior.

