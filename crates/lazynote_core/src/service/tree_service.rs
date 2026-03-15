//! Workspace tree use-case service.
//!
//! # Responsibility
//! - Validate tree hierarchy invariants above repository layer.
//! - Provide folder/atom_ref create, rename, move, and list operations.
//!
//! # Invariants
//! - Parent node must exist and be a container node when provided.
//! - Move operations must not create parent-child cycles.
//! - `atom_ref` must target an active atom (any view_hint).

use crate::model::atom::AtomId;
use crate::repo::tree_repo::{
    AtomRefLocation, TreeRepoError, TreeRepository, WorkspaceNode, WorkspaceNodeId,
    WorkspaceNodeKind,
};
use crate::repo::workspace_meta_repo::{WorkspaceMetaRepository, WorkspaceMetadata};
use std::collections::HashSet;
use std::error::Error;
use std::fmt::{Display, Formatter};

/// Folder delete mode for workspace tree.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FolderDeleteMode {
    /// Delete folder node only and move direct children to root.
    Dissolve,
    /// Delete folder subtree and soft-delete atoms with no remaining refs.
    DeleteAll,
}

/// Errors from workspace tree service operations.
#[derive(Debug)]
pub enum TreeServiceError {
    /// Display name is blank after trim.
    InvalidDisplayName,
    /// Target node does not exist.
    NodeNotFound(WorkspaceNodeId),
    /// Parent node does not exist.
    ParentNotFound(WorkspaceNodeId),
    /// Parent exists but is not folder kind.
    ParentMustBeFolder(WorkspaceNodeId),
    /// Target node exists but is not folder kind.
    NodeMustBeFolder(WorkspaceNodeId),
    /// Target atom does not exist or is soft-deleted.
    AtomNotFound(AtomId),
    /// Move operation would create a cycle.
    CycleDetected {
        node_uuid: WorkspaceNodeId,
        parent_uuid: WorkspaceNodeId,
    },
    /// Workspace root node cannot be deleted.
    WorkspaceRootProtected(WorkspaceNodeId),
    /// Designated folder cannot be deleted until role is reassigned.
    DesignatedFolderProtected(WorkspaceNodeId),
    /// Workspace root node cannot be moved.
    CannotMoveWorkspaceRoot(WorkspaceNodeId),
    /// Root level is reserved for workspace roots after migration 0012.
    CannotMoveToRoot(WorkspaceNodeId),
    /// Source node and target parent belong to different workspaces.
    CrossWorkspaceMoveNotAllowed {
        node_uuid: WorkspaceNodeId,
        target_parent: WorkspaceNodeId,
    },
    /// Designated folder target belongs to another workspace.
    DesignatedFolderWrongWorkspace {
        workspace_id: WorkspaceNodeId,
        node_uuid: WorkspaceNodeId,
    },
    /// Repository-level failure.
    Repo(TreeRepoError),
}

impl Display for TreeServiceError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidDisplayName => write!(f, "display name must not be blank"),
            Self::NodeNotFound(id) => write!(f, "workspace node not found: {id}"),
            Self::ParentNotFound(id) => write!(f, "workspace parent not found: {id}"),
            Self::ParentMustBeFolder(id) => {
                write!(f, "workspace parent must be folder: {id}")
            }
            Self::NodeMustBeFolder(id) => write!(f, "workspace node must be folder: {id}"),
            Self::AtomNotFound(id) => write!(f, "atom not found: {id}"),
            Self::CycleDetected {
                node_uuid,
                parent_uuid,
            } => write!(
                f,
                "move would create cycle: node {node_uuid} under parent {parent_uuid}"
            ),
            Self::WorkspaceRootProtected(node_uuid) => {
                write!(f, "workspace root node is protected: {node_uuid}")
            }
            Self::DesignatedFolderProtected(node_uuid) => {
                write!(f, "designated folder is protected until reassigned: {node_uuid}")
            }
            Self::CannotMoveWorkspaceRoot(node_uuid) => {
                write!(f, "workspace root node cannot be moved: {node_uuid}")
            }
            Self::CannotMoveToRoot(node_uuid) => {
                write!(f, "workspace node cannot move to root level: {node_uuid}")
            }
            Self::CrossWorkspaceMoveNotAllowed {
                node_uuid,
                target_parent,
            } => write!(
                f,
                "workspace node cannot move across workspaces: node {node_uuid} target {target_parent}"
            ),
            Self::DesignatedFolderWrongWorkspace {
                workspace_id,
                node_uuid,
            } => write!(
                f,
                "designated folder must belong to workspace {workspace_id}: {node_uuid}"
            ),
            Self::Repo(err) => write!(f, "{err}"),
        }
    }
}

impl Error for TreeServiceError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Repo(err) => Some(err),
            _ => None,
        }
    }
}

impl From<TreeRepoError> for TreeServiceError {
    fn from(value: TreeRepoError) -> Self {
        match value {
            TreeRepoError::NodeNotFound(node_uuid) => Self::NodeNotFound(node_uuid),
            TreeRepoError::NodeNotFolder(node_uuid) => Self::NodeMustBeFolder(node_uuid),
            TreeRepoError::CannotMoveToRoot(node_uuid) => Self::CannotMoveToRoot(node_uuid),
            other => Self::Repo(other),
        }
    }
}

/// No-op workspace metadata adapter used by legacy tree-only call sites.
#[derive(Debug, Clone, Copy, Default)]
pub struct NoopWorkspaceMetaRepository;

impl WorkspaceMetaRepository for NoopWorkspaceMetaRepository {
    fn get_default_workspace(&self) -> Result<Option<WorkspaceNodeId>, TreeRepoError> {
        Ok(None)
    }

    fn list_workspaces(&self) -> Result<Vec<WorkspaceMetadata>, TreeRepoError> {
        Ok(vec![])
    }

    fn resolve_designated(
        &self,
        _workspace_id: WorkspaceNodeId,
        _role: &str,
    ) -> Result<Option<WorkspaceNodeId>, TreeRepoError> {
        Ok(None)
    }

    fn is_designated(&self, _node_uuid: WorkspaceNodeId) -> Result<bool, TreeRepoError> {
        Ok(false)
    }

    fn reassign_designated(
        &self,
        _workspace_id: WorkspaceNodeId,
        _role: &str,
        _new_node_uuid: WorkspaceNodeId,
    ) -> Result<(), TreeRepoError> {
        Err(TreeRepoError::InvalidData(
            "workspace metadata repository not configured".to_string(),
        ))
    }
}

/// Workspace tree service facade.
pub struct TreeService<R: TreeRepository, W: WorkspaceMetaRepository = NoopWorkspaceMetaRepository>
{
    repo: R,
    workspace_meta: W,
}

impl<R: TreeRepository> TreeService<R, NoopWorkspaceMetaRepository> {
    /// Creates service from repository implementation.
    pub fn new(repo: R) -> Self {
        Self {
            repo,
            workspace_meta: NoopWorkspaceMetaRepository,
        }
    }
}

impl<R: TreeRepository, W: WorkspaceMetaRepository> TreeService<R, W> {
    /// Creates service from repository and workspace metadata implementations.
    pub fn with_workspace_meta(repo: R, workspace_meta: W) -> Self {
        Self {
            repo,
            workspace_meta,
        }
    }

    /// Creates one folder under optional parent.
    pub fn create_folder(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        display_name: impl Into<String>,
    ) -> Result<WorkspaceNode, TreeServiceError> {
        let normalized = normalize_display_name(display_name.into())?;
        if let Some(parent_uuid) = parent_uuid {
            self.ensure_parent_is_container(parent_uuid)?;
        }
        self.repo
            .create_folder(parent_uuid, normalized.as_str())
            .map_err(Into::into)
    }

    /// Creates one atom_ref under optional parent.
    pub fn create_atom_ref(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
        atom_uuid: AtomId,
        display_name: Option<String>,
    ) -> Result<WorkspaceNode, TreeServiceError> {
        if let Some(parent_uuid) = parent_uuid {
            self.ensure_parent_is_container(parent_uuid)?;
        }
        self.ensure_atom_exists(atom_uuid)?;

        let normalized = match display_name {
            Some(value) => normalize_display_name(value)?,
            None => "Untitled".to_string(),
        };

        self.repo
            .create_atom_ref(parent_uuid, atom_uuid, normalized.as_str())
            .map_err(Into::into)
    }

    /// Lists child nodes under optional parent.
    pub fn list_children(
        &self,
        parent_uuid: Option<WorkspaceNodeId>,
    ) -> Result<Vec<WorkspaceNode>, TreeServiceError> {
        if let Some(parent_uuid) = parent_uuid {
            self.ensure_parent_is_container(parent_uuid)?;
        }
        self.repo
            .list_children(parent_uuid, false)
            .map_err(Into::into)
    }

    /// Renames one node.
    pub fn rename_node(
        &self,
        node_uuid: WorkspaceNodeId,
        display_name: impl Into<String>,
    ) -> Result<(), TreeServiceError> {
        let normalized = normalize_display_name(display_name.into())?;
        self.repo
            .rename_node(node_uuid, normalized.as_str())
            .map_err(Into::into)
    }

    /// Moves one node under optional parent and optional sibling index.
    pub fn move_node(
        &self,
        node_uuid: WorkspaceNodeId,
        new_parent_uuid: Option<WorkspaceNodeId>,
        target_order: Option<i64>,
    ) -> Result<(), TreeServiceError> {
        let node = self
            .repo
            .get_node(node_uuid, false)?
            .ok_or(TreeServiceError::NodeNotFound(node_uuid))?;
        if node.kind == WorkspaceNodeKind::Workspace {
            return Err(TreeServiceError::CannotMoveWorkspaceRoot(node_uuid));
        }
        if new_parent_uuid.is_none() {
            return Err(TreeServiceError::CannotMoveToRoot(node_uuid));
        }

        if let Some(parent_uuid) = new_parent_uuid {
            if parent_uuid == node_uuid {
                return Err(TreeServiceError::CycleDetected {
                    node_uuid,
                    parent_uuid,
                });
            }

            self.ensure_parent_is_container(parent_uuid)?;
            let source_workspace = self.workspace_root_for_node(node_uuid)?;
            let target_workspace = self.workspace_root_for_node(parent_uuid)?;
            if source_workspace != target_workspace {
                return Err(TreeServiceError::CrossWorkspaceMoveNotAllowed {
                    node_uuid,
                    target_parent: parent_uuid,
                });
            }
            if self.would_create_cycle(node_uuid, parent_uuid)? {
                return Err(TreeServiceError::CycleDetected {
                    node_uuid,
                    parent_uuid,
                });
            }
        }

        self.repo
            .move_node(
                node_uuid,
                new_parent_uuid,
                target_order.map(|value| value.max(0)),
            )
            .map_err(Into::into)
    }

    /// Deletes a folder by mode.
    pub fn delete_folder(
        &self,
        folder_uuid: WorkspaceNodeId,
        mode: FolderDeleteMode,
    ) -> Result<(), TreeServiceError> {
        let folder = self
            .repo
            .get_node(folder_uuid, false)?
            .ok_or(TreeServiceError::NodeNotFound(folder_uuid))?;
        if folder.kind == WorkspaceNodeKind::Workspace {
            return Err(TreeServiceError::WorkspaceRootProtected(folder_uuid));
        }
        if folder.kind != WorkspaceNodeKind::Folder {
            return Err(TreeServiceError::NodeMustBeFolder(folder_uuid));
        }
        if self.workspace_meta.is_designated(folder_uuid)? {
            return Err(TreeServiceError::DesignatedFolderProtected(folder_uuid));
        }

        match mode {
            FolderDeleteMode::Dissolve => self.repo.delete_folder_dissolve(folder_uuid)?,
            FolderDeleteMode::DeleteAll => self.repo.delete_folder_delete_all(folder_uuid)?,
        }
        Ok(())
    }

    /// Returns ancestor folder display_names from root to direct parent
    /// for the given atom's first active `atom_ref`.
    pub fn ancestor_path(&self, atom_uuid: AtomId) -> Result<Vec<String>, TreeServiceError> {
        self.repo.ancestor_path(atom_uuid).map_err(Into::into)
    }

    /// Returns ancestor segments from workspace root to direct parent for one node.
    pub fn get_ancestor_path(
        &self,
        node_uuid: WorkspaceNodeId,
    ) -> Result<Vec<(WorkspaceNodeId, String)>, TreeServiceError> {
        self.repo.get_ancestor_path(node_uuid).map_err(Into::into)
    }

    /// Returns every active atom_ref location for one atom.
    pub fn list_atom_refs_for_atom(
        &self,
        atom_uuid: AtomId,
    ) -> Result<Vec<AtomRefLocation>, TreeServiceError> {
        self.repo
            .list_atom_refs_for_atom(atom_uuid)
            .map_err(Into::into)
    }

    /// Reassigns one designated role to another folder in the same workspace tree.
    pub fn reassign_designated(
        &self,
        workspace_id: WorkspaceNodeId,
        role: &str,
        new_node_uuid: WorkspaceNodeId,
    ) -> Result<(), TreeServiceError> {
        let workspace = self
            .repo
            .get_node(workspace_id, false)?
            .ok_or(TreeServiceError::NodeNotFound(workspace_id))?;
        if workspace.kind != WorkspaceNodeKind::Workspace {
            return Err(TreeServiceError::Repo(TreeRepoError::InvalidData(
                "designated reassign requires a workspace root id".to_string(),
            )));
        }

        let node = self
            .repo
            .get_node(new_node_uuid, false)?
            .ok_or(TreeServiceError::NodeNotFound(new_node_uuid))?;
        if node.kind != WorkspaceNodeKind::Folder {
            return Err(TreeServiceError::NodeMustBeFolder(new_node_uuid));
        }

        let target_workspace = self.workspace_root_for_node(new_node_uuid)?;
        if target_workspace != workspace_id {
            return Err(TreeServiceError::DesignatedFolderWrongWorkspace {
                workspace_id,
                node_uuid: new_node_uuid,
            });
        }

        self.workspace_meta
            .reassign_designated(workspace_id, role, new_node_uuid)?;
        Ok(())
    }

    fn ensure_parent_is_container(
        &self,
        parent_uuid: WorkspaceNodeId,
    ) -> Result<(), TreeServiceError> {
        let parent = self
            .repo
            .get_node(parent_uuid, false)?
            .ok_or(TreeServiceError::ParentNotFound(parent_uuid))?;
        if parent.kind != WorkspaceNodeKind::Folder && parent.kind != WorkspaceNodeKind::Workspace {
            return Err(TreeServiceError::ParentMustBeFolder(parent_uuid));
        }
        Ok(())
    }

    fn ensure_atom_exists(&self, atom_uuid: AtomId) -> Result<(), TreeServiceError> {
        match self.repo.atom_view_hint(atom_uuid)? {
            None => Err(TreeServiceError::AtomNotFound(atom_uuid)),
            Some(_) => Ok(()),
        }
    }

    fn would_create_cycle(
        &self,
        node_uuid: WorkspaceNodeId,
        candidate_parent_uuid: WorkspaceNodeId,
    ) -> Result<bool, TreeServiceError> {
        let mut visited = HashSet::new();
        let mut cursor = Some(candidate_parent_uuid);
        while let Some(current) = cursor {
            if current == node_uuid {
                return Ok(true);
            }
            if !visited.insert(current) {
                return Ok(true);
            }

            let node = self
                .repo
                .get_node(current, false)?
                .ok_or(TreeServiceError::ParentNotFound(current))?;
            cursor = node.parent_uuid;
        }
        Ok(false)
    }

    pub(crate) fn workspace_root_for_node(
        &self,
        node_uuid: WorkspaceNodeId,
    ) -> Result<WorkspaceNodeId, TreeServiceError> {
        let mut visited = HashSet::new();
        let mut cursor = Some(node_uuid);
        while let Some(current) = cursor {
            if !visited.insert(current) {
                return Err(TreeServiceError::Repo(TreeRepoError::InvalidData(
                    "workspace tree contains cycle while resolving workspace root".to_string(),
                )));
            }

            let node = self
                .repo
                .get_node(current, false)?
                .ok_or(TreeServiceError::NodeNotFound(current))?;
            if node.kind == WorkspaceNodeKind::Workspace {
                return Ok(node.node_uuid);
            }
            cursor = node.parent_uuid;
        }

        Err(TreeServiceError::Repo(TreeRepoError::InvalidData(
            "workspace root not found for node".to_string(),
        )))
    }
}

fn normalize_display_name(value: String) -> Result<String, TreeServiceError> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return Err(TreeServiceError::InvalidDisplayName);
    }
    Ok(trimmed.to_string())
}
