use super::*;

/// Creates one note from markdown content.
#[flutter_rust_bridge::frb]
pub async fn note_create(content: String, parent_node_id: Option<String>) -> AtomItemResponse {
    note_create_impl(content, parent_node_id)
}

pub(super) fn note_create_impl(
    content: String,
    parent_node_id: Option<String>,
) -> AtomItemResponse {
    let parsed_parent = match parse_optional_parent_node_id(parent_node_id) {
        Ok(value) => value,
        Err(err) => {
            return AtomItemResponse {
                ok: false,
                error_code: Some(err.code().to_string()),
                message: err.message().to_string(),
                item: None,
                node_uuid: None,
            };
        }
    };
    let workspace_id = match resolve_legacy_workspace_id(parsed_parent) {
        Ok(value) => value,
        Err(err) => {
            return AtomItemResponse {
                ok: false,
                error_code: Some("creation_failed".to_string()),
                message: format!("note_create failed: {}", err.message()),
                item: None,
                node_uuid: None,
            };
        }
    };
    let response = super::creation::atom_create_impl(
        legacy_default_caller(),
        FfiCreateAtomRequest {
            workspace_id,
            content,
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: parsed_parent.map(|value| value.to_string()),
            display_name: None,
        },
    );
    if response.ok {
        let atom_id = response.atom_uuid.expect("atom uuid");
        let loaded = note_get_impl(atom_id);
        AtomItemResponse {
            ok: loaded.ok,
            error_code: loaded.error_code,
            message: if loaded.ok {
                "Note created.".to_string()
            } else {
                loaded.message
            },
            item: loaded.item,
            node_uuid: response.node_uuid,
        }
    } else {
        AtomItemResponse {
            ok: false,
            error_code: Some("creation_failed".to_string()),
            message: format!("note_create failed: {}", response.message),
            item: None,
            node_uuid: None,
        }
    }
}

/// Fully replaces note content by stable id.
#[flutter_rust_bridge::frb]
pub async fn note_update(atom_id: String, content: String) -> AtomItemResponse {
    note_update_impl(atom_id, content)
}

pub(super) fn note_update_impl(atom_id: String, content: String) -> AtomItemResponse {
    let parsed_id = match parse_note_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return note_failure(err),
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|service| service.update_content(&caller, parsed_id, content)) {
        Ok(note) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Note updated.".to_string(),
            item: Some(to_atom_list_item_from_note(note)),
            node_uuid: None,
        },
        Err(err) => note_failure(map_guarded_to_notes_error(err)),
    }
}

/// Gets one note by stable id.
#[flutter_rust_bridge::frb]
pub async fn note_get(atom_id: String) -> AtomItemResponse {
    note_get_impl(atom_id)
}

pub(super) fn note_get_impl(atom_id: String) -> AtomItemResponse {
    let parsed_id = match parse_note_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return note_failure(err),
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|service| {
        service
            .get_note(&caller, parsed_id)?
            .ok_or(GuardedServiceError::Note(NoteServiceError::NoteNotFound(
                parsed_id,
            )))
    }) {
        Ok(note) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Note loaded.".to_string(),
            item: Some(to_atom_list_item_from_note(note)),
            node_uuid: None,
        },
        Err(err) => note_failure(map_guarded_to_notes_error(err)),
    }
}

/// Lists notes with optional single-tag filter and pagination.
#[flutter_rust_bridge::frb]
pub async fn notes_list(
    tag: Option<String>,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    notes_list_impl(tag, limit, offset)
}

pub(super) fn notes_list_impl(
    tag: Option<String>,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let resolved_offset = offset.unwrap_or(0);
    let applied_limit = lazynote_core::normalize_note_limit(limit);
    let normalized_tag = match tag {
        Some(value) => {
            let trimmed = value.trim();
            if trimmed.is_empty() {
                return AtomListResponse {
                    ok: false,
                    error_code: Some("invalid_tag".to_string()),
                    message: format!("invalid tag: {value}"),
                    items: Vec::new(),
                    applied_limit,
                };
            }
            Some(trimmed.to_ascii_lowercase())
        }
        None => None,
    };
    let descriptor = match legacy_root_scoped_query(
        Some(FfiViewHint::Note),
        FfiTimeFilterKind::Any,
        None,
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::Any,
        normalized_tag,
        None,
        false,
        FfiSortSpec::UpdatedAtDesc,
        applied_limit,
        resolved_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), applied_limit),
    };

    atom_list_from_scoped_query(
        super::query::query_atoms_impl(
            legacy_default_caller(),
            descriptor,
            FfiProjectionMode::Atom,
        ),
        applied_limit,
        "note(s)",
    )
}

/// Atomically replaces full tag set for one note.
#[flutter_rust_bridge::frb]
pub async fn note_set_tags(atom_id: String, tags: Vec<String>) -> AtomItemResponse {
    note_set_tags_impl(atom_id, tags)
}

pub(super) fn note_set_tags_impl(atom_id: String, tags: Vec<String>) -> AtomItemResponse {
    let parsed_id = match parse_note_id(atom_id.as_str()) {
        Ok(value) => value,
        Err(err) => return note_failure(err),
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|service| service.set_tags(&caller, parsed_id, tags)) {
        Ok(note) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Note tags replaced.".to_string(),
            item: Some(to_atom_list_item_from_note(note)),
            node_uuid: None,
        },
        Err(err) => note_failure(map_guarded_to_notes_error(err)),
    }
}

/// Lists normalized tags known by storage.
#[flutter_rust_bridge::frb]
pub async fn tags_list() -> TagsListResponse {
    tags_list_impl()
}

pub(super) fn tags_list_impl() -> TagsListResponse {
    match with_note_service(|service| service.list_tags().map_err(NoteServiceError::from)) {
        Ok(tags) => TagsListResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} tag(s).", tags.len()),
            tags,
        },
        Err(err) => TagsListResponse {
            ok: false,
            error_code: Some(err.code().to_string()),
            message: err.message(),
            tags: Vec::new(),
        },
    }
}

fn note_failure(error: NotesFfiError) -> AtomItemResponse {
    AtomItemResponse {
        ok: false,
        error_code: Some(error.code().to_string()),
        message: error.message(),
        item: None,
        node_uuid: None,
    }
}
