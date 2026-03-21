# PR-0412 Flutter Core Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `WorkspaceTreeService` to consume guarded workspace FFI, own designated-folder resolution plus mutation-delta metadata, and leave a stable Flutter core contract for `PR-0413` feature migration.

**Architecture:** Keep `WorkspaceTreeService` as a thin core facade over FFI, not a second tree database. Add only a small designated-node cache and `TreeMutationDelta` metadata. Compute mutation impact from request context plus guarded `workspace_get_ancestor_path` lookups instead of caching subtree state. Preserve existing coarse `workspaceTreeRevision` and legacy atom-based `ancestorPath(...)` compatibility for current feature callers until `PR-0413`.

Important contract carried forward from `PR-0410`: ordinary-node creation with
`parentNodeId == null` still means “attach to the default workspace root,” not
“emit a real top-level null parent.” Any create delta in this plan must resolve
that concrete workspace-root id before writing `affectedParentIds`.

**Tech Stack:** Dart, Flutter, Flutter Rust Bridge generated bindings, `ChangeNotifier`, guarded workspace FFI from `PR-0411`, Markdown workflow/spec docs

---

## Closeout Snapshot (2026-03-20)

Implementation is now merged. Review-leader sign-off, focused Flutter core
workspace tests, full Flutter validation, and repository architecture checks
have all been replayed green. A smoke-driven follow-up also landed in this PR:
post-`0012` Root-target mutations now resolve to the concrete default workspace
root id, and root create flows refresh the concrete workspace branch instead of
depending on legacy synthetic-root semantics.

## File Responsibility Map

- `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart`
  - Add guarded-workspace invoker typedefs.
  - Add `buildWorkspaceCaller(workspaceId)`.
  - Add `TreeMutationType`, `TreeMutationDelta`, and explicit exceptions used by core consumers.
- `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`
  - Remains the only core owner of workspace tree mutation state.
  - Add designated-node cache, guarded FFI consumption, mutation-delta emission, and reassign/system-node APIs.
  - Keep existing coarse revision and legacy atom-based `ancestorPath(...)` compatibility.
- `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`
  - New focused service-level tests for designated loading, sync lookup, mutation deltas, and reassign refresh.
- `apps/lazynote_flutter/test/notes_controller_workspace_tree_guards_test.dart`
  - Keep existing guard/busy/error behavior locked if service constructor or public shape changes.
- `docs/releases/v0.4/prs/PR-0412-flutter-core.md`
  - Spec closeout snapshot and current acceptance record.
- `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`
  - Update `flutter-core`, `execution-order`, and `verification-gates`.

## Chunk 1: Lock The B+ Contract With RED Tests

### Task 1: Create a focused `WorkspaceTreeService` test file

**Files:**
- Create: `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`
- Modify: `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart`
- Modify: `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`

- [x] **Step 1: Write failing tests for designated-node preload and sync lookup**

Cover at minimum:
- `loadSystemNodes(workspaceId)` loads `inbox`, `tasks`, `calendar`
- `getSystemNodeId(workspaceId, role)` returns the cached node id
- `getSystemNodeId(...)` throws before preload
- `loadSystemNodes(...)` throws explicit error on missing designated role

- [x] **Step 2: Write failing tests for caller helper and typed delta metadata**

Cover at minimum:
- `buildWorkspaceCaller('ws-1')` sets `identity=app`
- `buildWorkspaceCaller('ws-1')` sets `scopeWorkspaceId='ws-1'`
- `TreeMutationDelta` preserves `revision`, `type`, and deduped `affectedParentIds`

- [x] **Step 3: Run the new file and confirm RED**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: FAIL because guarded typedefs, exceptions, cache behavior, and delta types do not exist yet.

### Task 2: Add the new core types with minimal implementation

**Files:**
- Modify: `apps/lazynote_flutter/lib/core/workspace/workspace_tree_types.dart`

- [x] **Step 1: Add guarded invoker typedefs**

Add:
- `WorkspaceResolveDesignatedInvoker`
- `WorkspaceReassignDesignatedInvoker`
- `WorkspaceGetAncestorPathInvoker`

Keep existing legacy typedefs intact.

- [x] **Step 2: Add caller helper and exceptions**

Add:
- `FfiCallerContext buildWorkspaceCaller(String workspaceId)`
- `WorkspaceInitException`
- `DesignatedRoleNotFoundException`

- [x] **Step 3: Add mutation-delta types**

Add:
- `enum TreeMutationType { create, rename, move, delete, reassign }`
- `class TreeMutationDelta`

- [x] **Step 4: Re-run the targeted tests**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: some type-level tests PASS, service-behavior tests still FAIL.

## Chunk 2: Land Designated-Node Resolution Without Feature Migration

### Task 3: Extend `WorkspaceTreeService` constructor and state

**Files:**
- Modify: `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`
- Test: `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`

- [x] **Step 1: Add guarded invoker dependencies and internal cache**

Add injected fields for:
- `WorkspaceResolveDesignatedInvoker`
- `WorkspaceReassignDesignatedInvoker`
- `WorkspaceGetAncestorPathInvoker`

Add internal state:
- designated cache keyed by `(workspaceId, role)`
- `TreeMutationDelta? _lastMutation`
- `int _mutationRevision`

- [x] **Step 2: Keep legacy surface intact**

Do not remove:
- `workspaceTreeRevision`
- legacy CRUD methods
- `ancestorPath({required String atomId})`
- `WorkspaceTreeChildrenLoader`

- [x] **Step 3: Add getters for new core metadata**

Add at least:
- `TreeMutationDelta? get lastMutation`
- sync designated lookup method(s)

- [x] **Step 4: Re-run the focused tests**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: cache-lookup tests still fail because preload methods are not implemented yet.

### Task 4: Implement `loadSystemNodes(...)` and `getSystemNodeId(...)`

**Files:**
- Modify: `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`
- Test: `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`

- [x] **Step 1: Implement designated preload through guarded FFI**

Behavior:
- call `_prepare()`
- resolve `inbox`, `tasks`, `calendar` with `buildWorkspaceCaller(workspaceId)`
- cache successful ids under the requested workspace
- treat `workspace_not_found` and `designated_role_not_found` as explicit initialization failures

- [x] **Step 2: Implement synchronous role lookup**

Behavior:
- return cached id immediately
- throw `WorkspaceInitException` if workspace was never loaded
- throw `DesignatedRoleNotFoundException` if role is absent after load

- [x] **Step 3: Make preload idempotent**

If the same workspace is already fully loaded, early-return instead of re-hitting FFI.

- [x] **Step 4: Run the focused tests to GREEN**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: preload and sync lookup tests PASS.

## Chunk 3: Emit Mutation Deltas Without Violating The No-Cache Rule

### Task 5: Write failing delta tests for create, rename, move, and delete

**Files:**
- Modify: `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`

- [x] **Step 1: Add failing tests for `createWorkspaceFolder(...)` delta**

Assert:
- `lastMutation.type == TreeMutationType.create`
- when `parentNodeId != null`, `affectedParentIds == {parentNodeId}`
- when `parentNodeId == null`, `affectedParentIds` contains the concrete
  default workspace root id, not `{null}`

- [x] **Step 2: Add failing tests for `renameWorkspaceNode(...)` delta**

Stub guarded ancestor-path invoker to return the current parent chain and assert:
- `type == rename`
- `affectedParentIds` contains the resolved current parent only

- [x] **Step 3: Add failing tests for `moveWorkspaceNode(...)` delta**

Stub ancestor-path lookup before mutation and assert:
- old parent and new parent both appear
- same-parent move dedupes to one entry

- [x] **Step 4: Add failing tests for `deleteWorkspaceFolder(...)` delta**

Stub ancestor-path lookup before delete and assert:
- parent of deleted folder appears in `affectedParentIds`

- [x] **Step 5: Run the service test file and confirm RED**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: new delta tests FAIL.

### Task 6: Implement ancestor-path-backed delta emission

**Files:**
- Modify: `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`
- Test: `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`

- [x] **Step 1: Add private helpers to resolve parent ids from node-based ancestor path**

Suggested helpers:
- `_resolveParentForNode(String nodeId)`
- `_emitMutation(TreeMutationType type, Iterable<String?> parentIds)`

- [x] **Step 2: Wire create/rename/move/delete to emit deltas only on success**

Rules:
- do not emit delta on failed mutation
- keep `workspaceTreeRevision` bump behavior unchanged
- dedupe `affectedParentIds` with `Set<String?>`
- resolve create-without-parent to the real default workspace root id before
  emitting the delta

- [x] **Step 3: Re-run focused tests**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: create/rename/move/delete delta tests PASS.

## Chunk 4: Land Designated Reassign And Cache Refresh

### Task 7: Write failing tests for reassign flow

**Files:**
- Modify: `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`

- [x] **Step 1: Add failing test for successful reassign**

Assert:
- guarded reassign invoker receives `buildWorkspaceCaller(workspaceId)`
- cached designated node id for the role updates to `newNodeUuid`
- `lastMutation.type == TreeMutationType.reassign`
- `affectedParentIds` contains both old and new parents

- [x] **Step 2: Add failing test for failed reassign**

Assert:
- cache is unchanged
- no delta emitted
- existing mutation error surfaces remain actionable

- [x] **Step 3: Run the focused test file and confirm RED**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: reassign tests FAIL.

### Task 8: Implement `reassignDesignated(...)`

**Files:**
- Modify: `apps/lazynote_flutter/lib/core/workspace/workspace_tree_service.dart`
- Test: `apps/lazynote_flutter/test/core/workspace/workspace_tree_service_test.dart`

- [x] **Step 1: Resolve current designated folder before mutation**

Use cached role if loaded; otherwise resolve through guarded designated lookup so the method can compute old-parent impact.

- [x] **Step 2: Resolve old/new parents through node-based ancestor path**

Do this before mutating so the service stays no-cache but still computes a precise delta.

- [x] **Step 3: Perform guarded reassign and refresh cache**

On success:
- update cached role mapping
- emit `TreeMutationType.reassign`
- notify listeners

- [x] **Step 4: Re-run the focused service tests**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/core/workspace/workspace_tree_service_test.dart -r compact
```

Expected: reassign tests PASS.

## Chunk 5: Replay Existing Guards And Close Out Docs

### Task 9: Replay existing workspace guard tests

**Files:**
- Test: `apps/lazynote_flutter/test/notes_controller_workspace_tree_guards_test.dart`

- [x] **Step 1: Run existing guard regression tests**

Run:

```bash
cd apps/lazynote_flutter
flutter test test/notes_controller_workspace_tree_guards_test.dart -r compact
```

Expected: PASS, proving new core shape did not break current notes-side workspace wiring.

### Task 10: Run full Flutter validation and sync docs

**Files:**
- Modify: `docs/releases/v0.4/prs/PR-0412-flutter-core.md`
- Modify: `docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md`
- Modify: `docs/superpowers/plans/2026-03-19-pr-0412-flutter-core.md`

- [x] **Step 1: Run formatting and analysis**

Run:

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
```

Expected: PASS

- [x] **Step 2: Run Flutter tests**

Run:

```bash
cd apps/lazynote_flutter
flutter test
```

Expected: PASS

- [x] **Step 3: Run repository architecture validation**

Run:

```bash
dart run tools/ci/architecture_check.dart
```

Expected: `PASSED - no architecture violations.`

- [x] **Step 4: Update spec and workflow closeout**

Record:
- implementation snapshot
- verification snapshot
- `flutter-core` row status and evidence
- `execution-order` note showing Flutter core slice is now landed while feature migration stays pending
- `verification-gates` note for new Flutter core service tests
- explicit consumption notes for:
  - `OI-035` tree navigation
  - `OI-036` unified creation and TreeService evolution
  - `OI-038` FFI surface and migration bridge
  - `OI-039` WorkspaceTreeService B+ shape
  - `OI-040` mutation-delta and targeted reload
  - `OI-042` system-node resolution ownership
  - `OI-045` execution order
  - `OI-048` verification gates
  - note that the post-`0012` move-to-root / drag-to-root bridge and root-note
    branch refresh were pulled into `PR-0412` as a smoke-driven operability
    fix, leaving broader Explorer move UX cleanup with `PR-0413`

- [x] **Step 5: Commit**

Closeout complete: the branch owner committed and merged `PR-0412`.

```bash
git add -A apps/lazynote_flutter/lib apps/lazynote_flutter/test docs/releases/v0.4/prs/PR-0412-flutter-core.md docs/reports/v0.4/governance-execution/PR-0403/workspace-topology-carrier-promotion-workflow.md docs/superpowers/plans/2026-03-19-pr-0412-flutter-core.md
git commit -m "feat(workspace): land flutter core workspace service contract"
```

## Exit Criteria

- `WorkspaceTreeService` consumes guarded designated and ancestor-path FFI through explicit caller helpers.
- `WorkspaceTreeService` owns only designated-node cache plus mutation metadata, not subtree cache.
- `loadSystemNodes(...)` and `getSystemNodeId(...)` are landed and covered by focused tests.
- create, rename, move, delete, and reassign all emit correct `TreeMutationDelta` values.
- current `workspaceTreeRevision` behavior remains intact.
- legacy atom-based `ancestorPath(...)` helper remains compatibility-only and still works for current feature callers.
- Flutter validation and architecture checks are green.
- `flutter-core` workflow evidence is updated and the spec contains an implementation/verification snapshot after landing.
