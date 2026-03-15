//! Task/section use-case service.
//!
//! # Responsibility
//! - Provide section-based list queries (Inbox/Today/Upcoming) with tag enrichment.
//! - Provide universal status update for any atom type.
//!
//! # Invariants
//! - Section classification is driven by `start_at`/`end_at` nullability, not `type`.
//! - `update_status(None)` clears task_status (demote to statusless).

use crate::model::atom::{Atom, AtomId, TaskStatus};
use crate::repo::atom_repo::{AtomRepository, RepoError, SectionAtomRow};
use crate::repo::note_repo::load_tags_for_atoms;
use crate::repo::scoped_query_repo::{
    ProjectionMode, ScopedAtomQuery, ScopedAtomResult, ScopedQueryError, ScopedQueryRepository,
    SortSpec, StatusFilter, TimeFilter, TimeShapeFilter,
};
use crate::repo::tree_repo::{TreeRepoError, WorkspaceNodeId};
use crate::repo::workspace_meta_repo::WorkspaceMetaRepository;
use rusqlite::Connection;
use std::error::Error;
use std::fmt::{Display, Formatter};

/// A section query result enriched with tags.
#[derive(Debug, Clone)]
pub struct SectionAtom {
    /// The parsed atom entity.
    pub atom: Atom,
    /// Normalized lowercase tags for this atom.
    pub tags: Vec<String>,
    /// Epoch ms from `updated_at` column.
    pub updated_at: i64,
}

/// Errors from task/section service operations.
#[derive(Debug)]
pub enum TaskServiceError {
    /// Target atom does not exist or is soft-deleted.
    AtomNotFound(AtomId),
    /// Repository-level error.
    Repo(RepoError),
    /// Scoped query descriptor or execution error.
    ScopedQuery(ScopedQueryError),
    /// Workspace metadata resolution error.
    Workspace(TreeRepoError),
}

impl Display for TaskServiceError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::AtomNotFound(id) => write!(f, "atom not found: {id}"),
            Self::Repo(err) => write!(f, "{err}"),
            Self::ScopedQuery(err) => write!(f, "{err}"),
            Self::Workspace(err) => write!(f, "{err}"),
        }
    }
}

impl Error for TaskServiceError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::AtomNotFound(_) => None,
            Self::Repo(err) => Some(err),
            Self::ScopedQuery(err) => Some(err),
            Self::Workspace(err) => Some(err),
        }
    }
}

impl From<RepoError> for TaskServiceError {
    fn from(err: RepoError) -> Self {
        match err {
            RepoError::NotFound(id) => Self::AtomNotFound(id),
            other => Self::Repo(other),
        }
    }
}

impl From<ScopedQueryError> for TaskServiceError {
    fn from(err: ScopedQueryError) -> Self {
        Self::ScopedQuery(err)
    }
}

impl From<TreeRepoError> for TaskServiceError {
    fn from(err: TreeRepoError) -> Self {
        Self::Workspace(err)
    }
}

/// Service for section-based atom queries and universal status updates.
pub struct TaskService<
    'conn,
    A: AtomRepository,
    S: ScopedQueryRepository,
    W: WorkspaceMetaRepository,
> {
    atom_repo: &'conn A,
    scoped_repo: &'conn S,
    workspace_meta: &'conn W,
    conn: &'conn Connection,
}

impl<'conn, A: AtomRepository, S: ScopedQueryRepository, W: WorkspaceMetaRepository>
    TaskService<'conn, A, S, W>
{
    /// Creates a service from existing repository and connection references.
    pub fn new(
        atom_repo: &'conn A,
        scoped_repo: &'conn S,
        workspace_meta: &'conn W,
        conn: &'conn Connection,
    ) -> Self {
        Self {
            atom_repo,
            scoped_repo,
            workspace_meta,
            conn,
        }
    }

    /// Returns timeless atoms (both `start_at` and `end_at` NULL).
    pub fn fetch_inbox(
        &self,
        limit: u32,
        offset: u32,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        self.query_section_atoms(ScopedAtomQuery {
            folder_id: self.compatibility_scope()?,
            view_hint: None,
            time_filter: TimeFilter::Timeless,
            time_shape: TimeShapeFilter::Any,
            status_filter: StatusFilter::ActiveOnly,
            tag: None,
            text_query: None,
            include_path: false,
            include_overdue_deadlines: false,
            sort: SortSpec::UpdatedAtDesc,
            limit,
            offset,
        })
    }

    /// Returns atoms active today based on time-matrix rules.
    pub fn fetch_today(
        &self,
        bod_ms: i64,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        self.query_section_atoms(ScopedAtomQuery {
            folder_id: self.compatibility_scope()?,
            view_hint: None,
            time_filter: TimeFilter::Range {
                start_ms: bod_ms,
                end_ms: Some(eod_ms),
            },
            time_shape: TimeShapeFilter::Any,
            status_filter: StatusFilter::ActiveOnly,
            tag: None,
            text_query: None,
            include_path: false,
            include_overdue_deadlines: true,
            sort: SortSpec::StartAtAsc,
            limit,
            offset,
        })
    }

    /// Returns atoms anchored entirely in the future.
    pub fn fetch_upcoming(
        &self,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        self.query_section_atoms(ScopedAtomQuery {
            folder_id: self.compatibility_scope()?,
            view_hint: None,
            time_filter: TimeFilter::Range {
                start_ms: eod_ms,
                end_ms: None,
            },
            time_shape: TimeShapeFilter::Any,
            status_filter: StatusFilter::ActiveOnly,
            tag: None,
            text_query: None,
            include_path: false,
            include_overdue_deadlines: false,
            sort: SortSpec::StartAtAsc,
            limit,
            offset,
        })
    }

    /// Updates `task_status` for any atom type (universal completion).
    /// Pass `None` to clear status (demote).
    pub fn update_status(
        &self,
        id: AtomId,
        status: Option<TaskStatus>,
    ) -> Result<(), TaskServiceError> {
        self.atom_repo.update_atom_status(id, status)?;
        Ok(())
    }

    /// Returns atoms with both `start_at` and `end_at` set that overlap the given time range.
    /// Includes all statuses (done/cancelled shown on calendar).
    pub fn fetch_by_time_range(
        &self,
        range_start_ms: i64,
        range_end_ms: i64,
        limit: u32,
        offset: u32,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        self.query_section_atoms(ScopedAtomQuery {
            folder_id: self.compatibility_scope()?,
            view_hint: None,
            time_filter: TimeFilter::Range {
                start_ms: range_start_ms,
                end_ms: Some(range_end_ms),
            },
            time_shape: TimeShapeFilter::BoundedOnly,
            status_filter: StatusFilter::Any,
            tag: None,
            text_query: None,
            include_path: false,
            include_overdue_deadlines: false,
            sort: SortSpec::StartAtAsc,
            limit,
            offset,
        })
    }

    /// Updates only `start_at` and `end_at` for a calendar event.
    pub fn update_event_times(
        &self,
        id: AtomId,
        start_at: i64,
        end_at: i64,
    ) -> Result<(), TaskServiceError> {
        self.atom_repo.update_event_times(id, start_at, end_at)?;
        Ok(())
    }

    /// Returns all non-deleted, non-completed atoms that have at least one time field set.
    /// Used for startup reminder recovery.
    pub fn fetch_timed(&self) -> Result<Vec<SectionAtom>, TaskServiceError> {
        let rows = self.atom_repo.fetch_timed()?;
        self.enrich_with_tags(rows)
    }

    /// Loads a single non-deleted atom by ID with tags.
    /// Returns `None` when the atom does not exist or is soft-deleted.
    /// Unlike `NoteService::get_note`, this works for any atom type (note/task/event).
    pub fn get_atom_record(&self, id: AtomId) -> Result<Option<SectionAtom>, TaskServiceError> {
        let row = self.atom_repo.get_section_atom(id)?;
        match row {
            None => Ok(None),
            Some(r) => {
                let enriched = self.enrich_with_tags(vec![r])?;
                Ok(enriched.into_iter().next())
            }
        }
    }

    fn enrich_with_tags(
        &self,
        rows: Vec<SectionAtomRow>,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        if rows.is_empty() {
            return Ok(Vec::new());
        }

        let uuids: Vec<String> = rows.iter().map(|r| r.atom.uuid.to_string()).collect();
        let tag_map = load_tags_for_atoms(self.conn, &uuids).map_err(TaskServiceError::Repo)?;

        let result = rows
            .into_iter()
            .map(|row| {
                let uuid_str = row.atom.uuid.to_string();
                let tags = tag_map.get(&uuid_str).cloned().unwrap_or_default();
                SectionAtom {
                    atom: row.atom,
                    tags,
                    updated_at: row.updated_at,
                }
            })
            .collect();

        Ok(result)
    }

    fn compatibility_scope(&self) -> Result<WorkspaceNodeId, TaskServiceError> {
        // PR-0409 lands the scoped-query engine before PR-0410 reroutes creation
        // writes into designated folders, so current section reads stay rooted at
        // the default workspace to preserve existing visibility semantics.
        self.workspace_meta.get_default_workspace()?.ok_or_else(|| {
            TaskServiceError::Workspace(TreeRepoError::InvalidData(
                "default workspace not found".to_string(),
            ))
        })
    }

    fn query_section_atoms(
        &self,
        query: ScopedAtomQuery,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        let rows = self
            .scoped_repo
            .query_scoped_atoms(query, ProjectionMode::Atom)?;
        self.enrich_scoped_with_tags(rows)
    }

    fn enrich_scoped_with_tags(
        &self,
        rows: Vec<ScopedAtomResult>,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        if rows.is_empty() {
            return Ok(Vec::new());
        }

        let uuids: Vec<String> = rows.iter().map(|r| r.atom.uuid.to_string()).collect();
        let tag_map = load_tags_for_atoms(self.conn, &uuids).map_err(TaskServiceError::Repo)?;

        let result = rows
            .into_iter()
            .map(|row| {
                let uuid_str = row.atom.uuid.to_string();
                let tags = tag_map.get(&uuid_str).cloned().unwrap_or_default();
                SectionAtom {
                    atom: row.atom,
                    tags,
                    updated_at: row.updated_at,
                }
            })
            .collect();

        Ok(result)
    }
}
