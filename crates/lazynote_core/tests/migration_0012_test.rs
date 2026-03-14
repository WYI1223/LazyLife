use lazynote_core::db::migrations::{apply_migrations, latest_version};
use lazynote_core::db::open_db_in_memory;
use lazynote_core::{SqliteWorkspaceMetaRepository, WorkspaceMetaRepository};
use rusqlite::{params, Connection};
use uuid::Uuid;

#[test]
fn fresh_install_creates_default_workspace_and_designated_folders() {
    let conn = open_db_in_memory().unwrap();

    assert_eq!(latest_version(), 12);
    assert_eq!(schema_version(&conn), 12);
    assert_table_exists(&conn, "workspaces");
    assert_table_exists(&conn, "designated_folders");
    assert_column_exists(&conn, "atoms", "origin_workspace_id");

    let workspace_root_count: i64 = conn
        .query_row(
            "SELECT COUNT(*)
             FROM workspace_nodes
             WHERE kind = 'workspace'
               AND is_deleted = 0;",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(workspace_root_count, 1);

    let designated_role_count: i64 = conn
        .query_row("SELECT COUNT(*) FROM designated_folders;", [], |row| {
            row.get(0)
        })
        .unwrap();
    assert_eq!(designated_role_count, 3);
}

#[test]
fn upgrade_from_v11_backfills_default_workspace_and_origin_workspace_id() {
    let mut conn = Connection::open_in_memory().unwrap();
    migrate_to_v11(&conn);

    let note_id = Uuid::new_v4().to_string();
    let loose_atom_id = Uuid::new_v4().to_string();
    let folder_id = Uuid::new_v4().to_string();
    let atom_ref_id = Uuid::new_v4().to_string();

    conn.execute(
        "INSERT INTO atoms (uuid, view_hint, title, content)
         VALUES (?1, 'note', 'Migrated note', 'body');",
        [note_id.as_str()],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO atoms (uuid, view_hint, title, content)
         VALUES (?1, 'event', 'Loose atom', 'event body');",
        [loose_atom_id.as_str()],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'folder', NULL, NULL, 'Legacy root folder', 0, 0);",
        [folder_id.as_str()],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'atom_ref', NULL, ?2, 'Legacy root ref', 1, 0);",
        params![atom_ref_id, note_id],
    )
    .unwrap();

    apply_migrations(&mut conn).unwrap();

    assert_eq!(latest_version(), 12);
    assert_eq!(schema_version(&conn), 12);

    let default_workspace_id: String = conn
        .query_row(
            "SELECT workspace_id FROM workspaces WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .unwrap();

    let top_level_non_workspace_count: i64 = conn
        .query_row(
            "SELECT COUNT(*)
             FROM workspace_nodes
             WHERE parent_uuid IS NULL
               AND kind <> 'workspace'
               AND is_deleted = 0;",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(top_level_non_workspace_count, 0);

    let folder_parent: String = conn
        .query_row(
            "SELECT parent_uuid
             FROM workspace_nodes
             WHERE node_uuid = ?1;",
            [folder_id.as_str()],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(folder_parent, default_workspace_id);

    let atom_ref_parent: String = conn
        .query_row(
            "SELECT parent_uuid
             FROM workspace_nodes
             WHERE node_uuid = ?1;",
            [atom_ref_id.as_str()],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(atom_ref_parent, default_workspace_id);

    let atoms_backfilled: i64 = conn
        .query_row(
            "SELECT COUNT(*)
             FROM atoms
             WHERE origin_workspace_id = ?1;",
            [default_workspace_id.as_str()],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(atoms_backfilled, 2);
}

#[test]
fn workspace_root_and_designated_folder_guards_reject_invalid_mutations() {
    let conn = open_db_in_memory().unwrap();

    assert_eq!(latest_version(), 12);
    assert_eq!(schema_version(&conn), 12);

    let default_workspace_id: String = conn
        .query_row(
            "SELECT workspace_id FROM workspaces WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .unwrap();
    let inbox_folder_id: String = conn
        .query_row(
            "SELECT node_uuid
             FROM designated_folders
             WHERE workspace_id = ?1
               AND role = 'inbox';",
            [default_workspace_id.as_str()],
            |row| row.get(0),
        )
        .unwrap();

    let other_workspace_id = Uuid::new_v4().to_string();
    let other_folder_id = Uuid::new_v4().to_string();
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'workspace', NULL, NULL, 'Other workspace', 10, 0);",
        [other_workspace_id.as_str()],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO workspaces (workspace_id, name, is_default)
         VALUES (?1, 'Other workspace', 0);",
        [other_workspace_id.as_str()],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'folder', ?2, NULL, 'Other folder', 0, 0);",
        params![other_folder_id, other_workspace_id],
    )
    .unwrap();

    let reparent_root = conn.execute(
        "UPDATE workspace_nodes
         SET parent_uuid = ?1
         WHERE node_uuid = ?2;",
        params![inbox_folder_id, default_workspace_id],
    );
    assert!(reparent_root.is_err());

    let change_root_kind = conn.execute(
        "UPDATE workspace_nodes
         SET kind = 'folder'
         WHERE node_uuid = ?1;",
        [default_workspace_id.as_str()],
    );
    assert!(change_root_kind.is_err());

    let soft_delete_designated = conn.execute(
        "UPDATE workspace_nodes
         SET is_deleted = 1
         WHERE node_uuid = ?1;",
        [inbox_folder_id.as_str()],
    );
    assert!(soft_delete_designated.is_err());

    let hard_delete_designated = conn.execute(
        "DELETE FROM workspace_nodes WHERE node_uuid = ?1;",
        [inbox_folder_id.as_str()],
    );
    assert!(hard_delete_designated.is_err());

    let cross_workspace_reassign = conn.execute(
        "UPDATE designated_folders
         SET node_uuid = ?1
         WHERE workspace_id = ?2
           AND role = 'inbox';",
        params![other_folder_id, default_workspace_id],
    );
    assert!(cross_workspace_reassign.is_err());
}

#[test]
fn designated_folder_can_be_reassigned_to_nested_folder_in_same_workspace() {
    let conn = open_db_in_memory().unwrap();

    let default_workspace_id: String = conn
        .query_row(
            "SELECT workspace_id FROM workspaces WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .unwrap();
    let parent_folder_id = Uuid::new_v4().to_string();
    let nested_folder_id = Uuid::new_v4().to_string();

    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'folder', ?2, NULL, 'Projects', 10, 0);",
        params![parent_folder_id, default_workspace_id],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'folder', ?2, NULL, 'Nested', 0, 0);",
        params![nested_folder_id, parent_folder_id],
    )
    .unwrap();

    conn.execute(
        "UPDATE designated_folders
         SET node_uuid = ?1
         WHERE workspace_id = ?2
           AND role = 'tasks';",
        params![nested_folder_id, default_workspace_id],
    )
    .unwrap();

    let designated_node: String = conn
        .query_row(
            "SELECT node_uuid
             FROM designated_folders
             WHERE workspace_id = ?1
               AND role = 'tasks';",
            [default_workspace_id.as_str()],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(designated_node, nested_folder_id);
}

#[test]
fn schema_rejects_new_root_level_non_workspace_nodes_after_0012() {
    let conn = open_db_in_memory().unwrap();
    let rogue_folder_id = Uuid::new_v4().to_string();

    let insert_result = conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'folder', NULL, NULL, 'Rogue root folder', 99, 0);",
        [rogue_folder_id.as_str()],
    );

    assert!(insert_result.is_err());
}

#[test]
fn workspace_meta_repository_reads_default_workspace_and_designated_roles() {
    let conn = open_db_in_memory().unwrap();
    let repo = SqliteWorkspaceMetaRepository::try_new(&conn).unwrap();

    let default_workspace_id = repo.get_default_workspace().unwrap().unwrap();
    let workspaces = repo.list_workspaces().unwrap();
    assert_eq!(workspaces.len(), 1);
    assert_eq!(workspaces[0].workspace_id, default_workspace_id);
    assert!(workspaces[0].is_default);

    for role in ["inbox", "tasks", "calendar"] {
        let designated = repo
            .resolve_designated(default_workspace_id, role)
            .unwrap()
            .unwrap();
        let parent_uuid: String = conn
            .query_row(
                "SELECT parent_uuid
                 FROM workspace_nodes
                 WHERE node_uuid = ?1;",
                [designated.to_string()],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(parent_uuid, default_workspace_id.to_string());
    }
}

fn migrate_to_v11(conn: &Connection) {
    let migrations = [
        (1u32, include_str!("../src/db/migrations/0001_init.sql")),
        (2u32, include_str!("../src/db/migrations/0002_tags.sql")),
        (
            3u32,
            include_str!("../src/db/migrations/0003_external_mappings.sql"),
        ),
        (4u32, include_str!("../src/db/migrations/0004_fts.sql")),
        (
            5u32,
            include_str!("../src/db/migrations/0005_note_preview.sql"),
        ),
        (
            6u32,
            include_str!("../src/db/migrations/0006_time_matrix.sql"),
        ),
        (
            7u32,
            include_str!("../src/db/migrations/0007_workspace_tree.sql"),
        ),
        (
            8u32,
            include_str!("../src/db/migrations/0008_workspace_tree_delete_policy.sql"),
        ),
        (
            9u32,
            include_str!("../src/db/migrations/0009_workspace_note_ref_backfill.sql"),
        ),
        (
            10u32,
            include_str!("../src/db/migrations/0010_s1_core_fields.sql"),
        ),
        (
            11u32,
            include_str!("../src/db/migrations/0011_atom_ref_upgrade.sql"),
        ),
    ];

    for (version, sql) in migrations {
        conn.execute_batch(sql).unwrap();
        conn.execute_batch(&format!("PRAGMA user_version = {version};"))
            .unwrap();
    }
}

fn schema_version(conn: &Connection) -> u32 {
    conn.query_row("PRAGMA user_version;", [], |row| row.get(0))
        .unwrap()
}

fn assert_table_exists(conn: &Connection, table_name: &str) {
    let exists: i64 = conn
        .query_row(
            "SELECT EXISTS(
                SELECT 1
                FROM sqlite_master
                WHERE type = 'table'
                  AND name = ?1
            );",
            [table_name],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(exists, 1, "expected table {table_name} to exist");
}

fn assert_column_exists(conn: &Connection, table_name: &str, column_name: &str) {
    let pragma = format!("PRAGMA table_info({table_name});");
    let mut stmt = conn.prepare(&pragma).unwrap();
    let mut rows = stmt.query([]).unwrap();
    let mut found = false;

    while let Some(row) = rows.next().unwrap() {
        let name: String = row.get(1).unwrap();
        if name == column_name {
            found = true;
            break;
        }
    }

    assert!(found, "expected column {table_name}.{column_name} to exist");
}
