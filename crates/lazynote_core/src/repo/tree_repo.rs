//! Workspace tree repository contracts and SQLite implementation.
//!
//! # Responsibility
//! - Provide persistence APIs for folder/atom_ref workspace hierarchy.
//! - Keep SQL details and ordering behavior inside repository boundary.
//!
//! # Invariants
//! - Only active (`is_deleted=0`) nodes are returned by default.
//! - Child listing is deterministic: `sort_order ASC, node_uuid ASC`.
//! - `atom_ref` targets must point to active atoms (any view_hint).
//! - Workspace roots are the only top-level nodes in latest schema.

use crate::db::migrations::latest_version;
use crate::db::DbError;
use crate::model::atom::{AtomId, ViewHint};
use rusqlite::{params, Connection, OptionalExtension, Row, Transaction, TransactionBehavior};
use std::collections::HashSet;
use std::error::Error;
use std::fmt::{Display, Formatter};
use uuid::Uuid;

/// Stable workspace node identifier.
pub type WorkspaceNodeId = Uuid;

/// Result type used by workspace tree repository operations.
pub type TreeRepoResult<T> = Result<T, TreeRepoError>;

/// Errors from workspace tree repository operations.
#[derive(Debug)]
pub enum TreeRepoError {
    /// Underlying SQLite/bootstrap error.
    Db(DbError),
    /// Target workspace node does not exist or is soft-deleted.
    NodeNotFound(WorkspaceNodeId),
    /// Target workspace node exists but is not folder kind.
    NodeNotFolder(WorkspaceNodeId),
    /// Connection schema is not at the expected migrated version.
    UninitializedConnection {
        expected_version: u32,
        actual_version: u32,
    },
    /// Required table is missing.
    MissingRequiredTable(&'static str),
    /// Required column is missing from expected table.
    MissingRequiredColumn {
        table: &'static str,
        column: &'static str,
    },
    /// Persisted data cannot be converted to valid read model.
    InvalidData(String),
    /// Root level is reserved for workspace roots after migration 0012.
    CannotMoveToRoot(WorkspaceNodeId),
}

impl Display for TreeRepoError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Db(err) => write!(f, "{err}"),
            Self::NodeNotFound(id) => write!(f, "workspace node not found: {id}"),
            Self::NodeNotFolder(id) => write!(f, "workspace node is not a folder: {id}"),
            Self::UninitializedConnection {
                expected_version,
                actual_version,
            } => write!(
                f,
                "workspace repository requires schema version {expected_version}, got {actual_version}"
            ),
            Self::MissingRequiredTable(table) => {
                write!(f, "workspace repository requires table `{table}`")
            }
            Self::MissingRequiredColumn { table, column } => write!(
                f,
                "workspace repository requires column `{column}` in table `{table}`"
            ),
            Self::InvalidData(message) => write!(f, "invalid workspace data: {message}"),
            Self::CannotMoveToRoot(node_uuid) => {
                write!(f, "workspace node cannot move to root level: {node_uuid}")
            }
        }
    }
}

impl Error for TreeRepoError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Db(err) => Some(err),
            Self::NodeNotFound(_) => None,
            Self::NodeNotFolder(_) => None,
            Self::UninitializedConnection { .. } => None,
            Self::MissingRequiredTable(_) => None,
            Self::MissingRequiredColumn { .. } => None,
            Self::InvalidData(_) => None,
            Self::CannotMoveToRoot(_) => None,
        }
    }
}

impl From<DbError> for TreeRepoError {
    fn from(value: DbError) -> Self {
        Self::Db(value)
    }
}

impl From<rusqlite::Error> for TreeRepoError {
    fn from(value: rusqlite::Error) -> Self {
        Self::Db(DbError::Sqlite(value))
    }
}

/// Workspace tree node kind.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WorkspaceNodeKind {
    /// Top-level workspace root that can contain folders and atom refs.
    Workspace,
    /// Grouping node that can contain child nodes.
    Folder,
    /// Link node pointing to one atom (any type: note, task, event).
    AtomRef,
}

/// Workspace tree read model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceNode {
    /// Stable workspace node id.
    pub node_uuid: WorkspaceNodeId,
    /// Node type.
    pub kind: WorkspaceNodeKind,
    /// Parent node id. `None` means workspace-root node.
    pub parent_uuid: Option<WorkspaceNodeId>,
    /// Target atom id for note references.
    pub atom_uuid: Option<AtomId>,
    /// User-facing label.
    pub display_name: String,
    /// Stable child order key within one parent.
    pub sort_order: i64,
    /// Soft-delete marker.
    pub is_deleted: bool,
    /// Epoch ms creation timestamp.
    pub created_at: i64,
    /// Epoch ms update timestamp.
    pub updated_at: i64,
}

/// One active workspace location for an atom_ref.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomRefLocation {
    /// Stable atom_ref node identifier.
    pub node_uuid: WorkspaceNodeId,
    /// Workspace root that owns this ref subtree.
    pub workspace_id: WorkspaceNodeId,
    /// Slash-joined folder path beneath the workspace root.
    pub path: String,
    /// User-facing display name stored on the atom_ref node.
    pub display_name: String,
}

/// Repository interface for workspace tree operations.
pub trait TreeRepository {
    /// Creates one folder node.
    fn create_folder(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        display_name: &str,
    ) -> TreeRepoResult<WorkspaceNode>;
    /// Creates one atom_ref node.
    fn create_atom_ref(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        atom_uuid: AtomId,
        display_name: &str,
    ) -> TreeRepoResult<WorkspaceNode>;
    /// Loads one node by id.
    fn get_node(
        &self,
        node_uuid: WorkspaceNodeId,
        include_deleted: bool,
    ) -> TreeRepoResult<Option<WorkspaceNode>>;
    /// Lists children under one parent.
    fn list_children(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        include_deleted: bool,
    ) -> TreeRepoResult<Vec<WorkspaceNode>>;
    /// Renames one node.
    fn rename_node(&self, node_uuid: WorkspaceNodeId, display_name: &str) -> TreeRepoResult<()>;
    /// Moves one node to another parent and optional target order.
    fn move_node(
        &self,
        node_uuid: WorkspaceNodeId,
        new_parent_uuid: Option<WorkspaceNodeId>,
        target_order: Option<i64>,
    ) -> TreeRepoResult<()>;
    /// Deletes one folder by dissolving it into root-level children.
    fn delete_folder_dissolve(&self, folder_uuid: WorkspaceNodeId) -> TreeRepoResult<()>;
    /// Deletes one folder subtree and conditionally soft-deletes note atoms.
    fn delete_folder_delete_all(&self, folder_uuid: WorkspaceNodeId) -> TreeRepoResult<()>;
    /// Loads atom type for active atom, if present.
    fn atom_view_hint(&self, atom_uuid: AtomId) -> TreeRepoResult<Option<ViewHint>>;

    /// Returns ancestor segments from workspace root to direct parent for one node.
    fn get_ancestor_path(
        &self,
        node_uuid: WorkspaceNodeId,
    ) -> TreeRepoResult<Vec<(WorkspaceNodeId, String)>>;

    /// Returns every active atom_ref location for one atom.
    fn list_atom_refs_for_atom(&self, atom_uuid: AtomId) -> TreeRepoResult<Vec<AtomRefLocation>>;

    /// Returns ancestor folder display_names from root to direct parent
    /// for the first active `atom_ref` of the given atom.
    ///
    /// When multiple `atom_ref` nodes exist for the same atom, the one with
    /// the smallest `(sort_order, node_uuid)` is selected (deterministic).
    /// Root-level `atom_ref` (no parent folder) returns an empty `Vec`.
    fn ancestor_path(&self, atom_uuid: AtomId) -> TreeRepoResult<Vec<String>>;
}

/// SQLite-backed workspace tree repository.
pub struct SqliteTreeRepository<'conn> {
    conn: &'conn Connection,
}

impl<'conn> SqliteTreeRepository<'conn> {
    /// Creates repository from migrated connection.
    pub fn try_new(conn: &'conn Connection) -> TreeRepoResult<Self> {
        ensure_tree_connection_ready(conn)?;
        Ok(Self { conn })
    }
}

impl TreeRepository for SqliteTreeRepository<'_> {
    fn create_folder(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        display_name: &str,
    ) -> TreeRepoResult<WorkspaceNode> {
        let effective_parent_uuid = resolve_effective_parent_uuid(self.conn, parent_uuid)?;
        let node_uuid = Uuid::new_v4();
        let sort_order = next_sort_order(self.conn, Some(effective_parent_uuid))?;
        self.conn.execute(
            "INSERT INTO workspace_nodes (
                node_uuid,
                kind,
                parent_uuid,
                atom_uuid,
                display_name,
                sort_order,
                is_deleted
            ) VALUES (?1, 'folder', ?2, NULL, ?3, ?4, 0);",
            params![
                node_uuid.to_string(),
                effective_parent_uuid.to_string(),
                display_name,
                sort_order,
            ],
        )?;
        load_required_node(self.conn, node_uuid)
    }

    fn create_atom_ref(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        atom_uuid: AtomId,
        display_name: &str,
    ) -> TreeRepoResult<WorkspaceNode> {
        let effective_parent_uuid = resolve_effective_parent_uuid(self.conn, parent_uuid)?;
        let node_uuid = Uuid::new_v4();
        let sort_order = next_sort_order(self.conn, Some(effective_parent_uuid))?;
        self.conn.execute(
            "INSERT INTO workspace_nodes (
                node_uuid,
                kind,
                parent_uuid,
                atom_uuid,
                display_name,
                sort_order,
                is_deleted
            ) VALUES (?1, 'atom_ref', ?2, ?3, ?4, ?5, 0);",
            params![
                node_uuid.to_string(),
                effective_parent_uuid.to_string(),
                atom_uuid.to_string(),
                display_name,
                sort_order,
            ],
        )?;
        load_required_node(self.conn, node_uuid)
    }

    fn get_node(
        &self,
        node_uuid: WorkspaceNodeId,
        include_deleted: bool,
    ) -> TreeRepoResult<Option<WorkspaceNode>> {
        let sql = if include_deleted {
            "SELECT
                node_uuid,
                kind,
                parent_uuid,
                atom_uuid,
                display_name,
                sort_order,
                is_deleted,
                created_at,
                updated_at
             FROM workspace_nodes
             WHERE node_uuid = ?1;"
        } else {
            "SELECT
                n.node_uuid AS node_uuid,
                n.kind AS kind,
                n.parent_uuid AS parent_uuid,
                n.atom_uuid AS atom_uuid,
                n.display_name AS display_name,
                n.sort_order AS sort_order,
                n.is_deleted AS is_deleted,
                n.created_at AS created_at,
                n.updated_at AS updated_at
             FROM workspace_nodes n
             LEFT JOIN atoms a ON a.uuid = n.atom_uuid
             WHERE n.node_uuid = ?1
               AND n.is_deleted = 0
               AND (
                 n.kind IN ('folder', 'workspace')
                 OR (n.kind = 'atom_ref' AND a.is_deleted = 0)
               );"
        };
        let mut stmt = self.conn.prepare(sql)?;
        let mut rows = stmt.query([node_uuid.to_string()])?;
        if let Some(row) = rows.next()? {
            return Ok(Some(parse_workspace_node_row(row)?));
        }
        Ok(None)
    }

    fn list_children(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        include_deleted: bool,
    ) -> TreeRepoResult<Vec<WorkspaceNode>> {
        let sql = match (parent_uuid.is_some(), include_deleted) {
            (true, true) => {
                "SELECT
                    node_uuid,
                    kind,
                    parent_uuid,
                    atom_uuid,
                    display_name,
                    sort_order,
                    is_deleted,
                    created_at,
                    updated_at
                 FROM workspace_nodes
                 WHERE parent_uuid = ?1
                 ORDER BY sort_order ASC, node_uuid ASC;"
            }
            (false, true) => {
                "SELECT
                    node_uuid,
                    kind,
                    parent_uuid,
                    atom_uuid,
                    display_name,
                    sort_order,
                    is_deleted,
                    created_at,
                    updated_at
                 FROM workspace_nodes
                 WHERE parent_uuid IS NULL
                 ORDER BY sort_order ASC, node_uuid ASC;"
            }
            (true, false) => {
                "SELECT
                    n.node_uuid AS node_uuid,
                    n.kind AS kind,
                    n.parent_uuid AS parent_uuid,
                    n.atom_uuid AS atom_uuid,
                    n.display_name AS display_name,
                    n.sort_order AS sort_order,
                    n.is_deleted AS is_deleted,
                    n.created_at AS created_at,
                    n.updated_at AS updated_at
                 FROM workspace_nodes n
                 LEFT JOIN atoms a ON a.uuid = n.atom_uuid
                 WHERE n.parent_uuid = ?1
                   AND n.is_deleted = 0
                   AND (
                     n.kind IN ('folder', 'workspace')
                     OR (n.kind = 'atom_ref' AND a.is_deleted = 0)
                   )
                 ORDER BY n.sort_order ASC, n.node_uuid ASC;"
            }
            (false, false) => {
                "SELECT
                    n.node_uuid AS node_uuid,
                    n.kind AS kind,
                    n.parent_uuid AS parent_uuid,
                    n.atom_uuid AS atom_uuid,
                    n.display_name AS display_name,
                    n.sort_order AS sort_order,
                    n.is_deleted AS is_deleted,
                    n.created_at AS created_at,
                    n.updated_at AS updated_at
                 FROM workspace_nodes n
                 LEFT JOIN atoms a ON a.uuid = n.atom_uuid
                 WHERE n.parent_uuid IS NULL
                   AND n.is_deleted = 0
                   AND n.kind = 'workspace'
                 ORDER BY n.sort_order ASC, n.node_uuid ASC;"
            }
        };

        let mut stmt = self.conn.prepare(sql)?;
        let mut rows = match parent_uuid {
            Some(parent_uuid) => stmt.query([parent_uuid.to_string()])?,
            None => stmt.query([])?,
        };

        let mut items = Vec::new();
        while let Some(row) = rows.next()? {
            items.push(parse_workspace_node_row(row)?);
        }
        Ok(items)
    }

    fn rename_node(&self, node_uuid: WorkspaceNodeId, display_name: &str) -> TreeRepoResult<()> {
        let tx = Transaction::new_unchecked(self.conn, TransactionBehavior::Immediate)?;
        let kind: Option<String> = tx
            .query_row(
                "SELECT kind
                 FROM workspace_nodes
                 WHERE node_uuid = ?1
                   AND is_deleted = 0;",
                [node_uuid.to_string()],
                |row| row.get(0),
            )
            .optional()?;
        let Some(kind) = kind else {
            return Err(TreeRepoError::NodeNotFound(node_uuid));
        };

        tx.execute(
            "UPDATE workspace_nodes
             SET display_name = ?2,
                 updated_at = (strftime('%s', 'now') * 1000)
             WHERE node_uuid = ?1
               AND is_deleted = 0;",
            params![node_uuid.to_string(), display_name],
        )?;
        if kind == "workspace" {
            tx.execute(
                "UPDATE workspaces
                 SET name = ?2,
                     updated_at = (strftime('%s', 'now') * 1000)
                 WHERE workspace_id = ?1;",
                params![node_uuid.to_string(), display_name],
            )?;
        }
        tx.commit()?;
        Ok(())
    }

    fn move_node(
        &self,
        node_uuid: WorkspaceNodeId,
        new_parent_uuid: Option<WorkspaceNodeId>,
        target_order: Option<i64>,
    ) -> TreeRepoResult<()> {
        if self.get_node(node_uuid, false)?.is_none() {
            return Err(TreeRepoError::NodeNotFound(node_uuid));
        }
        if new_parent_uuid.is_none() {
            return Err(TreeRepoError::CannotMoveToRoot(node_uuid));
        }

        let tx = Transaction::new_unchecked(self.conn, TransactionBehavior::Immediate)?;
        let mut sibling_ids = list_visible_child_ids(&tx, new_parent_uuid)?;
        sibling_ids.retain(|id| *id != node_uuid);

        let target_index = target_order
            .unwrap_or(sibling_ids.len() as i64)
            .clamp(0, sibling_ids.len() as i64) as usize;
        sibling_ids.insert(target_index, node_uuid);

        tx.execute(
            "UPDATE workspace_nodes
             SET parent_uuid = ?2,
                 updated_at = (strftime('%s', 'now') * 1000)
             WHERE node_uuid = ?1
               AND is_deleted = 0;",
            params![
                node_uuid.to_string(),
                new_parent_uuid.map(|value| value.to_string()),
            ],
        )?;

        for (index, id) in sibling_ids.into_iter().enumerate() {
            tx.execute(
                "UPDATE workspace_nodes
                 SET sort_order = ?2,
                     updated_at = (strftime('%s', 'now') * 1000)
                 WHERE node_uuid = ?1
                   AND is_deleted = 0;",
                params![id.to_string(), index as i64],
            )?;
        }

        tx.commit()?;
        Ok(())
    }

    fn delete_folder_dissolve(&self, folder_uuid: WorkspaceNodeId) -> TreeRepoResult<()> {
        let tx = Transaction::new_unchecked(self.conn, TransactionBehavior::Immediate)?;
        ensure_active_folder_exists(&tx, folder_uuid)?;

        let children = list_active_child_ids(&tx, Some(folder_uuid))?;
        let workspace_root_uuid = resolve_workspace_root_for_node(&tx, folder_uuid)?;
        let base_order = next_sort_order(&tx, Some(workspace_root_uuid))?;
        for (index, child_uuid) in children.into_iter().enumerate() {
            tx.execute(
                "UPDATE workspace_nodes
                 SET parent_uuid = ?3,
                     sort_order = ?2,
                     updated_at = (strftime('%s', 'now') * 1000)
                 WHERE node_uuid = ?1
                   AND is_deleted = 0;",
                params![
                    child_uuid.to_string(),
                    base_order + index as i64,
                    workspace_root_uuid.to_string(),
                ],
            )?;
        }

        tx.execute(
            "UPDATE workspace_nodes
             SET is_deleted = 1,
                 updated_at = (strftime('%s', 'now') * 1000)
             WHERE node_uuid = ?1
               AND kind = 'folder'
               AND is_deleted = 0;",
            [folder_uuid.to_string()],
        )?;

        tx.commit()?;
        Ok(())
    }

    fn delete_folder_delete_all(&self, folder_uuid: WorkspaceNodeId) -> TreeRepoResult<()> {
        let tx = Transaction::new_unchecked(self.conn, TransactionBehavior::Immediate)?;
        ensure_active_folder_exists(&tx, folder_uuid)?;

        let referenced_atoms = list_referenced_atoms_in_subtree(&tx, folder_uuid)?;
        soft_delete_workspace_subtree(&tx, folder_uuid)?;

        for atom_uuid in referenced_atoms {
            let has_other_active_refs: i64 = tx.query_row(
                "SELECT EXISTS(
                    SELECT 1
                    FROM workspace_nodes
                    WHERE kind = 'atom_ref'
                      AND atom_uuid = ?1
                      AND is_deleted = 0
                );",
                [atom_uuid.to_string()],
                |row| row.get(0),
            )?;
            if has_other_active_refs == 1 {
                continue;
            }

            tx.execute(
                "UPDATE atoms
                 SET is_deleted = 1,
                     updated_at = (strftime('%s', 'now') * 1000)
                 WHERE uuid = ?1
                   AND is_deleted = 0;",
                [atom_uuid.to_string()],
            )?;
        }

        tx.commit()?;
        Ok(())
    }

    fn atom_view_hint(&self, atom_uuid: AtomId) -> TreeRepoResult<Option<ViewHint>> {
        let value: Option<String> = self
            .conn
            .query_row(
                "SELECT view_hint
                 FROM atoms
                 WHERE uuid = ?1
                   AND is_deleted = 0;",
                [atom_uuid.to_string()],
                |row| row.get(0),
            )
            .optional()?;

        match value.as_deref() {
            None => Ok(None),
            Some("note") => Ok(Some(ViewHint::Note)),
            Some("task") => Ok(Some(ViewHint::Task)),
            Some("event") => Ok(Some(ViewHint::Event)),
            Some(other) => Err(TreeRepoError::InvalidData(format!(
                "invalid view_hint `{other}` in atoms.view_hint"
            ))),
        }
    }

    fn get_ancestor_path(
        &self,
        node_uuid: WorkspaceNodeId,
    ) -> TreeRepoResult<Vec<(WorkspaceNodeId, String)>> {
        collect_ancestor_nodes(self.conn, node_uuid).map(|segments| {
            segments
                .into_iter()
                .map(|segment| (segment.node_uuid, segment.display_name))
                .collect()
        })
    }

    fn list_atom_refs_for_atom(&self, atom_uuid: AtomId) -> TreeRepoResult<Vec<AtomRefLocation>> {
        let mut stmt = self.conn.prepare(
            "SELECT node_uuid, display_name
             FROM workspace_nodes
             WHERE kind = 'atom_ref'
               AND atom_uuid = ?1
               AND is_deleted = 0
             ORDER BY node_uuid ASC;",
        )?;
        let mut rows = stmt.query([atom_uuid.to_string()])?;
        let mut locations = Vec::new();

        while let Some(row) = rows.next()? {
            let node_uuid_text: String = row.get(0)?;
            let node_uuid = parse_uuid(&node_uuid_text, "workspace_nodes.node_uuid")?;
            let display_name: String = row.get(1)?;
            let ancestors = collect_ancestor_nodes(self.conn, node_uuid)?;
            let workspace_id = ancestors
                .iter()
                .find(|segment| segment.kind == WorkspaceNodeKind::Workspace)
                .map(|segment| segment.node_uuid)
                .ok_or_else(|| {
                    TreeRepoError::InvalidData(format!(
                        "workspace root not found for atom_ref `{node_uuid}`"
                    ))
                })?;
            let path = ancestors
                .iter()
                .filter(|segment| segment.kind == WorkspaceNodeKind::Folder)
                .map(|segment| segment.display_name.as_str())
                .collect::<Vec<_>>()
                .join("/");

            locations.push(AtomRefLocation {
                node_uuid,
                workspace_id,
                path,
                display_name,
            });
        }

        locations.sort_by(|left, right| {
            left.workspace_id
                .cmp(&right.workspace_id)
                .then_with(|| left.path.cmp(&right.path))
                .then_with(|| left.display_name.cmp(&right.display_name))
                .then_with(|| left.node_uuid.cmp(&right.node_uuid))
        });
        Ok(locations)
    }

    fn ancestor_path(&self, atom_uuid: AtomId) -> TreeRepoResult<Vec<String>> {
        let first_ref_uuid: Option<String> = self
            .conn
            .query_row(
                "SELECT node_uuid
                 FROM workspace_nodes
                 WHERE atom_uuid = ?1
                   AND kind = 'atom_ref'
                   AND is_deleted = 0
                 ORDER BY sort_order ASC, node_uuid ASC
                 LIMIT 1;",
                [atom_uuid.to_string()],
                |row| row.get(0),
            )
            .optional()?;
        let Some(first_ref_uuid) = first_ref_uuid else {
            return Ok(vec![]);
        };
        let first_ref_uuid = parse_uuid(&first_ref_uuid, "workspace_nodes.node_uuid")?;
        let segments = collect_ancestor_nodes(self.conn, first_ref_uuid)?;
        Ok(segments
            .into_iter()
            .filter(|segment| segment.kind == WorkspaceNodeKind::Folder)
            .map(|segment| segment.display_name)
            .collect())
    }
}

#[derive(Debug, Clone)]
struct AncestorNode {
    node_uuid: WorkspaceNodeId,
    kind: WorkspaceNodeKind,
    display_name: String,
}

fn load_required_node(
    conn: &Connection,
    node_uuid: WorkspaceNodeId,
) -> TreeRepoResult<WorkspaceNode> {
    let mut stmt = conn.prepare(
        "SELECT
            node_uuid,
            kind,
            parent_uuid,
            atom_uuid,
            display_name,
            sort_order,
            is_deleted,
            created_at,
            updated_at
         FROM workspace_nodes
         WHERE node_uuid = ?1
           AND is_deleted = 0;",
    )?;
    let mut rows = stmt.query([node_uuid.to_string()])?;
    if let Some(row) = rows.next()? {
        return parse_workspace_node_row(row);
    }
    Err(TreeRepoError::NodeNotFound(node_uuid))
}

fn list_active_child_ids(
    conn: &Connection,
    parent_uuid: Option<WorkspaceNodeId>,
) -> TreeRepoResult<Vec<WorkspaceNodeId>> {
    let mut ids = Vec::new();
    if let Some(parent_uuid) = parent_uuid {
        let mut stmt = conn.prepare(
            "SELECT node_uuid
             FROM workspace_nodes
             WHERE parent_uuid = ?1
               AND is_deleted = 0
             ORDER BY sort_order ASC, node_uuid ASC;",
        )?;
        let mut rows = stmt.query([parent_uuid.to_string()])?;
        while let Some(row) = rows.next()? {
            let value: String = row.get(0)?;
            ids.push(parse_uuid(&value, "workspace_nodes.node_uuid")?);
        }
    } else {
        let mut stmt = conn.prepare(
            "SELECT node_uuid
             FROM workspace_nodes
             WHERE parent_uuid IS NULL
               AND is_deleted = 0
             ORDER BY sort_order ASC, node_uuid ASC;",
        )?;
        let mut rows = stmt.query([])?;
        while let Some(row) = rows.next()? {
            let value: String = row.get(0)?;
            ids.push(parse_uuid(&value, "workspace_nodes.node_uuid")?);
        }
    }
    Ok(ids)
}

fn list_visible_child_ids(
    conn: &Connection,
    parent_uuid: Option<WorkspaceNodeId>,
) -> TreeRepoResult<Vec<WorkspaceNodeId>> {
    let mut ids = Vec::new();
    if let Some(parent_uuid) = parent_uuid {
        let mut stmt = conn.prepare(
            "SELECT n.node_uuid
             FROM workspace_nodes n
             LEFT JOIN atoms a ON a.uuid = n.atom_uuid
             WHERE n.parent_uuid = ?1
               AND n.is_deleted = 0
               AND (
                 n.kind IN ('folder', 'workspace')
                 OR (n.kind = 'atom_ref' AND a.is_deleted = 0)
               )
             ORDER BY n.sort_order ASC, n.node_uuid ASC;",
        )?;
        let mut rows = stmt.query([parent_uuid.to_string()])?;
        while let Some(row) = rows.next()? {
            let value: String = row.get(0)?;
            ids.push(parse_uuid(&value, "workspace_nodes.node_uuid")?);
        }
    } else {
        let mut stmt = conn.prepare(
            "SELECT n.node_uuid
             FROM workspace_nodes n
             WHERE n.parent_uuid IS NULL
               AND n.is_deleted = 0
               AND n.kind = 'workspace'
             ORDER BY n.sort_order ASC, n.node_uuid ASC;",
        )?;
        let mut rows = stmt.query([])?;
        while let Some(row) = rows.next()? {
            let value: String = row.get(0)?;
            ids.push(parse_uuid(&value, "workspace_nodes.node_uuid")?);
        }
    }
    Ok(ids)
}

fn next_sort_order(conn: &Connection, parent_uuid: Option<WorkspaceNodeId>) -> TreeRepoResult<i64> {
    let next = if let Some(parent_uuid) = parent_uuid {
        conn.query_row(
            "SELECT COALESCE(MAX(sort_order), -1) + 1
             FROM workspace_nodes
             WHERE parent_uuid = ?1
               AND is_deleted = 0;",
            [parent_uuid.to_string()],
            |row| row.get(0),
        )?
    } else {
        conn.query_row(
            "SELECT COALESCE(MAX(sort_order), -1) + 1
             FROM workspace_nodes
             WHERE parent_uuid IS NULL
               AND kind = 'workspace'
               AND is_deleted = 0;",
            [],
            |row| row.get(0),
        )?
    };
    Ok(next)
}

fn ensure_active_folder_exists(
    conn: &Connection,
    folder_uuid: WorkspaceNodeId,
) -> TreeRepoResult<()> {
    let kind: Option<String> = conn
        .query_row(
            "SELECT kind
             FROM workspace_nodes
             WHERE node_uuid = ?1
               AND is_deleted = 0;",
            [folder_uuid.to_string()],
            |row| row.get(0),
        )
        .optional()?;

    match kind.as_deref() {
        None => Err(TreeRepoError::NodeNotFound(folder_uuid)),
        Some("folder") => Ok(()),
        Some(_) => Err(TreeRepoError::NodeNotFolder(folder_uuid)),
    }
}

fn list_referenced_atoms_in_subtree(
    conn: &Connection,
    folder_uuid: WorkspaceNodeId,
) -> TreeRepoResult<Vec<AtomId>> {
    let mut stmt = conn.prepare(
        "WITH RECURSIVE subtree(node_uuid) AS (
            SELECT node_uuid
            FROM workspace_nodes
            WHERE node_uuid = ?1
              AND is_deleted = 0
            UNION ALL
            SELECT child.node_uuid
            FROM workspace_nodes child
            INNER JOIN subtree parent ON child.parent_uuid = parent.node_uuid
            WHERE child.is_deleted = 0
        )
        SELECT DISTINCT nodes.atom_uuid
        FROM workspace_nodes nodes
        INNER JOIN subtree ON subtree.node_uuid = nodes.node_uuid
        WHERE nodes.kind = 'atom_ref'
          AND nodes.is_deleted = 0
          AND nodes.atom_uuid IS NOT NULL;",
    )?;

    let mut rows = stmt.query([folder_uuid.to_string()])?;
    let mut result = Vec::new();
    while let Some(row) = rows.next()? {
        let atom_uuid_text: String = row.get(0)?;
        result.push(parse_uuid(&atom_uuid_text, "workspace_nodes.atom_uuid")?);
    }
    Ok(result)
}

fn soft_delete_workspace_subtree(
    conn: &Connection,
    folder_uuid: WorkspaceNodeId,
) -> TreeRepoResult<()> {
    conn.execute(
        "WITH RECURSIVE subtree(node_uuid) AS (
            SELECT node_uuid
            FROM workspace_nodes
            WHERE node_uuid = ?1
              AND is_deleted = 0
            UNION ALL
            SELECT child.node_uuid
            FROM workspace_nodes child
            INNER JOIN subtree parent ON child.parent_uuid = parent.node_uuid
            WHERE child.is_deleted = 0
        )
        UPDATE workspace_nodes
        SET is_deleted = 1,
            updated_at = (strftime('%s', 'now') * 1000)
        WHERE node_uuid IN (SELECT node_uuid FROM subtree)
          AND is_deleted = 0;",
        [folder_uuid.to_string()],
    )?;
    Ok(())
}

fn parse_workspace_node_row(row: &Row<'_>) -> TreeRepoResult<WorkspaceNode> {
    let node_uuid_text: String = row.get("node_uuid")?;
    let node_uuid = parse_uuid(&node_uuid_text, "workspace_nodes.node_uuid")?;

    let parent_uuid = row
        .get::<_, Option<String>>("parent_uuid")?
        .map(|value| parse_uuid(&value, "workspace_nodes.parent_uuid"))
        .transpose()?;
    let atom_uuid = row
        .get::<_, Option<String>>("atom_uuid")?
        .map(|value| parse_uuid(&value, "workspace_nodes.atom_uuid"))
        .transpose()?;

    let kind_text: String = row.get("kind")?;
    let kind = parse_workspace_kind(&kind_text).ok_or_else(|| {
        TreeRepoError::InvalidData(format!(
            "invalid workspace node kind `{kind_text}` in workspace_nodes.kind"
        ))
    })?;

    let is_deleted = match row.get::<_, i64>("is_deleted")? {
        0 => false,
        1 => true,
        other => {
            return Err(TreeRepoError::InvalidData(format!(
                "invalid is_deleted value `{other}` in workspace_nodes.is_deleted"
            )));
        }
    };

    Ok(WorkspaceNode {
        node_uuid,
        kind,
        parent_uuid,
        atom_uuid,
        display_name: row.get("display_name")?,
        sort_order: row.get("sort_order")?,
        is_deleted,
        created_at: row.get("created_at")?,
        updated_at: row.get("updated_at")?,
    })
}

fn parse_workspace_kind(value: &str) -> Option<WorkspaceNodeKind> {
    match value {
        "workspace" => Some(WorkspaceNodeKind::Workspace),
        "folder" => Some(WorkspaceNodeKind::Folder),
        "atom_ref" => Some(WorkspaceNodeKind::AtomRef),
        _ => None,
    }
}

fn resolve_effective_parent_uuid(
    conn: &Connection,
    parent_uuid: Option<WorkspaceNodeId>,
) -> TreeRepoResult<WorkspaceNodeId> {
    match parent_uuid {
        Some(parent_uuid) => Ok(parent_uuid),
        None => default_workspace_root_id(conn),
    }
}

fn default_workspace_root_id(conn: &Connection) -> TreeRepoResult<WorkspaceNodeId> {
    let workspace_id: Option<String> = conn
        .query_row(
            "SELECT workspace_id
             FROM workspaces
             WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .optional()?;

    match workspace_id {
        Some(workspace_id) => parse_uuid(&workspace_id, "workspaces.workspace_id"),
        None => Err(TreeRepoError::InvalidData(
            "default workspace root not found".to_string(),
        )),
    }
}

fn resolve_workspace_root_for_node(
    conn: &Connection,
    node_uuid: WorkspaceNodeId,
) -> TreeRepoResult<WorkspaceNodeId> {
    let workspace_id: Option<String> = conn
        .query_row(
            "WITH RECURSIVE ancestors(node_uuid, parent_uuid, kind) AS (
                SELECT node_uuid, parent_uuid, kind
                FROM workspace_nodes
                WHERE node_uuid = ?1
              UNION ALL
                SELECT parent.node_uuid, parent.parent_uuid, parent.kind
                FROM workspace_nodes parent
                JOIN ancestors child ON parent.node_uuid = child.parent_uuid
            )
            SELECT node_uuid
            FROM ancestors
            WHERE kind = 'workspace'
            LIMIT 1;",
            [node_uuid.to_string()],
            |row| row.get(0),
        )
        .optional()?;

    match workspace_id {
        Some(workspace_id) => parse_uuid(&workspace_id, "workspace_nodes.node_uuid"),
        None => Err(TreeRepoError::InvalidData(format!(
            "workspace root not found for node `{node_uuid}`"
        ))),
    }
}

fn collect_ancestor_nodes(
    conn: &Connection,
    node_uuid: WorkspaceNodeId,
) -> TreeRepoResult<Vec<AncestorNode>> {
    let start_node =
        load_active_node(conn, node_uuid)?.ok_or(TreeRepoError::NodeNotFound(node_uuid))?;
    let mut visited = HashSet::new();
    let mut cursor = start_node.parent_uuid;
    let mut ancestors = Vec::new();

    while let Some(current) = cursor {
        if !visited.insert(current) {
            return Err(TreeRepoError::InvalidData(
                "workspace tree contains cycle while resolving ancestor path".to_string(),
            ));
        }

        let Some(node) = load_active_node(conn, current)? else {
            break;
        };
        if node.kind == WorkspaceNodeKind::Workspace || node.kind == WorkspaceNodeKind::Folder {
            ancestors.push(AncestorNode {
                node_uuid: node.node_uuid,
                kind: node.kind,
                display_name: node.display_name.clone(),
            });
        }
        cursor = node.parent_uuid;
    }

    ancestors.reverse();
    Ok(ancestors)
}

fn load_active_node(
    conn: &Connection,
    node_uuid: WorkspaceNodeId,
) -> TreeRepoResult<Option<WorkspaceNode>> {
    let mut stmt = conn.prepare(
        "SELECT
            n.node_uuid AS node_uuid,
            n.kind AS kind,
            n.parent_uuid AS parent_uuid,
            n.atom_uuid AS atom_uuid,
            n.display_name AS display_name,
            n.sort_order AS sort_order,
            n.is_deleted AS is_deleted,
            n.created_at AS created_at,
            n.updated_at AS updated_at
         FROM workspace_nodes n
         LEFT JOIN atoms a ON a.uuid = n.atom_uuid
         WHERE n.node_uuid = ?1
           AND n.is_deleted = 0
           AND (
             n.kind IN ('folder', 'workspace')
             OR (n.kind = 'atom_ref' AND a.is_deleted = 0)
           );",
    )?;
    let mut rows = stmt.query([node_uuid.to_string()])?;
    if let Some(row) = rows.next()? {
        return Ok(Some(parse_workspace_node_row(row)?));
    }
    Ok(None)
}

fn parse_uuid(value: &str, column: &'static str) -> TreeRepoResult<Uuid> {
    Uuid::parse_str(value)
        .map_err(|_| TreeRepoError::InvalidData(format!("invalid uuid `{value}` in {column}")))
}

fn ensure_tree_connection_ready(conn: &Connection) -> TreeRepoResult<()> {
    let expected_version = latest_version();
    let actual_version: u32 = conn.query_row("PRAGMA user_version;", [], |row| row.get(0))?;
    if actual_version != expected_version {
        return Err(TreeRepoError::UninitializedConnection {
            expected_version,
            actual_version,
        });
    }

    if !table_exists(conn, "workspace_nodes")? {
        return Err(TreeRepoError::MissingRequiredTable("workspace_nodes"));
    }

    for column in [
        "node_uuid",
        "kind",
        "parent_uuid",
        "atom_uuid",
        "display_name",
        "sort_order",
        "is_deleted",
        "created_at",
        "updated_at",
    ] {
        if !table_has_column(conn, "workspace_nodes", column)? {
            return Err(TreeRepoError::MissingRequiredColumn {
                table: "workspace_nodes",
                column,
            });
        }
    }

    Ok(())
}

fn table_exists(conn: &Connection, table: &str) -> TreeRepoResult<bool> {
    let exists: i64 = conn.query_row(
        "SELECT EXISTS(
            SELECT 1
            FROM sqlite_master
            WHERE type = 'table' AND name = ?1
        );",
        [table],
        |row| row.get(0),
    )?;
    Ok(exists == 1)
}

fn table_has_column(conn: &Connection, table: &str, column: &str) -> TreeRepoResult<bool> {
    let mut stmt = conn.prepare(&format!("PRAGMA table_info({table});"))?;
    let mut rows = stmt.query([])?;
    while let Some(row) = rows.next()? {
        let current: String = row.get(1)?;
        if current == column {
            return Ok(true);
        }
    }
    Ok(false)
}
