//! Atom repository contracts and SQLite implementation.
//!
//! # Responsibility
//! - Provide stable CRUD APIs over canonical `atoms` storage.
//! - Keep SQL details inside core persistence boundary.
//!
//! # Invariants
//! - Write paths must call `Atom::validate()` before SQL mutations.
//! - Read paths must reject invalid persisted state instead of masking it.
//!
//! # See also
//! - docs/releases/v0.1/prs/PR-0006-core-crud.md

use crate::db::migrations::latest_version;
use crate::db::DbError;
use crate::model::atom::{Atom, AtomId, AtomValidationError, TaskStatus, ViewHint};
use log::{error, info, warn};
use rusqlite::types::Value;
use rusqlite::{params, params_from_iter, Connection, Row};
use std::error::Error;
use std::fmt::{Display, Formatter};
use std::time::Instant;
use uuid::Uuid;

const ATOM_SELECT_SQL: &str = "SELECT
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
    is_deleted
FROM atoms";

/// Result type used by atom repository operations.
pub type RepoResult<T> = Result<T, RepoError>;

/// Generic repository error for atom persistence and query operations.
#[derive(Debug)]
pub enum RepoError {
    /// Domain-level atom validation failed before SQL execution.
    Validation(AtomValidationError),
    /// Underlying database/bootstrap operation failed.
    Db(DbError),
    /// Requested atom does not exist.
    NotFound(AtomId),
    /// Connection is open but not initialized to expected migration version.
    UninitializedConnection {
        expected_version: u32,
        actual_version: u32,
    },
    /// Required table is missing from schema.
    MissingRequiredTable(&'static str),
    /// Required column is missing from a required table.
    MissingRequiredColumn {
        table: &'static str,
        column: &'static str,
    },
    /// Persisted row exists but cannot be converted into a valid atom.
    InvalidData(String),
}

impl Display for RepoError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Validation(err) => write!(f, "{err}"),
            Self::Db(err) => write!(f, "{err}"),
            Self::NotFound(id) => write!(f, "atom not found: {id}"),
            Self::UninitializedConnection {
                expected_version,
                actual_version,
            } => write!(
                f,
                "repository requires migrated database schema version {expected_version}, got {actual_version}"
            ),
            Self::MissingRequiredTable(table) => {
                write!(f, "repository requires table `{table}`, but it was not found")
            }
            Self::MissingRequiredColumn { table, column } => write!(
                f,
                "repository requires column `{column}` in table `{table}`, but it was not found"
            ),
            Self::InvalidData(message) => write!(f, "invalid persisted atom data: {message}"),
        }
    }
}

impl Error for RepoError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Validation(err) => Some(err),
            Self::Db(err) => Some(err),
            Self::NotFound(_) => None,
            Self::UninitializedConnection { .. } => None,
            Self::MissingRequiredTable(_) => None,
            Self::MissingRequiredColumn { .. } => None,
            Self::InvalidData(_) => None,
        }
    }
}

impl From<AtomValidationError> for RepoError {
    fn from(value: AtomValidationError) -> Self {
        Self::Validation(value)
    }
}

impl From<DbError> for RepoError {
    fn from(value: DbError) -> Self {
        Self::Db(value)
    }
}

impl From<rusqlite::Error> for RepoError {
    fn from(value: rusqlite::Error) -> Self {
        Self::Db(DbError::Sqlite(value))
    }
}

/// A row returned by section queries, wrapping the parsed `Atom` with `updated_at`
/// which is not part of the domain model but is needed for FFI list items.
#[derive(Debug, Clone)]
pub struct SectionAtomRow {
    /// The parsed atom entity.
    pub atom: Atom,
    /// Epoch ms timestamp from the `updated_at` column.
    pub updated_at: i64,
}

/// SELECT columns for section queries (adds `updated_at` on top of ATOM_SELECT_SQL).
const SECTION_SELECT_SQL: &str = "SELECT
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
FROM atoms";

/// Query options for listing atoms.
#[derive(Debug, Clone, Default)]
pub struct AtomListQuery {
    /// Optional filter by view hint.
    pub view_hint: Option<ViewHint>,
    /// Whether soft-deleted rows should be included.
    pub include_deleted: bool,
    /// Maximum rows to return. When `None`, no explicit limit is applied.
    pub limit: Option<u32>,
    /// Number of rows to skip from the sorted result set.
    pub offset: u32,
}

/// Repository interface for atom CRUD operations.
pub trait AtomRepository {
    /// Inserts a new atom and returns its stable ID.
    fn create_atom(&self, atom: &Atom) -> RepoResult<AtomId>;
    /// Updates an existing atom by ID.
    ///
    /// Returns [`RepoError::NotFound`] when the target ID does not exist.
    fn update_atom(&self, atom: &Atom) -> RepoResult<()>;
    /// Loads a single atom by ID.
    ///
    /// Returns `None` when no row exists or row is soft-deleted and
    /// `include_deleted` is `false`.
    fn get_atom(&self, id: AtomId, include_deleted: bool) -> RepoResult<Option<Atom>>;
    /// Lists atoms using filter/pagination options.
    fn list_atoms(&self, query: &AtomListQuery) -> RepoResult<Vec<Atom>>;
    /// Soft-deletes an atom by ID.
    ///
    /// This operation is idempotent for rows already marked deleted.
    fn soft_delete_atom(&self, id: AtomId) -> RepoResult<()>;

    /// Returns atoms with both `start_at` and `end_at` NULL (timeless).
    /// Excludes done/cancelled atoms.
    fn fetch_inbox(&self, limit: u32, offset: u32) -> RepoResult<Vec<SectionAtomRow>>;

    /// Returns atoms "active today" based on time-matrix rules.
    /// `bod_ms` and `eod_ms` are device-local day boundaries in epoch ms.
    /// Excludes done/cancelled atoms.
    fn fetch_today(
        &self,
        bod_ms: i64,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> RepoResult<Vec<SectionAtomRow>>;

    /// Returns atoms anchored entirely in the future (after `eod_ms`).
    /// Excludes done/cancelled atoms.
    fn fetch_upcoming(
        &self,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> RepoResult<Vec<SectionAtomRow>>;

    /// Updates `task_status` for any atom type (universal completion).
    /// Pass `None` to clear status (demote to statusless).
    /// Idempotent: setting the same status twice succeeds.
    fn update_atom_status(&self, id: AtomId, status: Option<TaskStatus>) -> RepoResult<()>;

    /// Returns atoms with both `start_at` and `end_at` set that overlap the given time range.
    /// Includes all statuses (done/cancelled shown on calendar).
    fn fetch_by_time_range(
        &self,
        range_start_ms: i64,
        range_end_ms: i64,
        limit: u32,
        offset: u32,
    ) -> RepoResult<Vec<SectionAtomRow>>;

    /// Updates only `start_at` and `end_at` for a calendar event.
    /// Validates `end_at >= start_at`; returns `RepoError::Validation(InvalidEventWindow)` on failure.
    fn update_event_times(&self, id: AtomId, start_at: i64, end_at: i64) -> RepoResult<()>;

    /// Returns all non-deleted atoms that have at least one time field set
    /// (`start_at IS NOT NULL OR end_at IS NOT NULL`).
    /// Excludes done/cancelled atoms. Used for startup reminder recovery.
    fn fetch_timed(&self) -> RepoResult<Vec<SectionAtomRow>>;

    /// Loads a single non-deleted atom by ID as a `SectionAtomRow` (includes `updated_at`).
    /// Returns `None` when the atom does not exist or is soft-deleted.
    /// Unlike `get_atom`, this includes the `updated_at` field needed for FFI responses.
    fn get_section_atom(&self, id: AtomId) -> RepoResult<Option<SectionAtomRow>>;
}

/// SQLite-backed atom repository.
pub struct SqliteAtomRepository<'conn> {
    conn: &'conn Connection,
}

impl<'conn> SqliteAtomRepository<'conn> {
    /// Constructs a repository from an existing SQLite connection.
    ///
    /// # Errors
    /// - Returns [`RepoError::UninitializedConnection`] if schema version is not
    ///   fully migrated.
    /// - Returns [`RepoError::MissingRequiredTable`] or
    ///   [`RepoError::MissingRequiredColumn`] when required schema shape is
    ///   incomplete.
    pub fn try_new(conn: &'conn Connection) -> RepoResult<Self> {
        ensure_connection_ready(conn)?;
        Ok(Self { conn })
    }
}

impl AtomRepository for SqliteAtomRepository<'_> {
    fn create_atom(&self, atom: &Atom) -> RepoResult<AtomId> {
        let started_at = Instant::now();
        if let Err(err) = atom.validate() {
            warn!(
                "event=atom_create module=repo status=error atom_id={} view_hint={} duration_ms={} error_code=validation_error",
                atom.uuid,
                view_hint_to_db(atom.view_hint),
                started_at.elapsed().as_millis()
            );
            return Err(err.into());
        }

        if let Err(err) = self.conn.execute(
            "INSERT INTO atoms (
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
                is_deleted
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13);",
            params![
                atom.uuid.to_string(),
                view_hint_to_db(atom.view_hint),
                atom.title.as_str(),
                atom.content_type.as_str(),
                atom.content.as_str(),
                atom.preview_text.as_deref(),
                atom.preview_image.as_deref(),
                atom.task_status.map(task_status_to_db),
                atom.start_at,
                atom.end_at,
                atom.recurrence_rule.as_deref(),
                atom.hlc_timestamp.as_deref(),
                bool_to_int(atom.is_deleted),
            ],
        ) {
            error!(
                "event=atom_create module=repo status=error atom_id={} view_hint={} duration_ms={} error_code=db_write_failed error={}",
                atom.uuid,
                view_hint_to_db(atom.view_hint),
                started_at.elapsed().as_millis(),
                err
            );
            return Err(err.into());
        }

        info!(
            "event=atom_create module=repo status=ok atom_id={} view_hint={} duration_ms={}",
            atom.uuid,
            view_hint_to_db(atom.view_hint),
            started_at.elapsed().as_millis()
        );

        Ok(atom.uuid)
    }

    fn update_atom(&self, atom: &Atom) -> RepoResult<()> {
        let started_at = Instant::now();
        if let Err(err) = atom.validate() {
            warn!(
                "event=atom_update module=repo status=error atom_id={} view_hint={} duration_ms={} error_code=validation_error",
                atom.uuid,
                view_hint_to_db(atom.view_hint),
                started_at.elapsed().as_millis()
            );
            return Err(err.into());
        }

        let changed = match self.conn.execute(
            "UPDATE atoms
             SET
                view_hint = ?1,
                title = ?2,
                content_type = ?3,
                content = ?4,
                preview_text = ?5,
                preview_image = ?6,
                task_status = ?7,
                start_at = ?8,
                end_at = ?9,
                recurrence_rule = ?10,
                hlc_timestamp = ?11,
                is_deleted = ?12,
                updated_at = (strftime('%s', 'now') * 1000)
             WHERE uuid = ?13;",
            params![
                view_hint_to_db(atom.view_hint),
                atom.title.as_str(),
                atom.content_type.as_str(),
                atom.content.as_str(),
                atom.preview_text.as_deref(),
                atom.preview_image.as_deref(),
                atom.task_status.map(task_status_to_db),
                atom.start_at,
                atom.end_at,
                atom.recurrence_rule.as_deref(),
                atom.hlc_timestamp.as_deref(),
                bool_to_int(atom.is_deleted),
                atom.uuid.to_string(),
            ],
        ) {
            Ok(changed) => changed,
            Err(err) => {
                error!(
                    "event=atom_update module=repo status=error atom_id={} view_hint={} duration_ms={} error_code=db_write_failed error={}",
                    atom.uuid,
                    view_hint_to_db(atom.view_hint),
                    started_at.elapsed().as_millis(),
                    err
                );
                return Err(err.into());
            }
        };

        if changed == 0 {
            warn!(
                "event=atom_update module=repo status=error atom_id={} view_hint={} duration_ms={} error_code=not_found",
                atom.uuid,
                view_hint_to_db(atom.view_hint),
                started_at.elapsed().as_millis()
            );
            return Err(RepoError::NotFound(atom.uuid));
        }

        info!(
            "event=atom_update module=repo status=ok atom_id={} view_hint={} duration_ms={}",
            atom.uuid,
            view_hint_to_db(atom.view_hint),
            started_at.elapsed().as_millis()
        );

        Ok(())
    }

    fn get_atom(&self, id: AtomId, include_deleted: bool) -> RepoResult<Option<Atom>> {
        let mut stmt = self.conn.prepare(&format!(
            "{ATOM_SELECT_SQL}
             WHERE uuid = ?1
               AND (?2 = 1 OR is_deleted = 0);"
        ))?;

        let mut rows = stmt.query(params![id.to_string(), bool_to_int(include_deleted)])?;
        if let Some(row) = rows.next()? {
            return Ok(Some(parse_atom_row(row)?));
        }

        Ok(None)
    }

    fn list_atoms(&self, query: &AtomListQuery) -> RepoResult<Vec<Atom>> {
        let mut sql = format!("{ATOM_SELECT_SQL} WHERE 1 = 1");
        let mut bind_values: Vec<Value> = Vec::new();

        if !query.include_deleted {
            sql.push_str(" AND is_deleted = 0");
        }

        if let Some(hint) = query.view_hint {
            sql.push_str(" AND view_hint = ?");
            bind_values.push(Value::Text(view_hint_to_db(hint).to_string()));
        }

        sql.push_str(" ORDER BY updated_at DESC, uuid ASC");

        if let Some(limit) = query.limit {
            sql.push_str(" LIMIT ?");
            bind_values.push(Value::Integer(i64::from(limit)));
            if query.offset > 0 {
                sql.push_str(" OFFSET ?");
                bind_values.push(Value::Integer(i64::from(query.offset)));
            }
        } else if query.offset > 0 {
            sql.push_str(" LIMIT -1 OFFSET ?");
            bind_values.push(Value::Integer(i64::from(query.offset)));
        }

        let mut stmt = self.conn.prepare(&sql)?;
        let mut rows = stmt.query(params_from_iter(bind_values))?;
        let mut atoms = Vec::new();

        while let Some(row) = rows.next()? {
            atoms.push(parse_atom_row(row)?);
        }

        Ok(atoms)
    }

    fn soft_delete_atom(&self, id: AtomId) -> RepoResult<()> {
        let started_at = Instant::now();
        let changed = match self.conn.execute(
            "UPDATE atoms
             SET
                is_deleted = 1,
                updated_at = (strftime('%s', 'now') * 1000)
             WHERE uuid = ?1
               AND is_deleted = 0;",
            [id.to_string()],
        ) {
            Ok(changed) => changed,
            Err(err) => {
                error!(
                    "event=atom_soft_delete module=repo status=error atom_id={} duration_ms={} error_code=db_write_failed error={}",
                    id,
                    started_at.elapsed().as_millis(),
                    err
                );
                return Err(err.into());
            }
        };

        if changed > 0 {
            info!(
                "event=atom_soft_delete module=repo status=ok atom_id={} already_deleted=false duration_ms={}",
                id,
                started_at.elapsed().as_millis()
            );
            return Ok(());
        }

        if atom_exists(self.conn, id)? {
            info!(
                "event=atom_soft_delete module=repo status=ok atom_id={} already_deleted=true duration_ms={}",
                id,
                started_at.elapsed().as_millis()
            );
            return Ok(());
        }

        warn!(
            "event=atom_soft_delete module=repo status=error atom_id={} duration_ms={} error_code=not_found",
            id,
            started_at.elapsed().as_millis()
        );
        Err(RepoError::NotFound(id))
    }

    fn fetch_inbox(&self, limit: u32, offset: u32) -> RepoResult<Vec<SectionAtomRow>> {
        let sql = format!(
            "{SECTION_SELECT_SQL}
             WHERE start_at IS NULL
               AND end_at IS NULL
               AND (task_status IS NULL OR task_status NOT IN ('done', 'cancelled'))
               AND is_deleted = 0
             ORDER BY updated_at DESC, uuid ASC
             LIMIT ?1 OFFSET ?2"
        );
        let mut stmt = self.conn.prepare(&sql)?;
        let mut rows = stmt.query(params![limit, offset])?;
        let mut result = Vec::new();
        while let Some(row) = rows.next()? {
            result.push(parse_section_atom_row(row)?);
        }
        Ok(result)
    }

    fn fetch_today(
        &self,
        bod_ms: i64,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> RepoResult<Vec<SectionAtomRow>> {
        let sql = format!(
            "{SECTION_SELECT_SQL}
             WHERE is_deleted = 0
               AND (task_status IS NULL OR task_status NOT IN ('done', 'cancelled'))
               AND (
                 (end_at IS NOT NULL AND end_at <= ?1 AND start_at IS NULL)
                 OR (start_at IS NOT NULL AND end_at IS NULL AND start_at <= ?1)
                 OR (start_at IS NOT NULL AND end_at IS NOT NULL
                     AND start_at <= ?1 AND end_at >= ?2)
               )
             ORDER BY COALESCE(start_at, end_at) ASC, updated_at DESC
             LIMIT ?3 OFFSET ?4"
        );
        let mut stmt = self.conn.prepare(&sql)?;
        let mut rows = stmt.query(params![eod_ms, bod_ms, limit, offset])?;
        let mut result = Vec::new();
        while let Some(row) = rows.next()? {
            result.push(parse_section_atom_row(row)?);
        }
        Ok(result)
    }

    fn fetch_upcoming(
        &self,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> RepoResult<Vec<SectionAtomRow>> {
        let sql = format!(
            "{SECTION_SELECT_SQL}
             WHERE is_deleted = 0
               AND (task_status IS NULL OR task_status NOT IN ('done', 'cancelled'))
               AND (
                 (end_at IS NOT NULL AND end_at > ?1 AND start_at IS NULL)
                 OR (start_at IS NOT NULL AND end_at IS NULL AND start_at > ?1)
                 OR (start_at IS NOT NULL AND end_at IS NOT NULL AND start_at > ?1)
               )
             ORDER BY COALESCE(start_at, end_at) ASC, updated_at DESC
             LIMIT ?2 OFFSET ?3"
        );
        let mut stmt = self.conn.prepare(&sql)?;
        let mut rows = stmt.query(params![eod_ms, limit, offset])?;
        let mut result = Vec::new();
        while let Some(row) = rows.next()? {
            result.push(parse_section_atom_row(row)?);
        }
        Ok(result)
    }

    fn update_atom_status(&self, id: AtomId, status: Option<TaskStatus>) -> RepoResult<()> {
        let started_at = Instant::now();
        let status_db = status.map(task_status_to_db);

        // Why: re-derive view_hint atomically (mirrors derive_view_hint in note_service.rs).
        let changed = match self.conn.execute(
            "UPDATE atoms
             SET task_status = ?1,
                 view_hint = CASE
                     WHEN ?1 IS NOT NULL THEN 'task'
                     WHEN start_at IS NOT NULL OR end_at IS NOT NULL THEN 'event'
                     ELSE 'note'
                 END,
                 updated_at = (strftime('%s', 'now') * 1000)
             WHERE uuid = ?2
               AND is_deleted = 0;",
            params![status_db, id.to_string()],
        ) {
            Ok(changed) => changed,
            Err(err) => {
                error!(
                    "event=atom_update_status module=repo status=error atom_id={} duration_ms={} error_code=db_write_failed error={}",
                    id,
                    started_at.elapsed().as_millis(),
                    err
                );
                return Err(err.into());
            }
        };

        if changed == 0 {
            warn!(
                "event=atom_update_status module=repo status=error atom_id={} duration_ms={} error_code=not_found",
                id,
                started_at.elapsed().as_millis()
            );
            return Err(RepoError::NotFound(id));
        }

        info!(
            "event=atom_update_status module=repo status=ok atom_id={} new_status={} duration_ms={}",
            id,
            status_db.unwrap_or("null"),
            started_at.elapsed().as_millis()
        );

        Ok(())
    }

    fn fetch_by_time_range(
        &self,
        range_start_ms: i64,
        range_end_ms: i64,
        limit: u32,
        offset: u32,
    ) -> RepoResult<Vec<SectionAtomRow>> {
        let sql = format!(
            "{SECTION_SELECT_SQL}
             WHERE start_at IS NOT NULL
               AND end_at IS NOT NULL
               AND start_at < ?1
               AND end_at > ?2
               AND is_deleted = 0
             ORDER BY start_at ASC, end_at ASC
             LIMIT ?3 OFFSET ?4"
        );
        let mut stmt = self.conn.prepare(&sql)?;
        let mut rows = stmt.query(params![range_end_ms, range_start_ms, limit, offset])?;
        let mut result = Vec::new();
        while let Some(row) = rows.next()? {
            result.push(parse_section_atom_row(row)?);
        }
        Ok(result)
    }

    fn update_event_times(&self, id: AtomId, start_at: i64, end_at: i64) -> RepoResult<()> {
        let started_at = Instant::now();

        if end_at < start_at {
            warn!(
                "event=update_event_times module=repo status=error atom_id={} duration_ms={} error_code=validation_error",
                id,
                started_at.elapsed().as_millis()
            );
            return Err(RepoError::Validation(
                AtomValidationError::InvalidEventWindow {
                    start: start_at,
                    end: end_at,
                },
            ));
        }

        // Why: re-derive view_hint atomically (mirrors derive_view_hint in note_service.rs).
        let changed = match self.conn.execute(
            "UPDATE atoms
             SET start_at = ?1,
                 end_at = ?2,
                 view_hint = CASE
                     WHEN task_status IS NOT NULL THEN 'task'
                     WHEN ?1 IS NOT NULL OR ?2 IS NOT NULL THEN 'event'
                     ELSE 'note'
                 END,
                 updated_at = (strftime('%s', 'now') * 1000)
             WHERE uuid = ?3
               AND is_deleted = 0;",
            params![start_at, end_at, id.to_string()],
        ) {
            Ok(changed) => changed,
            Err(err) => {
                error!(
                    "event=update_event_times module=repo status=error atom_id={} duration_ms={} error_code=db_write_failed error={}",
                    id,
                    started_at.elapsed().as_millis(),
                    err
                );
                return Err(err.into());
            }
        };

        if changed == 0 {
            warn!(
                "event=update_event_times module=repo status=error atom_id={} duration_ms={} error_code=not_found",
                id,
                started_at.elapsed().as_millis()
            );
            return Err(RepoError::NotFound(id));
        }

        info!(
            "event=update_event_times module=repo status=ok atom_id={} start_at={} end_at={} duration_ms={}",
            id,
            start_at,
            end_at,
            started_at.elapsed().as_millis()
        );

        Ok(())
    }

    fn fetch_timed(&self) -> RepoResult<Vec<SectionAtomRow>> {
        let sql = format!(
            "{SECTION_SELECT_SQL}
             WHERE is_deleted = 0
               AND (task_status IS NULL OR task_status NOT IN ('done', 'cancelled'))
               AND (start_at IS NOT NULL OR end_at IS NOT NULL)
             ORDER BY COALESCE(start_at, end_at) ASC, updated_at DESC"
        );
        let mut stmt = self.conn.prepare(&sql)?;
        let mut rows = stmt.query([])?;
        let mut result = Vec::new();
        while let Some(row) = rows.next()? {
            result.push(parse_section_atom_row(row)?);
        }
        Ok(result)
    }

    fn get_section_atom(&self, id: AtomId) -> RepoResult<Option<SectionAtomRow>> {
        let sql = format!(
            "{SECTION_SELECT_SQL}
             WHERE uuid = ?1
               AND is_deleted = 0"
        );
        let mut stmt = self.conn.prepare(&sql)?;
        let mut rows = stmt.query(params![id.to_string()])?;
        if let Some(row) = rows.next()? {
            return Ok(Some(parse_section_atom_row(row)?));
        }
        Ok(None)
    }
}

fn parse_section_atom_row(row: &Row<'_>) -> RepoResult<SectionAtomRow> {
    let atom = parse_atom_row(row)?;
    let updated_at: i64 = row.get("updated_at")?;
    Ok(SectionAtomRow { atom, updated_at })
}

fn parse_atom_row(row: &Row<'_>) -> RepoResult<Atom> {
    let uuid_text: String = row.get("uuid")?;
    let uuid = Uuid::parse_str(&uuid_text).map_err(|_| {
        RepoError::InvalidData(format!("invalid uuid value `{uuid_text}` in atoms.uuid"))
    })?;

    let hint_text: String = row.get("view_hint")?;
    let view_hint = parse_view_hint(&hint_text).ok_or_else(|| {
        RepoError::InvalidData(format!(
            "invalid view_hint `{hint_text}` in atoms.view_hint"
        ))
    })?;

    let task_status = match row.get::<_, Option<String>>("task_status")? {
        Some(value) => Some(parse_task_status(&value).ok_or_else(|| {
            RepoError::InvalidData(format!(
                "invalid task status `{value}` in atoms.task_status"
            ))
        })?),
        None => None,
    };

    let is_deleted = match row.get::<_, i64>("is_deleted")? {
        0 => false,
        1 => true,
        other => {
            return Err(RepoError::InvalidData(format!(
                "invalid is_deleted value `{other}` in atoms.is_deleted"
            )));
        }
    };

    let atom = Atom {
        uuid,
        view_hint,
        title: row.get("title")?,
        content_type: row.get("content_type")?,
        content: row.get("content")?,
        preview_text: row.get("preview_text")?,
        preview_image: row.get("preview_image")?,
        task_status,
        start_at: row.get("start_at")?,
        end_at: row.get("end_at")?,
        recurrence_rule: row.get("recurrence_rule")?,
        hlc_timestamp: row.get("hlc_timestamp")?,
        is_deleted,
    };
    atom.validate()?;
    Ok(atom)
}

pub(crate) fn view_hint_to_db(hint: ViewHint) -> &'static str {
    match hint {
        ViewHint::Note => "note",
        ViewHint::Task => "task",
        ViewHint::Event => "event",
    }
}

fn parse_view_hint(value: &str) -> Option<ViewHint> {
    match value {
        "note" => Some(ViewHint::Note),
        "task" => Some(ViewHint::Task),
        "event" => Some(ViewHint::Event),
        _ => None,
    }
}

pub(crate) fn task_status_to_db(status: TaskStatus) -> &'static str {
    match status {
        TaskStatus::Todo => "todo",
        TaskStatus::InProgress => "in_progress",
        TaskStatus::Done => "done",
        TaskStatus::Cancelled => "cancelled",
    }
}

pub(crate) fn parse_task_status(value: &str) -> Option<TaskStatus> {
    match value {
        "todo" => Some(TaskStatus::Todo),
        "in_progress" => Some(TaskStatus::InProgress),
        "done" => Some(TaskStatus::Done),
        "cancelled" => Some(TaskStatus::Cancelled),
        _ => None,
    }
}

fn bool_to_int(value: bool) -> i64 {
    if value {
        1
    } else {
        0
    }
}

/// Validates that the connection schema is ready for repository queries.
fn ensure_connection_ready(conn: &Connection) -> RepoResult<()> {
    let expected_version = latest_version();
    let actual_version: u32 = conn.query_row("PRAGMA user_version;", [], |row| row.get(0))?;
    if actual_version != expected_version {
        return Err(RepoError::UninitializedConnection {
            expected_version,
            actual_version,
        });
    }

    let atoms_exists: i64 = conn.query_row(
        "SELECT EXISTS(
            SELECT 1
            FROM sqlite_master
            WHERE type = 'table' AND name = 'atoms'
        );",
        [],
        |row| row.get(0),
    )?;

    if atoms_exists != 1 {
        return Err(RepoError::MissingRequiredTable("atoms"));
    }

    for column in [
        "uuid",
        "view_hint",
        "title",
        "content_type",
        "content",
        "preview_text",
        "preview_image",
        "task_status",
        "start_at",
        "end_at",
        "recurrence_rule",
        "is_deleted",
        "updated_at",
    ] {
        if !table_has_column(conn, "atoms", column)? {
            return Err(RepoError::MissingRequiredColumn {
                table: "atoms",
                column,
            });
        }
    }

    Ok(())
}

/// Returns whether an atom row exists regardless of soft-delete state.
pub(crate) fn atom_exists(conn: &Connection, id: AtomId) -> RepoResult<bool> {
    let exists: i64 = conn.query_row(
        "SELECT EXISTS(
            SELECT 1
            FROM atoms
            WHERE uuid = ?1
        );",
        [id.to_string()],
        |row| row.get(0),
    )?;
    Ok(exists == 1)
}

/// Checks whether a table contains the specified column name.
fn table_has_column(conn: &Connection, table: &str, column: &str) -> RepoResult<bool> {
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
