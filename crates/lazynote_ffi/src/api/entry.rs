use super::*;

/// Searches single-entry text using entry-level defaults.
///
/// # FFI contract
/// - Async call, DB-backed execution.
/// - Never panics.
/// - Returns deterministic envelope with applied limit.
/// - `kind`: optional `all|note|task|event` (case-insensitive).
/// - Returns `invalid_kind` when `kind` is outside allowed values.
#[flutter_rust_bridge::frb]
pub async fn entry_search(
    text: String,
    kind: Option<String>,
    limit: Option<u32>,
) -> EntrySearchResponse {
    entry_search_impl(text, kind, limit)
}

pub(super) fn entry_search_impl(
    text: String,
    kind: Option<String>,
    limit: Option<u32>,
) -> EntrySearchResponse {
    let normalized_limit = normalize_entry_limit(limit);
    let query_text = text.trim().to_string();
    let parsed_kind = match parse_entry_search_kind(kind) {
        Ok(parsed) => parsed,
        Err(err) => {
            return EntrySearchResponse {
                ok: false,
                error_code: Some("invalid_kind".to_string()),
                items: Vec::new(),
                message: err,
                applied_limit: normalized_limit,
            };
        }
    };
    legacy_entry_search_via_fts(query_text, parsed_kind, normalized_limit)
}

fn parse_entry_search_kind(raw: Option<String>) -> Result<Option<ViewHint>, String> {
    let Some(value) = raw else {
        return Ok(None);
    };
    let normalized = value.trim().to_ascii_lowercase();
    if normalized.is_empty() {
        return Err("invalid kind: blank value is not allowed".to_string());
    }
    if normalized == "all" {
        return Ok(None);
    }
    match normalized.as_str() {
        "note" => Ok(Some(ViewHint::Note)),
        "task" => Ok(Some(ViewHint::Task)),
        "event" => Ok(Some(ViewHint::Event)),
        _ => Err(format!(
            "invalid kind `{value}`; expected one of all|note|task|event"
        )),
    }
}

fn legacy_entry_search_via_fts(
    query_text: String,
    parsed_kind: Option<ViewHint>,
    applied_limit: u32,
) -> EntrySearchResponse {
    let db_path = resolve_entry_db_path();
    let conn = match open_db(&db_path) {
        Ok(conn) => conn,
        Err(err) => {
            return EntrySearchResponse {
                ok: false,
                error_code: Some("db_error".to_string()),
                items: Vec::new(),
                message: format!("entry_search failed: {err}"),
                applied_limit,
            };
        }
    };

    let mut query = SearchQuery::new(query_text);
    query.view_hint = parsed_kind;
    query.limit = applied_limit;

    match search_all(&conn, &query) {
        Ok(hits) => {
            let items = hits
                .into_iter()
                .map(to_entry_search_item_from_hit)
                .collect::<Vec<_>>();
            EntrySearchResponse {
                ok: true,
                error_code: None,
                message: if items.is_empty() {
                    "No results.".to_string()
                } else {
                    format!("Found {} result(s).", items.len())
                },
                items,
                applied_limit,
            }
        }
        Err(err) => EntrySearchResponse {
            ok: false,
            error_code: Some("internal_error".to_string()),
            items: Vec::new(),
            message: format!("entry_search failed: {err}"),
            applied_limit,
        },
    }
}

/// Creates a note from single-entry command flow.
#[flutter_rust_bridge::frb]
pub async fn entry_create_note(content: String) -> EntryActionResponse {
    entry_create_note_impl(content)
}

pub(super) fn entry_create_note_impl(content: String) -> EntryActionResponse {
    let workspace_id = match resolve_legacy_workspace_id(None) {
        Ok(value) => value,
        Err(err) => {
            return EntryActionResponse::failure(format!(
                "entry_create_note failed: {}",
                err.message()
            ));
        }
    };
    let response = super::creation::atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content: content.trim().to_string(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: None,
            display_name: None,
        },
    );
    if response.ok {
        EntryActionResponse::success(
            "Note created.",
            response.atom_uuid.expect("atom uuid"),
            response.node_uuid.expect("node uuid"),
        )
    } else {
        EntryActionResponse::failure(format!("entry_create_note failed: {}", response.message))
    }
}

/// Creates a task from single-entry command flow.
#[flutter_rust_bridge::frb]
pub async fn entry_create_task(content: String) -> EntryActionResponse {
    entry_create_task_impl(content)
}

pub(super) fn entry_create_task_impl(content: String) -> EntryActionResponse {
    let workspace_id = match resolve_legacy_workspace_id(None) {
        Ok(value) => value,
        Err(err) => {
            return EntryActionResponse::failure(format!(
                "entry_create_task failed: {}",
                err.message()
            ));
        }
    };
    let response = super::creation::atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content: content.trim().to_string(),
            content_type: "markdown".to_string(),
            task_status: Some(FfiTaskStatus::Todo),
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: None,
            display_name: None,
        },
    );
    if response.ok {
        EntryActionResponse::success(
            "Task created.",
            response.atom_uuid.expect("atom uuid"),
            response.node_uuid.expect("node uuid"),
        )
    } else {
        EntryActionResponse::failure(format!("entry_create_task failed: {}", response.message))
    }
}

/// Schedules an event from single-entry command flow.
#[flutter_rust_bridge::frb]
pub async fn entry_schedule(
    title: String,
    start_epoch_ms: i64,
    end_epoch_ms: Option<i64>,
) -> EntryActionResponse {
    entry_schedule_impl(title, start_epoch_ms, end_epoch_ms)
}

pub(super) fn entry_schedule_impl(
    title: String,
    start_epoch_ms: i64,
    end_epoch_ms: Option<i64>,
) -> EntryActionResponse {
    let workspace_id = match resolve_legacy_workspace_id(None) {
        Ok(value) => value,
        Err(err) => {
            return EntryActionResponse::failure(format!(
                "entry_schedule failed: {}",
                err.message()
            ));
        }
    };
    let response = super::creation::atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content: title.trim().to_string(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: Some(start_epoch_ms),
            end_at: end_epoch_ms,
            tags: None,
            target_folder: None,
            display_name: None,
        },
    );
    if response.ok {
        EntryActionResponse::success(
            "Event scheduled.",
            response.atom_uuid.expect("atom uuid"),
            response.node_uuid.expect("node uuid"),
        )
    } else {
        EntryActionResponse::failure(format!("entry_schedule failed: {}", response.message))
    }
}
