//! Workspace metadata repository contracts and SQLite implementation.
//!
//! # Responsibility
//! - Read workspace-level metadata introduced by migration 0012.
//! - Resolve designated folders without leaking raw SQL into services.

use crate::db::migrations::latest_version;
use crate::repo::tree_repo::{TreeRepoError, TreeRepoResult, WorkspaceNodeId};
use rusqlite::{Connection, OptionalExtension};
use uuid::Uuid;

/// Workspace metadata read model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceMetadata {
    /// Stable workspace root id.
    pub workspace_id: WorkspaceNodeId,
    /// User-facing workspace name.
    pub name: String,
    /// Whether this workspace is the default one.
    pub is_default: bool,
}

/// Repository interface for workspace metadata reads.
pub trait WorkspaceMetaRepository {
    /// Returns the default workspace id, if present.
    fn get_default_workspace(&self) -> TreeRepoResult<Option<WorkspaceNodeId>>;

    /// Returns all workspaces in deterministic order.
    fn list_workspaces(&self) -> TreeRepoResult<Vec<WorkspaceMetadata>>;

    /// Returns whether one workspace id exists in `workspaces`.
    fn workspace_exists(&self, workspace_id: WorkspaceNodeId) -> TreeRepoResult<bool>;

    /// Resolves one designated folder by workspace id and role.
    fn resolve_designated(
        &self,
        workspace_id: WorkspaceNodeId,
        role: &str,
    ) -> TreeRepoResult<Option<WorkspaceNodeId>>;

    /// Returns whether one node is currently designated for any role.
    fn is_designated(&self, node_uuid: WorkspaceNodeId) -> TreeRepoResult<bool>;

    /// Reassigns one designated role to another folder in the same workspace tree.
    fn reassign_designated(
        &self,
        workspace_id: WorkspaceNodeId,
        role: &str,
        new_node_uuid: WorkspaceNodeId,
    ) -> TreeRepoResult<()>;
}

/// SQLite-backed workspace metadata repository.
pub struct SqliteWorkspaceMetaRepository<'conn> {
    conn: &'conn Connection,
}

impl<'conn> SqliteWorkspaceMetaRepository<'conn> {
    /// Creates repository from migrated connection.
    pub fn try_new(conn: &'conn Connection) -> TreeRepoResult<Self> {
        ensure_workspace_meta_connection_ready(conn)?;
        Ok(Self { conn })
    }
}

impl WorkspaceMetaRepository for SqliteWorkspaceMetaRepository<'_> {
    fn get_default_workspace(&self) -> TreeRepoResult<Option<WorkspaceNodeId>> {
        let workspace_id: Option<String> = self
            .conn
            .query_row(
                "SELECT workspace_id
                 FROM workspaces
                 WHERE is_default = 1;",
                [],
                |row| row.get(0),
            )
            .optional()?;

        workspace_id
            .map(|value| parse_uuid(&value, "workspaces.workspace_id"))
            .transpose()
    }

    fn list_workspaces(&self) -> TreeRepoResult<Vec<WorkspaceMetadata>> {
        let mut stmt = self.conn.prepare(
            "SELECT workspace_id, name, is_default
             FROM workspaces
             ORDER BY is_default DESC, name ASC, workspace_id ASC;",
        )?;
        let mut rows = stmt.query([])?;
        let mut items = Vec::new();

        while let Some(row) = rows.next()? {
            let workspace_id_text: String = row.get(0)?;
            let is_default = match row.get::<_, i64>(2)? {
                0 => false,
                1 => true,
                other => {
                    return Err(TreeRepoError::InvalidData(format!(
                        "invalid is_default value `{other}` in workspaces.is_default"
                    )));
                }
            };

            items.push(WorkspaceMetadata {
                workspace_id: parse_uuid(&workspace_id_text, "workspaces.workspace_id")?,
                name: row.get(1)?,
                is_default,
            });
        }

        Ok(items)
    }

    fn workspace_exists(&self, workspace_id: WorkspaceNodeId) -> TreeRepoResult<bool> {
        let exists: i64 = self.conn.query_row(
            "SELECT EXISTS(
                SELECT 1
                FROM workspaces
                WHERE workspace_id = ?1
            );",
            [workspace_id.to_string()],
            |row| row.get(0),
        )?;
        Ok(exists == 1)
    }

    fn resolve_designated(
        &self,
        workspace_id: WorkspaceNodeId,
        role: &str,
    ) -> TreeRepoResult<Option<WorkspaceNodeId>> {
        let node_uuid: Option<String> = self
            .conn
            .query_row(
                "SELECT node_uuid
                 FROM designated_folders
                 WHERE workspace_id = ?1
                   AND role = ?2;",
                [workspace_id.to_string(), role.to_string()],
                |row| row.get(0),
            )
            .optional()?;

        node_uuid
            .map(|value| parse_uuid(&value, "designated_folders.node_uuid"))
            .transpose()
    }

    fn is_designated(&self, node_uuid: WorkspaceNodeId) -> TreeRepoResult<bool> {
        let exists: i64 = self.conn.query_row(
            "SELECT EXISTS(
                SELECT 1
                FROM designated_folders
                WHERE node_uuid = ?1
            );",
            [node_uuid.to_string()],
            |row| row.get(0),
        )?;
        Ok(exists == 1)
    }

    fn reassign_designated(
        &self,
        workspace_id: WorkspaceNodeId,
        role: &str,
        new_node_uuid: WorkspaceNodeId,
    ) -> TreeRepoResult<()> {
        let target_kind: Option<String> = self
            .conn
            .query_row(
                "SELECT kind
                 FROM workspace_nodes
                 WHERE node_uuid = ?1
                   AND is_deleted = 0;",
                [new_node_uuid.to_string()],
                |row| row.get(0),
            )
            .optional()?;

        match target_kind.as_deref() {
            Some("folder") => {}
            Some(_) => return Err(TreeRepoError::NodeNotFolder(new_node_uuid)),
            None => return Err(TreeRepoError::NodeNotFound(new_node_uuid)),
        }

        let resolved_workspace = workspace_root_for_node(self.conn, new_node_uuid)?
            .ok_or(TreeRepoError::NodeNotFound(new_node_uuid))?;
        if resolved_workspace != workspace_id {
            return Err(TreeRepoError::InvalidData(
                "designated folder must belong to the same workspace subtree".to_string(),
            ));
        }

        let updated = self.conn.execute(
            "UPDATE designated_folders
             SET node_uuid = ?1
             WHERE workspace_id = ?2
               AND role = ?3;",
            [
                new_node_uuid.to_string(),
                workspace_id.to_string(),
                role.to_string(),
            ],
        )?;
        if updated == 0 {
            return Err(TreeRepoError::InvalidData(format!(
                "designated role `{role}` not found for workspace `{workspace_id}`"
            )));
        }
        Ok(())
    }
}

fn ensure_workspace_meta_connection_ready(conn: &Connection) -> TreeRepoResult<()> {
    let expected_version = latest_version();
    let actual_version: u32 = conn.query_row("PRAGMA user_version;", [], |row| row.get(0))?;
    if actual_version != expected_version {
        return Err(TreeRepoError::UninitializedConnection {
            expected_version,
            actual_version,
        });
    }

    for table in ["workspaces", "designated_folders"] {
        if !table_exists(conn, table)? {
            return Err(TreeRepoError::MissingRequiredTable(table));
        }
    }

    for (table, column) in [
        ("workspaces", "workspace_id"),
        ("workspaces", "name"),
        ("workspaces", "is_default"),
        ("designated_folders", "workspace_id"),
        ("designated_folders", "role"),
        ("designated_folders", "node_uuid"),
    ] {
        if !table_has_column(conn, table, column)? {
            return Err(TreeRepoError::MissingRequiredColumn { table, column });
        }
    }

    Ok(())
}

fn table_exists(conn: &Connection, table: &str) -> TreeRepoResult<bool> {
    let exists: i64 = conn.query_row(
        "SELECT EXISTS(
            SELECT 1
            FROM sqlite_master
            WHERE type = 'table'
              AND name = ?1
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

fn parse_uuid(value: &str, column: &'static str) -> TreeRepoResult<Uuid> {
    Uuid::parse_str(value)
        .map_err(|_| TreeRepoError::InvalidData(format!("invalid uuid `{value}` in {column}")))
}

fn workspace_root_for_node(
    conn: &Connection,
    node_uuid: WorkspaceNodeId,
) -> TreeRepoResult<Option<WorkspaceNodeId>> {
    let workspace_id: Option<String> = conn
        .query_row(
            "WITH RECURSIVE ancestors(node_uuid, kind, parent_uuid) AS (
                SELECT node_uuid, kind, parent_uuid
                FROM workspace_nodes
                WHERE node_uuid = ?1
                  AND is_deleted = 0
                UNION ALL
                SELECT parent.node_uuid, parent.kind, parent.parent_uuid
                FROM workspace_nodes parent
                JOIN ancestors child ON parent.node_uuid = child.parent_uuid
                WHERE parent.is_deleted = 0
            )
            SELECT node_uuid
            FROM ancestors
            WHERE kind = 'workspace'
            LIMIT 1;",
            [node_uuid.to_string()],
            |row| row.get(0),
        )
        .optional()?;

    workspace_id
        .map(|value| parse_uuid(&value, "workspace_nodes.node_uuid"))
        .transpose()
}
