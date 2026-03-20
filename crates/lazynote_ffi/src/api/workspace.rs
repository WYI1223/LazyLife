use super::*;

/// Lists direct children under an optional workspace parent node.
#[flutter_rust_bridge::frb]
pub async fn workspace_list_children(
    parent_node_id: Option<String>,
) -> WorkspaceListChildrenResponse {
    workspace_list_children_impl(parent_node_id)
}

pub(super) fn workspace_list_children_impl(
    parent_node_id: Option<String>,
) -> WorkspaceListChildrenResponse {
    let parsed_parent = match parse_optional_parent_node_id(parent_node_id) {
        Ok(value) => value,
        Err(err) => return workspace_list_failure(err),
    };

    match with_tree_service(|service| service.list_children(parsed_parent)) {
        Ok(nodes) => WorkspaceListChildrenResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} workspace node(s).", nodes.len()),
            items: nodes.into_iter().map(to_workspace_node_item).collect(),
        },
        Err(err) => workspace_list_failure(err),
    }
}

/// Creates one workspace folder under optional parent.
#[flutter_rust_bridge::frb]
pub async fn workspace_create_folder(
    parent_node_id: Option<String>,
    name: String,
) -> WorkspaceNodeResponse {
    workspace_create_folder_impl(parent_node_id, name)
}

pub(super) fn workspace_create_folder_impl(
    parent_node_id: Option<String>,
    name: String,
) -> WorkspaceNodeResponse {
    let parsed_parent = match parse_optional_parent_node_id(parent_node_id) {
        Ok(value) => value,
        Err(err) => return workspace_node_failure(err),
    };

    match with_tree_service(|service| service.create_folder(parsed_parent, name)) {
        Ok(node) => WorkspaceNodeResponse {
            ok: true,
            error_code: None,
            message: "Workspace folder created.".to_string(),
            node: Some(to_workspace_node_item(node)),
        },
        Err(err) => workspace_node_failure(err),
    }
}

/// Creates one workspace atom_ref under optional parent.
#[flutter_rust_bridge::frb]
pub async fn workspace_create_atom_ref(
    parent_node_id: Option<String>,
    atom_id: String,
    display_name: Option<String>,
) -> WorkspaceNodeResponse {
    workspace_create_atom_ref_impl(parent_node_id, atom_id, display_name)
}

pub(super) fn workspace_create_atom_ref_impl(
    parent_node_id: Option<String>,
    atom_id: String,
    display_name: Option<String>,
) -> WorkspaceNodeResponse {
    let parsed_parent = match parse_optional_parent_node_id(parent_node_id) {
        Ok(value) => value,
        Err(err) => return workspace_node_failure(err),
    };
    let parsed_atom_id = match parse_workspace_atom_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_node_failure(err),
    };

    match with_tree_service(|service| {
        service.create_atom_ref(parsed_parent, parsed_atom_id, display_name)
    }) {
        Ok(node) => WorkspaceNodeResponse {
            ok: true,
            error_code: None,
            message: "Workspace atom reference created.".to_string(),
            node: Some(to_workspace_node_item(node)),
        },
        Err(err) => workspace_node_failure(err),
    }
}

/// Renames one workspace node.
#[flutter_rust_bridge::frb]
pub async fn workspace_rename_node(node_id: String, new_name: String) -> WorkspaceActionResponse {
    workspace_rename_node_impl(node_id, new_name)
}

pub(super) fn workspace_rename_node_impl(
    node_id: String,
    new_name: String,
) -> WorkspaceActionResponse {
    let parsed_id = match parse_workspace_node_id(node_id.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_failure(err),
    };
    match with_tree_service(|service| service.rename_node(parsed_id, new_name)) {
        Ok(()) => WorkspaceActionResponse {
            ok: true,
            error_code: None,
            message: "Workspace node renamed.".to_string(),
        },
        Err(err) => workspace_failure(err),
    }
}

/// Moves one workspace node under optional new parent and target order.
#[flutter_rust_bridge::frb]
pub async fn workspace_move_node(
    node_id: String,
    new_parent_id: Option<String>,
    target_order: Option<i64>,
) -> WorkspaceActionResponse {
    workspace_move_node_impl(node_id, new_parent_id, target_order)
}

pub(super) fn workspace_move_node_impl(
    node_id: String,
    new_parent_id: Option<String>,
    target_order: Option<i64>,
) -> WorkspaceActionResponse {
    let parsed_id = match parse_workspace_node_id(node_id.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_failure(err),
    };
    let parsed_parent = match parse_optional_parent_node_id(new_parent_id) {
        Ok(value) => value,
        Err(err) => return workspace_failure(err),
    };

    match with_tree_service(|service| service.move_node(parsed_id, parsed_parent, target_order)) {
        Ok(()) => WorkspaceActionResponse {
            ok: true,
            error_code: None,
            message: "Workspace node moved.".to_string(),
        },
        Err(err) => workspace_failure(err),
    }
}

/// Deletes one workspace folder by explicit mode (`dissolve|delete_all`).
#[flutter_rust_bridge::frb]
pub async fn workspace_delete_folder(node_id: String, mode: String) -> WorkspaceActionResponse {
    workspace_delete_folder_impl(node_id, mode)
}

pub(super) fn workspace_delete_folder_impl(
    node_id: String,
    mode: String,
) -> WorkspaceActionResponse {
    let parsed_id = match parse_workspace_node_id(node_id.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_failure(err),
    };

    let parsed_mode = match parse_folder_delete_mode(mode.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_failure(err),
    };

    match with_tree_service(|service| service.delete_folder(parsed_id, parsed_mode)) {
        Ok(()) => WorkspaceActionResponse {
            ok: true,
            error_code: None,
            message: "Workspace folder deleted.".to_string(),
        },
        Err(err) => workspace_failure(err),
    }
}

/// Returns ancestor folder display_names for an atom's first active `atom_ref`.
#[flutter_rust_bridge::frb]
pub async fn workspace_ancestor_path(atom_id: String) -> WorkspaceAncestorPathResponse {
    workspace_ancestor_path_impl(atom_id)
}

pub(super) fn workspace_ancestor_path_impl(atom_id: String) -> WorkspaceAncestorPathResponse {
    let parsed_atom_id = match parse_workspace_atom_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_ancestor_path_failure(err),
    };

    match with_tree_service(|service| service.ancestor_path(parsed_atom_id)) {
        Ok(path) => WorkspaceAncestorPathResponse {
            ok: true,
            error_code: None,
            message: format!("Resolved {} ancestor segment(s).", path.len()),
            path,
        },
        Err(err) => workspace_ancestor_path_failure(err),
    }
}

/// Lists workspaces through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn workspace_list(caller: FfiCallerContext) -> WorkspaceListResponse {
    workspace_list_impl(caller)
}

pub(super) fn workspace_list_impl(caller: FfiCallerContext) -> WorkspaceListResponse {
    workspace_list_impl_with_noop_guard(caller)
}

fn workspace_list_impl_with_noop_guard(caller: FfiCallerContext) -> WorkspaceListResponse {
    workspace_list_impl_inner(caller, Box::new(NoopGuard))
}

fn workspace_list_impl_inner(
    caller: FfiCallerContext,
    guard: Box<dyn AccessGuard>,
) -> WorkspaceListResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return guarded_workspace_list_failure(err),
    };

    match with_guarded_workspace_service_using_guard(guard, |service| {
        service.list_workspaces(&caller)
    }) {
        Ok(workspaces) => WorkspaceListResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} workspace(s).", workspaces.len()),
            workspaces: workspaces.into_iter().map(to_workspace_info).collect(),
        },
        Err(err) => guarded_workspace_list_failure(err),
    }
}

#[cfg(test)]
pub(super) fn workspace_list_impl_with_guard(
    caller: FfiCallerContext,
    guard: Box<dyn AccessGuard>,
) -> WorkspaceListResponse {
    workspace_list_impl_inner(caller, guard)
}

/// Loads the default workspace through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn workspace_get_default(caller: FfiCallerContext) -> WorkspaceInfoResponse {
    workspace_get_default_impl(caller)
}

pub(super) fn workspace_get_default_impl(caller: FfiCallerContext) -> WorkspaceInfoResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return guarded_workspace_info_failure(err),
    };

    match with_guarded_workspace_service(|service| service.get_default_workspace(&caller)) {
        Ok(workspace) => WorkspaceInfoResponse {
            ok: true,
            error_code: None,
            message: match &workspace {
                Some(_) => "Default workspace resolved.".to_string(),
                None => "Default workspace not configured.".to_string(),
            },
            workspace: workspace.map(to_workspace_info),
        },
        Err(err) => guarded_workspace_info_failure(err),
    }
}

/// Resolves one designated folder through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn workspace_resolve_designated(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,
) -> DesignatedFolderResponse {
    workspace_resolve_designated_impl(caller, workspace_id, role)
}

pub(super) fn workspace_resolve_designated_impl(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,
) -> DesignatedFolderResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return designated_folder_failure(err),
    };
    let workspace_id = match parse_guarded_workspace_id(workspace_id.as_str()) {
        Ok(value) => value,
        Err(err) => return designated_folder_failure(err),
    };

    match with_guarded_workspace_service(|service| {
        service.resolve_designated(&caller, workspace_id, role.as_str())
    }) {
        Ok(Some(node_uuid)) => DesignatedFolderResponse {
            ok: true,
            error_code: None,
            message: "Designated folder resolved.".to_string(),
            node_uuid: Some(node_uuid.to_string()),
        },
        Ok(None) => match guarded_workspace_exists(workspace_id) {
            Ok(true) => designated_folder_failure(GuardedFfiError::DesignatedRoleNotFound(
                format!("designated role `{role}` not found for workspace `{workspace_id}`"),
            )),
            Ok(false) => designated_folder_failure(GuardedFfiError::WorkspaceNotFound(
                workspace_id.to_string(),
            )),
            Err(err) => designated_folder_failure(err),
        },
        Err(err) => designated_folder_failure(err),
    }
}

/// Reassigns one designated folder through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn workspace_reassign_designated(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,
    new_node_uuid: String,
) -> WorkspaceActionResponse {
    workspace_reassign_designated_impl(caller, workspace_id, role, new_node_uuid)
}

pub(super) fn workspace_reassign_designated_impl(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,
    new_node_uuid: String,
) -> WorkspaceActionResponse {
    workspace_reassign_designated_impl_with_noop_guard(caller, workspace_id, role, new_node_uuid)
}

fn workspace_reassign_designated_impl_with_noop_guard(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,
    new_node_uuid: String,
) -> WorkspaceActionResponse {
    workspace_reassign_designated_impl_inner(
        caller,
        workspace_id,
        role,
        new_node_uuid,
        Box::new(NoopGuard),
    )
}

fn workspace_reassign_designated_impl_inner(
    caller: FfiCallerContext,
    workspace_id: String,
    role: String,
    new_node_uuid: String,
    guard: Box<dyn AccessGuard>,
) -> WorkspaceActionResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return workspace_failure_from_guarded(err),
    };
    let workspace_id = match parse_guarded_workspace_id(workspace_id.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_failure_from_guarded(err),
    };
    let new_node_uuid = match parse_guarded_node_id(new_node_uuid.as_str()) {
        Ok(value) => value,
        Err(err) => return workspace_failure_from_guarded(err),
    };

    match with_guarded_tree_service_raw_using_guard(guard, |service| {
        service.reassign_designated(&caller, workspace_id, role.as_str(), new_node_uuid)
    }) {
        Ok(()) => WorkspaceActionResponse {
            ok: true,
            error_code: None,
            message: "Designated folder reassigned.".to_string(),
        },
        Err(err) => workspace_reassign_failure(err, workspace_id, new_node_uuid),
    }
}

/// Returns node-based ancestor path through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn workspace_get_ancestor_path(
    caller: FfiCallerContext,
    node_uuid: String,
) -> AncestorPathResponse {
    workspace_get_ancestor_path_impl(caller, node_uuid)
}

pub(super) fn workspace_get_ancestor_path_impl(
    caller: FfiCallerContext,
    node_uuid: String,
) -> AncestorPathResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return guarded_ancestor_path_failure(err),
    };
    let node_uuid = match parse_guarded_node_id(node_uuid.as_str()) {
        Ok(value) => value,
        Err(err) => return guarded_ancestor_path_failure(err),
    };

    match with_guarded_tree_service(|service| service.get_ancestor_path(&caller, node_uuid)) {
        Ok(segments) => AncestorPathResponse {
            ok: true,
            error_code: None,
            message: format!("Resolved {} ancestor segment(s).", segments.len()),
            segments: segments
                .into_iter()
                .map(|(node_uuid, display_name)| PathSegment {
                    node_uuid: node_uuid.to_string(),
                    display_name,
                })
                .collect(),
        },
        Err(err) => guarded_ancestor_path_failure(err),
    }
}

/// Returns atom-ref locations through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn workspace_list_atom_refs_for_atom(
    caller: FfiCallerContext,
    atom_uuid: String,
) -> AtomRefLocationsResponse {
    workspace_list_atom_refs_for_atom_impl(caller, atom_uuid)
}

pub(super) fn workspace_list_atom_refs_for_atom_impl(
    caller: FfiCallerContext,
    atom_uuid: String,
) -> AtomRefLocationsResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return atom_ref_locations_failure(err),
    };
    let atom_uuid = match parse_guarded_atom_id(atom_uuid.as_str()) {
        Ok(value) => value,
        Err(err) => return atom_ref_locations_failure(err),
    };

    match with_guarded_tree_service(|service| service.list_atom_refs_for_atom(&caller, atom_uuid)) {
        Ok(locations) => AtomRefLocationsResponse {
            ok: true,
            error_code: None,
            message: format!("Resolved {} atom ref location(s).", locations.len()),
            locations: locations
                .into_iter()
                .map(|location| FfiAtomRefLocation {
                    node_uuid: location.node_uuid.to_string(),
                    workspace_id: location.workspace_id.to_string(),
                    path: location.path,
                    display_name: location.display_name,
                })
                .collect(),
        },
        Err(err) => atom_ref_locations_failure(err),
    }
}

pub(super) fn workspace_failure_from_guarded(error: GuardedFfiError) -> WorkspaceActionResponse {
    WorkspaceActionResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
    }
}

pub(super) fn workspace_reassign_failure(
    error: GuardedServiceError,
    workspace_id: Uuid,
    new_node_uuid: Uuid,
) -> WorkspaceActionResponse {
    let mapped = match error {
        GuardedServiceError::Tree(TreeServiceError::NodeNotFound(node_id))
            if node_id == workspace_id =>
        {
            GuardedFfiError::WorkspaceNotFound(workspace_id.to_string())
        }
        GuardedServiceError::Tree(TreeServiceError::NodeNotFound(node_id))
            if node_id == new_node_uuid =>
        {
            GuardedFfiError::InvalidNodeId(node_id.to_string())
        }
        GuardedServiceError::Tree(TreeServiceError::NodeMustBeFolder(node_id)) => {
            GuardedFfiError::InvalidNodeId(node_id.to_string())
        }
        GuardedServiceError::Tree(TreeServiceError::DesignatedFolderWrongWorkspace {
            workspace_id,
            node_uuid,
        }) => GuardedFfiError::TargetFolderNotInWorkspace(format!(
            "target folder {node_uuid} does not belong to workspace {workspace_id}"
        )),
        GuardedServiceError::Tree(TreeServiceError::Repo(TreeRepoError::InvalidData(message)))
            if message.contains("designated role") =>
        {
            GuardedFfiError::DesignatedRoleNotFound(message)
        }
        other => map_guarded_service_error(other),
    };
    workspace_failure_from_guarded(mapped)
}

fn guarded_workspace_exists(workspace_id: Uuid) -> Result<bool, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    let workspace_meta =
        SqliteWorkspaceMetaRepository::try_new(&conn).map_err(map_guarded_tree_repo_error)?;
    workspace_meta
        .workspace_exists(workspace_id)
        .map_err(map_guarded_tree_repo_error)
}

fn parse_folder_delete_mode(raw: &str) -> Result<FolderDeleteMode, WorkspaceFfiError> {
    match raw.trim() {
        "dissolve" => Ok(FolderDeleteMode::Dissolve),
        "delete_all" => Ok(FolderDeleteMode::DeleteAll),
        other => Err(WorkspaceFfiError::InvalidDeleteMode(other.to_string())),
    }
}

fn parse_workspace_node_id(raw: &str) -> Result<Uuid, WorkspaceFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| WorkspaceFfiError::InvalidNodeId(raw.to_string()))
}

fn parse_workspace_atom_id(raw: &str) -> Result<AtomId, WorkspaceFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| WorkspaceFfiError::InvalidAtomId(raw.to_string()))
}

fn workspace_node_kind_label(kind: WorkspaceNodeKind) -> &'static str {
    match kind {
        WorkspaceNodeKind::Workspace => "workspace",
        WorkspaceNodeKind::Folder => "folder",
        WorkspaceNodeKind::AtomRef => "atom_ref",
    }
}

fn to_workspace_node_item(node: WorkspaceNode) -> WorkspaceNodeItem {
    WorkspaceNodeItem {
        node_id: node.node_uuid.to_string(),
        kind: workspace_node_kind_label(node.kind).to_string(),
        parent_node_id: node.parent_uuid.map(|value| value.to_string()),
        atom_id: node.atom_uuid.map(|value| value.to_string()),
        display_name: node.display_name,
        sort_order: node.sort_order,
    }
}

pub(super) fn workspace_failure(error: WorkspaceFfiError) -> WorkspaceActionResponse {
    WorkspaceActionResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
    }
}

pub(super) fn workspace_node_failure(error: WorkspaceFfiError) -> WorkspaceNodeResponse {
    WorkspaceNodeResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        node: None,
    }
}

pub(super) fn workspace_list_failure(error: WorkspaceFfiError) -> WorkspaceListChildrenResponse {
    WorkspaceListChildrenResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        items: Vec::new(),
    }
}

pub(super) fn workspace_ancestor_path_failure(
    error: WorkspaceFfiError,
) -> WorkspaceAncestorPathResponse {
    WorkspaceAncestorPathResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        path: Vec::new(),
    }
}

pub(super) fn map_workspace_db_error(err: lazynote_core::db::DbError) -> WorkspaceFfiError {
    if is_db_busy(&err) {
        WorkspaceFfiError::DbBusy(err.to_string())
    } else {
        WorkspaceFfiError::DbError(err.to_string())
    }
}

pub(super) fn map_tree_repo_error(err: TreeRepoError) -> WorkspaceFfiError {
    match err {
        TreeRepoError::Db(db_err) => map_workspace_db_error(db_err),
        TreeRepoError::NodeNotFound(node_id) => {
            WorkspaceFfiError::NodeNotFound(node_id.to_string())
        }
        TreeRepoError::NodeNotFolder(node_id) => {
            WorkspaceFfiError::NodeNotFolder(node_id.to_string())
        }
        TreeRepoError::UninitializedConnection {
            expected_version,
            actual_version,
        } => WorkspaceFfiError::DbError(format!(
            "repository requires schema {expected_version}, got {actual_version}"
        )),
        TreeRepoError::MissingRequiredTable(table) => {
            WorkspaceFfiError::DbError(format!("missing required table `{table}`"))
        }
        TreeRepoError::MissingRequiredColumn { table, column } => WorkspaceFfiError::DbError(
            format!("missing required column `{column}` in table `{table}`"),
        ),
        TreeRepoError::InvalidData(details) => WorkspaceFfiError::Internal(details),
        TreeRepoError::CannotMoveToRoot(node_id) => {
            WorkspaceFfiError::CannotMoveToRoot(node_id.to_string())
        }
    }
}

pub(super) fn map_tree_service_error(err: TreeServiceError) -> WorkspaceFfiError {
    match err {
        TreeServiceError::InvalidDisplayName => {
            WorkspaceFfiError::InvalidDisplayName("display name must not be blank".to_string())
        }
        TreeServiceError::NodeNotFound(node_id) => {
            WorkspaceFfiError::NodeNotFound(node_id.to_string())
        }
        TreeServiceError::ParentNotFound(node_id) => {
            WorkspaceFfiError::ParentNotFound(node_id.to_string())
        }
        TreeServiceError::ParentMustBeFolder(node_id) => {
            WorkspaceFfiError::ParentNotFolder(node_id.to_string())
        }
        TreeServiceError::NodeMustBeFolder(node_id) => {
            WorkspaceFfiError::NodeNotFolder(node_id.to_string())
        }
        TreeServiceError::AtomNotFound(atom_id) => {
            WorkspaceFfiError::AtomNotFound(atom_id.to_string())
        }
        TreeServiceError::CycleDetected {
            node_uuid,
            parent_uuid,
        } => WorkspaceFfiError::CycleDetected(format!("node={node_uuid} parent={parent_uuid}")),
        TreeServiceError::WorkspaceRootProtected(node_uuid) => {
            WorkspaceFfiError::Internal(format!("workspace root is protected: {node_uuid}"))
        }
        TreeServiceError::DesignatedFolderProtected(node_uuid) => WorkspaceFfiError::Internal(
            format!("designated folder must be reassigned before delete: {node_uuid}"),
        ),
        TreeServiceError::CannotMoveWorkspaceRoot(node_uuid) => {
            WorkspaceFfiError::Internal(format!("workspace root cannot be moved: {node_uuid}"))
        }
        TreeServiceError::CannotMoveToRoot(node_uuid) => {
            WorkspaceFfiError::CannotMoveToRoot(node_uuid.to_string())
        }
        TreeServiceError::CrossWorkspaceMoveNotAllowed {
            node_uuid,
            target_parent,
        } => WorkspaceFfiError::Internal(format!(
            "cross-workspace move rejected: node={node_uuid} target={target_parent}"
        )),
        TreeServiceError::DesignatedFolderWrongWorkspace {
            workspace_id,
            node_uuid,
        } => WorkspaceFfiError::Internal(format!(
            "designated folder must stay in workspace: workspace={workspace_id} node={node_uuid}"
        )),
        TreeServiceError::Repo(repo_err) => map_tree_repo_error(repo_err),
    }
}
