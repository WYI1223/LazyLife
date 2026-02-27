# PR-0258-notes-workspace-structural-decoupling

- Proposed title: `refactor(frontend): PR-0258 eliminate notes-workspace dual state system`
- Status: Planned

## Goal

Eliminate the dual-state system between NotesCoordinator and WorkspaceProvider.
After this PR, the coordinator is the sole source of tab/draft/save state;
WorkspaceProvider is reduced to pane-layout-only management.

Prerequisite:

- `PR-0257` completed (NoteTabManager pane-aware upgrade).

## Execution Contract (Canonical Inputs)

- PR plan: `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md` Section 4.6
- Solution proposal: `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md` Section 3.1.1 + 3.1.3
- Consumer audit: 08c 3.1.1 verified consumer table (app.dart, notes_page.dart, workspace_port.dart)
- Test audit: 08c 3.1.1 verified test table (bridge test 9 cases, WP test 7 tab/save cases)

## Scope

In scope:

- 08c 3.1.1 steps 1-6 (WP decoupling)
- 08c 3.1.3 steps 2-3 (coordinator slimming)
- affected test migration / deletion

Out of scope:

- Phase 2 EditorShellService extraction (v0.3)
- notes→workspace pane layout import elimination (v0.3)
- notes↔tags cycle break (PR-0259)
- reminders migration (PR-0259)

## WP Tab/Save State Consumers (verified)

| Consumer | File:Line | WP Fields Read | Migration |
|----------|-----------|----------------|-----------|
| app shell title | `app.dart:71-77` | `openTabsByPane`, `activePaneId` | read coordinator's `openNoteIds.length` |
| notes page overlay | `notes_page.dart:440-451` | `openTabsByPane`, `saveStateByNoteId` | read coordinator/managers |
| workspace port snapshot | `workspace_port.dart:4` | `openTabsByPane` (typedef field) | delete typedef (with WP Bridge) |

## Task Breakdown (strict sequential execution)

| Task | Content | File | Est. Change | Dep |
|------|---------|------|-------------|-----|
| T1 | Migrate `notes_page.dart` consumers: `openTabsByPane` → coordinator/managers | `notes_page.dart:438-454` | edit ~30 lines | — |
| T2 | Migrate `app.dart` titleBuilder: `workspace.openTabsByPane` → `coordinator.openNoteIds` | `app.dart:71-77` | edit ~5 lines | — |
| T3 | Delete `_syncWorkspaceActiveSnapshot()` method | `notes_coordinator_impl.dart` | delete ~12 lines | T1, T2 |
| T4 | Delete `_syncWorkspaceFromControllerState()` method | `notes_coordinator_impl.dart` | delete ~68 lines | T3 |
| T5 | Remove all sync call-sites in coordinator (`_openNote`, `_closeNote`, etc.) | `notes_coordinator_impl.dart` | edit ~15 lines | T3, T4 |
| T6 | Delete `_WorkspaceProviderPort` adapter class (lines 1608-1692) | `notes_coordinator_impl.dart` | delete ~85 lines | T5 |
| T7 | Delete `workspace_port.dart` | `workspace_port.dart` | delete 28 lines (entire file) | T6 |
| T8 | Delete helper mapping methods (`_mapSaveStateToWorkspace`, `_workspaceSaveStateForNote`, etc.) | `notes_coordinator_impl.dart` | delete ~70 lines | T6 |
| T9 | Slim WorkspaceProvider: delete tab/save/buffer state fields and all sync methods | `workspace_provider.dart` | delete ~464 lines (664 → ~200) | T5 |
| T10 | Update coordinator constructor: remove bridge initialization | `notes_coordinator_impl.dart` | edit ~15 lines | T9 |
| T11 | Remove `workspace_port.dart` import from `notes_coordinator.dart` | `notes_coordinator.dart` | delete 1 line | T7 |
| T12 | Extract typedef declarations and default invokers to `notes_coordinator_types.dart` (08c 3.1.3 step 2) | `notes_coordinator_impl.dart` → `notes_coordinator_types.dart` | new file ~150 lines, original -~150 lines | T10 |
| T13 | Evaluate getter proxy layer simplification (08c 3.1.3 step 3) | `notes_coordinator_impl.dart` | edit/delete ~50 lines (est.) | T12 |
| T14 | Delete `notes_controller_workspace_bridge_test.dart` (entire file) | `test/notes_controller_workspace_bridge_test.dart` | delete ~380 lines | T9 |
| T15 | Trim `workspace_provider_test.dart`: delete tab/save state tests, keep pane layout tests | `test/workspace_provider_test.dart` | delete ~140 lines | T9 |

### Critical Path

`T1 → T3 → T4 → T5 → T6 → T7/T8 (parallel) → T9 → T10 → T12 → T13`

T2 can run in parallel with T1. T11 runs after T7. T14 and T15 can run after T9.

## Branching Convention

- Branch: `feat/pr-0258-notes-workspace-decoupling`
- PR title: `refactor(frontend): PR-0258 eliminate notes-workspace dual state system`

## Planned File Changes

- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- `[edit]` `apps/lazynote_flutter/lib/app/app.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` (primary: ~260 lines deleted + ~150 lines extracted)
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator.dart`
- `[delete]` `apps/lazynote_flutter/lib/features/notes/workspace_port.dart`
- `[edit]` `apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart` (primary: ~464 lines deleted)
- `[add]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_types.dart`
- `[delete]` `apps/lazynote_flutter/test/notes_controller_workspace_bridge_test.dart`
- `[edit]` `apps/lazynote_flutter/test/workspace_provider_test.dart`

## Line Count Impact

| File | Before | After | Delta |
|------|--------|-------|-------|
| `notes_coordinator_impl.dart` | 1,782 | ~1,400 | -382 (delete sync/bridge ~260 + extract types ~150 + simplify ~50, add back imports ~78) |
| `workspace_provider.dart` | 664 | ~200 | -464 |
| `workspace_port.dart` | 28 | 0 | -28 (deleted) |
| `notes_coordinator_types.dart` | 0 | ~150 | +150 (new) |
| **Production code net** | | | **~-724 lines** |

## WP State Deletion Map

| Deleted | Phase 1 Owner |
|---------|---------------|
| `_openTabsByPane` | coordinator → NoteTabManager (PR-0257 upgraded) |
| `_activeTabByPane` | coordinator → NoteTabManager |
| `_buffersByNoteId` | coordinator → NoteDraftManager |
| `_saveStateByNoteId` | coordinator → NoteSaveTracker |
| `_saveDebounceByNoteId` | coordinator → NoteSaveTracker |
| `_saveInFlightByNoteId` | coordinator → NoteSaveTracker |
| **Kept** | `_layoutState`, `_activePaneId`, `splitActivePane`, `closeActivePane` |

## Test Baseline

Entry: ~338 pass / 0 fail (PR-0257 exit)
Exit: ~338 - 16 deleted = **~322 pass / 0 fail**

> Count method: by `test(` call count within files (consistent with 08c 3.1.1 test table).

Test reduction details:
1. Bridge tests (9 cases, entire file deleted): `notes_controller_workspace_bridge_test.dart` tests a system that no longer exists
2. WP tab/save tests (7 cases, selectively deleted from `workspace_provider_test.dart` 15 cases): tab/draft/save state migrated to coordinator managers with existing manager test coverage; 8 pane layout tests kept

## Task Checklist

- [ ] `T1` migrate `notes_page.dart` consumers
- [ ] `T2` migrate `app.dart` titleBuilder
- [ ] `T3` delete `_syncWorkspaceActiveSnapshot()`
- [ ] `T4` delete `_syncWorkspaceFromControllerState()`
- [ ] `T5` remove sync call-sites
- [ ] `T6` delete `_WorkspaceProviderPort`
- [ ] `T7` delete `workspace_port.dart`
- [ ] `T8` delete helper mapping methods
- [ ] `T9` slim WorkspaceProvider
- [ ] `T10` update coordinator constructor
- [ ] `T11` remove workspace_port import
- [ ] `T12` extract typedefs to `notes_coordinator_types.dart`
- [ ] `T13` evaluate getter proxy simplification
- [ ] `T14` delete bridge test file
- [ ] `T15` trim WP test file

## Verification

### CI gates (cwd: `apps/lazynote_flutter/`)

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

### Structural verification (cwd: repo root)

```bash
# Verify no bridge code residue
rg -n "syncExternalNote|beginBatchSync|endBatchSync|resetAll|syncSaveState" \
  apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart
# Expected: zero matches

# Verify WP has no tab/save state
rg -n "openTabsByPane|buffersByNoteId|saveStateByNoteId|_activeTabByPane" \
  apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart
# Expected: zero matches

# Verify workspace_port.dart deleted
test ! -f apps/lazynote_flutter/lib/features/notes/workspace_port.dart

# Line count check
wc -l apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart  # < 1,500
wc -l apps/lazynote_flutter/lib/features/workspace/workspace_provider.dart  # < 250
```

## Risk

| Risk | Severity | Mitigation |
|------|----------|------------|
| Consumer migration missed | HIGH | After T1/T2, run `rg "workspaceProvider\." notes_page.dart` — only pane layout calls should remain |
| Test reduction causes coverage gap | MEDIUM | Map each deleted test assertion to existing coordinator/manager test |
| Pane layout ops out of sync with NoteTabManager | MEDIUM | Coordinator's `splitActivePane`/`closeActivePane` call chains must synchronously operate NoteTabManager (PR-0257 handled) |

## Rollback

Single branch, can revert entirely. No coupled rollback units.

## Acceptance Criteria

- [ ] `notes_page.dart` reads tab/save state from coordinator, no longer from WP.
- [ ] `app.dart` titleBuilder reads from coordinator, no longer from WP.
- [ ] `_syncWorkspaceActiveSnapshot` and `_syncWorkspaceFromControllerState` deleted from coordinator_impl.
- [ ] `_WorkspaceProviderPort` class deleted.
- [ ] `workspace_port.dart` deleted.
- [ ] Helper mapping methods deleted.
- [ ] WorkspaceProvider reduced to pane-layout-only (no tab/save/buffer state).
- [ ] Typedefs and default invokers extracted to `notes_coordinator_types.dart`.
- [ ] `notes_controller_workspace_bridge_test.dart` deleted.
- [ ] `workspace_provider_test.dart` retains only pane layout tests.
- [ ] `notes_coordinator_impl.dart` < 1,500 lines.
- [ ] `workspace_provider.dart` < 250 lines.
- [ ] CI green (format + analyze + test + build).
