# Architecture Overview

## Purpose

This document defines the current LazyNote architecture baseline for v0.2.5.

Focus:

- local-first data ownership
- Rust Core as business and persistence boundary
- Flutter as UI/runtime/interaction boundary
- coordinator-based state management (post-PR-0252)
- declaration-only extension and sync contracts
- staged delivery via `docs/releases/`

## System Boundaries

### Flutter (`apps/lazynote_flutter`)

Responsibilities:

- UI rendering, interaction flow, and state orchestration
- route/shell orchestration via `EntryShellPage` with in-place section switching
- platform-level integration (window/runtime bootstrap, local notifications)
- feature-scoped controllers extending `ChangeNotifier` with `AnimatedBuilder`
- coordinator architecture for cross-cutting concerns (notes/workspace/tabs)
- settings loaded synchronously before first frame
- localization support (English / Chinese)
- diagnostics surface (Rust health panel + live log viewer)

Non-responsibilities:

- direct SQLite writes
- business invariant ownership
- external sync mapping ownership

### Rust Core (`crates/lazynote_core`)

Responsibilities:

- canonical domain model (`Atom` — universal entity for notes, tasks, events)
- validation and invariants (time-matrix, soft-delete, tag normalization)
- SQLite schema + 9 migrations (`PRAGMA user_version`-tracked)
- CRUD repository/service layers (atom, note, task, tree)
- FTS5 full-text search with snippet extraction
- workspace tree with cycle detection, folder delete modes (dissolve/delete-all)
- core logging (rolling files, 7-day retention, structured events)
- extension kernel contracts (declaration-only: manifest, registry, capabilities)
- provider SPI contracts (declaration-only: auth/pull/push/conflict-map)

### FFI Boundary (`crates/lazynote_ffi`)

Responsibilities:

- expose use-case-level APIs to Flutter (see `docs/api/ffi-contracts.md`)
- keep API contracts stable and explicit
- response envelopes with `ok/error_code/message` pattern

Non-responsibilities:

- business logic (thin wrappers only)
- leaking storage internals

## Current Runtime Flow (v0.2.5)

1. Flutter starts app shell with tiered bootstrap:
   a. Critical settings loaded synchronously (`LocalSettingsStore.ensureInitialized()`)
   b. `RustBridge` 3-stage initialization (FRB runtime → DB path → logging)
   c. Background runtime tasks (non-blocking)
2. Rust Core opens DB, applies migrations via `PRAGMA user_version`.
3. `EntryShellPage` renders workbench with section switching (notes, tasks, calendar, settings, diagnostics).
4. UI interacts with core use-cases via FFI (notes CRUD, task sections, calendar range queries, workspace tree operations).
5. Notes feature uses coordinator architecture:
   - `NotesCoordinator` orchestrates tab/draft/save lifecycle
   - Delegates to extracted managers (NoteTabStateManager, NoteDraftManager, NoteSaveTracker, NoteListManager, NoteTagManager, WorkspaceTreeManager)
   - `WorkspaceProvider` manages pane layout state (split/close/activate)
6. Reminders scheduled via `flutter_local_notifications` (in `lib/core/reminders/`, S7 ruling: platform infrastructure).

## Data Plane

- Primary store: SQLite (single file, `lazynote_entry.sqlite3`)
- Full-text index: FTS5 (`atoms_fts`) with sync triggers
- Migration version source: `PRAGMA user_version` (9 migrations, next = 10)
- Soft delete policy: `is_deleted` tombstone (business paths never hard-delete)
- Runtime file root: `%APPDATA%/LazyLife/` (Windows), `<app_support>/LazyLife/` (others)

## Module Map (v0.2.5)

### Rust Core

- `crates/lazynote_core/src/model`: canonical `Atom` model, `AtomType`, `TaskStatus` enums
- `crates/lazynote_core/src/db`: connection bootstrap + 9 migrations
- `crates/lazynote_core/src/repo`: persistence contracts/SQLite impl (atom, note, tree)
- `crates/lazynote_core/src/service`: use-case orchestration (atom, note, task, tree)
- `crates/lazynote_core/src/search`: FTS5 search with snippet extraction
- `crates/lazynote_core/src/logging`: structured rolling logs, Dart event bridge
- `crates/lazynote_core/src/extension`: declaration-only extension kernel (manifest, registry, capabilities)
- `crates/lazynote_core/src/sync`: declaration-only provider SPI (trait, registry, error envelopes)

### Flutter Features

- `lib/features/entry/`: workbench/shell, command parser, command router, section registry
- `lib/features/notes/`: coordinator + 6 managers, editor, explorer tree, tab strip
- `lib/features/tags/`: tag filter widget
- `lib/features/search/`: search results view
- `lib/features/tasks/`: tasks dashboard (Inbox/Today/Upcoming)
- `lib/features/calendar/`: weekly calendar with event create/edit
- `lib/features/workspace/`: WorkspaceProvider (pane layout state)
- `lib/core/reminders/`: local notification scheduling (S7 ruling: platform infrastructure)
- `lib/features/settings/`: extension permissions UI
- `lib/features/diagnostics/`: Rust health panel + live log viewer

### Flutter Core Infrastructure

- `lib/core/rust_bridge.dart`: RustBridge facade (3-stage init)
- `lib/core/bindings/`: auto-generated FRB Dart wrappers (do not edit)
- `lib/core/settings/`: LocalSettingsStore (JSON persistence)
- `lib/core/local_paths.dart`: platform-specific app root resolution
- `lib/core/debug/`: LogReader for rolling log files
- `lib/core/diagnostics/`: DartEventLogger for structured events
- `lib/app/`: app shell, routes, locale controller, UI slots

## Notes Coordinator Architecture (Post-PR-0252)

PR-0252 decomposed the monolithic `NotesController` into a coordinator + manager pattern:

```
NotesCoordinator (orchestrator)
├── NoteTabStateManager  — tab open/close/activate state
├── NoteDraftManager     — draft buffer lifecycle
├── NoteSaveTracker      — save state, debounce, retry
├── NoteListManager      — note list queries + pagination
├── NoteTagManager       — tag operations
└── WorkspaceTreeManager — explorer tree operations
```

WorkspaceProvider remains separate, managing pane layout only (split/close/activate pane).
PR-0258 eliminated the dual-state pattern — NotesCoordinator is now the sole source of tab/draft/save state. WorkspaceProvider was reduced from 664 to 166 lines.

## Extension Kernel (Declaration-Only)

v0.2 defines contracts without runtime execution:

- `ExtensionManifest`: id, version, capabilities, entrypoints, lifecycle
- `ExtensionRegistry`: validation, dedup, capability index, deny-by-default guard
- Capability model: `command`, `parser`, `provider`, `ui_slot`
- Runtime security capabilities: `network`, `file`, `notification`, `calendar`

**S5 ruling (v0.2.5)**: First-party commands (SingleEntry CommandParser/CommandRouter/CommandRegistry) are **not** registered through ExtensionManifest/ExtensionRegistry. They are direct in-process registrations. Extension Kernel is a third-party security contract; first-party does not go through it. See `docs/architecture/rulings/S5-extension-kernel-boundary.md`.

See: `docs/architecture/extension-kernel.md`

## Provider SPI (Declaration-Only)

v0.2 defines sync provider contracts without implementations:

- `ProviderSpi` trait: auth, pull, push, conflict_map
- `ProviderRegistry`: registration, active-provider selection
- Error/status/summary envelopes

**S6 ruling (v0.2.5)**: Three-layer responsibility separation — Provider (external API adapter), Orchestrator (sync coordination), Mapping (external_mappings table access). ProviderSpi implementations must not directly access `external_mappings` table. First concrete implementation is v0.3 scope (PR-0309).

See: `docs/architecture/provider-spi.md`

## Architecture Invariants

1. **Rule A**: Business invariants live in Rust Core. Flutter may contain interaction parsing and display-derived state.
2. **Rule B**: FFI exposes use-cases, not SQL internals. Exception: `debug_*`/`experimental_*` prefixes.
3. **Rule C**: Stable UUIDs; business-path deletion is soft-delete only.
4. **Rule D**: External sync mappings maintained in Core, not UI.
5. **Rule E**: Flutter `features/<name>` must not import each other's internals. Cross-feature UI primitives go to `lib/shared/`; cross-feature domain operations go through Core API. `lib/core/` infrastructure is exempt from this rule (S7 ruling).
6. **Rule F**: Unified app root `LazyLife/` for all runtime files.

See also: `docs/architecture/engineering-standards.md`.

## Delivery Status Snapshot (v0.2.5)

Completed:

- v0.1: PR-0000 through PR-0017 (core MVP)
- v0.2: PR-0203 through PR-0221 (workspace tree, tasks, calendar, split layout, localization, reminders, extension kernel, provider SPI)
- v0.2.5: PR-0252 modular refactor (22 tasks, coordinator architecture)
- v0.2.5: PR-0254A/B/C architecture baseline
- v0.2.5: PR-0255A/B/C frontend review reports
- v0.2.5: 08a-08d reassessment series

- v0.2.5: PR-0256 semantic rulings (S1-S8) and documentation alignment
- v0.2.5: PR-0257 pane-aware NoteTabManager
- v0.2.5: PR-0258 notes↔workspace structural decoupling
- v0.2.5: PR-0259 Rule E reduction and CI guardrails
- v0.2.5: PR-0253 closure and v0.3 handoff

Next: v0.3 (see `docs/releases/v0.3/README.md`)

## Out of Scope (current state)

- production-grade multi-provider sync engine (v0.3+)
- dynamic extension loading/sandbox runtime (v0.3+)
- cloud telemetry pipeline
- cross-platform parity (non-Windows UX maturity)
- CRDT merge runtime

## References

- `docs/releases/v0.2.5/README.md`
- `docs/releases/v0.3/README.md`
- `docs/architecture/data-model.md`
- `docs/architecture/engineering-standards.md`
- `docs/architecture/rulings/README.md` — S1-S8 semantic rulings registry
- `docs/architecture/extension-kernel.md`
- `docs/architecture/provider-spi.md`
- `docs/architecture/logging.md`
- `docs/architecture/settings-config.md`
- `docs/api/ffi-contracts.md`
- `docs/governance/API_COMPATIBILITY.md`
