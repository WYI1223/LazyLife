use lazynote_core::db::open_db_in_memory;
use lazynote_core::{
    Atom, AtomRepository, ProjectionMode, ScopedAtomQuery, ScopedQueryError, ScopedQueryRepository,
    SortSpec, SqliteAtomRepository, SqliteScopedQueryRepository, SqliteTreeRepository,
    SqliteWorkspaceMetaRepository, StatusFilter, TaskService, TimeFilter, TimeShapeFilter,
    TreeService, ViewHint,
};
use rusqlite::Connection;
use uuid::Uuid;

fn setup() -> Connection {
    open_db_in_memory().unwrap()
}

fn default_workspace_id(conn: &Connection) -> Uuid {
    let workspace_id: String = conn
        .query_row(
            "SELECT workspace_id FROM workspaces WHERE is_default = 1;",
            [],
            |row| row.get(0),
        )
        .unwrap();
    Uuid::parse_str(&workspace_id).unwrap()
}

fn insert_atom(conn: &Connection, atom: &Atom) {
    let repo = SqliteAtomRepository::try_new(conn).unwrap();
    repo.create_atom(atom).unwrap();
}

fn create_folder(conn: &Connection, parent_uuid: Option<Uuid>, name: &str) -> Uuid {
    let service = TreeService::new(SqliteTreeRepository::try_new(conn).unwrap());
    service.create_folder(parent_uuid, name).unwrap().node_uuid
}

fn create_atom_ref(
    conn: &Connection,
    parent_uuid: Option<Uuid>,
    atom_uuid: Uuid,
    display_name: &str,
) -> Uuid {
    let service = TreeService::new(SqliteTreeRepository::try_new(conn).unwrap());
    service
        .create_atom_ref(parent_uuid, atom_uuid, Some(display_name.to_string()))
        .unwrap()
        .node_uuid
}

fn insert_atom_ref_row(
    conn: &Connection,
    node_uuid: Uuid,
    parent_uuid: Uuid,
    atom_uuid: Uuid,
    display_name: &str,
    sort_order: i64,
) {
    conn.execute(
        "INSERT INTO workspace_nodes (
            node_uuid,
            kind,
            parent_uuid,
            atom_uuid,
            display_name,
            sort_order,
            is_deleted,
            created_at,
            updated_at
        ) VALUES (?1, 'atom_ref', ?2, ?3, ?4, ?5, 0, 1000, 1000);",
        rusqlite::params![
            node_uuid.to_string(),
            parent_uuid.to_string(),
            atom_uuid.to_string(),
            display_name,
            sort_order,
        ],
    )
    .unwrap();
}

fn make_atom(
    view_hint: ViewHint,
    content: &str,
    start_at: Option<i64>,
    end_at: Option<i64>,
) -> Atom {
    let mut atom = Atom::new(view_hint, content);
    atom.start_at = start_at;
    atom.end_at = end_at;
    atom
}

#[test]
fn subtree_scope_only_returns_descendants() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let project_a = create_folder(&conn, Some(workspace_id), "Project A");
    let child_a = create_folder(&conn, Some(project_a), "Child A");
    let project_b = create_folder(&conn, Some(workspace_id), "Project B");

    let atom_a = make_atom(ViewHint::Note, "A", None, None);
    let atom_child = make_atom(ViewHint::Note, "Child", None, None);
    let atom_b = make_atom(ViewHint::Note, "B", None, None);
    let atom_root = make_atom(ViewHint::Note, "Root", None, None);

    insert_atom(&conn, &atom_a);
    insert_atom(&conn, &atom_child);
    insert_atom(&conn, &atom_b);
    insert_atom(&conn, &atom_root);

    create_atom_ref(&conn, Some(project_a), atom_a.uuid, "A ref");
    create_atom_ref(&conn, Some(child_a), atom_child.uuid, "Child ref");
    create_atom_ref(&conn, Some(project_b), atom_b.uuid, "B ref");
    create_atom_ref(&conn, Some(workspace_id), atom_root.uuid, "Root ref");

    let repo = SqliteScopedQueryRepository::try_new(&conn).unwrap();
    let results = repo
        .query_scoped_atoms(
            ScopedAtomQuery {
                folder_id: project_a,
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
        .unwrap();

    let ids: Vec<_> = results.iter().map(|item| item.atom.uuid).collect();
    assert_eq!(results.len(), 2);
    assert!(ids.contains(&atom_a.uuid));
    assert!(ids.contains(&atom_child.uuid));
    assert!(!ids.contains(&atom_b.uuid));
    assert!(!ids.contains(&atom_root.uuid));
}

#[test]
fn atom_projection_dedups_duplicate_refs() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let project = create_folder(&conn, Some(workspace_id), "Project");
    let child = create_folder(&conn, Some(project), "Child");

    let atom = make_atom(ViewHint::Task, "Duplicate", None, Some(2_000));
    insert_atom(&conn, &atom);
    create_atom_ref(&conn, Some(project), atom.uuid, "Dup ref A");
    create_atom_ref(&conn, Some(child), atom.uuid, "Dup ref B");

    let repo = SqliteScopedQueryRepository::try_new(&conn).unwrap();
    let results = repo
        .query_scoped_atoms(
            ScopedAtomQuery {
                folder_id: project,
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
        .unwrap();

    assert_eq!(results.len(), 1);
    assert_eq!(results[0].atom.uuid, atom.uuid);
}

#[test]
fn ref_projection_returns_each_ref_with_path() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let project = create_folder(&conn, Some(workspace_id), "Project");
    let child = create_folder(&conn, Some(project), "Child");

    let atom = make_atom(ViewHint::Task, "Duplicate", None, Some(2_000));
    insert_atom(&conn, &atom);
    create_atom_ref(&conn, Some(project), atom.uuid, "Dup ref A");
    create_atom_ref(&conn, Some(child), atom.uuid, "Dup ref B");

    let repo = SqliteScopedQueryRepository::try_new(&conn).unwrap();
    let results = repo
        .query_scoped_atoms(
            ScopedAtomQuery {
                folder_id: project,
                view_hint: None,
                time_filter: TimeFilter::Any,
                time_shape: TimeShapeFilter::Any,
                status_filter: StatusFilter::Any,
                tag: None,
                text_query: None,
                include_path: true,
                include_overdue_deadlines: false,
                sort: SortSpec::UpdatedAtDesc,
                limit: 50,
                offset: 0,
            },
            ProjectionMode::Ref,
        )
        .unwrap();

    assert_eq!(results.len(), 2);
    assert!(results.iter().all(|item| item.path.is_some()));
    assert!(results
        .iter()
        .any(|item| item.path.as_deref().unwrap().contains("Project")));
    assert!(results
        .iter()
        .any(|item| item.path.as_deref().unwrap().contains("Child")));
}

#[test]
fn ref_projection_uses_representative_node_uuid_as_stable_tie_breaker() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);

    let atom = make_atom(ViewHint::Note, "Shared", None, None);
    insert_atom(&conn, &atom);

    let later_uuid = Uuid::parse_str("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb").unwrap();
    let earlier_uuid = Uuid::parse_str("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa").unwrap();

    insert_atom_ref_row(
        &conn,
        later_uuid,
        workspace_id,
        atom.uuid,
        "Later tie-breaker",
        0,
    );
    insert_atom_ref_row(
        &conn,
        earlier_uuid,
        workspace_id,
        atom.uuid,
        "Earlier tie-breaker",
        10,
    );

    let repo = SqliteScopedQueryRepository::try_new(&conn).unwrap();
    let results = repo
        .query_scoped_atoms(
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
            ProjectionMode::Ref,
        )
        .unwrap();

    let ref_ids: Vec<_> = results
        .iter()
        .map(|item| item.representative_node_uuid)
        .collect();
    assert_eq!(ref_ids, vec![earlier_uuid, later_uuid]);
}

#[test]
fn invalid_overdue_descriptor_is_rejected() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let repo = SqliteScopedQueryRepository::try_new(&conn).unwrap();

    let err = repo
        .query_scoped_atoms(
            ScopedAtomQuery {
                folder_id: workspace_id,
                view_hint: None,
                time_filter: TimeFilter::Any,
                time_shape: TimeShapeFilter::Any,
                status_filter: StatusFilter::Any,
                tag: None,
                text_query: None,
                include_path: false,
                include_overdue_deadlines: true,
                sort: SortSpec::UpdatedAtDesc,
                limit: 50,
                offset: 0,
            },
            ProjectionMode::Atom,
        )
        .unwrap_err();

    assert!(matches!(
        err,
        ScopedQueryError::InvalidQueryDescriptor(message)
        if message.contains("include_overdue_deadlines")
    ));
}

#[test]
fn open_ended_range_uses_anchor_forward_semantics() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);
    let project = create_folder(&conn, Some(workspace_id), "Project");

    let ongoing = make_atom(ViewHint::Task, "Ongoing", Some(500), None);
    let future_deadline = make_atom(ViewHint::Task, "Future deadline", None, Some(2_000));
    let future_event = make_atom(ViewHint::Event, "Future event", Some(2_500), Some(3_000));

    insert_atom(&conn, &ongoing);
    insert_atom(&conn, &future_deadline);
    insert_atom(&conn, &future_event);

    create_atom_ref(&conn, Some(project), ongoing.uuid, "Ongoing ref");
    create_atom_ref(&conn, Some(project), future_deadline.uuid, "Deadline ref");
    create_atom_ref(&conn, Some(project), future_event.uuid, "Event ref");

    let repo = SqliteScopedQueryRepository::try_new(&conn).unwrap();
    let results = repo
        .query_scoped_atoms(
            ScopedAtomQuery {
                folder_id: project,
                view_hint: None,
                time_filter: TimeFilter::Range {
                    start_ms: 1_000,
                    end_ms: None,
                },
                time_shape: TimeShapeFilter::Any,
                status_filter: StatusFilter::ActiveOnly,
                tag: None,
                text_query: None,
                include_path: false,
                include_overdue_deadlines: false,
                sort: SortSpec::StartAtAsc,
                limit: 50,
                offset: 0,
            },
            ProjectionMode::Atom,
        )
        .unwrap();

    let ids: Vec<_> = results.iter().map(|item| item.atom.uuid).collect();
    assert_eq!(results.len(), 2);
    assert!(ids.contains(&future_deadline.uuid));
    assert!(ids.contains(&future_event.uuid));
    assert!(!ids.contains(&ongoing.uuid));
}

#[test]
fn task_service_keeps_root_scoped_visibility_before_pr_0410() {
    let conn = setup();
    let workspace_id = default_workspace_id(&conn);

    let event = make_atom(ViewHint::Event, "Calendar bridge", Some(1_000), Some(2_000));
    insert_atom(&conn, &event);
    create_atom_ref(&conn, Some(workspace_id), event.uuid, "Root event ref");

    let atom_repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let scoped_repo = SqliteScopedQueryRepository::try_new(&conn).unwrap();
    let workspace_meta = SqliteWorkspaceMetaRepository::try_new(&conn).unwrap();
    let service = TaskService::new(&atom_repo, &scoped_repo, &workspace_meta, &conn);

    let results = service.fetch_by_time_range(1_000, 2_000, 50, 0).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].atom.uuid, event.uuid);
}
