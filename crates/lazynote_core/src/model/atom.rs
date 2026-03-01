//! Atom domain model.
//!
//! # Responsibility
//! - Define the canonical record shared by note/task/event projections.
//! - Provide lifecycle helpers for soft-delete semantics.
//!
//! # Invariants
//! - `uuid` is stable and never reused for another atom.
//! - `is_deleted` is the source of truth for tombstone state.
//! - `end_at` should not be earlier than `start_at` when both are set.
//!
//! # See also
//! - docs/architecture/data-model.md

use serde::{Deserialize, Serialize};
use std::error::Error;
use std::fmt::{Display, Formatter};
use uuid::Uuid;

/// Stable identifier for every domain object projected from an Atom.
///
/// Kept as a type alias to make semantic intent explicit in signatures.
pub type AtomId = Uuid;

/// Rendering hint for Atom projections.
///
/// Determines which UI shape (note editor, task checkbox, calendar block)
/// a view should use. Does **not** define the Atom's identity or lifecycle.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ViewHint {
    /// Free-form markdown note.
    Note,
    /// Actionable task with status metadata.
    Task,
    /// Calendar event with optional start/end time.
    Event,
}

/// Task lifecycle state (meaningful when `view_hint == ViewHint::Task`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TaskStatus {
    /// Created but not started.
    Todo,
    /// Work is in progress.
    InProgress,
    /// Completed successfully.
    Done,
    /// No longer actionable.
    Cancelled,
}

/// Canonical domain record for note/task/event data.
///
/// This model intentionally keeps task/event-specific fields optional, so
/// one storage shape can support multiple projections without data copying.
///
/// # Known Risk (v0.1)
/// - Fields are public for iteration speed, so direct mutation can bypass
///   constructor and deserialization validation.
/// - Callers must validate before persistence/FFI boundaries.
/// - TODO(v0.2): make mutation paths private/typed to enforce invariants
///   structurally.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(try_from = "AtomDe")]
pub struct Atom {
    /// Stable global ID used for linking, sync mapping and auditing.
    pub uuid: AtomId,
    /// Rendering hint that selects the UI shape (note / task / event).
    pub view_hint: ViewHint,
    /// User-facing title derived from content (first non-empty line for markdown).
    pub title: String,
    /// Content format indicator. Currently always `"markdown"`.
    pub content_type: String,
    /// Markdown body (or plain text fallback for simple inputs).
    pub content: String,
    /// Derived plain-text summary from markdown content.
    ///
    /// This field is a projection cache and not the source of truth. The
    /// source remains `content`.
    pub preview_text: Option<String>,
    /// Derived first markdown image path used by list preview UIs.
    ///
    /// This field is a projection cache and not the source of truth.
    pub preview_image: Option<String>,
    /// Meaningful only when `view_hint == ViewHint::Task`.
    pub task_status: Option<TaskStatus>,
    /// Unix epoch milliseconds. Drives section classification (Inbox/Today/Upcoming).
    pub start_at: Option<i64>,
    /// Unix epoch milliseconds. Should be >= `start_at` when set.
    pub end_at: Option<i64>,
    /// Reserved: RFC 5545 RRULE string for recurring atoms (v0.2+).
    pub recurrence_rule: Option<String>,
    /// Reserved for future CRDT/HLC merge strategy.
    pub hlc_timestamp: Option<String>,
    /// Soft delete tombstone to preserve sync/recovery history.
    pub is_deleted: bool,
}

/// Validation errors for atom construction/deserialization/update boundaries.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AtomValidationError {
    /// Stable ID must not be the all-zero UUID.
    NilUuid,
    /// Event window is reversed (`end < start`).
    InvalidEventWindow { start: i64, end: i64 },
}

impl Display for AtomValidationError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NilUuid => write!(f, "uuid must not be nil"),
            Self::InvalidEventWindow { start, end } => {
                write!(f, "end_at ({end}) must be >= start_at ({start})")
            }
        }
    }
}

impl Error for AtomValidationError {}

#[derive(Debug, Deserialize)]
struct AtomDe {
    uuid: AtomId,
    view_hint: ViewHint,
    #[serde(default)]
    title: String,
    #[serde(default = "default_content_type")]
    content_type: String,
    content: String,
    preview_text: Option<String>,
    preview_image: Option<String>,
    task_status: Option<TaskStatus>,
    start_at: Option<i64>,
    end_at: Option<i64>,
    recurrence_rule: Option<String>,
    hlc_timestamp: Option<String>,
    is_deleted: bool,
}

fn default_content_type() -> String {
    "markdown".to_string()
}

impl TryFrom<AtomDe> for Atom {
    type Error = AtomValidationError;

    fn try_from(value: AtomDe) -> Result<Self, Self::Error> {
        let atom = Self {
            uuid: value.uuid,
            view_hint: value.view_hint,
            title: value.title,
            content_type: value.content_type,
            content: value.content,
            preview_text: value.preview_text,
            preview_image: value.preview_image,
            task_status: value.task_status,
            start_at: value.start_at,
            end_at: value.end_at,
            recurrence_rule: value.recurrence_rule,
            hlc_timestamp: value.hlc_timestamp,
            is_deleted: value.is_deleted,
        };
        atom.validate()?;
        Ok(atom)
    }
}

impl Atom {
    /// Creates a new atom with a generated stable ID.
    ///
    /// # Invariants
    /// - Optional projection fields are initialized to `None`.
    /// - `is_deleted` starts as `false`.
    pub fn new(view_hint: ViewHint, content: impl Into<String>) -> Self {
        Self {
            uuid: Uuid::new_v4(),
            view_hint,
            title: String::new(),
            content_type: "markdown".to_string(),
            content: content.into(),
            preview_text: None,
            preview_image: None,
            task_status: None,
            start_at: None,
            end_at: None,
            recurrence_rule: None,
            hlc_timestamp: None,
            is_deleted: false,
        }
    }

    /// Creates a new atom with generated stable ID and validates invariants.
    pub fn try_new(
        view_hint: ViewHint,
        content: impl Into<String>,
    ) -> Result<Self, AtomValidationError> {
        let atom = Self::new(view_hint, content);
        atom.validate()?;
        Ok(atom)
    }

    /// Creates a new atom with a caller-provided stable ID.
    ///
    /// Used by import/sync paths where identity already exists externally.
    ///
    /// # Invariants
    /// - The provided `uuid` must remain stable for this atom lifetime.
    /// - `uuid` must not be nil.
    pub fn with_id(
        uuid: AtomId,
        view_hint: ViewHint,
        content: impl Into<String>,
    ) -> Result<Self, AtomValidationError> {
        let atom = Self {
            uuid,
            view_hint,
            title: String::new(),
            content_type: "markdown".to_string(),
            content: content.into(),
            preview_text: None,
            preview_image: None,
            task_status: None,
            start_at: None,
            end_at: None,
            recurrence_rule: None,
            hlc_timestamp: None,
            is_deleted: false,
        };
        atom.validate()?;
        Ok(atom)
    }

    /// Marks this Atom as softly deleted (tombstoned).
    pub fn soft_delete(&mut self) {
        self.is_deleted = true;
    }

    /// Clears soft delete flag.
    pub fn restore(&mut self) {
        self.is_deleted = false;
    }

    /// Returns whether this Atom should be considered visible/active.
    pub fn is_active(&self) -> bool {
        !self.is_deleted
    }

    /// Validates core invariants before persistence/FFI boundary hand-off.
    ///
    /// # Known Risk (v0.1)
    /// - Because fields are currently `pub`, this check can be skipped by
    ///   callers after mutation.
    /// - Persistence/repository/FFI entry points must call `validate()`.
    ///
    /// # Errors
    /// - Returns [`AtomValidationError::NilUuid`] for nil IDs.
    /// - Returns [`AtomValidationError::InvalidEventWindow`] when event time
    ///   range is reversed.
    pub fn validate(&self) -> Result<(), AtomValidationError> {
        if self.uuid.is_nil() {
            return Err(AtomValidationError::NilUuid);
        }

        if let (Some(start), Some(end)) = (self.start_at, self.end_at) {
            if end < start {
                return Err(AtomValidationError::InvalidEventWindow { start, end });
            }
        }

        Ok(())
    }
}
