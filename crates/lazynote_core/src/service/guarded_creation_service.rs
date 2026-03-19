//! Guarded creation facade.

use crate::guard::{AccessGuard, CallerContext, GuardedServiceError};
use crate::service::creation_service::{CreateAtomRequest, CreateAtomResult, CreationService};

/// Guarded wrapper around canonical atom creation.
pub struct GuardedCreationService<'a, 'conn> {
    guard: Box<dyn AccessGuard>,
    inner: &'a CreationService<'conn>,
}

impl<'a, 'conn> GuardedCreationService<'a, 'conn> {
    /// Creates a guarded creation facade.
    pub fn new(guard: Box<dyn AccessGuard>, inner: &'a CreationService<'conn>) -> Self {
        Self { guard, inner }
    }

    /// Creates one atom after a write check on the target workspace.
    pub fn create_atom(
        &self,
        caller: &CallerContext,
        request: &CreateAtomRequest,
    ) -> Result<CreateAtomResult, GuardedServiceError> {
        self.guard.check_write(caller, &request.workspace_id)?;
        self.inner.create_atom(request).map_err(Into::into)
    }
}
