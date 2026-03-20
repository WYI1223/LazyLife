use super::*;

/// Lists inbox atoms (both `start_at` and `end_at` NULL).
#[flutter_rust_bridge::frb]
pub async fn tasks_list_inbox(limit: Option<u32>, offset: Option<u32>) -> AtomListResponse {
    tasks_list_inbox_impl(limit, offset)
}

pub(super) fn tasks_list_inbox_impl(limit: Option<u32>, offset: Option<u32>) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Timeless,
        None,
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        false,
        FfiSortSpec::UpdatedAtDesc,
        norm_limit,
        norm_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), norm_limit),
    };

    atom_list_from_scoped_query(
        super::query::query_atoms_impl(
            legacy_default_caller(),
            descriptor,
            FfiProjectionMode::Atom,
        ),
        norm_limit,
        "inbox item(s)",
    )
}

/// Lists atoms active today based on time-matrix rules.
#[flutter_rust_bridge::frb]
pub async fn tasks_list_today(
    bod_ms: i64,
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    tasks_list_today_impl(bod_ms, eod_ms, limit, offset)
}

pub(super) fn tasks_list_today_impl(
    bod_ms: i64,
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(bod_ms),
        Some(eod_ms),
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        true,
        FfiSortSpec::StartAtAsc,
        norm_limit,
        norm_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), norm_limit),
    };

    atom_list_from_scoped_query(
        super::query::query_atoms_impl(
            legacy_default_caller(),
            descriptor,
            FfiProjectionMode::Atom,
        ),
        norm_limit,
        "today item(s)",
    )
}

/// Lists atoms anchored entirely in the future.
#[flutter_rust_bridge::frb]
pub async fn tasks_list_upcoming(
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    tasks_list_upcoming_impl(eod_ms, limit, offset)
}

pub(super) fn tasks_list_upcoming_impl(
    eod_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(eod_ms),
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        false,
        FfiSortSpec::StartAtAsc,
        norm_limit,
        norm_offset,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), norm_limit),
    };

    atom_list_from_scoped_query(
        super::query::query_atoms_impl(
            legacy_default_caller(),
            descriptor,
            FfiProjectionMode::Atom,
        ),
        norm_limit,
        "upcoming item(s)",
    )
}

/// Updates `task_status` for any atom type (universal completion).
#[flutter_rust_bridge::frb]
pub async fn atom_update_status(atom_id: String, status: Option<String>) -> EntryActionResponse {
    atom_update_status_impl(atom_id, status)
}

pub(super) fn atom_update_status_impl(
    atom_id: String,
    status: Option<String>,
) -> EntryActionResponse {
    let parsed_id = match Uuid::parse_str(atom_id.trim()) {
        Ok(id) => id,
        Err(_) => {
            let err = AtomFfiError::InvalidAtomId(atom_id);
            return EntryActionResponse::failure(err.message());
        }
    };

    let parsed_status = match status.as_deref() {
        None => None,
        Some("todo") => Some(lazynote_core::TaskStatus::Todo),
        Some("in_progress") => Some(lazynote_core::TaskStatus::InProgress),
        Some("done") => Some(lazynote_core::TaskStatus::Done),
        Some("cancelled") => Some(lazynote_core::TaskStatus::Cancelled),
        Some(other) => {
            let err = AtomFfiError::InvalidStatus(other.to_string());
            return EntryActionResponse::failure(err.message());
        }
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_task_service(|svc| svc.update_status(&caller, parsed_id, parsed_status)) {
        Ok(()) => EntryActionResponse {
            ok: true,
            atom_id: Some(parsed_id.to_string()),
            node_uuid: None,
            message: "Status updated.".to_string(),
        },
        Err(err) => EntryActionResponse::failure(map_guarded_to_atom_error(err).message()),
    }
}

/// Returns all non-deleted, non-completed atoms that have at least one time field set.
#[flutter_rust_bridge::frb]
pub async fn atoms_list_timed() -> AtomListResponse {
    atoms_list_timed_impl()
}

pub(super) fn atoms_list_timed_impl() -> AtomListResponse {
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(i64::MIN),
        None,
        FfiTimeShapeFilter::Any,
        FfiStatusFilterKind::ActiveOnly,
        None,
        None,
        false,
        FfiSortSpec::UpdatedAtDesc,
        u32::MAX,
        0,
    ) {
        Ok(value) => value,
        Err(err) => return atom_list_failure(map_guarded_to_atom_error(err), 0),
    };
    let response = super::query::query_atoms_impl(
        legacy_default_caller(),
        descriptor,
        FfiProjectionMode::Atom,
    );
    if response.ok {
        let count = response.items.len() as u32;
        AtomListResponse {
            ok: true,
            error_code: None,
            message: format!("Loaded {} timed atom(s).", count),
            items: response
                .items
                .into_iter()
                .map(to_atom_list_item_from_scoped)
                .collect(),
            applied_limit: count,
        }
    } else {
        AtomListResponse {
            ok: false,
            error_code: response.error_code,
            message: response.message,
            items: Vec::new(),
            applied_limit: 0,
        }
    }
}

/// Gets one atom by stable id, regardless of view_hint.
#[flutter_rust_bridge::frb]
pub async fn atom_get(atom_id: String) -> AtomItemResponse {
    atom_get_impl(atom_id)
}

pub(super) fn atom_get_impl(atom_id: String) -> AtomItemResponse {
    let parsed_id = match Uuid::parse_str(atom_id.trim()) {
        Ok(id) => id,
        Err(_) => {
            return AtomItemResponse {
                ok: false,
                error_code: Some("invalid_atom_id".to_string()),
                message: format!("Invalid atom ID: {atom_id}"),
                item: None,
                node_uuid: None,
            };
        }
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|svc| {
        svc.get_atom(&caller, parsed_id)?
            .ok_or(GuardedServiceError::Task(TaskServiceError::AtomNotFound(
                parsed_id,
            )))
    }) {
        Ok(sa) => AtomItemResponse {
            ok: true,
            error_code: None,
            message: "Atom loaded.".to_string(),
            item: Some(to_atom_list_item(sa)),
            node_uuid: None,
        },
        Err(err) => {
            let mapped = map_guarded_to_atom_error(err);
            AtomItemResponse {
                ok: false,
                error_code: Some(mapped.code().to_string()),
                message: mapped.message(),
                item: None,
                node_uuid: None,
            }
        }
    }
}
