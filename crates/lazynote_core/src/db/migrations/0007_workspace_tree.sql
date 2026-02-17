-- Migration: 0007_workspace_tree.sql
-- Purpose: add hierarchical workspace tree storage for folders and note refs.
-- Invariants:
-- - `kind='folder'` must not carry `atom_uuid`.
-- - `kind='note_ref'` must carry `atom_uuid` and point to an active note atom.
-- - `parent_uuid` links to another workspace node (nullable root).
-- - `is_deleted` is soft-delete marker (0 or 1).
-- Backward compatibility:
-- - additive schema update on top of 0006_time_matrix.sql.

CREATE TABLE workspace_nodes (
    node_uuid TEXT PRIMARY KEY NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('folder', 'note_ref')),
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
        OR (kind = 'note_ref' AND atom_uuid IS NOT NULL)
    ),
    FOREIGN KEY (parent_uuid) REFERENCES workspace_nodes(node_uuid),
    FOREIGN KEY (atom_uuid) REFERENCES atoms(uuid)
);

CREATE INDEX IF NOT EXISTS idx_workspace_nodes_parent_order
    ON workspace_nodes(parent_uuid, is_deleted, sort_order, node_uuid);
CREATE INDEX IF NOT EXISTS idx_workspace_nodes_atom_uuid
    ON workspace_nodes(atom_uuid);

CREATE TRIGGER workspace_nodes_note_ref_requires_note_insert
BEFORE INSERT ON workspace_nodes
WHEN NEW.kind = 'note_ref'
BEGIN
    SELECT
        CASE
            WHEN (
                SELECT COUNT(1)
                FROM atoms
                WHERE uuid = NEW.atom_uuid
                  AND type = 'note'
                  AND is_deleted = 0
            ) = 0
            THEN RAISE(ABORT, 'workspace note_ref atom_uuid must reference an active note atom')
        END;
END;

CREATE TRIGGER workspace_nodes_note_ref_requires_note_update
BEFORE UPDATE OF kind, atom_uuid ON workspace_nodes
WHEN NEW.kind = 'note_ref'
BEGIN
    SELECT
        CASE
            WHEN (
                SELECT COUNT(1)
                FROM atoms
                WHERE uuid = NEW.atom_uuid
                  AND type = 'note'
                  AND is_deleted = 0
            ) = 0
            THEN RAISE(ABORT, 'workspace note_ref atom_uuid must reference an active note atom')
        END;
END;
