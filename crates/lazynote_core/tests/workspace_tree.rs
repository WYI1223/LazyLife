use lazynote_core::db::open_db_in_memory;
use lazynote_core::{
    Atom, AtomRepository, FolderDeleteMode, SqliteAtomRepository, SqliteTreeRepository,
    TreeRepoError, TreeRepository, TreeService, TreeServiceError, ViewHint, WorkspaceNodeKind,
};
// Note: after migration 0011, workspace nodes use `atom_ref` (not `note_ref`)
// and accept any active atom type (not just notes).
use uuid::Uuid;

fn setup() -> rusqlite::Connection {
    open_db_in_memory().unwrap()
}

fn insert_atom(conn: &rusqlite::Connection, atom: &Atom) {
    let repo = SqliteAtomRepository::try_new(conn).unwrap();
    repo.create_atom(atom).unwrap();
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
fn list_children_at_root_surfaces_default_workspace_root_only() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let root_children = service.list_children(None).unwrap();
    assert_eq!(root_children.len(), 1);
    assert_eq!(root_children[0].display_name, "Default Workspace");
    assert_eq!(root_children[0].parent_uuid, None);
}

#[test]
fn root_level_creates_fall_back_to_default_workspace_root() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);
    let default_workspace_id = default_workspace_id(&conn);

    let note_atom = Atom::new(ViewHint::Note, "Note row");
    insert_atom(&conn, &note_atom);

    let created_folder = service.create_folder(None, "Loose folder").unwrap();
    assert_eq!(created_folder.parent_uuid, Some(default_workspace_id));

    let created_ref = service
        .create_atom_ref(None, note_atom.uuid, Some("Loose ref".to_string()))
        .unwrap();
    assert_eq!(created_ref.parent_uuid, Some(default_workspace_id));

    let root_children = service.list_children(None).unwrap();
    assert_eq!(root_children.len(), 1);

    let workspace_children = service.list_children(Some(default_workspace_id)).unwrap();
    assert!(workspace_children
        .iter()
        .any(|node| node.node_uuid == created_folder.node_uuid));
    assert!(workspace_children
        .iter()
        .any(|node| node.node_uuid == created_ref.node_uuid));
}

#[test]
fn create_and_list_children_keeps_deterministic_order() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);
    let default_workspace_id = default_workspace_id(&conn);

    let root = service.create_folder(None, "Root").unwrap();
    let child_a = service
        .create_folder(Some(root.node_uuid), "Alpha")
        .unwrap();
    let child_b = service.create_folder(Some(root.node_uuid), "Beta").unwrap();

    let root_children = service.list_children(None).unwrap();
    assert_eq!(root_children.len(), 1);
    assert_eq!(root_children[0].node_uuid, default_workspace_id);

    let workspace_children = service.list_children(Some(default_workspace_id)).unwrap();
    assert!(workspace_children
        .iter()
        .any(|node| node.node_uuid == root.node_uuid));

    let children = service.list_children(Some(root.node_uuid)).unwrap();
    assert_eq!(children.len(), 2);
    assert_eq!(children[0].node_uuid, child_a.node_uuid);
    assert_eq!(children[1].node_uuid, child_b.node_uuid);
    assert_eq!(children[0].sort_order, 0);
    assert_eq!(children[1].sort_order, 1);
}

#[test]
fn create_atom_ref_accepts_any_active_atom_type() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let task_atom = Atom::new(ViewHint::Task, "Task row");
    insert_atom(&conn, &task_atom);

    let atom_ref = service
        .create_atom_ref(None, task_atom.uuid, Some("TaskRef".to_string()))
        .unwrap();
    assert_eq!(atom_ref.kind, WorkspaceNodeKind::AtomRef);
    assert_eq!(atom_ref.atom_uuid, Some(task_atom.uuid));
}

#[test]
fn create_atom_ref_success_for_note_atom() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note_atom = Atom::new(ViewHint::Note, "Note row");
    insert_atom(&conn, &note_atom);

    let folder = service.create_folder(None, "Notes").unwrap();
    let atom_ref = service
        .create_atom_ref(Some(folder.node_uuid), note_atom.uuid, None)
        .unwrap();

    assert_eq!(atom_ref.kind, WorkspaceNodeKind::AtomRef);
    assert_eq!(atom_ref.parent_uuid, Some(folder.node_uuid));
    assert_eq!(atom_ref.atom_uuid, Some(note_atom.uuid));
    assert_eq!(atom_ref.display_name, "Untitled");
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
fn move_rejects_atom_ref_parent() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note_atom = Atom::new(ViewHint::Note, "Note row");
    insert_atom(&conn, &note_atom);

    let folder = service.create_folder(None, "Folder").unwrap();
    let note_ref = service
        .create_atom_ref(None, note_atom.uuid, Some("Ref".to_string()))
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
fn move_rejects_root_level_parent_after_0012() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let folder = service.create_folder(None, "Folder").unwrap();

    let err = service.move_node(folder.node_uuid, None, None).unwrap_err();
    assert!(matches!(
        err,
        TreeServiceError::CannotMoveToRoot(node_uuid) if node_uuid == folder.node_uuid
    ));
}

#[test]
fn repository_move_rejects_root_level_parent_after_0012() {
    let conn = setup();
    let repo = SqliteTreeRepository::try_new(&conn).unwrap();

    let folder = repo.create_folder(None, "Folder").unwrap();

    let err = repo.move_node(folder.node_uuid, None, None).unwrap_err();
    assert!(matches!(
        err,
        TreeRepoError::CannotMoveToRoot(node_uuid) if node_uuid == folder.node_uuid
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
fn rename_workspace_root_keeps_workspace_metadata_in_sync() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);
    let workspace_id = default_workspace_id(&conn);

    service
        .rename_node(workspace_id, "Renamed Workspace")
        .unwrap();

    let node_name: String = conn
        .query_row(
            "SELECT display_name
             FROM workspace_nodes
             WHERE node_uuid = ?1;",
            [workspace_id.to_string()],
            |row| row.get(0),
        )
        .unwrap();
    let metadata_name: String = conn
        .query_row(
            "SELECT name
             FROM workspaces
             WHERE workspace_id = ?1;",
            [workspace_id.to_string()],
            |row| row.get(0),
        )
        .unwrap();

    assert_eq!(node_name, "Renamed Workspace");
    assert_eq!(metadata_name, "Renamed Workspace");
}

#[test]
fn move_target_order_uses_visible_sibling_index_only() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note_hidden = Atom::new(ViewHint::Note, "hidden");
    let note_a = Atom::new(ViewHint::Note, "a");
    let note_b = Atom::new(ViewHint::Note, "b");
    insert_atom(&conn, &note_hidden);
    insert_atom(&conn, &note_a);
    insert_atom(&conn, &note_b);

    let root = service.create_folder(None, "Root").unwrap();
    let hidden_ref = service
        .create_atom_ref(
            Some(root.node_uuid),
            note_hidden.uuid,
            Some("hidden".to_string()),
        )
        .unwrap();
    let ref_a = service
        .create_atom_ref(Some(root.node_uuid), note_a.uuid, Some("A".to_string()))
        .unwrap();
    let ref_b = service
        .create_atom_ref(Some(root.node_uuid), note_b.uuid, Some("B".to_string()))
        .unwrap();

    // S4: soft-delete the workspace node (not the atom) to hide it.
    // The atoms_block_demote_when_referenced trigger prevents atom soft-delete
    // while active atom_refs exist.
    conn.execute(
        "UPDATE workspace_nodes SET is_deleted = 1, updated_at = (strftime('%s', 'now') * 1000) WHERE node_uuid = ?1;",
        rusqlite::params![hidden_ref.node_uuid.to_string()],
    )
    .unwrap();

    let before = service.list_children(Some(root.node_uuid)).unwrap();
    assert_eq!(before.len(), 2);
    assert_eq!(before[0].node_uuid, ref_a.node_uuid);
    assert_eq!(before[1].node_uuid, ref_b.node_uuid);

    service
        .move_node(ref_a.node_uuid, Some(root.node_uuid), Some(1))
        .unwrap();

    let after = service.list_children(Some(root.node_uuid)).unwrap();
    assert_eq!(after.len(), 2);
    assert_eq!(after[0].node_uuid, ref_b.node_uuid);
    assert_eq!(after[1].node_uuid, ref_a.node_uuid);

    // Hidden soft-deleted sibling should remain hidden and not occupy visible order slots.
    let hidden_still_filtered = after
        .iter()
        .all(|item| item.node_uuid != hidden_ref.node_uuid);
    assert!(hidden_still_filtered);
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

#[test]
fn soft_deleted_atom_ref_is_filtered_and_restores_on_node_restore() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let tree_service = TreeService::new(tree_repo);

    let note_atom = Atom::new(ViewHint::Note, "note");
    insert_atom(&conn, &note_atom);
    let root = tree_service.create_folder(None, "Root").unwrap();
    let atom_ref = tree_service
        .create_atom_ref(
            Some(root.node_uuid),
            note_atom.uuid,
            Some("ref".to_string()),
        )
        .unwrap();

    let before_delete = tree_service.list_children(Some(root.node_uuid)).unwrap();
    assert_eq!(before_delete.len(), 1);
    assert_eq!(before_delete[0].node_uuid, atom_ref.node_uuid);

    // S4: soft-delete the workspace node to hide the reference.
    // atoms_block_demote_when_referenced trigger prevents direct atom soft-delete
    // while active atom_refs exist.
    conn.execute(
        "UPDATE workspace_nodes SET is_deleted = 1, updated_at = (strftime('%s', 'now') * 1000) WHERE node_uuid = ?1;",
        rusqlite::params![atom_ref.node_uuid.to_string()],
    )
    .unwrap();

    let after_delete = tree_service.list_children(Some(root.node_uuid)).unwrap();
    assert!(after_delete.is_empty());

    // Restore the workspace node.
    conn.execute(
        "UPDATE workspace_nodes SET is_deleted = 0, updated_at = (strftime('%s', 'now') * 1000) WHERE node_uuid = ?1;",
        rusqlite::params![atom_ref.node_uuid.to_string()],
    )
    .unwrap();

    let after_restore = tree_service.list_children(Some(root.node_uuid)).unwrap();
    assert_eq!(after_restore.len(), 1);
    assert_eq!(after_restore[0].node_uuid, atom_ref.node_uuid);
}

#[test]
fn delete_folder_dissolve_moves_direct_children_to_root() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);
    let default_workspace_id = default_workspace_id(&conn);

    let note_a = Atom::new(ViewHint::Note, "A");
    let note_b = Atom::new(ViewHint::Note, "B");
    insert_atom(&conn, &note_a);
    insert_atom(&conn, &note_b);

    let folder = service.create_folder(None, "Group").unwrap();
    let direct_note_ref = service
        .create_atom_ref(
            Some(folder.node_uuid),
            note_a.uuid,
            Some("Direct".to_string()),
        )
        .unwrap();
    let child_folder = service
        .create_folder(Some(folder.node_uuid), "ChildFolder")
        .unwrap();
    let nested_note_ref = service
        .create_atom_ref(
            Some(child_folder.node_uuid),
            note_b.uuid,
            Some("Nested".to_string()),
        )
        .unwrap();

    service
        .delete_folder(folder.node_uuid, FolderDeleteMode::Dissolve)
        .unwrap();

    let workspace_children = service.list_children(Some(default_workspace_id)).unwrap();
    let workspace_ids: Vec<_> = workspace_children
        .iter()
        .map(|item| item.node_uuid)
        .collect();
    assert!(workspace_ids.contains(&direct_note_ref.node_uuid));
    assert!(workspace_ids.contains(&child_folder.node_uuid));
    assert!(!workspace_ids.contains(&folder.node_uuid));

    let nested_children = service.list_children(Some(child_folder.node_uuid)).unwrap();
    assert_eq!(nested_children.len(), 1);
    assert_eq!(nested_children[0].node_uuid, nested_note_ref.node_uuid);
}

#[test]
fn delete_folder_delete_all_soft_deletes_unique_atoms_only() {
    let conn = setup();
    let atom_repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);
    let default_workspace_id = default_workspace_id(&conn);

    let note_only_in_target = Atom::new(ViewHint::Note, "target-only");
    let note_shared = Atom::new(ViewHint::Note, "shared");
    insert_atom(&conn, &note_only_in_target);
    insert_atom(&conn, &note_shared);

    let target_folder = service.create_folder(None, "Target").unwrap();
    let other_folder = service.create_folder(None, "Other").unwrap();

    service
        .create_atom_ref(
            Some(target_folder.node_uuid),
            note_only_in_target.uuid,
            Some("target-only".to_string()),
        )
        .unwrap();
    let shared_ref_in_target = service
        .create_atom_ref(
            Some(target_folder.node_uuid),
            note_shared.uuid,
            Some("shared-target".to_string()),
        )
        .unwrap();
    let shared_ref_in_other = service
        .create_atom_ref(
            Some(other_folder.node_uuid),
            note_shared.uuid,
            Some("shared-other".to_string()),
        )
        .unwrap();

    service
        .delete_folder(target_folder.node_uuid, FolderDeleteMode::DeleteAll)
        .unwrap();

    let target_children_err = service
        .list_children(Some(target_folder.node_uuid))
        .unwrap_err();
    assert!(matches!(
        target_children_err,
        TreeServiceError::ParentNotFound(id) if id == target_folder.node_uuid
    ));

    let workspace_children = service.list_children(Some(default_workspace_id)).unwrap();
    let workspace_ids: Vec<_> = workspace_children
        .iter()
        .map(|item| item.node_uuid)
        .collect();
    assert!(!workspace_ids.contains(&target_folder.node_uuid));
    assert!(workspace_ids.contains(&other_folder.node_uuid));

    let shared_in_other_children = service.list_children(Some(other_folder.node_uuid)).unwrap();
    assert_eq!(shared_in_other_children.len(), 1);
    assert_eq!(
        shared_in_other_children[0].node_uuid,
        shared_ref_in_other.node_uuid
    );

    let deleted_ref_in_target_visible = workspace_children
        .iter()
        .any(|item| item.node_uuid == shared_ref_in_target.node_uuid);
    assert!(!deleted_ref_in_target_visible);

    let only_target_atom = atom_repo
        .get_atom(note_only_in_target.uuid, true)
        .unwrap()
        .unwrap();
    assert!(only_target_atom.is_deleted);

    let shared_atom = atom_repo.get_atom(note_shared.uuid, true).unwrap().unwrap();
    assert!(!shared_atom.is_deleted);
}

#[test]
fn move_node_rolls_back_when_reorder_fails() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let source_root = service.create_folder(None, "Source").unwrap();
    let _source_a = service
        .create_folder(Some(source_root.node_uuid), "A")
        .unwrap();
    let _source_b = service
        .create_folder(Some(source_root.node_uuid), "B")
        .unwrap();
    let moving = service
        .create_folder(Some(source_root.node_uuid), "Moving")
        .unwrap();

    let target_root = service.create_folder(None, "Target").unwrap();
    let _target_x = service
        .create_folder(Some(target_root.node_uuid), "X")
        .unwrap();
    let target_y = service
        .create_folder(Some(target_root.node_uuid), "Y")
        .unwrap();

    conn.execute_batch(&format!(
        "CREATE TRIGGER workspace_nodes_fail_sort_update_test
         BEFORE UPDATE OF sort_order ON workspace_nodes
         WHEN NEW.node_uuid = '{}'
         BEGIN
             SELECT RAISE(ABORT, 'forced sort failure');
         END;",
        target_y.node_uuid
    ))
    .unwrap();

    let move_result = service.move_node(moving.node_uuid, Some(target_root.node_uuid), Some(0));
    assert!(move_result.is_err());

    let source_children = service.list_children(Some(source_root.node_uuid)).unwrap();
    let source_ids: Vec<_> = source_children.iter().map(|item| item.node_uuid).collect();
    assert!(source_ids.contains(&moving.node_uuid));

    let target_children = service.list_children(Some(target_root.node_uuid)).unwrap();
    let target_ids: Vec<_> = target_children.iter().map(|item| item.node_uuid).collect();
    assert!(!target_ids.contains(&moving.node_uuid));
}

// ── ancestor_path tests (PR-RB-10) ─────────────────────────────────

#[test]
fn ancestor_path_root_level_atom_ref_returns_empty() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note = Atom::new(ViewHint::Note, "root note");
    insert_atom(&conn, &note);

    service
        .create_atom_ref(None, note.uuid, Some("RootNote".to_string()))
        .unwrap();

    let path = service.ancestor_path(note.uuid).unwrap();
    assert!(
        path.is_empty(),
        "root-level atom_ref should return empty path"
    );
}

#[test]
fn ancestor_path_single_level_nesting() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note = Atom::new(ViewHint::Note, "nested note");
    insert_atom(&conn, &note);

    let folder = service.create_folder(None, "Projects").unwrap();
    service
        .create_atom_ref(Some(folder.node_uuid), note.uuid, Some("Note".to_string()))
        .unwrap();

    let path = service.ancestor_path(note.uuid).unwrap();
    assert_eq!(path, vec!["Projects"]);
}

#[test]
fn ancestor_path_deep_nesting() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note = Atom::new(ViewHint::Note, "deep note");
    insert_atom(&conn, &note);

    let folder_a = service.create_folder(None, "Work").unwrap();
    let folder_b = service
        .create_folder(Some(folder_a.node_uuid), "Engineering")
        .unwrap();
    let folder_c = service
        .create_folder(Some(folder_b.node_uuid), "Backend")
        .unwrap();
    service
        .create_atom_ref(
            Some(folder_c.node_uuid),
            note.uuid,
            Some("Note".to_string()),
        )
        .unwrap();

    let path = service.ancestor_path(note.uuid).unwrap();
    assert_eq!(path, vec!["Work", "Engineering", "Backend"]);
}

#[test]
fn ancestor_path_nonexistent_atom_returns_empty() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let unknown_atom = Uuid::new_v4();
    let path = service.ancestor_path(unknown_atom).unwrap();
    assert!(path.is_empty(), "nonexistent atom should return empty path");
}

#[test]
fn ancestor_path_soft_deleted_ref_is_excluded() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note = Atom::new(ViewHint::Note, "deleted ref");
    insert_atom(&conn, &note);

    let folder = service.create_folder(None, "Archive").unwrap();
    let atom_ref = service
        .create_atom_ref(Some(folder.node_uuid), note.uuid, Some("Ref".to_string()))
        .unwrap();

    // Soft-delete the atom_ref node
    conn.execute(
        "UPDATE workspace_nodes SET is_deleted = 1, updated_at = (strftime('%s', 'now') * 1000) WHERE node_uuid = ?1;",
        rusqlite::params![atom_ref.node_uuid.to_string()],
    )
    .unwrap();

    let path = service.ancestor_path(note.uuid).unwrap();
    assert!(path.is_empty(), "soft-deleted atom_ref should be excluded");
}

#[test]
fn ancestor_path_soft_deleted_folder_in_chain_is_excluded() {
    let conn = setup();
    let tree_repo = SqliteTreeRepository::try_new(&conn).unwrap();
    let service = TreeService::new(tree_repo);

    let note = Atom::new(ViewHint::Note, "note in deleted folder");
    insert_atom(&conn, &note);

    let folder_a = service.create_folder(None, "Top").unwrap();
    let folder_b = service
        .create_folder(Some(folder_a.node_uuid), "Middle")
        .unwrap();
    service
        .create_atom_ref(Some(folder_b.node_uuid), note.uuid, Some("Ref".to_string()))
        .unwrap();

    // Soft-delete the top-level folder
    conn.execute(
        "UPDATE workspace_nodes SET is_deleted = 1, updated_at = (strftime('%s', 'now') * 1000) WHERE node_uuid = ?1;",
        rusqlite::params![folder_a.node_uuid.to_string()],
    )
    .unwrap();

    let path = service.ancestor_path(note.uuid).unwrap();
    // Only "Middle" is returned since "Top" is soft-deleted and the CTE stops
    assert_eq!(path, vec!["Middle"]);
}
