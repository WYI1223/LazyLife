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

mod calendar;
mod creation;
mod entry;
mod errors;
mod mappers;
mod notes;
mod query;
mod support;
mod tasks;
mod workspace;

pub use self::calendar::{calendar_list_by_range, calendar_update_event};
pub use self::creation::atom_create;
pub use self::entry::{entry_create_note, entry_create_task, entry_schedule, entry_search};
use self::errors::*;
use self::mappers::*;
pub use self::notes::{note_create, note_get, note_set_tags, note_update, notes_list, tags_list};
pub use self::query::query_atoms;
use self::support::*;
pub use self::tasks::{
    atom_get, atom_update_status, atoms_list_timed, tasks_list_inbox, tasks_list_today,
    tasks_list_upcoming,
};
use self::workspace::{map_tree_repo_error, map_tree_service_error, map_workspace_db_error};
pub use self::workspace::{
    workspace_ancestor_path, workspace_create_atom_ref, workspace_create_folder,
    workspace_delete_folder, workspace_get_ancestor_path, workspace_get_default, workspace_list,
    workspace_list_atom_refs_for_atom, workspace_list_children, workspace_move_node,
    workspace_reassign_designated, workspace_rename_node, workspace_resolve_designated,
};

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

fn parse_note_id(raw: &str) -> Result<AtomId, NotesFfiError> {
    Uuid::parse_str(raw.trim()).map_err(|_| NotesFfiError::InvalidNoteId(raw.to_string()))
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

fn view_hint_label(hint: ViewHint) -> &'static str {
    match hint {
        ViewHint::Note => "note",
        ViewHint::Task => "task",
        ViewHint::Event => "event",
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

fn normalize_entry_limit(limit: Option<u32>) -> u32 {
    match limit {
        Some(0) => ENTRY_DEFAULT_LIMIT,
        Some(value) if value > ENTRY_SEARCH_MAX_LIMIT => ENTRY_SEARCH_MAX_LIMIT,
        Some(value) => value,
        None => ENTRY_DEFAULT_LIMIT,
    }
}

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
        task_status: sa.atom.task_status.map(|status| {
            match status {
                TaskStatus::Todo => "todo",
                TaskStatus::InProgress => "in_progress",
                TaskStatus::Done => "done",
                TaskStatus::Cancelled => "cancelled",
            }
            .to_string()
        }),
        updated_at: sa.updated_at,
    }
}

/// Converts a `NoteRecord` into `AtomListItem`.
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

fn atom_list_failure(err: AtomFfiError, limit: u32) -> AtomListResponse {
    AtomListResponse {
        ok: false,
        error_code: Some(err.code().to_string()),
        message: err.message(),
        items: Vec::new(),
        applied_limit: limit,
    }
}

#[cfg(test)]
mod test_support;
#[cfg(test)]
mod tests;
