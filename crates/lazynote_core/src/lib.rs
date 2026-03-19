//! Core domain logic for LazyNote.
//! This crate is the single source of truth for business invariants.

/// Database open/migration APIs.
pub mod db;
/// Extension kernel declaration contracts.
pub mod extension;
/// Access-guard contracts used by guarded FFI facades.
pub mod guard;
/// Structured logging initialization and status APIs.
pub mod logging;
/// Canonical Atom data model.
pub mod model;
/// Persistence contracts and SQLite repository implementations.
pub mod repo;
/// FTS5 search APIs.
pub mod search;
/// Use-case orchestration services.
pub mod service;
/// Provider SPI and sync contracts.
pub mod sync;

/// Re-export extension runtime capability guard contracts.
pub use extension::capability::{
    parse_runtime_capability, supported_runtime_capability_strings, RuntimeCapability,
    RuntimeCapabilityError, RUNTIME_CAPABILITY_CALENDAR, RUNTIME_CAPABILITY_FILE,
    RUNTIME_CAPABILITY_NETWORK, RUNTIME_CAPABILITY_NOTIFICATION,
};
/// Re-export extension kernel contracts.
pub use extension::kernel::{
    ExtensionAdapter, ExtensionHealth, ExtensionInvocation, ExtensionKernelError,
    ExtensionRegistry, ExtensionSource, FirstPartyExtensionAdapter, RegisteredExtension,
};
/// Re-export extension manifest contracts.
pub use extension::manifest::{
    supported_capabilities, ExtensionManifest, ManifestEntrypoints, ManifestValidationError,
    CAPABILITY_COMMAND, CAPABILITY_PARSER, CAPABILITY_PROVIDER, CAPABILITY_UI_SLOT,
};
/// Re-export guard contracts and guarded facade errors.
pub use guard::{
    resolve_workspace_for_atom, resolve_workspace_root, AccessError, AccessGuard, CallerContext,
    CallerIdentity, Capability, GuardedServiceError, NoopGuard,
};
/// Re-export logging entry points for FFI/UI layers.
pub use logging::{
    default_log_level, init_logging, log_dart_event, logging_status, LogDartEventError,
};
/// Re-export canonical Atom model types.
pub use model::atom::{Atom, AtomId, AtomValidationError, TaskStatus, ViewHint};
/// Re-export repository contracts and SQLite implementation.
pub use repo::atom_repo::{
    AtomListQuery, AtomRepository, RepoError, RepoResult, SectionAtomRow, SqliteAtomRepository,
};
/// Re-export notes/tags repository models and implementation.
pub use repo::note_repo::{
    load_tags_for_atoms, normalize_note_limit, normalize_tag, normalize_tags, NoteListQuery,
    NoteRecord, NoteRepository, SqliteNoteRepository,
};
/// Re-export scoped subtree query contracts and implementation.
pub use repo::scoped_query_repo::{
    ProjectionMode, ScopedAtomQuery, ScopedAtomResult, ScopedQueryError, ScopedQueryRepository,
    SortSpec, SqliteScopedQueryRepository, StatusFilter, TimeFilter, TimeShapeFilter,
};
/// Re-export workspace tree repository contracts and implementation.
pub use repo::tree_repo::{
    AtomRefLocation, SqliteTreeRepository, TreeRepoError, TreeRepoResult, TreeRepository,
    WorkspaceNode, WorkspaceNodeId, WorkspaceNodeKind,
};
/// Re-export workspace metadata repository contracts and implementation.
pub use repo::workspace_meta_repo::{
    SqliteWorkspaceMetaRepository, WorkspaceMetaRepository, WorkspaceMetadata,
};
/// Re-export search query/result models and search entry point.
pub use search::fts::{search_all, SearchError, SearchHit, SearchQuery, SearchResult};
/// Re-export atom service facade.
pub use service::atom_service::{AtomService, ScheduleEventRequest};
/// Re-export unified creation service facade and errors.
pub use service::creation_service::{
    CreateAtomRequest, CreateAtomResult, CreateEventWithRefRequest, CreationService,
    CreationServiceError,
};
/// Re-export guarded service facades.
pub use service::guarded_atom_service::GuardedAtomService;
pub use service::guarded_creation_service::GuardedCreationService;
pub use service::guarded_query_service::GuardedQueryService;
pub use service::guarded_task_service::GuardedTaskService;
pub use service::guarded_tree_service::GuardedTreeService;
pub use service::guarded_workspace_service::GuardedWorkspaceService;
/// Re-export notes service facade and models.
pub use service::note_service::{
    derive_markdown_preview, MarkdownPreview, NoteService, NoteServiceError, NotesListResult,
};
/// Re-export task/section service facade and models.
pub use service::task_service::{SectionAtom, TaskService, TaskServiceError};
/// Re-export workspace tree service facade and errors.
pub use service::tree_service::{FolderDeleteMode, TreeService, TreeServiceError};
/// Re-export provider SPI and sync contract models.
pub use sync::provider_registry::{ProviderRegistry, ProviderRegistryError};
pub use sync::provider_spi::ProviderSpi;
pub use sync::provider_types::{
    now_epoch_ms, ConflictMapDecision, ConflictReason, ConflictResolution, ProviderAuthRequest,
    ProviderAuthResult, ProviderAuthState, ProviderConflict, ProviderConflictMapRequest,
    ProviderConflictMapResult, ProviderErrorEnvelope, ProviderHealth, ProviderPullRequest,
    ProviderPullResult, ProviderPushChange, ProviderPushRequest, ProviderPushResult,
    ProviderRecord, ProviderResult, ProviderStatus, PushOperation, SyncEntityKind, SyncStage,
    SyncSummary,
};

/// Minimal health-check API for early integration.
pub fn ping() -> &'static str {
    "pong"
}

/// Returns the core crate version.
pub fn core_version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

#[cfg(test)]
mod tests {
    use super::{core_version, ping};

    #[test]
    fn ping_returns_pong() {
        assert_eq!(ping(), "pong");
    }

    #[test]
    fn version_is_not_empty() {
        assert!(!core_version().is_empty());
    }
}
