use crate::db::{DbError, DbResult};
use rusqlite::{params, Transaction};
use uuid::Uuid;

const MIGRATION_0012_SQL: &str = include_str!("0012_workspace_single_root.sql");

pub(super) fn apply_migration_0012(tx: &Transaction<'_>) -> DbResult<()> {
    tx.execute_batch(sql_phase("schema")?)?;

    let workspace_root_id = Uuid::new_v4().to_string();
    let inbox_folder_id = Uuid::new_v4().to_string();
    let tasks_folder_id = Uuid::new_v4().to_string();
    let calendar_folder_id = Uuid::new_v4().to_string();

    tx.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'workspace', NULL, NULL, 'Default Workspace', 0, 0);",
        [workspace_root_id.as_str()],
    )?;
    tx.execute(
        "INSERT INTO workspaces (workspace_id, name, is_default)
         VALUES (?1, 'Default Workspace', 1);",
        [workspace_root_id.as_str()],
    )?;

    insert_designated_folder(
        tx,
        &workspace_root_id,
        &inbox_folder_id,
        "inbox",
        "Inbox",
        0,
    )?;
    insert_designated_folder(
        tx,
        &workspace_root_id,
        &tasks_folder_id,
        "tasks",
        "Tasks",
        1,
    )?;
    insert_designated_folder(
        tx,
        &workspace_root_id,
        &calendar_folder_id,
        "calendar",
        "Calendar",
        2,
    )?;

    tx.execute(
        "UPDATE workspace_nodes
         SET parent_uuid = ?1,
             sort_order = sort_order + 3,
             updated_at = (strftime('%s', 'now') * 1000)
         WHERE parent_uuid IS NULL
           AND node_uuid <> ?1;",
        [workspace_root_id.as_str()],
    )?;

    tx.execute(
        "UPDATE atoms
         SET origin_workspace_id = ?1
         WHERE origin_workspace_id IS NULL;",
        [workspace_root_id.as_str()],
    )?;

    tx.execute_batch(sql_phase("guards")?)?;

    assert_single_default_workspace(tx)?;
    assert_designated_roles_exist(tx, &workspace_root_id)?;
    assert_no_top_level_non_workspace_nodes(tx)?;

    Ok(())
}

fn insert_designated_folder(
    tx: &Transaction<'_>,
    workspace_root_id: &str,
    node_uuid: &str,
    role: &str,
    display_name: &str,
    sort_order: i64,
) -> DbResult<()> {
    tx.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'folder', ?2, NULL, ?3, ?4, 0);",
        params![node_uuid, workspace_root_id, display_name, sort_order],
    )?;
    tx.execute(
        "INSERT INTO designated_folders (workspace_id, role, node_uuid)
         VALUES (?1, ?2, ?3);",
        params![workspace_root_id, role, node_uuid],
    )?;
    Ok(())
}

fn assert_single_default_workspace(tx: &Transaction<'_>) -> DbResult<()> {
    let default_count: i64 = tx.query_row(
        "SELECT COUNT(*) FROM workspaces WHERE is_default = 1;",
        [],
        |row| row.get(0),
    )?;
    if default_count != 1 {
        return Err(DbError::MigrationInvariantFailed(
            "migration 0012 must create exactly one default workspace",
        ));
    }

    let workspace_root_count: i64 = tx.query_row(
        "SELECT COUNT(*)
         FROM workspace_nodes
         WHERE kind = 'workspace'
           AND is_deleted = 0;",
        [],
        |row| row.get(0),
    )?;
    if workspace_root_count != 1 {
        return Err(DbError::MigrationInvariantFailed(
            "migration 0012 must leave exactly one active workspace root",
        ));
    }

    Ok(())
}

fn assert_designated_roles_exist(tx: &Transaction<'_>, workspace_root_id: &str) -> DbResult<()> {
    let designated_count: i64 = tx.query_row(
        "SELECT COUNT(*)
         FROM designated_folders
         WHERE workspace_id = ?1;",
        [workspace_root_id],
        |row| row.get(0),
    )?;
    if designated_count != 3 {
        return Err(DbError::MigrationInvariantFailed(
            "migration 0012 must create inbox/tasks/calendar designated folders",
        ));
    }

    Ok(())
}

fn assert_no_top_level_non_workspace_nodes(tx: &Transaction<'_>) -> DbResult<()> {
    let lingering_count: i64 = tx.query_row(
        "SELECT COUNT(*)
         FROM workspace_nodes
         WHERE parent_uuid IS NULL
           AND kind <> 'workspace'
           AND is_deleted = 0;",
        [],
        |row| row.get(0),
    )?;
    if lingering_count != 0 {
        return Err(DbError::MigrationInvariantFailed(
            "migration 0012 must re-parent active top-level nodes under the default workspace",
        ));
    }

    Ok(())
}

fn sql_phase(name: &str) -> DbResult<&'static str> {
    let marker = format!("-- @phase {name}");
    let start = MIGRATION_0012_SQL
        .find(&marker)
        .ok_or(DbError::InvalidMigrationRegistry(
            "migration 0012 SQL phase marker missing",
        ))?;
    let content_start = start + marker.len();
    let remaining = &MIGRATION_0012_SQL[content_start..];
    let next_phase = remaining.find("-- @phase ").unwrap_or(remaining.len());
    let sql = remaining[..next_phase].trim();

    if sql.is_empty() {
        return Err(DbError::InvalidMigrationRegistry(
            "migration 0012 SQL phase is empty",
        ));
    }

    Ok(sql)
}
