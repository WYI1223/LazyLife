//! Unified creation service for atom + workspace reference.
//!
//! # Responsibility
//! - Ensure every created atom gets at least one workspace atom_ref (S4 ruling).
//! - Provide transactional create operations for note, task, and event atoms.
//!
//! # Invariants
//! - Atom and atom_ref are created inside an explicit IMMEDIATE transaction.
//! - Business creation writes route to explicit target folders or designated
//!   folders, never to workspace root fallback.
//!
//! # See also
//! - docs/architecture/rulings/S4-creation-path-unification.md
//! - docs/releases/v0.3/prs/PR-RB-03-s4-atom-ref-unification.md

use crate::model::atom::{Atom, AtomId, TaskStatus, ViewHint};
use crate::repo::atom_repo::{AtomRepository, RepoError, SqliteAtomRepository};
use crate::repo::note_repo::{normalize_tags, NoteRecord};
use crate::repo::tree_repo::{
    SqliteTreeRepository, TreeRepository, WorkspaceNode, WorkspaceNodeId, WorkspaceNodeKind,
};
use crate::repo::workspace_meta_repo::{SqliteWorkspaceMetaRepository, WorkspaceMetaRepository};
use crate::service::note_service::{derive_markdown_preview, derive_title};
use crate::service::tree_service::{TreeService, TreeServiceError};
use rusqlite::{params, Connection, Transaction, TransactionBehavior};
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
    /// Only the current content-type allowlist is accepted.
    InvalidContentType(String),
    /// The requested workspace root does not exist or is inactive.
    WorkspaceNotFound(WorkspaceNodeId),
    /// Explicit target folder must stay inside the requested workspace tree.
    TargetFolderNotInWorkspace {
        workspace_id: WorkspaceNodeId,
        target_folder: WorkspaceNodeId,
    },
    /// One designated role was not available for the requested workspace.
    MissingDesignatedFolder {
        workspace_id: WorkspaceNodeId,
        role: String,
    },
    /// Read-back after create did not find the expected record.
    InconsistentState(&'static str),
}

impl Display for CreationServiceError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Repo(err) => write!(f, "{err}"),
            Self::Tree(err) => write!(f, "{err}"),
            Self::InvalidContentType(value) => {
                write!(
                    f,
                    "invalid content_type `{value}`; only `markdown` is supported"
                )
            }
            Self::WorkspaceNotFound(workspace_id) => {
                write!(f, "workspace not found: {workspace_id}")
            }
            Self::TargetFolderNotInWorkspace {
                workspace_id,
                target_folder,
            } => write!(
                f,
                "target folder {target_folder} does not belong to workspace {workspace_id}"
            ),
            Self::MissingDesignatedFolder { workspace_id, role } => write!(
                f,
                "designated folder `{role}` missing for workspace {workspace_id}"
            ),
            Self::InconsistentState(msg) => write!(f, "inconsistent state: {msg}"),
        }
    }
}

impl Error for CreationServiceError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Repo(err) => Some(err),
            Self::Tree(err) => Some(err),
            Self::InvalidContentType(_) => None,
            Self::WorkspaceNotFound(_) => None,
            Self::TargetFolderNotInWorkspace { .. } => None,
            Self::MissingDesignatedFolder { .. } => None,
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

/// Canonical input for business atom creation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CreateAtomRequest {
    /// Target workspace root that owns the new atom.
    pub workspace_id: WorkspaceNodeId,
    /// Canonical body content.
    pub content: String,
    /// Content format allowlist. Currently only `markdown`.
    pub content_type: String,
    /// Optional task status. Presence promotes the atom to task view.
    pub task_status: Option<TaskStatus>,
    /// Optional start time in epoch milliseconds.
    pub start_at: Option<i64>,
    /// Optional end time in epoch milliseconds.
    pub end_at: Option<i64>,
    /// Optional tag set for immediate attachment.
    pub tags: Option<Vec<String>>,
    /// Explicit target folder. When omitted, designated routing is used.
    pub target_folder: Option<WorkspaceNodeId>,
    /// Optional explicit display name for the atom_ref node.
    pub display_name: Option<String>,
}

/// Canonical output for business atom creation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CreateAtomResult {
    /// Persisted atom snapshot as written by the service.
    pub atom: Atom,
    /// Workspace atom_ref created for the new atom.
    pub node: WorkspaceNode,
}

/// Composite service that creates atoms with mandatory workspace atom_ref.
pub struct CreationService<'conn> {
    conn: &'conn Connection,
}

impl<'conn> CreationService<'conn> {
    /// Creates service from a migrated connection.
    pub fn try_new(conn: &'conn Connection) -> Result<Self, CreationServiceError> {
        let _ = SqliteAtomRepository::try_new(conn)?;
        Ok(Self { conn })
    }

    /// Creates one atom through the canonical business write path.
    pub fn create_atom(
        &self,
        request: &CreateAtomRequest,
    ) -> Result<CreateAtomResult, CreationServiceError> {
        validate_content_type(request.content_type.as_str())?;
        let workspace_id = ensure_workspace_root_exists(self.conn, request.workspace_id)?;
        let (target_folder, origin_workspace_id) =
            resolve_target_folder(self.conn, request, workspace_id)?;

        let atom = build_atom(request);
        let display_name = normalize_optional_display_name(request.display_name.clone())
            .or_else(|| derive_display_name(atom.title.as_str()));

        let tx = begin_immediate(self.conn)?;
        let atom_repo = SqliteAtomRepository::try_new(&tx)?;
        atom_repo.create_atom(&atom)?;
        set_origin_workspace_id(&tx, atom.uuid, origin_workspace_id)?;
        write_tags(&tx, atom.uuid, request.tags.as_deref().unwrap_or(&[]))?;

        let tree_repo = SqliteTreeRepository::try_new(&tx)
            .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?;
        let node = TreeService::new(tree_repo).create_atom_ref(
            Some(target_folder),
            atom.uuid,
            display_name,
        )?;

        commit(tx)?;
        Ok(CreateAtomResult { atom, node })
    }

    /// Creates a note atom plus one workspace atom_ref.
    pub fn create_note_with_ref(
        &self,
        content: impl Into<String>,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(NoteRecord, WorkspaceNode), CreationServiceError> {
        let workspace_id = requested_workspace_for_parent(self.conn, parent_node_id)?;
        let result = self.create_atom(&CreateAtomRequest {
            workspace_id,
            content: content.into(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: parent_node_id,
            display_name: None,
        })?;

        let record = read_back_note_record(self.conn, result.atom.uuid)?.ok_or(
            CreationServiceError::InconsistentState("created note not found in read-back"),
        )?;
        Ok((record, result.node))
    }

    /// Creates a task atom plus one workspace atom_ref.
    pub fn create_task_with_ref(
        &self,
        content: impl Into<String>,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(AtomId, WorkspaceNode), CreationServiceError> {
        let workspace_id = requested_workspace_for_parent(self.conn, parent_node_id)?;
        let result = self.create_atom(&CreateAtomRequest {
            workspace_id,
            content: content.into(),
            content_type: "markdown".to_string(),
            task_status: Some(TaskStatus::Todo),
            start_at: None,
            end_at: None,
            tags: None,
            target_folder: parent_node_id,
            display_name: None,
        })?;
        Ok((result.atom.uuid, result.node))
    }

    /// Creates an event atom plus one workspace atom_ref.
    pub fn create_event_with_ref(
        &self,
        request: &CreateEventWithRefRequest,
        parent_node_id: Option<WorkspaceNodeId>,
    ) -> Result<(AtomId, WorkspaceNode), CreationServiceError> {
        let workspace_id = requested_workspace_for_parent(self.conn, parent_node_id)?;
        let result = self.create_atom(&CreateAtomRequest {
            workspace_id,
            content: request.title.clone(),
            content_type: "markdown".to_string(),
            task_status: None,
            start_at: Some(request.start_epoch_ms),
            end_at: request.end_epoch_ms,
            tags: None,
            target_folder: parent_node_id,
            display_name: None,
        })?;
        Ok((result.atom.uuid, result.node))
    }
}

fn begin_immediate(conn: &Connection) -> Result<Transaction<'_>, CreationServiceError> {
    Transaction::new_unchecked(conn, TransactionBehavior::Immediate)
        .map_err(|err| CreationServiceError::Repo(RepoError::from(err)))
}

fn commit(tx: Transaction<'_>) -> Result<(), CreationServiceError> {
    tx.commit()
        .map_err(|err| CreationServiceError::Repo(RepoError::from(err)))
}

fn requested_workspace_for_parent(
    conn: &Connection,
    parent_node_id: Option<WorkspaceNodeId>,
) -> Result<WorkspaceNodeId, CreationServiceError> {
    match parent_node_id {
        Some(parent_node_id) => workspace_root_for_node(conn, parent_node_id),
        None => default_workspace_id(conn),
    }
}

fn default_workspace_id(conn: &Connection) -> Result<WorkspaceNodeId, CreationServiceError> {
    let workspace_meta = SqliteWorkspaceMetaRepository::try_new(conn)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?;
    workspace_meta
        .get_default_workspace()
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?
        .ok_or(CreationServiceError::InconsistentState(
            "default workspace missing",
        ))
}

fn ensure_workspace_root_exists(
    conn: &Connection,
    workspace_id: WorkspaceNodeId,
) -> Result<WorkspaceNodeId, CreationServiceError> {
    let tree_repo = SqliteTreeRepository::try_new(conn)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?;
    let node = tree_repo
        .get_node(workspace_id, false)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?
        .ok_or(CreationServiceError::WorkspaceNotFound(workspace_id))?;
    if node.kind != WorkspaceNodeKind::Workspace {
        return Err(CreationServiceError::WorkspaceNotFound(workspace_id));
    }
    Ok(workspace_id)
}

fn resolve_target_folder(
    conn: &Connection,
    request: &CreateAtomRequest,
    workspace_id: WorkspaceNodeId,
) -> Result<(WorkspaceNodeId, WorkspaceNodeId), CreationServiceError> {
    if let Some(target_folder) = request.target_folder {
        ensure_target_folder_in_workspace(conn, workspace_id, target_folder)?;
        return Ok((target_folder, workspace_id));
    }

    let role = resolve_creation_role(request);
    let workspace_meta = SqliteWorkspaceMetaRepository::try_new(conn)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?;
    let designated_folder_id = workspace_meta
        .resolve_designated(workspace_id, role)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?
        .ok_or_else(|| CreationServiceError::MissingDesignatedFolder {
            workspace_id,
            role: role.to_string(),
        })?;
    Ok((designated_folder_id, workspace_id))
}

fn ensure_target_folder_in_workspace(
    conn: &Connection,
    workspace_id: WorkspaceNodeId,
    target_folder: WorkspaceNodeId,
) -> Result<(), CreationServiceError> {
    let tree_repo = SqliteTreeRepository::try_new(conn)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?;
    let node = tree_repo
        .get_node(target_folder, false)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?
        .ok_or(CreationServiceError::Tree(TreeServiceError::NodeNotFound(
            target_folder,
        )))?;
    if node.kind != WorkspaceNodeKind::Folder {
        return Err(CreationServiceError::Tree(
            TreeServiceError::NodeMustBeFolder(target_folder),
        ));
    }

    let actual_workspace = workspace_root_for_node(conn, target_folder)?;
    if actual_workspace != workspace_id {
        return Err(CreationServiceError::TargetFolderNotInWorkspace {
            workspace_id,
            target_folder,
        });
    }
    Ok(())
}

fn workspace_root_for_node(
    conn: &Connection,
    node_uuid: WorkspaceNodeId,
) -> Result<WorkspaceNodeId, CreationServiceError> {
    let tree_repo = SqliteTreeRepository::try_new(conn)
        .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?;
    let mut cursor = Some(node_uuid);
    while let Some(current) = cursor {
        let node = tree_repo
            .get_node(current, false)
            .map_err(|err| CreationServiceError::Tree(TreeServiceError::from(err)))?
            .ok_or(CreationServiceError::Tree(TreeServiceError::NodeNotFound(
                current,
            )))?;
        if node.kind == WorkspaceNodeKind::Workspace {
            return Ok(node.node_uuid);
        }
        cursor = node.parent_uuid;
    }

    Err(CreationServiceError::InconsistentState(
        "workspace root not found for target node",
    ))
}

fn set_origin_workspace_id(
    conn: &Connection,
    atom_id: AtomId,
    workspace_id: WorkspaceNodeId,
) -> Result<(), CreationServiceError> {
    conn.execute(
        "UPDATE atoms
         SET origin_workspace_id = ?1
         WHERE uuid = ?2;",
        params![workspace_id.to_string(), atom_id.to_string()],
    )
    .map_err(|err| CreationServiceError::Repo(RepoError::from(err)))?;
    Ok(())
}

fn write_tags(
    conn: &Connection,
    atom_id: AtomId,
    tags: &[String],
) -> Result<(), CreationServiceError> {
    let normalized = normalize_tags(tags);
    if normalized.is_empty() {
        return Ok(());
    }

    for tag in normalized {
        conn.execute(
            "INSERT OR IGNORE INTO tags (name) VALUES (?1);",
            [tag.as_str()],
        )
        .map_err(|err| CreationServiceError::Repo(RepoError::from(err)))?;
        conn.execute(
            "INSERT INTO atom_tags (atom_uuid, tag_id)
             SELECT ?1, id
             FROM tags
             WHERE name = ?2 COLLATE NOCASE;",
            params![atom_id.to_string(), tag.as_str()],
        )
        .map_err(|err| CreationServiceError::Repo(RepoError::from(err)))?;
    }

    Ok(())
}

fn validate_content_type(content_type: &str) -> Result<(), CreationServiceError> {
    if content_type.trim() == "markdown" {
        Ok(())
    } else {
        Err(CreationServiceError::InvalidContentType(
            content_type.to_string(),
        ))
    }
}

fn build_atom(request: &CreateAtomRequest) -> Atom {
    let view_hint = derive_view_hint(request);
    let mut atom = Atom::new(view_hint, request.content.clone());
    atom.content_type = request.content_type.trim().to_string();
    atom.task_status = request.task_status;
    atom.start_at = request.start_at;
    atom.end_at = request.end_at;

    let preview = derive_markdown_preview(request.content.as_str());
    atom.preview_text = preview.preview_text;
    atom.preview_image = preview.preview_image;
    atom.title = derive_title(request.content.as_str(), atom.content_type.as_str());
    atom
}

fn derive_view_hint(request: &CreateAtomRequest) -> ViewHint {
    if request.task_status.is_some() {
        ViewHint::Task
    } else if request.start_at.is_some() || request.end_at.is_some() {
        ViewHint::Event
    } else {
        ViewHint::Note
    }
}

fn resolve_creation_role(request: &CreateAtomRequest) -> &'static str {
    if request.task_status.is_some() {
        "tasks"
    } else if request.start_at.is_some() || request.end_at.is_some() {
        "calendar"
    } else {
        "inbox"
    }
}

fn normalize_optional_display_name(display_name: Option<String>) -> Option<String> {
    display_name.and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.to_string())
        }
    })
}

fn derive_display_name(title: &str) -> Option<String> {
    let trimmed = title.trim();
    if trimmed.is_empty() {
        None
    } else {
        Some(trimmed.to_string())
    }
}

/// Reads back a `NoteRecord` from the atoms table for a freshly created note.
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
