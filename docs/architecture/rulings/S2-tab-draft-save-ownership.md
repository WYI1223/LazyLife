# S2: Tab Draft Save Ownership

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S2-tab-draft-save-ownership.md`](../rulings-legacy/S2-tab-draft-save-ownership.md) |
| Current ADR | [`../adr/ADR-0002-editor-shell-ownership.md`](../adr/ADR-0002-editor-shell-ownership.md) |

## Decision

Tab, draft, save, and pane-aware editing state belong to workbench-level editor-shell infrastructure rather than to notes-local feature state.

## Normative Rules

1. Shell state must have one authoritative owner at any given time.
2. Dual-write bridge patterns are not allowed.
3. Tab state is pane-aware rather than single-pane-only.
4. `EditorGroupModel` owns per-pane visual state such as tab list, active atom, and preview-tab identity.
5. `EditBuffer` owns per-atom editing state, including content, last-saved snapshot, save phase, and dirty/saving/error derivation.
6. A tab title follows `atom.title`; it must not derive from per-ref `display_name`.
7. Loading and error guards are part of the shell contract: a buffer that is not `ready` must not accept edit/save/flush mutations.
8. Coordinator remains a mediator for feature DTO loading, tag sequencing, and injected callbacks, but it does not regain ownership of tab/draft/save state.
9. The line may be implemented in phases, but each phase must preserve the same single-source ownership direction and append detail to the same line rather than recreate shell ownership under a second carrier.
10. When the same atom is open in multiple panes, those panes must share one `EditBuffer` instance rather than maintain duplicated draft state.
11. `EditBuffer` keeps complete string content as the source of truth; advisory `EditOp` metadata may exist, but it must not replace full-string truth or create a second authoritative delta model.
12. Bridge semantics between `EditBuffer` and text widgets use direct buffer notifications plus string-comparison guards; consumer-side debounce is allowed for heavy derived views, but it does not replace immediate buffer notification.
13. Shell-owned load and persist callbacks control buffer hydration and flush behavior; active/background load timing may differ, but both must preserve the same ready/loading/error lifecycle rules.
14. Cursor and selection state remain per-pane UI state; synchronized cursors across panes are not part of the shell model.
15. The current single-process local model does not require a dedicated same-note conflict-handling subsystem; exclusive focus, serial `buffer.edit()` execution, and stale-save guards are the governing behavior.
16. `EditorResolver` is the shell-side selection layer that maps `content_type` to `EditorPane`; it sits between shell-owned state and feature-owned chrome rather than replacing either side.
17. The resolver-facing pane interface is limited to `BuildContext` and `EditBuffer`-derived inputs; it must not receive `EditorGroupModel`, feature metadata, or feature-layer coordinators as resolver parameters.
18. Resolver registration uses explicit `register()` entries keyed by `content_type`; unsupported types must render an explicit placeholder and must not silently fallback to markdown.
19. Future per-pane `View Mode` expansion may append to the same line, but it must not redefine `content_type` semantics or reopen shell ownership.

## Current Interpretation

- `DI-1` now supplies the first stable shell-detail layer for this ruling: per-pane group models, per-atom edit buffers, coordinator-as-mediator boundaries, and `lib/core/editor/` landing.
- `DI-4` now extends that same line with shared-buffer sync, advisory `EditOp`, manual-listener bridge rules, immediate notification semantics, and explicit load/error guards.
- `DI-5` then confirms that cursor independence and local no-conflict behavior are direct consequences of the same shell / buffer model rather than new architectural decisions.
- `DI-10` now extends that same line with the resolver-shell layer: `EditorResolver` sits between shell state and feature chrome, panes consume only `EditBuffer`-driven inputs, registration stays explicit, and unknown carriers must render a visible placeholder instead of silently falling back.
- `DI-0` naming clarification stays inside this same line: the state-side artifact is `EditorGroupModel`, while the widget-side tab strip remains presentation-only.
- Later DI work may extend the shell implementation detail, but it should append to this line rather than fork it by default.
- Current architecture should read workbench shell ownership from this ruling first, then from later DI detail.

## Open Edges

- Later richer editor-mode and thin-client follow-up may append finer-grained shell detail without changing ownership.
- Cross-pane undo/redo semantics remain a later explicit edge rather than a blocker for the current ruling.

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Later detail sources: [`../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md`](../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md), [`../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md`](../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md), [`../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md`](../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md), [`../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`](../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md)
- Journey record: [`../adr/ADR-0002-editor-shell-ownership.md`](../adr/ADR-0002-editor-shell-ownership.md)
