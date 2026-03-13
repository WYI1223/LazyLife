# ADR-0009: Cross-Feature Infrastructure Placement

## Reconstruction Notice

> This document is a retrospective reconstruction ADR, published on 2026-03-11 from a known source corpus.
> It retells this decision line from a future perspective and is not a contemporaneous original record.
> The current normative interpretation follows [`../rulings/S9-cross-feature-infrastructure-placement.md`](../rulings/S9-cross-feature-infrastructure-placement.md).

## Decision Line

- Document Class: `Retrospective Reconstruction ADR`
- Narrative Perspective: future-perspective reconstruction
- Decision Line: Why should cross-feature editor and workspace infrastructure live under `lib/core/` rather than feature-local directories, so that Rule E stays satisfied and shared foundation boundaries remain predictable?
- Coverage Scope: Covers `DI-1 / Q4.3, Q5`, `DI-10 / Q4 + resolver placement boundary`, `DI-14 / Q0-Q2` workspace-tree core-promotion detail, the historical legacy `S9` snapshot, and the rebuilt current-effective ruling published in `PR-0403`. Stops before the `DI-17` migration-boundary follow-up and later cleanup DIs.
- Current Normative Source: [`../rulings/S9-cross-feature-infrastructure-placement.md`](../rulings/S9-cross-feature-infrastructure-placement.md)
- Source Corpus Summary: `DI-1` supplied the first replay-ready placement decision for editor and workspace infrastructure, `DI-10` later added concrete editor-resolver landing and feature-chrome boundary detail, `DI-14` then closed the workspace-tree core-promotion and shared query-surface side of the same placement line while explicitly migrating later follow-up to `DI-17`, and the legacy `S9` snapshot preserved the earlier ruling-shaped carrier that this run rebuilds into current ADR/ruling assets.

## Source Corpus

- Trigger Source: no standalone upstream trigger document; `DI-1` contains the local Rule E pressure, extraction motivation, and placement problem framing directly
- Decision Source: [`../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md`](../../reports/v0.3/design-discussions/DI-1-editor-shell-service.md)
- Execution / Closure Sources: [`../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`](../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md), [`../../reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md`](../../reports/v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md)
- Historical Normative Snapshot: [`../rulings-legacy/S9-cross-feature-infrastructure-placement.md`](../rulings-legacy/S9-cross-feature-infrastructure-placement.md)

## Corpus Coverage Declaration

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|
| Trigger Source | embedded in `DOC-009 / DI-1` | `embedded` | `DI-1` carries its own local Rule E pressure and extraction motivation |
| Decision Source | `DOC-009 / Q4.3, Q5` | `present` | Placement decision is fully replayed from the resolved DI |
| Normative Source | legacy S9 + rebuilt S9 | `present` | Rebuilt ruling is now authoritative |
| Execution / Closure Source | `DOC-018 / DI-10`, `DOC-022 / DI-14` | `present` | `DI-10` appended editor-resolver landing and feature-chrome boundary evidence; `DI-14` then appended workspace-tree core-promotion, shared query-surface, and feature-local UI-boundary detail without reopening the stable why-question |
| Superseded / Redirected Source | none | `not_applicable` | This line is rebuilt, not redirected from another active theme |

## Journey Timeline / Phases

1. `DI-1` identified that editor-shell and workspace infrastructure were being extracted from notes-local code while Rule E still required a stable cross-feature placement rule.
2. `DI-1 / Q4.3` resolved that `WorkspaceTreeManager` should become an independent cross-feature service rather than remain buried under notes.
3. `DI-1 / Q5` resolved that `EditorShellService` belongs under `lib/core/editor/`, not under any feature directory and not under `lib/shared/`.
4. A historical `S9` ruling snapshot preserved that placement line during the pre-replay governance era.
5. `PR-0403` rebuilt the line into current ADR and ruling carriers without collapsing it into shell-ownership semantics.
6. `DI-14` later resolved that shared workspace-tree state and service infrastructure belongs under `lib/core/workspace/`, defined subtree-rooted shared query primitives and feature-local UI boundaries, and explicitly migrated change notification, shared tree UI, and system-node-resolution follow-up to `DI-17`.

## Current State

Current architecture treats cross-feature editor and workspace infrastructure as `lib/core/` modules organized by domain rather than as feature-local implementation details. The authoritative interpretation follows [`../rulings/S9-cross-feature-infrastructure-placement.md`](../rulings/S9-cross-feature-infrastructure-placement.md), which keeps `lib/shared/` reserved for UI primitives and keeps Rule E compliance explicit at the placement layer. `DOC-018 / DI-10` added the concrete resolver placement refinement that this line had left open: `editor_resolver.dart` and `MarkdownEditorPane` land under `lib/core/editor/`, while loading, error, metadata, and similar chrome remain feature-local rather than sliding into core infrastructure. `DOC-022 / DI-14` then extends the same line to workspace-tree promotion: shared workspace-tree state and service infrastructure belongs under `lib/core/workspace/`, the shared service surface is subtree-rooted rather than feature-local, flattened subtree collection requires Rust-side support rather than recursive Flutter composition, and feature-local expand/collapse state, filtering, grouping, and rendering remain outside the shared carrier.

## Open Edges

- `DOC-025 / DI-17` still owns the follow-up questions that `DI-14` intentionally migrated: change-notification/cache-consistency design, shared tree-UI layering, and system-node-resolution ownership.
- Later `DI-18` cleanup work may append no-move and residual-placement cleanup evidence without reopening the stable why-question.

## Revision Record

- 2026-03-11: Initial retrospective reconstruction ADR published in `PR-0403` from `DOC-009 / DI-1` and the historical S9 snapshot.
- 2026-03-12: `DOC-018 / DI-10` replay appended editor-resolver landing, `MarkdownEditorPane` extraction boundary, and the rule that feature chrome remains feature-local rather than moving into core infrastructure.
- 2026-03-12: `DOC-022 / DI-14` replay appended workspace-tree core-promotion, subtree-rooted shared query semantics, feature-local UI-boundary detail, and the explicit `DI-17` migration boundary for later change-notification / tree-UI / system-node-resolution follow-up.
