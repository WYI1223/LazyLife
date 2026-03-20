use super::entry::entry_schedule_impl;
use super::notes::note_create_impl;
use super::workspace::workspace_create_folder_impl;
use super::*;
use lazynote_core::db::open_db;
use lazynote_core::{
    search_all, AccessError, AccessGuard, Atom, AtomRepository, CallerContext, CallerIdentity,
    Capability, SearchQuery, SqliteAtomRepository, SqliteTreeRepository, TaskStatus, TreeService,
    ViewHint,
};
use std::sync::{Mutex, MutexGuard};
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

pub(super) static TEST_DB_LOCK: Mutex<()> = Mutex::new(());

pub(super) fn acquire_test_db_lock() -> MutexGuard<'static, ()> {
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

pub(super) struct CrossWorkspaceDenyGuard;

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

pub(super) struct CapabilityDenyGuard;

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

pub(super) struct SelectiveWorkspaceReadGuard {
    pub(super) allowed_workspace: Uuid,
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

pub(super) fn create_workspace_folder(name: &str) -> String {
    let conn = open_db(super::resolve_entry_db_path()).expect("open db");
    let repo = SqliteTreeRepository::try_new(&conn).expect("init tree repo");
    let service = TreeService::new(repo);
    service
        .create_folder(None, name.to_string())
        .expect("create workspace folder")
        .node_uuid
        .to_string()
}

pub(super) fn default_workspace_node_id() -> String {
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

pub(super) fn designated_folder_node_id(role: &str) -> String {
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

pub(super) fn insert_workspace_root_for_test(name: &str) -> String {
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

pub(super) fn default_caller() -> FfiCallerContext {
    FfiCallerContext {
        identity: FfiCallerIdentity::App,
        scope_workspace_id: Some(default_workspace_node_id()),
    }
}

pub(super) fn base_query(folder_id: String) -> FfiScopedAtomQuery {
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

pub(super) fn create_task_request(content: &str) -> FfiCreateAtomRequest {
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

pub(super) fn create_legacy_root_scoped_atom(
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

pub(super) fn create_workspace_atom_ref_node() -> String {
    let response = note_create_impl("workspace note".to_string(), None);
    assert!(response.ok, "{}", response.message);
    response.node_uuid.expect("node_uuid from note_create")
}

pub(super) fn create_workspace_folder_via_ffi(name: &str) -> String {
    let response = workspace_create_folder_impl(None, name.to_string());
    assert!(response.ok, "{}", response.message);
    response
        .node
        .expect("workspace node payload")
        .node_id
        .to_string()
}

pub(super) fn create_test_event(title: &str, start_ms: i64, end_ms: i64) -> String {
    let resp = entry_schedule_impl(title.to_string(), start_ms, Some(end_ms));
    assert!(resp.ok, "create_test_event failed: {}", resp.message);
    resp.atom_id.expect("event should return atom_id")
}

pub(super) fn unique_token(prefix: &str) -> String {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("time went backwards")
        .as_nanos();
    format!("{prefix}-{nanos}")
}

pub(super) fn function_source(signature: &str) -> &'static str {
    let needle = format!("{signature}(");
    let sources = [
        include_str!("mod.rs"),
        include_str!("entry.rs"),
        include_str!("notes.rs"),
        include_str!("tasks.rs"),
        include_str!("calendar.rs"),
        include_str!("query.rs"),
        include_str!("creation.rs"),
        include_str!("workspace.rs"),
    ];

    for source in sources {
        if let Some(start) = source.find(needle.as_str()) {
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
        }
    }

    panic!("signature `{signature}` not found");
}

pub(super) fn assert_thin_wrapper(signature: &str, delegate_call: &str, forbidden: &[&str]) {
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

pub(super) fn direct_search(query: &str) -> Vec<SearchHit> {
    let conn = open_db(super::resolve_entry_db_path()).expect("open db");
    search_all(&conn, &SearchQuery::new(query)).expect("direct search")
}
