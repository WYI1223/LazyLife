# PR-0257-pane-aware-tab-manager-upgrade

- Proposed title: `refactor(frontend): PR-0257 extend NoteTabManager with pane-scoped tab tracking`
- Status: Planned

## Goal

Extend NoteTabManager from a flat `_openNoteIds` list to a pane-scoped
`_openNoteIdsByPane` map, so the coordinator can read pane-level tab state
from NoteTabManager instead of WorkspaceProvider. This is a prerequisite
for PR-0258 (notes↔workspace decoupling).

Prerequisite:

- `PR-0256` completed (S2 ruling documented).

## Execution Contract (Canonical Inputs)

- PR plan: `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md` Section 4.5
- Solution proposal: `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md` Section 3.1.1 (prerequisite)
- Critical code context: `notes_coordinator_impl.dart:269-279` (dual-source `openNoteIds` getter)

## Scope

In scope:

- NoteTabManager pane-scoped data structures and methods
- coordinator `openNoteIds` getter switch to NoteTabManager
- coordinator open/close/activate method routing update
- new pane-scoped tab tests

Out of scope:

- WP Bridge deletion (PR-0258)
- WP tab/save state deletion (PR-0258)
- test file deletion (PR-0258)

## Background

The coordinator's `openNoteIds` getter (`notes_coordinator_impl.dart:269-279`)
currently reads WP's `openTabsByPane` exclusively in multi-pane mode:

```dart
List<String> get openNoteIds {
    final workspaceTabs = _workspaceProvider.openTabsByPane[_workspaceProvider.activePaneId];
    if (_workspaceProvider.layoutState.paneOrder.length > 1) {
      return List.unmodifiable(workspaceTabs);  // multi-pane: reads WP only
    }
    return workspaceTabs.isEmpty
        ? _noteTabManager.openNoteIds  // single-pane fallback: flat list
        : List.unmodifiable(workspaceTabs);
}
```

NoteTabManager currently only has flat `_openNoteIds: List<String>`
(`managers/note_tab_manager.dart:56`), no per-pane tracking. If PR-0258
deletes WP's tab state without upgrading NoteTabManager first, multi-pane
tab routing will break.

## Task Breakdown

| Task | Content | File | Est. Change | Dep |
|------|---------|------|-------------|-----|
| T1 | Add `_openNoteIdsByPane: Map<String, List<String>>` and `_activePaneId` fields to NoteTabManager | `managers/note_tab_manager.dart` | add ~20 lines | — |
| T2 | Add pane-scoped methods: `openNoteIdsForPane(paneId)`, `addNoteToPane(paneId, atomId)`, `removeNoteFromPane(paneId, atomId)`, `switchPane(paneId)`, `addPane(paneId)`, `removePane(paneId, mergeToPaneId)` | `managers/note_tab_manager.dart` | add ~80 lines | T1 |
| T3 | Refactor NoteTabManager internal methods (`openNote`, `closeNote`, `activateNote`, etc.) from operating on `_openNoteIds` to operating on `_openNoteIdsByPane[activePaneId]`, preserving single-pane behavior | `managers/note_tab_manager.dart` | edit ~60 lines | T2 |
| T4 | Update coordinator's `openNoteIds` getter: read from `_noteTabManager.openNoteIdsForPane(activePaneId)` instead of `_workspaceProvider.openTabsByPane` | `notes_coordinator_impl.dart:269-279` | edit ~10 lines | T3 |
| T5 | Update coordinator's `_openNote`, `_closeNote`, `_activateNote` methods: route through NoteTabManager pane-scoped methods | `notes_coordinator_impl.dart` | edit ~30 lines | T4 |
| T6 | Add pane-scoped tab management tests | `test/note_tab_manager_pane_test.dart` or extend `test/note_tab_manager_test.dart` | add ~100 lines (~5 test cases) | T3 |

### Critical Path

`T1 → T2 → T3 → T4 → T5`

T6 can run in parallel with T4-T5 (tests can be written against T3's output).

## Branching Convention

- Branch: `feat/pr-0257-pane-aware-tab-manager`
- PR title: `refactor(frontend): PR-0257 extend NoteTabManager with pane-scoped tab tracking`

## Planned File Changes

- `[edit]` `apps/lazynote_flutter/lib/features/notes/managers/note_tab_manager.dart` (~160 lines changed)
- `[edit]` `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart` (~40 lines changed)
- `[add]` or `[edit]` pane-scoped tab test file

## Line Count Impact

| File | Before | After | Delta |
|------|--------|-------|-------|
| `note_tab_manager.dart` | 343 | ~440 | +100 (pane-scoped logic) |
| `notes_coordinator_impl.dart` | 1,782 | 1,782 | 0 (internal impl change, line count neutral) |

## Test Baseline

Entry: 333 pass / 0 fail (PR-0252 exit)
Exit: 333 + ~5 new pane tests = **~338 pass / 0 fail**

## Task Checklist

- [ ] `T1` add pane-scoped fields to NoteTabManager
- [ ] `T2` add pane-scoped methods
- [ ] `T3` refactor internal methods to pane-scoped
- [ ] `T4` update coordinator `openNoteIds` getter
- [ ] `T5` update coordinator open/close/activate routing
- [ ] `T6` add pane-scoped tab tests

## Verification (cwd: `apps/lazynote_flutter/`)

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

## Risk

| Risk | Severity | Mitigation |
|------|----------|------------|
| Single-pane regression | MEDIUM | T3 must preserve flat list semantic compatibility: when only one pane exists, behavior is identical to original flat list |
| NoteTabManager out of sync with WP split/close | MEDIUM | Coordinator's `splitActivePane`/`closeActivePane` call chains must synchronously notify NoteTabManager to add/remove panes |

## Rollback

Independent branch, safe to revert entirely. Does not affect other PRs.

## Acceptance Criteria

- [ ] NoteTabManager supports `openNoteIdsForPane(paneId)` method.
- [ ] Coordinator `openNoteIds` reads from NoteTabManager in both single-pane and multi-pane modes.
- [ ] Existing single-pane behavior fully preserved (all 333 existing tests pass).
- [ ] New pane-scoped test coverage: add/remove/switch pane, tab open/close within pane.
- [ ] CI green (format + analyze + test + build).
