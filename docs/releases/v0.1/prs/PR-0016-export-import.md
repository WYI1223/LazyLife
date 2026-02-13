# PR-0016-export-import

- Proposed title: `feat(portability): export/import Markdown + JSON + ICS`
- Status: Planned (optimized)

## Goal

Provide baseline portability and local backup/restore for v0.1.

## Scope (v0.1)

In scope:

- export Markdown/JSON/ICS
- import JSON/Markdown/ICS baseline
- post-import index rebuild

Out of scope:

- merge wizard UI
- partial conflict resolution UI
- encrypted backup format

## Optimized Phases

Phase A (Export First):

- implement export modules and tests
- expose export APIs via FFI
- add minimal UI entry

Phase B (Import + Reindex):

- implement import parsers and validation
- implement transactional import + reindex
- add end-to-end tests

## Step-by-Step

1. Define export/import API contract and error mapping.
2. Implement export modules (`markdown/json/ics`) in core.
3. Add export tests (format validity + deterministic output baseline).
4. Expose export FFI APIs and regenerate bindings.
5. Implement import modules with validation guards.
6. Add transactional import flow and rollback behavior on failure.
7. Trigger FTS/index rebuild after successful import.
8. Add import tests (happy path + malformed input + partial failure).
9. Add backup/restore UI page in settings.
10. Update product scope docs.
11. Run full quality gates.

## Planned File Changes

- [add] `crates/lazynote_core/src/export/mod.rs`
- [add] `crates/lazynote_core/src/export/markdown.rs`
- [add] `crates/lazynote_core/src/export/json.rs`
- [add] `crates/lazynote_core/src/export/ics.rs`
- [add] `crates/lazynote_core/src/import/mod.rs`
- [edit] `crates/lazynote_ffi/src/api.rs`
- [add] `apps/lazynote_flutter/lib/features/settings/backup_restore_page.dart`
- [edit] `docs/product/mvp-scope.md`

## Dependencies

- PR0006, PR0007, PR0010, PR0011, PR0012

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `flutter analyze`
- `flutter test`

## Acceptance Criteria

- [ ] Export outputs are valid and re-importable
- [ ] Import is transactional and rebuilds search index
- [ ] Backup/restore entry is available in settings
- [ ] API/product docs updated for user-facing behavior
