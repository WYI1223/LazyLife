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

    /// Resolves one designated folder by workspace id and role.
    fn resolve_designated(
        &self,
        workspace_id: WorkspaceNodeId,
        role: &str,
    ) -> TreeRepoResult<Option<WorkspaceNodeId>>;
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
