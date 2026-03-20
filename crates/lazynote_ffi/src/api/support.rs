use super::*;

pub(super) fn legacy_default_caller() -> FfiCallerContext {
    FfiCallerContext {
        identity: FfiCallerIdentity::App,
        scope_workspace_id: None,
    }
}

pub(super) fn resolve_legacy_workspace_id(
    target_folder: Option<Uuid>,
) -> Result<String, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    match target_folder {
        Some(target_folder) => resolve_legacy_workspace_root_for_node(&conn, target_folder)
            .map(|value| value.to_string()),
        None => {
            let workspace_meta = SqliteWorkspaceMetaRepository::try_new(&conn)
                .map_err(map_guarded_tree_repo_error)?;
            workspace_meta
                .get_default_workspace()
                .map_err(map_guarded_tree_repo_error)?
                .map(|value| value.to_string())
                .ok_or_else(|| GuardedFfiError::WorkspaceNotFound("default".to_string()))
        }
    }
}

fn resolve_legacy_workspace_root_for_node(
    conn: &rusqlite::Connection,
    node_uuid: Uuid,
) -> Result<Uuid, GuardedFfiError> {
    let repo = SqliteTreeRepository::try_new(conn).map_err(map_guarded_tree_repo_error)?;
    let mut cursor = Some(node_uuid);
    while let Some(current) = cursor {
        let node = repo
            .get_node(current, false)
            .map_err(map_guarded_tree_repo_error)?
            .ok_or_else(|| GuardedFfiError::InvalidTargetFolder(current.to_string()))?;
        if node.kind == WorkspaceNodeKind::Workspace {
            return Ok(node.node_uuid);
        }
        cursor = node.parent_uuid;
    }

    Err(GuardedFfiError::InvalidTargetFolder(node_uuid.to_string()))
}

#[allow(clippy::too_many_arguments)]
pub(super) fn legacy_root_scoped_query(
    view_hint: Option<FfiViewHint>,
    time_filter: FfiTimeFilterKind,
    time_start_ms: Option<i64>,
    time_end_ms: Option<i64>,
    time_shape: FfiTimeShapeFilter,
    status_filter: FfiStatusFilterKind,
    tag: Option<String>,
    text_query: Option<String>,
    include_overdue_deadlines: bool,
    sort: FfiSortSpec,
    limit: u32,
    offset: u32,
) -> Result<FfiScopedAtomQuery, GuardedFfiError> {
    Ok(FfiScopedAtomQuery {
        folder_id: resolve_legacy_workspace_id(None)?,
        view_hint,
        time_filter,
        time_start_ms,
        time_end_ms,
        time_shape,
        status_filter,
        task_statuses: None,
        tag,
        text_query,
        include_path: false,
        include_overdue_deadlines,
        sort,
        limit,
        offset,
    })
}

pub(super) fn with_guarded_query_service_using_guard<T>(
    guard: Box<dyn AccessGuard>,
    f: impl FnOnce(
        &GuardedQueryService<'_, SqliteScopedQueryRepository<'_>, SqliteTreeRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    let scoped_repo = SqliteScopedQueryRepository::try_new(&conn).map_err(|err| match err {
        lazynote_core::ScopedQueryError::InvalidQueryDescriptor(message) => {
            GuardedFfiError::InvalidQueryDescriptor(message)
        }
        lazynote_core::ScopedQueryError::Repo(repo_err) => map_guarded_repo_error(repo_err),
    })?;
    let tree_repo = SqliteTreeRepository::try_new(&conn).map_err(map_guarded_tree_repo_error)?;
    let service = GuardedQueryService::new(guard, &scoped_repo, &tree_repo);
    f(&service).map_err(map_guarded_service_error)
}

pub(super) fn with_guarded_creation_service_using_guard<T>(
    guard: Box<dyn AccessGuard>,
    f: impl FnOnce(&GuardedCreationService<'_, '_>) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    let service = CreationService::try_new(&conn)
        .map_err(|err| GuardedFfiError::Internal(format!("creation service init: {err}")))?;
    let guarded = GuardedCreationService::new(guard, &service);
    f(&guarded).map_err(map_guarded_service_error)
}

pub(super) fn with_guarded_atom_service<T>(
    f: impl FnOnce(
        &mut GuardedAtomService<
            '_,
            SqliteNoteRepository<'_>,
            SqliteAtomRepository<'_>,
            SqliteScopedQueryRepository<'_>,
            SqliteWorkspaceMetaRepository<'_>,
            SqliteTreeRepository<'_>,
        >,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let mut note_conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    let shared_conn = open_db(&db_path).map_err(map_guarded_db_error)?;

    let note_repo =
        SqliteNoteRepository::try_new(&mut note_conn).map_err(map_guarded_repo_error)?;
    let mut note_service = NoteService::new(note_repo);

    let atom_repo = SqliteAtomRepository::try_new(&shared_conn).map_err(map_guarded_repo_error)?;
    let scoped_repo =
        SqliteScopedQueryRepository::try_new(&shared_conn).map_err(|err| match err {
            lazynote_core::ScopedQueryError::InvalidQueryDescriptor(message) => {
                GuardedFfiError::InvalidQueryDescriptor(message)
            }
            lazynote_core::ScopedQueryError::Repo(repo_err) => map_guarded_repo_error(repo_err),
        })?;
    let workspace_meta = SqliteWorkspaceMetaRepository::try_new(&shared_conn)
        .map_err(map_guarded_tree_repo_error)?;
    let task_service = TaskService::new(&atom_repo, &scoped_repo, &workspace_meta, &shared_conn);
    let tree_repo =
        SqliteTreeRepository::try_new(&shared_conn).map_err(map_guarded_tree_repo_error)?;

    let mut guarded = GuardedAtomService::new(
        Box::new(NoopGuard),
        &mut note_service,
        &task_service,
        &tree_repo,
    );
    f(&mut guarded).map_err(map_guarded_service_error)
}

pub(super) fn with_guarded_task_service<T>(
    f: impl FnOnce(
        &GuardedTaskService<
            '_,
            SqliteAtomRepository<'_>,
            SqliteScopedQueryRepository<'_>,
            SqliteWorkspaceMetaRepository<'_>,
            SqliteTreeRepository<'_>,
        >,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    let atom_repo = SqliteAtomRepository::try_new(&conn).map_err(map_guarded_repo_error)?;
    let scoped_repo = SqliteScopedQueryRepository::try_new(&conn).map_err(|err| match err {
        lazynote_core::ScopedQueryError::InvalidQueryDescriptor(message) => {
            GuardedFfiError::InvalidQueryDescriptor(message)
        }
        lazynote_core::ScopedQueryError::Repo(repo_err) => map_guarded_repo_error(repo_err),
    })?;
    let workspace_meta =
        SqliteWorkspaceMetaRepository::try_new(&conn).map_err(map_guarded_tree_repo_error)?;
    let task_service = TaskService::new(&atom_repo, &scoped_repo, &workspace_meta, &conn);
    let tree_repo = SqliteTreeRepository::try_new(&conn).map_err(map_guarded_tree_repo_error)?;
    let guarded = GuardedTaskService::new(Box::new(NoopGuard), &task_service, &tree_repo);
    f(&guarded).map_err(map_guarded_service_error)
}

pub(super) fn with_guarded_workspace_service<T>(
    f: impl FnOnce(
        &GuardedWorkspaceService<'_, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    with_guarded_workspace_service_using_guard(Box::new(NoopGuard), f)
}

pub(super) fn with_guarded_workspace_service_using_guard<T>(
    guard: Box<dyn AccessGuard>,
    f: impl FnOnce(
        &GuardedWorkspaceService<'_, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    let workspace_meta =
        SqliteWorkspaceMetaRepository::try_new(&conn).map_err(map_guarded_tree_repo_error)?;
    let guarded = GuardedWorkspaceService::new(guard, &workspace_meta);
    f(&guarded).map_err(map_guarded_service_error)
}

pub(super) fn with_guarded_tree_service<T>(
    f: impl FnOnce(
        &GuardedTreeService<'_, SqliteTreeRepository<'_>, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    with_guarded_tree_service_using_guard(Box::new(NoopGuard), f)
}

pub(super) fn with_guarded_tree_service_using_guard<T>(
    guard: Box<dyn AccessGuard>,
    f: impl FnOnce(
        &GuardedTreeService<'_, SqliteTreeRepository<'_>, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    with_guarded_tree_service_raw_using_guard(guard, f).map_err(map_guarded_service_error)
}

pub(super) fn with_guarded_tree_service_raw_using_guard<T>(
    guard: Box<dyn AccessGuard>,
    f: impl FnOnce(
        &GuardedTreeService<'_, SqliteTreeRepository<'_>, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedServiceError> {
    let db_path = resolve_entry_db_path();
    let conn =
        open_db(&db_path).map_err(|err| GuardedServiceError::Workspace(TreeRepoError::Db(err)))?;
    let repo = SqliteTreeRepository::try_new(&conn).map_err(GuardedServiceError::Workspace)?;
    let workspace_meta =
        SqliteWorkspaceMetaRepository::try_new(&conn).map_err(GuardedServiceError::Workspace)?;
    let service = TreeService::with_workspace_meta(repo, workspace_meta);
    let guarded = GuardedTreeService::new(guard, &service);
    f(&guarded)
}

pub(super) fn resolve_entry_db_path() -> PathBuf {
    if let Ok(raw) = std::env::var("LAZYNOTE_DB_PATH") {
        let trimmed = raw.trim();
        if !trimmed.is_empty() {
            return PathBuf::from(trimmed);
        }
    }

    match ENTRY_DB_PATH_OVERRIDE.lock() {
        Ok(guard) => {
            if let Some(path) = guard.as_ref() {
                return path.clone();
            }
        }
        Err(_) => {
            error!("event=db_path_resolve module=ffi status=error error_code=mutex_poisoned");
        }
    }

    std::env::temp_dir().join(ENTRY_DB_FILE_NAME)
}

pub(super) fn set_configured_entry_db_path(db_path: &str) -> Result<(), String> {
    let trimmed = db_path.trim();
    if trimmed.is_empty() {
        return Err("db_path must not be empty".to_string());
    }

    let path = PathBuf::from(trimmed);
    if !path.is_absolute() {
        return Err("db_path must be an absolute path".to_string());
    }

    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            std::fs::create_dir_all(parent)
                .map_err(|err| format!("failed to create db parent directory: {err}"))?;
        }
    }

    let mut guard = ENTRY_DB_PATH_OVERRIDE
        .lock()
        .map_err(|_| "entry db path lock poisoned".to_string())?;
    *guard = Some(path);
    Ok(())
}

pub(super) fn with_note_service<T>(
    f: impl FnOnce(&mut NoteService<SqliteNoteRepository<'_>>) -> Result<T, NoteServiceError>,
) -> Result<T, NotesFfiError> {
    let db_path = resolve_entry_db_path();
    let mut conn = open_db(&db_path).map_err(map_db_error)?;
    let repo = SqliteNoteRepository::try_new(&mut conn).map_err(map_repo_error)?;
    let mut service = NoteService::new(repo);
    f(&mut service).map_err(map_note_service_error)
}

pub(super) fn with_tree_service<T>(
    f: impl FnOnce(
        &TreeService<SqliteTreeRepository<'_>, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, TreeServiceError>,
) -> Result<T, WorkspaceFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_workspace_db_error)?;
    let repo = SqliteTreeRepository::try_new(&conn).map_err(map_tree_repo_error)?;
    let workspace_meta =
        SqliteWorkspaceMetaRepository::try_new(&conn).map_err(map_tree_repo_error)?;
    let service = TreeService::with_workspace_meta(repo, workspace_meta);
    f(&service).map_err(map_tree_service_error)
}
