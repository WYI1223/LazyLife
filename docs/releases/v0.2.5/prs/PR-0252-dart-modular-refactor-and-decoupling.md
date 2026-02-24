# PR-0252-dart-modular-refactor-and-decoupling

- Proposed title: `refactor(frontend): execute phased modular refactor with behavior parity`
- Status: In Progress (execution baseline: `PR-0255C` signed-off)

## Goal

Execute the v0.2.5 frontend refactor by following the signed phased plan,
decomposing god-objects and reducing coupling without changing user-visible behavior.

Prerequisite:

- `PR-0254C` baseline artifact index is completed.
- `PR-0255A` code-health report is completed and signed.
- `PR-0255B` module-split blueprint is completed and signed.
- `PR-0255C` phased refactor plan is completed and signed.

## Execution Contract (Canonical Inputs)

- Risk baseline: `docs/reports/v0.2.5/frontend-review/01-code-health-report.md`
- Boundary contract: `docs/reports/v0.2.5/frontend-review/02-module-split-blueprint.md`
- Phase/task contract: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md`

This PR must not redefine boundaries or ordering from `PR-0255C`.

## Scope

In scope:

- execute task IDs `P0-1` to `P3-5` defined in `03-phased-refactor-plan.md` Section 4.2
- implement modular extraction in notes/entry per `0255B` D1-D8 rules
- migrate affected tests with behavior-parity baseline preserved
- keep Rust/FFI signatures unchanged

Out of scope:

- new product behavior or interaction expansion
- storage/schema migration
- state-management framework migration
- Rust API signature changes in `crates/lazynote_ffi/src/api.rs` (unless approved as separate task)
- P2 module split items explicitly excluded by `PR-0255C` Section 2.2

## Phase-to-PR Arrangement

| Phase | Window | Task IDs | Primary Outputs | Merge Notes |
|------|--------|----------|-----------------|------------|
| Phase 0 | Week 1 first half | `P0-1..P0-5` | `workspace_port.dart`, regression checklist v1, gate rules, NoteSaveTracker sample PR | establish gate before bulk extraction |
| Phase 1 | Week 1 second half ~ Week 2 | `P1-1..P1-8` | WorkspaceTree/Draft/Tag managers + 4 dialogs + ExplorerTreeBuilder | manager lane and dialog lane may run in parallel |
| Phase 2 | Week 3 | `P2-1..P2-4` | NoteTabManager, NoteListManager, NotesCoordinator, test migration | `P2-3` is the only breaking point; `P2-3` and `P2-4` must be merged together |
| Phase 3 | Week 4 first half | `P3-1..P3-5` | SectionRegistry, zero cross-feature import verification, boundary update, retrospective, TL sign-off | closure and handoff to release lane |

### Critical Path (must keep order)

1. `P0-3 -> P0-4 -> P1-2 -> P2-1 -> P2-2 -> P2-3 -> P2-4 -> P3-1`
2. `P0-1 -> P1-1` (Phase 1 DoD blocker)
3. `P1-3 -> P2-2` (filter dependency)

### Parallel Lanes (allowed)

- `P1-4..P1-8` (Explorer dialog/builder lane) can run parallel with manager lane.
- `P3-3 + P3-4` can run parallel after `P2-3`.

## Branching and PR Opening Conventions

### Branch policy

- Do not run one long-lived refactor code branch.
- Create one short-lived branch per task ID from latest `main`.
- Recommended branch name format:
  - `feat/pr-0252-<task-id>-<short-topic>`
  - examples:
    - `feat/pr-0252-p0-1-workspace-port`
    - `feat/pr-0252-p1-1-workspace-tree-manager`

### PR title policy

- Format:
  - `refactor(frontend): PR-0252 <task-id> <summary>`
- examples:
  - `refactor(frontend): PR-0252 P0-1 add workspace port abstraction`
  - `refactor(frontend): PR-0252 P1-3 extract note tag manager`

### Mandatory reviewer policy

- `P0-5`, `P2-3`, `P3-5`: TL review is mandatory.
- other extraction PRs: at least one reviewer; TL review is recommended.

## Trunk-Based Execution Workflow (Mandatory)

This PR follows trunk-based development. Every task PR (`P0-1` .. `P3-5`) must follow the same workflow.

### Non-negotiable rules

- one task ID per branch and per PR; do not mix multiple task IDs in one PR
- branch from latest `main` only; do not branch from another feature/task branch
- merge back to `main` quickly after review; do not keep long-lived refactor branches
- dependency order is controlled by this file and `PR-0255C`; out-of-order merge is not allowed
- `P2-3` and `P2-4` are coupled and must be merged/reverted together

### Standard steps for each sub-PR

1. sync trunk
   - `git switch main`
   - `git pull --ff-only`
2. create task branch from trunk
   - `git switch -c feat/pr-0252-<task-id>-<short-topic>`
3. implement only the scope defined in `docs/releases/v0.2.5/prs/PR-0252/<task-spec>.md`
4. run mandatory checks locally
   - `cd apps/lazynote_flutter && dart format --output=none --set-exit-if-changed .`
   - `cd apps/lazynote_flutter && flutter analyze`
   - `cd apps/lazynote_flutter && flutter test`
   - `cd apps/lazynote_flutter && flutter build windows --debug`
   - run D-rule checks in "Structural Gate Checks (D1-D8)" when applicable
5. re-sync before opening or merging PR
   - `git fetch origin`
   - `git rebase origin/main`
6. open PR using the planned branch/title in this file, and include
   - task ID, phase, dependency, risk, rollback note, verification command outputs
7. merge only after
   - CI green
   - required reviewer approved (`P0-5`, `P2-3`, `P3-5` require TL)
8. after merge, update tracking docs before starting next task
   - `PR-0252` checklist (`Task Checklist`)
   - `03-phased-refactor-plan.md` task status (Section 4.2)

### Dependency handling in trunk mode

- if a task has unmet prerequisite, keep it draft or do not open; never merge early
- parallel lanes are allowed only where explicitly listed in this PR (`P1-4..P1-8`, `P3-3 + P3-4`)
- if emergency fixes land on `main`, rebase active task branches before further commits

## Initial PR Batch (Phase 0-1)

| Order | Task ID | Branch name | Suggested PR title | Required reviewer |
|------|---------|-------------|--------------------|-------------------|
| 1 | `P0-1` | `feat/pr-0252-p0-1-workspace-port` | `refactor(frontend): PR-0252 P0-1 add workspace port abstraction` | 1 reviewer |
| 2 | `P0-2` | `feat/pr-0252-p0-2-regression-checklist` | `docs(frontend): PR-0252 P0-2 add regression checklist v1` | 1 reviewer |
| 3 | `P0-3` | `feat/pr-0252-p0-3-pr-gate-rules` | `docs(frontend): PR-0252 P0-3 lock PR gate rules` | 1 reviewer |
| 4 | `P0-4` | `feat/pr-0252-p0-4-note-save-tracker` | `refactor(frontend): PR-0252 P0-4 extract note save tracker` | 1 reviewer |
| 5 | `P0-5` | `feat/pr-0252-p0-5-sample-review-closure` | `docs(frontend): PR-0252 P0-5 sample PR review and regression closure` | TL mandatory |
| 6 | `P1-1` | `feat/pr-0252-p1-1-workspace-tree-manager` | `refactor(frontend): PR-0252 P1-1 extract workspace tree manager` | 1 reviewer |
| 7 | `P1-2` | `feat/pr-0252-p1-2-note-draft-manager` | `refactor(frontend): PR-0252 P1-2 extract note draft manager` | 1 reviewer |
| 8 | `P1-3` | `feat/pr-0252-p1-3-note-tag-manager` | `refactor(frontend): PR-0252 P1-3 extract note tag manager` | 1 reviewer |
| 9 | `P1-4` | `feat/pr-0252-p1-4-create-folder-dialog` | `refactor(frontend): PR-0252 P1-4 extract create folder dialog` | 1 reviewer |
| 10 | `P1-5` | `feat/pr-0252-p1-5-delete-folder-dialog` | `refactor(frontend): PR-0252 P1-5 extract delete folder dialog` | 1 reviewer |
| 11 | `P1-6` | `feat/pr-0252-p1-6-rename-node-dialog` | `refactor(frontend): PR-0252 P1-6 extract rename node dialog` | 1 reviewer |
| 12 | `P1-7` | `feat/pr-0252-p1-7-move-node-dialog` | `refactor(frontend): PR-0252 P1-7 extract move node dialog` | 1 reviewer |
| 13 | `P1-8` | `feat/pr-0252-p1-8-explorer-tree-builder` | `refactor(frontend): PR-0252 P1-8 extract explorer tree builder` | 1 reviewer |

## PR Batch (Phase 2-3)

| Order | Task ID | Branch name | Suggested PR title | Required reviewer |
|------|---------|-------------|--------------------|-------------------|
| 14 | `P2-1` | `feat/pr-0252-p2-1-note-tab-manager` | `refactor(frontend): PR-0252 P2-1 extract note tab manager` | 1 reviewer |
| 15 | `P2-2` | `feat/pr-0252-p2-2-note-list-manager` | `refactor(frontend): PR-0252 P2-2 extract note list manager` | 1 reviewer |
| 16 | `P2-3` | `feat/pr-0252-p2-3-notes-coordinator` | `refactor(frontend): PR-0252 P2-3 create notes coordinator and migrate consumers` | TL mandatory |
| 17 | `P2-4` | `feat/pr-0252-p2-4-test-migration` | `refactor(frontend): PR-0252 P2-4 migrate tests from NotesController to NotesCoordinator` | 1 reviewer |
| 18 | `P3-1` | `feat/pr-0252-p3-1-section-registry` | `refactor(frontend): PR-0252 P3-1 create section registry and decouple entry shell` | 1 reviewer |
| 19 | `P3-2` | `feat/pr-0252-p3-2-entry-shell-verification` | `docs(frontend): PR-0252 P3-2 verify entry shell zero cross-feature import` | 1 reviewer |
| 20 | `P3-3` | `feat/pr-0252-p3-3-boundary-map-update` | `docs(frontend): PR-0252 P3-3 update boundary map to reflect post-refactor state` | 1 reviewer |
| 21 | `P3-4` | `feat/pr-0252-p3-4-retrospective` | `docs(frontend): PR-0252 P3-4 deliver refactor retrospective` | 1 reviewer |
| 22 | `P3-5` | `feat/pr-0252-p3-5-tl-acceptance` | `docs(frontend): PR-0252 P3-5 TL stage acceptance and closure sign-off` | TL mandatory |

## Task Checklist (PR-0252 Execution Board)

- [x] `P0-1` create `workspace_port.dart`
- [x] `P0-2` regression checklist v1 confirmed
- [ ] `P0-3` PR gate rules confirmed
- [ ] `P0-4` NoteSaveTracker sample extraction PR merged
- [ ] `P0-5` sample PR TL review and regression pass
- [ ] `P1-1` WorkspaceTreeManager extracted
- [ ] `P1-2` NoteDraftManager extracted
- [ ] `P1-3` NoteTagManager extracted
- [ ] `P1-4` CreateFolderDialog extracted
- [ ] `P1-5` DeleteFolderDialog extracted
- [ ] `P1-6` RenameNodeDialog extracted
- [ ] `P1-7` MoveNodeDialog extracted
- [ ] `P1-8` ExplorerTreeBuilder extracted
- [ ] `P2-1` NoteTabManager extracted
- [ ] `P2-2` NoteListManager extracted
- [ ] `P2-3` NotesCoordinator created and consumers migrated
- [ ] `P2-4` tests migrated from NotesController to NotesCoordinator
- [ ] `P3-1` SectionRegistry landed and EntryShellPage migrated
- [ ] `P3-2` zero cross-feature import verification passed
- [ ] `P3-3` boundary map updated
- [ ] `P3-4` retrospective doc delivered
- [ ] `P3-5` TL stage acceptance and closure sign-off

## Planned File Changes

- [add] `apps/lazynote_flutter/lib/features/notes/workspace_port.dart`
- [add] `apps/lazynote_flutter/lib/features/notes/notes_coordinator.dart`
- [add/edit] `apps/lazynote_flutter/lib/features/notes/managers/*`
- [add] `apps/lazynote_flutter/lib/features/notes/dialogs/*`
- [add] `apps/lazynote_flutter/lib/features/notes/explorer_tree_builder.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/note_content_area.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- [delete] `apps/lazynote_flutter/lib/features/notes/notes_controller.dart` (after `P2-3`)
- [add] `apps/lazynote_flutter/lib/app/section_registry.dart`
- [edit] `apps/lazynote_flutter/lib/features/entry/entry_shell_page.dart`
- [edit] `apps/lazynote_flutter/lib/app/ui_slots/first_party_ui_slots.dart`
- [edit] `apps/lazynote_flutter/test/*` (targeted migration per `PR-0255C` Section 5.5)
- [edit] `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` (task status updates)

## Verification and Gates

### Mandatory CI Gates (every PR)

- `cd apps/lazynote_flutter && dart format --output=none --set-exit-if-changed .`
- `cd apps/lazynote_flutter && flutter analyze`
- `cd apps/lazynote_flutter && flutter test`
- `cd apps/lazynote_flutter && flutter build windows --debug`

Baseline rule:

- test baseline must remain `313 pass / 0 known-fail`.
- no newly introduced failures are allowed.

Baseline note:

- `CalendarPage` layout overflow at `calendar_page.dart:67` was fixed on `main` on 2026-02-24 before refactor execution.

### Structural Gate Checks (D1-D8)

- `rg -n "import.*managers/" apps/lazynote_flutter/lib/features/notes/notes_page.dart apps/lazynote_flutter/lib/features/notes/note_content_area.dart apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- `if (Test-Path "apps/lazynote_flutter/lib/features/notes/managers") { rg -n "import.*flutter" apps/lazynote_flutter/lib/features/notes/managers/ } else { Write-Output "[skip] managers/ not created yet" }`
- `if (Test-Path "apps/lazynote_flutter/lib/features/notes/dialogs") { rg -n "import.*(coordinator|manager)" apps/lazynote_flutter/lib/features/notes/dialogs/ } else { Write-Output "[skip] dialogs/ not created yet" }`
- `rg -n "features/workspace" apps/lazynote_flutter/lib/features/notes/`
- `rg -n "notes_style" apps/lazynote_flutter/lib/features/tags/`

### Rollback Rule

- any single extraction PR must be independently revertable.
- `P2-3` and `P2-4` are a coupled rollback unit and must be reverted together if needed.

## Acceptance Criteria

- [ ] all tasks `P0-1..P3-5` are completed, or explicitly scope-cut with TL approval record
- [ ] phase DoD in `PR-0255C` Section 3/11 is satisfied and traceable
- [ ] `notes_controller.dart` is removed and replaced by `NotesCoordinator + managers`
- [ ] EntryShellPage reaches zero cross-feature import for non-entry features
- [ ] D1-D8 checks pass with phase-specific allowances from `PR-0255C` Section 6.4
- [ ] regression baseline remains `313 pass / 0 known-fail` with no new failures
- [ ] no Rust/FFI signature drift is introduced

## Execution PR Specs

Individual task specs are in `docs/releases/v0.2.5/prs/PR-0252/`:

### Phase 0

- `P0-1-workspace-port.md`
- `P0-2-regression-checklist.md`
- `P0-3-pr-gate-rules.md`
- `P0-4-note-save-tracker.md`
- `P0-5-sample-review-closure.md`

### Phase 1

- `P1-1-workspace-tree-manager.md`
- `P1-2-note-draft-manager.md`
- `P1-3-note-tag-manager.md`
- `P1-4-create-folder-dialog.md`
- `P1-5-delete-folder-dialog.md`
- `P1-6-rename-node-dialog.md`
- `P1-7-move-node-dialog.md`
- `P1-8-explorer-tree-builder.md`

### Phase 2

- `P2-1-note-tab-manager.md`
- `P2-2-note-list-manager.md`
- `P2-3-notes-coordinator.md`
- `P2-4-test-migration.md`

### Phase 3

- `P3-1-section-registry.md`
- `P3-2-entry-shell-verification.md`
- `P3-3-boundary-map-update.md`
- `P3-4-retrospective.md`
- `P3-5-tl-acceptance.md`
