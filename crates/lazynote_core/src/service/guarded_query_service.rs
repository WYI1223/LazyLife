//! Guarded subtree-query facade.

use crate::guard::{resolve_workspace_root, AccessGuard, CallerContext, GuardedServiceError};
use crate::repo::scoped_query_repo::{
    ProjectionMode, ScopedAtomQuery, ScopedAtomResult, ScopedQueryRepository,
};
use crate::repo::tree_repo::TreeRepository;

/// Guarded wrapper around the scoped-query repository.
pub struct GuardedQueryService<'a, S: ScopedQueryRepository, T: TreeRepository> {
    guard: Box<dyn AccessGuard>,
    scoped_repo: &'a S,
    tree_repo: &'a T,
}

impl<'a, S: ScopedQueryRepository, T: TreeRepository> GuardedQueryService<'a, S, T> {
    /// Creates a guarded query facade.
    pub fn new(guard: Box<dyn AccessGuard>, scoped_repo: &'a S, tree_repo: &'a T) -> Self {
        Self {
            guard,
            scoped_repo,
            tree_repo,
        }
    }

    /// Executes one workspace-scoped query after a read check.
    pub fn query_atoms(
        &self,
        caller: &CallerContext,
        query: ScopedAtomQuery,
        projection: ProjectionMode,
    ) -> Result<Vec<ScopedAtomResult>, GuardedServiceError> {
        let target_workspace = resolve_workspace_root(self.tree_repo, query.folder_id)?;
        self.guard.check_read(caller, &target_workspace)?;
        self.scoped_repo
            .query_scoped_atoms(query, projection)
            .map_err(Into::into)
    }
}
