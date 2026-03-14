-- Migration: 0012_workspace_single_root.sql
-- Purpose: add multi-root-capable workspace schema and backfill current data
-- into one default workspace.

-- @phase schema
DROP TRIGGER IF EXISTS workspace_nodes_atom_ref_requires_atom_insert;
DROP TRIGGER IF EXISTS workspace_nodes_atom_ref_requires_atom_update;
DROP TRIGGER IF EXISTS atoms_block_demote_when_referenced;
DROP TRIGGER IF EXISTS atoms_block_delete_when_referenced;

CREATE TABLE workspace_nodes_new (
    node_uuid TEXT PRIMARY KEY NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('folder', 'atom_ref', 'workspace')),
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
        OR (kind = 'workspace' AND atom_uuid IS NULL AND parent_uuid IS NULL)
    ),
    FOREIGN KEY (parent_uuid) REFERENCES workspace_nodes_new(node_uuid),
    FOREIGN KEY (atom_uuid) REFERENCES atoms(uuid)
);

INSERT INTO workspace_nodes_new (
    node_uuid, kind, parent_uuid, atom_uuid,
    display_name, sort_order, is_deleted, created_at, updated_at
)
SELECT
    node_uuid, kind, parent_uuid, atom_uuid,
    display_name, sort_order, is_deleted, created_at, updated_at
FROM workspace_nodes;

DROP TABLE workspace_nodes;
ALTER TABLE workspace_nodes_new RENAME TO workspace_nodes;

CREATE INDEX IF NOT EXISTS idx_workspace_nodes_parent_order
    ON workspace_nodes(parent_uuid, is_deleted, sort_order, node_uuid);
CREATE INDEX IF NOT EXISTS idx_workspace_nodes_atom_uuid
    ON workspace_nodes(atom_uuid);

CREATE TABLE workspaces (
    workspace_id TEXT PRIMARY KEY
        REFERENCES workspace_nodes(node_uuid) DEFERRABLE INITIALLY DEFERRED,
    name TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
);

CREATE UNIQUE INDEX idx_workspaces_default
    ON workspaces(is_default)
    WHERE is_default = 1;

CREATE TABLE designated_folders (
    workspace_id TEXT NOT NULL REFERENCES workspaces(workspace_id),
    role TEXT NOT NULL CHECK (role IN ('inbox', 'tasks', 'calendar')),
    node_uuid TEXT NOT NULL REFERENCES workspace_nodes(node_uuid),
    PRIMARY KEY (workspace_id, role)
);

CREATE UNIQUE INDEX idx_designated_folders_node_uuid
    ON designated_folders(node_uuid);

ALTER TABLE atoms ADD COLUMN origin_workspace_id TEXT
    REFERENCES workspaces(workspace_id);

-- @phase guards
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

CREATE TRIGGER atoms_block_demote_when_referenced
BEFORE UPDATE OF view_hint, is_deleted ON atoms
WHEN OLD.is_deleted = 0
  AND NEW.is_deleted <> 0
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

CREATE TRIGGER protect_workspace_root_reparent
BEFORE UPDATE OF parent_uuid ON workspace_nodes
WHEN OLD.kind = 'workspace'
  AND COALESCE(NEW.parent_uuid, '') <> COALESCE(OLD.parent_uuid, '')
BEGIN
    SELECT RAISE(ABORT, 'workspace root cannot be re-parented');
END;

CREATE TRIGGER protect_workspace_root_kind
BEFORE UPDATE OF kind ON workspace_nodes
WHEN OLD.kind = 'workspace'
  AND NEW.kind <> 'workspace'
BEGIN
    SELECT RAISE(ABORT, 'workspace root kind cannot change');
END;

CREATE TRIGGER protect_non_workspace_root_insert
BEFORE INSERT ON workspace_nodes
WHEN NEW.kind <> 'workspace'
  AND NEW.parent_uuid IS NULL
BEGIN
    SELECT RAISE(ABORT, 'top-level nodes must be workspace roots');
END;

CREATE TRIGGER protect_non_workspace_root_update
BEFORE UPDATE OF kind, parent_uuid ON workspace_nodes
WHEN NEW.kind <> 'workspace'
  AND NEW.parent_uuid IS NULL
BEGIN
    SELECT RAISE(ABORT, 'top-level nodes must be workspace roots');
END;

CREATE TRIGGER sync_workspace_name_from_root_rename
AFTER UPDATE OF display_name ON workspace_nodes
WHEN NEW.kind = 'workspace'
  AND NEW.display_name <> OLD.display_name
BEGIN
    UPDATE workspaces
    SET name = NEW.display_name,
        updated_at = (strftime('%s', 'now') * 1000)
    WHERE workspace_id = NEW.node_uuid;
END;

CREATE TRIGGER protect_designated_folder_soft_delete
BEFORE UPDATE OF is_deleted ON workspace_nodes
WHEN OLD.is_deleted = 0
  AND NEW.is_deleted = 1
  AND EXISTS (
      SELECT 1
      FROM designated_folders
      WHERE node_uuid = OLD.node_uuid
  )
BEGIN
    SELECT RAISE(ABORT, 'designated folder cannot be soft-deleted while designated');
END;

CREATE TRIGGER protect_designated_folder_hard_delete
BEFORE DELETE ON workspace_nodes
WHEN EXISTS (
    SELECT 1
    FROM designated_folders
    WHERE node_uuid = OLD.node_uuid
)
BEGIN
    SELECT RAISE(ABORT, 'designated folder cannot be hard-deleted while designated');
END;

CREATE TRIGGER validate_designated_folder_workspace
BEFORE INSERT ON designated_folders
BEGIN
    SELECT
        CASE
            WHEN (
                WITH RECURSIVE ancestors(node_uuid, parent_uuid) AS (
                    SELECT node_uuid, parent_uuid
                    FROM workspace_nodes
                    WHERE node_uuid = NEW.node_uuid
                      AND kind = 'folder'
                      AND is_deleted = 0
                    UNION ALL
                    SELECT parent.node_uuid, parent.parent_uuid
                    FROM workspace_nodes parent
                    JOIN ancestors child ON parent.node_uuid = child.parent_uuid
                )
                SELECT COUNT(1)
                FROM ancestors
                WHERE node_uuid = NEW.workspace_id
            ) = 0
            THEN RAISE(ABORT, 'designated folder must belong to the same workspace')
        END;
END;

CREATE TRIGGER validate_designated_folder_workspace_update
BEFORE UPDATE OF workspace_id, node_uuid ON designated_folders
BEGIN
    SELECT
        CASE
            WHEN (
                WITH RECURSIVE ancestors(node_uuid, parent_uuid) AS (
                    SELECT node_uuid, parent_uuid
                    FROM workspace_nodes
                    WHERE node_uuid = NEW.node_uuid
                      AND kind = 'folder'
                      AND is_deleted = 0
                    UNION ALL
                    SELECT parent.node_uuid, parent.parent_uuid
                    FROM workspace_nodes parent
                    JOIN ancestors child ON parent.node_uuid = child.parent_uuid
                )
                SELECT COUNT(1)
                FROM ancestors
                WHERE node_uuid = NEW.workspace_id
            ) = 0
            THEN RAISE(ABORT, 'designated folder must belong to the same workspace')
        END;
END;
