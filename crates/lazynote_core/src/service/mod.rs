//! Core use-case services.
//!
//! # Responsibility
//! - Orchestrate repository calls into use-case level APIs.
//! - Keep UI/FFI layers decoupled from storage details.
//!
//! # See also
//! - docs/releases/v0.1/prs/PR-0006-core-crud.md

pub mod atom_service;
pub mod creation_service;
pub mod guarded_atom_service;
pub mod guarded_creation_service;
pub mod guarded_query_service;
pub mod guarded_task_service;
pub mod guarded_tree_service;
pub mod guarded_workspace_service;
pub mod note_service;
pub mod task_service;
pub mod tree_service;
