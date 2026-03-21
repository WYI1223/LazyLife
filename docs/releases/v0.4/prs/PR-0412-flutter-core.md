# PR-0412: Flutter Core WorkspaceTreeService B+ and Mutation Delta
- Proposed title: `feat(workspace): adopt guarded workspace core contracts in WorkspaceTreeService`
- Status: Merged

## Goal

Land the Flutter core slice of the workspace-topology chain by upgrading
`WorkspaceTreeService` to consume the guarded workspace FFI exported in
`PR-0411`, own system-node resolution, expose `TreeMutationDelta`, and leave a
stable core contract for `PR-0413` feature migration.

## Closeout Snapshot (2026-03-20)

Implementation is now merged and the Flutter core contract is closed. Review
leader sign-off, focused regressions, full Flutter validation, and architecture
checks are all complete. A smoke-driven follow-up fix also landed in this PR:
post-`0012` "Root" mutations in Flutter no longer forward `null parent` for
ordinary nodes, and root create flows now refresh the concrete workspace branch
instead of relying on legacy synthetic-root semantics.

## Implementation Snapshot (2026-03-20)

The landed Flutter-core shape now includes:

- guarded workspace typedefs, `buildWorkspaceCaller(...)`,
  `WorkspaceInitException`, `DesignatedRoleNotFoundException`,
  `WorkspaceGetDefaultInvoker`, `TreeMutationType`, and `TreeMutationDelta` in
  `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart`
- `WorkspaceTreeService.loadSystemNodes(...)`,
  `WorkspaceTreeService.getSystemNodeId(...)`, `lastMutation`, targeted
  mutation-delta emission for create/rename/move/delete, and
  `reassignDesignated(...)` cache refresh in
  `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`
- guarded workspace default/resolve/reassign/ancestor-path wiring through
  `NotesCoordinator` defaults and constructor plumbing in
  `apps/lazynote_flutter/lib/features/notes/notes_coordinator.dart`,
  `apps/lazynote_flutter/lib/features/notes/notes_coordinator_impl.dart`, and
  `apps/lazynote_flutter/lib/features/notes/notes_coordinator_defaults.dart`
- post-`0012` root-bridge fixes in
  `apps/lazynote_flutter/lib/features/notes/note_explorer.dart` so move-dialog
  "Root" targets, drag-to-root drops, and root note/folder create refreshes all
  resolve to the concrete default workspace root id rather than a legacy
  `null`-parent placeholder
- focused service coverage for designated preload, sync lookup, mutation
  deltas, and reassign behavior in
  `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`
- focused Explorer regressions in
  `apps/lazynote_flutter/test/explorer_context_actions_test.dart`,
  `apps/lazynote_flutter/test/note_explorer_tree_test.dart`, and
  `apps/lazynote_flutter/test/workspace_integration_flow_test.dart` locking the
  concrete-root move/create bridge and post-`0012` branch-refresh behavior

`PR-0412` explicitly consumes:

- `OI-035` tree navigation via guarded node-based ancestor-path usage and
  preserved atom-based compatibility
- `OI-036` unified creation and TreeService evolution via
  create-without-parent delta resolution to the concrete default workspace root
- `OI-038` FFI surface and migration bridge via guarded workspace exports wired
  into Flutter core while legacy consumer migration remains deferred
- `OI-039` WorkspaceTreeService B+ shape via designated-node cache only,
  mutation metadata, and no local subtree cache
- `OI-040` mutation-delta and targeted-reload contract via create/rename/move/
  delete/reassign parent-impact emission
- `OI-042` system-node resolution ownership via `loadSystemNodes(...)` and
  `getSystemNodeId(...)`
- `OI-045` execution order by consuming the already-landed `PR-0408` through
  `PR-0411A` chain without pulling `PR-0413` feature migration forward
- `OI-048` verification gates through focused workspace service tests, replayed
  notes guard regressions, full Flutter validation, and repository architecture
  checks

## Verification Snapshot (2026-03-20)

Fresh replay used for this closeout:

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
flutter test test/notes_controller_workspace_tree_guards_test.dart -r compact
flutter test test/explorer_context_actions_test.dart -r compact
flutter test test/note_explorer_tree_test.dart -r compact
flutter test test/workspace_integration_flow_test.dart -r compact

cd ../..
dart run tools/ci/architecture_check.dart
```

Results:

- `flutter analyze`: PASS
- `flutter test`: PASS
- focused workspace service tests: PASS
- legacy notes workspace guard tests: PASS
- focused Explorer/root-bridge regressions: PASS
- `architecture_check`: PASS (`0` broken docs links / `0` architecture
  violations; existing non-blocking generated-file size warning remains)

## Executable Plan

Implementation is tracked in:

- [`docs/superpowers/plans/2026-03-19-pr-0412-flutter-core.md`](../../../superpowers/plans/2026-03-19-pr-0412-flutter-core.md)

This spec is the contract. The linked plan is the step-by-step execution guide.

## Dependency Clarification

`PR-0412` consumes the already-landed upstream chain:

- `PR-0408` schema, designated-folder, and workspace metadata contracts
- `PR-0409` scoped-query and compatibility-bridge contracts
- `PR-0410` canonical creation/tree-routing contracts
- `PR-0411` guarded FFI exports and caller contract
- `PR-0411A` structural cleanup of Rust FFI module layout

Canonical implication:

- Flutter core must consume workspace behavior through guarded FFI contracts,
  never through raw schema assumptions.
- `WorkspaceTreeService` may own a small designated-node cache and mutation
  metadata, but it must not become a second tree store.
- `query_atoms` consumer migration stays owned by `PR-0413`.

## Workflow Inputs

This PR must explicitly consume and later report against these handoff bundles:

- `OI-035` tree navigation
- `OI-036` unified creation and TreeService evolution
- `OI-038` FFI surface and migration bridge
- `OI-039` WorkspaceTreeService B+ shape and no-cache rule
- `OI-040` mutation-delta and targeted-reload contract
- `OI-042` system-node resolution ownership
- `OI-045` execution order
- `OI-048` verification gates

Primary workflow source:

- [`docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`](../../../reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md)

Shared governance decision point:

- [`docs/reports/v0.4/governance-execution/carrier-promotion-decision-register.md`](../../../reports/v0.4/governance-execution/carrier-promotion-decision-register.md)

`PR-0412` may land implementation and update workflow evidence, but it may not
publish carrier text directly.

## In Scope

- `WorkspaceTreeService` consumption of guarded FFI:
  - `workspace_resolve_designated`
  - `workspace_reassign_designated`
  - `workspace_get_ancestor_path`
  - optionally `workspace_get_default` if needed for local bootstrap helpers
- `FfiCallerContext(identity, scopeWorkspaceId)` helper usage inside Flutter
  core workspace code
- `TreeMutationDelta` and `TreeMutationType`
- `loadSystemNodes(workspaceId)` and `getSystemNodeId(workspaceId, role)`
- cache refresh after successful `reassignDesignated(...)`
- dedicated service-level tests for mutation deltas, designated cache behavior,
  and caller plumbing
- workflow-ledger updates for `flutter-core`, `execution-order`, and the
  `PR-0412` part of `verification-gates`

## Out of Scope

- `query_atoms` adoption in feature controllers
- broader Tasks, Calendar, Notes, Entry, or Explorer consumer migration
- synthetic uncategorized removal
- tree UI layering changes beyond the narrow post-`0012` operability bridge
  needed to keep concrete-root create/move behavior usable in `NoteExplorer`
- legacy FFI removal
- ADR, ruling, or topic-map publication

`PR-0412` may still land smoke-driven `NoteExplorer` fixes when they are
strictly required to preserve the already-landed Flutter-core contract
(`TreeMutationDelta`, concrete default-workspace-root semantics, or guarded
workspace wiring). Broader consumer migration, UX cleanup, and synthetic-node
removal remain with `PR-0413`.

## Historical Pre-Implementation Reality

The current `WorkspaceTreeService` still reflects the pre-`PR-0411` shape:

- it consumes only legacy workspace tree FFI
- it still routes ancestor-path lookup through the atom-based compatibility API
- it has no designated-node cache
- it exposes only coarse `workspaceTreeRevision`, not targeted mutation deltas
- it still depends on `WorkspaceTreeChildrenLoader`, including synthetic
  uncategorized fallback behavior

`PR-0412` must improve the service shape without prematurely pulling `PR-0413`
feature cleanup into core.

## Canonical Delivery Decisions

### 1. WorkspaceTreeService owns only designated-node cache, not tree cache

`WorkspaceTreeService` may cache:

- designated folder node ids by `(workspaceId, role)`
- latest `TreeMutationDelta`
- coarse revision counters already exposed today

It must not cache:

- subtree child lists
- parent/child graph snapshots
- projected query results

This preserves the `DI-17` no-cache rule while still allowing synchronous
feature access to system-node ids.

### 2. Mutation deltas are computed from request context plus ancestor-path FFI

`WorkspaceTreeService` must not infer mutation impact by maintaining a local
tree mirror.

Instead:

- create uses the target parent already present in the request; when the
  request omits `parentNodeId`, Flutter core must resolve the real default
  workspace root id and emit that concrete id instead of `{null}`
- rename resolves the current parent through `workspace_get_ancestor_path`
- move resolves the old parent through `workspace_get_ancestor_path` before the
  mutation and combines it with the requested new parent
- delete resolves the current parent through `workspace_get_ancestor_path`
- reassign resolves both old and new designated folders and computes their
  parents through `workspace_get_ancestor_path`

This keeps delta ownership in Flutter core without violating the no-cache rule.

### 3. System-node resolution is async preload plus sync lookup

Canonical Flutter core contract:

- `Future<void> loadSystemNodes(String workspaceId)`
- `String getSystemNodeId(String workspaceId, String role)`

`loadSystemNodes(...)` populates the designated-node cache by consuming guarded
FFI. `getSystemNodeId(...)` is synchronous and throws explicit exceptions when
called before a role is loaded or after a required role is missing.

Recommended explicit exceptions:

- `WorkspaceInitException`
- `DesignatedRoleNotFoundException`

### 4. Caller helper is mandatory for guarded workspace FFI

Any new guarded workspace FFI consumption in Flutter core must pass:

```dart
FfiCallerContext(
  identity: FfiCallerIdentity.app,
  scopeWorkspaceId: workspaceId,
)
```

`workspaceId` remains the business target. `scopeWorkspaceId` remains the
declared access scope. They must not be collapsed into a single concept.

### 5. Create-without-parent still resolves to the default workspace root, not
top-level null parent

`PR-0410` already tightened ordinary-node root semantics:

- new writes no longer create ordinary nodes with a real `NULL` parent
- root-level ordinary-node semantics are replaced by “attach to the default
  workspace root”

`PR-0412` must preserve that contract when computing mutation deltas.

Canonical implication:

- `createWorkspaceFolder(..., parentNodeId: null)` may still be a valid Flutter
  core entrypoint for “create under default workspace”
- but the emitted `TreeMutationDelta.affectedParentIds` must contain the real
  default workspace root id, never `{null}`
- if a future PR needs a top-level workspace-root sentinel, it must define that
  sentinel explicitly instead of reusing ordinary-node `null` semantics

### 6. Atom-based ancestor path remains compatibility-only in this PR

`PR-0412` may keep the old atom-based `ancestorPath(atomId)` helper alive for
current feature callers, but it must not expand that compatibility shape.

The canonical new core-side path consumption is node-based:

- `workspace_get_ancestor_path(caller, nodeUuid)`

Full feature migration to the new path belongs to `PR-0413`.

## Target File Set

Primary implementation files:

- `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart`
- `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`
- `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`

Supporting documentation files:

- `docs/releases/v0.4/prs/PR-0412-flutter-core.md`
- `docs/superpowers/plans/2026-03-19-pr-0412-flutter-core.md`
- `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`

Only touch other Flutter files if strictly required to preserve compileability,
existing constructor wiring, or the narrow smoke-driven `NoteExplorer`
operability bridge for concrete-root create/move behavior.

## Chunked Execution Summary

1. Add RED tests for caller helper, designated cache behavior, and mutation
   delta envelopes.
2. Extend `workspace_tree_types.dart` with guarded invoker typedefs,
   `TreeMutationDelta`, and explicit exceptions.
3. Upgrade `WorkspaceTreeService` to consume guarded FFI, load designated
   folders, and expose synchronous system-node lookup.
4. Emit targeted mutation deltas using ancestor-path lookups instead of local
   tree caching.
5. Replay Flutter validation and update workflow/spec evidence.

## Verification

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test

cd ../..
dart run tools/ci/architecture_check.dart
```

Targeted replay commands that must exist in the execution plan:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
flutter test test/notes_controller_workspace_tree_guards_test.dart -r compact
```

## Acceptance Criteria

- [x] `WorkspaceTreeService` consumes guarded workspace FFI through explicit
      caller helpers
- [x] `workspace_tree_types.dart` defines `TreeMutationDelta`,
      `TreeMutationType`, and guarded workspace invoker typedefs
- [x] `loadSystemNodes(workspaceId)` loads `inbox`, `tasks`, and `calendar`
      designated folders through guarded FFI
- [x] `getSystemNodeId(workspaceId, role)` is synchronous and throws explicit
      exceptions on missing cache entries
- [x] successful `reassignDesignated(...)` refreshes the local designated-node
      cache for the affected role
- [x] successful create, rename, move, delete, and reassign operations each
      emit `TreeMutationDelta` with correct `affectedParentIds`
- [x] create-without-parent resolves `affectedParentIds` to the concrete
      default workspace root id rather than `{null}`
- [x] mutation-delta calculation uses ancestor-path FFI or request context, not
      local subtree caching
- [x] existing coarse `workspaceTreeRevision` behavior remains intact for
      current consumers
- [x] `flutter analyze` is green
- [x] `flutter test` is green
- [x] `workspace-topology-carrier-promotion-workflow.md` updates
      `flutter-core`, `execution-order`, and the `PR-0412` portion of
      `verification-gates` with evidence paths
- [x] closeout notes explicitly cite `OI-035`, `OI-036`, `OI-038`, `OI-039`,
      `OI-040`, `OI-042`, `OI-045`, and `OI-048`
- [x] PR spec status remains `Draft` until landing; update to `Merged` only
      after code, tests, and closeout evidence are landed
