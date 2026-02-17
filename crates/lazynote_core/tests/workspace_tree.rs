use lazynote_core::db::open_db_in_memory;
use lazynote_core::{
    Atom, AtomRepository, AtomType, SqliteAtomRepository, SqliteTreeRepository, TreeService,
    TreeServiceError, WorkspaceNodeKind,
};
use uuid::Uuid;

fn setup() -> rusqlite::Connection {
    open_db_in_memory().unwrap()
}

fn insert_atom(conn: &rusqlite::Connection, atom: &Atom) {
    let repo = SqliteAtomRepository::try_new(conn).unwrap();
    repo.create_atom(atom).unwrap();
}

#[test]
fn migration_7_creates_workspace_nodes_table() {
    let conn = setup();

    let exists: i64 = conn
        .query_row(
            "SELECT EXISTS(
                SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'workspace_nodes'
            );",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(exists, 1);

    let mut stmt = conn.prepare("PRAGMA table_info(workspace_nodes);").unwrap();
    let mut rows = stmt.query([]).unwrap();
    let mut columns = Vec::new();
    while let Some(row) = rows.next().unwrap() {
        let column_name: String = row.get(1).unwrap();
        columns.push(column_name);
    }
    assert!(columns.contains(&"node_uuid".to_string()));
    assert!(columns.contains(&"kind".to_string()));
    assert!(columns.contains(&"parent_uuid".to_string()));
    assert!(columns.contains(&"atom_uuid".to_string()));
    assert!(columns.contains(&"display_name".to_string()));
    assert!(columns.contains(&"sort_order".to_string()));
}

#[test]
fn create_and_list_children_keeps_deterministic_order() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let root = service.create_folder(None, "Root").unwrap();
    let child_a = service
        .create_folder(Some(root.node_uuid), "Alpha")
        .unwrap();
    let child_b = service.create_folder(Some(root.node_uuid), "Beta").unwrap();

    let root_children = service.list_children(None).unwrap();
    assert_eq!(root_children.len(), 1);
    assert_eq!(root_children[0].node_uuid, root.node_uuid);

    let children = service.list_children(Some(root.node_uuid)).unwrap();
    assert_eq!(children.len(), 2);
    assert_eq!(children[0].node_uuid, child_a.node_uuid);
    assert_eq!(children[1].node_uuid, child_b.node_uuid);
    assert_eq!(children[0].sort_order, 0);
    assert_eq!(children[1].sort_order, 1);
}

#[test]
fn create_note_ref_requires_active_note_atom() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let task_atom = Atom::new(AtomType::Task, "Task row");
    insert_atom(&conn, &task_atom);

    let err = service
        .create_note_ref(None, task_atom.uuid, Some("TaskRef".to_string()))
        .unwrap_err();
    assert!(matches!(err, TreeServiceError::AtomNotNote(id) if id == task_atom.uuid));
}

#[test]
fn create_note_ref_success_for_note_atom() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note_atom = Atom::new(AtomType::Note, "Note row");
    insert_atom(&conn, &note_atom);

    let folder = service.create_folder(None, "Notes").unwrap();
    let note_ref = service
        .create_note_ref(Some(folder.node_uuid), note_atom.uuid, None)
        .unwrap();

    assert_eq!(note_ref.kind, WorkspaceNodeKind::NoteRef);
    assert_eq!(note_ref.parent_uuid, Some(folder.node_uuid));
    assert_eq!(note_ref.atom_uuid, Some(note_atom.uuid));
    assert_eq!(note_ref.display_name, "Untitled note");
}

#[test]
fn move_rejects_cycle_parenting() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let folder_a = service.create_folder(None, "A").unwrap();
    let folder_b = service
        .create_folder(Some(folder_a.node_uuid), "B")
        .unwrap();

    let err = service
        .move_node(folder_a.node_uuid, Some(folder_b.node_uuid), None)
        .unwrap_err();
    assert!(matches!(
        err,
        TreeServiceError::CycleDetected {
            node_uuid,
            parent_uuid
        } if node_uuid == folder_a.node_uuid && parent_uuid == folder_b.node_uuid
    ));
}

#[test]
fn move_rejects_note_ref_parent() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note_atom = Atom::new(AtomType::Note, "Note row");
    insert_atom(&conn, &note_atom);

    let folder = service.create_folder(None, "Folder").unwrap();
    let note_ref = service
        .create_note_ref(None, note_atom.uuid, Some("Ref".to_string()))
        .unwrap();

    let err = service
        .move_node(folder.node_uuid, Some(note_ref.node_uuid), None)
        .unwrap_err();
    assert!(matches!(
        err,
        TreeServiceError::ParentMustBeFolder(parent_uuid) if parent_uuid == note_ref.node_uuid
    ));
}

#[test]
fn move_with_target_order_reorders_siblings() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let root = service.create_folder(None, "Root").unwrap();
    let child_a = service
        .create_folder(Some(root.node_uuid), "Alpha")
        .unwrap();
    let child_b = service.create_folder(Some(root.node_uuid), "Beta").unwrap();
    let child_c = service
        .create_folder(Some(root.node_uuid), "Gamma")
        .unwrap();

    service
        .move_node(child_c.node_uuid, Some(root.node_uuid), Some(0))
        .unwrap();

    let children = service.list_children(Some(root.node_uuid)).unwrap();
    assert_eq!(children.len(), 3);
    assert_eq!(children[0].node_uuid, child_c.node_uuid);
    assert_eq!(children[1].node_uuid, child_a.node_uuid);
    assert_eq!(children[2].node_uuid, child_b.node_uuid);
    assert_eq!(children[0].sort_order, 0);
    assert_eq!(children[1].sort_order, 1);
    assert_eq!(children[2].sort_order, 2);
}

#[test]
fn create_folder_rejects_unknown_parent() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);
    let unknown_parent = Uuid::new_v4();

    let err = service
        .create_folder(Some(unknown_parent), "x")
        .unwrap_err();
    assert!(matches!(
        err,
        TreeServiceError::ParentNotFound(parent_uuid) if parent_uuid == unknown_parent
    ));
}
