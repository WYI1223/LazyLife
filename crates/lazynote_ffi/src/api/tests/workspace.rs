use super::*;
use lazynote_core::db::open_db;
use uuid::Uuid;

#[test]
fn workspace_list_returns_default_workspace() {
    let _guard = acquire_test_db_lock();
    let response = workspace_list_impl(default_caller());
    assert!(response.ok, "{}", response.message);
    assert!(response
        .workspaces
        .iter()
        .any(|workspace| workspace.is_default));
}

#[test]
fn workspace_list_filters_to_readable_subset_under_guard() {
    let _guard = acquire_test_db_lock();
    let default_workspace = default_workspace_node_id();
    let _other_workspace = insert_workspace_root_for_test("Other Workspace");

    let response = workspace_list_impl_with_guard(
        default_caller(),
        Box::new(SelectiveWorkspaceReadGuard {
            allowed_workspace: Uuid::parse_str(&default_workspace).expect("default workspace uuid"),
        }),
    );
    assert!(response.ok, "{}", response.message);
    assert_eq!(response.workspaces.len(), 1);
    assert_eq!(
        response.workspaces[0].workspace_id.as_str(),
        default_workspace.as_str()
    );
}

#[test]
fn workspace_get_default_returns_default_workspace() {
    let _guard = acquire_test_db_lock();
    let expected_id = default_workspace_node_id();
    let response = workspace_get_default_impl(default_caller());
    assert!(response.ok, "{}", response.message);
    assert_eq!(
        response
            .workspace
            .as_ref()
            .map(|workspace| workspace.workspace_id.as_str()),
        Some(expected_id.as_str())
    );
}

#[test]
fn workspace_resolve_designated_returns_inbox_folder() {
    let _guard = acquire_test_db_lock();
    let workspace_id = default_workspace_node_id();
    let expected = designated_folder_node_id("inbox");

    let response =
        workspace_resolve_designated_impl(default_caller(), workspace_id, "inbox".to_string());
    assert!(response.ok, "{}", response.message);
    assert_eq!(response.node_uuid.as_deref(), Some(expected.as_str()));
}

#[test]
fn workspace_resolve_designated_returns_workspace_not_found_for_unknown_workspace() {
    let _guard = acquire_test_db_lock();
    let response = workspace_resolve_designated_impl(
        default_caller(),
        Uuid::new_v4().to_string(),
        "inbox".to_string(),
    );
    assert!(!response.ok, "expected failure for unknown workspace");
    assert_eq!(response.error_code.as_deref(), Some("workspace_not_found"));
}

#[test]
fn workspace_reassign_designated_updates_role_target() {
    let _guard = acquire_test_db_lock();
    let workspace_id = default_workspace_node_id();
    let folder = workspace_create_folder_impl(None, unique_token("reassign-folder"));
    assert!(folder.ok, "{}", folder.message);
    let folder_id = folder.node.expect("folder node").node_id;

    let action = workspace_reassign_designated_impl(
        default_caller(),
        workspace_id.clone(),
        "inbox".to_string(),
        folder_id.clone(),
    );
    assert!(action.ok, "{}", action.message);

    let resolved =
        workspace_resolve_designated_impl(default_caller(), workspace_id, "inbox".to_string());
    assert!(resolved.ok, "{}", resolved.message);
    assert_eq!(resolved.node_uuid.as_deref(), Some(folder_id.as_str()));
}

#[test]
fn workspace_reassign_designated_returns_workspace_not_found_for_unknown_workspace() {
    let _guard = acquire_test_db_lock();
    let folder = workspace_create_folder_impl(None, unique_token("missing-workspace-folder"));
    assert!(folder.ok, "{}", folder.message);
    let folder_id = folder.node.expect("folder node").node_id;

    let action = workspace_reassign_designated_impl(
        default_caller(),
        Uuid::new_v4().to_string(),
        "inbox".to_string(),
        folder_id,
    );
    assert!(!action.ok, "expected missing workspace failure");
    assert_eq!(action.error_code.as_deref(), Some("workspace_not_found"));
}

#[test]
fn workspace_reassign_designated_rejects_folder_outside_workspace() {
    let _guard = acquire_test_db_lock();
    let default_workspace = default_workspace_node_id();
    let other_workspace = insert_workspace_root_for_test("Other Workspace");
    let folder = workspace_create_folder_impl(
        Some(other_workspace),
        unique_token("foreign-designated-folder"),
    );
    assert!(folder.ok, "{}", folder.message);
    let folder_id = folder.node.expect("folder node").node_id;

    let action = workspace_reassign_designated_impl(
        default_caller(),
        default_workspace,
        "inbox".to_string(),
        folder_id,
    );
    assert!(!action.ok, "expected cross-workspace reassign failure");
    assert_eq!(
        action.error_code.as_deref(),
        Some("target_folder_not_in_workspace")
    );
}

#[test]
fn workspace_get_ancestor_path_returns_node_segments() {
    let _guard = acquire_test_db_lock();
    let folder_name = unique_token("path-folder");
    let folder = workspace_create_folder_impl(None, folder_name.clone());
    assert!(folder.ok, "{}", folder.message);
    let folder_id = folder.node.expect("folder node").node_id;
    let created = note_create_impl("path child".to_string(), Some(folder_id));
    assert!(created.ok, "{}", created.message);
    let node_uuid = created.node_uuid.expect("node uuid");

    let response = workspace_get_ancestor_path_impl(default_caller(), node_uuid);
    assert!(response.ok, "{}", response.message);
    assert_eq!(
        response
            .segments
            .last()
            .map(|segment| segment.display_name.as_str()),
        Some(folder_name.as_str())
    );
}

#[test]
fn workspace_list_atom_refs_for_atom_returns_ref_locations() {
    let _guard = acquire_test_db_lock();
    let folder_name = unique_token("atom-ref-folder");
    let folder = workspace_create_folder_impl(None, folder_name.clone());
    assert!(folder.ok, "{}", folder.message);
    let folder_id = folder.node.expect("folder node").node_id;
    let created = note_create_impl("ref location".to_string(), Some(folder_id));
    assert!(created.ok, "{}", created.message);
    let atom_uuid = created.item.as_ref().expect("note payload").atom_id.clone();

    let response = workspace_list_atom_refs_for_atom_impl(default_caller(), atom_uuid);
    assert!(response.ok, "{}", response.message);
    assert!(response
        .locations
        .iter()
        .any(|location| location.path.contains(folder_name.as_str())));
}

#[test]
fn workspace_create_folder_returns_node_payload() {
    let _guard = acquire_test_db_lock();
    let name = unique_token("workspace-folder");
    let response = workspace_create_folder_impl(None, name.clone());
    assert!(response.ok, "{}", response.message);
    let node = response.node.expect("workspace node payload");
    let default_workspace_id = default_workspace_node_id();
    assert_eq!(node.kind, "folder");
    assert_eq!(node.display_name, name);
    assert!(uuid::Uuid::parse_str(node.node_id.as_str()).is_ok());
    assert_eq!(
        node.parent_node_id.as_deref(),
        Some(default_workspace_id.as_str())
    );
    assert!(node.atom_id.is_none());
}

#[test]
fn workspace_create_folder_rejects_invalid_parent_node_id() {
    let _guard = acquire_test_db_lock();
    let response =
        workspace_create_folder_impl(Some("not-a-uuid".to_string()), "invalid parent".to_string());
    assert!(!response.ok);
    assert_eq!(
        response.error_code.as_deref(),
        Some("invalid_parent_node_id")
    );
}

#[test]
fn workspace_create_folder_maps_parent_not_found_error_code() {
    let _guard = acquire_test_db_lock();
    let missing_parent = uuid::Uuid::new_v4().to_string();
    let response = workspace_create_folder_impl(Some(missing_parent), "child-folder".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("parent_not_found"));
}

#[test]
fn workspace_create_folder_maps_parent_not_folder_error_code() {
    let _guard = acquire_test_db_lock();
    let parent_atom_ref = create_workspace_atom_ref_node();
    let response = workspace_create_folder_impl(Some(parent_atom_ref), "child-folder".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("parent_not_folder"));
}

#[test]
fn workspace_list_children_returns_created_root_folder() {
    let _guard = acquire_test_db_lock();
    let name = unique_token("workspace-list-root");
    let created_id = create_workspace_folder_via_ffi(name.as_str());
    let default_workspace_id = default_workspace_node_id();

    let response = workspace_list_children_impl(Some(default_workspace_id));
    assert!(response.ok, "{}", response.message);
    assert!(
        response
            .items
            .iter()
            .any(|item| item.node_id == created_id && item.display_name == name),
        "created folder should appear under the default workspace root"
    );
}

#[test]
fn workspace_create_atom_ref_rejects_invalid_atom_id() {
    let _guard = acquire_test_db_lock();
    let response = workspace_create_atom_ref_impl(None, "not-a-uuid".to_string(), None);
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("invalid_atom_id"));
}

#[test]
fn workspace_create_atom_ref_maps_atom_not_found_error_code() {
    let _guard = acquire_test_db_lock();
    let missing_atom = uuid::Uuid::new_v4().to_string();
    let response = workspace_create_atom_ref_impl(None, missing_atom, None);
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("atom_not_found"));
}

#[test]
fn workspace_create_atom_ref_accepts_task_atom() {
    let _guard = acquire_test_db_lock();
    let created = entry_create_task_impl("workspace task".to_string());
    assert!(created.ok, "{}", created.message);
    let atom_id = created.atom_id.expect("task atom id");
    let response = workspace_create_atom_ref_impl(None, atom_id, None);
    assert!(
        response.ok,
        "atom_ref should accept task atoms: {}",
        response.message
    );
    let node = response.node.expect("workspace node payload");
    assert_eq!(node.kind, "atom_ref");
}

#[test]
fn workspace_rename_node_rejects_blank_name() {
    let _guard = acquire_test_db_lock();
    let node_id = create_workspace_folder_via_ffi("rename-target");
    let response = workspace_rename_node_impl(node_id, "   ".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("invalid_display_name"));
}

#[test]
fn workspace_rename_root_keeps_workspace_metadata_in_sync() {
    let _guard = acquire_test_db_lock();
    let conn = open_db(super::super::resolve_entry_db_path()).unwrap();
    let workspace_id: String = conn
        .query_row(
            "SELECT workspace_id FROM workspaces WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .unwrap();
    drop(conn);

    let response =
        workspace_rename_node_impl(workspace_id.clone(), "Renamed Workspace".to_string());
    assert!(response.ok, "{}", response.message);

    let verify_conn = open_db(super::super::resolve_entry_db_path()).unwrap();
    let node_name: String = verify_conn
        .query_row(
            "SELECT display_name
             FROM workspace_nodes
             WHERE node_uuid = ?1;",
            [workspace_id.as_str()],
            |row| row.get(0),
        )
        .unwrap();
    let metadata_name: String = verify_conn
        .query_row(
            "SELECT name
             FROM workspaces
             WHERE workspace_id = ?1;",
            [workspace_id.as_str()],
            |row| row.get(0),
        )
        .unwrap();

    assert_eq!(node_name, "Renamed Workspace");
    assert_eq!(metadata_name, "Renamed Workspace");
}

#[test]
fn workspace_move_node_rejects_cycle() {
    let _guard = acquire_test_db_lock();
    let parent_id = create_workspace_folder_via_ffi("move-parent");
    let child_response =
        workspace_create_folder_impl(Some(parent_id.clone()), "move-child".to_string());
    assert!(child_response.ok, "{}", child_response.message);
    let child_id = child_response
        .node
        .expect("child node payload")
        .node_id
        .to_string();

    let move_response = workspace_move_node_impl(parent_id, Some(child_id), None);
    assert!(!move_response.ok);
    assert_eq!(move_response.error_code.as_deref(), Some("cycle_detected"));
}

#[test]
fn workspace_move_node_rejects_root_level_target() {
    let _guard = acquire_test_db_lock();
    let node_id = create_workspace_folder_via_ffi("move-root-target");

    let response = workspace_move_node_impl(node_id, None, None);
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("cannot_move_to_root"));
}

#[test]
fn workspace_delete_folder_rejects_invalid_node_id() {
    let _guard = acquire_test_db_lock();
    let response = workspace_delete_folder_impl("not-a-uuid".to_string(), "dissolve".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("invalid_node_id"));
}

#[test]
fn workspace_delete_folder_rejects_invalid_mode() {
    let _guard = acquire_test_db_lock();
    let folder_id = create_workspace_folder("invalid-mode");
    let response = workspace_delete_folder_impl(folder_id, "archive".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("invalid_delete_mode"));
}

#[test]
fn workspace_delete_folder_maps_node_not_found_error_code() {
    let _guard = acquire_test_db_lock();
    let random_id = uuid::Uuid::new_v4().to_string();
    let response = workspace_delete_folder_impl(random_id, "dissolve".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("node_not_found"));
}

#[test]
fn workspace_delete_folder_maps_node_not_folder_error_code() {
    let _guard = acquire_test_db_lock();
    let node_id = create_workspace_atom_ref_node();
    let response = workspace_delete_folder_impl(node_id, "dissolve".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("node_not_folder"));
}

#[test]
fn workspace_delete_folder_rejects_designated_folder_via_service_guard() {
    let _guard = acquire_test_db_lock();
    let inbox_folder_id = designated_folder_node_id("inbox");

    let response = workspace_delete_folder_impl(inbox_folder_id, "dissolve".to_string());
    assert!(!response.ok);
    assert_eq!(response.error_code.as_deref(), Some("internal_error"));
    assert!(
        response.message.contains("designated folder"),
        "FFI should surface designated-folder protection instead of raw DB trigger failure"
    );
}

#[test]
fn workspace_delete_folder_supports_both_modes() {
    let _guard = acquire_test_db_lock();
    let dissolve_folder = create_workspace_folder("dissolve-ok");
    let delete_all_folder = create_workspace_folder("delete-all-ok");

    let dissolve_response = workspace_delete_folder_impl(dissolve_folder, "dissolve".to_string());
    assert!(dissolve_response.ok, "{}", dissolve_response.message);
    assert!(dissolve_response.error_code.is_none());

    let delete_all_response =
        workspace_delete_folder_impl(delete_all_folder, "delete_all".to_string());
    assert!(delete_all_response.ok, "{}", delete_all_response.message);
    assert!(delete_all_response.error_code.is_none());
}
