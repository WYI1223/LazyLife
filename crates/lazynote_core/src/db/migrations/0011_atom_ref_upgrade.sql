-- Migration: 0011_atom_ref_upgrade.sql
-- Purpose: S4 ruling — upgrade note_ref → atom_ref; allow any atom type in workspace tree.
-- Invariants:
-- - `kind='folder'` must not carry `atom_uuid`.
-- - `kind='atom_ref'` must carry `atom_uuid` and point to an active atom (any view_hint).
-- - All existing note_ref rows are migrated to atom_ref.
-- - Active task/event atoms without workspace references receive root-level atom_ref.
-- - Triggers enforce atom_ref validity for any atom type (not just note).
-- Backward compatibility:
-- - Table rebuild required — SQLite does not support ALTER COLUMN on CHECK constraints.

-- 1. Drop old triggers on workspace_nodes (will be auto-dropped by table rebuild,
--    but explicit drop avoids edge cases).
DROP TRIGGER IF EXISTS workspace_nodes_note_ref_requires_note_insert;
DROP TRIGGER IF EXISTS workspace_nodes_note_ref_requires_note_update;

-- 2. Drop old triggers on atoms that reference workspace_nodes.
DROP TRIGGER IF EXISTS atoms_block_note_demote_when_referenced;
DROP TRIGGER IF EXISTS atoms_block_note_delete_when_referenced;

-- 3. Create new table with atom_ref replacing note_ref.
CREATE TABLE workspace_nodes_new (
    node_uuid TEXT PRIMARY KEY NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('folder', 'atom_ref')),
    parent_uuid TEXT NULL,
    atom_uuid TEXT NULL,
    display_name TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    CHECK (parent_uuid IS NULL OR parent_uuid <> node_uuid),
    CHECK (
        (kind = 'folder' AND atom_uuid IS NULL)
        OR (kind = 'atom_ref' AND atom_uuid IS NOT NULL)
    ),
    FOREIGN KEY (parent_uuid) REFERENCES workspace_nodes_new(node_uuid),
    FOREIGN KEY (atom_uuid) REFERENCES atoms(uuid)
);

-- 4. Migrate data (note_ref → atom_ref).
INSERT INTO workspace_nodes_new (
    node_uuid, kind, parent_uuid, atom_uuid,
    display_name, sort_order, is_deleted, created_at, updated_at
)
SELECT
    node_uuid,
    CASE kind WHEN 'note_ref' THEN 'atom_ref' ELSE kind END,
    parent_uuid, atom_uuid,
    display_name, sort_order, is_deleted, created_at, updated_at
FROM workspace_nodes;

-- 5. Replace table.
DROP TABLE workspace_nodes;
ALTER TABLE workspace_nodes_new RENAME TO workspace_nodes;

-- 6. Rebuild indexes.
CREATE INDEX IF NOT EXISTS idx_workspace_nodes_parent_order
    ON workspace_nodes(parent_uuid, is_deleted, sort_order, node_uuid);
CREATE INDEX IF NOT EXISTS idx_workspace_nodes_atom_uuid
    ON workspace_nodes(atom_uuid);

-- 7. Backfill: create root-level atom_ref for active task/event atoms without references.
WITH missing_atoms AS (
    SELECT
        a.uuid AS atom_uuid,
        COALESCE(NULLIF(TRIM(a.title), ''), 'Untitled') AS display_name,
        ROW_NUMBER() OVER (ORDER BY a.updated_at DESC, a.uuid ASC) AS row_num
    FROM atoms a
    WHERE a.is_deleted = 0
      AND a.view_hint IN ('task', 'event')
      AND NOT EXISTS (
          SELECT 1
          FROM workspace_nodes wn
          WHERE wn.atom_uuid = a.uuid AND wn.is_deleted = 0
      )
),
base_sort AS (
    SELECT COALESCE(MAX(sort_order), -1) AS base_order
    FROM workspace_nodes
    WHERE parent_uuid IS NULL
      AND is_deleted = 0
)
INSERT INTO workspace_nodes (
    node_uuid, kind, parent_uuid, atom_uuid,
    display_name, sort_order, is_deleted, created_at, updated_at
)
SELECT
    lower(
        hex(randomblob(4)) || '-' ||
        hex(randomblob(2)) || '-4' ||
        substr(hex(randomblob(2)), 2) || '-' ||
        substr('89ab', (abs(random()) % 4) + 1, 1) ||
        substr(hex(randomblob(2)), 2) || '-' ||
        hex(randomblob(6))
    ) AS node_uuid,
    'atom_ref' AS kind,
    NULL AS parent_uuid,
    m.atom_uuid,
    m.display_name,
    (b.base_order + m.row_num) AS sort_order,
    0 AS is_deleted,
    (strftime('%s', 'now') * 1000) AS created_at,
    (strftime('%s', 'now') * 1000) AS updated_at
FROM missing_atoms m
CROSS JOIN base_sort b;

-- 8. New trigger: atom_ref INSERT validation (any active atom, not just note).
CREATE TRIGGER workspace_nodes_atom_ref_requires_atom_insert
BEFORE INSERT ON workspace_nodes
WHEN NEW.kind = 'atom_ref'
BEGIN
    SELECT
        CASE
            WHEN (
                SELECT COUNT(1)
                FROM atoms
                WHERE uuid = NEW.atom_uuid
                  AND is_deleted = 0
            ) = 0
            THEN RAISE(ABORT, 'workspace atom_ref atom_uuid must reference an active atom')
        END;
END;

-- 9. New trigger: atom_ref UPDATE validation.
CREATE TRIGGER workspace_nodes_atom_ref_requires_atom_update
BEFORE UPDATE OF kind, atom_uuid ON workspace_nodes
WHEN NEW.kind = 'atom_ref'
BEGIN
    SELECT
        CASE
            WHEN (
                SELECT COUNT(1)
                FROM atoms
                WHERE uuid = NEW.atom_uuid
                  AND is_deleted = 0
            ) = 0
            THEN RAISE(ABORT, 'workspace atom_ref atom_uuid must reference an active atom')
        END;
END;

-- 10. New trigger: block deactivation of any atom referenced by active atom_ref.
CREATE TRIGGER atoms_block_demote_when_referenced
BEFORE UPDATE OF view_hint, is_deleted ON atoms
WHEN OLD.is_deleted = 0
  AND (NEW.is_deleted <> 0)
BEGIN
    SELECT
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM workspace_nodes
                WHERE kind = 'atom_ref'
                  AND atom_uuid = OLD.uuid
                  AND is_deleted = 0
            )
            THEN RAISE(ABORT, 'cannot deactivate atom referenced by active workspace atom_ref')
        END;
END;

-- 11. New trigger: block hard-delete of any atom referenced by active atom_ref.
CREATE TRIGGER atoms_block_delete_when_referenced
BEFORE DELETE ON atoms
WHEN EXISTS (
    SELECT 1
    FROM workspace_nodes
    WHERE kind = 'atom_ref'
      AND atom_uuid = OLD.uuid
      AND is_deleted = 0
)
BEGIN
    SELECT RAISE(ABORT, 'cannot delete atom referenced by active workspace atom_ref');
END;
