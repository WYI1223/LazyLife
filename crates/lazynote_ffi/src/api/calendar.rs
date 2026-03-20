use super::*;

/// Lists atoms with both `start_at` and `end_at` that overlap the given time range.
#[flutter_rust_bridge::frb]
pub async fn calendar_list_by_range(
    start_ms: i64,
    end_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    calendar_list_by_range_impl(start_ms, end_ms, limit, offset)
}

pub(super) fn calendar_list_by_range_impl(
    start_ms: i64,
    end_ms: i64,
    limit: Option<u32>,
    offset: Option<u32>,
) -> AtomListResponse {
    let norm_limit = normalize_section_limit(limit);
    let norm_offset = offset.unwrap_or(0);
    let descriptor = match legacy_root_scoped_query(
        None,
        FfiTimeFilterKind::Range,
        Some(start_ms),
        Some(end_ms),
        FfiTimeShapeFilter::BoundedOnly,
        FfiStatusFilterKind::Any,
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
        "calendar event(s)",
    )
}

/// Updates only `start_at` and `end_at` for a calendar event.
#[flutter_rust_bridge::frb]
pub async fn calendar_update_event(
    atom_id: String,
    start_ms: i64,
    end_ms: i64,
) -> EntryActionResponse {
    calendar_update_event_impl(atom_id, start_ms, end_ms)
}

pub(super) fn calendar_update_event_impl(
    atom_id: String,
    start_ms: i64,
    end_ms: i64,
) -> EntryActionResponse {
    let parsed_id = match Uuid::parse_str(atom_id.trim()) {
        Ok(id) => id,
        Err(_) => {
            let err = AtomFfiError::InvalidAtomId(atom_id);
            return EntryActionResponse::failure(err.message());
        }
    };

    let caller = parse_ffi_caller(legacy_default_caller()).expect("legacy caller");
    match with_guarded_atom_service(|svc| svc.update_time(&caller, parsed_id, start_ms, end_ms)) {
        Ok(()) => EntryActionResponse {
            ok: true,
            atom_id: Some(parsed_id.to_string()),
            node_uuid: None,
            message: "Event times updated.".to_string(),
        },
        Err(err) => EntryActionResponse::failure(map_guarded_to_atom_error(err).message()),
    }
}
