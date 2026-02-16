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
}

impl Display for TaskServiceError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::AtomNotFound(id) => write!(f, "atom not found: {id}"),
            Self::Repo(err) => write!(f, "{err}"),
        }
    }
}

impl Error for TaskServiceError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::AtomNotFound(_) => None,
            Self::Repo(err) => Some(err),
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

/// Service for section-based atom queries and universal status updates.
pub struct TaskService<'conn, R: AtomRepository> {
    repo: &'conn R,
    conn: &'conn Connection,
}

impl<'conn, R: AtomRepository> TaskService<'conn, R> {
    /// Creates a service from existing repository and connection references.
    pub fn new(repo: &'conn R, conn: &'conn Connection) -> Self {
        Self { repo, conn }
    }

    /// Returns timeless atoms (both `start_at` and `end_at` NULL).
    pub fn fetch_inbox(
        &self,
        limit: u32,
        offset: u32,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        let rows = self.repo.fetch_inbox(limit, offset)?;
        self.enrich_with_tags(rows)
    }

    /// Returns atoms active today based on time-matrix rules.
    pub fn fetch_today(
        &self,
        bod_ms: i64,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        let rows = self.repo.fetch_today(bod_ms, eod_ms, limit, offset)?;
        self.enrich_with_tags(rows)
    }

    /// Returns atoms anchored entirely in the future.
    pub fn fetch_upcoming(
        &self,
        eod_ms: i64,
        limit: u32,
        offset: u32,
    ) -> Result<Vec<SectionAtom>, TaskServiceError> {
        let rows = self.repo.fetch_upcoming(eod_ms, limit, offset)?;
        self.enrich_with_tags(rows)
    }

    /// Updates `task_status` for any atom type (universal completion).
    /// Pass `None` to clear status (demote).
    pub fn update_status(
        &self,
        id: AtomId,
        status: Option<TaskStatus>,
    ) -> Result<(), TaskServiceError> {
        self.repo.update_atom_status(id, status)?;
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
        let rows = self
            .repo
            .fetch_by_time_range(range_start_ms, range_end_ms, limit, offset)?;
        self.enrich_with_tags(rows)
    }

    /// Updates only `start_at` and `end_at` for a calendar event.
    pub fn update_event_times(
        &self,
        id: AtomId,
        start_at: i64,
        end_at: i64,
    ) -> Result<(), TaskServiceError> {
        self.repo.update_event_times(id, start_at, end_at)?;
        Ok(())
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
}
