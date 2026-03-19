//! Guard contracts for workspace-aware access control at the FFI boundary.

use crate::model::atom::AtomId;
use crate::repo::atom_repo::RepoError;
use crate::repo::scoped_query_repo::ScopedQueryError;
use crate::repo::tree_repo::{TreeRepoError, TreeRepository, WorkspaceNodeId, WorkspaceNodeKind};
use crate::service::creation_service::CreationServiceError;
use crate::service::note_service::NoteServiceError;
use crate::service::task_service::TaskServiceError;
use crate::service::tree_service::TreeServiceError;
use std::error::Error;
use std::fmt::{Display, Formatter};

/// Caller identity attached to one guarded request.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CallerIdentity {
    /// Flutter app runtime.
    App,
}

/// Capability families that future guards may enforce.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Capability {
    /// Workspace-scoped read capability.
    WorkspaceRead,
    /// Workspace-scoped write capability.
    WorkspaceWrite,
}

/// Request caller context passed through guarded FFI exports.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CallerContext {
    /// Calling identity.
    pub identity: CallerIdentity,
    /// Optional declared workspace scope.
    pub scope_workspace_id: Option<WorkspaceNodeId>,
}

/// Guard-level access denial.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AccessError {
    /// Caller scope does not cover the target workspace.
    CrossWorkspaceAccessDenied {
        /// Declared scope on the caller.
        scope: WorkspaceNodeId,
        /// Workspace resolved for the target entity.
        target: WorkspaceNodeId,
    },
    /// Caller lacks one required capability.
    InsufficientCapability {
        /// Calling identity.
        identity: CallerIdentity,
        /// Missing capability.
        required: Capability,
    },
}

impl AccessError {
    /// Stable machine-readable code.
    pub fn code(&self) -> &'static str {
        match self {
            Self::CrossWorkspaceAccessDenied { .. } => "cross_workspace_access_denied",
            Self::InsufficientCapability { .. } => "insufficient_capability",
        }
    }
}

impl Display for AccessError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::CrossWorkspaceAccessDenied { scope, target } => write!(
                f,
                "caller scope `{scope}` does not cover workspace `{target}`"
            ),
            Self::InsufficientCapability { identity, required } => write!(
                f,
                "caller `{:?}` lacks required capability `{:?}`",
                identity, required
            ),
        }
    }
}

impl Error for AccessError {}

/// Runtime-pluggable access guard.
pub trait AccessGuard: Send + Sync {
    /// Validates one workspace-scoped read.
    fn check_read(
        &self,
        caller: &CallerContext,
        target_workspace: &WorkspaceNodeId,
    ) -> Result<(), AccessError>;

    /// Validates one workspace-scoped write.
    fn check_write(
        &self,
        caller: &CallerContext,
        target_workspace: &WorkspaceNodeId,
    ) -> Result<(), AccessError>;
}

/// Default v0.4 guard implementation that allows every request through.
#[derive(Debug, Clone, Copy, Default)]
pub struct NoopGuard;

impl AccessGuard for NoopGuard {
    fn check_read(
        &self,
        _caller: &CallerContext,
        _target_workspace: &WorkspaceNodeId,
    ) -> Result<(), AccessError> {
        Ok(())
    }

    fn check_write(
        &self,
        _caller: &CallerContext,
        _target_workspace: &WorkspaceNodeId,
    ) -> Result<(), AccessError> {
        Ok(())
    }
}

/// Shared error surface returned by guarded facades.
#[derive(Debug)]
pub enum GuardedServiceError {
    /// Access denied before the inner service ran.
    Access(AccessError),
    /// Scoped query descriptor or execution error.
    Query(ScopedQueryError),
    /// Canonical creation failure.
    Creation(CreationServiceError),
    /// Note service failure.
    Note(NoteServiceError),
    /// Task service failure.
    Task(TaskServiceError),
    /// Tree service failure.
    Tree(TreeServiceError),
    /// Workspace metadata or lookup failure.
    Workspace(TreeRepoError),
    /// Generic atom repository failure.
    Repo(RepoError),
}

impl Display for GuardedServiceError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Access(err) => write!(f, "{err}"),
            Self::Query(err) => write!(f, "{err}"),
            Self::Creation(err) => write!(f, "{err}"),
            Self::Note(err) => write!(f, "{err}"),
            Self::Task(err) => write!(f, "{err}"),
            Self::Tree(err) => write!(f, "{err}"),
            Self::Workspace(err) => write!(f, "{err}"),
            Self::Repo(err) => write!(f, "{err}"),
        }
    }
}

impl Error for GuardedServiceError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Access(err) => Some(err),
            Self::Query(err) => Some(err),
            Self::Creation(err) => Some(err),
            Self::Note(err) => Some(err),
            Self::Task(err) => Some(err),
            Self::Tree(err) => Some(err),
            Self::Workspace(err) => Some(err),
            Self::Repo(err) => Some(err),
        }
    }
}

impl From<AccessError> for GuardedServiceError {
    fn from(value: AccessError) -> Self {
        Self::Access(value)
    }
}

impl From<ScopedQueryError> for GuardedServiceError {
    fn from(value: ScopedQueryError) -> Self {
        Self::Query(value)
    }
}

impl From<CreationServiceError> for GuardedServiceError {
    fn from(value: CreationServiceError) -> Self {
        Self::Creation(value)
    }
}

impl From<NoteServiceError> for GuardedServiceError {
    fn from(value: NoteServiceError) -> Self {
        Self::Note(value)
    }
}

impl From<TaskServiceError> for GuardedServiceError {
    fn from(value: TaskServiceError) -> Self {
        Self::Task(value)
    }
}

impl From<TreeServiceError> for GuardedServiceError {
    fn from(value: TreeServiceError) -> Self {
        Self::Tree(value)
    }
}

impl From<TreeRepoError> for GuardedServiceError {
    fn from(value: TreeRepoError) -> Self {
        Self::Workspace(value)
    }
}

impl From<RepoError> for GuardedServiceError {
    fn from(value: RepoError) -> Self {
        Self::Repo(value)
    }
}

/// Resolves the workspace root that owns one node.
pub fn resolve_workspace_root<T: TreeRepository>(
    tree_repo: &T,
    node_uuid: WorkspaceNodeId,
) -> Result<WorkspaceNodeId, TreeRepoError> {
    let mut cursor = Some(node_uuid);
    while let Some(current) = cursor {
        let node = tree_repo
            .get_node(current, false)?
            .ok_or(TreeRepoError::NodeNotFound(current))?;
        if node.kind == WorkspaceNodeKind::Workspace {
            return Ok(node.node_uuid);
        }
        cursor = node.parent_uuid;
    }

    Err(TreeRepoError::InvalidData(
        "workspace root not found for node".to_string(),
    ))
}

/// Resolves the workspace root for one atom from its first active atom_ref.
pub fn resolve_workspace_for_atom<T: TreeRepository>(
    tree_repo: &T,
    atom_uuid: AtomId,
) -> Result<WorkspaceNodeId, TreeRepoError> {
    tree_repo
        .list_atom_refs_for_atom(atom_uuid)?
        .into_iter()
        .next()
        .map(|location| location.workspace_id)
        .ok_or(TreeRepoError::InvalidData(format!(
            "active atom_ref location not found for atom `{atom_uuid}`"
        )))
}
