use lazynote_core::db::open_db_in_memory;
use lazynote_core::{
    CreateAtomRequest, CreateEventWithRefRequest, CreationService, TaskStatus, ViewHint,
};
use uuid::Uuid;

fn setup() -> rusqlite::Connection {
    open_db_in_memory().unwrap()
}

fn default_workspace_id(conn: &rusqlite::Connection) -> Uuid {
    let workspace_id: String = conn
        .query_row(
            "SELECT workspace_id FROM workspaces WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .unwrap();
    Uuid::parse_str(&workspace_id).unwrap()
}

fn designated_folder_id(conn: &rusqlite::Connection, role: &str) -> Uuid {
    let workspace_id = default_workspace_id(conn);
    let node_id: String = conn
        .query_row(
            "SELECT node_uuid
             FROM designated_folders
             WHERE workspace_id = ?1
               AND role = ?2;",
            [workspace_id.to_string(), role.to_string()],
            |row| row.get(0),
        )
        .unwrap();
    Uuid::parse_str(&node_id).unwrap()
}

fn load_origin_workspace_id(conn: &rusqlite::Connection, atom_id: Uuid) -> Option<Uuid> {
    let value: Option<String> = conn
        .query_row(
            "SELECT origin_workspace_id
             FROM atoms
             WHERE uuid = ?1;",
            [atom_id.to_string()],
            |row| row.get(0),
        )
        .unwrap();
    value.map(|item| Uuid::parse_str(&item).unwrap())
}

fn insert_workspace_root(conn: &rusqlite::Connection, name: &str) -> Uuid {
    let workspace_id = Uuid::new_v4();
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'workspace', NULL, NULL, ?2, 10, 0);",
        rusqlite::params![workspace_id.to_string(), name],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO workspaces (workspace_id, name, is_default)
         VALUES (?1, ?2, 0);",
        rusqlite::params![workspace_id.to_string(), name],
    )
    .unwrap();
    workspace_id
}

fn insert_folder_node(
    conn: &rusqlite::Connection,
    parent_uuid: Uuid,
    display_name: &str,
    sort_order: i64,
) -> Uuid {
    let node_id = Uuid::new_v4();
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
         ) VALUES (?1, 'folder', ?2, NULL, ?3, ?4, 0);",
        rusqlite::params![
            node_id.to_string(),
            parent_uuid.to_string(),
            display_name,
            sort_order
        ],
    )
    .unwrap();
    node_id
}

#[test]
fn create_note_with_ref_without_parent_routes_to_inbox_designated_folder() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let inbox_folder = designated_folder_id(&conn, "inbox");

    let (_record, node) = service.create_note_with_ref("Inbox note", None).unwrap();

    assert_eq!(node.parent_uuid, Some(inbox_folder));
}

#[test]
fn create_task_with_ref_without_parent_routes_to_tasks_designated_folder() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let tasks_folder = designated_folder_id(&conn, "tasks");

    let (_atom_id, node) = service.create_task_with_ref("Task item", None).unwrap();

    assert_eq!(node.parent_uuid, Some(tasks_folder));
}

#[test]
fn create_event_with_ref_without_parent_routes_to_calendar_designated_folder() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let calendar_folder = designated_folder_id(&conn, "calendar");
    let request = CreateEventWithRefRequest {
        title: "Calendar item".to_string(),
        start_epoch_ms: 1_000,
        end_epoch_ms: Some(2_000),
    };

    let (_atom_id, node) = service.create_event_with_ref(&request, None).unwrap();

    assert_eq!(node.parent_uuid, Some(calendar_folder));
}

#[test]
fn create_task_with_ref_writes_origin_workspace_id_for_new_atom() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let default_workspace = default_workspace_id(&conn);

    let (atom_id, _node) = service.create_task_with_ref("Task item", None).unwrap();

    assert_eq!(
        load_origin_workspace_id(&conn, atom_id),
        Some(default_workspace),
    );
}

#[test]
fn create_atom_routes_task_to_designated_folder_and_writes_tags() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let default_workspace = default_workspace_id(&conn);
    let tasks_folder = designated_folder_id(&conn, "tasks");

    let result = service
        .create_atom(&CreateAtomRequest {
            workspace_id: default_workspace,
            content: "Task item".to_string(),
            content_type: "markdown".to_string(),
            task_status: Some(TaskStatus::Todo),
            start_at: None,
            end_at: None,
            tags: Some(vec![
                " Work ".to_string(),
                "work".to_string(),
                "Urgent".to_string(),
            ]),
            target_folder: None,
            display_name: None,
        })
        .unwrap();

    assert_eq!(result.node.parent_uuid, Some(tasks_folder));
    assert_eq!(
        load_origin_workspace_id(&conn, result.atom.uuid),
        Some(default_workspace),
    );

    let tags: Vec<String> = {
        let mut stmt = conn
            .prepare(
                "SELECT tags.name
                 FROM atom_tags
                 JOIN tags ON tags.id = atom_tags.tag_id
                 WHERE atom_tags.atom_uuid = ?1
                 ORDER BY tags.name COLLATE NOCASE ASC;",
            )
            .unwrap();
        let rows = stmt
            .query_map([result.atom.uuid.to_string()], |row| {
                row.get::<_, String>(0)
            })
            .unwrap();
        rows.map(|row| row.unwrap()).collect()
    };
    assert_eq!(tags, vec!["urgent".to_string(), "work".to_string()]);
}

#[test]
fn create_atom_explicit_target_folder_overrides_designated_routing() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let default_workspace = default_workspace_id(&conn);
    let explicit_folder = insert_folder_node(&conn, default_workspace, "Projects", 10);

    let result = service
        .create_atom(&CreateAtomRequest {
            workspace_id: default_workspace,
            content: "Task in projects".to_string(),
            content_type: "markdown".to_string(),
            task_status: Some(TaskStatus::Todo),
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: Some(explicit_folder),
            display_name: Some("Project Task".to_string()),
        })
        .unwrap();

    assert_eq!(result.node.parent_uuid, Some(explicit_folder));
    assert_eq!(result.atom.view_hint, ViewHint::Task);
}

#[test]
fn create_atom_rejects_target_folder_from_other_workspace() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let default_workspace = default_workspace_id(&conn);
    let other_workspace = insert_workspace_root(&conn, "Other Workspace");
    let other_folder = insert_folder_node(&conn, other_workspace, "Elsewhere", 0);

    let err = service
        .create_atom(&CreateAtomRequest {
            workspace_id: default_workspace,
            content: "Wrong place".to_string(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: Some(other_folder),
            display_name: None,
        })
        .unwrap_err();

    assert!(
        err.to_string().contains("target folder"),
        "cross-workspace target should be rejected by canonical create_atom contract",
    );
}

#[test]
fn create_atom_does_not_fallback_to_workspace_root_when_designated_row_is_missing() {
    let conn = setup();
    let service = CreationService::try_new(&conn).unwrap();
    let default_workspace = default_workspace_id(&conn);

    conn.execute(
        "DELETE FROM designated_folders
         WHERE workspace_id = ?1
           AND role = 'inbox';",
        [default_workspace.to_string()],
    )
    .unwrap();

    let err = service
        .create_atom(&CreateAtomRequest {
            workspace_id: default_workspace,
            content: "Inbox note".to_string(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: None,
            display_name: None,
        })
        .unwrap_err();

    assert!(
        err.to_string().contains("designated"),
        "missing designated folder must fail instead of falling back to workspace root",
    );
}
