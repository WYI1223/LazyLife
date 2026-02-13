//! FFI use-case API for Flutter-facing calls.
//!
//! # Responsibility
//! - Expose stable, use-case-level functions to Dart via FRB.
//! - Keep error semantics simple for early-stage UI integration.
//!
//! # Invariants
//! - Exported functions must not panic across FFI boundary.
//! - Return values are UTF-8 strings with stable meaning.
//!
//! # See also
//! - docs/architecture/logging.md

use lazynote_core::{
    core_version as core_version_inner, init_logging as init_logging_inner, ping as ping_inner,
};

const ENTRY_DEFAULT_LIMIT: u32 = 10;
const ENTRY_LIMIT_MAX: u32 = 10;

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

/// Search item returned by single-entry search API.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EntrySearchItem {
    /// Stable atom ID in string form.
    pub atom_id: String,
    /// Atom projection kind (`note|task|event`).
    pub kind: String,
    /// Short snippet summary for result display.
    pub snippet: String,
}

/// Search response envelope for single-entry search flow.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EntrySearchResponse {
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
    /// Human-readable response message for diagnostics/UI.
    pub message: String,
}

impl EntryActionResponse {
    fn scaffold_not_ready(action: &str) -> Self {
        Self {
            ok: false,
            atom_id: None,
            message: format!(
                "{action} is scaffolded in PR-0009A phase 1; execution wiring lands in phase 2"
            ),
        }
    }
}

/// Searches single-entry text using entry-level defaults.
///
/// # FFI contract
/// - Sync call, currently non-blocking scaffold behavior.
/// - Never panics.
/// - Returns deterministic envelope with applied limit.
#[flutter_rust_bridge::frb(sync)]
pub fn entry_search(text: String, limit: Option<u32>) -> EntrySearchResponse {
    let normalized_limit = normalize_entry_limit(limit);
    let query_len = text.trim().chars().count();
    EntrySearchResponse {
        items: Vec::new(),
        message: format!(
            "entry_search scaffold ready (query_len={query_len}, limit={normalized_limit})"
        ),
        applied_limit: normalized_limit,
    }
}

/// Creates a note from single-entry command flow.
///
/// # FFI contract
/// - Sync call, phase-1 scaffold.
/// - Never panics.
/// - Returns explicit not-ready response until phase-2 execution wiring.
#[flutter_rust_bridge::frb(sync)]
pub fn entry_create_note(_content: String) -> EntryActionResponse {
    EntryActionResponse::scaffold_not_ready("entry_create_note")
}

/// Creates a task from single-entry command flow.
///
/// # FFI contract
/// - Sync call, phase-1 scaffold.
/// - Never panics.
/// - Returns explicit not-ready response until phase-2 execution wiring.
#[flutter_rust_bridge::frb(sync)]
pub fn entry_create_task(_content: String) -> EntryActionResponse {
    EntryActionResponse::scaffold_not_ready("entry_create_task")
}

/// Schedules an event from single-entry command flow.
///
/// # FFI contract
/// - Sync call, phase-1 scaffold.
/// - Accepts point (`end_epoch_ms=None`) and range (`Some(end)`) shapes.
/// - Never panics.
/// - Returns explicit not-ready response until phase-2 execution wiring.
#[flutter_rust_bridge::frb(sync)]
pub fn entry_schedule(
    _title: String,
    _start_epoch_ms: i64,
    _end_epoch_ms: Option<i64>,
) -> EntryActionResponse {
    EntryActionResponse::scaffold_not_ready("entry_schedule")
}

fn normalize_entry_limit(limit: Option<u32>) -> u32 {
    match limit {
        Some(0) => ENTRY_DEFAULT_LIMIT,
        Some(value) if value > ENTRY_LIMIT_MAX => ENTRY_LIMIT_MAX,
        Some(value) => value,
        None => ENTRY_DEFAULT_LIMIT,
    }
}

#[cfg(test)]
mod tests {
    use super::{
        core_version, entry_create_note, entry_create_task, entry_schedule, entry_search,
        init_logging, ping,
    };

    #[test]
    fn ping_returns_pong() {
        assert_eq!(ping(), "pong");
    }

    #[test]
    fn version_is_not_empty() {
        assert!(!core_version().is_empty());
    }

    #[test]
    fn init_logging_rejects_empty_log_dir() {
        let error = init_logging("info".to_string(), String::new());
        assert!(!error.is_empty());
    }

    #[test]
    fn init_logging_rejects_unsupported_level() {
        let error = init_logging("verbose".to_string(), "tmp/logs".to_string());
        assert!(!error.is_empty());
    }

    #[test]
    fn entry_search_normalizes_limit_in_phase_one() {
        let response = entry_search("hello world".to_string(), Some(42));
        assert_eq!(response.items.len(), 0);
        assert_eq!(response.applied_limit, 10);
        assert!(response.message.contains("scaffold ready"));
    }

    #[test]
    fn entry_commands_are_explicitly_scaffolded_in_phase_one() {
        let note = entry_create_note("draft".to_string());
        let task = entry_create_task("todo".to_string());
        let schedule = entry_schedule("event".to_string(), 1_000, Some(2_000));

        assert!(!note.ok);
        assert!(!task.ok);
        assert!(!schedule.ok);
        assert!(note.message.contains("phase 1"));
        assert!(task.message.contains("phase 1"));
        assert!(schedule.message.contains("phase 1"));
    }
}
