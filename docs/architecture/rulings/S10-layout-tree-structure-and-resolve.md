# S10: Layout Tree Structure And Resolve

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | `none` |
| Current ADR | [`../adr/ADR-0010-layout-tree-structure-and-resolve.md`](../adr/ADR-0010-layout-tree-structure-and-resolve.md) |

## Decision

Pane layout must be represented as an immutable recursive binary tree that resolves top-down from container space and persists through a dedicated staged layout contract.

## Normative Rules

1. The layout model uses a sealed `LayoutNode` hierarchy with `SplitNode(first, second, axis, fraction)` and `LeafNode(groupId)`.
2. Structural mutations rebuild and return a new `GroupLayout`; mutable per-node listener trees are not allowed as the authoritative layout model.
3. `resolve` is a top-down pass that emits leaf rects and divider metadata from available container space; data-layer authority does not depend on Flutter `LayoutDelegate` or bottom-up constraint solving.
4. The public layout surface is fixed at `split`, `closeGroup`, `resizeAt`, `resolve`, `allGroupIds`, and `canSplit`.
5. The layout tree must preserve the DI-2 invariant set: binary shape, unique leaf IDs, bounded fractions, minimum resolved size, non-empty root, group-leaf bijection, and no duplicate sibling leaves.
6. Group lifecycle maps onto tree operations: startup begins as one leaf, split replaces a leaf with a split node plus a new sibling leaf, close collapses a parent split to the surviving sibling, and the last pane never disappears.
7. Layout state is persisted to a standalone `workspace_layout.json` file, separate from `settings.json`, using one-second debounced atomic writes and recovery semantics that preserve the previous good file on failure.
8. The persisted payload includes the layout tree, per-group tab lists, per-group `activeTab` and `previewTab`, and `activeGroupId`; draft content, save state, and cursor position are not serialized into the layout file.
9. Migration from the old in-memory `WorkspaceLayoutState` world is a one-shot replacement rather than an on-disk compatibility conversion, because no prior persisted layout file existed for backward translation.
10. Split validation must reject growth beyond eight panes before resolve, then enforce minimum resolved pane size after resolve; no explicit depth cap is part of the line.
11. Restore is staged: DI-3 restores `GroupLayout` plus tab-shell state from JSON in the critical path, while DI-4 later loads buffer content into those already-created loading buffers.
12. Stage-2 loading runs through shell-owned load callbacks and must preserve the already-restored group and loading-buffer shells rather than rebuilding layout state.
13. Active and background buffers may use different load timing, but both paths must converge on the same runtime load semantics and buffer lifecycle outcomes.
14. Stage-2 load failure is handled at the buffer/state layer; it must not invalidate the recovered layout tree or rewrite the structural contract.
15. The old three-track parallel rollout model is not current for this line; DI-6 replaces it with a rebased dependency sequence because layout structure and editor-state infrastructure no longer live on separable delivery lanes.
16. Gate B is the editor-infrastructure checkpoint for this line: multi-pane structure, persistence, staged restore, and same-line runtime loading behavior must form one coherent baseline before the editor-infrastructure phase is treated as closed.
17. Gate A and the Release Gate remain explicit boundaries around this line: semantic/data prerequisites close before Gate B, while broader Gate A and release-policy mechanics remain outside the current line even after DI-7 closes the line-specific Gate B precision and verification surface.
18. Gate B verification for this line must use explicit checks rather than vague language: multi-pane structure, same-atom cross-pane editing behavior, DI-2 invariants, DI-3 restore fallback, and DI-4/5 runtime synchronization behavior all require named measurable checks.
19. Audit-language mappings such as "same-note multi-pane editing content-coherent", "recursive split stable", and "preview/pinned tab deterministic" must be translated into executable check surfaces before Gate B is treated as precise.
20. Performance evaluation for this line inherits the DI-4 latency envelope and must be stated against canonical document sizes, pane-count scenarios, and an explicit baseline rather than a bare `>= 60 FPS` goal.
21. The current v0.3 SLA table for this line includes service-path thresholds for split/close, buffer sync, persistence, and startup restore, plus frame-budget targets for tab switching and typing.
22. Verification for this line is two-layered: service-layer Stopwatch regression guards may run in CI with relaxed thresholds, while frame-sensitive UI checks use local profile-mode integration testing at Gate B.
23. v0.3 does not require a dedicated automated benchmark-CI system for this line; the current contract is the two-layer verification model plus relaxed CI regression guards.

## Current Interpretation

- This line is distinct from `S2`: `S2` answers who owns tab/draft/save state, while `S10` answers how pane layout itself is modeled, persisted, restored, populated after restore, and positioned inside the rebased delivery sequence.
- Current architecture should read `GroupLayout`, the top-down resolve algorithm, invariant enforcement, layout persistence, pane-cap enforcement, the staged restore boundary, the stage-2 loading continuation, and the rebased dependency/gate framing from this ruling first.
- DI-7 closed the line-specific precision gap for this line: Gate B exactness, benchmark dimensions, the v0.3 SLA table, the two-layer verification model, and the no-benchmark-CI decision now belong to the same current-effective interpretation.
- Broader repo-wide Gate A, Release Gate, and test-migration policy remains explicit governance carry-forward material rather than current line semantics.

## Open Edges

- Later implementation-lineage evidence may append without changing the structural contract itself.
- Broader repo-wide Gate A / Release Gate / test-migration policy remains outside this line and continues as explicit governance carry-forward material.

## Traceability

- Historical structural source: [`../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md`](../../reports/v0.3/design-discussions/DI-2-layout-tree-structure.md)
- Historical persistence source: [`../../reports/v0.3/design-discussions/DI-3-layout-persistence.md`](../../reports/v0.3/design-discussions/DI-3-layout-persistence.md)
- Later loading source: [`../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md`](../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md)
- Later gate/dependency source: [`../../reports/v0.3/design-discussions/DI-6-cross-track-dependencies.md`](../../reports/v0.3/design-discussions/DI-6-cross-track-dependencies.md)
- Later verification/SLA source: [`../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md`](../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md)
- Journey record: [`../adr/ADR-0010-layout-tree-structure-and-resolve.md`](../adr/ADR-0010-layout-tree-structure-and-resolve.md)
