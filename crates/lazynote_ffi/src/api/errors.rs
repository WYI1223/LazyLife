use super::*;

#[derive(Debug, Clone, PartialEq, Eq)]
pub(super) enum LogDartEventFfiError {
    InvalidLevel(String),
    InvalidEventName(String),
    InvalidModule(String),
    InvalidMessage(String),
    LoggingNotInitialized,
}

impl LogDartEventFfiError {
    pub(super) fn code(&self) -> &'static str {
        match self {
            Self::InvalidLevel(_) => "invalid_level",
            Self::InvalidEventName(_) => "invalid_event_name",
            Self::InvalidModule(_) => "invalid_module",
            Self::InvalidMessage(_) => "invalid_message",
            Self::LoggingNotInitialized => "logging_not_initialized",
        }
    }

    pub(super) fn message(&self) -> String {
        match self {
            Self::InvalidLevel(value) => {
                format!("invalid level `{value}`; expected trace|debug|info|warn|error")
            }
            Self::InvalidEventName(value) => format!("invalid event_name: {value}"),
            Self::InvalidModule(value) => format!("invalid module: {value}"),
            Self::InvalidMessage(value) => format!("invalid message: {value}"),
            Self::LoggingNotInitialized => {
                "logging is not initialized; call init_logging first".to_string()
            }
        }
    }
}

pub(super) fn map_log_dart_event_error(err: LogDartEventError) -> LogDartEventFfiError {
    match err {
        LogDartEventError::InvalidLevel(value) => LogDartEventFfiError::InvalidLevel(value),
        LogDartEventError::LoggingNotInitialized => LogDartEventFfiError::LoggingNotInitialized,
    }
}

#[derive(Debug)]
pub(super) enum GuardedFfiError {
    InvalidWorkspaceId(String),
    InvalidNodeId(String),
    InvalidAtomId(String),
    AtomNotFound(String),
    InvalidCallerScope(String),
    InvalidTargetFolder(String),
    InvalidQueryDescriptor(String),
    InvalidContentType(String),
    InvalidTag(String),
    InvalidTimeRange(String),
    CrossWorkspaceAccessDenied(String),
    InsufficientCapability(String),
    WorkspaceNotFound(String),
    DesignatedRoleNotFound(String),
    TargetFolderNotInWorkspace(String),
    DbError(String),
    Internal(String),
}

impl GuardedFfiError {
    pub(super) fn code(&self) -> &'static str {
        match self {
            Self::InvalidWorkspaceId(_) => "invalid_workspace_id",
            Self::InvalidNodeId(_) => "invalid_node_id",
            Self::InvalidAtomId(_) => "invalid_atom_id",
            Self::AtomNotFound(_) => "atom_not_found",
            Self::InvalidCallerScope(_) => "invalid_caller_scope",
            Self::InvalidTargetFolder(_) => "invalid_target_folder",
            Self::InvalidQueryDescriptor(_) => "invalid_query_descriptor",
            Self::InvalidContentType(_) => "invalid_content_type",
            Self::InvalidTag(_) => "invalid_tag",
            Self::InvalidTimeRange(_) => "invalid_time_range",
            Self::CrossWorkspaceAccessDenied(_) => "cross_workspace_access_denied",
            Self::InsufficientCapability(_) => "insufficient_capability",
            Self::WorkspaceNotFound(_) => "workspace_not_found",
            Self::DesignatedRoleNotFound(_) => "designated_role_not_found",
            Self::TargetFolderNotInWorkspace(_) => "target_folder_not_in_workspace",
            Self::DbError(_) => "db_error",
            Self::Internal(_) => "internal_error",
        }
    }

    pub(super) fn message(&self) -> String {
        match self {
            Self::InvalidWorkspaceId(value) => format!("invalid workspace id: {value}"),
            Self::InvalidNodeId(value) => format!("invalid node id: {value}"),
            Self::InvalidAtomId(value) => format!("invalid atom id: {value}"),
            Self::AtomNotFound(value) => format!("atom not found: {value}"),
            Self::InvalidCallerScope(value) => format!("invalid caller scope: {value}"),
            Self::InvalidTargetFolder(value) => format!("invalid target folder: {value}"),
            Self::InvalidQueryDescriptor(value) => value.clone(),
            Self::InvalidContentType(value) => format!("invalid content type: {value}"),
            Self::InvalidTag(value) => format!("invalid tag: {value}"),
            Self::InvalidTimeRange(value) => format!("invalid time range: {value}"),
            Self::CrossWorkspaceAccessDenied(value) => value.clone(),
            Self::InsufficientCapability(value) => value.clone(),
            Self::WorkspaceNotFound(value) => format!("workspace not found: {value}"),
            Self::DesignatedRoleNotFound(value) => value.clone(),
            Self::TargetFolderNotInWorkspace(value) => value.clone(),
            Self::DbError(value) => format!("database error: {value}"),
            Self::Internal(value) => value.clone(),
        }
    }
}

#[derive(Debug)]
pub(super) enum NotesFfiError {
    InvalidNoteId(String),
    InvalidTag(String),
    NoteNotFound(String),
    DbBusy(String),
    DbError(String),
    InvalidArgument(String),
    Internal(String),
}

impl NotesFfiError {
    pub(super) fn code(&self) -> &'static str {
        match self {
            Self::InvalidNoteId(_) => "invalid_note_id",
            Self::InvalidTag(_) => "invalid_tag",
            Self::NoteNotFound(_) => "note_not_found",
            Self::DbBusy(_) => "db_busy",
            Self::DbError(_) => "db_error",
            Self::InvalidArgument(_) => "invalid_argument",
            Self::Internal(_) => "internal_error",
        }
    }

    pub(super) fn message(&self) -> String {
        match self {
            Self::InvalidNoteId(value) => format!("invalid note id: {value}"),
            Self::InvalidTag(value) => format!("invalid tag: {value}"),
            Self::NoteNotFound(value) => format!("note not found: {value}"),
            Self::DbBusy(value) => format!("notes database busy: {value}"),
            Self::DbError(value) => format!("notes database error: {value}"),
            Self::InvalidArgument(value) => format!("invalid argument: {value}"),
            Self::Internal(value) => format!("internal error: {value}"),
        }
    }
}

#[derive(Debug)]
#[allow(dead_code)]
pub(super) enum AtomFfiError {
    InvalidAtomId(String),
    AtomNotFound(String),
    InvalidStatus(String),
    InvalidTimeRange(String),
    DbError(String),
    Internal(String),
}

impl AtomFfiError {
    pub(super) fn code(&self) -> &'static str {
        match self {
            Self::InvalidAtomId(_) => "invalid_atom_id",
            Self::AtomNotFound(_) => "atom_not_found",
            Self::InvalidStatus(_) => "invalid_status",
            Self::InvalidTimeRange(_) => "invalid_time_range",
            Self::DbError(_) => "db_error",
            Self::Internal(_) => "internal_error",
        }
    }

    pub(super) fn message(&self) -> String {
        match self {
            Self::InvalidAtomId(v) => format!("invalid atom id: {v}"),
            Self::AtomNotFound(v) => format!("atom not found: {v}"),
            Self::InvalidStatus(v) => format!("invalid status: {v}"),
            Self::InvalidTimeRange(v) => format!("invalid time range: {v}"),
            Self::DbError(v) => format!("database error: {v}"),
            Self::Internal(v) => format!("internal error: {v}"),
        }
    }
}

pub(super) fn map_guarded_to_notes_error(err: GuardedFfiError) -> NotesFfiError {
    match err {
        GuardedFfiError::InvalidAtomId(value) => NotesFfiError::InvalidNoteId(value),
        GuardedFfiError::AtomNotFound(value) => NotesFfiError::NoteNotFound(value),
        GuardedFfiError::DbError(value) => NotesFfiError::DbError(value),
        GuardedFfiError::InvalidTag(value) => NotesFfiError::InvalidTag(value),
        GuardedFfiError::InvalidContentType(value)
        | GuardedFfiError::InvalidWorkspaceId(value)
        | GuardedFfiError::InvalidNodeId(value)
        | GuardedFfiError::InvalidCallerScope(value)
        | GuardedFfiError::InvalidTargetFolder(value)
        | GuardedFfiError::InvalidQueryDescriptor(value)
        | GuardedFfiError::InvalidTimeRange(value)
        | GuardedFfiError::WorkspaceNotFound(value)
        | GuardedFfiError::DesignatedRoleNotFound(value)
        | GuardedFfiError::TargetFolderNotInWorkspace(value)
        | GuardedFfiError::CrossWorkspaceAccessDenied(value)
        | GuardedFfiError::InsufficientCapability(value)
        | GuardedFfiError::Internal(value) => NotesFfiError::Internal(value),
    }
}

pub(super) fn map_guarded_to_atom_error(err: GuardedFfiError) -> AtomFfiError {
    match err {
        GuardedFfiError::InvalidAtomId(value) => AtomFfiError::InvalidAtomId(value),
        GuardedFfiError::AtomNotFound(value) => AtomFfiError::AtomNotFound(value),
        GuardedFfiError::DbError(value) => AtomFfiError::DbError(value),
        GuardedFfiError::InvalidTimeRange(value) => AtomFfiError::InvalidTimeRange(value),
        GuardedFfiError::InvalidContentType(value)
        | GuardedFfiError::InvalidWorkspaceId(value)
        | GuardedFfiError::InvalidNodeId(value)
        | GuardedFfiError::InvalidCallerScope(value)
        | GuardedFfiError::InvalidTargetFolder(value)
        | GuardedFfiError::InvalidQueryDescriptor(value)
        | GuardedFfiError::InvalidTag(value)
        | GuardedFfiError::WorkspaceNotFound(value)
        | GuardedFfiError::DesignatedRoleNotFound(value)
        | GuardedFfiError::TargetFolderNotInWorkspace(value)
        | GuardedFfiError::CrossWorkspaceAccessDenied(value)
        | GuardedFfiError::InsufficientCapability(value)
        | GuardedFfiError::Internal(value) => AtomFfiError::Internal(value),
    }
}

pub(super) fn map_guarded_service_error(err: GuardedServiceError) -> GuardedFfiError {
    match err {
        GuardedServiceError::Access(AccessError::CrossWorkspaceAccessDenied { .. }) => {
            GuardedFfiError::CrossWorkspaceAccessDenied(err.to_string())
        }
        GuardedServiceError::Access(AccessError::InsufficientCapability { .. }) => {
            GuardedFfiError::InsufficientCapability(err.to_string())
        }
        GuardedServiceError::Query(lazynote_core::ScopedQueryError::InvalidQueryDescriptor(
            message,
        )) => GuardedFfiError::InvalidQueryDescriptor(message),
        GuardedServiceError::Query(lazynote_core::ScopedQueryError::Repo(repo_err)) => {
            map_guarded_repo_error(repo_err)
        }
        GuardedServiceError::Creation(CreationServiceError::InvalidContentType(value)) => {
            GuardedFfiError::InvalidContentType(value)
        }
        GuardedServiceError::Creation(CreationServiceError::Repo(
            lazynote_core::RepoError::Validation(
                lazynote_core::AtomValidationError::InvalidEventWindow { start, end },
            ),
        )) => GuardedFfiError::InvalidTimeRange(format!(
            "end_at ({end}) must be >= start_at ({start})"
        )),
        GuardedServiceError::Creation(CreationServiceError::WorkspaceNotFound(workspace_id)) => {
            GuardedFfiError::WorkspaceNotFound(workspace_id.to_string())
        }
        GuardedServiceError::Creation(CreationServiceError::TargetFolderNotInWorkspace {
            workspace_id,
            target_folder,
        }) => GuardedFfiError::TargetFolderNotInWorkspace(format!(
            "target folder {target_folder} does not belong to workspace {workspace_id}"
        )),
        GuardedServiceError::Creation(CreationServiceError::MissingDesignatedFolder {
            workspace_id,
            role,
        }) => GuardedFfiError::DesignatedRoleNotFound(format!(
            "designated folder `{role}` missing for workspace `{workspace_id}`"
        )),
        GuardedServiceError::Creation(CreationServiceError::Repo(repo_err)) => {
            map_guarded_repo_error(repo_err)
        }
        GuardedServiceError::Creation(other) => GuardedFfiError::Internal(other.to_string()),
        GuardedServiceError::Workspace(repo_err) => map_guarded_tree_repo_error(repo_err),
        GuardedServiceError::Tree(service_err) => {
            GuardedFfiError::Internal(service_err.to_string())
        }
        GuardedServiceError::Task(TaskServiceError::AtomNotFound(atom_id)) => {
            GuardedFfiError::AtomNotFound(atom_id.to_string())
        }
        GuardedServiceError::Task(TaskServiceError::Repo(
            lazynote_core::RepoError::Validation(
                lazynote_core::AtomValidationError::InvalidEventWindow { start, end },
            ),
        )) => GuardedFfiError::InvalidTimeRange(format!(
            "end_at ({end}) must be >= start_at ({start})"
        )),
        GuardedServiceError::Task(TaskServiceError::Repo(repo_err)) => {
            map_guarded_repo_error(repo_err)
        }
        GuardedServiceError::Task(TaskServiceError::ScopedQuery(
            lazynote_core::ScopedQueryError::InvalidQueryDescriptor(message),
        )) => GuardedFfiError::InvalidQueryDescriptor(message),
        GuardedServiceError::Task(TaskServiceError::ScopedQuery(
            lazynote_core::ScopedQueryError::Repo(repo_err),
        )) => map_guarded_repo_error(repo_err),
        GuardedServiceError::Task(TaskServiceError::Workspace(repo_err)) => {
            map_guarded_tree_repo_error(repo_err)
        }
        GuardedServiceError::Note(NoteServiceError::InvalidTag(value)) => {
            GuardedFfiError::InvalidTag(value)
        }
        GuardedServiceError::Note(NoteServiceError::NoteNotFound(atom_id)) => {
            GuardedFfiError::AtomNotFound(atom_id.to_string())
        }
        GuardedServiceError::Note(NoteServiceError::Repo(repo_err)) => {
            map_guarded_repo_error(repo_err)
        }
        GuardedServiceError::Note(NoteServiceError::InconsistentState(details)) => {
            GuardedFfiError::Internal(details.to_string())
        }
        GuardedServiceError::Repo(repo_err) => map_guarded_repo_error(repo_err),
    }
}

pub(super) fn map_guarded_repo_error(err: lazynote_core::RepoError) -> GuardedFfiError {
    match err {
        lazynote_core::RepoError::Db(db_err) => GuardedFfiError::DbError(db_err.to_string()),
        lazynote_core::RepoError::NotFound(atom_id) => {
            GuardedFfiError::AtomNotFound(atom_id.to_string())
        }
        other => GuardedFfiError::Internal(other.to_string()),
    }
}

pub(super) fn map_guarded_tree_repo_error(err: TreeRepoError) -> GuardedFfiError {
    match err {
        TreeRepoError::Db(db_err) => GuardedFfiError::DbError(db_err.to_string()),
        TreeRepoError::NodeNotFound(node_id) => GuardedFfiError::InvalidNodeId(node_id.to_string()),
        other => GuardedFfiError::Internal(other.to_string()),
    }
}

pub(super) fn map_guarded_db_error(err: lazynote_core::db::DbError) -> GuardedFfiError {
    GuardedFfiError::DbError(err.to_string())
}

pub(super) fn map_note_service_error(err: NoteServiceError) -> NotesFfiError {
    match err {
        NoteServiceError::InvalidTag(value) => NotesFfiError::InvalidTag(value),
        NoteServiceError::NoteNotFound(atom_id) => NotesFfiError::NoteNotFound(atom_id.to_string()),
        NoteServiceError::Repo(repo_err) => map_repo_error(repo_err),
        NoteServiceError::InconsistentState(details) => {
            NotesFfiError::Internal(details.to_string())
        }
    }
}

pub(super) fn map_repo_error(err: lazynote_core::RepoError) -> NotesFfiError {
    match err {
        lazynote_core::RepoError::NotFound(atom_id) => {
            NotesFfiError::NoteNotFound(atom_id.to_string())
        }
        lazynote_core::RepoError::Validation(validation) => {
            NotesFfiError::InvalidArgument(validation.to_string())
        }
        lazynote_core::RepoError::Db(db_err) => map_db_error(db_err),
        lazynote_core::RepoError::UninitializedConnection {
            expected_version,
            actual_version,
        } => NotesFfiError::DbError(format!(
            "repository requires schema {expected_version}, got {actual_version}"
        )),
        lazynote_core::RepoError::MissingRequiredTable(table) => {
            NotesFfiError::DbError(format!("missing required table `{table}`"))
        }
        lazynote_core::RepoError::MissingRequiredColumn { table, column } => {
            NotesFfiError::DbError(format!(
                "missing required column `{column}` in table `{table}`"
            ))
        }
        lazynote_core::RepoError::InvalidData(details) => NotesFfiError::Internal(details),
    }
}

pub(super) fn map_db_error(err: lazynote_core::db::DbError) -> NotesFfiError {
    if is_db_busy(&err) {
        NotesFfiError::DbBusy(err.to_string())
    } else {
        NotesFfiError::DbError(err.to_string())
    }
}

pub(super) fn is_db_busy(err: &lazynote_core::db::DbError) -> bool {
    matches!(
        err,
        lazynote_core::db::DbError::Sqlite(rusqlite::Error::SqliteFailure(sqlite_err, _))
            if sqlite_err.code == rusqlite::ErrorCode::DatabaseBusy
                || sqlite_err.code == rusqlite::ErrorCode::DatabaseLocked
    )
}
