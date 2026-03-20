use super::*;

#[test]
fn legacy_wrapper_tasks_list_inbox_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let token = unique_token("legacy-inbox");
    let created = entry_create_note_impl(token.clone());
    assert!(created.ok, "{}", created.message);
    let atom_id = created.atom_id.expect("atom id");

    let response = tasks_list_inbox_impl(Some(50), Some(0));
    assert!(response.ok, "{}", response.message);
    assert!(response.items.iter().any(|item| item.atom_id == atom_id));
    assert_eq!(response.error_code, None);
}

#[test]
fn legacy_wrapper_tasks_list_today_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = entry_schedule_impl(unique_token("legacy-today"), 10_000, Some(12_000));
    assert!(response.ok, "{}", response.message);
    let atom_id = response.atom_id.expect("atom id");

    let listed = tasks_list_today_impl(9_000, 13_000, Some(50), Some(0));
    assert!(listed.ok, "{}", listed.message);
    assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
}

#[test]
fn legacy_wrapper_tasks_list_upcoming_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = entry_schedule_impl(unique_token("legacy-upcoming"), 20_000, Some(21_000));
    assert!(response.ok, "{}", response.message);
    let atom_id = response.atom_id.expect("atom id");

    let listed = tasks_list_upcoming_impl(15_000, Some(50), Some(0));
    assert!(listed.ok, "{}", listed.message);
    assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
}

#[test]
fn legacy_wrapper_calendar_list_by_range_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = entry_schedule_impl(unique_token("legacy-cal"), 30_000, Some(32_000));
    assert!(response.ok, "{}", response.message);
    let atom_id = response.atom_id.expect("atom id");

    let listed = calendar_list_by_range_impl(29_000, 33_000, Some(50), Some(0));
    assert!(listed.ok, "{}", listed.message);
    assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
}

#[test]
fn legacy_wrapper_notes_list_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let token = unique_token("legacy-notes");
    let created = note_create_impl(token.clone(), None);
    assert!(created.ok, "{}", created.message);
    let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

    let listed = notes_list_impl(None, Some(50), Some(0));
    assert!(listed.ok, "{}", listed.message);
    assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
}

#[test]
fn legacy_wrapper_notes_list_preserves_tags() {
    let _guard = acquire_test_db_lock();
    let token = unique_token("legacy-notes-tags");
    let created = note_create_impl(token.clone(), None);
    assert!(created.ok, "{}", created.message);
    let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

    let tagged = note_set_tags_impl(
        atom_id.clone(),
        vec!["alpha".to_string(), "beta".to_string()],
    );
    assert!(tagged.ok, "{}", tagged.message);

    let listed = notes_list_impl(None, Some(50), Some(0));
    assert!(listed.ok, "{}", listed.message);
    let listed_item = listed
        .items
        .iter()
        .find(|item| item.atom_id == atom_id)
        .expect("listed note");
    assert_eq!(
        listed_item.tags,
        vec!["alpha".to_string(), "beta".to_string()]
    );
}

#[test]
fn legacy_wrapper_entry_search_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let token = unique_token("legacy-search");
    let created = entry_create_note_impl(token.clone());
    assert!(created.ok, "{}", created.message);
    let atom_id = created.atom_id.expect("atom id");

    let searched = entry_search_impl(token, None, Some(50));
    assert!(searched.ok, "{}", searched.message);
    assert!(searched.items.iter().any(|item| item.atom_id == atom_id));
}

#[test]
fn legacy_wrapper_entry_search_preserves_fts_snippet_and_order() {
    let _guard = acquire_test_db_lock();
    let token = unique_token("legacy-search-fts");
    let strong = format!("strong {token} {token} {token}");
    let weak = format!("weak {token}");

    let created_a = entry_create_note_impl(strong);
    assert!(created_a.ok, "{}", created_a.message);
    let created_b = entry_create_note_impl(weak);
    assert!(created_b.ok, "{}", created_b.message);

    let expected_hits = direct_search(&token);
    assert!(expected_hits.len() >= 2, "expected 2 direct hits");

    let searched = entry_search_impl(token, None, Some(50));
    assert!(searched.ok, "{}", searched.message);
    assert!(searched.items.len() >= 2, "expected 2 wrapper hits");

    assert_eq!(
        searched.items[0].atom_id,
        expected_hits[0].atom_id.to_string()
    );
    assert_eq!(searched.items[0].snippet, expected_hits[0].snippet);
}

#[test]
fn legacy_wrapper_atoms_list_timed_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = entry_schedule_impl(unique_token("legacy-timed"), 40_000, Some(41_000));
    assert!(response.ok, "{}", response.message);
    let atom_id = response.atom_id.expect("atom id");

    let listed = atoms_list_timed_impl();
    assert!(listed.ok, "{}", listed.message);
    assert!(listed.items.iter().any(|item| item.atom_id == atom_id));
}

#[test]
fn legacy_wrapper_entry_create_note_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = entry_create_note_impl(unique_token("legacy-create-note"));
    assert!(response.ok, "{}", response.message);
    assert!(response.atom_id.is_some());
    assert!(response.node_uuid.is_some());
}

#[test]
fn legacy_wrapper_entry_create_task_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = entry_create_task_impl(unique_token("legacy-create-task"));
    assert!(response.ok, "{}", response.message);
    assert!(response.atom_id.is_some());
    assert!(response.node_uuid.is_some());
}

#[test]
fn legacy_wrapper_entry_schedule_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = entry_schedule_impl(unique_token("legacy-schedule"), 50_000, Some(51_000));
    assert!(response.ok, "{}", response.message);
    assert!(response.atom_id.is_some());
    assert!(response.node_uuid.is_some());
}

#[test]
fn legacy_wrapper_note_create_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let response = note_create_impl(unique_token("legacy-note-create"), None);
    assert!(response.ok, "{}", response.message);
    assert!(response.item.is_some());
    assert!(response.node_uuid.is_some());
}

#[test]
fn legacy_wrapper_note_update_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let created = note_create_impl("legacy update seed".to_string(), None);
    assert!(created.ok, "{}", created.message);
    let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

    let updated = note_update_impl(atom_id, "legacy update body".to_string());
    assert!(updated.ok, "{}", updated.message);
    assert!(updated
        .item
        .as_ref()
        .expect("updated payload")
        .content
        .contains("legacy update body"));
}

#[test]
fn legacy_wrapper_note_set_tags_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let created = note_create_impl("legacy tags seed".to_string(), None);
    assert!(created.ok, "{}", created.message);
    let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

    let tagged = note_set_tags_impl(atom_id, vec!["Alpha".to_string(), "Beta".to_string()]);
    assert!(tagged.ok, "{}", tagged.message);
    assert_eq!(
        tagged.item.as_ref().expect("tagged payload").tags,
        vec!["alpha".to_string(), "beta".to_string()]
    );
}

#[test]
fn legacy_wrapper_calendar_update_event_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let created = entry_schedule_impl(unique_token("legacy-update-event"), 60_000, Some(61_000));
    assert!(created.ok, "{}", created.message);
    let atom_id = created.atom_id.expect("atom id");

    let updated = calendar_update_event_impl(atom_id.clone(), 62_000, 63_000);
    assert!(updated.ok, "{}", updated.message);
    assert_eq!(updated.atom_id.as_deref(), Some(atom_id.as_str()));
}

#[test]
fn legacy_wrapper_note_get_preserves_contract() {
    let _guard = acquire_test_db_lock();
    let created = note_create_impl("legacy get seed".to_string(), None);
    assert!(created.ok, "{}", created.message);
    let atom_id = created.item.as_ref().expect("note payload").atom_id.clone();

    let loaded = note_get_impl(atom_id.clone());
    assert!(loaded.ok, "{}", loaded.message);
    assert_eq!(
        loaded.item.as_ref().expect("loaded payload").atom_id,
        atom_id
    );
}

#[test]
fn legacy_wrapper_bodies_delegate_to_approved_surfaces() {
    assert_thin_wrapper(
        "fn entry_create_note_impl",
        "atom_create_impl(",
        &["with_creation_service("],
    );
    assert_thin_wrapper(
        "fn entry_create_task_impl",
        "atom_create_impl(",
        &["with_creation_service("],
    );
    assert_thin_wrapper(
        "fn entry_schedule_impl",
        "atom_create_impl(",
        &["with_creation_service("],
    );
    assert_thin_wrapper(
        "fn note_create_impl",
        "atom_create_impl(",
        &["with_creation_service("],
    );
    assert_thin_wrapper(
        "fn note_update_impl",
        "with_guarded_atom_service(",
        &["with_note_service("],
    );
    assert_thin_wrapper(
        "fn note_get_impl",
        "with_guarded_atom_service(",
        &["with_note_service("],
    );
    assert_thin_wrapper(
        "fn note_set_tags_impl",
        "with_guarded_atom_service(",
        &["with_note_service("],
    );
    assert_thin_wrapper(
        "fn calendar_update_event_impl",
        "with_guarded_atom_service(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn atom_update_status_impl",
        "with_guarded_task_service(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn atom_get_impl",
        "with_guarded_atom_service(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn tasks_list_inbox_impl",
        "query_atoms_impl(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn tasks_list_today_impl",
        "query_atoms_impl(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn tasks_list_upcoming_impl",
        "query_atoms_impl(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn atoms_list_timed_impl",
        "query_atoms_impl(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn calendar_list_by_range_impl",
        "query_atoms_impl(",
        &["with_task_service("],
    );
    assert_thin_wrapper(
        "fn notes_list_impl",
        "query_atoms_impl(",
        &["with_note_service("],
    );
    assert_thin_wrapper(
        "fn entry_search_impl",
        "legacy_entry_search_via_fts(",
        &["search_all(", "open_db("],
    );
}
