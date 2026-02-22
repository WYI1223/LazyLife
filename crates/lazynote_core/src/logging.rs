//! Core logging bootstrap and safety policy.
//!
//! # Responsibility
//! - Initialize file-based session logs exactly once per process.
//! - Emit stable, metadata-only diagnostic events from core.
//!
//! # Invariants
//! - Logging init is idempotent for the same directory.
//! - Logging initialization must not panic.
//! - Re-initialization with a different directory is rejected.
//!
//! # See also
//! - docs/architecture/logging.md

use flexi_logger::{FileSpec, Logger, LoggerHandle, WriteMode};
use log::{error, info, trace, warn};
use once_cell::sync::OnceCell;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};

const LOG_FILE_BASENAME: &str = "lazynote";
const LOG_FILE_SUFFIX: &str = "log";
const LOG_FILE_DISCRIMINANT_PREFIX: &str = "pid";
const LOG_RETENTION_MAX_AGE_DAYS: u64 = 7;
const LOG_RETENTION_MAX_FILES: usize = 20;
const LOG_RETENTION_MAX_TOTAL_BYTES: u64 = 50 * 1024 * 1024;
const MAX_PANIC_PAYLOAD_CHARS: usize = 160;

#[derive(Clone, Copy, Debug)]
struct LogRetentionPolicy {
    max_age_days: u64,
    max_files: usize,
    max_total_bytes: u64,
}

impl Default for LogRetentionPolicy {
    fn default() -> Self {
        Self {
            max_age_days: LOG_RETENTION_MAX_AGE_DAYS,
            max_files: LOG_RETENTION_MAX_FILES,
            max_total_bytes: LOG_RETENTION_MAX_TOTAL_BYTES,
        }
    }
}

#[derive(Debug, Default)]
struct LogRetentionSummary {
    scanned: usize,
    removed: usize,
    retained: usize,
    failed: usize,
    warnings: Vec<String>,
}

#[derive(Clone, Debug)]
struct ManagedLogFile {
    path: PathBuf,
    modified_at: SystemTime,
    size_bytes: u64,
}

static LOGGING_STATE: OnceCell<LoggingState> = OnceCell::new();
static PANIC_HOOK_INSTALLED: OnceCell<()> = OnceCell::new();

struct LoggingState {
    level: &'static str,
    log_dir: PathBuf,
    _logger: LoggerHandle,
}

/// Runtime error variants for `log_dart_event`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LogDartEventError {
    /// Input level is not one of supported values.
    InvalidLevel(String),
    /// Logging bootstrap has not been initialized in current process.
    LoggingNotInitialized,
}

/// Initializes core logging with level and directory.
///
/// Returns `Ok(())` when logging is active, or a human-readable error string
/// when initialization fails.
///
/// # Invariants
/// - Calling this function repeatedly with the same `log_dir` is idempotent.
/// - Calling this function repeatedly with a different `level` is rejected.
/// - Re-initialization with a different `log_dir` is rejected.
/// - Initialization never panics.
///
/// # Errors
/// - Returns an error when `level` is unsupported.
/// - Returns an error when `log_dir` is empty, non-absolute, or cannot be created.
/// - Returns an error when logger backend setup fails.
pub fn init_logging(level: &str, log_dir: &str) -> Result<(), String> {
    let normalized_level = normalize_level(level)?;
    let normalized_dir = normalize_log_dir(log_dir)?;

    if let Some(state) = LOGGING_STATE.get() {
        if state.log_dir == normalized_dir {
            if state.level != normalized_level {
                return Err(format!(
                    "logging already initialized with level `{}`; refusing to switch to `{}`",
                    state.level, normalized_level
                ));
            }
            return Ok(());
        }
        return Err(format!(
            "logging already initialized at `{}`; refusing to switch to `{}`",
            state.log_dir.display(),
            normalized_dir.display()
        ));
    }

    let init_level = normalized_level;
    let init_dir = normalized_dir.clone();

    let state = LOGGING_STATE.get_or_try_init(|| -> Result<LoggingState, String> {
        std::fs::create_dir_all(&init_dir).map_err(|err| {
            format!(
                "failed to create log directory `{}`: {err}",
                init_dir.display()
            )
        })?;

        let retention_policy = LogRetentionPolicy::default();
        let retention_summary =
            cleanup_managed_logs_best_effort(&init_dir, retention_policy, SystemTime::now());

        let logger = Logger::try_with_str(init_level)
            .map_err(|err| format!("invalid log level `{init_level}`: {err}"))?
            .log_to_file(build_session_file_spec(&init_dir))
            .write_mode(WriteMode::BufferAndFlush)
            // Why: detailed_format adds timestamp + source location, enabling the
            // diagnostics viewer to parse and display a structured timestamp column.
            // Format: [YYYY-MM-DD HH:MM:SS.ffffff TZ] LEVEL [module] file:line: message
            .format_for_files(flexi_logger::detailed_format)
            .start()
            .map_err(|err| format!("failed to start logger: {err}"))?;

        install_panic_hook_once();

        info!(
            "event=app_start module=core status=ok platform={} build_mode={} version={}",
            std::env::consts::OS,
            build_mode(),
            env!("CARGO_PKG_VERSION")
        );
        info!(
            "event=core_init module=core status=ok level={} log_dir={}",
            init_level,
            init_dir.display()
        );
        if retention_summary.failed > 0 {
            warn!(
                "event=log_retention_cleanup module=core status=degraded scanned={} removed={} retained={} failed={} max_age_days={} max_files={} max_total_bytes={}",
                retention_summary.scanned,
                retention_summary.removed,
                retention_summary.retained,
                retention_summary.failed,
                retention_policy.max_age_days,
                retention_policy.max_files,
                retention_policy.max_total_bytes
            );
            for warning in retention_summary.warnings.iter().take(5) {
                warn!("event=log_retention_cleanup_warning module=core detail={}", warning);
            }
        } else {
            info!(
                "event=log_retention_cleanup module=core status=ok scanned={} removed={} retained={} max_age_days={} max_files={} max_total_bytes={}",
                retention_summary.scanned,
                retention_summary.removed,
                retention_summary.retained,
                retention_policy.max_age_days,
                retention_policy.max_files,
                retention_policy.max_total_bytes
            );
        }

        Ok(LoggingState {
            level: init_level,
            log_dir: init_dir,
            _logger: logger,
        })
    })?;

    if state.log_dir != normalized_dir {
        return Err(format!(
            "logging already initialized at `{}`; refusing to switch to `{}`",
            state.log_dir.display(),
            normalized_dir.display()
        ));
    }
    if state.level != normalized_level {
        return Err(format!(
            "logging already initialized with level `{}`; refusing to switch to `{}`",
            state.level, normalized_level
        ));
    }

    Ok(())
}

/// Emits one structured Dart-side diagnostics event into the active session log.
///
/// # Invariants
/// - Requires logging initialization in current process.
/// - Never panics.
pub fn log_dart_event(
    level: &str,
    event_name: &str,
    module: &str,
    message: &str,
) -> Result<(), LogDartEventError> {
    let normalized_level =
        normalize_level(level).map_err(|_| LogDartEventError::InvalidLevel(level.to_string()))?;
    let state = LOGGING_STATE
        .get()
        .ok_or(LogDartEventError::LoggingNotInitialized)?;

    let normalized_event_name = sanitize_inline_field(event_name);
    let normalized_module = sanitize_inline_field(module);
    let normalized_message = sanitize_inline_field(message);

    match normalized_level {
        "trace" => trace!(
            "event=dart_event module=dart event_name={} dart_module={} message={}",
            normalized_event_name,
            normalized_module,
            normalized_message
        ),
        "debug" => log::debug!(
            "event=dart_event module=dart event_name={} dart_module={} message={}",
            normalized_event_name,
            normalized_module,
            normalized_message
        ),
        "info" => info!(
            "event=dart_event module=dart event_name={} dart_module={} message={}",
            normalized_event_name, normalized_module, normalized_message
        ),
        "warn" => warn!(
            "event=dart_event module=dart event_name={} dart_module={} message={}",
            normalized_event_name, normalized_module, normalized_message
        ),
        "error" => error!(
            "event=dart_event module=dart event_name={} dart_module={} message={}",
            normalized_event_name, normalized_module, normalized_message
        ),
        _ => {
            return Err(LogDartEventError::InvalidLevel(level.to_string()));
        }
    }

    // Keep sync bridge behavior deterministic for diagnostics timeline reads.
    state._logger.flush();
    Ok(())
}

/// Returns active logging status metadata.
///
/// Returns `None` when logging has not been initialized.
/// Returns `(level, log_dir)` when logging is active.
pub fn logging_status() -> Option<(&'static str, PathBuf)> {
    LOGGING_STATE
        .get()
        .map(|state| (state.level, state.log_dir.clone()))
}

/// Returns the default log level for current build mode.
///
/// - `debug` builds -> `debug`
/// - `release` builds -> `info`
pub fn default_log_level() -> &'static str {
    if cfg!(debug_assertions) {
        "debug"
    } else {
        "info"
    }
}

fn normalize_level(level: &str) -> Result<&'static str, String> {
    match level.trim().to_ascii_lowercase().as_str() {
        "trace" => Ok("trace"),
        "debug" => Ok("debug"),
        "info" => Ok("info"),
        "warn" | "warning" => Ok("warn"),
        "error" => Ok("error"),
        other => Err(format!(
            "unsupported log level `{other}`; expected trace|debug|info|warn|error"
        )),
    }
}

fn normalize_log_dir(log_dir: &str) -> Result<PathBuf, String> {
    let trimmed = log_dir.trim();
    if trimmed.is_empty() {
        return Err("log_dir cannot be empty".to_string());
    }
    let path = Path::new(trimmed);
    if !path.is_absolute() {
        return Err(format!("log_dir must be an absolute path, got `{trimmed}`"));
    }
    Ok(path.to_path_buf())
}

fn build_mode() -> &'static str {
    if cfg!(debug_assertions) {
        "debug"
    } else {
        "release"
    }
}

fn build_session_file_spec(log_dir: &Path) -> FileSpec {
    let pid = std::process::id();
    FileSpec::default()
        .directory(log_dir)
        .basename(LOG_FILE_BASENAME)
        .suffix(LOG_FILE_SUFFIX)
        .discriminant(format!("{LOG_FILE_DISCRIMINANT_PREFIX}{pid}"))
        .use_timestamp(true)
}

fn cleanup_managed_logs_best_effort(
    log_dir: &Path,
    policy: LogRetentionPolicy,
    now: SystemTime,
) -> LogRetentionSummary {
    let mut summary = LogRetentionSummary::default();

    let entries = match std::fs::read_dir(log_dir) {
        Ok(entries) => entries,
        Err(err) => {
            summary.failed += 1;
            summary.warnings.push(format!(
                "failed to list log directory `{}`: {err}",
                log_dir.display()
            ));
            return summary;
        }
    };

    let mut files = Vec::new();
    for entry in entries {
        let entry = match entry {
            Ok(value) => value,
            Err(err) => {
                summary.failed += 1;
                summary
                    .warnings
                    .push(format!("failed to read log entry: {err}"));
                continue;
            }
        };
        let path = entry.path();
        if !is_managed_log_file(&path) {
            continue;
        }

        let metadata = match entry.metadata() {
            Ok(value) => value,
            Err(err) => {
                summary.failed += 1;
                summary.warnings.push(format!(
                    "failed to read metadata for `{}`: {err}",
                    path.display()
                ));
                continue;
            }
        };
        if !metadata.is_file() {
            continue;
        }

        let modified_at = match metadata.modified() {
            Ok(value) => value,
            Err(err) => {
                summary.failed += 1;
                summary.warnings.push(format!(
                    "failed to read modified time for `{}`: {err}",
                    path.display()
                ));
                continue;
            }
        };

        files.push(ManagedLogFile {
            path,
            modified_at,
            size_bytes: metadata.len(),
        });
    }

    summary.scanned = files.len();
    if files.is_empty() {
        return summary;
    }

    let planned_deletions = plan_log_deletions(files, policy, now);
    summary.retained = summary.scanned.saturating_sub(planned_deletions.len());

    for path in planned_deletions {
        match std::fs::remove_file(&path) {
            Ok(()) => {
                summary.removed += 1;
            }
            Err(err) => {
                summary.failed += 1;
                summary.retained += 1;
                summary
                    .warnings
                    .push(format!("failed to remove `{}`: {err}", path.display()));
            }
        }
    }

    summary
}

fn plan_log_deletions(
    mut files: Vec<ManagedLogFile>,
    policy: LogRetentionPolicy,
    now: SystemTime,
) -> Vec<PathBuf> {
    use std::cmp::Ordering;
    use std::collections::BTreeSet;

    files.sort_by(|left, right| {
        let time = right.modified_at.cmp(&left.modified_at);
        if time != Ordering::Equal {
            return time;
        }
        left.path.cmp(&right.path)
    });

    let mut marked = BTreeSet::new();
    let cutoff = now.checked_sub(Duration::from_secs(
        policy.max_age_days.saturating_mul(24 * 60 * 60),
    ));

    let mut retained = Vec::new();
    for file in files {
        let expired = cutoff
            .map(|deadline| file.modified_at <= deadline)
            .unwrap_or(false);
        if expired {
            marked.insert(file.path);
            continue;
        }
        retained.push(file);
    }

    if retained.len() > policy.max_files {
        for file in retained.iter().skip(policy.max_files) {
            marked.insert(file.path.clone());
        }
        retained.truncate(policy.max_files);
    }

    if policy.max_total_bytes > 0 {
        let mut consumed = 0_u64;
        for (index, file) in retained.iter().enumerate() {
            let next = consumed.saturating_add(file.size_bytes);
            // Keep at least the newest session file even when it is oversized.
            if index > 0 && next > policy.max_total_bytes {
                marked.insert(file.path.clone());
                continue;
            }
            consumed = next;
        }
    }

    marked.into_iter().collect()
}

fn is_managed_log_file(path: &Path) -> bool {
    let Some(name) = path.file_name().and_then(|value| value.to_str()) else {
        return false;
    };
    let normalized = name.to_ascii_lowercase();
    normalized.starts_with(LOG_FILE_BASENAME)
        && normalized.ends_with(&format!(".{LOG_FILE_SUFFIX}"))
}

fn install_panic_hook_once() {
    if PANIC_HOOK_INSTALLED.get().is_some() {
        return;
    }

    let previous_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        // Why: panic payload can include user-controlled text; sanitize and cap
        // length before logging to reduce privacy and log-bloat risk.
        let location = panic_info
            .location()
            .map(|loc| format!("{}:{}", loc.file(), loc.line()))
            .unwrap_or_else(|| "unknown".to_string());
        let payload = panic_payload_summary(panic_info);
        error!(
            "event=panic_captured module=core status=error location={} payload={}",
            location, payload
        );
        if let Some(state) = LOGGING_STATE.get() {
            state._logger.flush();
        }
        previous_hook(panic_info);
    }));

    let _ = PANIC_HOOK_INSTALLED.set(());
}

fn panic_payload_summary(info: &std::panic::PanicHookInfo<'_>) -> String {
    let payload = if let Some(message) = info.payload().downcast_ref::<&str>() {
        (*message).to_string()
    } else if let Some(message) = info.payload().downcast_ref::<String>() {
        message.clone()
    } else {
        "non-string panic payload".to_string()
    };

    sanitize_message(&payload, MAX_PANIC_PAYLOAD_CHARS)
}

fn sanitize_message(value: &str, max_chars: usize) -> String {
    let normalized = value.replace(['\n', '\r'], " ");
    let mut truncated = normalized.chars().take(max_chars).collect::<String>();
    if normalized.chars().count() > max_chars {
        truncated.push_str("...");
    }
    truncated
}

fn sanitize_inline_field(value: &str) -> String {
    value.replace(['\n', '\r'], " ").trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::{
        build_session_file_spec, cleanup_managed_logs_best_effort, init_logging, log_dart_event,
        logging_status, normalize_level, normalize_log_dir, sanitize_message, LogDartEventError,
        LogRetentionPolicy, LOG_FILE_BASENAME,
    };
    use std::path::{Path, PathBuf};
    use std::time::{Duration, SystemTime, UNIX_EPOCH};

    fn unique_temp_dir(suffix: &str) -> PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system time should be after unix epoch")
            .as_nanos();
        std::env::temp_dir().join(format!(
            "lazynote-logging-{suffix}-{}-{nanos}",
            std::process::id()
        ))
    }

    #[test]
    fn normalize_level_accepts_known_values() {
        assert_eq!(
            normalize_level("INFO").expect("INFO should normalize"),
            "info"
        );
        assert_eq!(
            normalize_level(" warning ").expect("warning should normalize"),
            "warn"
        );
    }

    #[test]
    fn normalize_log_dir_rejects_relative_path() {
        let error = normalize_log_dir("logs/dev").expect_err("relative paths must be rejected");
        assert!(error.contains("absolute"));
    }

    #[test]
    fn sanitize_message_removes_newlines_and_truncates() {
        let sanitized = sanitize_message("line1\nline2\rline3", 8);
        assert!(!sanitized.contains('\n'));
        assert!(!sanitized.contains('\r'));
        assert!(sanitized.ends_with("..."));
    }

    #[test]
    fn log_dart_event_rejects_invalid_level() {
        let result = log_dart_event("verbose", "startup", "app", "hello");
        assert!(matches!(
            result,
            Err(LogDartEventError::InvalidLevel(value)) if value == "verbose"
        ));
    }

    #[test]
    fn session_file_spec_contains_pid_and_timestamp() {
        let file_path = build_session_file_spec(Path::new("C:/logs")).as_pathbuf(None);
        let file_name = file_path
            .file_name()
            .and_then(|value| value.to_str())
            .expect("file name must be UTF-8");

        let pid_prefix = format!("{LOG_FILE_BASENAME}_pid{}_", std::process::id());
        assert!(
            file_name.starts_with(&pid_prefix),
            "unexpected session file name: {file_name}"
        );
        assert!(file_name.ends_with(".log"));
    }

    #[test]
    fn retention_cleanup_enforces_file_count_limit() {
        let log_dir = unique_temp_dir("retention-max-files");
        std::fs::create_dir_all(&log_dir).expect("temp log dir should be creatable");

        let oldest = create_managed_log_file(&log_dir, "lazynote_a.log", 12);
        std::thread::sleep(Duration::from_millis(20));
        let middle = create_managed_log_file(&log_dir, "lazynote_b.log", 12);
        std::thread::sleep(Duration::from_millis(20));
        let newest = create_managed_log_file(&log_dir, "lazynote_c.log", 12);

        let summary = cleanup_managed_logs_best_effort(
            &log_dir,
            LogRetentionPolicy {
                max_age_days: 365,
                max_files: 2,
                max_total_bytes: 1024,
            },
            SystemTime::now(),
        );
        assert_eq!(summary.removed, 1);
        assert_eq!(summary.failed, 0);
        assert!(!oldest.exists());
        assert!(middle.exists());
        assert!(newest.exists());

        std::fs::remove_dir_all(&log_dir).expect("temp log dir should be removable");
    }

    #[test]
    fn retention_cleanup_enforces_total_size_limit() {
        let log_dir = unique_temp_dir("retention-max-size");
        std::fs::create_dir_all(&log_dir).expect("temp log dir should be creatable");

        let oldest = create_managed_log_file(&log_dir, "lazynote_size_a.log", 8);
        std::thread::sleep(Duration::from_millis(20));
        let middle = create_managed_log_file(&log_dir, "lazynote_size_b.log", 8);
        std::thread::sleep(Duration::from_millis(20));
        let newest = create_managed_log_file(&log_dir, "lazynote_size_c.log", 8);

        let summary = cleanup_managed_logs_best_effort(
            &log_dir,
            LogRetentionPolicy {
                max_age_days: 365,
                max_files: 20,
                max_total_bytes: 12,
            },
            SystemTime::now(),
        );
        assert_eq!(summary.removed, 2);
        assert_eq!(summary.failed, 0);
        assert!(!oldest.exists());
        assert!(!middle.exists());
        assert!(newest.exists());

        std::fs::remove_dir_all(&log_dir).expect("temp log dir should be removable");
    }

    #[test]
    fn retention_cleanup_age_zero_removes_existing_logs() {
        let log_dir = unique_temp_dir("retention-age-zero");
        std::fs::create_dir_all(&log_dir).expect("temp log dir should be creatable");

        let first = create_managed_log_file(&log_dir, "lazynote_age_a.log", 4);
        let second = create_managed_log_file(&log_dir, "lazynote_age_b.log", 4);
        let unrelated = create_managed_log_file(&log_dir, "other.log", 4);

        let summary = cleanup_managed_logs_best_effort(
            &log_dir,
            LogRetentionPolicy {
                max_age_days: 0,
                max_files: 20,
                max_total_bytes: 1024,
            },
            SystemTime::now(),
        );
        assert_eq!(summary.removed, 2);
        assert_eq!(summary.failed, 0);
        assert!(!first.exists());
        assert!(!second.exists());
        assert!(unrelated.exists());

        std::fs::remove_dir_all(&log_dir).expect("temp log dir should be removable");
    }

    fn create_managed_log_file(log_dir: &Path, name: &str, size: usize) -> PathBuf {
        let path = log_dir.join(name);
        let content = vec![b'a'; size];
        std::fs::write(&path, content).expect("log file should be writable");
        path
    }

    #[test]
    fn init_logging_is_idempotent_for_same_config_and_rejects_conflicts() {
        let log_dir = unique_temp_dir("idempotent");
        let log_dir_str = log_dir
            .to_str()
            .expect("temp dir should be valid UTF-8")
            .to_string();
        let second_dir = unique_temp_dir("different");
        let second_dir_str = second_dir
            .to_str()
            .expect("temp dir should be valid UTF-8")
            .to_string();

        init_logging("info", &log_dir_str).expect("first init should succeed");
        init_logging("info", &log_dir_str).expect("same config should be idempotent");

        let level_error =
            init_logging("debug", &log_dir_str).expect_err("level conflict should fail");
        assert!(level_error.contains("refusing to switch"));

        let dir_error =
            init_logging("info", &second_dir_str).expect_err("directory conflict should fail");
        assert!(dir_error.contains("refusing to switch"));

        let (active_level, active_dir) = logging_status().expect("logging should be active");
        assert_eq!(active_level, "info");
        assert_eq!(active_dir, log_dir);
    }
}
