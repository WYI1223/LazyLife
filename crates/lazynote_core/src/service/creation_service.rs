//! Unified creation service for atom + workspace reference.
//!
//! # Responsibility
//! - Ensure every created atom gets at least one workspace atom_ref (S4 ruling).
//! - Provide transactional create operations for note, task, and event atoms.
//!
//! # Invariants
//! - Atom and atom_ref are created on the same `Connection` (implicit SQLite
//!   transaction guarantees atomicity).
//! - New atoms receive a root-level atom_ref when `parent_node_id` is `None`.
//!
//! # See also
//! - docs/architecture/rulings/S4-creation-path-unification.md
//! - docs/releases/v0.3/prs/PR-RB-03-s4-atom-ref-unification.md

use crate::model::atom::{Atom, AtomId, TaskStatus, ViewHint};
use crate::repo::atom_repo::{AtomRepository, RepoError, SqliteAtomRepository};
use crate::repo::note_repo::NoteRecord;
use crate::repo::tree_repo::{SqliteTreeRepository, WorkspaceNode, WorkspaceNodeId};
use crate::service::note_service::{derive_markdown_preview, derive_title};
use crate::service::tree_service::{TreeService, TreeServiceError};
use rusqlite::Connection;
use std::error::Error;
use std::fmt::{Display, Formatter};
use uuid::Uuid;

/// Errors from unified creation operations.
#[derive(Debug)]
pub enum CreationServiceError {
    /// Atom persistence error.
    Repo(RepoError),
    /// Workspace tree operation error.
    Tree(TreeServiceError),
    /// Read-back after create did not find the expected record.
    InconsistentState(&'static str),
}

impl Display for CreationServiceError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Repo(err) => write!(f, "{err}"),
            Self::Tree(err) => write!(f, "{err}"),
            Self::InconsistentState(msg) => write!(f, "inconsistent state: {msg}"),
        }
    }
}

impl Error for CreationServiceError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Repo(err) => Some(err),
            Self::Tree(err) => Some(err),
            Self::InconsistentState(_) => None,
        }
    }
}

impl From<RepoError> for CreationServiceError {
    fn from(value: RepoError) -> Self {
        Self::Repo(value)
    }
}

impl From<TreeServiceError> for CreationServiceError {
    fn from(value: TreeServiceError) -> Self {
        Self::Tree(value)
    }
}

/// Request model for creating an event atom with workspace reference.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CreateEventWithRefRequest {
    /// Event title/content.
    pub title: String,
    /// Event start in epoch milliseconds.
    pub start_epoch_ms: i64,
    /// Optional event end in epoch milliseconds.
    pub end_epoch_ms: Option<i64>,
}

/// Composite service that creates atoms with mandatory workspace atom_ref.
///
/// Holds a shared `&Connection` reference; atom and tree repositories are
/// constructed on demand to avoid mutable-borrow conflicts.
pub struct CreationService<'conn> {
    conn: &'conn Connection,
}

impl<'conn> CreationService<'conn> {
    /// Creates service from a migrated connection.
    pub fn try_new(conn: &'conn Connection) -> Result<Self, CreationServiceError> {
        // Verify atom repo readiness (implicitly checks migration version).
        let _ = SqliteAtomRepository::try_new(conn)?;
        Ok(Self { conn })
    }

    /// Creates a note atom + root-level (or parent-scoped) atom_ref.
    pub fn create_note_with_ref(
        &self,
        content: impl Into<String>,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(NoteRecord, WorkspaceNode), CreationServiceError> {
        let content = content.into();
        let preview = derive_markdown_preview(content.as_str());
        let title = derive_title(content.as_str(), "markdown");

        let mut atom = Atom::new(ViewHint::Note, content);
        atom.title = title.clone();
        atom.preview_text = preview.preview_text;
        atom.preview_image = preview.preview_image;

        // 1. Persist atom.
        let atom_repo = SqliteAtomRepository::try_new(self.conn)?;
        atom_repo.create_atom(&atom)?;

        // 2. Create atom_ref.
        let display_name = if title.is_empty() {
            None
        } else {
            Some(title)
        };
        let node = self.create_atom_ref_for(atom.uuid, parent_node_id, display_name)?;

        // 3. Read-back NoteRecord (tags are always empty for a new note).
        let record = read_back_note_record(self.conn, atom.uuid)?
            .ok_or(CreationServiceError::InconsistentState(
                "created note not found in read-back",
            ))?;

        Ok((record, node))
    }

    /// Creates a task atom + root-level (or parent-scoped) atom_ref.
    pub fn create_task_with_ref(
        &self,
        content: impl Into<String>,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(AtomId, WorkspaceNode), CreationServiceError> {
        let content = content.into();
        let title = derive_title(content.as_str(), "markdown");

        let mut atom = Atom::new(ViewHint::Task, content);
        atom.title = title.clone();
        atom.task_status = Some(TaskStatus::Todo);

        let atom_repo = SqliteAtomRepository::try_new(self.conn)?;
        atom_repo.create_atom(&atom)?;

        let display_name = if title.is_empty() {
            None
        } else {
            Some(title)
        };
        let node = self.create_atom_ref_for(atom.uuid, parent_node_id, display_name)?;

        Ok((atom.uuid, node))
    }

    /// Creates an event atom + root-level (or parent-scoped) atom_ref.
    pub fn create_event_with_ref(
        &self,
        request: &CreateEventWithRefRequest,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(AtomId, WorkspaceNode), CreationServiceError> {
        let title = derive_title(request.title.as_str(), "markdown");

        let mut atom = Atom::new(ViewHint::Event, request.title.clone());
        atom.title = title.clone();
        atom.start_at = Some(request.start_epoch_ms);
        atom.end_at = request.end_epoch_ms;

        let atom_repo = SqliteAtomRepository::try_new(self.conn)?;
        atom_repo.create_atom(&atom)?;

        let display_name = if title.is_empty() {
            None
        } else {
            Some(title)
        };
        let node = self.create_atom_ref_for(atom.uuid, parent_node_id, display_name)?;

        Ok((atom.uuid, node))
    }

    /// Shared helper: create workspace atom_ref via TreeService.
    fn create_atom_ref_for(
        &self,
        atom_uuid: AtomId,
        parent_node_id: Option<WorkspaceNodeId>,
        display_name: Option<String>,
    ) -> Result<WorkspaceNode, CreationServiceError> {
        let tree_repo = SqliteTreeRepository::try_new(self.conn)
            .map_err(|e| CreationServiceError::Tree(TreeServiceError::from(e)))?;
        let tree_service = TreeService::new(tree_repo);
        tree_service
            .create_atom_ref(parent_node_id, atom_uuid, display_name)
            .map_err(Into::into)
    }
}

/// Reads back a `NoteRecord` from the atoms table for a freshly created note.
///
/// Uses `&Connection` (no `&mut` requirement) since this is a read-only query.
/// Tags are always empty for newly created notes.
fn read_back_note_record(
    conn: &Connection,
    atom_id: AtomId,
) -> Result<Option<NoteRecord>, RepoError> {
    let uuid_text = atom_id.to_string();
    let mut stmt = conn.prepare(
        "SELECT
            uuid,
            view_hint,
            title,
            content_type,
            content,
            preview_text,
            preview_image,
            updated_at,
            start_at,
            end_at,
            task_status
         FROM atoms
         WHERE uuid = ?1
           AND is_deleted = 0;",
    )?;

    let mut rows = stmt.query([uuid_text.as_str()])?;
    if let Some(row) = rows.next()? {
        let uuid_val: String = row.get("uuid")?;
        let parsed_id = Uuid::parse_str(&uuid_val)
            .map_err(|_| RepoError::InvalidData(format!("invalid uuid `{uuid_val}` in atoms")))?;

        return Ok(Some(NoteRecord {
            atom_id: parsed_id,
            view_hint: row.get("view_hint")?,
            title: row.get("title")?,
            content_type: row.get("content_type")?,
            content: row.get("content")?,
            preview_text: row.get("preview_text")?,
            preview_image: row.get("preview_image")?,
            updated_at: row.get("updated_at")?,
            tags: vec![],
            start_at: row.get("start_at")?,
            end_at: row.get("end_at")?,
            task_status: row.get("task_status")?,
        }));
    }

    Ok(None)
}
