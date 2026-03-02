use lazynote_core::db::open_db_in_memory;
use lazynote_core::{
    Atom, AtomRepository, SqliteAtomRepository, TaskService, TaskStatus, ViewHint,
};

/// Helper: creates a migrated in-memory DB and returns (conn, repo).
fn setup() -> rusqlite::Connection {
    open_db_in_memory().unwrap()
}

fn insert_atom(conn: &rusqlite::Connection, atom: &Atom) {
    let repo = SqliteAtomRepository::try_new(conn).unwrap();
    repo.create_atom(atom).unwrap();
}

fn make_atom(kind: ViewHint, content: &str, start: Option<i64>, end: Option<i64>) -> Atom {
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
    let note = make_atom(ViewHint::Note, "pure note", None, None);
    let timed = make_atom(
        ViewHint::Task,
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
    let mut note = make_atom(ViewHint::Note, "completed", None, None);
    note.task_status = Some(TaskStatus::Done);
    insert_atom(&conn, &note);

    let mut note2 = make_atom(ViewHint::Note, "cancelled", None, None);
    note2.task_status = Some(TaskStatus::Cancelled);
    insert_atom(&conn, &note2);

    let active = make_atom(ViewHint::Note, "active", None, None);
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
    let ddl = make_atom(ViewHint::Task, "deadline today", None, Some(500));
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
    let ongoing = make_atom(ViewHint::Task, "started task", Some(100), None);
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
    let event = make_atom(ViewHint::Event, "meeting", Some(500), Some(1500));
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
    let future_ddl = make_atom(ViewHint::Task, "future deadline", None, Some(5000));
    insert_atom(&conn, &future_ddl);

    // Future ongoing: start_at=5000, eod=1000 → start_at > eod → NOT today
    let future_ongoing = make_atom(ViewHint::Task, "future start", Some(5000), None);
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
    let future_ddl = make_atom(ViewHint::Task, "future deadline", None, Some(5000));
    let future_event = make_atom(ViewHint::Event, "future event", Some(5000), Some(6000));
    let today_ddl = make_atom(ViewHint::Task, "today deadline", None, Some(500));
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
    let note = make_atom(ViewHint::Note, "demotable", None, None);
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
    let note = make_atom(ViewHint::Note, "idem", None, None);
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
    let note = make_atom(ViewHint::Note, "will be deleted", None, None);
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
    let note = make_atom(ViewHint::Note, "unique_searchable_term_xyz", None, None);
    insert_atom(&conn, &note);

    let query = lazynote_core::SearchQuery {
        text: "unique_searchable_term_xyz".to_string(),
        view_hint: None,
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
    let note = make_atom(ViewHint::Note, "tagged inbox", None, None);
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

// ---------------------------------------------------------------------------
// view_hint re-derivation on status / time updates (S1 R3)
// ---------------------------------------------------------------------------

#[test]
fn update_status_re_derives_view_hint_to_task() {
    let conn = setup();
    let note = make_atom(ViewHint::Note, "promote to task", None, None);
    insert_atom(&conn, &note);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);

    // Initially note
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Note);

    // Set status → view_hint must become Task
    svc.update_status(note.uuid, Some(TaskStatus::Todo))
        .unwrap();
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Task);
}

#[test]
fn clear_status_re_derives_view_hint_back_to_note() {
    let conn = setup();
    let note = make_atom(ViewHint::Note, "demote back", None, None);
    insert_atom(&conn, &note);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);

    // Promote to task
    svc.update_status(note.uuid, Some(TaskStatus::Done))
        .unwrap();
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Task);

    // Clear status → should go back to Note (no time fields)
    svc.update_status(note.uuid, None).unwrap();
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Note);
}

#[test]
fn clear_status_on_timed_atom_re_derives_to_event() {
    let conn = setup();
    // Atom with time fields AND status
    let mut atom = make_atom(ViewHint::Task, "timed task", Some(1000), Some(2000));
    atom.task_status = Some(TaskStatus::Todo);
    insert_atom(&conn, &atom);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);

    // Initially task (status takes priority)
    let loaded = repo.get_atom(atom.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Task);

    // Clear status → time fields present → Event
    svc.update_status(atom.uuid, None).unwrap();
    let loaded = repo.get_atom(atom.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Event);
}

#[test]
fn update_event_times_re_derives_view_hint_to_event() {
    let conn = setup();
    let note = make_atom(ViewHint::Note, "will become event", None, None);
    insert_atom(&conn, &note);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);

    // Initially note
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Note);

    // Set time fields → view_hint must become Event
    svc.update_event_times(note.uuid, 5000, 6000).unwrap();
    let loaded = repo.get_atom(note.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Event);
}

#[test]
fn update_event_times_preserves_task_when_status_set() {
    let conn = setup();
    let mut atom = make_atom(ViewHint::Task, "task with times", None, None);
    atom.task_status = Some(TaskStatus::Todo);
    insert_atom(&conn, &atom);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);

    // Set time fields — but task_status is set, so view_hint stays Task
    svc.update_event_times(atom.uuid, 5000, 6000).unwrap();
    let loaded = repo.get_atom(atom.uuid, false).unwrap().unwrap();
    assert_eq!(loaded.view_hint, ViewHint::Task);
}

// ---------------------------------------------------------------------------
// fetch_timed — startup reminder recovery (PR-RB-04 / S7)
// ---------------------------------------------------------------------------

#[test]
fn fetch_timed_returns_atoms_with_any_time_field() {
    let conn = setup();

    // Timeless note — should NOT appear
    let note = make_atom(ViewHint::Note, "pure note", None, None);
    insert_atom(&conn, &note);

    // DDL task (end_at only) — SHOULD appear
    let ddl = make_atom(ViewHint::Task, "deadline", None, Some(2_000_000_000_000));
    insert_atom(&conn, &ddl);

    // Ongoing task (start_at only) — SHOULD appear
    let ongoing = make_atom(ViewHint::Task, "ongoing", Some(1_000_000_000_000), None);
    insert_atom(&conn, &ongoing);

    // Timed event (both) — SHOULD appear
    let event = make_atom(
        ViewHint::Event,
        "meeting",
        Some(1_000_000_000_000),
        Some(1_000_003_600_000),
    );
    insert_atom(&conn, &event);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let timed = svc.fetch_timed().unwrap();

    assert_eq!(timed.len(), 3);
    let ids: Vec<_> = timed.iter().map(|s| s.atom.uuid).collect();
    assert!(ids.contains(&ddl.uuid));
    assert!(ids.contains(&ongoing.uuid));
    assert!(ids.contains(&event.uuid));
    assert!(!ids.contains(&note.uuid));
}

#[test]
fn fetch_timed_excludes_done_and_cancelled() {
    let conn = setup();

    let mut done_task = make_atom(ViewHint::Task, "done", None, Some(2_000_000_000_000));
    done_task.task_status = Some(TaskStatus::Done);
    insert_atom(&conn, &done_task);

    let mut cancelled_task = make_atom(ViewHint::Task, "cancelled", None, Some(2_000_000_000_000));
    cancelled_task.task_status = Some(TaskStatus::Cancelled);
    insert_atom(&conn, &cancelled_task);

    let active_task = make_atom(ViewHint::Task, "active", None, Some(2_000_000_000_000));
    insert_atom(&conn, &active_task);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let timed = svc.fetch_timed().unwrap();

    assert_eq!(timed.len(), 1);
    assert_eq!(timed[0].atom.uuid, active_task.uuid);
}

#[test]
fn fetch_timed_excludes_soft_deleted() {
    let conn = setup();

    let task = make_atom(
        ViewHint::Task,
        "will be deleted",
        None,
        Some(2_000_000_000_000),
    );
    insert_atom(&conn, &task);

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    repo.soft_delete_atom(task.uuid).unwrap();

    let svc = TaskService::new(&repo, &conn);
    let timed = svc.fetch_timed().unwrap();
    assert!(timed.is_empty());
}

#[test]
fn fetch_timed_includes_tags() {
    let conn = setup();

    let task = make_atom(ViewHint::Task, "tagged task", None, Some(2_000_000_000_000));
    insert_atom(&conn, &task);

    // Add a tag
    conn.execute("INSERT INTO tags (name) VALUES ('urgent');", [])
        .unwrap();
    let tag_id: i64 = conn
        .query_row("SELECT id FROM tags WHERE name = 'urgent'", [], |r| {
            r.get(0)
        })
        .unwrap();
    conn.execute(
        "INSERT INTO atom_tags (atom_uuid, tag_id) VALUES (?1, ?2);",
        rusqlite::params![task.uuid.to_string(), tag_id],
    )
    .unwrap();

    let repo = SqliteAtomRepository::try_new(&conn).unwrap();
    let svc = TaskService::new(&repo, &conn);
    let timed = svc.fetch_timed().unwrap();

    assert_eq!(timed.len(), 1);
    assert_eq!(timed[0].tags, vec!["urgent".to_string()]);
}
