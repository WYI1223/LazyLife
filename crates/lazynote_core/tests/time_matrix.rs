use lazynote_core::db::open_db_in_memory;
use lazynote_core::{
    Atom, AtomRepository, AtomType, SqliteAtomRepository, TaskService, TaskStatus,
};

/// Helper: creates a migrated in-memory DB and returns (conn, repo).
fn setup() -> rusqlite::Connection {
    open_db_in_memory().unwrap()
}

fn insert_atom(conn: &rusqlite::Connection, atom: &Atom) {
    let repo = SqliteAtomRepository::try_new(conn).unwrap();
    repo.create_atom(atom).unwrap();
}

fn make_atom(kind: AtomType, content: &str, start: Option<i64>, end: Option<i64>) -> Atom {
    let mut atom = Atom::new(kind, content);
    atom.start_at = start;
    atom.end_at = end;
    atom
}

// ---------------------------------------------------------------------------
// Migration 6
// ---------------------------------------------------------------------------

#[test]
fn migration_6_renames_columns() {
    let conn = setup();

    // start_at / end_at should exist
    let mut stmt = conn.prepare("PRAGMA table_info(atoms);").unwrap();
    let mut rows = stmt.query([]).unwrap();
    let mut cols = Vec::new();
    while let Some(row) = rows.next().unwrap() {
        let name: String = row.get(1).unwrap();
        cols.push(name);
    }
    assert!(cols.contains(&"start_at".to_string()));
    assert!(cols.contains(&"end_at".to_string()));
    assert!(cols.contains(&"recurrence_rule".to_string()));
    assert!(!cols.contains(&"event_start".to_string()));
    assert!(!cols.contains(&"event_end".to_string()));
}

// ---------------------------------------------------------------------------
// Inbox section
// ---------------------------------------------------------------------------

#[test]
fn fetch_inbox_returns_timeless_atoms() {
    let conn = setup();
    let note = make_atom(AtomType::Note, "pure note", None, None);
    let timed = make_atom(
        AtomType::Task,
        "has deadline",
        None,
        Some(2_000_000_000_000),
    );
    insert_atom(&conn, &note);
    insert_atom(&conn, &timed);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let inbox = svc.fetch_inbox(50, 0).unwrap();

    assert_eq!(inbox.len(), 1);
    assert_eq!(inbox[0].atom.uuid, note.uuid);
}

#[test]
fn fetch_inbox_excludes_done_and_cancelled() {
    let conn = setup();
    let mut note = make_atom(AtomType::Note, "completed", None, None);
    note.task_status = Some(TaskStatus::Done);
    insert_atom(&conn, &note);

    let mut note2 = make_atom(AtomType::Note, "cancelled", None, None);
    note2.task_status = Some(TaskStatus::Cancelled);
    insert_atom(&conn, &note2);

    let active = make_atom(AtomType::Note, "active", None, None);
    insert_atom(&conn, &active);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let inbox = svc.fetch_inbox(50, 0).unwrap();

    assert_eq!(inbox.len(), 1);
    assert_eq!(inbox[0].atom.uuid, active.uuid);
}

// ---------------------------------------------------------------------------
// Today section
// ---------------------------------------------------------------------------

#[test]
fn fetch_today_returns_ddl_task_due_today() {
    let conn = setup();
    // DDL task: end_at within today (end_at=500, eod=1000)
    let ddl = make_atom(AtomType::Task, "deadline today", None, Some(500));
    insert_atom(&conn, &ddl);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let today = svc.fetch_today(0, 1000, 50, 0).unwrap();

    assert_eq!(today.len(), 1);
    assert_eq!(today[0].atom.uuid, ddl.uuid);
}

#[test]
fn fetch_today_returns_started_ongoing_task() {
    let conn = setup();
    // Ongoing: start_at=100, no end, eod=1000 → start_at <= eod
    let ongoing = make_atom(AtomType::Task, "started task", Some(100), None);
    insert_atom(&conn, &ongoing);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let today = svc.fetch_today(0, 1000, 50, 0).unwrap();

    assert_eq!(today.len(), 1);
    assert_eq!(today[0].atom.uuid, ongoing.uuid);
}

#[test]
fn fetch_today_returns_overlapping_event() {
    let conn = setup();
    // Event overlapping today: start_at=500, end_at=1500, bod=0, eod=1000
    let event = make_atom(AtomType::Event, "meeting", Some(500), Some(1500));
    insert_atom(&conn, &event);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let today = svc.fetch_today(0, 1000, 50, 0).unwrap();

    assert_eq!(today.len(), 1);
    assert_eq!(today[0].atom.uuid, event.uuid);
}

#[test]
fn fetch_today_excludes_future_only_atoms() {
    let conn = setup();
    // Future DDL: end_at=5000, eod=1000 → end_at > eod → NOT today
    let future_ddl = make_atom(AtomType::Task, "future deadline", None, Some(5000));
    insert_atom(&conn, &future_ddl);

    // Future ongoing: start_at=5000, eod=1000 → start_at > eod → NOT today
    let future_ongoing = make_atom(AtomType::Task, "future start", Some(5000), None);
    insert_atom(&conn, &future_ongoing);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let today = svc.fetch_today(0, 1000, 50, 0).unwrap();

    assert!(today.is_empty());
}

// ---------------------------------------------------------------------------
// Upcoming section
// ---------------------------------------------------------------------------

#[test]
fn fetch_upcoming_returns_future_atoms() {
    let conn = setup();
    let future_ddl = make_atom(AtomType::Task, "future deadline", None, Some(5000));
    let future_event = make_atom(AtomType::Event, "future event", Some(5000), Some(6000));
    let today_ddl = make_atom(AtomType::Task, "today deadline", None, Some(500));
    insert_atom(&conn, &future_ddl);
    insert_atom(&conn, &future_event);
    insert_atom(&conn, &today_ddl);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let upcoming = svc.fetch_upcoming(1000, 50, 0).unwrap();

    assert_eq!(upcoming.len(), 2);
    let ids: Vec<_> = upcoming.iter().map(|s| s.atom.uuid).collect();
    assert!(ids.contains(&future_ddl.uuid));
    assert!(ids.contains(&future_event.uuid));
}

// ---------------------------------------------------------------------------
// Status update
// ---------------------------------------------------------------------------

#[test]
fn update_status_sets_and_clears() {
    let conn = setup();
    let note = make_atom(AtomType::Note, "demotable", None, None);
    insert_atom(&conn, &note);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);

    // Set to done
    svc.update_status(note.uuid, Some(TaskStatus::Done))
        .unwrap();
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.task_status, Some(TaskStatus::Done));

    // Set to todo
    svc.update_status(note.uuid, Some(TaskStatus::Todo))
        .unwrap();
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.task_status, Some(TaskStatus::Todo));

    // Clear (demote)
    svc.update_status(note.uuid, None).unwrap();
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.task_status, None);
}

#[test]
fn update_status_is_idempotent() {
    let conn = setup();
    let note = make_atom(AtomType::Note, "idem", None, None);
    insert_atom(&conn, &note);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);

    svc.update_status(note.uuid, Some(TaskStatus::Done))
        .unwrap();
    svc.update_status(note.uuid, Some(TaskStatus::Done))
        .unwrap();

    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.task_status, Some(TaskStatus::Done));
}

#[test]
fn update_status_on_deleted_atom_returns_not_found() {
    let conn = setup();
    let note = make_atom(AtomType::Note, "will be deleted", None, None);
    insert_atom(&conn, &note);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    repo.soft_delete_atom(note.uuid).unwrap();

    let svc = TaskService::new(&repo, &conn);
    let result = svc.update_status(note.uuid, Some(TaskStatus::Done));
    assert!(result.is_err());
}

// ---------------------------------------------------------------------------
// FTS still works after migration 6
// ---------------------------------------------------------------------------

#[test]
fn fts_search_works_after_migration_6() {
    let conn = setup();
    let note = make_atom(AtomType::Note, "unique_searchable_term_xyz", None, None);
    insert_atom(&conn, &note);

    let query = lazynote_core::SearchQuery {
        text: "unique_searchable_term_xyz".to_string(),
        kind: None,
        limit: 10,
        raw_fts_syntax: false,
    };
    let results = lazynote_core::search_all(&conn, &query).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].atom_id, note.uuid);
}

// ---------------------------------------------------------------------------
// Tag enrichment in section queries
// ---------------------------------------------------------------------------

#[test]
fn section_queries_include_tags() {
    let conn = setup();
    let note = make_atom(AtomType::Note, "tagged inbox", None, None);
    insert_atom(&conn, &note);

    // Manually add a tag
    conn.execute("INSERT INTO tags (name) VALUES ('work');", [])
        .unwrap();
    let tag_id: i64 = conn
        .query_row("SELECT id FROM tags WHERE name = 'work'", [], |r| r.get(0))
        .unwrap();
    conn.execute(
        "INSERT INTO atom_tags (atom_uuid, tag_id) VALUES (?1, ?2);",
        rusqlite::params![note.uuid.to_string(), tag_id],
    )
    .unwrap();

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let inbox = svc.fetch_inbox(50, 0).unwrap();

    assert_eq!(inbox.len(), 1);
    assert_eq!(inbox[0].tags, vec!["work".to_string()]);
}
