# Code & Comment Standards

This standard defines readability and comment requirements for LazyNote code.

## 1. Scope

- Rust: `crates/lazynote_core`, `crates/lazynote_ffi`, `crates/lazynote_cli`
- Dart: `apps/lazynote_flutter/lib`
- SQL migrations: `crates/lazynote_core/src/db/migrations/*.sql`

## 2. Principles

- Code should be self-explanatory first; comments explain why, contract, and invariants.
- Domain invariants must be visible in code and tests, not only in comments.
- Public APIs are contracts and must be documented.
- Outdated comments are defects and must be fixed in the same PR.

## 3. Mandatory Rules

### Rule A: Public APIs must have doc comments

- Rust public types/functions (`pub`) must use `///`.
- Dart public widgets/services/methods must use `///`.
- Minimum content:
  - purpose
  - input/output semantics (nullable, units, format)
  - side effects or constraints

### Rule B: Rust modules must have module headers

- Production modules in core/ffi/sync/storage layers must include `//!` module headers.
- Header must include:
  - responsibility
  - key invariants
  - `See also` doc link when relevant
- Exemptions:
  - generated files
  - test-only modules
  - trivial re-export modules

### Rule C: FFI exports must include an `FFI contract`

- Every exported FFI function must document:
  - blocking model (`sync`/`async`)
  - threading expectation (UI-safe or not)
  - error behavior (throws/never throws/result semantics)
  - return stability

### Rule D: SQL migrations must have a header

- Every migration file must start with:
  - `Purpose`
  - `Invariants`
- Recommended:
  - `Backward compatibility`

### Rule E: Domain fields must be semantically documented

- Key fields must explain semantics, e.g.:
  - stable IDs (`uuid` / `atom_id`)
  - soft delete markers (`is_deleted`)
  - time unit (`ms`/`s`)
  - evolution-reserved fields (`hlc_timestamp`)

### Rule F: Inline comments only for non-obvious logic

- Allowed:
  - compatibility branches
  - non-obvious performance tradeoffs
  - security-sensitive handling
  - easy-to-misuse edge cases
- Forbidden:
  - restating obvious code behavior

### Rule G: TODO/FIXME must be traceable

- Accepted formats:
  - `TODO(#123): ...`
  - `TODO(v0.2): ...`
  - `TODO(perf): ...`
  - `FIXME(#123): ...`
- Bare TODO/FIXME without tag is not allowed.

### Rule H: Security/privacy notes stay centralized

- Security/privacy policy details must live in `docs/compliance/*`.
- Code comments should use short references, e.g. `See also: docs/compliance/privacy.md`.

### Rule I: Comment language

- Code comments and doc comments should be in English.
- Architecture/governance docs may be Chinese or bilingual.

## 4. Red Lines

- Do not write restatement comments (`i++; // increment i`).
- Do not use comments as a substitute for tests.
- Do not scatter security/privacy requirements across random files.

## 5. Templates

### 5.1 Rust module header

```rust
//! Notes service.
//!
//! # Responsibility
//! - Create/update note atoms.
//! - Keep invariants: note atoms must have `kind=Note`.
//!
//! # See also
//! - docs/architecture/data-model.md
```

### 5.2 Rust public API

```rust
/// Creates a new note atom.
///
/// # Invariants
/// - Title must not be empty.
/// - Returned id is stable and never reused.
///
/// # Errors
/// - Returns validation/storage errors.
pub fn create_note(title: &str) -> Result<AtomId, CreateNoteError> { ... }
```

### 5.3 Rust FFI export

```rust
/// Returns core version string.
///
/// # FFI contract
/// - Sync call, non-blocking.
/// - UI-thread safe.
/// - Never throws; always returns a string.
pub fn core_version() -> String { ... }
```

### 5.4 Dart public API and why-comment

```dart
/// Entry box that routes input to search or commands.
///
/// Contract:
/// - Input starts with `>` => command mode.
/// - Otherwise => full-text search mode.
class EntryBox extends StatefulWidget { ... }

// Why: 120ms debounce balances typing latency and FFI call frequency.
```

### 5.5 SQL migration header

```sql
-- Migration: 0001_init.sql
-- Purpose: create atoms and tags tables.
-- Invariants:
-- - atoms.id is stable UUID.
-- - atoms.is_deleted is soft delete marker.
-- Backward compatibility:
-- - additive changes only in v0.1.
```

## 6. PR Checklist

- New public APIs include doc comments.
- Rust production modules include `//!` headers.
- FFI exports include `FFI contract`.
- New migrations include `Purpose + Invariants`.
- Complex branches include concise why-comments.
- Invariants are covered by tests/assertions.
- Comments match implementation.
