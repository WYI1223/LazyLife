use super::*;
use lazynote_core::LogDartEventError;
use uuid::Uuid;

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
