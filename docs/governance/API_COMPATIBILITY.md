# API Compatibility Policy

This policy defines compatibility rules for public API surfaces.

Canonical lifecycle/deprecation policy lives at:

- `docs/governance/api-lifecycle-policy.md`

## Public API Surfaces

The following are treated as compatibility-sensitive:

- Rust FFI exports in `crates/lazynote_ffi/src/api.rs`
- Dart-visible FFI models in `apps/lazynote_flutter/lib/core/bindings/api.dart`
- behavior contracts documented in `docs/api/*.md`

Architecture contract docs are also compatibility-sensitive for internal
integration lanes:

- `docs/architecture/extension-kernel.md` (PR-0213 baseline)

## Breaking Changes

A change is considered breaking when any of the following happens:

- rename/remove an exposed FFI function
- change parameter semantics, units, or requiredness
- change return field semantics (including `ok/error_code` behavior)
- remove or repurpose stable error codes
- change Single Entry behavior boundary (`onChanged` vs `Enter/send`)
- add new required (non-optional) request parameters without compatibility fallback

## Allowed Non-Breaking Changes

- additive response fields that preserve existing meaning
- additive error codes
- additive commands behind explicit version docs
- internal refactors without contract change

## Change Process

For compatibility-sensitive changes, PR must include:

1. contract delta in `docs/api/*`
2. tests updated for old/new behavior expectations
3. release note update in `docs/releases/`
4. migration guidance if callers must change

For internal architecture contracts (for example extension kernel contracts),
PRs must include:

1. updated architecture contract doc
2. validation/registry tests for changed invariants
3. release plan status sync in `docs/releases/`

## v0.x Practical Rule

In v0.x (pre-v1.0), FFI contracts and error codes may change with documented rationale in the same PR.
Fast iteration is allowed; silent API drift is not.

Default lifecycle class for newly introduced extension/provider contracts in v0.x is
`experimental` unless explicitly promoted by docs and tests.

Stability guarantee starts at **v1.0**: from v1.0 onward, all changes to public API surfaces are subject
to the full breaking-change process above, including migration guidance and release note updates.

## Planned Type Migrations

### `AtomListResponse` / `AtomListItem` (v0.1.5 → v0.3)

v0.1.5 introduces `AtomListItem` and `AtomListResponse` for tasks section queries. These types
carry full atom metadata (`kind`, `start_at`, `end_at`, `task_status`) that the existing
`EntryListItem` / `NoteItem` types do not.

**Coexistence plan (v0.1.5):**
- New tasks APIs use `AtomListResponse` / `AtomListItem`.
- Existing notes APIs continue to use `NoteItem` / `NotesListResponse`.
- Both type families are available simultaneously.

**Migration completed (v0.3 PR-RB-01):**
- `notes_list` migrated from `NotesListResponse` to `AtomListResponse`.
- `note_create`, `note_update`, `note_get`, `note_set_tags` migrated from `NoteResponse` to `AtomItemResponse`.
- `NoteItem`, `NoteResponse`, `NotesListResponse` removed from FFI crate and hand-written Flutter code.
- `tags_list` response unchanged (`TagsListResponse`).
- Migration rationale: `NoteItem` actively discards time/status fields at FFI boundary; unified `AtomListItem` gives all consumers the full Atom projection. See S8 ruling.

This was a **non-breaking additive change** in v0.1.5 (new types only). The v0.3 PR-RB-01
completed the endpoint unification as documented.

### S1 Core Fields (v0.3 PR-RB-02)

`AtomListItem` and `EntrySearchItem` gain new required fields as part of S1 ruling implementation:

- `title: String` — user-facing title auto-derived from content first line.
- `content_type: String` — content format indicator (currently always `"markdown"`).

Rust Core and FFI model changes:
- `AtomType` enum renamed to `ViewHint` (Rust internal).
- DB column `type` renamed to `view_hint` in Migration 10.
- FFI field `kind` renamed to `view_hint` on `AtomListItem` and `EntrySearchItem`.
- `derive_title()` and `derive_view_hint()` functions auto-derive fields on create/update.

This is a **breaking change** for any code that references `AtomListItem.kind` or `EntrySearchItem.kind` — the field is now `view_hint`. Flutter Dart callers use `.viewHint` after codegen.
Breaking for any code that directly constructs `AtomListItem` or `EntrySearchItem` (Flutter test helpers updated).

### Calendar APIs (PR-0012A)

Two new FFI functions added as **non-breaking additive changes**:

- `calendar_list_by_range(start_ms, end_ms, limit?, offset?) -> AtomListResponse`
- `calendar_update_event(atom_id, start_ms, end_ms) -> EntryActionResponse`

Both reuse existing response types (`AtomListResponse`, `EntryActionResponse`).

New error code: `invalid_time_range` — additive, no impact on existing callers.
