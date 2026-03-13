# S9: Cross-Feature Infrastructure Placement

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S9-cross-feature-infrastructure-placement.md`](../rulings-legacy/S9-cross-feature-infrastructure-placement.md) |
| Current ADR | [`../adr/ADR-0009-cross-feature-infrastructure-placement.md`](../adr/ADR-0009-cross-feature-infrastructure-placement.md) |

## Decision

Cross-feature editor and workspace infrastructure belongs under `lib/core/` rather than under any `lib/features/<name>/` directory.

## Normative Rules

1. A stateful or service-oriented module that is consumed by two or more features must not live under a feature-local directory.
2. `lib/core/` is the home for cross-feature platform, state, and service infrastructure; `lib/shared/` remains reserved for shared UI primitives.
3. Cross-feature infrastructure under `lib/core/` should be organized by domain, such as `editor/`, `workspace/`, `reminders/`, and `settings/`.
4. `EditorShellService` and its companion shell-state artifacts belong under `lib/core/editor/`.
5. `WorkspaceTreeService` and shared workspace-tree state or service infrastructure belong under `lib/core/workspace/`.
6. Shared workspace-tree access should be expressed as subtree-rooted core service primitives rather than feature-local tree walks; one-level browsing and flattened subtree collection belong to the shared service layer.
7. Supporting queries such as single-node lookup, ancestor-path lookup, and atom-ref reverse lookup belong with the same core workspace service when they are consumed by multiple features.
8. Feature-local expand or collapse state, filtering, grouping, and concrete tree or list rendering remain feature-local UI responsibilities even after workspace-tree promotion.
9. Flattened subtree collection must be backed by Rust-side query support rather than recursive Flutter-side composition when current semantics require one coherent subtree result across features.
10. Moving a module into `lib/core/` is a semantic boundary decision, not just a cosmetic file move; the resulting placement must keep Rule E compliance explicit and predictable.
11. `EditorResolver`, `editor_resolver.dart`, and pane implementations such as `MarkdownEditorPane` belong under `lib/core/editor/` as cross-feature editor infrastructure.
12. Feature chrome such as loading, error, breadcrumb, save-state, and metadata presentation remains feature-local; moving resolver infrastructure into `lib/core/` does not move those chrome concerns out of feature controllers.

## Current Interpretation

- This line is distinct from shell ownership itself: `S2` answers who owns tab/draft/save state, while `S9` answers where cross-feature editor/workspace infrastructure must live.
- Current architecture should treat `lib/core/` placement as the default landing zone for shared non-UI infrastructure and should treat feature-local placement of the same infrastructure as a Rule E risk.
- `lib/shared/` is not a fallback for service/state modules; it remains the UI-primitive layer.
- `DI-10` now closes the editor-resolver placement detail that the rebuilt line had left open: resolver infrastructure lives in `lib/core/editor/`, while feature chrome stays with notes/tasks/other feature controllers.
- `DI-14` now closes the workspace-tree promotion side of the same line: shared workspace-tree state and service infrastructure belong in `lib/core/workspace/`, shared query primitives live in that layer, and feature-local tree UI state stays outside the shared carrier.

## Open Edges

- Later `DOC-025 / DI-17` may append the change-notification/cache-consistency, shared tree-UI, and system-node-resolution ownership detail that `DI-14` intentionally migrated out of local closure.
- Later cleanup work may append residual no-move or transitional-placement evidence without reopening the stable why-question.

## Traceability

- Historical source: [`../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md`](../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md)
- Later detail sources: [`../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`](../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md), [`../../reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md`](../../reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md)
- Journey record: [`../adr/ADR-0009-cross-feature-infrastructure-placement.md`](../adr/ADR-0009-cross-feature-infrastructure-placement.md)
