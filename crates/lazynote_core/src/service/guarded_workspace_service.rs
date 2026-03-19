//! Guarded workspace-metadata facade.

use crate::guard::{AccessGuard, CallerContext, GuardedServiceError};
use crate::repo::tree_repo::WorkspaceNodeId;
use crate::repo::workspace_meta_repo::{WorkspaceMetaRepository, WorkspaceMetadata};

/// Guarded wrapper around workspace metadata reads/writes.
pub struct GuardedWorkspaceService<'a, W: WorkspaceMetaRepository> {
    guard: Box<dyn AccessGuard>,
    workspace_meta: &'a W,
}

impl<'a, W: WorkspaceMetaRepository> GuardedWorkspaceService<'a, W> {
    /// Creates a guarded workspace facade.
    pub fn new(guard: Box<dyn AccessGuard>, workspace_meta: &'a W) -> Self {
        Self {
            guard,
            workspace_meta,
        }
    }

    /// Lists only workspaces the caller can read.
    pub fn list_workspaces(
        &self,
        caller: &CallerContext,
    ) -> Result<Vec<WorkspaceMetadata>, GuardedServiceError> {
        let workspaces = self.workspace_meta.list_workspaces()?;
        let mut visible = Vec::new();
        for workspace in workspaces {
            if self
                .guard
                .check_read(caller, &workspace.workspace_id)
                .is_ok()
            {
                visible.push(workspace);
            }
        }
        Ok(visible)
    }

    /// Returns the default workspace, if configured.
    pub fn get_default_workspace(
        &self,
        caller: &CallerContext,
    ) -> Result<Option<WorkspaceMetadata>, GuardedServiceError> {
        let default_id = self.workspace_meta.get_default_workspace()?;
        let workspaces = self.workspace_meta.list_workspaces()?;
        let item = workspaces
            .into_iter()
            .find(|workspace| Some(workspace.workspace_id) == default_id);
        if let Some(workspace) = &item {
            self.guard.check_read(caller, &workspace.workspace_id)?;
        }
        Ok(item)
    }

    /// Resolves one designated folder role after a read check.
    pub fn resolve_designated(
        &self,
        caller: &CallerContext,
        workspace_id: WorkspaceNodeId,
        role: &str,
    ) -> Result<Option<WorkspaceNodeId>, GuardedServiceError> {
        self.guard.check_read(caller, &workspace_id)?;
        self.workspace_meta
            .resolve_designated(workspace_id, role)
            .map_err(Into::into)
    }

    /// Reassigns one designated folder role after a write check.
    pub fn reassign_designated(
        &self,
        caller: &CallerContext,
        workspace_id: WorkspaceNodeId,
        role: &str,
        new_node_uuid: WorkspaceNodeId,
    ) -> Result<(), GuardedServiceError> {
        self.guard.check_write(caller, &workspace_id)?;
        self.workspace_meta
            .reassign_designated(workspace_id, role, new_node_uuid)
            .map_err(Into::into)
    }
}
