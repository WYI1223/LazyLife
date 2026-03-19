//! Guarded task-status facade.

use crate::guard::{resolve_workspace_for_atom, AccessGuard, CallerContext, GuardedServiceError};
use crate::model::atom::{AtomId, TaskStatus};
use crate::repo::atom_repo::AtomRepository;
use crate::repo::scoped_query_repo::ScopedQueryRepository;
use crate::repo::tree_repo::TreeRepository;
use crate::repo::workspace_meta_repo::WorkspaceMetaRepository;
use crate::service::task_service::{TaskService, TaskServiceError};

/// Guarded wrapper around task-status writes.
pub struct GuardedTaskService<
    'a,
    A: AtomRepository,
    S: ScopedQueryRepository,
    W: WorkspaceMetaRepository,
    T: TreeRepository,
> {
    guard: Box<dyn AccessGuard>,
    task_service: &'a TaskService<'a, A, S, W>,
    tree_repo: &'a T,
}

impl<
        'a,
        A: AtomRepository,
        S: ScopedQueryRepository,
        W: WorkspaceMetaRepository,
        T: TreeRepository,
    > GuardedTaskService<'a, A, S, W, T>
{
    /// Creates a guarded task facade.
    pub fn new(
        guard: Box<dyn AccessGuard>,
        task_service: &'a TaskService<'a, A, S, W>,
        tree_repo: &'a T,
    ) -> Self {
        Self {
            guard,
            task_service,
            tree_repo,
        }
    }

    fn require_atom_exists(&self, atom_uuid: AtomId) -> Result<(), GuardedServiceError> {
        if self.tree_repo.atom_view_hint(atom_uuid)?.is_none() {
            return Err(TaskServiceError::AtomNotFound(atom_uuid).into());
        }
        Ok(())
    }

    /// Updates one atom status after a write check.
    pub fn update_status(
        &self,
        caller: &CallerContext,
        atom_uuid: AtomId,
        status: Option<TaskStatus>,
    ) -> Result<(), GuardedServiceError> {
        self.require_atom_exists(atom_uuid)?;
        let workspace_id = resolve_workspace_for_atom(self.tree_repo, atom_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.task_service
            .update_status(atom_uuid, status)
            .map_err(Into::into)
    }
}
