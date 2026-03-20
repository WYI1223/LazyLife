use super::*;
use lazynote_core::db::open_db;
use lazynote_core::ViewHint;

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

    let blank_response = entry_search_impl("hello".to_string(), Some("   ".to_string()), Some(7));
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

    let conn = open_db(super::super::resolve_entry_db_path()).expect("open db");
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

    let conn = open_db(super::super::resolve_entry_db_path()).expect("open db");
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

    let folder = workspace_create_folder_impl(None, "target-folder".to_string());
    assert!(folder.ok, "{}", folder.message);
    let folder_id = folder.node.expect("folder node").node_id;

    let created = note_create_impl("# child note".to_string(), Some(folder_id.clone()));
    assert!(created.ok, "{}", created.message);
    let node_uuid = created
        .node_uuid
        .expect("note_create should return node_uuid");

    let children = workspace_list_children_impl(Some(folder_id.clone()));
    assert!(children.ok, "{}", children.message);
    let child_ids: Vec<&str> = children.items.iter().map(|n| n.node_id.as_str()).collect();
    assert!(
        child_ids.contains(&node_uuid.as_str()),
        "atom_ref should be under target folder, got: {:?}",
        child_ids
    );

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

    let conn = open_db(super::super::resolve_entry_db_path()).expect("open db");
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

#[test]
fn calendar_list_by_range_returns_overlapping_events() {
    let _guard = acquire_test_db_lock();
    let inside_id = create_test_event("overlap", 10_000, 12_000);
    let outside_id = create_test_event("outside", 20_000, 22_000);

    let resp = calendar_list_by_range_impl(9_000, 13_000, None, None);
    assert!(resp.ok, "{}", resp.message);
    assert!(
        resp.items.iter().any(|i| i.atom_id == inside_id),
        "overlapping event should be in results"
    );
    assert!(
        !resp.items.iter().any(|i| i.atom_id == outside_id),
        "non-overlapping event should not be in results"
    );
}

#[test]
fn calendar_list_by_range_includes_done_events() {
    let _guard = acquire_test_db_lock();
    let event_id = create_test_event("done-cal", 30_000, 32_000);

    let status_resp = atom_update_status_impl(event_id.clone(), Some("done".to_string()));
    assert!(status_resp.ok, "{}", status_resp.message);

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

    let conn = open_db(super::super::resolve_entry_db_path()).expect("open db");
    let original_updated_at: i64 = conn
        .query_row(
            "SELECT updated_at FROM atoms WHERE uuid = ?1",
            [event_id.as_str()],
            |row| row.get(0),
        )
        .expect("read updated_at");

    let resp = calendar_update_event_impl(event_id.clone(), 70_000, 75_000);
    assert!(resp.ok, "{}", resp.message);
    assert_eq!(resp.atom_id.as_deref(), Some(event_id.as_str()));

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
