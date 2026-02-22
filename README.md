# LazyNote

> A minimal, local-first personal productivity system.
> Notes, tasks, and calendar converge into a single entry point.

**[中文文档 →](README_ZH.md)**

Documentation entrypoint: **[docs/index.md](docs/index.md)**

---

## What is LazyNote?

LazyNote is a personal productivity app built around three core values:

- **Single Entry** — One search bar and command panel. All key actions are directly reachable.
- **Strong Linkage** — Notes, tasks, and events are different views of the same data graph.
- **Low Friction** — Simple by default, powerful by choice. No feature bloat, no cognitive overhead.

This is not "the most feature-rich" productivity tool. It is the one with the least friction.

---

## Design Principles

| Principle | Description |
|-----------|-------------|
| **Local-First** | Data lives on-device by default. Offline is always available. Sync is optional. |
| **Privacy-First** | Minimum permissions, zero telemetry by default, no forced account. |
| **One Input** | A unified entry point is preferred over multi-page navigation. |
| **Default Simple** | Complex features (e.g., graph view, semantic search) are opt-in, not default. |
| **Cross-Platform by Design** | Architecture targets Windows / macOS / iOS / Android from the start. |

---

## Architecture

```
┌───────────────────────────────────────────────┐
│              Flutter UI Layer                  │
│  Single Entry · Notes · Tasks · Calendar      │
│  Workspace Tree · Diagnostics · Settings      │
└──────────────────────┬────────────────────────┘
                       │  Flutter-Rust Bridge (FRB / FFI)
┌──────────────────────▼────────────────────────┐
│              Rust Core Layer                   │
│  Domain Model · Services · Repositories       │
│  FTS5 Search · Migrations · Logging           │
│  Extension Kernel · Sync SPI (contracts)      │
└──────────────────────┬────────────────────────┘
                       │
┌──────────────────────▼────────────────────────┐
│             Local Data Plane                   │
│  SQLite (atoms, tags, workspace tree,          │
│          external mappings)                    │
│  FTS5 (full-text search virtual table)         │
└───────────────────────────────────────────────┘
```

The Rust core is the single source of truth for all business logic. Flutter is UI-only — it communicates with the core exclusively through the FFI boundary. The FFI layer (`lazynote_ffi`) exposes use-case APIs and never raw database operations.

---

## Package Structure

```
apps/
  lazynote_flutter/                  # Flutter client (Windows-first, multi-platform target)
    lib/
      app/                           # Routes, shell orchestration, locale controller, UI slots
      core/                          # RustBridge, FFI bindings (generated), settings, paths
      features/
        entry/                       # Single-entry search + command panel
        notes/                       # Note list, editor, explorer tree, tab manager
        tags/                        # Tag filter widget
        search/                      # Search results view
        tasks/                       # Tasks dashboard: Inbox / Today / Upcoming
        calendar/                    # Weekly calendar: sidebar, week grid, event blocks
        workspace/                   # Workspace tree provider + models
        reminders/                   # Local notification scheduling
        settings/                    # Extension capability settings
        diagnostics/                 # Rust health panel + live log viewer
      l10n/                          # Localization (English + Chinese)

crates/
  lazynote_core/                     # All business logic (Rust)
    src/
      model/atom.rs                  # Canonical Atom entity, AtomType, TaskStatus
      db/                            # SQLite bootstrap + 9 versioned migrations
      repo/                          # Persistence traits + SQLite implementations
        atom_repo.rs                 # Atom CRUD, section queries, status update
        note_repo.rs                 # Note CRUD, tag normalization
        tree_repo.rs                 # Workspace tree CRUD
      service/                       # Use-case orchestration
        atom_service.rs              # Atom creation façade
        note_service.rs              # Note lifecycle + markdown preview
        task_service.rs              # Section queries + status management
        tree_service.rs              # Workspace tree with cycle detection
      search/fts.rs                  # FTS5 full-text search
      logging.rs                     # Structured rolling-file logger
      extension/                     # Extension kernel contracts (declaration-only)
      sync/                          # Sync provider SPI contracts (declaration-only)

  lazynote_ffi/                      # FFI boundary (thin wrappers, no logic)
    src/api.rs                       # Exported FFI functions — edit here
    src/frb_generated.rs             # AUTO-GENERATED — do not edit

  lazynote_cli/                      # CLI linkage probe (minimal)

docs/                                # Architecture, API contracts, release plans
scripts/                             # doctor.ps1, gen_bindings.ps1, format.ps1
tools/                               # CI helpers, architecture analysis, Docker
server/relay/                        # Planned sync relay (stub)
```

---

## Data Model

LazyNote unifies notes, tasks, and events into a single canonical entity: **Atom**.

The same record can be projected as a note, task, or event. `kind` drives UI rendering shape only; list section membership (Inbox/Today/Upcoming) is determined by `start_at`/`end_at` nullability — not by `kind`. There is no data duplication across entity types.

| Field | Type | Description |
|-------|------|-------------|
| `uuid` | UUIDv4 | Stable global identifier, never reused |
| `kind` | `note \| task \| event` | Rendering hint only — does not drive section classification |
| `content` | String | Markdown body |
| `preview_text` | String? | Derived from content (first plain text, max 100 chars) |
| `preview_image` | String? | First markdown image path |
| `task_status` | Enum? | `todo \| in_progress \| done \| cancelled`; NULL = no status |
| `start_at` | i64? | Epoch ms — time-matrix anchor |
| `end_at` | i64? | Epoch ms; always >= `start_at` |
| `recurrence_rule` | String? | Reserved RFC 5545 RRULE string — NULL until implemented |
| `is_deleted` | bool | Soft-delete tombstone — authoritative for visibility |
| `hlc_timestamp` | String? | Reserved for CRDT sync (not yet active) |

**Time-Matrix Section Classification:**

| start_at | end_at | Section |
|----------|--------|---------|
| NULL | NULL | Inbox |
| NULL | set | Today (if overdue/today) or Upcoming |
| set | NULL | Today (if started) or Upcoming |
| set | set | Today (if overlaps today) or Upcoming |

Atoms with `task_status` of `done` or `cancelled` are hidden from active sections.

**Workspace Tree:**

Notes are organized in a hierarchical tree of folders and note references. Each `WorkspaceNode` has a `kind` (Folder or NoteRef), optional parent, and a sort order. Tree operations include create, rename, move (with cycle detection), and delete (dissolve children to parent, or recursive delete).

**Invariants enforced in code:**
- `uuid` is never nil
- `end_at >= start_at` when both are set
- All default queries filter `WHERE is_deleted = 0`
- Deletion is soft-delete only — `DELETE` statements on `atoms` are prohibited in feature code
- Tags are always lowercased and deduplicated

---

## Current Implementation Status

| Feature | Status |
|---------|--------|
| Atom data model + SQLite schema (9 migrations) | Implemented |
| FTS5 full-text search | Implemented |
| Note CRUD via FFI | Implemented |
| Tag management (create, assign, filter) | Implemented |
| Single-entry search + command panel | Implemented |
| Note editor (Markdown) with tab manager | Implemented |
| Workspace tree (folders, note refs, drag-and-drop) | Implemented |
| Tasks engine (Inbox/Today/Upcoming, status toggle) | Implemented |
| Calendar (weekly view, create/edit events) | Implemented |
| Reminders (local notifications) | Implemented |
| Localization (English + Chinese) | Implemented |
| UI extension slot system | Implemented |
| Structured logging + diagnostics panel | Implemented |
| Windows build | Implemented |
| Extension kernel (contracts defined) | Declaration-only |
| Sync provider SPI (contracts defined) | Declaration-only |
| Google Calendar sync | Planned |
| Import / export | Planned |
| Mobile (iOS / Android) | Planned |
| CRDT / multi-device sync | Planned |

---

## Development Setup

### Prerequisites

- Rust stable toolchain (see `rust-toolchain.toml`)
- Flutter SDK (Dart >= 3.11)
- Windows SDK (for Windows builds)

### Quick Verification

```powershell
# From repo root
./scripts/doctor.ps1
```

### Build

```bash
# Rust (from crates/)
cargo build --all

# Flutter (from apps/lazynote_flutter/)
flutter pub get
flutter build windows --debug
```

### Test

```bash
# Rust (from crates/)
cargo test --all

# Flutter (from apps/lazynote_flutter/)
flutter test
```

### Code Quality

```bash
# Rust
cargo fmt --all -- --check
cargo clippy --all -- -D warnings

# Flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
```

### Code Generation

After modifying `crates/lazynote_ffi/src/api.rs`, regenerate the FFI bindings:

```powershell
./scripts/gen_bindings.ps1
```

For detailed Windows setup instructions, see [docs/development/windows-quickstart.md](docs/development/windows-quickstart.md).

---

## Runtime File Layout

On Windows, LazyNote stores all runtime files under `%APPDATA%\LazyLife\`:

```
%APPDATA%\LazyLife\
  settings.json               — App settings (log level, DB path, UI language)
  logs/                        — Rolling log files (7-day retention)
  data/
    lazynote_entry.sqlite3     — SQLite database
```

On macOS/iOS: `<app_support>/LazyLife/` with the same structure.

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| UI | Flutter | SDK |
| FFI Bridge | Flutter-Rust Bridge | 2.11.1 |
| Core Logic | Rust | stable |
| Database | SQLite (rusqlite bundled) | 0.32 |
| Full-Text Search | FTS5 | Built into SQLite |
| Logging | flexi_logger | 0.29 |
| Notifications | flutter_local_notifications | 20.1.0 |
| Calendar Widget | table_calendar | 3.1.0 |
| Window Manager | window_manager | 0.5.1 |

---

## Roadmap

| Phase | Focus |
|-------|-------|
| **v0.1** | Notes + tags + full-text search + single-entry panel |
| **v0.1.5** | Atom Time-Matrix — Inbox/Today/Upcoming task views + calendar minimal |
| **v0.2** | Workspace tree, notes explorer, extension kernel contracts, sync SPI contracts |
| **v0.2.5** | Architecture baseline, code health analysis |
| **v0.3** | Advanced layout, drag-to-split, cross-pane sync |
| **v1.0** | Plugin sandbox, iOS distribution, API compat CI gates |

Post-v0.2: Google Calendar sync, import/export, mobile platforms, CRDT multi-device sync.

---

## Key Documentation

| Document | Description |
|----------|-------------|
| [docs/index.md](docs/index.md) | Canonical docs entrypoint and navigation index |
| [docs/architecture/engineering-standards.md](docs/architecture/engineering-standards.md) | 6 mandatory architecture rules |
| [docs/architecture/data-model.md](docs/architecture/data-model.md) | Atom entity spec and schema |
| [docs/architecture/overview.md](docs/architecture/overview.md) | Architecture overview |
| [docs/api/ffi-contracts.md](docs/api/ffi-contracts.md) | FFI API contract |
| [docs/api/error-codes.md](docs/api/error-codes.md) | Stable error code registry |
| [docs/governance/API_COMPATIBILITY.md](docs/governance/API_COMPATIBILITY.md) | API breaking change policy |
| [docs/product/vision.md](docs/product/vision.md) | Product vision and long-term direction |
| [docs/product/roadmap.md](docs/product/roadmap.md) | Product roadmap |
| [docs/development/windows-quickstart.md](docs/development/windows-quickstart.md) | Windows setup guide |
| [CLAUDE.md](CLAUDE.md) | AI agent development guide |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/governance/CONTRIBUTING.md](docs/governance/CONTRIBUTING.md) for contribution guidelines.

Commits follow [Conventional Commits](https://www.conventionalcommits.org/):
`feat(scope):`, `fix(scope):`, `chore(scope):`, `docs(scope):`, `test(scope):`, `refactor(scope):`

One concern per PR. No mixing features with unrelated refactoring.

---

## License

[MIT License](LICENSE)
