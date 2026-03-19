//! FFI use-case API for Flutter-facing calls.
//!
//! # Responsibility
//! - Expose stable, use-case-level functions to Dart via FRB.
//! - Keep error semantics simple for early-stage UI integration.
//!
//! # Invariants
//! - Exported functions must not panic across FFI boundary.
//! - Return envelopes keep `ok/error_code/message` semantics stable.
//!
//! # See also
//! - docs/architecture/logging.md

use lazynote_core::db::open_db;
use lazynote_core::{
    core_version as core_version_inner, init_logging as init_logging_inner,
    log_dart_event as log_dart_event_inner, ping as ping_inner, search_all, AccessError,
    AccessGuard, AtomId, CallerContext, CallerIdentity, CreateAtomRequest, CreationService,
    CreationServiceError, FolderDeleteMode, GuardedAtomService, GuardedCreationService,
    GuardedQueryService, GuardedServiceError, GuardedTaskService, GuardedTreeService,
    GuardedWorkspaceService, LogDartEventError, NoopGuard, NoteRecord, NoteService,
    NoteServiceError, ProjectionMode, ScopedAtomQuery, ScopedAtomResult, SearchHit, SearchQuery,
    SectionAtom, SortSpec, SqliteAtomRepository, SqliteNoteRepository, SqliteScopedQueryRepository,
    SqliteTreeRepository, SqliteWorkspaceMetaRepository, StatusFilter, TaskService,
    TaskServiceError, TaskStatus, TimeFilter, TimeShapeFilter, TreeRepoError, TreeRepository,
    TreeService, TreeServiceError, ViewHint, WorkspaceMetaRepository, WorkspaceMetadata,
    WorkspaceNode, WorkspaceNodeKind,
};
use log::error;
use std::path::PathBuf;
use std::sync::Mutex;
use uuid::Uuid;

const ENTRY_DEFAULT_LIMIT: u32 = 10;
const ENTRY_SEARCH_MAX_LIMIT: u32 = 50;
const ENTRY_DB_FILE_NAME: &str = "lazynote_entry.sqlite3";
const LOG_DART_EVENT_MAX_EVENT_NAME_CHARS: usize = 64;
const LOG_DART_EVENT_MAX_MODULE_CHARS: usize = 64;
const LOG_DART_EVENT_MAX_MESSAGE_CHARS: usize = 512;
static ENTRY_DB_PATH_OVERRIDE: Mutex<Option<PathBuf>> = Mutex::new(None);

/// Minimal health-check API for FRB smoke integration.
///
/// # FFI contract
/// - Sync call, non-blocking.
/// - UI-thread safe for current implementation.
/// - Never throws; always returns a UTF-8 string.
#[flutter_rust_bridge::frb(sync)]
pub fn ping() -> String {
    ping_inner().to_owned()
}

/// Expose core crate version through FFI.
///
/// # FFI contract
/// - Sync call, non-blocking.
/// - UI-thread safe for current implementation.
/// - Never throws; always returns a UTF-8 string.
#[flutter_rust_bridge::frb(sync)]
pub fn core_version() -> String {
    core_version_inner().to_owned()
}

/// Initializes Rust core logging once per process.
///
/// Input semantics:
/// - `level`: one of `trace|debug|info|warn|error` (case-insensitive).
/// - `log_dir`: absolute directory path where rolling logs are written.
///
/// # FFI contract
/// - Sync call; may perform small file-system setup work.
/// - Safe to call repeatedly with the same `level + log_dir` (idempotent).
/// - Reconfiguration attempts with different level or directory return error.
/// - Never panics; returns empty string on success and error message on failure.
#[flutter_rust_bridge::frb(sync)]
pub fn init_logging(level: String, log_dir: String) -> String {
    match init_logging_inner(level.as_str(), log_dir.as_str()) {
        Ok(()) => String::new(),
        Err(err) => err,
    }
}

/// Configures a process-local default SQLite path for entry APIs.
///
/// # FFI contract
/// - Sync call, non-blocking.
/// - Safe to call multiple times; latest successful path wins.
/// - Returns empty string on success, error message on validation/IO failure.
#[flutter_rust_bridge::frb(sync)]
pub fn configure_entry_db_path(db_path: String) -> String {
    match set_configured_entry_db_path(db_path.as_str()) {
        Ok(()) => String::new(),
        Err(err) => err,
    }
}

/// Dart-side diagnostics logging response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LogDartEventResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum LogDartEventFfiError {
    InvalidLevel(String),
    InvalidEventName(String),
    InvalidModule(String),
    InvalidMessage(String),
    LoggingNotInitialized,
}

impl LogDartEventFfiError {
    fn code(&self) -> &'static str {
        match self {
            Self::InvalidLevel(_) => "invalid_level",
            Self::InvalidEventName(_) => "invalid_event_name",
            Self::InvalidModule(_) => "invalid_module",
            Self::InvalidMessage(_) => "invalid_message",
            Self::LoggingNotInitialized => "logging_not_initialized",
        }
    }

    fn message(&self) -> String {
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

/// Writes one structured Dart event into the Rust session log stream.
///
/// # FFI contract
/// - Sync call.
/// - additive API; does not change existing FFI signatures.
/// - payload validation is enforced at FFI boundary.
#[flutter_rust_bridge::frb(sync)]
pub fn log_dart_event(
    level: String,
    event_name: String,
    module: String,
    message: String,
) -> LogDartEventResponse {
    log_dart_event_impl(level, event_name, module, message)
}

fn log_dart_event_impl(
    level: String,
    event_name: String,
    module: String,
    message: String,
) -> LogDartEventResponse {
    match try_log_dart_event(level, event_name, module, message) {
        Ok(()) => LogDartEventResponse {
            ok: true,
            error_code: None,
            message: "Dart event logged.".to_string(),
        },
        Err(err) => LogDartEventResponse {
            ok: false,
            error_code: Some(err.code().to_string()),
            message: err.message(),
        },
    }
}

fn try_log_dart_event(
    level: String,
    event_name: String,
    module: String,
    message: String,
) -> Result<(), LogDartEventFfiError> {
    let normalized_level = normalize_log_dart_event_level(level.as_str())?;
    let normalized_event_name = validate_log_dart_event_event_name(event_name.as_str())?;
    let normalized_module = validate_log_dart_event_module(module.as_str())?;
    let normalized_message = validate_log_dart_event_message(message.as_str())?;

    log_dart_event_inner(
        normalized_level.as_str(),
        normalized_event_name.as_str(),
        normalized_module.as_str(),
        normalized_message.as_str(),
    )
    .map_err(map_log_dart_event_error)
}

fn normalize_log_dart_event_level(raw: &str) -> Result<String, LogDartEventFfiError> {
    let normalized = raw.trim().to_ascii_lowercase();
    let accepted = match normalized.as_str() {
        "trace" | "debug" | "info" | "warn" | "error" => normalized,
        "warning" => "warn".to_string(),
        _ => {
            return Err(LogDartEventFfiError::InvalidLevel(raw.to_string()));
        }
    };
    Ok(accepted)
}

fn validate_log_dart_event_event_name(raw: &str) -> Result<String, LogDartEventFfiError> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(LogDartEventFfiError::InvalidEventName(
            "value cannot be blank".to_string(),
        ));
    }
    if trimmed.chars().count() > LOG_DART_EVENT_MAX_EVENT_NAME_CHARS {
        return Err(LogDartEventFfiError::InvalidEventName(format!(
            "value exceeds max {} chars",
            LOG_DART_EVENT_MAX_EVENT_NAME_CHARS
        )));
    }
    Ok(trimmed.to_string())
}

fn validate_log_dart_event_module(raw: &str) -> Result<String, LogDartEventFfiError> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(LogDartEventFfiError::InvalidModule(
            "value cannot be blank".to_string(),
        ));
    }
    if trimmed.chars().count() > LOG_DART_EVENT_MAX_MODULE_CHARS {
        return Err(LogDartEventFfiError::InvalidModule(format!(
            "value exceeds max {} chars",
            LOG_DART_EVENT_MAX_MODULE_CHARS
        )));
    }
    Ok(trimmed.to_string())
}

fn validate_log_dart_event_message(raw: &str) -> Result<String, LogDartEventFfiError> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(LogDartEventFfiError::InvalidMessage(
            "value cannot be blank".to_string(),
        ));
    }
    if trimmed.chars().count() > LOG_DART_EVENT_MAX_MESSAGE_CHARS {
        return Err(LogDartEventFfiError::InvalidMessage(format!(
            "value exceeds max {} chars",
            LOG_DART_EVENT_MAX_MESSAGE_CHARS
        )));
    }
    Ok(trimmed.to_string())
}

fn map_log_dart_event_error(err: LogDartEventError) -> LogDartEventFfiError {
    match err {
        LogDartEventError::InvalidLevel(value) => LogDartEventFfiError::InvalidLevel(value),
        LogDartEventError::LoggingNotInitialized => LogDartEventFfiError::LoggingNotInitialized,
    }
}

/// Search item returned by single-entry search API.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EntrySearchItem {
    /// Stable atom ID in string form.
    pub atom_id: String,
    /// Atom view hint (`note|task|event`).
    pub view_hint: String,
    /// User-facing title derived from content.
    pub title: String,
    /// Short snippet summary for result display.
    pub snippet: String,
}

/// Search response envelope for single-entry search flow.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EntrySearchResponse {
    /// Whether search execution succeeded.
    pub ok: bool,
    /// Optional stable error code for machine branching.
    pub error_code: Option<String>,
    /// Search results (empty when no hits or scaffold mode).
    pub items: Vec<EntrySearchItem>,
    /// Human-readable response message for diagnostics.
    pub message: String,
    /// Effective applied search limit.
    pub applied_limit: u32,
}

/// Generic action response envelope for single-entry command flow.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EntryActionResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Optional created atom ID.
    pub atom_id: Option<String>,
    /// Optional workspace node ID for the created atom_ref (S4).
    pub node_uuid: Option<String>,
    /// Human-readable response message for diagnostics/UI.
    pub message: String,
}

impl EntryActionResponse {
    fn success(message: impl Into<String>, atom_id: String, node_uuid: String) -> Self {
        Self {
            ok: true,
            atom_id: Some(atom_id),
            node_uuid: Some(node_uuid),
            message: message.into(),
        }
    }

    fn failure(message: impl Into<String>) -> Self {
        Self {
            ok: false,
            atom_id: None,
            node_uuid: None,
            message: message.into(),
        }
    }
}

/// Tags list response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TagsListResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
    /// Normalized tags known by storage.
    pub tags: Vec<String>,
}

/// Workspace action response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceActionResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
}

/// Workspace tree node DTO exposed over FFI.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceNodeItem {
    /// Stable workspace node id.
    pub node_id: String,
    /// Node kind label (`folder|atom_ref`).
    pub kind: String,
    /// Parent node id for non-root nodes.
    pub parent_node_id: Option<String>,
    /// Target atom id for atom_ref nodes.
    pub atom_id: Option<String>,
    /// User-facing display name.
    pub display_name: String,
    /// Deterministic sibling order key.
    pub sort_order: i64,
}

/// Workspace single-node response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceNodeResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
    /// Returned node payload on success.
    pub node: Option<WorkspaceNodeItem>,
}

/// Workspace children-list response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceListChildrenResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
    /// Child nodes in deterministic order.
    pub items: Vec<WorkspaceNodeItem>,
}

/// Workspace ancestor path response envelope (PR-RB-10).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceAncestorPathResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
    /// Ancestor folder display_names from root to direct parent.
    /// Empty when atom_ref is at root level or atom has no active ref.
    pub path: Vec<String>,
}

/// Caller identity for guarded FFI exports.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiCallerIdentity {
    /// Flutter app caller.
    App,
}

/// Caller context passed to guarded FFI exports.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FfiCallerContext {
    /// Calling identity.
    pub identity: FfiCallerIdentity,
    /// Optional declared workspace scope in UUID string form.
    pub scope_workspace_id: Option<String>,
}

/// Time-filter kind for guarded queries.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiTimeFilterKind {
    Any,
    Timeless,
    Range,
}

/// Time-shape filter for guarded queries.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiTimeShapeFilter {
    Any,
    BoundedOnly,
}

/// Status-filter kind for guarded queries.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiStatusFilterKind {
    Any,
    ActiveOnly,
    TaskStatuses,
}

/// Sort specification for guarded queries.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiSortSpec {
    UpdatedAtDesc,
    StartAtAsc,
    TitleAsc,
}

/// Projection mode for guarded queries.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiProjectionMode {
    Atom,
    Ref,
}

/// View-hint filter for guarded queries.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiViewHint {
    Note,
    Task,
    Event,
}

/// Task-status enum for guarded create/query helpers.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiTaskStatus {
    Todo,
    InProgress,
    Done,
    Cancelled,
}

/// Query descriptor for guarded subtree reads.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FfiScopedAtomQuery {
    pub folder_id: String,
    pub view_hint: Option<FfiViewHint>,
    pub time_filter: FfiTimeFilterKind,
    pub time_start_ms: Option<i64>,
    pub time_end_ms: Option<i64>,
    pub time_shape: FfiTimeShapeFilter,
    pub status_filter: FfiStatusFilterKind,
    pub task_statuses: Option<Vec<FfiTaskStatus>>,
    pub tag: Option<String>,
    pub text_query: Option<String>,
    pub include_path: bool,
    pub include_overdue_deadlines: bool,
    pub sort: FfiSortSpec,
    pub limit: u32,
    pub offset: u32,
}

/// Canonical creation request for guarded exports.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FfiCreateAtomRequest {
    pub workspace_id: String,
    pub content: String,
    pub content_type: String,
    pub task_status: Option<FfiTaskStatus>,
    pub start_at: Option<i64>,
    pub end_at: Option<i64>,
    pub tags: Option<Vec<String>>,
    pub target_folder: Option<String>,
    pub display_name: Option<String>,
}

/// One guarded-query result row.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScopedAtomItem {
    pub uuid: String,
    pub view_hint: String,
    pub title: String,
    pub content_type: String,
    pub content: String,
    pub preview_text: Option<String>,
    pub preview_image: Option<String>,
    pub tags: Vec<String>,
    pub task_status: Option<String>,
    pub start_at: Option<i64>,
    pub end_at: Option<i64>,
    pub is_deleted: bool,
    pub updated_at: i64,
    pub representative_node_uuid: String,
    pub path: Option<String>,
}

/// Guarded-query response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScopedQueryResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub items: Vec<ScopedAtomItem>,
}

/// Guarded atom-create response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomCreateResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub atom_uuid: Option<String>,
    pub node_uuid: Option<String>,
}

/// Workspace metadata DTO for guarded exports.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceInfo {
    pub workspace_id: String,
    pub name: String,
    pub is_default: bool,
}

/// Workspace-list response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceListResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub workspaces: Vec<WorkspaceInfo>,
}

/// Single-workspace response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorkspaceInfoResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub workspace: Option<WorkspaceInfo>,
}

/// Designated-folder resolution response.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DesignatedFolderResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub node_uuid: Option<String>,
}

/// One ancestor-path segment.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PathSegment {
    pub node_uuid: String,
    pub display_name: String,
}

/// Node-based ancestor-path response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AncestorPathResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub segments: Vec<PathSegment>,
}

/// One atom-ref location DTO.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FfiAtomRefLocation {
    pub node_uuid: String,
    pub workspace_id: String,
    pub path: String,
    pub display_name: String,
}

/// Atom-ref locations response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomRefLocationsResponse {
    pub ok: bool,
    pub error_code: Option<String>,
    pub message: String,
    pub locations: Vec<FfiAtomRefLocation>,
}

#[derive(Debug)]
enum GuardedFfiError {
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
    fn code(&self) -> &'static str {
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

    fn message(&self) -> String {
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
enum WorkspaceFfiError {
    InvalidNodeId(String),
    InvalidParentNodeId(String),
    InvalidAtomId(String),
    InvalidDisplayName(String),
    InvalidDeleteMode(String),
    NodeNotFound(String),
    ParentNotFound(String),
    NodeNotFolder(String),
    ParentNotFolder(String),
    AtomNotFound(String),
    CycleDetected(String),
    CannotMoveToRoot(String),
    DbBusy(String),
    DbError(String),
    Internal(String),
}

impl WorkspaceFfiError {
    fn code(&self) -> &'static str {
        match self {
            Self::InvalidNodeId(_) => "invalid_node_id",
            Self::InvalidParentNodeId(_) => "invalid_parent_node_id",
            Self::InvalidAtomId(_) => "invalid_atom_id",
            Self::InvalidDisplayName(_) => "invalid_display_name",
            Self::InvalidDeleteMode(_) => "invalid_delete_mode",
            Self::NodeNotFound(_) => "node_not_found",
            Self::ParentNotFound(_) => "parent_not_found",
            Self::NodeNotFolder(_) => "node_not_folder",
            Self::ParentNotFolder(_) => "parent_not_folder",
            Self::AtomNotFound(_) => "atom_not_found",
            Self::CycleDetected(_) => "cycle_detected",
            Self::CannotMoveToRoot(_) => "cannot_move_to_root",
            Self::DbBusy(_) => "db_busy",
            Self::DbError(_) => "db_error",
            Self::Internal(_) => "internal_error",
        }
    }

    fn message(&self) -> String {
        match self {
            Self::InvalidNodeId(value) => format!("invalid node id: {value}"),
            Self::InvalidParentNodeId(value) => format!("invalid parent node id: {value}"),
            Self::InvalidAtomId(value) => format!("invalid atom id: {value}"),
            Self::InvalidDisplayName(value) => format!("invalid display name: {value}"),
            Self::InvalidDeleteMode(value) => {
                format!("invalid delete mode: {value}, expected dissolve|delete_all")
            }
            Self::NodeNotFound(value) => format!("workspace node not found: {value}"),
            Self::ParentNotFound(value) => format!("workspace parent not found: {value}"),
            Self::NodeNotFolder(value) => format!("workspace node is not a folder: {value}"),
            Self::ParentNotFolder(value) => format!("workspace parent is not a folder: {value}"),
            Self::AtomNotFound(value) => format!("workspace atom not found: {value}"),
            Self::CycleDetected(value) => format!("workspace cycle detected: {value}"),
            Self::CannotMoveToRoot(value) => {
                format!("workspace node cannot move to root level: {value}")
            }
            Self::DbBusy(value) => format!("workspace database busy: {value}"),
            Self::DbError(value) => format!("workspace database error: {value}"),
            Self::Internal(value) => format!("workspace internal error: {value}"),
        }
    }
}

#[derive(Debug)]
enum NotesFfiError {
    InvalidNoteId(String),
    InvalidTag(String),
    NoteNotFound(String),
    DbBusy(String),
    DbError(String),
    InvalidArgument(String),
    Internal(String),
}

impl NotesFfiError {
    fn code(&self) -> &'static str {
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

    fn message(&self) -> String {
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

/// Searches single-entry text using entry-level defaults.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Never panics.
/// - Returns deterministic envelope with applied limit.
/// - `kind`: optional `all|note|task|event` (case-insensitive).
/// - Returns `invalid_kind` when `kind` is outside allowed values.
#[flutter_rust_bridge::frb]
pub async fn entry_search(
    text: String,
    kind: Option<String>,
    limit: Option<u32>,
) -> EntrySearchResponse {
    entry_search_impl(text, kind, limit)
}

fn entry_search_impl(
    text: String,
    kind: Option<String>,
    limit: Option<u32>,
) -> EntrySearchResponse {
    let normalized_limit = normalize_entry_limit(limit);
    let query_text = text.trim().to_string();
    let parsed_kind = match parse_entry_search_kind(kind) {
        Ok(parsed) => parsed,
        Err(err) => {
            return EntrySearchResponse {
                ok: false,
                error_code: Some("invalid_kind".to_string()),
                items: Vec::new(),
                message: err,
                applied_limit: normalized_limit,
            };
        }
    };
    // Keep the legacy FTS bridge during PR-0411 expand stage so ranking/snippet
    // semantics stay stable until PR-0413 removes this wrapper surface.
    legacy_entry_search_via_fts(query_text, parsed_kind, normalized_limit)
}

fn parse_entry_search_kind(raw: Option<String>) -> Result<Option<ViewHint>, String> {
    let Some(value) = raw else {
        return Ok(None);
    };
    let normalized = value.trim().to_ascii_lowercase();
    if normalized.is_empty() {
        return Err("invalid kind: blank value is not allowed".to_string());
    }
    if normalized == "all" {
        return Ok(None);
    }
    match normalized.as_str() {
        "note" => Ok(Some(ViewHint::Note)),
        "task" => Ok(Some(ViewHint::Task)),
        "event" => Ok(Some(ViewHint::Event)),
        _ => Err(format!(
            "invalid kind `{value}`; expected one of all|note|task|event"
        )),
    }
}

/// Creates a note from single-entry command flow.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Never panics.
/// - Returns operation result and created atom ID on success.
#[flutter_rust_bridge::frb]
pub async fn entry_create_note(content: String) -> EntryActionResponse {
    entry_create_note_impl(content)
}

fn entry_create_note_impl(content: String) -> EntryActionResponse {
    let workspace_id = match resolve_legacy_workspace_id(None) {
        Ok(value) => value,
        Err(err) => {
            return EntryActionResponse::failure(format!(
                "entry_create_note failed: {}",
                err.message()
            ))
        }
    };
    let response = atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content: content.trim().to_string(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: None,
            display_name: None,
        },
    );
    if response.ok {
        EntryActionResponse::success(
            "Note created.",
            response.atom_uuid.expect("atom uuid"),
            response.node_uuid.expect("node uuid"),
        )
    } else {
        EntryActionResponse::failure(format!("entry_create_note failed: {}", response.message))
    }
}

/// Creates a task from single-entry command flow.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Never panics.
/// - Returns operation result and created atom ID on success.
#[flutter_rust_bridge::frb]
pub async fn entry_create_task(content: String) -> EntryActionResponse {
    entry_create_task_impl(content)
}

fn entry_create_task_impl(content: String) -> EntryActionResponse {
    let workspace_id = match resolve_legacy_workspace_id(None) {
        Ok(value) => value,
        Err(err) => {
            return EntryActionResponse::failure(format!(
                "entry_create_task failed: {}",
                err.message()
            ))
        }
    };
    let response = atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content: content.trim().to_string(),
            content_type: "markdown".to_string(),
            task_status: Some(FfiTaskStatus::Todo),
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: None,
            display_name: None,
        },
    );
    if response.ok {
        EntryActionResponse::success(
            "Task created.",
            response.atom_uuid.expect("atom uuid"),
            response.node_uuid.expect("node uuid"),
        )
    } else {
        EntryActionResponse::failure(format!("entry_create_task failed: {}", response.message))
    }
}

/// Schedules an event from single-entry command flow.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Accepts point (`end_epoch_ms=None`) and range (`Some(end)`) shapes.
/// - Never panics.
/// - Returns operation result and created atom ID on success.
#[flutter_rust_bridge::frb]
pub async fn entry_schedule(
    title: String,
    start_epoch_ms: i64,
    end_epoch_ms: Option<i64>,
) -> EntryActionResponse {
    entry_schedule_impl(title, start_epoch_ms, end_epoch_ms)
}

fn entry_schedule_impl(
    title: String,
    start_epoch_ms: i64,
    end_epoch_ms: Option<i64>,
) -> EntryActionResponse {
    let workspace_id = match resolve_legacy_workspace_id(None) {
        Ok(value) => value,
        Err(err) => {
            return EntryActionResponse::failure(format!(
                "entry_schedule failed: {}",
                err.message()
            ))
        }
    };
    let response = atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content: title.trim().to_string(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: Some(start_epoch_ms),
            end_at: end_epoch_ms,
            tags: None,
            target_folder: None,
            display_name: None,
        },
    );
    if response.ok {
        EntryActionResponse::success(
            "Event scheduled.",
            response.atom_uuid.expect("atom uuid"),
            response.node_uuid.expect("node uuid"),
        )
    } else {
        EntryActionResponse::failure(format!("entry_schedule failed: {}", response.message))
    }
}

/// Creates one note from markdown content.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Applies markdown preview hooks (`preview_text`, `preview_image`).
/// - Returns typed envelope with stable error codes.
#[flutter_rust_bridge::frb]
pub async fn note_create(content: String, parent_node_id: Option<String>) -> AtomItemResponse {
    note_create_impl(content, parent_node_id)
}

fn note_create_impl(content: String, parent_node_id: Option<String>) -> AtomItemResponse {
    let parsed_parent = match parse_optional_parent_node_id(parent_node_id) {
        Ok(value) => value,
        Err(err) => {
            return AtomItemResponse {
                ok: false,
                error_code: Some(err.code().to_string()),
                message: err.message().to_string(),
                item: None,
                node_uuid: None,
            };
        }
    };
    let workspace_id = match resolve_legacy_workspace_id(parsed_parent) {
        Ok(value) => value,
        Err(err) => {
            return AtomItemResponse {
                ok: false,
                error_code: Some("creation_failed".to_string()),
                message: format!("note_create failed: {}", err.message()),
                item: None,
                node_uuid: None,
            };
        }
    };
    let response = atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content,
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: parsed_parent.map(|value| value.to_string()),
            display_name: None,
        },
    );
    if response.ok {
        let atom_id = response.atom_uuid.expect("atom uuid");
        let loaded = note_get_impl(atom_id);
        AtomItemResponse {
            ok: loaded.ok,
            error_code: loaded.error_code,
            message: if loaded.ok {
                "Note created.".to_string()
            } else {
                loaded.message
            },
            item: loaded.item,
            node_uuid: response.node_uuid,
        }
    } else {
        AtomItemResponse {
            ok: false,
            error_code: Some("creation_failed".to_string()),
            message: format!("note_create failed: {}", response.message),
            item: None,
            node_uuid: None,
        }
    }
}

/// Fully replaces note content by stable id.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `content` is treated as full markdown source replacement.
/// - Returns typed envelope with stable error codes.
#[flutter_rust_bridge::frb]
pub async fn note_update(atom_id: String, content: String) -> AtomItemResponse {
    note_update_impl(atom_id, content)
}

fn note_update_impl(atom_id: String, content: String) -> AtomItemResponse {
    let parsed_id = match parse_note_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return note_failure(err),
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|service| service.update_content(&caller, parsed_id, content)) {
        Ok(note) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Note updated.".to_string(),
            item: Some(to_atom_list_item_from_note(note)),
            node_uuid: None,
        },
        Err(err) => note_failure(map_guarded_to_notes_error(err)),
    }
}

/// Gets one note by stable id.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Returns typed envelope with stable error codes.
#[flutter_rust_bridge::frb]
pub async fn note_get(atom_id: String) -> AtomItemResponse {
    note_get_impl(atom_id)
}

fn note_get_impl(atom_id: String) -> AtomItemResponse {
    let parsed_id = match parse_note_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return note_failure(err),
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|service| {
        service
            .get_note(&caller, parsed_id)?
            .ok_or(GuardedServiceError::Note(NoteServiceError::NoteNotFound(
                parsed_id,
            )))
    }) {
        Ok(note) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Note loaded.".to_string(),
            item: Some(to_atom_list_item_from_note(note)),
            node_uuid: None,
        },
        Err(err) => note_failure(map_guarded_to_notes_error(err)),
    }
}

/// Lists notes with optional single-tag filter and pagination.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Returns only `ViewHint::Note` rows.
/// - Limit normalization: default 10, max 50.
#[flutter_rust_bridge::frb]
pub async fn notes_list(
    tag: Option<String>,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    notes_list_impl(tag, limit, offset)
}

fn notes_list_impl(
    tag: Option<String>,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let resolved_offset = offset.unwrap_or(0);
    let applied_limit = lazynote_core::normalize_note_limit(limit);
    let normalized_tag = match tag {
        Some(value) => {
            let trimmed = value.trim();
            if trimmed.is_empty() {
                return AtomListResponse {
                    ok: false,
                    error_code: Some("invalid_tag".to_string()),
                    message: format!("invalid tag: {value}"),
                    items: Vec::new(),
                    applied_limit,
                };
            }
            Some(trimmed.to_ascii_lowercase())
        }
        None => None,
    };
    let descriptor = match legacy_root_scoped_query(
        Some(FfiViewHint::Note),
        FfiTimeFilterKind::Any,
        None,
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::Any,
        normalized_tag,
        None,
        false,
        FfiSortSpec::UpdatedAtDesc,
        applied_limit,
        resolved_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), applied_limit),
    };

    atom_list_from_scoped_query(
        query_atoms_impl(legacy_default_caller(), descriptor, FfiProjectionMode::Atom),
        applied_limit,
        "note(s)",
    )
}

/// Atomically replaces full tag set for one note.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `tags` is treated as complete replacement, not incremental patch.
/// - Returns typed envelope with stable error codes.
#[flutter_rust_bridge::frb]
pub async fn note_set_tags(atom_id: String, tags: Vec<String>) -> AtomItemResponse {
    note_set_tags_impl(atom_id, tags)
}

fn note_set_tags_impl(atom_id: String, tags: Vec<String>) -> AtomItemResponse {
    let parsed_id = match parse_note_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return note_failure(err),
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|service| service.set_tags(&caller, parsed_id, tags)) {
        Ok(note) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Note tags replaced.".to_string(),
            item: Some(to_atom_list_item_from_note(note)),
            node_uuid: None,
        },
        Err(err) => note_failure(map_guarded_to_notes_error(err)),
    }
}

/// Lists normalized tags known by storage.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Returns typed envelope with stable error codes.
#[flutter_rust_bridge::frb]
pub async fn tags_list() -> TagsListResponse {
    tags_list_impl()
}

fn tags_list_impl() -> TagsListResponse {
    match with_note_service(|service| service.list_tags().map_err(NoteServiceError::from)) {
        Ok(tags) => TagsListResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} tag(s).", tags.len()),
            tags,
        },
        Err(err) => TagsListResponse {
            ok: false,
            error_code: Some(err.code().to_string()),
            message: err.message(),
            tags: Vec::new(),
        },
    }
}

/// Lists workspace child nodes under optional parent.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `parent_node_id` is optional UUID string; `None` lists root-level nodes.
#[flutter_rust_bridge::frb]
pub async fn workspace_list_children(
    parent_node_id: Option<String>,
) -> WorkspaceListChildrenResponse {
    workspace_list_children_impl(parent_node_id)
}

fn workspace_list_children_impl(parent_node_id: Option<String>) -> WorkspaceListChildrenResponse {
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
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `parent_node_id` is optional UUID string; `None` creates a folder under the default workspace root.
#[flutter_rust_bridge::frb]
pub async fn workspace_create_folder(
    parent_node_id: Option<String>,
    name: String,
) -> WorkspaceNodeResponse {
    workspace_create_folder_impl(parent_node_id, name)
}

fn workspace_create_folder_impl(
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
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `atom_id` must be UUID string of an active atom (any type).
#[flutter_rust_bridge::frb]
pub async fn workspace_create_atom_ref(
    parent_node_id: Option<String>,
    atom_id: String,
    display_name: Option<String>,
) -> WorkspaceNodeResponse {
    workspace_create_atom_ref_impl(parent_node_id, atom_id, display_name)
}

fn workspace_create_atom_ref_impl(
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
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `node_id` must be UUID string.
#[flutter_rust_bridge::frb]
pub async fn workspace_rename_node(node_id: String, new_name: String) -> WorkspaceActionResponse {
    workspace_rename_node_impl(node_id, new_name)
}

fn workspace_rename_node_impl(node_id: String, new_name: String) -> WorkspaceActionResponse {
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
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `new_parent_id = None` is rejected because root level is reserved for workspace roots.
#[flutter_rust_bridge::frb]
pub async fn workspace_move_node(
    node_id: String,
    new_parent_id: Option<String>,
    target_order: Option<i64>,
) -> WorkspaceActionResponse {
    workspace_move_node_impl(node_id, new_parent_id, target_order)
}

fn workspace_move_node_impl(
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
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `node_id` must be UUID string of a folder node.
/// - `mode` must be one of `dissolve` or `delete_all`.
#[flutter_rust_bridge::frb]
pub async fn workspace_delete_folder(node_id: String, mode: String) -> WorkspaceActionResponse {
    workspace_delete_folder_impl(node_id, mode)
}

fn workspace_delete_folder_impl(node_id: String, mode: String) -> WorkspaceActionResponse {
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
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - `atom_id` must be UUID string of an atom.
/// - Returns ordered `path` from root to direct parent folder.
/// - Root-level `atom_ref` or nonexistent atom returns empty `path`.
#[flutter_rust_bridge::frb]
pub async fn workspace_ancestor_path(atom_id: String) -> WorkspaceAncestorPathResponse {
    workspace_ancestor_path_impl(atom_id)
}

fn workspace_ancestor_path_impl(atom_id: String) -> WorkspaceAncestorPathResponse {
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

/// Queries workspace-scoped atoms through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn query_atoms(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse {
    query_atoms_impl(caller, descriptor, projection)
}

fn query_atoms_impl(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse {
    query_atoms_impl_with_noop_guard(caller, descriptor, projection)
}

fn query_atoms_impl_with_noop_guard(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
) -> ScopedQueryResponse {
    query_atoms_impl_inner(caller, descriptor, projection, Box::new(NoopGuard))
}

fn query_atoms_impl_inner(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
    guard: Box<dyn AccessGuard>,
) -> ScopedQueryResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return scoped_query_failure(err),
    };
    let query = match build_scoped_query(descriptor) {
        Ok(value) => value,
        Err(err) => return scoped_query_failure(err),
    };
    let projection = map_projection_mode(projection);

    match with_guarded_query_service_using_guard(guard, |service| {
        service.query_atoms(&caller, query, projection)
    }) {
        Ok(items) => ScopedQueryResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} scoped atom(s).", items.len()),
            items: items.into_iter().map(to_scoped_atom_item).collect(),
        },
        Err(err) => scoped_query_failure(err),
    }
}

#[cfg(test)]
fn query_atoms_impl_with_guard(
    caller: FfiCallerContext,
    descriptor: FfiScopedAtomQuery,
    projection: FfiProjectionMode,
    guard: Box<dyn AccessGuard>,
) -> ScopedQueryResponse {
    query_atoms_impl_inner(caller, descriptor, projection, guard)
}

/// Creates one atom through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn atom_create(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
) -> AtomCreateResponse {
    atom_create_impl(caller, request)
}

fn atom_create_impl(caller: FfiCallerContext, request: FfiCreateAtomRequest) -> AtomCreateResponse {
    atom_create_impl_with_noop_guard(caller, request)
}

fn atom_create_impl_with_noop_guard(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
) -> AtomCreateResponse {
    atom_create_impl_inner(caller, request, Box::new(NoopGuard))
}

fn atom_create_impl_inner(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
    guard: Box<dyn AccessGuard>,
) -> AtomCreateResponse {
    let caller = match parse_ffi_caller(caller) {
        Ok(value) => value,
        Err(err) => return atom_create_failure(err),
    };
    let request = match build_create_atom_request(request) {
        Ok(value) => value,
        Err(err) => return atom_create_failure(err),
    };

    match with_guarded_creation_service_using_guard(guard, |service| {
        service.create_atom(&caller, &request)
    }) {
        Ok(result) => AtomCreateResponse {
            ok: true,
            error_code: None,
            message: "Atom created.".to_string(),
            atom_uuid: Some(result.atom.uuid.to_string()),
            node_uuid: Some(result.node.node_uuid.to_string()),
        },
        Err(err) => atom_create_failure(err),
    }
}

#[cfg(test)]
fn atom_create_impl_with_guard(
    caller: FfiCallerContext,
    request: FfiCreateAtomRequest,
    guard: Box<dyn AccessGuard>,
) -> AtomCreateResponse {
    atom_create_impl_inner(caller, request, guard)
}

/// Lists workspaces through the guarded FFI surface.
#[flutter_rust_bridge::frb]
pub async fn workspace_list(caller: FfiCallerContext) -> WorkspaceListResponse {
    workspace_list_impl(caller)
}

fn workspace_list_impl(caller: FfiCallerContext) -> WorkspaceListResponse {
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
fn workspace_list_impl_with_guard(
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

fn workspace_get_default_impl(caller: FfiCallerContext) -> WorkspaceInfoResponse {
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

fn workspace_resolve_designated_impl(
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

fn workspace_reassign_designated_impl(
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

fn workspace_get_ancestor_path_impl(
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

fn workspace_list_atom_refs_for_atom_impl(
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

fn parse_ffi_caller(caller: FfiCallerContext) -> Result<CallerContext, GuardedFfiError> {
    let identity = match caller.identity {
        FfiCallerIdentity::App => CallerIdentity::App,
    };
    let scope_workspace_id = match caller.scope_workspace_id {
        Some(value) => Some(
            parse_guarded_workspace_id(value.as_str())
                .map_err(|_| GuardedFfiError::InvalidCallerScope(value.to_string()))?,
        ),
        None => None,
    };
    Ok(CallerContext {
        identity,
        scope_workspace_id,
    })
}

fn parse_guarded_workspace_id(raw: &str) -> Result<Uuid, GuardedFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| GuardedFfiError::InvalidWorkspaceId(raw.to_string()))
}

fn parse_guarded_node_id(raw: &str) -> Result<Uuid, GuardedFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| GuardedFfiError::InvalidNodeId(raw.to_string()))
}

fn parse_guarded_atom_id(raw: &str) -> Result<Uuid, GuardedFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| GuardedFfiError::InvalidAtomId(raw.to_string()))
}

fn parse_guarded_optional_node_id(raw: Option<String>) -> Result<Option<Uuid>, GuardedFfiError> {
    match raw {
        Some(value) => parse_guarded_node_id(value.as_str()).map(Some),
        None => Ok(None),
    }
}

fn map_view_hint_filter(value: Option<FfiViewHint>) -> Option<ViewHint> {
    value.map(|hint| match hint {
        FfiViewHint::Note => ViewHint::Note,
        FfiViewHint::Task => ViewHint::Task,
        FfiViewHint::Event => ViewHint::Event,
    })
}

fn map_task_status(value: FfiTaskStatus) -> TaskStatus {
    match value {
        FfiTaskStatus::Todo => TaskStatus::Todo,
        FfiTaskStatus::InProgress => TaskStatus::InProgress,
        FfiTaskStatus::Done => TaskStatus::Done,
        FfiTaskStatus::Cancelled => TaskStatus::Cancelled,
    }
}

fn map_time_shape(value: FfiTimeShapeFilter) -> TimeShapeFilter {
    match value {
        FfiTimeShapeFilter::Any => TimeShapeFilter::Any,
        FfiTimeShapeFilter::BoundedOnly => TimeShapeFilter::BoundedOnly,
    }
}

fn map_sort_spec(value: FfiSortSpec) -> SortSpec {
    match value {
        FfiSortSpec::UpdatedAtDesc => SortSpec::UpdatedAtDesc,
        FfiSortSpec::StartAtAsc => SortSpec::StartAtAsc,
        FfiSortSpec::TitleAsc => SortSpec::TitleAsc,
    }
}

fn map_projection_mode(value: FfiProjectionMode) -> ProjectionMode {
    match value {
        FfiProjectionMode::Atom => ProjectionMode::Atom,
        FfiProjectionMode::Ref => ProjectionMode::Ref,
    }
}

fn build_scoped_query(descriptor: FfiScopedAtomQuery) -> Result<ScopedAtomQuery, GuardedFfiError> {
    let folder_id = parse_guarded_node_id(descriptor.folder_id.as_str())?;
    let time_filter = match descriptor.time_filter {
        FfiTimeFilterKind::Any => TimeFilter::Any,
        FfiTimeFilterKind::Timeless => {
            if descriptor.include_overdue_deadlines {
                return Err(GuardedFfiError::InvalidQueryDescriptor(
                    "include_overdue_deadlines requires range time filter".to_string(),
                ));
            }
            TimeFilter::Timeless
        }
        FfiTimeFilterKind::Range => {
            let start_ms = descriptor.time_start_ms.ok_or_else(|| {
                GuardedFfiError::InvalidQueryDescriptor(
                    "range query requires time_start_ms".to_string(),
                )
            })?;
            TimeFilter::Range {
                start_ms,
                end_ms: descriptor.time_end_ms,
            }
        }
    };
    if descriptor.include_overdue_deadlines && !matches!(time_filter, TimeFilter::Range { .. }) {
        return Err(GuardedFfiError::InvalidQueryDescriptor(
            "include_overdue_deadlines requires range time filter".to_string(),
        ));
    }

    let status_filter = match descriptor.status_filter {
        FfiStatusFilterKind::Any => StatusFilter::Any,
        FfiStatusFilterKind::ActiveOnly => StatusFilter::ActiveOnly,
        FfiStatusFilterKind::TaskStatuses => {
            let statuses = descriptor.task_statuses.ok_or_else(|| {
                GuardedFfiError::InvalidQueryDescriptor(
                    "task_statuses filter requires task_statuses values".to_string(),
                )
            })?;
            StatusFilter::TaskStatuses(statuses.into_iter().map(map_task_status).collect())
        }
    };

    Ok(ScopedAtomQuery {
        folder_id,
        view_hint: map_view_hint_filter(descriptor.view_hint),
        time_filter,
        time_shape: map_time_shape(descriptor.time_shape),
        status_filter,
        tag: descriptor.tag,
        text_query: descriptor
            .text_query
            .and_then(|value| normalize_guarded_text_query(value.as_str())),
        include_path: descriptor.include_path,
        include_overdue_deadlines: descriptor.include_overdue_deadlines,
        sort: map_sort_spec(descriptor.sort),
        limit: descriptor.limit,
        offset: descriptor.offset,
    })
}

fn normalize_guarded_text_query(raw: &str) -> Option<String> {
    let terms = raw
        .split_whitespace()
        .map(str::trim)
        .filter(|term| !term.is_empty())
        .map(|term| format!("\"{}\"", term.replace('"', "\"\"")))
        .collect::<Vec<_>>();
    if terms.is_empty() {
        None
    } else {
        Some(terms.join(" AND "))
    }
}

fn build_create_atom_request(
    request: FfiCreateAtomRequest,
) -> Result<CreateAtomRequest, GuardedFfiError> {
    if request.content_type.trim() != "markdown" {
        return Err(GuardedFfiError::InvalidContentType(
            request.content_type.to_string(),
        ));
    }
    Ok(CreateAtomRequest {
        workspace_id: parse_guarded_workspace_id(request.workspace_id.as_str())?,
        content: request.content,
        content_type: request.content_type,
        task_status: request.task_status.map(map_task_status),
        start_at: request.start_at,
        end_at: request.end_at,
        tags: request.tags,
        target_folder: parse_guarded_optional_node_id(request.target_folder).map_err(|err| {
            match err {
                GuardedFfiError::InvalidNodeId(value) => {
                    GuardedFfiError::InvalidTargetFolder(value)
                }
                other => other,
            }
        })?,
        display_name: request.display_name,
    })
}

fn to_scoped_atom_item(item: ScopedAtomResult) -> ScopedAtomItem {
    ScopedAtomItem {
        uuid: item.atom.uuid.to_string(),
        view_hint: view_hint_label(item.atom.view_hint).to_string(),
        title: item.atom.title,
        content_type: item.atom.content_type,
        content: item.atom.content,
        preview_text: item.atom.preview_text,
        preview_image: item.atom.preview_image,
        tags: item.tags,
        task_status: item.atom.task_status.map(|status| {
            match status {
                TaskStatus::Todo => "todo",
                TaskStatus::InProgress => "in_progress",
                TaskStatus::Done => "done",
                TaskStatus::Cancelled => "cancelled",
            }
            .to_string()
        }),
        start_at: item.atom.start_at,
        end_at: item.atom.end_at,
        is_deleted: item.atom.is_deleted,
        updated_at: item.updated_at,
        representative_node_uuid: item.representative_node_uuid.to_string(),
        path: item.path,
    }
}

fn to_workspace_info(workspace: WorkspaceMetadata) -> WorkspaceInfo {
    WorkspaceInfo {
        workspace_id: workspace.workspace_id.to_string(),
        name: workspace.name,
        is_default: workspace.is_default,
    }
}

fn legacy_default_caller() -> FfiCallerContext {
    FfiCallerContext {
        identity: FfiCallerIdentity::App,
        scope_workspace_id: None,
    }
}

fn resolve_legacy_workspace_id(target_folder: Option<Uuid>) -> Result<String, GuardedFfiError> {
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

fn to_atom_list_item_from_scoped(item: ScopedAtomItem) -> AtomListItem {
    AtomListItem {
        atom_id: item.uuid,
        view_hint: item.view_hint,
        title: item.title,
        content_type: item.content_type,
        content: item.content,
        preview_text: item.preview_text,
        preview_image: item.preview_image,
        tags: item.tags,
        start_at: item.start_at,
        end_at: item.end_at,
        task_status: item.task_status,
        updated_at: item.updated_at,
    }
}

fn to_entry_search_item_from_hit(hit: SearchHit) -> EntrySearchItem {
    EntrySearchItem {
        atom_id: hit.atom_id.to_string(),
        view_hint: view_hint_label(hit.view_hint).to_string(),
        title: hit.title,
        snippet: hit.snippet,
    }
}

fn map_guarded_to_notes_error(err: GuardedFfiError) -> NotesFfiError {
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

fn map_guarded_to_atom_error(err: GuardedFfiError) -> AtomFfiError {
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

#[allow(clippy::too_many_arguments)]
fn legacy_root_scoped_query(
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

fn atom_list_from_scoped_query(
    response: ScopedQueryResponse,
    applied_limit: u32,
    success_label: &str,
) -> AtomListResponse {
    if response.ok {
        AtomListResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} {success_label}.", response.items.len()),
            items: response
                .items
                .into_iter()
                .map(to_atom_list_item_from_scoped)
                .collect(),
            applied_limit,
        }
    } else {
        AtomListResponse {
            ok: false,
            error_code: response.error_code,
            message: response.message,
            items: Vec::new(),
            applied_limit,
        }
    }
}

fn legacy_entry_search_via_fts(
    query_text: String,
    parsed_kind: Option<ViewHint>,
    applied_limit: u32,
) -> EntrySearchResponse {
    let db_path = resolve_entry_db_path();
    let conn = match open_db(&db_path) {
        Ok(conn) => conn,
        Err(err) => {
            return EntrySearchResponse {
                ok: false,
                error_code: Some("db_error".to_string()),
                items: Vec::new(),
                message: format!("entry_search failed: {err}"),
                applied_limit,
            };
        }
    };

    let mut query = SearchQuery::new(query_text);
    query.view_hint = parsed_kind;
    query.limit = applied_limit;

    match search_all(&conn, &query) {
        Ok(hits) => {
            let items = hits
                .into_iter()
                .map(to_entry_search_item_from_hit)
                .collect::<Vec<_>>();
            EntrySearchResponse {
                ok: true,
                error_code: None,
                message: if items.is_empty() {
                    "No results.".to_string()
                } else {
                    format!("Found {} result(s).", items.len())
                },
                items,
                applied_limit,
            }
        }
        Err(err) => EntrySearchResponse {
            ok: false,
            error_code: Some("internal_error".to_string()),
            items: Vec::new(),
            message: format!("entry_search failed: {err}"),
            applied_limit,
        },
    }
}

fn map_guarded_service_error(err: GuardedServiceError) -> GuardedFfiError {
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

fn map_guarded_repo_error(err: lazynote_core::RepoError) -> GuardedFfiError {
    match err {
        lazynote_core::RepoError::Db(db_err) => GuardedFfiError::DbError(db_err.to_string()),
        lazynote_core::RepoError::NotFound(atom_id) => {
            GuardedFfiError::AtomNotFound(atom_id.to_string())
        }
        other => GuardedFfiError::Internal(other.to_string()),
    }
}

fn map_guarded_tree_repo_error(err: TreeRepoError) -> GuardedFfiError {
    match err {
        TreeRepoError::Db(db_err) => GuardedFfiError::DbError(db_err.to_string()),
        TreeRepoError::NodeNotFound(node_id) => GuardedFfiError::InvalidNodeId(node_id.to_string()),
        other => GuardedFfiError::Internal(other.to_string()),
    }
}

fn map_guarded_db_error(err: lazynote_core::db::DbError) -> GuardedFfiError {
    GuardedFfiError::DbError(err.to_string())
}

fn scoped_query_failure(error: GuardedFfiError) -> ScopedQueryResponse {
    ScopedQueryResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        items: Vec::new(),
    }
}

fn atom_create_failure(error: GuardedFfiError) -> AtomCreateResponse {
    AtomCreateResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        atom_uuid: None,
        node_uuid: None,
    }
}

fn guarded_workspace_list_failure(error: GuardedFfiError) -> WorkspaceListResponse {
    WorkspaceListResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        workspaces: Vec::new(),
    }
}

fn guarded_workspace_info_failure(error: GuardedFfiError) -> WorkspaceInfoResponse {
    WorkspaceInfoResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        workspace: None,
    }
}

fn designated_folder_failure(error: GuardedFfiError) -> DesignatedFolderResponse {
    DesignatedFolderResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        node_uuid: None,
    }
}

fn guarded_ancestor_path_failure(error: GuardedFfiError) -> AncestorPathResponse {
    AncestorPathResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        segments: Vec::new(),
    }
}

fn atom_ref_locations_failure(error: GuardedFfiError) -> AtomRefLocationsResponse {
    AtomRefLocationsResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        locations: Vec::new(),
    }
}

fn workspace_failure_from_guarded(error: GuardedFfiError) -> WorkspaceActionResponse {
    WorkspaceActionResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
    }
}

fn workspace_reassign_failure(
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

fn with_guarded_query_service_using_guard<T>(
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

fn with_guarded_creation_service_using_guard<T>(
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

fn guarded_workspace_exists(workspace_id: Uuid) -> Result<bool, GuardedFfiError> {
    let db_path = resolve_entry_db_path();
    let conn = open_db(&db_path).map_err(map_guarded_db_error)?;
    let workspace_meta =
        SqliteWorkspaceMetaRepository::try_new(&conn).map_err(map_guarded_tree_repo_error)?;
    workspace_meta
        .workspace_exists(workspace_id)
        .map_err(map_guarded_tree_repo_error)
}

fn with_guarded_atom_service<T>(
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

fn with_guarded_task_service<T>(
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

fn with_guarded_workspace_service<T>(
    f: impl FnOnce(
        &GuardedWorkspaceService<'_, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    with_guarded_workspace_service_using_guard(Box::new(NoopGuard), f)
}

fn with_guarded_workspace_service_using_guard<T>(
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

fn with_guarded_tree_service<T>(
    f: impl FnOnce(
        &GuardedTreeService<'_, SqliteTreeRepository<'_>, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    with_guarded_tree_service_using_guard(Box::new(NoopGuard), f)
}

fn with_guarded_tree_service_using_guard<T>(
    guard: Box<dyn AccessGuard>,
    f: impl FnOnce(
        &GuardedTreeService<'_, SqliteTreeRepository<'_>, SqliteWorkspaceMetaRepository<'_>>,
    ) -> Result<T, GuardedServiceError>,
) -> Result<T, GuardedFfiError> {
    with_guarded_tree_service_raw_using_guard(guard, f).map_err(map_guarded_service_error)
}

fn with_guarded_tree_service_raw_using_guard<T>(
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
    let tree_service = TreeService::with_workspace_meta(repo, workspace_meta);
    let guarded = GuardedTreeService::new(guard, &tree_service);
    f(&guarded)
}

fn normalize_entry_limit(limit: Option<u32>) -> u32 {
    match limit {
        Some(0) => ENTRY_DEFAULT_LIMIT,
        Some(value) if value > ENTRY_SEARCH_MAX_LIMIT => ENTRY_SEARCH_MAX_LIMIT,
        Some(value) => value,
        None => ENTRY_DEFAULT_LIMIT,
    }
}

fn resolve_entry_db_path() -> PathBuf {
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

fn set_configured_entry_db_path(db_path: &str) -> Result<(), String> {
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

fn with_note_service<T>(
    f: impl FnOnce(&mut NoteService<SqliteNoteRepository<'_>>) -> Result<T, NoteServiceError>,
) -> Result<T, NotesFfiError> {
    let db_path = resolve_entry_db_path();
    let mut conn = open_db(&db_path).map_err(map_db_error)?;
    let repo = SqliteNoteRepository::try_new(&mut conn).map_err(map_repo_error)?;
    let mut service = NoteService::new(repo);
    f(&mut service).map_err(map_note_service_error)
}

fn with_tree_service<T>(
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

fn parse_optional_parent_node_id(raw: Option<String>) -> Result<Option<Uuid>, WorkspaceFfiError> {
    match raw {
        None => Ok(None),
        Some(value) => {
            let trimmed = value.trim();
            if trimmed.is_empty() {
                return Err(WorkspaceFfiError::InvalidParentNodeId(value));
            }
            Uuid::parse_str(trimmed)
                .map(Some)
                .map_err(|_| WorkspaceFfiError::InvalidParentNodeId(value))
        }
    }
}

fn parse_workspace_atom_id(raw: &str) -> Result<AtomId, WorkspaceFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| WorkspaceFfiError::InvalidAtomId(raw.to_string()))
}

fn parse_note_id(raw: &str) -> Result<AtomId, NotesFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| NotesFfiError::InvalidNoteId(raw.to_string()))
}

/// Converts a `NoteRecord` (with S8-expanded fields) into `AtomListItem`.
fn to_atom_list_item_from_note(nr: NoteRecord) -> AtomListItem {
    AtomListItem {
        atom_id: nr.atom_id.to_string(),
        view_hint: nr.view_hint,
        title: nr.title,
        content_type: nr.content_type,
        content: nr.content,
        preview_text: nr.preview_text,
        preview_image: nr.preview_image,
        tags: nr.tags,
        start_at: nr.start_at,
        end_at: nr.end_at,
        task_status: nr.task_status,
        updated_at: nr.updated_at,
    }
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

fn note_failure(error: NotesFfiError) -> AtomItemResponse {
    AtomItemResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        item: None,
        node_uuid: None,
    }
}

fn workspace_failure(error: WorkspaceFfiError) -> WorkspaceActionResponse {
    WorkspaceActionResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
    }
}

fn workspace_node_failure(error: WorkspaceFfiError) -> WorkspaceNodeResponse {
    WorkspaceNodeResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        node: None,
    }
}

fn workspace_list_failure(error: WorkspaceFfiError) -> WorkspaceListChildrenResponse {
    WorkspaceListChildrenResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        items: Vec::new(),
    }
}

fn workspace_ancestor_path_failure(error: WorkspaceFfiError) -> WorkspaceAncestorPathResponse {
    WorkspaceAncestorPathResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        path: Vec::new(),
    }
}

fn map_note_service_error(err: NoteServiceError) -> NotesFfiError {
    match err {
        NoteServiceError::InvalidTag(value) => NotesFfiError::InvalidTag(value),
        NoteServiceError::NoteNotFound(atom_id) => NotesFfiError::NoteNotFound(atom_id.to_string()),
        NoteServiceError::Repo(repo_err) => map_repo_error(repo_err),
        NoteServiceError::InconsistentState(details) => {
            NotesFfiError::Internal(details.to_string())
        }
    }
}

fn map_repo_error(err: lazynote_core::RepoError) -> NotesFfiError {
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

fn map_db_error(err: lazynote_core::db::DbError) -> NotesFfiError {
    if is_db_busy(&err) {
        NotesFfiError::DbBusy(err.to_string())
    } else {
        NotesFfiError::DbError(err.to_string())
    }
}

fn map_workspace_db_error(err: lazynote_core::db::DbError) -> WorkspaceFfiError {
    if is_db_busy(&err) {
        WorkspaceFfiError::DbBusy(err.to_string())
    } else {
        WorkspaceFfiError::DbError(err.to_string())
    }
}

fn map_tree_repo_error(err: TreeRepoError) -> WorkspaceFfiError {
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

fn map_tree_service_error(err: TreeServiceError) -> WorkspaceFfiError {
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

fn is_db_busy(err: &lazynote_core::db::DbError) -> bool {
    matches!(
        err,
        lazynote_core::db::DbError::Sqlite(rusqlite::Error::SqliteFailure(sqlite_err, _))
            if sqlite_err.code == rusqlite::ErrorCode::DatabaseBusy
                || sqlite_err.code == rusqlite::ErrorCode::DatabaseLocked
    )
}

fn view_hint_label(hint: ViewHint) -> &'static str {
    match hint {
        ViewHint::Note => "note",
        ViewHint::Task => "task",
        ViewHint::Event => "event",
    }
}

// ---------------------------------------------------------------------------
// Tasks / Section APIs (v0.1.5)
// ---------------------------------------------------------------------------

/// Atom list item returned by section queries (Inbox/Today/Upcoming).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomListItem {
    /// Stable atom ID in string form.
    pub atom_id: String,
    /// Atom view hint (`note|task|event`).
    pub view_hint: String,
    /// User-facing title derived from content.
    pub title: String,
    /// Content format indicator (e.g. `markdown`).
    pub content_type: String,
    /// Raw markdown content.
    pub content: String,
    /// Derived plain-text preview.
    pub preview_text: Option<String>,
    /// Derived first markdown image path.
    pub preview_image: Option<String>,
    /// Normalized lowercase tags for this atom.
    pub tags: Vec<String>,
    /// Epoch ms — start boundary (NULL = no start).
    pub start_at: Option<i64>,
    /// Epoch ms — end boundary (NULL = no end).
    pub end_at: Option<i64>,
    /// Current task status string, or null if statusless.
    pub task_status: Option<String>,
    /// Update timestamp in epoch milliseconds.
    pub updated_at: i64,
}

/// Single atom item response envelope (notes create/update/get/set_tags).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomItemResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
    /// Returned atom item payload on success.
    pub item: Option<AtomListItem>,
    /// Optional workspace node ID for the created atom_ref (S4, create-only).
    pub node_uuid: Option<String>,
}

/// Section list response envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomListResponse {
    /// Whether operation succeeded.
    pub ok: bool,
    /// Stable machine-readable error code for failure paths.
    pub error_code: Option<String>,
    /// Human-readable message for diagnostics/UI.
    pub message: String,
    /// Section items.
    pub items: Vec<AtomListItem>,
    /// Effective limit after normalization.
    pub applied_limit: u32,
}

const SECTION_DEFAULT_LIMIT: u32 = 50;
const SECTION_LIMIT_MAX: u32 = 50;

#[derive(Debug)]
#[allow(dead_code)] // Internal reserved for future use
enum AtomFfiError {
    InvalidAtomId(String),
    AtomNotFound(String),
    InvalidStatus(String),
    InvalidTimeRange(String),
    DbError(String),
    Internal(String),
}

impl AtomFfiError {
    fn code(&self) -> &'static str {
        match self {
            Self::InvalidAtomId(_) => "invalid_atom_id",
            Self::AtomNotFound(_) => "atom_not_found",
            Self::InvalidStatus(_) => "invalid_status",
            Self::InvalidTimeRange(_) => "invalid_time_range",
            Self::DbError(_) => "db_error",
            Self::Internal(_) => "internal_error",
        }
    }

    fn message(&self) -> String {
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

fn normalize_section_limit(limit: Option<u32>) -> u32 {
    match limit {
        Some(0) => SECTION_DEFAULT_LIMIT,
        Some(v) if v > SECTION_LIMIT_MAX => SECTION_LIMIT_MAX,
        Some(v) => v,
        None => SECTION_DEFAULT_LIMIT,
    }
}

fn to_atom_list_item(sa: SectionAtom) -> AtomListItem {
    AtomListItem {
        atom_id: sa.atom.uuid.to_string(),
        view_hint: view_hint_label(sa.atom.view_hint).to_string(),
        title: sa.atom.title,
        content_type: sa.atom.content_type,
        content: sa.atom.content,
        preview_text: sa.atom.preview_text,
        preview_image: sa.atom.preview_image,
        tags: sa.tags,
        start_at: sa.atom.start_at,
        end_at: sa.atom.end_at,
        task_status: sa.atom.task_status.map(|s| {
            match s {
                lazynote_core::TaskStatus::Todo => "todo",
                lazynote_core::TaskStatus::InProgress => "in_progress",
                lazynote_core::TaskStatus::Done => "done",
                lazynote_core::TaskStatus::Cancelled => "cancelled",
            }
            .to_string()
        }),
        updated_at: sa.updated_at,
    }
}

fn atom_list_failure(err: AtomFfiError, limit: u32) -> AtomListResponse {
    AtomListResponse {
        ok: false,
        error_code: Some(err.code().to_string()),
        message: err.message(),
        items: Vec::new(),
        applied_limit: limit,
    }
}

/// Lists inbox atoms (both `start_at` and `end_at` NULL).
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Excludes done/cancelled atoms.
#[flutter_rust_bridge::frb]
pub async fn tasks_list_inbox(limit: Option<u32>, offset: Option<u32>) -> AtomListResponse {
    tasks_list_inbox_impl(limit, offset)
}

fn tasks_list_inbox_impl(limit: Option<u32>, offset: Option<u32>) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Timeless,
        None,
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        false,
        FfiSortSpec::UpdatedAtDesc,
        norm_limit,
        norm_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), norm_limit),
    };

    atom_list_from_scoped_query(
        query_atoms_impl(legacy_default_caller(), descriptor, FfiProjectionMode::Atom),
        norm_limit,
        "inbox item(s)",
    )
}

/// Lists atoms active today based on time-matrix rules.
///
/// # FFI contract
/// - `bod_ms`/`eod_ms`: device-local day boundaries in epoch ms.
/// - Async call, DB-backed execution.
/// - Excludes done/cancelled atoms.
#[flutter_rust_bridge::frb]
pub async fn tasks_list_today(
    bod_ms: i64,
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    tasks_list_today_impl(bod_ms, eod_ms, limit, offset)
}

fn tasks_list_today_impl(
    bod_ms: i64,
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(bod_ms),
        Some(eod_ms),
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        true,
        FfiSortSpec::StartAtAsc,
        norm_limit,
        norm_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), norm_limit),
    };

    atom_list_from_scoped_query(
        query_atoms_impl(legacy_default_caller(), descriptor, FfiProjectionMode::Atom),
        norm_limit,
        "today item(s)",
    )
}

/// Lists atoms anchored entirely in the future.
///
/// # FFI contract
/// - `eod_ms`: end of today in epoch ms.
/// - Async call, DB-backed execution.
/// - Excludes done/cancelled atoms.
#[flutter_rust_bridge::frb]
pub async fn tasks_list_upcoming(
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    tasks_list_upcoming_impl(eod_ms, limit, offset)
}

fn tasks_list_upcoming_impl(
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(eod_ms),
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        false,
        FfiSortSpec::StartAtAsc,
        norm_limit,
        norm_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), norm_limit),
    };

    atom_list_from_scoped_query(
        query_atoms_impl(legacy_default_caller(), descriptor, FfiProjectionMode::Atom),
        norm_limit,
        "upcoming item(s)",
    )
}

/// Updates `task_status` for any atom type (universal completion).
///
/// # FFI contract
/// - `status`: one of `todo|in_progress|done|cancelled`, or null to clear (demote).
/// - Async call, DB-backed execution.
/// - Idempotent: setting the same status twice succeeds.
#[flutter_rust_bridge::frb]
pub async fn atom_update_status(atom_id: String, status: Option<String>) -> EntryActionResponse {
    atom_update_status_impl(atom_id, status)
}

fn atom_update_status_impl(atom_id: String, status: Option<String>) -> EntryActionResponse {
    let parsed_id = match Uuid::parse_str(atom_id.trim()) {
        Ok(id) => id,
        Err(_) => {
            let err = AtomFfiError::InvalidAtomId(atom_id);
            return EntryActionResponse::failure(err.message());
        }
    };

    let parsed_status = match status.as_deref() {
        None => None,
        Some("todo") => Some(lazynote_core::TaskStatus::Todo),
        Some("in_progress") => Some(lazynote_core::TaskStatus::InProgress),
        Some("done") => Some(lazynote_core::TaskStatus::Done),
        Some("cancelled") => Some(lazynote_core::TaskStatus::Cancelled),
        Some(other) => {
            let err = AtomFfiError::InvalidStatus(other.to_string());
            return EntryActionResponse::failure(err.message());
        }
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_task_service(|svc| svc.update_status(&caller, parsed_id, parsed_status)) {
        Ok(()) => EntryActionResponse {
            ok: true,
            atom_id: Some(parsed_id.to_string()),
            node_uuid: None,
            message: "Status updated.".to_string(),
        },
        Err(err) => EntryActionResponse::failure(map_guarded_to_atom_error(err).message()),
    }
}

/// Returns all non-deleted, non-completed atoms that have at least one time field set.
/// Used for startup reminder recovery.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - No pagination: returns all matching rows (timed atom count is bounded in practice).
/// - Excludes done/cancelled atoms.
#[flutter_rust_bridge::frb]
pub async fn atoms_list_timed() -> AtomListResponse {
    atoms_list_timed_impl()
}

fn atoms_list_timed_impl() -> AtomListResponse {
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(i64::MIN),
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        false,
        FfiSortSpec::UpdatedAtDesc,
        u32::MAX,
        0,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), 0),
    };
    let response = query_atoms_impl(legacy_default_caller(), descriptor, FfiProjectionMode::Atom);
    if response.ok {
        let count = response.items.len() as u32;
        AtomListResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} timed atom(s).", count),
            items: response
                .items
                .into_iter()
                .map(to_atom_list_item_from_scoped)
                .collect(),
            applied_limit: count,
        }
    } else {
        AtomListResponse {
            ok: false,
            error_code: response.error_code,
            message: response.message,
            items: Vec::new(),
            applied_limit: 0,
        }
    }
}

/// Gets one atom by stable id, regardless of view_hint.
///
/// Unlike `note_get` which only returns `view_hint = 'note'` atoms, this
/// returns any non-deleted atom (note, task, or event).
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Returns typed envelope with stable error codes.
/// - Returns `atom_not_found` when the target does not exist or is soft-deleted.
#[flutter_rust_bridge::frb]
pub async fn atom_get(atom_id: String) -> AtomItemResponse {
    atom_get_impl(atom_id)
}

fn atom_get_impl(atom_id: String) -> AtomItemResponse {
    let parsed_id = match Uuid::parse_str(atom_id.trim()) {
        Ok(id) => id,
        Err(_) => {
            return AtomItemResponse {
                ok: false,
                error_code: Some("invalid_atom_id".to_string()),
                message: format!("Invalid atom ID: {atom_id}"),
                item: None,
                node_uuid: None,
            };
        }
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|svc| {
        svc.get_atom(&caller, parsed_id)?
            .ok_or(GuardedServiceError::Task(TaskServiceError::AtomNotFound(
                parsed_id,
            )))
    }) {
        Ok(sa) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Atom loaded.".to_string(),
            item: Some(to_atom_list_item(sa)),
            node_uuid: None,
        },
        Err(err) => {
            let mapped = map_guarded_to_atom_error(err);
            AtomItemResponse {
                ok: false,
                error_code: Some(mapped.code().to_string()),
                message: mapped.message(),
                item: None,
                node_uuid: None,
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Calendar APIs (PR-0012A)
// ---------------------------------------------------------------------------

/// Lists atoms with both `start_at` and `end_at` that overlap the given time range.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Includes all statuses (done/cancelled shown on calendar).
/// - Range overlap: `start_at < range_end AND end_at > range_start`.
#[flutter_rust_bridge::frb]
pub async fn calendar_list_by_range(
    start_ms: i64,
    end_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    calendar_list_by_range_impl(start_ms, end_ms, limit, offset)
}

fn calendar_list_by_range_impl(
    start_ms: i64,
    end_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(start_ms),
        Some(end_ms),
        FfiTimeShapeFilter::BoundedOnly,
        FfiStatusFilterKind::Any,
        None,
        None,
        false,
        FfiSortSpec::StartAtAsc,
        norm_limit,
        norm_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), norm_limit),
    };

    atom_list_from_scoped_query(
        query_atoms_impl(legacy_default_caller(), descriptor, FfiProjectionMode::Atom),
        norm_limit,
        "calendar event(s)",
    )
}

/// Updates only `start_at` and `end_at` for a calendar event.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Validates `end_ms >= start_ms`; returns `invalid_time_range` on failure.
/// - Returns `atom_not_found` when target atom does not exist.
#[flutter_rust_bridge::frb]
pub async fn calendar_update_event(
    atom_id: String,
    start_ms: i64,
    end_ms: i64,
) -> EntryActionResponse {
    calendar_update_event_impl(atom_id, start_ms, end_ms)
}

fn calendar_update_event_impl(atom_id: String, start_ms: i64, end_ms: i64) -> EntryActionResponse {
    let parsed_id = match Uuid::parse_str(atom_id.trim()) {
        Ok(id) => id,
        Err(_) => {
            let err = AtomFfiError::InvalidAtomId(atom_id);
            return EntryActionResponse::failure(err.message());
        }
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|svc| svc.update_time(&caller, parsed_id, start_ms, end_ms)) {
        Ok(()) => EntryActionResponse {
            ok: true,
            atom_id: Some(parsed_id.to_string()),
            node_uuid: None,
            message: "Event times updated.".to_string(),
        },
        Err(err) => EntryActionResponse::failure(map_guarded_to_atom_error(err).message()),
    }
}

#[cfg(test)]
mod tests {
    use super::{
        atom_create_impl, atom_create_impl_with_guard, atom_get_impl, calendar_list_by_range_impl,
        calendar_update_event_impl, configure_entry_db_path, core_version, entry_create_note_impl,
        entry_create_task_impl, entry_schedule_impl, entry_search_impl, init_logging,
        log_dart_event_impl, map_db_error, map_log_dart_event_error, map_repo_error,
        map_workspace_db_error, note_create_impl, note_get_impl, note_set_tags_impl,
        note_update_impl, notes_list_impl, ping, query_atoms_impl, query_atoms_impl_with_guard,
        tags_list_impl, tasks_list_inbox_impl, tasks_list_today_impl, tasks_list_upcoming_impl,
        workspace_create_atom_ref_impl, workspace_create_folder_impl, workspace_delete_folder_impl,
        workspace_get_ancestor_path_impl, workspace_get_default_impl,
        workspace_list_atom_refs_for_atom_impl, workspace_list_children_impl, workspace_list_impl,
        workspace_list_impl_with_guard, workspace_move_node_impl,
        workspace_reassign_designated_impl, workspace_rename_node_impl,
        workspace_resolve_designated_impl, FfiCallerContext, FfiCallerIdentity,
        FfiCreateAtomRequest, FfiProjectionMode, FfiScopedAtomQuery, FfiSortSpec,
        FfiStatusFilterKind, FfiTaskStatus, FfiTimeFilterKind, FfiTimeShapeFilter, NotesFfiError,
        WorkspaceFfiError,
    };
    use lazynote_core::db::open_db;
    use lazynote_core::LogDartEventError;
    use lazynote_core::{
        search_all, AccessError, AccessGuard, Atom, AtomRepository, CallerContext, CallerIdentity,
        Capability, SearchQuery, SqliteAtomRepository, SqliteTreeRepository, TaskStatus,
        TreeService, ViewHint,
    };
    use std::sync::{Mutex, MutexGuard};
    use std::time::{SystemTime, UNIX_EPOCH};
    use uuid::Uuid;

    static TEST_DB_LOCK: Mutex<()> = Mutex::new(());

    fn acquire_test_db_lock() -> MutexGuard<'static, ()> {
        let guard = TEST_DB_LOCK
            .lock()
            .expect("ffi api test db lock should not be poisoned");
        let db_path =
            std::env::temp_dir().join(format!("lazynote_ffi_test_{}.sqlite3", unique_token("db")));
        let configure_error = configure_entry_db_path(db_path.to_string_lossy().to_string());
        assert!(
            configure_error.is_empty(),
            "configure test db path: {configure_error}"
        );
        guard
    }

    struct CrossWorkspaceDenyGuard;

    impl AccessGuard for CrossWorkspaceDenyGuard {
        fn check_read(
            &self,
            caller: &CallerContext,
            target_workspace: &Uuid,
        ) -> Result<(), AccessError> {
            Err(AccessError::CrossWorkspaceAccessDenied {
                scope: caller.scope_workspace_id.unwrap_or(*target_workspace),
                target: *target_workspace,
            })
        }

        fn check_write(
            &self,
            caller: &CallerContext,
            target_workspace: &Uuid,
        ) -> Result<(), AccessError> {
            Err(AccessError::CrossWorkspaceAccessDenied {
                scope: caller.scope_workspace_id.unwrap_or(*target_workspace),
                target: *target_workspace,
            })
        }
    }

    struct CapabilityDenyGuard;

    impl AccessGuard for CapabilityDenyGuard {
        fn check_read(
            &self,
            _caller: &CallerContext,
            _target_workspace: &Uuid,
        ) -> Result<(), AccessError> {
            Err(AccessError::InsufficientCapability {
                identity: CallerIdentity::App,
                required: Capability::WorkspaceRead,
            })
        }

        fn check_write(
            &self,
            _caller: &CallerContext,
            _target_workspace: &Uuid,
        ) -> Result<(), AccessError> {
            Err(AccessError::InsufficientCapability {
                identity: CallerIdentity::App,
                required: Capability::WorkspaceWrite,
            })
        }
    }

    struct SelectiveWorkspaceReadGuard {
        allowed_workspace: Uuid,
    }

    impl AccessGuard for SelectiveWorkspaceReadGuard {
        fn check_read(
            &self,
            _caller: &CallerContext,
            target_workspace: &Uuid,
        ) -> Result<(), AccessError> {
            if *target_workspace == self.allowed_workspace {
                Ok(())
            } else {
                Err(AccessError::CrossWorkspaceAccessDenied {
                    scope: self.allowed_workspace,
                    target: *target_workspace,
                })
            }
        }

        fn check_write(
            &self,
            _caller: &CallerContext,
            _target_workspace: &Uuid,
        ) -> Result<(), AccessError> {
            Ok(())
        }
    }

    #[test]
    fn ping_returns_pong() {
        let _guard = acquire_test_db_lock();
        assert_eq!(ping(), "pong");
    }

    #[test]
    fn version_is_not_empty() {
        let _guard = acquire_test_db_lock();
        assert!(!core_version().is_empty());
    }

    #[test]
    fn init_logging_rejects_empty_log_dir() {
        let _guard = acquire_test_db_lock();
        let error = init_logging("info".to_string(), String::new());
        assert!(!error.is_empty());
    }

    #[test]
    fn init_logging_rejects_unsupported_level() {
        let _guard = acquire_test_db_lock();
        let error = init_logging("verbose".to_string(), "tmp/logs".to_string());
        assert!(!error.is_empty());
    }

    #[test]
    fn log_dart_event_rejects_invalid_level() {
        let _guard = acquire_test_db_lock();
        let response = log_dart_event_impl(
            "verbose".to_string(),
            "app.start".to_string(),
            "workbench".to_string(),
            "hello".to_string(),
        );
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("invalid_level"));
    }

    #[test]
    fn log_dart_event_rejects_blank_event_name() {
        let _guard = acquire_test_db_lock();
        let response = log_dart_event_impl(
            "info".to_string(),
            "   ".to_string(),
            "workbench".to_string(),
            "hello".to_string(),
        );
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("invalid_event_name"));
    }

    #[test]
    fn log_dart_event_rejects_blank_module() {
        let _guard = acquire_test_db_lock();
        let response = log_dart_event_impl(
            "info".to_string(),
            "app.start".to_string(),
            "   ".to_string(),
            "hello".to_string(),
        );
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("invalid_module"));
    }

    #[test]
    fn log_dart_event_rejects_oversized_message() {
        let _guard = acquire_test_db_lock();
        let long_message = "x".repeat(513);
        let response = log_dart_event_impl(
            "info".to_string(),
            "app.start".to_string(),
            "workbench".to_string(),
            long_message,
        );
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("invalid_message"));
    }

    #[test]
    fn log_dart_event_maps_logging_not_initialized_error() {
        let mapped = map_log_dart_event_error(LogDartEventError::LoggingNotInitialized);
        assert_eq!(mapped.code(), "logging_not_initialized");
    }

    #[test]
    fn configure_entry_db_path_rejects_empty_path() {
        let _guard = acquire_test_db_lock();
        let error = configure_entry_db_path(String::new());
        assert!(!error.is_empty());
    }

    #[test]
    fn configure_entry_db_path_rejects_relative_path() {
        let _guard = acquire_test_db_lock();
        let error = configure_entry_db_path("relative/path.sqlite3".to_string());
        assert!(!error.is_empty());
    }

    #[test]
    fn entry_search_normalizes_limit_and_finds_created_note() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("entry-search");
        let created = entry_create_note_impl(format!("note {token}"));
        assert!(created.ok, "{}", created.message);
        let created_id = created
            .atom_id
            .clone()
            .expect("created note should return atom_id");

        let response = entry_search_impl(token, None, Some(200));
        assert_eq!(response.applied_limit, 50);
        assert!(response.ok, "{}", response.message);
        assert!(response.error_code.is_none());
        assert!(response.items.iter().any(|item| item.atom_id == created_id));
    }

    #[test]
    fn entry_search_rejects_invalid_kind() {
        let _guard = acquire_test_db_lock();
        let response = entry_search_impl("hello".to_string(), Some("memo".to_string()), Some(7));
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("invalid_kind"));
        assert_eq!(response.applied_limit, 7);

        let blank_response =
            entry_search_impl("hello".to_string(), Some("   ".to_string()), Some(7));
        assert!(!blank_response.ok);
        assert_eq!(blank_response.error_code.as_deref(), Some("invalid_kind"));
    }

    #[test]
    fn entry_search_filters_results_by_kind() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("entry-search-kind");

        let note = entry_create_note_impl(format!("note {token}"));
        assert!(note.ok, "{}", note.message);

        let task = entry_create_task_impl(format!("task {token}"));
        assert!(task.ok, "{}", task.message);

        let note_response = entry_search_impl(token.clone(), Some("note".to_string()), Some(50));
        assert!(note_response.ok, "{}", note_response.message);
        assert!(!note_response.items.is_empty());
        assert!(note_response
            .items
            .iter()
            .all(|item| item.view_hint == "note"));

        let task_response = entry_search_impl(token, Some("task".to_string()), Some(50));
        assert!(task_response.ok, "{}", task_response.message);
        assert!(!task_response.items.is_empty());
        assert!(task_response
            .items
            .iter()
            .all(|item| item.view_hint == "task"));
    }

    #[test]
    fn entry_search_kind_filter_is_case_insensitive() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("entry-search-kind-case");

        let note = entry_create_note_impl(format!("note {token}"));
        assert!(note.ok, "{}", note.message);

        let task = entry_create_task_impl(format!("task {token}"));
        assert!(task.ok, "{}", task.message);

        let note_response = entry_search_impl(token.clone(), Some("NOTE".to_string()), Some(50));
        assert!(note_response.ok, "{}", note_response.message);
        assert!(!note_response.items.is_empty());
        assert!(note_response
            .items
            .iter()
            .all(|item| item.view_hint == "note"));

        let task_response = entry_search_impl(token, Some("Task".to_string()), Some(50));
        assert!(task_response.ok, "{}", task_response.message);
        assert!(!task_response.items.is_empty());
        assert!(task_response
            .items
            .iter()
            .all(|item| item.view_hint == "task"));
    }

    #[test]
    fn entry_create_task_sets_default_todo_status() {
        let _guard = acquire_test_db_lock();
        let task = entry_create_task_impl("todo".to_string());
        assert!(task.ok, "{}", task.message);
        let atom_id = task.atom_id.expect("task create should return atom_id");

        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        let (kind, status): (String, Option<String>) = conn
            .query_row(
                "SELECT view_hint, task_status FROM atoms WHERE uuid = ?1",
                [atom_id.as_str()],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .expect("query task row");
        assert_eq!(kind, "task");
        assert_eq!(status.as_deref(), Some("todo"));
    }

    #[test]
    fn entry_schedule_supports_point_shape() {
        let _guard = acquire_test_db_lock();
        let title = unique_token("entry-schedule-point");
        let response = entry_schedule_impl(title, 1_700_000_000_000, None);
        assert!(response.ok, "{}", response.message);
        let atom_id = response.atom_id.expect("schedule should return atom_id");

        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        let (kind, start, end): (String, Option<i64>, Option<i64>) = conn
            .query_row(
                "SELECT view_hint, start_at, end_at FROM atoms WHERE uuid = ?1",
                [atom_id.as_str()],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
            )
            .expect("query event row");
        assert_eq!(kind, "event");
        assert_eq!(start, Some(1_700_000_000_000));
        assert_eq!(end, None);
    }

    #[test]
    fn entry_schedule_rejects_reversed_time_range() {
        let _guard = acquire_test_db_lock();
        let response = entry_schedule_impl("bad range".to_string(), 2_000, Some(1_000));
        assert!(!response.ok);
        assert!(response.message.contains("end_at"));
    }

    #[test]
    fn note_create_and_get_returns_typed_payload() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("# heading ![](first.png)".to_string(), None);
        assert!(created.ok, "{}", created.message);
        assert!(created.error_code.is_none());
        let atom_id = created
            .item
            .as_ref()
            .expect("note payload should exist")
            .atom_id
            .clone();

        let loaded = note_get_impl(atom_id);
        assert!(loaded.ok, "{}", loaded.message);
        assert!(loaded.error_code.is_none());
        assert_eq!(
            loaded
                .item
                .as_ref()
                .and_then(|n| n.preview_image.as_deref()),
            Some("first.png")
        );
    }

    #[test]
    fn note_get_returns_s8_fields_for_pure_note() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("s8 field check".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let loaded = note_get_impl(atom_id);
        assert!(loaded.ok, "{}", loaded.message);
        let item = loaded.item.as_ref().expect("loaded payload");
        assert_eq!(item.view_hint, "note", "view_hint must be 'note'");
        assert!(item.start_at.is_none(), "pure note has no start_at");
        assert!(item.end_at.is_none(), "pure note has no end_at");
        assert!(item.task_status.is_none(), "pure note has no task_status");
    }

    #[test]
    fn atom_get_returns_note() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("atom_get note test".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let loaded = atom_get_impl(atom_id);
        assert!(loaded.ok, "{}", loaded.message);
        let item = loaded.item.as_ref().expect("loaded payload");
        assert_eq!(item.view_hint, "note");
        assert!(item.content.contains("atom_get note test"));
    }

    #[test]
    fn atom_get_returns_task() {
        let _guard = acquire_test_db_lock();
        let created = entry_create_task_impl("atom_get task test".to_string());
        assert!(created.ok, "{}", created.message);
        let atom_id = created.atom_id.clone().expect("task atom_id");

        let loaded = atom_get_impl(atom_id);
        assert!(loaded.ok, "{}", loaded.message);
        let item = loaded.item.as_ref().expect("loaded payload");
        assert_eq!(item.view_hint, "task");
        assert_eq!(item.task_status.as_deref(), Some("todo"));
    }

    #[test]
    fn atom_get_returns_event() {
        let _guard = acquire_test_db_lock();
        let start = 1_700_100_000_000_i64;
        let end = 1_700_103_600_000_i64;
        let created = entry_schedule_impl("atom_get event test".to_string(), start, Some(end));
        assert!(created.ok, "{}", created.message);
        let atom_id = created.atom_id.clone().expect("event atom_id");

        let loaded = atom_get_impl(atom_id);
        assert!(loaded.ok, "{}", loaded.message);
        let item = loaded.item.as_ref().expect("loaded payload");
        assert_eq!(item.view_hint, "event");
        assert_eq!(item.start_at, Some(start));
        assert_eq!(item.end_at, Some(end));
    }

    #[test]
    fn atom_get_returns_not_found_for_invalid_id() {
        let _guard = acquire_test_db_lock();
        let loaded = atom_get_impl("not-a-uuid".to_string());
        assert!(!loaded.ok);
        assert_eq!(loaded.error_code.as_deref(), Some("invalid_atom_id"));
    }

    #[test]
    fn atom_get_returns_not_found_for_nonexistent_id() {
        let _guard = acquire_test_db_lock();
        let loaded = atom_get_impl("00000000-0000-0000-0000-000000000000".to_string());
        assert!(!loaded.ok);
        assert_eq!(loaded.error_code.as_deref(), Some("atom_not_found"));
    }

    #[test]
    fn note_create_with_parent_places_atom_ref_under_folder() {
        let _guard = acquire_test_db_lock();

        // Create a folder to serve as parent.
        let folder = workspace_create_folder_impl(None, "target-folder".to_string());
        assert!(folder.ok, "{}", folder.message);
        let folder_id = folder.node.expect("folder node").node_id;

        // Create note with parent_node_id pointing to the folder.
        let created = note_create_impl("# child note".to_string(), Some(folder_id.clone()));
        assert!(created.ok, "{}", created.message);
        let node_uuid = created
            .node_uuid
            .expect("note_create should return node_uuid");

        // List children of the folder — the atom_ref must be there.
        let children = workspace_list_children_impl(Some(folder_id.clone()));
        assert!(children.ok, "{}", children.message);
        let child_ids: Vec<&str> = children.items.iter().map(|n| n.node_id.as_str()).collect();
        assert!(
            child_ids.contains(&node_uuid.as_str()),
            "atom_ref should be under target folder, got: {:?}",
            child_ids
        );

        // Root level must NOT contain a duplicate ref for the same atom.
        let root_children = workspace_list_children_impl(None);
        assert!(root_children.ok, "{}", root_children.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();
        let root_refs_for_atom: Vec<_> = root_children
            .items
            .iter()
            .filter(|n| n.atom_id.as_deref() == Some(atom_id.as_str()))
            .collect();
        assert!(
            root_refs_for_atom.is_empty(),
            "no duplicate root ref should exist; found {:?}",
            root_refs_for_atom
                .iter()
                .map(|n| &n.node_id)
                .collect::<Vec<_>>()
        );
    }

    #[test]
    fn note_create_without_parent_routes_atom_ref_to_inbox_designated_folder() {
        let _guard = acquire_test_db_lock();

        let created = note_create_impl("# root note".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let node_uuid = created
            .node_uuid
            .expect("note_create should return node_uuid");
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();
        let inbox_folder_id = designated_folder_node_id("inbox");

        let inbox_children = workspace_list_children_impl(Some(inbox_folder_id));
        assert!(inbox_children.ok, "{}", inbox_children.message);
        let inbox_refs: Vec<_> = inbox_children
            .items
            .iter()
            .filter(|n| n.atom_id.as_deref() == Some(atom_id.as_str()))
            .collect();
        assert_eq!(
            inbox_refs.len(),
            1,
            "exactly one inbox ref expected; found {}",
            inbox_refs.len()
        );
        assert_eq!(inbox_refs[0].node_id, node_uuid);
    }

    // T5 (PR-RB-11): atom_ref consistency — all creation entry points
    // produce an atom_ref in the workspace tree.

    #[test]
    fn entry_create_note_routes_atom_ref_to_inbox_designated_folder() {
        let _guard = acquire_test_db_lock();

        let created = entry_create_note_impl("entry note content".to_string());
        assert!(created.ok, "{}", created.message);
        let node_uuid = created
            .node_uuid
            .expect("entry_create_note should return node_uuid");
        let inbox_folder_id = designated_folder_node_id("inbox");

        let inbox_children = workspace_list_children_impl(Some(inbox_folder_id));
        assert!(inbox_children.ok, "{}", inbox_children.message);
        let found = inbox_children.items.iter().any(|n| n.node_id == node_uuid);
        assert!(
            found,
            "atom_ref from entry_create_note must appear under inbox designated folder; node_uuid={}",
            node_uuid
        );
    }

    #[test]
    fn entry_create_task_routes_atom_ref_to_tasks_designated_folder() {
        let _guard = acquire_test_db_lock();

        let created = entry_create_task_impl("entry task content".to_string());
        assert!(created.ok, "{}", created.message);
        let node_uuid = created
            .node_uuid
            .expect("entry_create_task should return node_uuid");
        let tasks_folder_id = designated_folder_node_id("tasks");

        let tasks_children = workspace_list_children_impl(Some(tasks_folder_id));
        assert!(tasks_children.ok, "{}", tasks_children.message);
        let found = tasks_children.items.iter().any(|n| n.node_id == node_uuid);
        assert!(
            found,
            "atom_ref from entry_create_task must appear under tasks designated folder; node_uuid={}",
            node_uuid
        );
    }

    #[test]
    fn entry_schedule_routes_atom_ref_to_calendar_designated_folder() {
        let _guard = acquire_test_db_lock();

        let created = entry_schedule_impl(
            "entry event".to_string(),
            1_700_000_000_000,
            Some(1_700_003_600_000),
        );
        assert!(created.ok, "{}", created.message);
        let node_uuid = created
            .node_uuid
            .expect("entry_schedule should return node_uuid");
        let calendar_folder_id = designated_folder_node_id("calendar");

        let calendar_children = workspace_list_children_impl(Some(calendar_folder_id));
        assert!(calendar_children.ok, "{}", calendar_children.message);
        let found = calendar_children
            .items
            .iter()
            .any(|n| n.node_id == node_uuid);
        assert!(
            found,
            "atom_ref from entry_schedule must appear under calendar designated folder; node_uuid={}",
            node_uuid
        );
    }

    #[test]
    fn calendar_list_returns_s8_fields_for_event() {
        let _guard = acquire_test_db_lock();
        let start = 1_700_000_000_000_i64;
        let end = 1_700_003_600_000_i64;
        let scheduled = entry_schedule_impl("s8 event".to_string(), start, Some(end));
        assert!(scheduled.ok, "{}", scheduled.message);

        let list = calendar_list_by_range_impl(start, end, Some(50), Some(0));
        assert!(list.ok, "{}", list.message);

        let event = list
            .items
            .iter()
            .find(|i| i.content == "s8 event")
            .expect("event must appear in calendar range");
        assert_eq!(event.view_hint, "event", "view_hint must be 'event'");
        assert_eq!(event.start_at, Some(start), "start_at must match");
        assert_eq!(event.end_at, Some(end), "end_at must match");
        assert!(event.task_status.is_none(), "event has no task_status");
    }

    #[test]
    fn tasks_list_inbox_keeps_root_scoped_refs_visible_before_pr_0410() {
        let _guard = acquire_test_db_lock();
        create_legacy_root_scoped_atom(ViewHint::Note, "ffi inbox bridge", None, None, None);

        let list = tasks_list_inbox_impl(Some(50), Some(0));
        assert!(list.ok, "{}", list.message);
        assert!(
            list.items
                .iter()
                .any(|item| item.content == "ffi inbox bridge"),
            "root-scoped inbox atom should remain visible through FFI bridge"
        );
    }

    #[test]
    fn tasks_list_today_keeps_root_scoped_refs_visible_before_pr_0410() {
        let _guard = acquire_test_db_lock();
        let start = 11_000_i64;
        let end = 12_000_i64;
        create_legacy_root_scoped_atom(
            ViewHint::Event,
            "ffi today bridge",
            None,
            Some(start),
            Some(end),
        );

        let list = tasks_list_today_impl(9_000, 13_000, Some(50), Some(0));
        assert!(list.ok, "{}", list.message);
        assert!(
            list.items
                .iter()
                .any(|item| item.content == "ffi today bridge"),
            "root-scoped today atom should remain visible through FFI bridge"
        );
    }

    #[test]
    fn tasks_list_upcoming_keeps_root_scoped_refs_visible_before_pr_0410() {
        let _guard = acquire_test_db_lock();
        let start = 20_000_i64;
        let end = 22_000_i64;
        create_legacy_root_scoped_atom(
            ViewHint::Event,
            "ffi upcoming bridge",
            None,
            Some(start),
            Some(end),
        );

        let list = tasks_list_upcoming_impl(13_000, Some(50), Some(0));
        assert!(list.ok, "{}", list.message);
        assert!(
            list.items
                .iter()
                .any(|item| item.content == "ffi upcoming bridge"),
            "root-scoped upcoming atom should remain visible through FFI bridge"
        );
    }

    #[test]
    fn note_update_uses_full_replace_and_updates_preview() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("first body".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created
            .item
            .as_ref()
            .expect("created note payload")
            .atom_id
            .clone();

        let updated = note_update_impl(atom_id, "second body ![](two.png)".to_string());
        assert!(updated.ok, "{}", updated.message);
        assert_eq!(
            updated
                .item
                .as_ref()
                .and_then(|n| n.preview_image.as_deref()),
            Some("two.png")
        );
    }

    #[test]
    fn notes_list_caps_limit_and_filters_single_tag() {
        let _guard = acquire_test_db_lock();
        let first = note_create_impl("work note".to_string(), None);
        assert!(first.ok, "{}", first.message);
        let first_id = first.item.as_ref().expect("first note").atom_id.clone();
        let second = note_create_impl("other note".to_string(), None);
        assert!(second.ok, "{}", second.message);
        let second_id = second.item.as_ref().expect("second note").atom_id.clone();

        let tag_set = note_set_tags_impl(
            first_id.clone(),
            vec![
                "Work".to_string(),
                "work".to_string(),
                "Important".to_string(),
            ],
        );
        assert!(tag_set.ok, "{}", tag_set.message);

        let filtered = notes_list_impl(Some("work".to_string()), Some(200), Some(0));
        assert!(filtered.ok, "{}", filtered.message);
        assert_eq!(filtered.applied_limit, 50);
        assert!(filtered.items.iter().any(|item| item.atom_id == first_id));
        assert!(!filtered.items.iter().any(|item| item.atom_id == second_id));
    }

    #[test]
    fn notes_list_rejects_blank_tag_with_invalid_tag_error_code() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("blank tag filter source".to_string(), None);
        assert!(created.ok, "{}", created.message);

        let response = notes_list_impl(Some("   ".to_string()), Some(20), Some(0));
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("invalid_tag"));
    }

    #[test]
    fn note_set_tags_normalizes_values_and_refreshes_updated_at() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("tag update target".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created
            .item
            .as_ref()
            .expect("created note payload")
            .atom_id
            .clone();

        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        conn.execute(
            "UPDATE atoms SET updated_at = 1000 WHERE uuid = ?1;",
            [atom_id.as_str()],
        )
        .expect("set old updated_at");

        let tagged = note_set_tags_impl(
            atom_id,
            vec![
                "Work".to_string(),
                "work".to_string(),
                "Important".to_string(),
            ],
        );
        assert!(tagged.ok, "{}", tagged.message);
        let note = tagged.item.expect("note payload should exist");
        assert_eq!(note.tags, vec!["important".to_string(), "work".to_string()]);
        assert!(note.updated_at > 1000);
    }

    #[test]
    fn note_get_invalid_id_returns_error_code() {
        let _guard = acquire_test_db_lock();
        let response = note_get_impl("not-a-uuid".to_string());
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("invalid_note_id"));
    }

    #[test]
    fn invalid_persisted_data_maps_to_internal_error() {
        let mapped = map_repo_error(lazynote_core::RepoError::InvalidData(
            "broken row".to_string(),
        ));
        assert!(matches!(mapped, NotesFfiError::Internal(details) if details == "broken row"));
    }

    #[test]
    fn sqlite_busy_maps_to_db_busy_error_code() {
        let mapped = map_db_error(lazynote_core::db::DbError::Sqlite(
            rusqlite::Error::SqliteFailure(
                rusqlite::ffi::Error::new(rusqlite::ffi::SQLITE_BUSY),
                Some("database is busy".to_string()),
            ),
        ));
        assert!(matches!(mapped, NotesFfiError::DbBusy(_)));
    }

    #[test]
    fn sqlite_locked_maps_to_db_busy_error_code() {
        let mapped = map_db_error(lazynote_core::db::DbError::Sqlite(
            rusqlite::Error::SqliteFailure(
                rusqlite::ffi::Error::new(rusqlite::ffi::SQLITE_LOCKED),
                Some("database is locked".to_string()),
            ),
        ));
        assert!(matches!(mapped, NotesFfiError::DbBusy(_)));
    }

    #[test]
    fn workspace_sqlite_busy_maps_to_db_busy_error_code() {
        let mapped = map_workspace_db_error(lazynote_core::db::DbError::Sqlite(
            rusqlite::Error::SqliteFailure(
                rusqlite::ffi::Error::new(rusqlite::ffi::SQLITE_BUSY),
                Some("database is busy".to_string()),
            ),
        ));
        assert!(matches!(mapped, WorkspaceFfiError::DbBusy(_)));
    }

    #[test]
    fn workspace_sqlite_locked_maps_to_db_busy_error_code() {
        let mapped = map_workspace_db_error(lazynote_core::db::DbError::Sqlite(
            rusqlite::Error::SqliteFailure(
                rusqlite::ffi::Error::new(rusqlite::ffi::SQLITE_LOCKED),
                Some("database is locked".to_string()),
            ),
        ));
        assert!(matches!(mapped, WorkspaceFfiError::DbBusy(_)));
    }

    #[test]
    fn tags_list_returns_normalized_values() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("tag source".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created
            .item
            .as_ref()
            .expect("created note payload")
            .atom_id
            .clone();
        let tagged = note_set_tags_impl(atom_id, vec!["Work".to_string(), "HOME".to_string()]);
        assert!(tagged.ok, "{}", tagged.message);

        let tags = tags_list_impl();
        assert!(tags.ok, "{}", tags.message);
        assert!(tags.tags.contains(&"work".to_string()));
        assert!(tags.tags.contains(&"home".to_string()));
    }

    fn create_workspace_folder(name: &str) -> String {
        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        let repo = SqliteTreeRepository::try_new(&conn).expect("init tree repo");
        let service = TreeService::new(repo);
        service
            .create_folder(None, name.to_string())
            .expect("create workspace folder")
            .node_uuid
            .to_string()
    }

    fn default_workspace_node_id() -> String {
        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        conn.query_row(
            "SELECT workspace_id
             FROM workspaces
             WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .expect("default workspace id")
    }

    fn designated_folder_node_id(role: &str) -> String {
        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        conn.query_row(
            "SELECT node_uuid
             FROM designated_folders
             WHERE workspace_id = (
                 SELECT workspace_id
                 FROM workspaces
                 WHERE is_default = 1
             )
               AND role = ?1;",
            [role],
            |row| row.get(0),
        )
        .expect("designated folder id")
    }

    fn insert_workspace_root_for_test(name: &str) -> String {
        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        let workspace_id = Uuid::new_v4();
        conn.execute(
            "INSERT INTO workspace_nodes (
                node_uuid, kind, parent_uuid, atom_uuid, display_name, sort_order, is_deleted
             ) VALUES (?1, 'workspace', NULL, NULL, ?2, 10, 0);",
            rusqlite::params![workspace_id.to_string(), name],
        )
        .expect("insert workspace root");
        conn.execute(
            "INSERT INTO workspaces (workspace_id, name, is_default)
             VALUES (?1, ?2, 0);",
            rusqlite::params![workspace_id.to_string(), name],
        )
        .expect("insert workspace metadata");
        workspace_id.to_string()
    }

    fn default_caller() -> FfiCallerContext {
        FfiCallerContext {
            identity: FfiCallerIdentity::App,
            scope_workspace_id: Some(default_workspace_node_id()),
        }
    }

    fn base_query(folder_id: String) -> FfiScopedAtomQuery {
        FfiScopedAtomQuery {
            folder_id,
            view_hint: None,
            time_filter: FfiTimeFilterKind::Any,
            time_start_ms: None,
            time_end_ms: None,
            time_shape: FfiTimeShapeFilter::Any,
            status_filter: FfiStatusFilterKind::Any,
            task_statuses: None,
            tag: None,
            text_query: None,
            include_path: false,
            include_overdue_deadlines: false,
            sort: FfiSortSpec::UpdatedAtDesc,
            limit: 50,
            offset: 0,
        }
    }

    fn create_task_request(content: &str) -> FfiCreateAtomRequest {
        FfiCreateAtomRequest {
            workspace_id: default_workspace_node_id(),
            content: content.to_string(),
            content_type: "markdown".to_string(),
            task_status: Some(FfiTaskStatus::Todo),
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: None,
            display_name: None,
        }
    }

    fn create_legacy_root_scoped_atom(
        view_hint: ViewHint,
        content: &str,
        task_status: Option<TaskStatus>,
        start_at: Option<i64>,
        end_at: Option<i64>,
    ) -> String {
        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        let mut atom = Atom::new(view_hint, content.to_string());
        atom.title = content.to_string();
        atom.task_status = task_status;
        atom.start_at = start_at;
        atom.end_at = end_at;

        let atom_repo = SqliteAtomRepository::try_new(&conn).expect("atom repo");
        atom_repo
            .create_atom(&atom)
            .expect("legacy root atom create");

        let tree_repo = SqliteTreeRepository::try_new(&conn).expect("tree repo");
        TreeService::new(tree_repo)
            .create_atom_ref(None, atom.uuid, Some(content.to_string()))
            .expect("legacy root atom_ref");
        atom.uuid.to_string()
    }

    fn create_workspace_atom_ref_node() -> String {
        let response = note_create_impl("workspace note".to_string(), None);
        assert!(response.ok, "{}", response.message);
        response.node_uuid.expect("node_uuid from note_create")
    }

    fn create_workspace_folder_via_ffi(name: &str) -> String {
        let response = workspace_create_folder_impl(None, name.to_string());
        assert!(response.ok, "{}", response.message);
        response
            .node
            .expect("workspace node payload")
            .node_id
            .to_string()
    }

    #[test]
    fn query_atoms_returns_scoped_items() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("guarded-query");
        let created = note_create_impl(format!("# {token}"), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let mut descriptor = base_query(default_workspace_node_id());
        descriptor.text_query = Some(token);
        let response = query_atoms_impl(default_caller(), descriptor, FfiProjectionMode::Atom);
        assert!(response.ok, "{}", response.message);
        assert!(response.items.iter().any(|item| item.uuid == atom_id));
    }

    #[test]
    fn atom_create_routes_task_to_designated_folder() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("guarded-create");
        let tasks_folder = designated_folder_node_id("tasks");

        let response = atom_create_impl(default_caller(), create_task_request(&token));
        assert!(response.ok, "{}", response.message);
        let node_uuid = response.node_uuid.expect("node uuid");
        let atom_uuid = response.atom_uuid.expect("atom uuid");

        let children = workspace_list_children_impl(Some(tasks_folder));
        assert!(children.ok, "{}", children.message);
        assert!(children.items.iter().any(|item| item.node_id == node_uuid));

        let loaded = atom_get_impl(atom_uuid);
        assert!(loaded.ok, "{}", loaded.message);
        assert_eq!(
            loaded
                .item
                .as_ref()
                .and_then(|item| item.task_status.as_deref()),
            Some("todo")
        );
    }

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
                allowed_workspace: Uuid::parse_str(&default_workspace)
                    .expect("default workspace uuid"),
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
    fn ffi_query_atoms_maps_cross_workspace_deny_guard_error_code() {
        let _guard = acquire_test_db_lock();
        let response = query_atoms_impl_with_guard(
            FfiCallerContext {
                identity: FfiCallerIdentity::App,
                scope_workspace_id: Some(Uuid::new_v4().to_string()),
            },
            base_query(default_workspace_node_id()),
            FfiProjectionMode::Atom,
            Box::new(CrossWorkspaceDenyGuard),
        );
        assert!(!response.ok, "expected deny guard to fail query_atoms");
        assert_eq!(
            response.error_code.as_deref(),
            Some("cross_workspace_access_denied")
        );
    }

    #[test]
    fn ffi_atom_create_maps_insufficient_capability_guard_error_code() {
        let _guard = acquire_test_db_lock();
        let response = atom_create_impl_with_guard(
            default_caller(),
            create_task_request("guard-write-denied"),
            Box::new(CapabilityDenyGuard),
        );
        assert!(!response.ok, "expected deny guard to fail atom_create");
        assert_eq!(
            response.error_code.as_deref(),
            Some("insufficient_capability")
        );
    }

    #[test]
    fn legacy_wrapper_tasks_list_inbox_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("legacy-inbox");
        let created = entry_create_note_impl(token.clone());
        assert!(created.ok, "{}", created.message);
        let atom_id = created.atom_id.expect("atom id");

        let response = tasks_list_inbox_impl(Some(50), Some(0));
        assert!(response.ok, "{}", response.message);
        assert!(response.items.iter().any(|item| item.atom_id == atom_id));
        assert_eq!(response.error_code, None);
    }

    #[test]
    fn legacy_wrapper_tasks_list_today_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = entry_schedule_impl(unique_token("legacy-today"), 10_000, Some(12_000));
        assert!(response.ok, "{}", response.message);
        let atom_id = response.atom_id.expect("atom id");

        let listed = tasks_list_today_impl(9_000, 13_000, Some(50), Some(0));
        assert!(listed.ok, "{}", listed.message);
        assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
    }

    #[test]
    fn legacy_wrapper_tasks_list_upcoming_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = entry_schedule_impl(unique_token("legacy-upcoming"), 20_000, Some(21_000));
        assert!(response.ok, "{}", response.message);
        let atom_id = response.atom_id.expect("atom id");

        let listed = tasks_list_upcoming_impl(15_000, Some(50), Some(0));
        assert!(listed.ok, "{}", listed.message);
        assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
    }

    #[test]
    fn legacy_wrapper_calendar_list_by_range_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = entry_schedule_impl(unique_token("legacy-cal"), 30_000, Some(32_000));
        assert!(response.ok, "{}", response.message);
        let atom_id = response.atom_id.expect("atom id");

        let listed = calendar_list_by_range_impl(29_000, 33_000, Some(50), Some(0));
        assert!(listed.ok, "{}", listed.message);
        assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
    }

    #[test]
    fn legacy_wrapper_notes_list_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("legacy-notes");
        let created = note_create_impl(token.clone(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let listed = notes_list_impl(None, Some(50), Some(0));
        assert!(listed.ok, "{}", listed.message);
        assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
    }

    #[test]
    fn legacy_wrapper_notes_list_preserves_tags() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("legacy-notes-tags");
        let created = note_create_impl(token.clone(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let tagged = note_set_tags_impl(
            atom_id.clone(),
            vec!["alpha".to_string(), "beta".to_string()],
        );
        assert!(tagged.ok, "{}", tagged.message);

        let listed = notes_list_impl(None, Some(50), Some(0));
        assert!(listed.ok, "{}", listed.message);
        let listed_item = listed
            .items
            .iter()
            .find(|item| item.atom_id == atom_id)
            .expect("listed note");
        assert_eq!(
            listed_item.tags,
            vec!["alpha".to_string(), "beta".to_string()]
        );
    }

    #[test]
    fn legacy_wrapper_entry_search_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("legacy-search");
        let created = entry_create_note_impl(token.clone());
        assert!(created.ok, "{}", created.message);
        let atom_id = created.atom_id.expect("atom id");

        let searched = entry_search_impl(token, None, Some(50));
        assert!(searched.ok, "{}", searched.message);
        assert!(searched.items.iter().any(|item| item.atom_id == atom_id));
    }

    #[test]
    fn legacy_wrapper_entry_search_preserves_fts_snippet_and_order() {
        let _guard = acquire_test_db_lock();
        let token = unique_token("legacy-search-fts");
        let strong = format!("strong {token} {token} {token}");
        let weak = format!("weak {token}");

        let created_a = entry_create_note_impl(strong);
        assert!(created_a.ok, "{}", created_a.message);
        let created_b = entry_create_note_impl(weak);
        assert!(created_b.ok, "{}", created_b.message);

        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        let expected_hits = search_all(&conn, &SearchQuery::new(&token)).expect("direct search");
        assert!(expected_hits.len() >= 2, "expected 2 direct hits");

        let searched = entry_search_impl(token, None, Some(50));
        assert!(searched.ok, "{}", searched.message);
        assert!(searched.items.len() >= 2, "expected 2 wrapper hits");

        assert_eq!(
            searched.items[0].atom_id,
            expected_hits[0].atom_id.to_string()
        );
        assert_eq!(searched.items[0].snippet, expected_hits[0].snippet);
    }

    #[test]
    fn legacy_wrapper_atoms_list_timed_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = entry_schedule_impl(unique_token("legacy-timed"), 40_000, Some(41_000));
        assert!(response.ok, "{}", response.message);
        let atom_id = response.atom_id.expect("atom id");

        let listed = super::atoms_list_timed_impl();
        assert!(listed.ok, "{}", listed.message);
        assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
    }

    #[test]
    fn legacy_wrapper_entry_create_note_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = entry_create_note_impl(unique_token("legacy-create-note"));
        assert!(response.ok, "{}", response.message);
        assert!(response.atom_id.is_some());
        assert!(response.node_uuid.is_some());
    }

    #[test]
    fn legacy_wrapper_entry_create_task_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = entry_create_task_impl(unique_token("legacy-create-task"));
        assert!(response.ok, "{}", response.message);
        assert!(response.atom_id.is_some());
        assert!(response.node_uuid.is_some());
    }

    #[test]
    fn legacy_wrapper_entry_schedule_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = entry_schedule_impl(unique_token("legacy-schedule"), 50_000, Some(51_000));
        assert!(response.ok, "{}", response.message);
        assert!(response.atom_id.is_some());
        assert!(response.node_uuid.is_some());
    }

    #[test]
    fn legacy_wrapper_note_create_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let response = note_create_impl(unique_token("legacy-note-create"), None);
        assert!(response.ok, "{}", response.message);
        assert!(response.item.is_some());
        assert!(response.node_uuid.is_some());
    }

    #[test]
    fn legacy_wrapper_note_update_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("legacy update seed".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let updated = note_update_impl(atom_id, "legacy update body".to_string());
        assert!(updated.ok, "{}", updated.message);
        assert!(updated
            .item
            .as_ref()
            .expect("updated payload")
            .content
            .contains("legacy update body"));
    }

    #[test]
    fn legacy_wrapper_note_set_tags_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("legacy tags seed".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let tagged = note_set_tags_impl(atom_id, vec!["Alpha".to_string(), "Beta".to_string()]);
        assert!(tagged.ok, "{}", tagged.message);
        assert_eq!(
            tagged.item.as_ref().expect("tagged payload").tags,
            vec!["alpha".to_string(), "beta".to_string()]
        );
    }

    #[test]
    fn legacy_wrapper_calendar_update_event_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let created =
            entry_schedule_impl(unique_token("legacy-update-event"), 60_000, Some(61_000));
        assert!(created.ok, "{}", created.message);
        let atom_id = created.atom_id.expect("atom id");

        let updated = calendar_update_event_impl(atom_id.clone(), 62_000, 63_000);
        assert!(updated.ok, "{}", updated.message);
        assert_eq!(updated.atom_id.as_deref(), Some(atom_id.as_str()));
    }

    #[test]
    fn legacy_wrapper_note_get_preserves_contract() {
        let _guard = acquire_test_db_lock();
        let created = note_create_impl("legacy get seed".to_string(), None);
        assert!(created.ok, "{}", created.message);
        let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

        let loaded = note_get_impl(atom_id.clone());
        assert!(loaded.ok, "{}", loaded.message);
        assert_eq!(
            loaded.item.as_ref().expect("loaded payload").atom_id,
            atom_id
        );
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
        let response = workspace_create_folder_impl(
            Some("not-a-uuid".to_string()),
            "invalid parent".to_string(),
        );
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
        let response =
            workspace_create_folder_impl(Some(missing_parent), "child-folder".to_string());
        assert!(!response.ok);
        assert_eq!(response.error_code.as_deref(), Some("parent_not_found"));
    }

    #[test]
    fn workspace_create_folder_maps_parent_not_folder_error_code() {
        let _guard = acquire_test_db_lock();
        let parent_atom_ref = create_workspace_atom_ref_node();
        let response =
            workspace_create_folder_impl(Some(parent_atom_ref), "child-folder".to_string());
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
        let conn = open_db(super::resolve_entry_db_path()).unwrap();
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

        let verify_conn = open_db(super::resolve_entry_db_path()).unwrap();
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
        let response =
            workspace_delete_folder_impl("not-a-uuid".to_string(), "dissolve".to_string());
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

        let dissolve_response =
            workspace_delete_folder_impl(dissolve_folder, "dissolve".to_string());
        assert!(dissolve_response.ok, "{}", dissolve_response.message);
        assert!(dissolve_response.error_code.is_none());

        let delete_all_response =
            workspace_delete_folder_impl(delete_all_folder, "delete_all".to_string());
        assert!(delete_all_response.ok, "{}", delete_all_response.message);
        assert!(delete_all_response.error_code.is_none());
    }

    // -----------------------------------------------------------------------
    // Calendar API tests (PR-0012A)
    // -----------------------------------------------------------------------

    /// Helper: creates an event atom with given start/end times via entry_schedule.
    fn create_test_event(title: &str, start_ms: i64, end_ms: i64) -> String {
        let resp = entry_schedule_impl(title.to_string(), start_ms, Some(end_ms));
        assert!(resp.ok, "create_test_event failed: {}", resp.message);
        resp.atom_id.expect("event should return atom_id")
    }

    #[test]
    fn calendar_list_by_range_returns_overlapping_events() {
        let _guard = acquire_test_db_lock();
        // Event: 10:00–12:00 (10_000–12_000)
        let inside_id = create_test_event("overlap", 10_000, 12_000);
        // Event: 20:00–22:00 (20_000–22_000) — outside range
        let _outside_id = create_test_event("outside", 20_000, 22_000);

        // Query range: 9:00–13:00 (9_000–13_000)
        let resp = calendar_list_by_range_impl(9_000, 13_000, None, None);
        assert!(resp.ok, "{}", resp.message);
        assert!(
            resp.items.iter().any(|i| i.atom_id == inside_id),
            "overlapping event should be in results"
        );
        assert!(
            !resp.items.iter().any(|i| i.atom_id == _outside_id),
            "non-overlapping event should not be in results"
        );
    }

    #[test]
    fn calendar_list_by_range_includes_done_events() {
        let _guard = acquire_test_db_lock();
        let event_id = create_test_event("done-cal", 30_000, 32_000);

        // Mark as done
        let status_resp =
            super::atom_update_status_impl(event_id.clone(), Some("done".to_string()));
        assert!(status_resp.ok, "{}", status_resp.message);

        // Query should still include it
        let resp = calendar_list_by_range_impl(29_000, 33_000, None, None);
        assert!(resp.ok, "{}", resp.message);
        assert!(
            resp.items.iter().any(|i| i.atom_id == event_id),
            "done event should appear in calendar range query"
        );
    }

    #[test]
    fn calendar_update_event_validates_time_range() {
        let _guard = acquire_test_db_lock();
        let event_id = create_test_event("validate-range", 40_000, 42_000);

        // end < start should fail
        let resp = calendar_update_event_impl(event_id, 42_000, 40_000);
        assert!(!resp.ok);
        assert!(
            resp.message.contains("invalid time range"),
            "should contain error message, got: {}",
            resp.message
        );
    }

    #[test]
    fn calendar_update_event_not_found() {
        let _guard = acquire_test_db_lock();
        let fake_id = uuid::Uuid::new_v4().to_string();
        let resp = calendar_update_event_impl(fake_id, 50_000, 52_000);
        assert!(!resp.ok);
        assert!(
            resp.message.contains("not found"),
            "should contain not found, got: {}",
            resp.message
        );
    }

    #[test]
    fn calendar_update_event_success() {
        let _guard = acquire_test_db_lock();
        let event_id = create_test_event("update-times", 60_000, 62_000);

        // Read original updated_at
        let conn = open_db(super::resolve_entry_db_path()).expect("open db");
        let original_updated_at: i64 = conn
            .query_row(
                "SELECT updated_at FROM atoms WHERE uuid = ?1",
                [event_id.as_str()],
                |row| row.get(0),
            )
            .expect("read updated_at");

        // Update times
        let resp = calendar_update_event_impl(event_id.clone(), 70_000, 75_000);
        assert!(resp.ok, "{}", resp.message);
        assert_eq!(resp.atom_id.as_deref(), Some(event_id.as_str()));

        // Verify times changed
        let (start, end, new_updated_at): (Option<i64>, Option<i64>, i64) = conn
            .query_row(
                "SELECT start_at, end_at, updated_at FROM atoms WHERE uuid = ?1",
                [event_id.as_str()],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
            )
            .expect("read updated event");
        assert_eq!(start, Some(70_000));
        assert_eq!(end, Some(75_000));
        assert!(
            new_updated_at >= original_updated_at,
            "updated_at should advance"
        );
    }

    fn unique_token(prefix: &str) -> String {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("time went backwards")
            .as_nanos();
        format!("{prefix}-{nanos}")
    }

    fn function_source(signature: &str) -> &'static str {
        let source = include_str!("api.rs");
        let start = source
            .find(signature)
            .unwrap_or_else(|| panic!("signature `{signature}` not found"));
        let tail = &source[start..];

        let body_start = tail
            .find('{')
            .unwrap_or_else(|| panic!("function `{signature}` has no body"));
        let mut depth = 0usize;
        for (index, ch) in tail[body_start..].char_indices() {
            match ch {
                '{' => depth += 1,
                '}' => {
                    depth -= 1;
                    if depth == 0 {
                        return &tail[..body_start + index + 1];
                    }
                }
                _ => {}
            }
        }

        panic!("function `{signature}` body did not terminate");
    }

    fn assert_thin_wrapper(signature: &str, delegate_call: &str, forbidden: &[&str]) {
        let source = function_source(signature);
        assert!(
            source.contains(delegate_call),
            "expected `{signature}` to delegate via `{delegate_call}`"
        );
        for forbidden_call in forbidden {
            assert!(
                !source.contains(forbidden_call),
                "expected `{signature}` to drop legacy helper `{forbidden_call}`"
            );
        }
    }

    #[test]
    fn legacy_wrapper_bodies_delegate_to_approved_surfaces() {
        assert_thin_wrapper(
            "fn entry_create_note_impl",
            "atom_create_impl(",
            &["with_creation_service("],
        );
        assert_thin_wrapper(
            "fn entry_create_task_impl",
            "atom_create_impl(",
            &["with_creation_service("],
        );
        assert_thin_wrapper(
            "fn entry_schedule_impl",
            "atom_create_impl(",
            &["with_creation_service("],
        );
        assert_thin_wrapper(
            "fn note_create_impl",
            "atom_create_impl(",
            &["with_creation_service("],
        );
        assert_thin_wrapper(
            "fn note_update_impl",
            "with_guarded_atom_service(",
            &["with_note_service("],
        );
        assert_thin_wrapper(
            "fn note_get_impl",
            "with_guarded_atom_service(",
            &["with_note_service("],
        );
        assert_thin_wrapper(
            "fn note_set_tags_impl",
            "with_guarded_atom_service(",
            &["with_note_service("],
        );
        assert_thin_wrapper(
            "fn calendar_update_event_impl",
            "with_guarded_atom_service(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn atom_update_status_impl",
            "with_guarded_task_service(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn atom_get_impl",
            "with_guarded_atom_service(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn tasks_list_inbox_impl",
            "query_atoms_impl(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn tasks_list_today_impl",
            "query_atoms_impl(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn tasks_list_upcoming_impl",
            "query_atoms_impl(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn atoms_list_timed_impl",
            "query_atoms_impl(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn calendar_list_by_range_impl",
            "query_atoms_impl(",
            &["with_task_service("],
        );
        assert_thin_wrapper(
            "fn notes_list_impl",
            "query_atoms_impl(",
            &["with_note_service("],
        );
        assert_thin_wrapper(
            "fn entry_search_impl",
            "legacy_entry_search_via_fts(",
            &["search_all(", "open_db("],
        );
    }
}
