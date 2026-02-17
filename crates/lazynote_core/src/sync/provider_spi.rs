//! Provider SPI trait contracts.

use crate::sync::provider_types::{
    ProviderAuthRequest, ProviderAuthResult, ProviderConflictMapRequest, ProviderConflictMapResult,
    ProviderPullRequest, ProviderPullResult, ProviderPushRequest, ProviderPushResult,
    ProviderResult, ProviderStatus,
};

/// Provider SPI contract for auth/pull/push/conflict-map operations.
///
/// v0.2 baseline keeps this interface in-process and declaration-oriented.
pub trait ProviderSpi: Send + Sync {
    /// Stable provider identifier (for example `google_calendar`).
    fn provider_id(&self) -> &str;

    /// Current provider status snapshot.
    fn status(&self) -> ProviderStatus;

    /// Authentication operation.
    fn auth(&self, request: ProviderAuthRequest) -> ProviderResult<ProviderAuthResult>;

    /// Pull operation for remote changes.
    fn pull(&self, request: ProviderPullRequest) -> ProviderResult<ProviderPullResult>;

    /// Push operation for local changes.
    fn push(&self, request: ProviderPushRequest) -> ProviderResult<ProviderPushResult>;

    /// Conflict-map operation for deterministic resolution planning.
    fn conflict_map(
        &self,
        request: ProviderConflictMapRequest,
    ) -> ProviderResult<ProviderConflictMapResult>;
}
