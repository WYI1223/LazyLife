use lazynote_core::db::open_db_in_memory;
use lazynote_core::CreationService;
use lazynote_core::{
    AccessError, AccessGuard, CallerContext, CallerIdentity, CreateAtomRequest,
    GuardedCreationService, GuardedQueryService, GuardedServiceError, NoopGuard, ProjectionMode,
    ScopedAtomQuery, SortSpec, SqliteScopedQueryRepository, SqliteTreeRepository,
    SqliteWorkspaceMetaRepository, StatusFilter, TaskStatus, TimeFilter, TimeShapeFilter,
    WorkspaceMetaRepository,
};
use rusqlite::Connection;
use uuid::Uuid;

struct DenyGuard;

impl AccessGuard for DenyGuard {
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

fn setup() -> Connection {
    open_db_in_memory().expect("open in-memory db")
}

fn default_workspace_id(conn: &Connection) -> Uuid {
    let workspace_meta = SqliteWorkspaceMetaRepository::try_new(conn).expect("workspace meta");
    workspace_meta
        .get_default_workspace()
        .expect("default workspace query")
        .expect("default workspace exists")
}

fn atom_count(conn: &Connection) -> i64 {
    conn.query_row("SELECT COUNT(*) FROM atoms;", [], |row| row.get(0))
        .expect("atom count")
}

#[test]
fn noop_guard_allows_scoped_query_for_matching_workspace() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let creation = CreationService::try_new(&conn).expect("creation service");
    let query_repo = SqliteScopedQueryRepository::try_new(&conn).expect("scoped repo");
    let tree_repo = SqliteTreeRepository::try_new(&conn).expect("tree repo");

    let created = creation
        .create_atom(&CreateAtomRequest {
            workspace_id,
            content: "guarded query note".to_string(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: None,
            display_name: None,
        })
        .expect("seed note");

    let service = GuardedQueryService::new(Box::new(NoopGuard), &query_repo, &tree_repo);
    let caller = CallerContext {
        identity: CallerIdentity::App,
        scope_workspace_id: Some(workspace_id),
    };
    let results = service
        .query_atoms(
            &caller,
            ScopedAtomQuery {
                folder_id: workspace_id,
                view_hint: None,
                time_filter: TimeFilter::Any,
                time_shape: TimeShapeFilter::Any,
                status_filter: StatusFilter::Any,
                tag: None,
                text_query: None,
                include_path: false,
                include_overdue_deadlines: false,
                sort: SortSpec::UpdatedAtDesc,
                limit: 50,
                offset: 0,
            },
            ProjectionMode::Atom,
        )
        .expect("noop guard query succeeds");

    assert!(results
        .iter()
        .any(|item| item.atom.uuid == created.atom.uuid));
}

#[test]
fn deny_guard_rejects_scoped_query_before_repository_read() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let query_repo = SqliteScopedQueryRepository::try_new(&conn).expect("scoped repo");
    let tree_repo = SqliteTreeRepository::try_new(&conn).expect("tree repo");
    let service = GuardedQueryService::new(Box::new(DenyGuard), &query_repo, &tree_repo);
    let caller = CallerContext {
        identity: CallerIdentity::App,
        scope_workspace_id: Some(workspace_id),
    };

    let err = service
        .query_atoms(
            &caller,
            ScopedAtomQuery {
                folder_id: workspace_id,
                view_hint: None,
                time_filter: TimeFilter::Any,
                time_shape: TimeShapeFilter::Any,
                status_filter: StatusFilter::Any,
                tag: None,
                text_query: None,
                include_path: false,
                include_overdue_deadlines: false,
                sort: SortSpec::UpdatedAtDesc,
                limit: 50,
                offset: 0,
            },
            ProjectionMode::Atom,
        )
        .expect_err("deny guard should reject query");

    assert!(matches!(
        err,
        GuardedServiceError::Access(AccessError::CrossWorkspaceAccessDenied { .. })
    ));
}

#[test]
fn deny_guard_rejects_create_atom_before_inner_service_write() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let creation = CreationService::try_new(&conn).expect("creation service");
    let guarded = GuardedCreationService::new(Box::new(DenyGuard), &creation);
    let caller = CallerContext {
        identity: CallerIdentity::App,
        scope_workspace_id: Some(workspace_id),
    };
    let before = atom_count(&conn);

    let err = guarded
        .create_atom(
            &caller,
            &CreateAtomRequest {
                workspace_id,
                content: "blocked create".to_string(),
                content_type: "markdown".to_string(),
                task_status: Some(TaskStatus::Todo),
                start_at: None,
                end_at: None,
                tags: None,
                target_folder: None,
                display_name: None,
            },
        )
        .expect_err("deny guard should reject write");

    let after = atom_count(&conn);
    assert_eq!(
        before, after,
        "inner creation should not run when guard denies"
    );
    assert!(matches!(
        err,
        GuardedServiceError::Access(AccessError::CrossWorkspaceAccessDenied { .. })
    ));
}
