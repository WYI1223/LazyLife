//! Guarded workspace-tree facade.

use crate::guard::{AccessGuard, CallerContext, GuardedServiceError};
use crate::model::atom::AtomId;
use crate::repo::tree_repo::{AtomRefLocation, TreeRepository, WorkspaceNode, WorkspaceNodeId};
use crate::repo::workspace_meta_repo::WorkspaceMetaRepository;
use crate::service::tree_service::{FolderDeleteMode, TreeService};

/// Guarded wrapper around workspace tree operations.
pub struct GuardedTreeService<'a, R: TreeRepository, W: WorkspaceMetaRepository> {
    guard: Box<dyn AccessGuard>,
    inner: &'a TreeService<R, W>,
}

impl<'a, R: TreeRepository, W: WorkspaceMetaRepository> GuardedTreeService<'a, R, W> {
    /// Creates a guarded tree facade.
    pub fn new(guard: Box<dyn AccessGuard>, inner: &'a TreeService<R, W>) -> Self {
        Self { guard, inner }
    }

    /// Lists children after a read check for the target workspace.
    pub fn list_children(
        &self,
        caller: &CallerContext,
        parent_uuid: Option<WorkspaceNodeId>,
    ) -> Result<Vec<WorkspaceNode>, GuardedServiceError> {
        if let Some(parent_uuid) = parent_uuid {
            let workspace_id = self.inner.workspace_root_for_node(parent_uuid)?;
            self.guard.check_read(caller, &workspace_id)?;
        }
        self.inner.list_children(parent_uuid).map_err(Into::into)
    }

    /// Creates one folder after a write check.
    pub fn create_folder(
        &self,
        caller: &CallerContext,
        parent_uuid: Option<WorkspaceNodeId>,
        display_name: impl Into<String>,
    ) -> Result<WorkspaceNode, GuardedServiceError> {
        let workspace_id = self.inner.workspace_for_parent_or_default(parent_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.inner
            .create_folder(parent_uuid, display_name)
            .map_err(Into::into)
    }

    /// Creates one atom_ref after a write check.
    pub fn create_atom_ref(
        &self,
        caller: &CallerContext,
        parent_uuid: Option<WorkspaceNodeId>,
        atom_uuid: AtomId,
        display_name: Option<String>,
    ) -> Result<WorkspaceNode, GuardedServiceError> {
        let workspace_id = self.inner.workspace_for_parent_or_default(parent_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.inner
            .create_atom_ref(parent_uuid, atom_uuid, display_name)
            .map_err(Into::into)
    }

    /// Renames one node after a write check.
    pub fn rename_node(
        &self,
        caller: &CallerContext,
        node_uuid: WorkspaceNodeId,
        display_name: impl Into<String>,
    ) -> Result<(), GuardedServiceError> {
        let workspace_id = self.inner.workspace_root_for_node(node_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.inner
            .rename_node(node_uuid, display_name)
            .map_err(Into::into)
    }

    /// Moves one node after a write check.
    pub fn move_node(
        &self,
        caller: &CallerContext,
        node_uuid: WorkspaceNodeId,
        new_parent_uuid: Option<WorkspaceNodeId>,
        target_order: Option<i64>,
    ) -> Result<(), GuardedServiceError> {
        let workspace_id = self.inner.workspace_root_for_node(node_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.inner
            .move_node(node_uuid, new_parent_uuid, target_order)
            .map_err(Into::into)
    }

    /// Deletes one folder after a write check.
    pub fn delete_folder(
        &self,
        caller: &CallerContext,
        folder_uuid: WorkspaceNodeId,
        mode: FolderDeleteMode,
    ) -> Result<(), GuardedServiceError> {
        let workspace_id = self.inner.workspace_root_for_node(folder_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.inner
            .delete_folder(folder_uuid, mode)
            .map_err(Into::into)
    }

    /// Returns node-based ancestor path after a read check.
    pub fn get_ancestor_path(
        &self,
        caller: &CallerContext,
        node_uuid: WorkspaceNodeId,
    ) -> Result<Vec<(WorkspaceNodeId, String)>, GuardedServiceError> {
        let workspace_id = self.inner.workspace_root_for_node(node_uuid)?;
        self.guard.check_read(caller, &workspace_id)?;
        self.inner.get_ancestor_path(node_uuid).map_err(Into::into)
    }

    /// Returns atom_ref locations after a read check.
    pub fn list_atom_refs_for_atom(
        &self,
        caller: &CallerContext,
        atom_uuid: AtomId,
    ) -> Result<Vec<AtomRefLocation>, GuardedServiceError> {
        let workspace_id = self.inner.workspace_root_for_atom(atom_uuid)?;
        self.guard.check_read(caller, &workspace_id)?;
        self.inner
            .list_atom_refs_for_atom(atom_uuid)
            .map_err(Into::into)
    }

    /// Returns compatibility atom-based ancestor path after a read check.
    pub fn ancestor_path(
        &self,
        caller: &CallerContext,
        atom_uuid: AtomId,
    ) -> Result<Vec<String>, GuardedServiceError> {
        let workspace_id = self.inner.workspace_root_for_atom(atom_uuid)?;
        self.guard.check_read(caller, &workspace_id)?;
        self.inner.ancestor_path(atom_uuid).map_err(Into::into)
    }

    /// Reassigns one designated folder after a write check.
    pub fn reassign_designated(
        &self,
        caller: &CallerContext,
        workspace_id: WorkspaceNodeId,
        role: &str,
        new_node_uuid: WorkspaceNodeId,
    ) -> Result<(), GuardedServiceError> {
        self.guard.check_write(caller, &workspace_id)?;
        self.inner
            .reassign_designated(workspace_id, role, new_node_uuid)
            .map_err(Into::into)
    }
}
