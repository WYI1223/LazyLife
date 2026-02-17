//! Provider SPI DTO and error contracts.

use std::time::{SystemTime, UNIX_EPOCH};

/// Sync pipeline stage for machine-branchable errors.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncStage {
    Auth,
    Pull,
    Push,
    ConflictMap,
}

/// Provider readiness state.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProviderHealth {
    Healthy,
    Degraded,
    Unavailable,
}

/// Provider authentication state.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProviderAuthState {
    Unauthenticated,
    Authenticating,
    Authenticated,
    Expired,
}

/// Telemetry-safe provider status snapshot.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderStatus {
    pub provider_id: String,
    pub health: ProviderHealth,
    pub auth_state: ProviderAuthState,
    pub last_sync_at_ms: Option<i64>,
}

impl ProviderStatus {
    /// Returns a baseline disconnected status.
    pub fn unauthenticated(provider_id: impl Into<String>) -> Self {
        Self {
            provider_id: provider_id.into(),
            health: ProviderHealth::Unavailable,
            auth_state: ProviderAuthState::Unauthenticated,
            last_sync_at_ms: None,
        }
    }
}

/// Unified provider error envelope.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderErrorEnvelope {
    pub provider_id: String,
    pub stage: SyncStage,
    pub code: String,
    pub message: String,
    pub retriable: bool,
}

impl ProviderErrorEnvelope {
    /// Constructs one provider error envelope with normalized strings.
    pub fn new(
        provider_id: impl Into<String>,
        stage: SyncStage,
        code: impl Into<String>,
        message: impl Into<String>,
        retriable: bool,
    ) -> Self {
        Self {
            provider_id: provider_id.into().trim().to_string(),
            stage,
            code: code.into().trim().to_string(),
            message: message.into().trim().to_string(),
            retriable,
        }
    }
}

/// Common provider result alias.
pub type ProviderResult<T> = Result<T, ProviderErrorEnvelope>;

/// Authentication request contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderAuthRequest {
    pub interactive: bool,
    pub scopes: Vec<String>,
}

/// Authentication result contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderAuthResult {
    pub state: ProviderAuthState,
    pub granted: bool,
    pub expires_at_ms: Option<i64>,
}

/// Pull request contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderPullRequest {
    pub cursor: Option<String>,
    pub limit: u32,
}

/// Logical entity kinds projected by provider sync.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncEntityKind {
    Task,
    Event,
}

/// Telemetry-safe remote record projection.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderRecord {
    pub external_id: String,
    pub entity_kind: SyncEntityKind,
    pub updated_at_ms: i64,
    pub payload_hash: Option<String>,
}

/// Pull result contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderPullResult {
    pub records: Vec<ProviderRecord>,
    pub next_cursor: Option<String>,
    pub has_more: bool,
}

/// Push operation kind for one local change.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PushOperation {
    Upsert,
    Delete,
}

/// One push request item.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderPushChange {
    pub atom_uuid: String,
    pub entity_kind: SyncEntityKind,
    pub operation: PushOperation,
    pub external_id: Option<String>,
    pub local_version: Option<i64>,
}

/// Push request contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderPushRequest {
    pub changes: Vec<ProviderPushChange>,
}

/// Conflict reason from provider/local compare stage.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConflictReason {
    VersionMismatch,
    DeletedRemotely,
    DeletedLocally,
    Unknown,
}

/// One conflict projection.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderConflict {
    pub atom_uuid: String,
    pub external_id: Option<String>,
    pub reason: ConflictReason,
}

/// Push result contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderPushResult {
    pub accepted_count: usize,
    pub failed_count: usize,
    pub conflict_candidates: Vec<ProviderConflict>,
}

/// Conflict resolution strategy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConflictResolution {
    KeepLocal,
    KeepRemote,
    ManualMerge,
}

/// One conflict resolution decision.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConflictMapDecision {
    pub atom_uuid: String,
    pub resolution: ConflictResolution,
}

/// Conflict-map request contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderConflictMapRequest {
    pub conflicts: Vec<ProviderConflict>,
}

/// Conflict-map response contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderConflictMapResult {
    pub decisions: Vec<ConflictMapDecision>,
}

/// Telemetry-safe sync execution summary.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncSummary {
    pub provider_id: String,
    pub started_at_ms: i64,
    pub finished_at_ms: i64,
    pub pulled_records: usize,
    pub pushed_changes: usize,
    pub conflicts_detected: usize,
    pub conflicts_resolved: usize,
    pub error_code: Option<String>,
}

impl SyncSummary {
    /// Builds one successful sync summary.
    pub fn success(
        provider_id: impl Into<String>,
        started_at_ms: i64,
        finished_at_ms: i64,
        pulled_records: usize,
        pushed_changes: usize,
        conflicts_detected: usize,
        conflicts_resolved: usize,
    ) -> Self {
        Self {
            provider_id: provider_id.into().trim().to_string(),
            started_at_ms,
            finished_at_ms,
            pulled_records,
            pushed_changes,
            conflicts_detected,
            conflicts_resolved,
            error_code: None,
        }
    }

    /// Builds one failed sync summary with stable error code.
    pub fn failure(
        provider_id: impl Into<String>,
        started_at_ms: i64,
        finished_at_ms: i64,
        error_code: impl Into<String>,
    ) -> Self {
        Self {
            provider_id: provider_id.into().trim().to_string(),
            started_at_ms,
            finished_at_ms,
            pulled_records: 0,
            pushed_changes: 0,
            conflicts_detected: 0,
            conflicts_resolved: 0,
            error_code: Some(error_code.into().trim().to_string()),
        }
    }

    /// Returns total sync duration (clamped at zero for clock skew).
    pub fn duration_ms(&self) -> i64 {
        (self.finished_at_ms - self.started_at_ms).max(0)
    }
}

/// Returns current epoch milliseconds.
pub fn now_epoch_ms() -> i64 {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    now.as_millis() as i64
}
