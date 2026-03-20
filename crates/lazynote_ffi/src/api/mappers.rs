use super::*;

pub(super) fn map_view_hint_filter(value: Option<FfiViewHint>) -> Option<ViewHint> {
    value.map(|hint| match hint {
        FfiViewHint::Note => ViewHint::Note,
        FfiViewHint::Task => ViewHint::Task,
        FfiViewHint::Event => ViewHint::Event,
    })
}

pub(super) fn map_task_status(value: FfiTaskStatus) -> TaskStatus {
    match value {
        FfiTaskStatus::Todo => TaskStatus::Todo,
        FfiTaskStatus::InProgress => TaskStatus::InProgress,
        FfiTaskStatus::Done => TaskStatus::Done,
        FfiTaskStatus::Cancelled => TaskStatus::Cancelled,
    }
}

pub(super) fn map_time_shape(value: FfiTimeShapeFilter) -> TimeShapeFilter {
    match value {
        FfiTimeShapeFilter::Any => TimeShapeFilter::Any,
        FfiTimeShapeFilter::BoundedOnly => TimeShapeFilter::BoundedOnly,
    }
}

pub(super) fn map_sort_spec(value: FfiSortSpec) -> SortSpec {
    match value {
        FfiSortSpec::UpdatedAtDesc => SortSpec::UpdatedAtDesc,
        FfiSortSpec::StartAtAsc => SortSpec::StartAtAsc,
        FfiSortSpec::TitleAsc => SortSpec::TitleAsc,
    }
}

pub(super) fn map_projection_mode(value: FfiProjectionMode) -> ProjectionMode {
    match value {
        FfiProjectionMode::Atom => ProjectionMode::Atom,
        FfiProjectionMode::Ref => ProjectionMode::Ref,
    }
}

pub(super) fn to_scoped_atom_item(item: ScopedAtomResult) -> ScopedAtomItem {
    ScopedAtomItem {
        uuid: item.atom.uuid.to_string(),
        view_hint: view_hint_label(item.atom.view_hint).to_string(),
        title: item.atom.title,
        content_type: item.atom.content_type,
        content: item.atom.content,
        preview_text: item.atom.preview_text,
        preview_image: item.atom.preview_image,
        tags: item.tags,
        task_status: item.atom.task_status.map(|status| {
            match status {
                TaskStatus::Todo => "todo",
                TaskStatus::InProgress => "in_progress",
                TaskStatus::Done => "done",
                TaskStatus::Cancelled => "cancelled",
            }
            .to_string()
        }),
        start_at: item.atom.start_at,
        end_at: item.atom.end_at,
        is_deleted: item.atom.is_deleted,
        updated_at: item.updated_at,
        representative_node_uuid: item.representative_node_uuid.to_string(),
        path: item.path,
    }
}

pub(super) fn to_workspace_info(workspace: WorkspaceMetadata) -> WorkspaceInfo {
    WorkspaceInfo {
        workspace_id: workspace.workspace_id.to_string(),
        name: workspace.name,
        is_default: workspace.is_default,
    }
}

pub(super) fn to_atom_list_item_from_scoped(item: ScopedAtomItem) -> AtomListItem {
    AtomListItem {
        atom_id: item.uuid,
        view_hint: item.view_hint,
        title: item.title,
        content_type: item.content_type,
        content: item.content,
        preview_text: item.preview_text,
        preview_image: item.preview_image,
        tags: item.tags,
        start_at: item.start_at,
        end_at: item.end_at,
        task_status: item.task_status,
        updated_at: item.updated_at,
    }
}

pub(super) fn to_entry_search_item_from_hit(hit: SearchHit) -> EntrySearchItem {
    EntrySearchItem {
        atom_id: hit.atom_id.to_string(),
        view_hint: view_hint_label(hit.view_hint).to_string(),
        title: hit.title,
        snippet: hit.snippet,
    }
}
