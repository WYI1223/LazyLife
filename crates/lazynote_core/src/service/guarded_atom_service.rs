//! Guarded atom/note facade.

use crate::guard::{resolve_workspace_for_atom, AccessGuard, CallerContext, GuardedServiceError};
use crate::model::atom::AtomId;
use crate::repo::atom_repo::AtomRepository;
use crate::repo::note_repo::{NoteRecord, NoteRepository};
use crate::repo::scoped_query_repo::ScopedQueryRepository;
use crate::repo::tree_repo::TreeRepository;
use crate::repo::workspace_meta_repo::WorkspaceMetaRepository;
use crate::service::note_service::{NoteService, NoteServiceError};
use crate::service::task_service::{SectionAtom, TaskService, TaskServiceError};

/// Guarded wrapper around note and atom read/write operations.
pub struct GuardedAtomService<
    'a,
    N: NoteRepository,
    A: AtomRepository,
    S: ScopedQueryRepository,
    W: WorkspaceMetaRepository,
    T: TreeRepository,
> {
    guard: Box<dyn AccessGuard>,
    note_service: &'a mut NoteService<N>,
    task_service: &'a TaskService<'a, A, S, W>,
    tree_repo: &'a T,
}

impl<
        'a,
        N: NoteRepository,
        A: AtomRepository,
        S: ScopedQueryRepository,
        W: WorkspaceMetaRepository,
        T: TreeRepository,
    > GuardedAtomService<'a, N, A, S, W, T>
{
    /// Creates a guarded atom facade.
    pub fn new(
        guard: Box<dyn AccessGuard>,
        note_service: &'a mut NoteService<N>,
        task_service: &'a TaskService<'a, A, S, W>,
        tree_repo: &'a T,
    ) -> Self {
        Self {
            guard,
            note_service,
            task_service,
            tree_repo,
        }
    }

    fn require_note_exists(&self, atom_uuid: AtomId) -> Result<(), GuardedServiceError> {
        if self.tree_repo.atom_view_hint(atom_uuid)?.is_none() {
            return Err(NoteServiceError::NoteNotFound(atom_uuid).into());
        }
        Ok(())
    }

    fn require_atom_exists(&self, atom_uuid: AtomId) -> Result<(), GuardedServiceError> {
        if self.tree_repo.atom_view_hint(atom_uuid)?.is_none() {
            return Err(TaskServiceError::AtomNotFound(atom_uuid).into());
        }
        Ok(())
    }

    /// Loads one note after a read check.
    pub fn get_note(
        &mut self,
        caller: &CallerContext,
        atom_uuid: AtomId,
    ) -> Result<Option<NoteRecord>, GuardedServiceError> {
        self.require_note_exists(atom_uuid)?;
        let workspace_id = resolve_workspace_for_atom(self.tree_repo, atom_uuid)?;
        self.guard.check_read(caller, &workspace_id)?;
        self.note_service.get_note(atom_uuid).map_err(Into::into)
    }

    /// Loads one atom after a read check.
    pub fn get_atom(
        &self,
        caller: &CallerContext,
        atom_uuid: AtomId,
    ) -> Result<Option<SectionAtom>, GuardedServiceError> {
        self.require_atom_exists(atom_uuid)?;
        let workspace_id = resolve_workspace_for_atom(self.tree_repo, atom_uuid)?;
        self.guard.check_read(caller, &workspace_id)?;
        self.task_service
            .get_atom_record(atom_uuid)
            .map_err(Into::into)
    }

    /// Updates note content after a write check.
    pub fn update_content(
        &mut self,
        caller: &CallerContext,
        atom_uuid: AtomId,
        content: impl Into<String>,
    ) -> Result<NoteRecord, GuardedServiceError> {
        self.require_note_exists(atom_uuid)?;
        let workspace_id = resolve_workspace_for_atom(self.tree_repo, atom_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.note_service
            .update_note(atom_uuid, content)
            .map_err(Into::into)
    }

    /// Replaces note tags after a write check.
    pub fn set_tags(
        &mut self,
        caller: &CallerContext,
        atom_uuid: AtomId,
        tags: Vec<String>,
    ) -> Result<NoteRecord, GuardedServiceError> {
        self.require_note_exists(atom_uuid)?;
        let workspace_id = resolve_workspace_for_atom(self.tree_repo, atom_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.note_service
            .set_note_tags(atom_uuid, tags)
            .map_err(Into::into)
    }

    /// Updates calendar event times after a write check.
    pub fn update_time(
        &self,
        caller: &CallerContext,
        atom_uuid: AtomId,
        start_at: i64,
        end_at: i64,
    ) -> Result<(), GuardedServiceError> {
        self.require_atom_exists(atom_uuid)?;
        let workspace_id = resolve_workspace_for_atom(self.tree_repo, atom_uuid)?;
        self.guard.check_write(caller, &workspace_id)?;
        self.task_service
            .update_event_times(atom_uuid, start_at, end_at)
            .map_err(Into::into)
    }
}
