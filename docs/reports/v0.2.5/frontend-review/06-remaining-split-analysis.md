# 06 — Remaining Split Analysis

> Post-PR-0252 deep analysis of large modules and new technical debt.
> Provides actionable split/no-split verdicts with trigger conditions for future planning.

| Field | Value |
|-------|-------|
| Date | 2026-02-26 |
| Baseline commit | `c30f91a` (post PR-0252 closure) |
| Parent | `05-refactor-retrospective.md` |
| Scope | NoteExplorer, NotesCoordinator impl, D9, D10 |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [NoteExplorer Analysis](#2-noteexplorer-analysis)
3. [NotesCoordinator Impl Analysis](#3-notescoordinator-impl-analysis)
4. [D9 — Coordinator Impl Scale](#4-d9--coordinator-impl-scale)
5. [D10 — Reminders Cross-Feature Import](#5-d10--reminders-cross-feature-import)
6. [Decision Matrix](#6-decision-matrix)
7. [Recommended Next Actions](#7-recommended-next-actions)

---

## 1. Executive Summary

PR-0252 completed 23 tasks and decomposed the 3,160-line `NotesController` into a coordinator + 6 managers. Two large modules remain above original targets:

| Module | Actual | Original target | Verdict |
|--------|--------|-----------------|---------|
| `note_explorer.dart` | 1,720 lines | < 500 | **Hold** — already well-layered; further split has diminishing returns |
| `notes_coordinator_impl.dart` | 1,782 lines | < 300 | **Hold** — best next move is subtraction (delete WP bridge), not extraction |

Two new technical debt items (D9, D10) were identified during PR-0252 retrospective. Neither requires immediate action.

**Overall recommendation: no new split PR in v0.2.x.** The codebase is safe for v0.3 feature overlay. The most impactful improvement is deleting the WorkspaceProvider compatibility bridge once consumers migrate to direct coordinator access.

---

## 2. NoteExplorer Analysis

### 2.1 Current State

- **File:** `lib/features/notes/note_explorer.dart`
- **Lines:** 1,720 (physical, `wc -l`)
- **Type:** `StatefulWidget` + `State<NoteExplorer>`
- **PR-0252 target:** < 500 lines
- **Deviation:** +1,220 lines (3.4x target)

### 2.2 Already-Extracted Satellite Files

PR-0252 extracted the following from the original NoteExplorer:

| File | Lines | Responsibility |
|------|-------|----------------|
| `explorer_tree_builder.dart` | 357 | Tree node construction, folder/note row rendering |
| `explorer_tree_state.dart` | 229 | Expand/collapse state, toggle logic |
| `explorer_drag_controller.dart` | 103 | Drag hit-test geometry, drop target detection |
| `explorer_context_menu.dart` | 65 | Menu item enum and label definitions |
| `dialogs/create_folder_dialog.dart` | 85 | Create folder dialog widget |
| `dialogs/delete_folder_dialog.dart` | 127 | Delete folder confirmation dialog |
| `dialogs/rename_node_dialog.dart` | 93 | Rename node dialog widget |
| `dialogs/move_node_dialog.dart` | 105 | Move node dialog widget |
| **Subtotal extracted** | **1,164** | |

The explorer subsystem totals 2,884 lines across 9 files. NoteExplorer itself retains the orchestration and widget build logic.

### 2.3 Functional Area Breakdown

| Area | Line range (approx.) | Lines | Key methods |
|------|----------------------|-------|-------------|
| **Imports + typedefs** | L1–L70 | ~70 | 6 invoker typedefs, 17 imports |
| **State fields + init** | L70–L180 | ~110 | Constructor params, `initState()`, `dispose()`, state flags |
| **Controller listener + tree reload** | L180–L265 | ~85 | `_handleControllerChange()`, `_reloadRootTree()`, `_refreshParentBranch()` |
| **Widget build + layout** | L265–L700 | ~435 | `build()`, `_buildBody()`, `_buildSuccessTree()`, `_createTreeBuilder()`, `_buildTagFilter()`, `_buildScrollableRows()` |
| **Note tap handling** | L695–L730 | ~35 | `_handleNoteTap()`, `_isSyntheticRootNodeId()` |
| **Context menu triggers** | L729–L830 | ~100 | `_recordRowContextMenuTrigger()`, `_shouldSuppressBlankAreaContextMenu()`, `_showBlankAreaContextMenu()`, `_showBlankAreaContextMenuDeferred()` |
| **Root drop lane** | L793–L845 | ~50 | `_buildRootDropLane()` |
| **Drag & drop wrapping** | L844–L1075 | ~230 | `_wrapWorkspaceRowWithDrag()`, `_buildDragFeedback()`, `_performDragMove()`, `_refreshDropBranches()` |
| **Row context menus** | L1076–L1240 | ~165 | `_showFolderContextMenu()`, `_showNoteContextMenu()`, `_showContextMenuAtPosition()`, `_runContextAction()` |
| **Dialog orchestration** | L1238–L1700 | ~460 | `_buildFolderTree()`, `_showCreateFolderDialog()`, `_showDeleteFolderDialog()`, `_handleCreateNoteFromContext()`, `_showRenameNodeDialog()`, `_showMoveNodeDialog()`, `_loadMoveTargetOptions()` |
| **Helper types** | L1700–L1720 | ~20 | `_ExplorerContextTarget` enum-like class |

### 2.4 Candidate Split Points

#### A. Dialog Orchestration Layer (~460 lines)

**What:** The 5 `_show*Dialog()` methods + `_handleCreateNoteFromContext()` + `_loadMoveTargetOptions()` + `_buildFolderTree()`.

**Extract to:** A mixin (`NoteExplorerDialogMixin`) or a stateless helper class.

**Pros:**
- Largest contiguous block, self-contained async logic
- Each method takes `BuildContext` + callback/coordinator references
- Clear separation: "which dialog to show" vs "how to render the tree"

**Cons:**
- All methods need access to `widget.*` (8 callback fields), `_treeState`, `mounted`, `setState()`
- A mixin on `State<NoteExplorer>` would compile but offers no real decoupling — the mixin is only usable by NoteExplorer
- A helper class would need ~10 constructor parameters to replicate the State context
- Dialog widgets are already extracted; what remains is the orchestration glue

**Verdict:** Marginal net benefit. The overhead of parameter threading negates the readability gain.

#### B. Drag & Drop Layer (~230 lines)

**What:** `_wrapWorkspaceRowWithDrag()`, `_buildDragFeedback()`, `_performDragMove()`, `_refreshDropBranches()`.

**Extract to:** Expand `ExplorerDragController` to include widget wrapping logic.

**Pros:**
- `_buildDragFeedback()` (53 lines) is pure render — no state dependency
- `_performDragMove()` is async with clear input/output

**Cons:**
- `_wrapWorkspaceRowWithDrag()` is a 100-line method that builds `Draggable` + `DragTarget` widgets, deeply interleaved with tree state reads (`_treeState.isExpanded`, `_dragInProgress`) and `setState()` calls
- Splitting would require either a callback-heavy interface or exposing internal state

**Verdict:** Not recommended unless DnD complexity grows significantly (e.g., multi-select drag).

#### C. Context Menu Trigger Layer (~265 lines)

**What:** Blank area + folder + note context menu show/dispatch logic.

**Extract to:** A delegate class that receives `BuildContext` + action callback.

**Pros:**
- `_showContextMenuAtPosition()` is a reusable overlay-positioning utility
- Menu trigger logic is conceptually separate from tree rendering

**Cons:**
- `_runContextAction()` dispatches to 5 different dialog orchestrators — extracting it alone creates a circular dependency back to the dialog layer
- Only ~100 lines of pure trigger logic; ~165 lines are action dispatch that couples back to State

**Verdict:** Not worth it as standalone extraction. Would only make sense if combined with dialog extraction (A+C together = ~725 lines), but then the "extracted" piece is larger than the remainder.

### 2.5 Verdict: Hold

**NoteExplorer should not be split further in v0.2.x.**

Rationale:
1. The 1,720-line count is inflated by the nature of Flutter `StatefulWidget`: lifecycle, `BuildContext`, `setState()` references make clean extraction into non-mixin classes impractical.
2. The effective satellite extraction (1,164 lines in 8 files) already achieved the real modularity goal: tree rendering, state tracking, drag detection, and all 4 dialogs are independently testable units.
3. The remaining code is orchestration glue — connecting tree state, context menus, drag operations, and dialog launches. This is inherently cohesive.
4. No single extraction candidate offers > 300 lines of clean separation without introducing parameter-threading overhead.

**Trigger for re-evaluation:**
- NoteExplorer exceeds 2,200 lines (growth > 30%)
- v0.3 introduces multi-select or batch operations (new interaction axis)
- A second consumer of explorer-like tree UI appears (justifying shared abstraction)

---

## 3. NotesCoordinator Impl Analysis

### 3.1 Current State

- **File:** `lib/features/notes/notes_coordinator_impl.dart`
- **Lines:** 1,782 (physical, `wc -l`)
- **Type:** `part of` coordinator, extends `ChangeNotifier`
- **PR-0252 target:** < 300 lines (coordinator as thin routing layer)
- **Deviation:** +1,482 lines (5.9x target)
- **Public API file:** `notes_coordinator.dart` (53 lines, re-exports)

### 3.2 Manager Delegation Structure

The coordinator owns 6 managers via composition:

| Manager | Lines | `notifyListeners` calls | State owned |
|---------|-------|------------------------|-------------|
| `NoteListManager` | 227 | 6 | List items, phase, error, filter state |
| `NoteTabManager` | 363 | 15 | Open tabs, active tab, preview tab, pane split |
| `NoteTagManager` | 330 | 7 | Tag catalog, selected filter, loading state |
| `NoteDraftManager` | 263 | 7 | Draft content, version, dirty tracking |
| `NoteSaveTracker` | 95 | 3 | Save state, save futures, error |
| `WorkspaceTreeManager` | 533 | 5 | Tree revision, folder CRUD state, workspace ops |
| **Manager subtotal** | **1,811** | **43** | |

### 3.3 Functional Area Breakdown

| Area | Line range (approx.) | Lines | Nature |
|------|----------------------|-------|--------|
| **Typedef declarations** | L1–L30 | ~30 | 7 invoker + 2 factory typedefs |
| **Constructor + field init** | L39–L210 | ~170 | 11 named params, 6 manager instantiation, listener wiring |
| **Getter proxy layer** | L212–L470 | ~260 | ~50 getters delegating to managers (`get x => _manager.x`) |
| **Manager listener bridges** | L485–L527 | ~40 | 6 `_handle*Changed()` methods, each calls `notifyListeners()` |
| **Pane split operations** | L336–L430 | ~95 | `splitPane()`, `closeSplitPane()`, `switchActivePane()`, `activateNextPane()` |
| **Note lifecycle (load/select)** | L557–L670 | ~115 | `loadNotes()`, `retryLoad()`, `selectNote()`, `activateOpenNote()`, tab cycling |
| **Note CRUD (create)** | L827–L940 | ~115 | `createNote()` — multi-step: create atom → insert list → tag apply → open tab → focus |
| **Tag operations** | L924–L940 | ~15 | 3 thin delegates to `_noteTagManager` |
| **Workspace operations** | L648–L750 | ~100 | `createWorkspaceFolder()`, `deleteWorkspaceFolder()`, `listWorkspaceChildren()`, etc. |
| **Save pipeline** | L759–L830 | ~70 | `flushPendingSave()`, `retrySaveCurrentDraft()` |
| **Draft update + autosave** | L1108–L1150 | ~40 | `updateActiveDraft()` |
| **Internal load machinery** | L1149–L1350 | ~200 | `_loadNotes()`, `_loadSelectedDetail()`, `_syncPersistedSnapshot()` |
| **Tab reconciliation** | L941–L1030 | ~90 | `_reconcileOpenTabsAfterWorkspaceMutation()` |
| **WorkspaceProvider sync bridge** | L1422–L1680 | ~260 | `_syncWorkspaceFromControllerState()`, `_adoptWorkspaceActivePaneState()`, `_syncWorkspaceActiveSnapshot()` |
| **Helpers** | L1350–L1420, L1680+ | ~100 | `_envelopeError()`, `_titleFromContent()`, `_isDirty()`, etc. |

### 3.4 Candidate Split Points

#### A. WorkspaceProvider Sync Bridge (~260 lines)

**What:** L1422–L1680 — bidirectional state projection between coordinator internal state and the legacy `WorkspaceProvider` interface.

**Includes:**
- `_syncWorkspaceFromControllerState()` (~70 lines) — pushes coordinator state → WorkspaceProvider
- `_adoptWorkspaceActivePaneState()` (~30 lines) — pulls WorkspaceProvider pane state → coordinator
- `_syncWorkspaceActiveSnapshot()` (~15 lines) — syncs active note snapshot
- `_mapSaveStateToWorkspace()`, `_workspaceSaveStateForNote()`, `_workspacePersistedContentFor()`, `_workspaceDraftContentFor()` — state type mapping
- The `_NoteDraftManagerWorkspaceAdapter` inner class (~60 lines) — adapter bridging draft manager API to WorkspaceProvider's expected interface

**Why it exists:** `WorkspaceProvider` predates the coordinator refactor. NoteExplorer and EntryShellPage consume `WorkspaceProvider` for tree state and save indicators. The bridge keeps them working without migrating those consumers.

**Recommended action: DELETE (not extract) in v0.3.**

The correct fix is to migrate `WorkspaceProvider` consumers to read from coordinator/managers directly, then remove the bridge entirely. This is subtraction, not extraction — the code should cease to exist, not move to another file.

**Preconditions for deletion:**
1. NoteExplorer stops reading `WorkspaceProvider` for save state (uses coordinator directly)
2. EntryShellPage/SectionRegistry builder closure stops passing `WorkspaceProvider` as listenable (uses coordinator)
3. `WorkspaceProvider` is either deleted or reduced to a thin reference holder

**Estimated reduction:** 250–270 lines from coordinator impl.

#### B. Getter Proxy Layer (~260 lines)

**What:** ~50 one-line getters like `List<NoteItem> get items => _noteListManager.items`.

**Why it exists:** Coordinator presents a single API surface to UI consumers (`NotesPage`, `NoteContentArea`, etc.). Without these proxies, consumers would need references to individual managers.

**Split option 1 — Keep as-is:** These are one-liner delegates. They add lines but zero complexity. The cognitive load is trivial.

**Split option 2 — Expose managers directly:** Let consumers hold manager references (e.g., `coordinator.tabManager.openNoteIds`). This removes proxy getters but couples consumers to manager existence.

**Recommended action: Defer.** The proxy pattern is standard for facade/coordinator. 260 lines of `get x => _mgr.x` is verbose but harmless. Exposing managers directly is a v0.3 architectural decision that affects the entire consumer surface.

#### C. Note Create Flow (~115 lines)

**What:** `createNote()` is the most complex single method — a multi-step transaction:
1. Validate not already creating
2. Call `note_create` FFI
3. Insert into list manager
4. Cache detail
5. Apply contextual tag (if filtered)
6. Await tag apply with timeout
7. Open as active tab
8. Handle `note_ref` workspace linking (if workspace active)
9. Bump tree revision
10. Request editor focus

**Split option:** Extract as a `NoteCreateUseCase` class with explicit dependencies.

**Pros:**
- Independently testable transaction
- Clear input (empty content) / output (success + atom ID)

**Cons:**
- Needs references to 4 managers + 3 invokers + workspace provider
- This is a one-time operation, not a reusable pattern
- The transaction semantics (step ordering, error handling) are inherently coordinator-level concerns

**Recommended action: Defer.** The complexity is necessary complexity. Extracting it moves the code but doesn't simplify the logic.

### 3.5 Line Budget Projection

| Scenario | Lines removed | Remaining | Notes |
|----------|--------------|-----------|-------|
| Current state | — | 1,782 | — |
| After WP bridge deletion (v0.3) | ~260 | ~1,520 | Largest single reduction |
| After WP bridge + getter simplification | ~520 | ~1,260 | Requires exposing managers |
| Theoretical minimum (thin routing only) | ~1,480 | ~300 | Would require 6+ use-case classes |

### 3.6 Verdict: Hold — Plan for Subtraction

**NotesCoordinator impl should not be split in v0.2.x.**

The coordinator's role is cross-manager orchestration. Extracting orchestration logic into more classes does not reduce coupling — it relocates it while adding indirection overhead.

**The highest-value next step is deleting the WorkspaceProvider bridge (~260 lines)** as part of v0.3 state management unification. This is subtraction (code removal), not extraction (code relocation).

**Trigger for re-evaluation:**
- Coordinator impl exceeds 2,200 lines
- A 7th manager is added
- v0.3 pane/split model requires a second coordinator

---

## 4. D9 — Coordinator Impl Scale

| Field | Value |
|-------|-------|
| Debt ID | D9 |
| Introduced | PR-0252 retrospective (2026-02-26) |
| Severity | Low |
| Module | `notes_coordinator_impl.dart` |
| Current | 1,782 lines |
| Original target | < 300 lines |

### Root Cause

The < 300 target assumed coordinator would be a pure delegation router. In practice, the coordinator also owns:

1. **Cross-manager transactions** — `createNote()`, `selectNote()`, `_reconcileOpenTabsAfterWorkspaceMutation()` require multi-manager state updates in specific order
2. **Detail load pipeline** — `_loadSelectedDetail()` involves request deduplication, cache update, error handling, and draft reconciliation
3. **WorkspaceProvider bridge** — ~260 lines of legacy adapter code (see Section 3.4A)
4. **Pane split operations** — ~95 lines of split/close/switch/cycle logic that spans tab manager + workspace provider

### Disposition

**Status: Acknowledged, no immediate action required.**

The coordinator impl size is a consequence of necessary orchestration complexity, not poor decomposition. The 6 managers collectively hold 1,811 lines of extracted logic that would otherwise be in this file.

**Effective reduction path:**
1. v0.3: Delete WorkspaceProvider bridge → ~1,520 lines
2. v0.3: If pane split model is redesigned, extract pane operations → ~1,425 lines
3. Long-term: If getter proxy pattern is abandoned → ~1,260 lines

**Trigger condition:** Coordinator impl exceeds 2,200 lines, or a new feature area (not notes) needs coordinator-like orchestration (justifying a shared coordinator base class).

---

## 5. D10 — Reminders Cross-Feature Import

| Field | Value |
|-------|-------|
| Debt ID | D10 |
| Introduced | PR-0252 retrospective (2026-02-26) |
| Severity | Low |
| Module | `features/calendar/`, `features/tasks/` |

### Current Imports

```
calendar_controller.dart  →  import features/reminders/reminder_scheduler.dart
tasks_controller.dart     →  import features/reminders/reminder_scheduler.dart
```

Both import `ReminderScheduler` to call `scheduleForAtom()` after creating/updating atoms with time fields.

### Analysis

**Nature of coupling:** `ReminderScheduler` is a cross-cutting infrastructure concern, not a feature-to-feature business dependency. It is analogous to:
- `l10n/app_localizations.dart` — imported by all features for i18n
- `core/diagnostics/dart_event_logger.dart` — imported for structured logging

**Why this differs from Rule E violations:**
- Rule E targets business coupling: Feature A importing Feature B's internal models/state
- `ReminderScheduler` exposes a single stateless method (`scheduleForAtom(atomId, startAt, endAt)`)
- No internal state of `features/reminders/` is leaked to consumers
- The import direction is "consumer → infrastructure", not "peer → peer"

### Resolution Options

| Option | Effort | Benefit | Recommendation |
|--------|--------|---------|----------------|
| A. Move `ReminderScheduler` to `lib/shared/` | Low | Formally compliant with Rule E letter | Unnecessary — moves file but changes nothing structurally |
| B. Inject via app-layer DI | Medium | Calendar/tasks controllers accept `ReminderScheduler` as constructor parameter | Over-engineered for a singleton with one method |
| C. Add Rule E exemption for infrastructure modules | Low | Documents intent, prevents false alarms in future audits | **Recommended** |
| D. No action | Zero | — | Acceptable given low severity |

### Disposition

**Recommended: Option C — Add Rule E exemption annotation.**

Add `reminders` to the same exemption category as `l10n` and `core/`. Infrastructure modules that provide cross-cutting services (notifications, logging, localization) should be explicitly exempted from Rule E's feature isolation constraint.

Suggested exemption wording for `engineering-standards.md`:

> **Rule E exemption — Infrastructure modules:** `features/reminders/`, `l10n/`, and `core/` are infrastructure modules providing cross-cutting services. They may be imported by any feature module without violating Rule E. This exemption does not extend to feature modules that contain business state or domain models.

**Trigger condition:** A third feature imports `ReminderScheduler`, or `reminders/` grows beyond pure scheduling to include feature-specific business logic.

---

## 6. Decision Matrix

| Item | Can split? | Worth splitting now? | Best next action | Trigger for re-evaluation |
|------|-----------|---------------------|------------------|--------------------------|
| NoteExplorer (1,720) | Yes — dialog layer (~460), DnD (~230), context menu (~265) | **No** — all candidates need extensive State parameter threading | Hold | > 2,200 lines or new interaction axis (multi-select) |
| Coordinator impl (1,782) | Yes — WP bridge (~260), getter proxy (~260), create flow (~115) | **No** — best move is subtraction (delete WP bridge), not extraction | Delete WP bridge in v0.3 | > 2,200 lines or 7th manager added |
| D9 (coordinator scale) | See coordinator impl | See coordinator impl | Acknowledge; plan WP bridge deletion | Same as coordinator impl |
| D10 (reminders import) | Yes — move to shared/ or inject via DI | **No** — infrastructure cross-cut, not business coupling | Add Rule E exemption | 3rd consumer or reminders gains business state |

---

## 7. Recommended Next Actions

### 7.1 No New Split PR in v0.2.x

The codebase is stable. Both large modules are at acceptable complexity for their responsibilities. Splitting them now would produce more indirection without meaningful decoupling benefit.

### 7.2 v0.3 WorkspaceProvider Bridge Deletion (Highest Value)

**Estimated effort:** 1–2 person-days
**Estimated lines removed:** 250–270 from coordinator impl + potential simplification of WorkspaceProvider itself

**Steps:**
1. Migrate NoteExplorer save-state reads from `WorkspaceProvider` to coordinator
2. Migrate EntryShellPage/SectionRegistry listenable from `WorkspaceProvider` to coordinator
3. Delete `_syncWorkspaceFromControllerState()`, `_adoptWorkspaceActivePaneState()`, `_NoteDraftManagerWorkspaceAdapter`, and related helper methods
4. Evaluate if `WorkspaceProvider` can be deleted entirely or reduced to a thin holder

### 7.3 Rule E Exemption for Infrastructure Modules

**Estimated effort:** < 0.5 person-day
**Action:** Update `docs/architecture/engineering-standards.md` Rule E with infrastructure module exemption clause covering `reminders/`, `l10n/`, `core/`.

### 7.4 Monitoring Thresholds

Establish automated line-count checks (can be added to CI or pre-merge script):

| File | Current | Warning | Action threshold |
|------|---------|---------|-----------------|
| `note_explorer.dart` | 1,720 | 2,000 | 2,200 |
| `notes_coordinator_impl.dart` | 1,782 | 2,000 | 2,200 |
| Any new single file | — | 800 | 1,000 |

---

## Appendix A: NoteExplorer Import Graph

```
note_explorer.dart
├── features/notes/dialogs/create_folder_dialog.dart    (same feature)
├── features/notes/dialogs/delete_folder_dialog.dart    (same feature)
├── features/notes/dialogs/move_node_dialog.dart        (same feature)
├── features/notes/dialogs/rename_node_dialog.dart      (same feature)
├── features/notes/explorer_context_menu.dart           (same feature)
├── features/notes/explorer_drag_controller.dart        (same feature)
├── features/notes/explorer_tree_builder.dart           (same feature)
├── features/notes/explorer_tree_state.dart             (same feature)
├── features/notes/notes_coordinator.dart               (same feature)
├── features/notes/notes_style.dart                     (same feature)
├── features/tags/tag_filter.dart                       (cross-feature — D1)
├── core/bindings/api.dart                              (core)
└── l10n/app_localizations.dart                         (infrastructure)
```

## Appendix B: NotesCoordinator Impl Manager Wiring

```
_NotesCoordinatorImpl
├── _noteListManager: NoteListManager (227 lines)
│   └── owns: items, listPhase, listError, selectedTag
├── _noteTabManager: NoteTabManager (363 lines)
│   └── owns: openNoteIds, activeNoteId, previewTabId, pane split state
├── _noteTagManager: NoteTagManager (330 lines)
│   └── owns: availableTags, tagsLoading, tagFilter
├── _noteDraftManager: NoteDraftManager (263 lines)
│   └── owns: draftContent, draftVersion, persistedContent
├── _noteSaveTracker: NoteSaveTracker (95 lines)
│   └── owns: saveState, saveFutures, saveError
├── _workspaceTreeManager: WorkspaceTreeManager (533 lines)
│   └── owns: treeRevision, folderCRUD state, workspace operations
└── _workspaceProvider: WorkspaceProvider (external, features/workspace/)
    └── legacy bridge target — candidate for deletion in v0.3
```

## Appendix C: Cross-Feature Import Inventory (Post PR-0252)

| # | Source file | Imported feature | Import target | Debt ID |
|---|-----------|-----------------|---------------|---------|
| 1 | `notes/note_explorer.dart` | `tags` | `tag_filter.dart` | D1 |
| 2 | `notes/notes_style.dart` | (exported to `tags`) | — | D1 (exempted D8) |
| 3 | `notes/notes_coordinator.dart` | `workspace` | `workspace_provider.dart` | D4 |
| 4 | `notes/notes_coordinator.dart` | `workspace` | `workspace_models.dart` | D4 |
| 5 | `notes/workspace_port.dart` | `workspace` | `workspace_provider.dart` | D4 |
| 6 | `notes/workspace_port.dart` | `workspace` | `workspace_models.dart` | D4 |
| 7 | `search/search_results_view.dart` | `notes` | `notes_style.dart` | D2 |
| 8 | `tags/tag_filter.dart` | `notes` | `notes_style.dart` | D1 (exempted D8) |
| 9 | `calendar/calendar_controller.dart` | `reminders` | `reminder_scheduler.dart` | D10 |
| 10 | `tasks/tasks_controller.dart` | `reminders` | `reminder_scheduler.dart` | D10 |

**Total: 10 cross-feature imports** (baseline 16 → reduced 6 by PR-0252 EntryShellPage decoupling; +2 new from reminders).
