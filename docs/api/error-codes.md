# Error Codes (v0.1)

This file defines stable error codes that UI should branch on.

## Rules

- Prefer branching by code, not by message text.
- `message` is for display and diagnostics, not control flow.
- New codes must be added here in the same PR.

## Entry Search (FFI)

Producer: `crates/lazynote_ffi/src/api.rs`

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `invalid_kind` | search kind value invalid | blank kind or kind not in `all/note/task/event` | keep input and prompt user to choose supported filter |
| `db_error` | entry DB cannot be opened | invalid path, permissions, IO failure | show inline error, keep input |
| `internal_error` | search execution failed | SQL/FTS query failure | show inline error, keep input |

## Notes/Tags (FFI)

Producer: `crates/lazynote_ffi/src/api.rs`

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `invalid_note_id` | note id format invalid | non-UUID `atom_id` | show validation error, keep input |
| `invalid_tag` | invalid tag value | blank or malformed tag input | show validation error, keep input |
| `note_not_found` | target note missing | stale/deleted id | show not-found state and refresh list |
| `db_busy` | repository/database is temporarily locked | concurrent writer/reader lock contention | show retry affordance and keep user input |
| `db_error` | repository/database failure | sqlite/schema/io issue | show error and allow retry |
| `invalid_argument` | input violates contract | unsupported argument/value | show validation error, keep input |
| `internal_error` | unexpected invariant failure | read-back mismatch or unexpected state | show error and allow retry |

Notes:

- `PR-0205A` (Notes UI shell alignment) is Flutter-only and does not add/change
  any FFI error code.
- `PR-0206` (Notes split layout v1) is Flutter-only and does not add/change
  any FFI error code.
- `PR-0206B` (split pane unsplit/merge follow-up) is Flutter-only and does not
  add/change any FFI error code.

## Command Parser (Flutter)

Producer: `apps/lazynote_flutter/lib/features/entry/command_parser.dart`

| Code | Meaning | Typical Input | UI Handling |
| --- | --- | --- | --- |
| `missing_prefix` | command missing `>` prefix | `new note x` | parse error state |
| `empty_command` | command body is empty | `>` | parse error state |
| `unknown_command` | unsupported command keyword | `> remind x` | parse error state |
| `note_content_empty` | note content missing | `> new note` | parse error state |
| `task_content_empty` | task content missing | `> task` | parse error state |
| `schedule_format_invalid` | schedule input format invalid | `> schedule tomorrow x` | parse error state |
| `schedule_title_empty` | schedule title missing | malformed schedule text | parse error state |
| `schedule_datetime_invalid` | date/time parse failed | invalid date/time values | parse error state |
| `schedule_range_invalid` | range end is not after start | `10:45-09:30` | parse error state |

## Tasks/Status (FFI) — v0.1.5

Producer: `crates/lazynote_ffi/src/api.rs`

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `invalid_atom_id` | atom id format invalid | non-UUID `atom_id` | show validation error |
| `atom_not_found` | target atom missing | stale/deleted id | show not-found state and refresh list |
| `invalid_status` | status value not in allowed set | typo or unsupported status string | show validation error |
| `db_error` | repository/database failure | sqlite/schema/io issue | show error and allow retry |
| `internal_error` | unexpected invariant failure | read-back mismatch or unexpected state | show error and allow retry |

## Calendar (FFI) — PR-0012A

Producer: `crates/lazynote_ffi/src/api.rs`

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `invalid_time_range` | end_at < start_at in event time update | reversed time range input | show validation error |
| `invalid_atom_id` | atom id format invalid | non-UUID `atom_id` | show validation error |
| `atom_not_found` | target atom missing | stale/deleted id | show not-found state and refresh |
| `db_error` | repository/database failure | sqlite/schema/io issue | show error and allow retry |

## Guarded FFI (PR-0411)

Producer: `crates/lazynote_ffi/src/api.rs`

These codes are produced by the new guarded exports such as `query_atoms`,
`atom_create`, `workspace_list`, `workspace_get_default`,
`workspace_resolve_designated`, `workspace_reassign_designated`,
`workspace_get_ancestor_path`, and `workspace_list_atom_refs_for_atom`.

Legacy wrappers retained during the expand stage keep their existing envelopes
and may map guarded failures back into older domain-specific code sets.

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `invalid_workspace_id` | workspace id format invalid | non-UUID `workspace_id` on guarded workspace APIs | show validation error and block request |
| `invalid_node_id` | workspace node id format invalid | non-UUID `node_uuid` or malformed folder target | show validation error and block request |
| `invalid_atom_id` | atom id format invalid | non-UUID `atom_uuid` on guarded atom/ref APIs | show validation error and block request |
| `atom_not_found` | target atom missing | stale/deleted atom id on guarded read/write path | refresh the relevant list/view and show not-found state |
| `invalid_caller_scope` | caller scope format invalid | malformed `scope_workspace_id` in `FfiCallerContext` | treat as programmer/integration error; block request |
| `invalid_target_folder` | requested folder target invalid | malformed `target_folder`, root node used where folder expected, or resolved node not usable as folder target | show validation error and keep input |
| `invalid_query_descriptor` | scoped query descriptor violates contract | missing folder id, invalid range, unsupported filter combination, bad pagination | show validation error and keep current filters |
| `invalid_content_type` | content type unsupported | `content_type` not supported by guarded create path | show validation error and keep input |
| `invalid_tag` | invalid tag value | blank or malformed tag input on guarded note/tag path | show validation error and keep input |
| `invalid_time_range` | event/timed range invalid | `end_at < start_at` on create/update path | show validation error and keep current values |
| `cross_workspace_access_denied` | caller scope does not cover target workspace | guarded request targets a workspace outside declared caller scope | block request and surface access-denied state |
| `insufficient_capability` | caller identity lacks required capability | future/non-noop guard denies read or write capability | block request and surface access-denied state |
| `workspace_not_found` | target workspace missing | stale or unknown `workspace_id` | refresh workspace state and show not-found message |
| `designated_role_not_found` | designated folder mapping missing | workspace has no current mapping for `inbox/tasks/calendar` role | surface setup/state error and allow retry after refresh |
| `target_folder_not_in_workspace` | designated or explicit target folder is outside target workspace | create/reassign request mixes folder/workspace ownership | show validation error and refresh workspace tree |
| `db_error` | repository/database failure | sqlite/schema/io issue | show error and allow retry |
| `internal_error` | unexpected invariant failure | uncategorized guarded-service failure | show error and capture diagnostics |

## Workspace Tree (FFI) - PR-0203 + PR-0221

Producer: `crates/lazynote_ffi/src/api.rs`

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `invalid_node_id` | node id format invalid | non-UUID `node_id` | show validation error and block request |
| `invalid_parent_node_id` | parent node id format invalid | non-UUID `parent_node_id` | show validation error and block request |
| `invalid_atom_id` | atom id format invalid | non-UUID `atom_id` in `workspace_create_note_ref` | show validation error and keep input |
| `invalid_display_name` | display name is blank after trim | empty folder/rename/display text | show validation error and keep input |
| `invalid_delete_mode` | delete mode value is unsupported | value not in `dissolve/delete_all` | show validation error, keep current selection |
| `node_not_found` | target workspace node missing | stale/deleted folder id | refresh tree and show not-found message |
| `parent_not_found` | target parent node missing | stale/deleted `parent_node_id` | refresh tree and retry with updated parent |
| `node_not_folder` | target node is not folder kind | caller passed `note_ref` id | show operation invalid error and refresh tree |
| `parent_not_folder` | target parent is not folder kind | caller passed `note_ref` as parent | show operation invalid error and refresh tree |
| `atom_not_found` | target atom missing | stale/deleted `atom_id` for note ref creation | show not-found error and refresh note list |
| `atom_not_note` | target atom is not note type | passed task/event atom to note_ref API | show validation error and block request |
| `cycle_detected` | move operation would create cycle | moving node under its descendant | show operation invalid error and keep tree unchanged |
| `db_busy` | repository/database temporarily locked | concurrent sqlite lock contention | show retry affordance and keep pending action |
| `db_error` | repository/database failure | sqlite/schema/io issue | show error and allow retry |
| `internal_error` | unexpected invariant failure | unexpected data or service invariant break | show error and capture diagnostics |

## Workspace Tree (Flutter Controller Local) - PR-0221 / PR-0205

Producer: `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `busy` | local action guard rejected operation | user triggered folder create/delete while previous same action is still running | disable repeated action and retry after current operation ends |
| `save_blocked` | pre-delete local draft flush failed | active note has unsaved draft and `flushPendingSave()` returned false | prompt user to retry save or keep editing before delete |

## Diagnostics Log Bridge (FFI) - PR-0210A

Producer: `crates/lazynote_ffi/src/api.rs`

| Code | Meaning | Typical Cause | UI Handling |
| --- | --- | --- | --- |
| `invalid_level` | log level value invalid | level not in `trace/debug/info/warn/error` | show validation error and keep input |
| `invalid_event_name` | event_name invalid | blank or exceeds max length | show validation error and keep input |
| `invalid_module` | module invalid | blank or exceeds max length | show validation error and keep input |
| `invalid_message` | message invalid | blank or exceeds max length | show validation error and keep input |
| `logging_not_initialized` | Rust logging bootstrap unavailable | `init_logging` not called yet in process | show non-fatal diagnostics warning and retry later |

## Reserved Pattern

- Use lowercase snake case.
- Prefix by domain if needed in future:
  - `entry_*`
  - `sync_*`
  - `auth_*`
