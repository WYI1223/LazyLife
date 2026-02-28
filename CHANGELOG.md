# Changelog

All notable changes to this project will be documented in this file.

This project follows:

- Keep a Changelog style
- Semantic Versioning (`SemVer`)

## [Unreleased]

### Added

- TBD

### Changed

- TBD

### Fixed

- TBD

### Docs

- TBD

## [0.2.5] - 2026-02-27

Technical-debt paydown and semantic alignment bridge between v0.2 MVP and v0.3
feature expansion.

### Changed

- **Dart god-object decomposition** (PR-0252): NotesController split into
  NotesCoordinator + 6 focused managers (NoteListManager, NoteTabStateManager,
  NoteDraftManager, NoteSaveTracker, NoteTagManager, WorkspaceTreeManager).
  22 tasks, strict behavior parity, 333 pass / 0 fail.
- **Pane-aware tab manager** (PR-0257): NoteTabStateManager upgraded from flat
  list to per-pane `Map<String, List<String>>` for multi-pane tab isolation.
- **Notes-workspace decoupling** (PR-0258): Eliminated dual-state system.
  NotesCoordinator is now sole source of tab/draft/save state.
  WorkspaceProvider reduced to pane-layout-only (664 → 166 lines).
- **Rule E violation reduction** (PR-0259): Broke notes↔tags import cycle via
  `lib/shared/ui_tokens.dart`. Migrated reminders from `features/` to `core/`.
  0 non-allowlisted violations remaining.

### Added

- **CI architecture guardrails** (PR-0259): `architecture_check.dart` enforces
  Rule E cross-feature import ban, file size limits, and structural layer rules
  in CI pipeline.

### Docs

- **Semantic rulings** (PR-0256): S1-S8 rulings documented and synchronized
  across architecture docs. 08a-08d reassessment series completed.
- **Architecture baseline artifacts** (PR-0254A/B/C): Code-generated dependency
  graphs and size baselines with reproducible index.
- **Frontend TL review reports** (PR-0255A/B/C): Code health, module split
  blueprint, and phased refactor plan.

## [0.1.0] - TBD

### Added

- Initial public project scaffold and governance baseline.

### Changed

- N/A

### Fixed

- N/A
