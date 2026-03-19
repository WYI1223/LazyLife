//! Scoped query repository for workspace-subtree atom reads.
//!
//! # Responsibility
//! - Provide one read-only query surface for subtree-scoped atom queries.
//! - Keep recursive-scope SQL and filter composition inside repository layer.

use crate::db::migrations::latest_version;
use crate::db::DbError;
use crate::model::atom::{Atom, AtomId, TaskStatus, ViewHint};
use crate::repo::atom_repo::{parse_atom_row, RepoError};
use crate::repo::tree_repo::WorkspaceNodeId;
use rusqlite::types::Value;
use rusqlite::{params, params_from_iter, Connection, OptionalExtension};
use std::collections::{HashMap, HashSet};
use std::error::Error;
use std::fmt::{Display, Formatter};
use uuid::Uuid;

/// Query descriptor for subtree-scoped atom reads.
#[derive(Debug, Clone)]
pub struct ScopedAtomQuery {
    /// Folder or workspace-root node that bounds the query subtree.
    pub folder_id: WorkspaceNodeId,
    /// Optional view-hint filter.
    pub view_hint: Option<ViewHint>,
    /// Time filter semantics.
    pub time_filter: TimeFilter,
    /// Optional time-shape restriction.
    pub time_shape: TimeShapeFilter,
    /// Optional task-status restriction.
    pub status_filter: StatusFilter,
    /// Optional normalized tag filter.
    pub tag: Option<String>,
    /// Optional FTS text query filter.
    pub text_query: Option<String>,
    /// Whether returned rows should include a folder path.
    pub include_path: bool,
    /// Whether overdue T1 deadlines should be unioned into range results.
    pub include_overdue_deadlines: bool,
    /// Deterministic sort rule.
    pub sort: SortSpec,
    /// Page size.
    pub limit: u32,
    /// Page offset.
    pub offset: u32,
}

/// Time filter descriptor.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TimeFilter {
    /// No time filtering.
    Any,
    /// Both `start_at` and `end_at` are `NULL`.
    Timeless,
    /// Range overlap (`end_ms=Some`) or anchor-forward (`end_ms=None`) semantics.
    Range { start_ms: i64, end_ms: Option<i64> },
}

/// Restricts which time-shape variants are returned.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TimeShapeFilter {
    /// No time-shape filtering.
    Any,
    /// Requires both `start_at` and `end_at` to be non-null.
    BoundedOnly,
}

/// Restricts task status values.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StatusFilter {
    /// No status filter.
    Any,
    /// Excludes `done` and `cancelled`.
    ActiveOnly,
    /// Includes only the provided statuses.
    TaskStatuses(Vec<TaskStatus>),
}

/// Output sort rule.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SortSpec {
    /// Newest updates first.
    UpdatedAtDesc,
    /// Earliest time anchor first.
    StartAtAsc,
    /// Case-insensitive title ascending.
    TitleAsc,
}

/// Output projection mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProjectionMode {
    /// Deduplicate by atom within the subtree.
    Atom,
    /// Return one row per `atom_ref`.
    Ref,
}

/// One scoped-query result row.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScopedAtomResult {
    /// Representative ref node for this result.
    pub representative_node_uuid: WorkspaceNodeId,
    /// Parsed canonical atom.
    pub atom: Atom,
    /// Normalized lowercase tags for this atom.
    pub tags: Vec<String>,
    /// Optional folder path from subtree root to direct parent folder.
    pub path: Option<String>,
    /// Atom `updated_at` in epoch ms.
    pub updated_at: i64,
}

/// Scoped query repository error.
#[derive(Debug)]
pub enum ScopedQueryError {
    /// Descriptor contains an invalid parameter combination.
    InvalidQueryDescriptor(String),
    /// Underlying repository/bootstrap error.
    Repo(RepoError),
}

impl Display for ScopedQueryError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidQueryDescriptor(message) => write!(f, "{message}"),
            Self::Repo(err) => write!(f, "{err}"),
        }
    }
}

impl Error for ScopedQueryError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::InvalidQueryDescriptor(_) => None,
            Self::Repo(err) => Some(err),
        }
    }
}

impl From<RepoError> for ScopedQueryError {
    fn from(value: RepoError) -> Self {
        Self::Repo(value)
    }
}

impl From<DbError> for ScopedQueryError {
    fn from(value: DbError) -> Self {
        Self::Repo(RepoError::Db(value))
    }
}

impl From<rusqlite::Error> for ScopedQueryError {
    fn from(value: rusqlite::Error) -> Self {
        Self::Repo(RepoError::from(value))
    }
}

/// Read-only repository interface for scoped subtree queries.
pub trait ScopedQueryRepository {
    /// Executes one subtree-scoped atom query.
    fn query_scoped_atoms(
        &self,
        query: ScopedAtomQuery,
        projection: ProjectionMode,
    ) -> Result<Vec<ScopedAtomResult>, ScopedQueryError>;
}

/// SQLite-backed scoped query repository.
pub struct SqliteScopedQueryRepository<'conn> {
    conn: &'conn Connection,
}

impl<'conn> SqliteScopedQueryRepository<'conn> {
    /// Creates repository from a migrated connection.
    pub fn try_new(conn: &'conn Connection) -> Result<Self, ScopedQueryError> {
        ensure_connection_ready(conn)?;
        Ok(Self { conn })
    }
}

impl ScopedQueryRepository for SqliteScopedQueryRepository<'_> {
    fn query_scoped_atoms(
        &self,
        mut query: ScopedAtomQuery,
        projection: ProjectionMode,
    ) -> Result<Vec<ScopedAtomResult>, ScopedQueryError> {
        normalize_descriptor(&mut query)?;
        ensure_scope_root_exists(self.conn, query.folder_id)?;

        let built = build_query_sql(&query, projection);
        let mut stmt = self.conn.prepare(&built.sql)?;
        let mut rows = stmt.query(params_from_iter(built.bind_values))?;
        let mut pending_results = Vec::new();

        while let Some(row) = rows.next()? {
            let representative_node_uuid_text: String = row.get("representative_node_uuid")?;
            let representative_node_uuid = parse_uuid(
                &representative_node_uuid_text,
                "query.representative_node_uuid",
            )?;
            let atom = parse_atom_row(row)?;
            let updated_at: i64 = row.get("updated_at")?;
            pending_results.push(ScopedAtomResult {
                representative_node_uuid,
                atom,
                tags: Vec::new(),
                path: row.get("path")?,
                updated_at,
            });
        }

        let tags_by_atom =
            load_tags_for_atoms(self.conn, pending_results.iter().map(|item| item.atom.uuid))?;
        let results = pending_results
            .into_iter()
            .map(|mut item| {
                item.tags = tags_by_atom
                    .get(&item.atom.uuid)
                    .cloned()
                    .unwrap_or_default();
                item
            })
            .collect();

        Ok(results)
    }
}

struct BuiltQuery {
    sql: String,
    bind_values: Vec<Value>,
}

fn build_query_sql(query: &ScopedAtomQuery, projection: ProjectionMode) -> BuiltQuery {
    let mut bind_values = vec![
        Value::Text(query.folder_id.to_string()),
        Value::Integer(bool_to_int(query.include_path)),
    ];

    let filter_sql = build_filter_sql(query, &mut bind_values);

    let mut sql = String::from(
        "WITH RECURSIVE subtree(node_uuid, kind, atom_uuid, depth, path) AS (
            SELECT
                node_uuid,
                kind,
                atom_uuid,
                0 AS depth,
                CASE
                    WHEN kind = 'folder' THEN display_name
                    ELSE CAST(NULL AS TEXT)
                END AS path
            FROM workspace_nodes
            WHERE node_uuid = ?
              AND is_deleted = 0
              AND kind IN ('folder', 'workspace')
            UNION ALL
            SELECT
                child.node_uuid,
                child.kind,
                child.atom_uuid,
                parent.depth + 1,
                CASE
                    WHEN child.kind = 'folder' THEN
                        CASE
                            WHEN parent.path IS NULL THEN child.display_name
                            ELSE parent.path || '/' || child.display_name
                        END
                    WHEN child.kind = 'atom_ref' THEN parent.path
                    ELSE parent.path
                END
            FROM workspace_nodes child
            JOIN subtree parent ON child.parent_uuid = parent.node_uuid
            WHERE child.is_deleted = 0
        ),
        scope_refs AS (
            SELECT
                node_uuid AS representative_node_uuid,
                atom_uuid,
                depth,
                CASE
                    WHEN ? = 1 THEN path
                    ELSE NULL
                END AS path
            FROM subtree
            WHERE kind = 'atom_ref'
              AND atom_uuid IS NOT NULL
        ),
        filtered AS (",
    );
    sql.push_str(&filter_sql.main_select_sql);
    if let Some(overdue_sql) = filter_sql.overdue_union_sql {
        sql.push_str(" UNION ALL ");
        sql.push_str(&overdue_sql);
    }
    sql.push(')');

    match projection {
        ProjectionMode::Atom => {
            sql.push_str(
                " , ranked AS (
                    SELECT
                        filtered.*,
                        ROW_NUMBER() OVER (
                            PARTITION BY uuid
                            ORDER BY depth ASC, representative_node_uuid ASC
                        ) AS rn
                    FROM filtered
                )
                SELECT
                    representative_node_uuid,
                    path,
                    uuid,
                    view_hint,
                    title,
                    content_type,
                    content,
                    preview_text,
                    preview_image,
                    task_status,
                    start_at,
                    end_at,
                    recurrence_rule,
                    hlc_timestamp,
                    is_deleted,
                    updated_at
                FROM ranked
                WHERE rn = 1",
            );
        }
        ProjectionMode::Ref => {
            sql.push_str(
                " SELECT
                    representative_node_uuid,
                    path,
                    uuid,
                    view_hint,
                    title,
                    content_type,
                    content,
                    preview_text,
                    preview_image,
                    task_status,
                    start_at,
                    end_at,
                    recurrence_rule,
                    hlc_timestamp,
                    is_deleted,
                    updated_at
                FROM filtered",
            );
        }
    }

    sql.push_str(" ORDER BY ");
    sql.push_str(sort_sql(query.sort));
    if matches!(projection, ProjectionMode::Ref) {
        sql.push_str(", representative_node_uuid ASC");
    }
    sql.push_str(" LIMIT ? OFFSET ?");
    bind_values.push(Value::Integer(i64::from(query.limit)));
    bind_values.push(Value::Integer(i64::from(query.offset)));

    BuiltQuery { sql, bind_values }
}

struct FilterSql {
    main_select_sql: String,
    overdue_union_sql: Option<String>,
}

fn build_filter_sql(query: &ScopedAtomQuery, bind_values: &mut Vec<Value>) -> FilterSql {
    let mut where_clauses = vec!["atoms.is_deleted = 0".to_string()];
    let mut join_clauses = Vec::new();

    if let Some(view_hint) = query.view_hint {
        where_clauses.push("atoms.view_hint = ?".to_string());
        bind_values.push(Value::Text(view_hint_to_db(view_hint).to_string()));
    }

    match query.time_shape {
        TimeShapeFilter::Any => {}
        TimeShapeFilter::BoundedOnly => {
            where_clauses
                .push("atoms.start_at IS NOT NULL AND atoms.end_at IS NOT NULL".to_string());
        }
    }

    push_time_filter_clauses(&query.time_filter, &mut where_clauses, bind_values);
    push_status_filter_clauses(
        &query.status_filter,
        "atoms",
        &mut where_clauses,
        bind_values,
    );

    if let Some(tag) = &query.tag {
        where_clauses.push(
            "EXISTS (
                SELECT 1
                FROM atom_tags
                JOIN tags ON tags.id = atom_tags.tag_id
                WHERE atom_tags.atom_uuid = atoms.uuid
                  AND tags.name = ?
            )"
            .to_string(),
        );
        bind_values.push(Value::Text(tag.clone()));
    }

    if let Some(text_query) = &query.text_query {
        join_clauses.push("JOIN atoms_fts ON atoms_fts.rowid = atoms.rowid".to_string());
        where_clauses.push("atoms_fts MATCH ?".to_string());
        bind_values.push(Value::Text(text_query.clone()));
    }

    let mut main_select_sql = String::from(
        "SELECT
            scope_refs.representative_node_uuid,
            scope_refs.depth,
            scope_refs.path,
            atoms.uuid AS uuid,
            atoms.view_hint AS view_hint,
            atoms.title AS title,
            atoms.content_type AS content_type,
            atoms.content AS content,
            atoms.preview_text AS preview_text,
            atoms.preview_image AS preview_image,
            atoms.task_status AS task_status,
            atoms.start_at AS start_at,
            atoms.end_at AS end_at,
            atoms.recurrence_rule AS recurrence_rule,
            atoms.hlc_timestamp AS hlc_timestamp,
            atoms.is_deleted AS is_deleted,
            atoms.updated_at AS updated_at
        FROM scope_refs
        JOIN atoms ON atoms.uuid = scope_refs.atom_uuid",
    );
    for join in &join_clauses {
        main_select_sql.push(' ');
        main_select_sql.push_str(join);
    }
    main_select_sql.push_str(" WHERE ");
    main_select_sql.push_str(&where_clauses.join(" AND "));

    let overdue_union_sql = build_overdue_union_sql(query, &join_clauses, bind_values);
    FilterSql {
        main_select_sql,
        overdue_union_sql,
    }
}

fn build_overdue_union_sql(
    query: &ScopedAtomQuery,
    join_clauses: &[String],
    bind_values: &mut Vec<Value>,
) -> Option<String> {
    if !query.include_overdue_deadlines {
        return None;
    }

    let TimeFilter::Range { start_ms, .. } = query.time_filter else {
        return None;
    };

    let mut where_clauses = vec![
        "atoms.is_deleted = 0".to_string(),
        "atoms.start_at IS NULL".to_string(),
        "atoms.end_at IS NOT NULL".to_string(),
        "atoms.end_at < ?".to_string(),
    ];
    bind_values.push(Value::Integer(start_ms));

    match query.time_shape {
        TimeShapeFilter::Any => {}
        TimeShapeFilter::BoundedOnly => {
            where_clauses.push("1 = 0".to_string());
        }
    }

    if let Some(view_hint) = query.view_hint {
        where_clauses.push("atoms.view_hint = ?".to_string());
        bind_values.push(Value::Text(view_hint_to_db(view_hint).to_string()));
    }

    push_status_filter_clauses(
        &query.status_filter,
        "atoms",
        &mut where_clauses,
        bind_values,
    );

    if let Some(tag) = &query.tag {
        where_clauses.push(
            "EXISTS (
                SELECT 1
                FROM atom_tags
                JOIN tags ON tags.id = atom_tags.tag_id
                WHERE atom_tags.atom_uuid = atoms.uuid
                  AND tags.name = ?
            )"
            .to_string(),
        );
        bind_values.push(Value::Text(tag.clone()));
    }

    if let Some(text_query) = &query.text_query {
        where_clauses.push("atoms_fts MATCH ?".to_string());
        bind_values.push(Value::Text(text_query.clone()));
    }

    let mut sql = String::from(
        "SELECT
            scope_refs.representative_node_uuid,
            scope_refs.depth,
            scope_refs.path,
            atoms.uuid AS uuid,
            atoms.view_hint AS view_hint,
            atoms.title AS title,
            atoms.content_type AS content_type,
            atoms.content AS content,
            atoms.preview_text AS preview_text,
            atoms.preview_image AS preview_image,
            atoms.task_status AS task_status,
            atoms.start_at AS start_at,
            atoms.end_at AS end_at,
            atoms.recurrence_rule AS recurrence_rule,
            atoms.hlc_timestamp AS hlc_timestamp,
            atoms.is_deleted AS is_deleted,
            atoms.updated_at AS updated_at
        FROM scope_refs
        JOIN atoms ON atoms.uuid = scope_refs.atom_uuid",
    );
    for join in join_clauses {
        sql.push(' ');
        sql.push_str(join);
    }
    sql.push_str(" WHERE ");
    sql.push_str(&where_clauses.join(" AND "));
    Some(sql)
}

fn push_time_filter_clauses(
    time_filter: &TimeFilter,
    where_clauses: &mut Vec<String>,
    bind_values: &mut Vec<Value>,
) {
    match time_filter {
        TimeFilter::Any => {}
        TimeFilter::Timeless => {
            where_clauses.push("atoms.start_at IS NULL AND atoms.end_at IS NULL".to_string());
        }
        TimeFilter::Range { start_ms, end_ms } => match end_ms {
            Some(end_ms) => {
                where_clauses.push(
                    "(
                        (atoms.start_at IS NULL AND atoms.end_at IS NOT NULL AND atoms.end_at >= ?)
                        OR (atoms.start_at IS NOT NULL AND atoms.end_at IS NULL AND atoms.start_at < ?)
                        OR (atoms.start_at IS NOT NULL AND atoms.end_at IS NOT NULL
                            AND atoms.start_at < ? AND atoms.end_at >= ?)
                    )"
                    .to_string(),
                );
                bind_values.push(Value::Integer(*start_ms));
                bind_values.push(Value::Integer(*end_ms));
                bind_values.push(Value::Integer(*end_ms));
                bind_values.push(Value::Integer(*start_ms));
            }
            None => {
                where_clauses.push(
                    "(
                        (atoms.start_at IS NULL AND atoms.end_at IS NOT NULL AND atoms.end_at >= ?)
                        OR (atoms.start_at IS NOT NULL AND atoms.end_at IS NULL AND atoms.start_at >= ?)
                        OR (atoms.start_at IS NOT NULL AND atoms.end_at IS NOT NULL AND atoms.start_at >= ?)
                    )"
                    .to_string(),
                );
                bind_values.push(Value::Integer(*start_ms));
                bind_values.push(Value::Integer(*start_ms));
                bind_values.push(Value::Integer(*start_ms));
            }
        },
    }
}

fn push_status_filter_clauses(
    status_filter: &StatusFilter,
    atom_alias: &str,
    where_clauses: &mut Vec<String>,
    bind_values: &mut Vec<Value>,
) {
    match status_filter {
        StatusFilter::Any => {}
        StatusFilter::ActiveOnly => {
            where_clauses.push(format!(
                "({atom_alias}.task_status IS NULL OR {atom_alias}.task_status NOT IN ('done', 'cancelled'))"
            ));
        }
        StatusFilter::TaskStatuses(statuses) => {
            let placeholders = vec!["?"; statuses.len()].join(", ");
            where_clauses.push(format!("{atom_alias}.task_status IN ({placeholders})"));
            for status in statuses {
                bind_values.push(Value::Text(task_status_to_db(*status).to_string()));
            }
        }
    }
}

fn sort_sql(sort: SortSpec) -> &'static str {
    match sort {
        SortSpec::UpdatedAtDesc => "updated_at DESC, uuid ASC",
        SortSpec::StartAtAsc => "COALESCE(start_at, end_at) ASC, updated_at DESC, uuid ASC",
        SortSpec::TitleAsc => "LOWER(title) ASC, updated_at DESC, uuid ASC",
    }
}

fn normalize_descriptor(query: &mut ScopedAtomQuery) -> Result<(), ScopedQueryError> {
    query.tag = query.tag.take().and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.to_ascii_lowercase())
        }
    });

    query.text_query = query.text_query.take().and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.to_string())
        }
    });

    if query.include_overdue_deadlines
        && !matches!(
            query.time_filter,
            TimeFilter::Range {
                end_ms: Some(_),
                ..
            }
        )
    {
        return Err(ScopedQueryError::InvalidQueryDescriptor(
            "include_overdue_deadlines requires TimeFilter::Range with end_ms".to_string(),
        ));
    }

    if let StatusFilter::TaskStatuses(statuses) = &query.status_filter {
        if statuses.is_empty() {
            return Err(ScopedQueryError::InvalidQueryDescriptor(
                "TaskStatuses must not be empty".to_string(),
            ));
        }
    }

    Ok(())
}

fn ensure_scope_root_exists(
    conn: &Connection,
    folder_id: WorkspaceNodeId,
) -> Result<(), ScopedQueryError> {
    let kind: Option<String> = conn
        .query_row(
            "SELECT kind
             FROM workspace_nodes
             WHERE node_uuid = ?1
               AND is_deleted = 0;",
            [folder_id.to_string()],
            |row| row.get(0),
        )
        .optional()?;

    match kind.as_deref() {
        Some("folder") | Some("workspace") => Ok(()),
        Some(other) => Err(ScopedQueryError::InvalidQueryDescriptor(format!(
            "folder_id must reference an active folder or workspace root, got `{other}`"
        ))),
        None => Err(ScopedQueryError::InvalidQueryDescriptor(format!(
            "folder_id `{folder_id}` does not reference an active folder or workspace root"
        ))),
    }
}

fn ensure_connection_ready(conn: &Connection) -> Result<(), ScopedQueryError> {
    let expected_version = latest_version();
    let actual_version: u32 = conn.query_row("PRAGMA user_version;", [], |row| row.get(0))?;
    if actual_version != expected_version {
        return Err(RepoError::UninitializedConnection {
            expected_version,
            actual_version,
        }
        .into());
    }

    for table in ["atoms", "workspace_nodes", "tags", "atom_tags"] {
        if !table_exists(conn, table)? {
            return Err(RepoError::MissingRequiredTable(table).into());
        }
    }

    for (table, column) in [
        ("atoms", "uuid"),
        ("atoms", "view_hint"),
        ("atoms", "task_status"),
        ("atoms", "start_at"),
        ("atoms", "end_at"),
        ("atoms", "updated_at"),
        ("workspace_nodes", "node_uuid"),
        ("workspace_nodes", "kind"),
        ("workspace_nodes", "parent_uuid"),
        ("workspace_nodes", "atom_uuid"),
        ("workspace_nodes", "display_name"),
        ("workspace_nodes", "is_deleted"),
    ] {
        if !table_has_column(conn, table, column)? {
            return Err(RepoError::MissingRequiredColumn { table, column }.into());
        }
    }

    Ok(())
}

fn table_exists(conn: &Connection, table: &'static str) -> Result<bool, ScopedQueryError> {
    let exists: i64 = conn.query_row(
        "SELECT EXISTS(
            SELECT 1
            FROM sqlite_master
            WHERE type = 'table'
              AND name = ?1
        );",
        params![table],
        |row| row.get(0),
    )?;
    Ok(exists == 1)
}

fn table_has_column(
    conn: &Connection,
    table: &'static str,
    column: &'static str,
) -> Result<bool, ScopedQueryError> {
    let mut stmt = conn.prepare(&format!("PRAGMA table_info({table});"))?;
    let mut rows = stmt.query([])?;
    while let Some(row) = rows.next()? {
        let current: String = row.get(1)?;
        if current == column {
            return Ok(true);
        }
    }
    Ok(false)
}

fn parse_uuid(value: &str, column: &'static str) -> Result<Uuid, ScopedQueryError> {
    Uuid::parse_str(value).map_err(|_| {
        ScopedQueryError::Repo(RepoError::InvalidData(format!(
            "invalid uuid `{value}` in {column}"
        )))
    })
}

fn load_tags_for_atoms<I>(
    conn: &Connection,
    atom_ids: I,
) -> Result<HashMap<AtomId, Vec<String>>, ScopedQueryError>
where
    I: IntoIterator<Item = AtomId>,
{
    let mut ordered_atom_ids = Vec::new();
    let mut seen_atom_ids = HashSet::new();
    for atom_id in atom_ids {
        let atom_id_text = atom_id.to_string();
        if seen_atom_ids.insert(atom_id_text.clone()) {
            ordered_atom_ids.push(atom_id_text);
        }
    }

    if ordered_atom_ids.is_empty() {
        return Ok(HashMap::new());
    }

    let placeholders = (1..=ordered_atom_ids.len())
        .map(|index| format!("?{index}"))
        .collect::<Vec<_>>()
        .join(", ");
    let sql = format!(
        "SELECT atom_tags.atom_uuid, tags.name
         FROM atom_tags
         JOIN tags ON tags.id = atom_tags.tag_id
         WHERE atom_tags.atom_uuid IN ({placeholders})
         ORDER BY atom_tags.atom_uuid ASC, tags.name ASC;"
    );
    let bind_values = ordered_atom_ids.into_iter().map(Value::Text);
    let mut stmt = conn.prepare(&sql)?;
    let mut rows = stmt.query(params_from_iter(bind_values))?;
    let mut tags_by_atom = HashMap::new();
    while let Some(row) = rows.next()? {
        let atom_uuid_text: String = row.get(0)?;
        let atom_uuid = parse_uuid(&atom_uuid_text, "atom_tags.atom_uuid")?;
        let tag: String = row.get(1)?;
        tags_by_atom
            .entry(atom_uuid)
            .or_insert_with(Vec::new)
            .push(tag);
    }
    Ok(tags_by_atom)
}

fn bool_to_int(value: bool) -> i64 {
    if value {
        1
    } else {
        0
    }
}

fn view_hint_to_db(hint: ViewHint) -> &'static str {
    match hint {
        ViewHint::Note => "note",
        ViewHint::Task => "task",
        ViewHint::Event => "event",
    }
}

#[cfg(test)]
mod tests {
    use super::{
        build_query_sql, ProjectionMode, ScopedAtomQuery, SortSpec, StatusFilter, TimeFilter,
        TimeShapeFilter,
    };
    use uuid::Uuid;

    fn sample_query(sort: SortSpec) -> ScopedAtomQuery {
        ScopedAtomQuery {
            folder_id: Uuid::parse_str("11111111-1111-4111-8111-111111111111").unwrap(),
            view_hint: None,
            time_filter: TimeFilter::Any,
            time_shape: TimeShapeFilter::Any,
            status_filter: StatusFilter::Any,
            tag: None,
            text_query: None,
            include_path: false,
            include_overdue_deadlines: false,
            sort,
            limit: 20,
            offset: 0,
        }
    }

    fn function_source(signature: &str) -> &'static str {
        let source = include_str!("scoped_query_repo.rs");
        let start = source
            .rfind(signature)
            .unwrap_or_else(|| panic!("signature `{signature}` not found"));
        let tail = &source[start..];

        let body_start = tail
            .find('{')
            .unwrap_or_else(|| panic!("function `{signature}` has no body"));
        let mut depth = 0usize;
        for (index, ch) in tail[body_start..].char_indices() {
            match ch {
                '{' => depth += 1,
                '}' => {
                    depth -= 1;
                    if depth == 0 {
                        return &tail[..body_start + index + 1];
                    }
                }
                _ => {}
            }
        }

        panic!("function `{signature}` body did not terminate");
    }

    #[test]
    fn ref_projection_sort_adds_representative_node_uuid_tie_breaker() {
        let updated_sql =
            build_query_sql(&sample_query(SortSpec::UpdatedAtDesc), ProjectionMode::Ref).sql;
        assert!(updated_sql
            .contains("ORDER BY updated_at DESC, uuid ASC, representative_node_uuid ASC"));

        let start_sql =
            build_query_sql(&sample_query(SortSpec::StartAtAsc), ProjectionMode::Ref).sql;
        assert!(start_sql.contains(
            "ORDER BY COALESCE(start_at, end_at) ASC, updated_at DESC, uuid ASC, representative_node_uuid ASC"
        ));

        let title_sql = build_query_sql(&sample_query(SortSpec::TitleAsc), ProjectionMode::Ref).sql;
        assert!(title_sql.contains(
            "ORDER BY LOWER(title) ASC, updated_at DESC, uuid ASC, representative_node_uuid ASC"
        ));
    }

    #[test]
    fn query_scoped_atoms_batches_tag_loading_outside_row_loop() {
        let source = function_source("fn query_scoped_atoms(");
        let loop_start = source
            .find("while let Some(row) = rows.next()?")
            .expect("row loop must exist");
        let batched_lookup_start = source
            .find("let tags_by_atom =")
            .expect("batched tag lookup must exist");
        let between = &source[loop_start..batched_lookup_start];
        assert!(
            source.contains("load_tags_for_atoms("),
            "expected batched tag lookup to exist"
        );
        assert!(
            !between.contains("load_tags_for_atom("),
            "expected row loop region to avoid per-row tag lookups"
        );
        assert!(
            !between.contains("load_tags_for_atoms("),
            "expected batched tag lookup to occur after the row loop"
        );
    }
}

fn task_status_to_db(status: TaskStatus) -> &'static str {
    match status {
        TaskStatus::Todo => "todo",
        TaskStatus::InProgress => "in_progress",
        TaskStatus::Done => "done",
        TaskStatus::Cancelled => "cancelled",
    }
}
