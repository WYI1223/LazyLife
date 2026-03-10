# Note Schema (v0.2 → v0.3 Evolution)

## Purpose

Define the canonical note data shape used by Rust core and exposed through FFI. Notes are one projection of the Atom entity — see [data-model.md](data-model.md) for the unified Atom schema and [S1](rulings-legacy/S1-atom-projection.md) for the full projection semantics.

## Storage Model

Notes are stored in `atoms`. In the current schema, note rows are identified by `type = 'note'` (v0.3: `view_hint = 'note'`). However, `view_hint` is a rendering hint only — list classification is driven by time fields and `task_status`, not by `view_hint` (see [data-model.md § Atom Time-Matrix](data-model.md#atom-time-matrix-v015)).

Core columns used by note flow:

- `uuid` (stable note id)
- `content` (raw markdown source — Core treats as opaque string)
- `title` **(v0.3, S1 R8)**: derived from content first non-empty line, strip `#`, truncate 50 chars. Replaces `preview_text`-as-title usage.
- `preview_text` (derived summary for list card secondary area, max 100 chars — **not** used as title in v0.3+)
- `preview_image` (derived first markdown image path, nullable)
- `updated_at` (ordering and recency)

Tag relationship:

- `tags` table (`name` unique, case-insensitive)
- `atom_tags` bridge (`atom_uuid` → `tags.id`)

Workspace tree relationship:

- `workspace_nodes.kind = 'note_ref'` references atoms via `workspace_nodes.atom_uuid`
- **v0.3 (S1 R5)**: atom_ref is generalized — any Atom type can have workspace references, not just notes. The `kind` column value remains `note_ref` in schema for backward compatibility; semantic scope is broadened.
- **v0.3 (S1 R5)**: Atom creation always produces at least one atom_ref. See [data-model.md § atom_ref Multi-Reference Model](data-model.md#atom_ref-multi-reference-model-s1-r5--r7).

## Contract Rules

1. `note_update` is full replace:
   - caller submits complete markdown `content`
   - previous `content` is fully replaced
2. List ordering is fixed:
   - `updated_at DESC, uuid ASC`
3. Tag normalization:
   - tags are normalized to lowercase on write
   - lookup is case-insensitive
4. `note_set_tags` is atomic full replacement:
   - existing links removed
   - provided tag set inserted in one transaction
5. `notes_list` returns note rows only:
   - no task/event rows in this API
6. **(v0.2)** Tree note refs must target notes only:
   - service/repository reject task/event atoms as `note_ref` targets
   - **(v0.3)** Broadened: atom_ref can target any active Atom (S1 R5)
7. Workspace refs follow hybrid visibility semantics:
   - note delete/type change is not blocked by existing `atom_ref`
   - dangling refs are hidden in tree read paths
   - restoring the note restores visibility of existing refs
8. Title source-of-truth policy:
   - **(v0.2)** note title shown in explorer is a projection from Atom data/draft state
   - **(v0.3, S1 R8)** `atoms.title` is the canonical display name. For `content_type = 'markdown'`, title is auto-derived from content first non-empty line by Rust Core on create/update. All views (Tab bar, Explorer, Task list, Calendar) read `atoms.title`.
   - `workspace_nodes.display_name` for atom_ref is reserved as a per-reference alias (deferred to v0.4+)
   - `folder` rename continues to use `display_name` as authoritative folder label

## Markdown Preview Hook

Hook runs in Rust on note create/update.

Input:

- raw markdown string (`content`)

Derived fields:

- `title` **(v0.3)**: first non-empty line, strip leading `#` and whitespace, truncate to 50 characters
- `preview_image`:
  - extract first markdown image path with regex match (`!\[[^\]]*]\(([^)]+)\)`)
- `preview_text`:
  - remove markdown image/link/symbol syntax
  - normalize whitespace
  - keep first 100 characters

Notes:

- `content` remains source of truth.
- `title` is a derived display field — for `markdown` content_type, it always reflects content first line. Manual override is not supported; user aliases use atom_ref `display_name` instead.
- `preview_*` are denormalized view fields for faster list rendering.

## Pagination Rules

- default `limit = 10`
- max `limit = 50`
- single-tag filter in v0.1: `tag = X`

## Non-Goals (current)

- rich markdown rendering in core (Core treats content as opaque string)
- attachment lifecycle management
- YAML frontmatter parsing
- multi-tag boolean expression filtering

## References

- [data-model.md](data-model.md) — canonical Atom entity and schema
- [S1: Atom 投影语义](rulings-legacy/S1-atom-projection.md) — R8 title, R5 atom_ref
- [S4: 创建入口统一](rulings-legacy/S4-creation-path-unification.md) — creation path routing
