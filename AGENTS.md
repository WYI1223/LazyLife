# AGENTS.md

> Operational guide for AI agents working on the **LazyNote** repository.
> Complements `CLAUDE.md` (architecture reference). This file focuses on **workflows, decision trees, and common task patterns**.

---

## Quick Orientation

| Question | Answer |
|----------|--------|
| What is this? | Local-first productivity app: Notes + Tasks + Calendar unified by a single `Atom` entity |
| Tech stack? | Flutter UI → Flutter-Rust Bridge (FRB 2.11.1) FFI → Rust Core → SQLite |
| Where is business logic? | `crates/lazynote_core/` — **only here**, never in Flutter or FFI |
| Where is UI? | `apps/lazynote_flutter/` — UI only, all data through FFI |
| Where is FFI? | `crates/lazynote_ffi/src/api.rs` — thin wrappers, no logic |
| Primary reference? | `CLAUDE.md` for architecture details, this file for workflows |

---

## Before You Start Any Task

1. **Read `CLAUDE.md`** — it has the architecture rules, data model, FFI surface, and pitfalls.
2. **Identify which layer** your change touches:
   - Domain logic / data model / persistence → `crates/lazynote_core/`
   - FFI surface change → `crates/lazynote_ffi/src/api.rs` + regenerate bindings
   - UI / interaction / display → `apps/lazynote_flutter/lib/features/`
   - Cross-cutting (e.g., new entity) → Core first, then FFI, then Flutter
3. **Never modify auto-generated files:**
   - `crates/lazynote_ffi/src/frb_generated.rs`
   - `apps/lazynote_flutter/lib/core/bindings/*.dart`

---

## Decision Trees

### "Where does this code belong?"

```
Is it a validation rule, data constraint, or persistence logic?
  → crates/lazynote_core/ (Rule A)

Is it an FFI function signature or response envelope?
  → crates/lazynote_ffi/src/api.rs (Rule B)

Is it UI rendering, user interaction, or display state?
  → apps/lazynote_flutter/lib/features/<feature>/

Is it command parsing (e.g., "> new note")?
  → apps/lazynote_flutter/lib/features/entry/command_parser.dart
  (Intentionally in Flutter for UX iteration speed)

Is it shared UI primitive (used by multiple features)?
  → apps/lazynote_flutter/lib/shared/ (Rule E)

Is it a settings/config concern?
  → apps/lazynote_flutter/lib/core/settings/
```

### "How do I add a new feature?"

```
1. Model & validation       → crates/lazynote_core/src/model/
2. Repository trait + impl  → crates/lazynote_core/src/repo/
3. Service orchestration    → crates/lazynote_core/src/service/
4. DB migration (if needed) → crates/lazynote_core/src/db/migrations/000N_*.sql
5. FFI wrapper              → crates/lazynote_ffi/src/api.rs
6. Regenerate bindings      → scripts/gen_bindings.ps1
7. Flutter UI               → apps/lazynote_flutter/lib/features/<name>/
8. Tests                    → Core: crates/lazynote_core/tests/; Flutter: test/
9. Docs                     → docs/api/ffi-contracts.md + docs/architecture/data-model.md
```

### "How do I add a new FFI function?"

```
1. Add function in crates/lazynote_ffi/src/api.rs
   - Use #[flutter_rust_bridge::frb(sync)] for non-DB calls
   - Use #[flutter_rust_bridge::frb] (async) for DB-backed calls
2. Define response envelope struct if new pattern needed
3. Run: scripts/gen_bindings.ps1
4. Add /// doc comment to the function
5. Implement core logic in lazynote_core (never in lazynote_ffi)
6. Update docs/api/ffi-contracts.md
7. Write tests
```

### "How do I add a database migration?"

```
1. Create: crates/lazynote_core/src/db/migrations/000N_description.sql
   - Next number is 10 (9 exist)
2. Register in: crates/lazynote_core/src/db/migrations/mod.rs
   - Add to MIGRATIONS array
3. NEVER modify existing migration files
4. Update: docs/architecture/data-model.md
```

---

## Common Task Patterns

### Adding a New Rust Service Method

```rust
// 1. In crates/lazynote_core/src/service/<service>.rs:
pub fn your_method(&self, ...) -> Result<ReturnType, ServiceError> {
    // Call repo methods, apply business rules
}

// 2. In crates/lazynote_ffi/src/api.rs:
#[flutter_rust_bridge::frb]
pub async fn your_ffi_function(...) -> YourResponse {
    your_ffi_function_impl(...)
}

fn your_ffi_function_impl(...) -> YourResponse {
    // Open DB, create repo, create service, call method
    // Return typed envelope
}

// 3. Run: scripts/gen_bindings.ps1
```

### Adding a New Flutter Feature

```
1. Create directory: lib/features/<name>/
2. Create controller: <name>_controller.dart (extends ChangeNotifier)
   - Accept injectable FFI invokers for testability
   - Use request ID deduplication pattern
3. Create page: <name>_page.dart
4. Register route in lib/app/routes.dart (maps to EntryShellPage)
5. Add WorkbenchSection enum variant in entry_shell_page.dart
6. DO NOT import other feature internals (Rule E)
```

### Modifying Atom Model

```
1. Update struct in crates/lazynote_core/src/model/atom.rs
2. Update validation in Atom::validate()
3. Add migration for schema changes
4. Update repo layer SQL queries
5. Update FFI DTOs and mapping functions
6. Regenerate bindings
7. Update Flutter-side models
```

---

## Architecture Constraints (Quick Reference)

| Rule | Constraint | Violation Example |
|------|-----------|-------------------|
| **A** | Business logic in Rust Core only | Adding validation in Flutter |
| **B** | FFI exposes use-cases, not SQL | Exposing `insert_row()` in FFI |
| **C** | Stable UUIDs + soft-delete only | `DELETE FROM atoms` in feature code |
| **D** | Sync mappings in Core | Storing Google Calendar IDs in Flutter |
| **E** | No cross-feature imports | `notes/` importing `tasks/` internals |
| **F** | Unified app root path | Writing files outside `%APPDATA%/LazyLife/` |

Changing any Rule A-F requires a Ruling in `docs/architecture/rulings/`.

---

## Code Quality Checklist

Before submitting changes, verify:

### Rust
```bash
cd crates/
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all
```

### Flutter
```bash
cd apps/lazynote_flutter/
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

### If FFI changed
```powershell
# From repo root
./scripts/gen_bindings.ps1
```

---

## File Patterns & Conventions

### Naming
| Layer | Pattern | Example |
|-------|---------|---------|
| Rust model | `snake_case.rs` | `atom.rs`, `tree_repo.rs` |
| Rust service | `<entity>_service.rs` | `note_service.rs` |
| Flutter controller | `<feature>_controller.dart` | `tasks_controller.dart` |
| Flutter page | `<feature>_page.dart` | `notes_page.dart` |
| Flutter manager | `<concern>_manager.dart` | `note_tab_manager.dart` |
| Migration | `000N_description.sql` | `0009_workspace_note_ref_backfill.sql` |

### Commit Messages
```
feat(scope): Add new capability
fix(scope): Fix specific bug
chore(scope): Maintenance task
docs(scope): Documentation update
test(scope): Test addition/fix
refactor(scope): Code restructure
```

Common scopes: `core`, `ffi`, `notes`, `tasks`, `calendar`, `workspace`, `entry`, `settings`, `ci`

### Comments & TODOs
- All public Rust functions must have `///` doc comments
- TODOs must be traceable: `TODO(#123)`, `TODO(v0.3)`, `FIXME(perf)`
- See `docs/architecture/code-comment-standards.md` for full conventions

---

## Testing Patterns

### Rust Tests
- Unit tests in `#[cfg(test)] mod tests` within each module
- Integration tests in `crates/lazynote_core/tests/`
- Use `open_db_in_memory()` for test databases
- Test both success and error paths

### Flutter Tests
- Controllers accept injectable FFI invokers (function typedefs)
- Never call real FFI in widget tests
- Mock invokers return predefined responses
- Test files mirror source structure under `test/`

---

## Key Patterns to Preserve

### FFI Response Envelopes
All FFI responses follow the pattern:
```rust
pub struct XxxResponse {
    pub ok: bool,
    pub error_code: Option<String>,  // Machine-readable
    pub message: String,             // Human-readable
    pub data: Option<DataType>,      // Payload on success
}
```

### Request Deduplication
Controllers use monotonic `_requestId` to prevent stale responses from overwriting newer data:
```dart
final myRequestId = ++_requestId;
final result = await invoker(...);
if (myRequestId != _requestId) return; // Stale, discard
```

### Three-Stage Bootstrap
```
1. Critical path (sync): Settings → Locale → UI rendering
2. Background: Rust logging init
3. Background: Reminder scheduling
```
App launch is never blocked by non-critical bootstrap.

### Autosave Debounce
Note editing uses debounced autosave (1500ms) with pending-save tracking. Tab close triggers immediate flush.

---

## Common Pitfalls

1. **Forgetting to regenerate bindings** after editing `api.rs` → Dart build will fail
2. **Adding business logic to FFI layer** → Violates Rule B; move to Core service/repo
3. **Cross-feature imports in Flutter** → Violates Rule E; use `shared/` or Core API
4. **Modifying existing migrations** → Will break existing databases; add new migration
5. **Hard-deleting atoms** → Violates Rule C; use `is_deleted = 1`
6. **Using old column names** → `event_start`/`event_end` renamed to `start_at`/`end_at` in migration 6
7. **Classifying by `kind`/`type`** → Section membership is determined by `start_at`/`end_at` nullability
8. **Assuming extension/sync are functional** → They are declaration-only contracts (no runtime loading)
9. **Editing auto-generated files** → `frb_generated.rs` and `lib/core/bindings/` are overwritten by codegen
10. **Skipping `flutter pub get`** → Required after pubspec.yaml or binding changes

---

## Project Status Summary

**Current phase:** Post-v0.2.5 baseline (Windows-first MVP).

**Implemented:** Notes + Tags + FTS search + Single Entry + Tasks (Inbox/Today/Upcoming) + Calendar (weekly) + Workspace tree + Reminders + Localization (en/zh) + Diagnostics + Extension/Sync contracts (declaration-only).

**Not yet implemented:** Extension runtime loading, sync execution, Google Calendar integration, import/export, mobile platforms, CRDT multi-device sync.

---

## Documentation Map

| Need | Document |
|------|----------|
| Architecture rules & data model | `CLAUDE.md` |
| Full architecture specs | `docs/architecture/` |
| FFI API surface | `docs/api/ffi-contracts.md` |
| Error codes | `docs/api/error-codes.md` |
| API compatibility policy | `docs/governance/API_COMPATIBILITY.md` |
| Product roadmap | `docs/product/roadmap.md` |
| Windows dev setup | `docs/development/windows-quickstart.md` |
| Contribution guidelines | `CONTRIBUTING.md` |
| Version policy | `VERSIONING.md` |
