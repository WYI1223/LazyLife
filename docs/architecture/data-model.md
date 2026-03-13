# Data Model

## Purpose

This document defines the canonical data model used by LazyNote core. Covers the current schema (v0.1–v0.2) and planned v0.3 schema evolution driven by [S1 Atom 投影语义](rulings/S1-atom-projection.md).

---

## Canonical Entity: Atom

`Atom` is the single storage shape for all projections (note/task/event). There are no separate entity tables. All data lives in `atoms`.

### Atom Six-Layer Container Model (S1 R1)

Atom is not a union type of "note/task/event" — it is a **six-layer generic container**:

| Layer | Fields | Responsibility |
|-------|--------|----------------|
| Identity | `uuid` | Globally unique, immutable |
| Content | `content`, `content_type` (v0.3) | Payload + format declaration |
| Projection | `view_hint` (currently `type`), `task_status` | Rendering hint |
| Time | `start_at`, `end_at`, `recurrence_rule` | Time dimension |
| Metadata | `title` (v0.3), `preview_text`, `preview_image`, `tags` | Index & display |
| Organization | `atom_ref[]` (workspace tree) | Structural filing |

Any Atom can simultaneously have time fields and task_status. `view_hint` is a rendering suggestion, not a type constraint.

### Current Fields (v0.1–v0.2 Schema)

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `uuid` | TEXT | NO | Stable UUIDv4, never reused |
| `type` | TEXT | NO | Rendering hint: `note \| task \| event`. Determines UI form, not list classification. **v0.3: renamed to `view_hint`** (S1 R3) |
| `content` | TEXT | NO | Markdown body (opaque string — Core does not parse) |
| `task_status` | TEXT | YES | `todo \| in_progress \| done \| cancelled`. Applies to all atom types (universal completion). NULL = no status. Setting to `null` demotes the atom. |
| `start_at` | INTEGER | YES | Epoch ms. Meaning depends on time-matrix quadrant. |
| `end_at` | INTEGER | YES | Epoch ms. Meaning depends on time-matrix quadrant. |
| `recurrence_rule` | TEXT | YES | Reserved — RFC 5545 RRULE string (e.g. `FREQ=WEEKLY`). Currently always NULL. |
| `preview_text` | TEXT | YES | Derived first non-empty text line (max 100 chars) |
| `preview_image` | TEXT | YES | Derived first markdown image path |
| `hlc_timestamp` | TEXT | YES | Reserved for CRDT/HLC merge logic |
| `is_deleted` | INTEGER | NO | `0 \| 1` soft-delete flag |
| `created_at` | INTEGER | NO | Epoch ms |
| `updated_at` | INTEGER | NO | Epoch ms |

Code reference: `crates/lazynote_core/src/model/atom.rs`.

### Planned Fields (v0.3 Schema — S1 Rulings)

These fields will be added via new migrations in v0.3:

| Field | Type | Default | S1 Rule | Description |
|-------|------|---------|---------|-------------|
| `title` | TEXT | `''` | R8 | Display name. Application semantics: always non-empty, always plain text. Derivation strategy varies by `content_type`. |
| `content_type` | TEXT | `'markdown'` | R2 | Content format declaration: `markdown \| canvas \| conversation \| plugin:<id>`. Determines editor selection (EditorResolver). |
| `view_hint` | TEXT | — | R3 | Rename of `type` (Migration 10). Auto-derived by Core on create/update: `task_status → task`, time fields → `event`, default → `note`. |
| `cover_image` | TEXT (nullable) | NULL | R10 | User-set cover image. Display priority: `cover_image` > `preview_image` > NULL. **v0.4+ implementation.** |
| `icon` | TEXT (nullable) | NULL | R9 | User-set icon (emoji or icon name). Overrides view_hint default icon. **v0.4+ implementation.** |

**`type` → `view_hint` rename**: The existing `type` column will be renamed to `view_hint` in a v0.3 migration. Semantics remain identical (rendering hint only), but the new name better conveys that it is a derived suggestion, not a type constraint.

**`title` derivation strategy** (by content_type, executed in Rust Core):

| content_type | title source | On content update |
|---|---|---|
| `markdown` | Auto-derived: first non-empty line, strip `#`, truncate 50 chars | Auto re-derive and overwrite |
| `canvas` | User-named, default "Untitled" | Not auto-updated (content is JSON) |
| `conversation` | Auto-derived: first user prompt, truncated | Not auto-updated (preserve first prompt) |

**`content_type` ↔ `view_hint` orthogonality**: `content_type` determines **editor selection** (which EditorPane renders the content). `view_hint` determines **list rendering shape** (icon, card template). The two axes are independent — a `canvas` Atom can have `view_hint = task` if it has `task_status`.

---

## Workspace Tree Entity (v0.2)

`workspace_nodes` stores hierarchy metadata for folders and atom references.

> **Terminology evolution**: v0.2 used "note_ref" exclusively. S1 R5 generalizes this to "atom_ref" — any Atom type (note, task, event, canvas) can have workspace references. Migration 11 (PR-RB-03) upgrades the DB column value from `note_ref` to `atom_ref` and backfills existing rows.

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `node_uuid` | TEXT | NO | Stable workspace-node UUID |
| `kind` | TEXT | NO | `folder \| atom_ref` (migrated from `note_ref` in Migration 11, PR-RB-03) |
| `parent_uuid` | TEXT | YES | Parent workspace node id (`NULL` = root level, i.e. "Uncategorized") |
| `atom_uuid` | TEXT | YES | Required for `atom_ref`; must be `NULL` for `folder` |
| `display_name` | TEXT | NO | Folder: authoritative label. atom_ref: alias (v0.2 frozen, S1 R8 title takes priority) |
| `sort_order` | INTEGER | NO | Backend compatibility ordering key for deterministic storage/replay |
| `is_deleted` | INTEGER | NO | `0 \| 1` soft-delete marker |
| `created_at` | INTEGER | NO | Epoch ms |
| `updated_at` | INTEGER | NO | Epoch ms |

### Tree Invariants

1. `kind='folder'` must not carry `atom_uuid`.
2. `kind='atom_ref'` must carry `atom_uuid`; create/update validates target as any active atom (S1 R5, implemented in PR-RB-03).
3. `parent_uuid` may be `NULL` (root) or reference another `workspace_nodes.node_uuid`.
4. Service layer rejects cycle-producing moves (`A -> ... -> A`).
5. Core child listing order is deterministic for storage/replay: `sort_order ASC, node_uuid ASC`.
6. Atom soft-delete and hard-delete are **blocked** by DB triggers when active `atom_ref` entries reference the atom (Migration 0011). Callers must delete or soft-delete referencing `atom_ref` nodes first.
7. Tree read paths hide soft-deleted `atom_ref` and only surface active references.

Code reference: `crates/lazynote_core/src/repo/tree_repo.rs`, `crates/lazynote_core/src/service/tree_service.rs`.

### atom_ref Multi-Reference Model (S1 R5 + R7)

**Mandatory accompaniment** (S1 R5): Atom creation must always produce at least one `atom_ref`. An Atom without any `atom_ref` is a "dead atom" — invisible in Explorer. Current schema already supports this (`workspace_nodes` has no `UNIQUE(atom_uuid)` constraint).

**Multi-reference semantics** (S1 R7): A single Atom can have multiple `atom_ref` entries (appear in multiple folders). All references are equal — no "primary ref" concept.

| Operation | Behavior |
|-----------|----------|
| Drag atom_ref to another folder | **Move** ref (change `parent_uuid`) |
| Duplicate + drag to target | **Create reference** (new atom_ref pointing to same Atom) |
| Delete ref (not last) | Remove that atom_ref only |
| Delete ref (last one) | atom_ref returns to root (`parent_uuid = NULL`); Atom never becomes orphan |
| Delete Atom | soft-delete Atom (`is_deleted = 1`) + all refs |

### Designated Default Folder Model (S1 R6)

Replaces the earlier "Smart Folder" concept. A designated folder is a **normal folder** that is configured as the default creation target for a specific view:

| Creation context | atom_ref target | Additional behavior |
|---|---|---|
| Right-click inside folder | That folder | — |
| Tasks view create | Tasks designated folder | Auto-set `task_status` |
| Calendar view create | Calendar designated folder | Optionally set time fields |
| Header button (tag selected) | Root level | Auto-apply current tag |
| Header button (no context) | Root level | — |
| Single Entry command | Route to designated folder by command type | Set properties per command |

Configuration: view → folder mapping stored in settings. User-changeable. Not setting a designated folder → atom_ref falls to root level (valid state).

See [S1 R6](rulings/S1-atom-projection.md) for full lifecycle (re-designate, un-designate, delete protection).

### Title/Label Semantics (v0.2 → v0.3 Evolution)

**v0.2 policy** (current):
1. Visible titles in Explorer are projections from Atom data (and draft state in Flutter), not a separately user-managed `note_ref` alias.
2. `workspace_nodes.display_name` remains in schema for forward compatibility, but `atom_ref` rename is frozen.
3. `folder` rename uses `display_name` as authoritative folder label.

**v0.3 evolution** (S1 R8):
1. `atoms.title` becomes the canonical display name field — all views (Tab bar, Explorer, Task list, Calendar) read the same field.
2. `preview_text` reverts to its original role as secondary summary, no longer used as title.
3. `workspace_nodes.display_name` for atom_ref becomes an alias that can override Atom title at the reference level (deferred to v0.4+).

### Explorer Ordering/Move Transition Freeze (v0.2)

This is a UI policy freeze that coexists with the current schema:

1. Explorer move is parent-change-only; same-parent manual reorder is not a user capability.
2. `workspace_move_node(..., target_order?)` is retained for compatibility, but UI move paths use `target_order = null`.
3. Explorer row order policy:
   - root: synthetic `Uncategorized` first, then folders by name ascending (case-insensitive)
   - folder children: `folder` group first, `atom_ref` group second
   - within each group: name ascending (case-insensitive), stable id tie-break
   - `Uncategorized` note rows: by note `updated_at DESC`, then note id tie-break
4. Explorer note rows are title-only (no preview text line in row rendering).

---

## Atom Time-Matrix (v0.1.5+)

Classification for list views is **driven entirely by `start_at`/`end_at` nullability** — not by the `view_hint`/`type` field.

| start_at | end_at | Semantic | UI rendering | Default section |
|----------|--------|----------|--------------|----------------|
| NULL | NULL | Pure note / idea (Timeless) | Plain text | **Inbox** |
| NULL | Value | DDL task — "complete before end_at" | Checkbox + countdown | **Today** (if end_at ≤ today) or **Upcoming** |
| Value | NULL | Ongoing task — "started at start_at, no deadline" | Checkbox + elapsed time | **Today** (if start_at ≤ today) or **Upcoming** |
| Value | Value | Timed event / time block | Time range bar | **Today** (if overlaps today) or **Upcoming** |

**Rule**: `view_hint` decides shape; time-matrix decides position. These two axes are independent (S1 R3/R4).

---

## view_hint Auto-Derivation (S1 R3)

`view_hint` (currently `type`) is auto-derived by Rust Core on create/update. **task_status takes priority**:

| Derivation rule | view_hint |
|---|---|
| Has `task_status` | `task` |
| No `task_status` + has time fields | `event` |
| No `task_status` + no time fields | `note` (default/N/A) |

**Usage scope**: `view_hint` is a rendering hint, not a query dimension:

| Use case | Uses view_hint | Uses field query |
|---|---|---|
| Explorer / search result icon | Yes | — |
| List card rendering template | Yes | — |
| Tasks view filter | — | `task_status IS NOT NULL` |
| Calendar view filter | — | `start_at IS NOT NULL AND end_at IS NOT NULL` |

All query contexts use field-based queries, not view_hint filtering. This ensures consistent Atom visibility across different query entry points.

See [S1 R3–R4](rulings/S1-atom-projection.md) for the full rendering behavior matrix.

---

## Section Query Logic

Let `BOD` = today 00:00:00 (device local, epoch ms), `EOD` = today 23:59:59.

Atoms with `task_status IN ('done', 'cancelled')` are excluded from all sections.

### Inbox

```sql
WHERE start_at IS NULL
  AND end_at IS NULL
  AND (task_status IS NULL OR task_status NOT IN ('done', 'cancelled'))
  AND is_deleted = 0
ORDER BY updated_at DESC, uuid ASC
```

### Today

Any atom "active today" — three OR conditions:

```sql
WHERE is_deleted = 0
  AND (task_status IS NULL OR task_status NOT IN ('done', 'cancelled'))
  AND (
    -- DDL overdue or due today [NULL, Value]
    (end_at IS NOT NULL AND end_at <= :eod AND start_at IS NULL)
    -- Ongoing task already started [Value, NULL]
    OR (start_at IS NOT NULL AND end_at IS NULL AND start_at <= :eod)
    -- Event overlapping today [Value, Value]
    OR (start_at IS NOT NULL AND end_at IS NOT NULL
        AND start_at <= :eod AND end_at >= :bod)
  )
ORDER BY COALESCE(start_at, end_at) ASC, updated_at DESC
```

### Upcoming

Any atom anchored entirely in the future:

```sql
WHERE is_deleted = 0
  AND (task_status IS NULL OR task_status NOT IN ('done', 'cancelled'))
  AND (
    -- Future DDL [NULL, Value]
    (end_at IS NOT NULL AND end_at > :eod AND start_at IS NULL)
    -- Future ongoing [Value, NULL]
    OR (start_at IS NOT NULL AND end_at IS NULL AND start_at > :eod)
    -- Future event [Value, Value]
    OR (start_at IS NOT NULL AND end_at IS NOT NULL AND start_at > :eod)
  )
ORDER BY COALESCE(start_at, end_at) ASC, updated_at DESC
```

---

## Invariants

1. `uuid` is stable, never nil, never reused.
2. `end_at >= start_at` when both are non-null.
3. `is_deleted` is the source of truth for visibility lifecycle.
4. `recurrence_rule` must be NULL or a valid RFC 5545 RRULE string (enforced when logic is activated).
5. **(v0.3)** Every Atom must have at least one `atom_ref` at creation time (S1 R5).
6. **(v0.3)** `title` is application-level non-empty — empty string is only the DB default; service layer always writes a derived or explicit value (S1 R8).

Enforcement: `Atom::validate()`, DB `CHECK` constraints, repository write boundaries.

---

## Relational Schema

| Migration | File | Change |
|-----------|------|--------|
| 1 | `0001_init.sql` | `atoms` table with `type`, content, timestamps, soft-delete |
| 2 | `0002_tags.sql` | `tags`, `atom_tags` junction |
| 3 | `0003_external_mappings.sql` | `external_mappings` for sync linkage |
| 4 | `0004_fts.sql` | `atoms_fts` FTS5 virtual table + sync triggers |
| 5 | `0005_note_preview.sql` | `preview_text`, `preview_image` columns |
| 6 | `0006_time_matrix.sql` | Rename `event_start`→`start_at`, `event_end`→`end_at`; add `recurrence_rule TEXT` |
| 7 | `0007_workspace_tree.sql` | Add `workspace_nodes`, ordering index, and note-ref integrity triggers |
| 8 | `0008_workspace_tree_delete_policy.sql` | Remove atom-side blocking triggers and switch tree visibility to read-time filtering |
| 9 | `0009_workspace_note_ref_backfill.sql` | Backfill root-level `note_ref` for active notes missing active workspace references |
| 10 | `0010_s1_core_fields.sql` | Add `title`, `content_type`; rename `type`→`view_hint`; rebuild FTS5 with title indexing |
| 11 | `0011_atom_ref_upgrade.sql` | `note_ref` → `atom_ref` workspace node kind, task/event backfill, S4 triggers |

**Planned future migrations**:
- `cover_image`, `icon` columns (v0.4+, S1 R9/R10)
- `atom_overlays` table for Block WYSIWYG metadata (S1 R14, v0.4+)
- `atom_comments` table for comment entities (S1 R11, v0.4+)

---

## Search Model

FTS index behavior:

- Indexes `content` and `title` from all non-deleted atoms regardless of `view_hint`.
- FTS5 indexes `title` for improved search relevance (added in Migration 10).
- Search results include notes, tasks, and events in a unified result set.
- Frontend uses `view_hint` to render result rows differently (checkbox badge, time badge, etc.).
- Rank + deterministic tie-break: `updated_at DESC, uuid ASC`.

Code reference: `crates/lazynote_core/src/search/fts.rs`.

---

## ID Policy

- Primary ID: UUID string, generated in Rust Core.
- FFI and UI treat IDs as opaque stable identifiers.

---

## Deletion Policy

- Business-path deletion: soft-delete only (`is_deleted = 1`).
- Search and list APIs exclude `is_deleted = 1` rows.
- Maintenance/purge hard-delete requires a Ruling (see `engineering-standards.md` Rule C).

---

## External Mapping Model

`external_mappings` provides provider linkage for sync:

| Column | Description |
|--------|-------------|
| `provider` | Sync provider name (e.g. `google_calendar`) |
| `external_id` | Provider-side ID |
| `atom_uuid` | Foreign key to `atoms.uuid` |
| `external_version` | Provider version/etag |
| `last_synced_at` | Epoch ms of last sync |

Uniqueness constraints: `(provider, external_id)` and `(provider, atom_uuid)`.

Mapping is **Atom-level** (not atom_ref-level) — a single Atom maps to one external record per provider. atom_ref multi-references do not affect mapping (S6 ruling).

**Three-layer responsibility separation** (S6): Provider (API adapter) → Orchestrator (sync coordination, mapping management) → Mapping persistence (table CRUD). ProviderSpi implementations must not directly access `external_mappings` table. See [S6](rulings/S6-provider-spi-interaction.md).

---

## Known Deferred Work

| Item | Target | Ruling |
|------|--------|--------|
| `type` → `view_hint` rename + auto-derivation | v0.3 | S1 R3 |
| `title` field + derivation logic in Core | v0.3 | S1 R8 |
| `content_type` field | v0.3 | S1 R2 |
| atom_ref mandatory accompaniment | v0.3 (PR-RB-03 done) | S1 R5 |
| Designated default folder model | v0.3 | S1 R6 |
| `icon` field | v0.4+ | S1 R9 |
| `cover_image` field | v0.4+ | S1 R10 |
| `atom_comments` table (independent entity) | v0.4+ | S1 R11 |
| Canvas content_type + spatial document schema | v0.3–v0.4+ | S1 R12 |
| Conversation content_type | v0.4+ | S1 R13 |
| `atom_overlays` sidecar table (Block WYSIWYG metadata) | v0.4+ | S1 R14 |
| NoteItem → AtomListItem DTO unification | v0.3 | S8 |
| `Atom` fields currently public | v0.3: privatize fields, use typed mutation paths | — |
| `hlc_timestamp` reserved | Future: CRDT/HLC merge logic | — |
| `recurrence_rule` logic | v0.3+: RRULE calculation engine | — |

---

## References

- [S1: Atom 投影语义](rulings/S1-atom-projection.md) — canonical ruling for Atom model evolution
- [S4: 创建入口统一](rulings/S4-creation-path-unification.md) — creation path routing
- [S6: Provider SPI 交互](rulings/S6-provider-spi-interaction.md) — external mapping ownership
- `docs/releases/v0.1/prs/PR-0004-atom-model.md`
- `docs/releases/v0.1/prs/PR-0005-sqlite-schema-migrations.md`
- `docs/releases/v0.1/prs/PR-0006-core-crud.md`
- `docs/releases/v0.1/prs/PR-0007-fts5-search.md`
- `docs/releases/v0.1.5/README.md`
