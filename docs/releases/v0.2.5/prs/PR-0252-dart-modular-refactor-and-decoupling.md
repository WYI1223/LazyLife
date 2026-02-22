# PR-0252-dart-modular-refactor-and-decoupling

- Proposed title: `refactor(notes/workspace): decompose god-objects with behavior parity`
- Status: Planned

## Goal

Refactor large Dart "god-object" modules into smaller units with explicit
boundaries, while preserving existing runtime behavior and contracts.

Prerequisite:

- `PR-0254C` baseline artifact index is completed.
- `PR-0255C` phased refactor plan is completed and approved.

## Scope

In scope:

- split high-complexity files into focused modules
- reduce direct cross-layer coupling in Notes/Workspace flows
- add/adjust tests to protect behavior parity
- keep FFI/API contract surface unchanged

Out of scope:

- new product behavior or interaction expansion
- storage schema migration
- contract wording changes (handled by `PR-0251`)

## Refactor Targets (Initial)

1. `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
2. `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
3. `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
4. `apps/lazynote_flutter/lib/core/rust_bridge.dart` (seam cleanup only)

## Decomposition Principles

1. One owner per module responsibility (state, projection, command, wiring).
2. Directional dependencies only (`view -> controller -> service`).
3. No semantic change hidden behind refactor commits.
4. New seams must be testable in isolation.

## Implementation Plan

1. Define module boundaries and extraction map.
2. Extract code in small slices with compile/test green after each slice.
3. Add parity-focused tests around extracted seams.
4. Remove dead/duplicated paths introduced by prior growth.
5. Keep docs synchronized when module paths change.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/controller/*`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer/*`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/page/*`
- [edit] `apps/lazynote_flutter/lib/core/rust_bridge.dart`
- [edit] `apps/lazynote_flutter/test/*` (parity and seam tests)

## Verification

- `cd apps/lazynote_flutter && dart format --output=none --set-exit-if-changed .`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`

## Acceptance Criteria

- [ ] Target god-objects are decomposed with clear ownership boundaries.
- [ ] No user-visible behavior change is introduced by refactor.
- [ ] Existing contracts (`docs/api/*`) remain valid without drift.
- [ ] Refactor ordering follows `PR-0255B/PR-0255C` priorities.
- [ ] CI checks remain green with no format/lint regressions.
