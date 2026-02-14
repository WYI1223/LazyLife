# v0.3 Release Plan

## Positioning

v0.3 delivers the IDE-grade workspace interaction model on top of v0.2 foundations.

Theme:

- recursive split architecture
- drag-to-split interaction
- cross-pane editor coherence
- performance guardrails for long markdown documents
- workspace launcher user flow on top of links index
- first-party pluginization on extension kernel (entry/provider/ui slots)

## User-Facing Outcomes

At the end of v0.3, users should be able to:

1. Split workspace recursively (not just limited preset split).
2. Drag tabs to edge zones to create new splits naturally.
3. Open the same note in different panes with coherent live content state.
4. Use preview/pinned tab semantics similar to IDE workflows.
5. Launch a workspace link set safely (`Open All` with confirmation/limits).
6. Use local task-calendar projection without requiring external provider login.
7. Connect Google Calendar via provider plugin flow (optional integration).

## Architecture Outcomes

At the end of v0.3, engineering should have:

1. Recursive layout tree model (`Internal` + `Leaf` nodes).
2. Geometry and safety rules (`>= 200px`) enforced in layout engine.
3. Buffer synchronization model designed for multi-pane editing.
4. Rendering strategy for long markdown with measurable performance targets.
5. Workspace launcher orchestration tied to links index and active pane rules.
6. Local task-calendar projection rules as core capability.
7. Google Calendar provider implemented against provider SPI, not app-internal coupling.
8. First-party command/parser features migrated to registry-based plugin form.

## Scope

In scope:

- recursive workspace layout tree (`PR-0301`)
- drag-to-split edge zone interactions (`PR-0302`)
- cross-pane live buffer synchronization (`PR-0303`)
- preview/pinned tab model (`PR-0304`)
- markdown segment rendering + perf gate (`PR-0305`)
- reliability hardening and closure (`PR-0306`)
- workspace launcher experience (`PR-0307`)
- local task-calendar projection (`PR-0308`)
- Google Calendar provider plugin (`PR-0309`)
- first-party command/parser pluginization (`PR-0310`)

Out of scope:

- collaborative multi-user editing
- CRDT merge runtime
- provider-sync conflict UI redesign

## Dependencies from v0.2

Required baseline:

- tree schema + tree FFI
- workspace provider state hoisting
- explorer recursive lazy rendering
- split layout v1
- extension kernel + provider SPI + capability model

## Execution Order

1. `PR-0301-recursive-layout-tree`
2. `PR-0302-drag-to-split-edge-zones`
3. `PR-0303-cross-pane-live-buffer-sync`
4. `PR-0304-tab-preview-pinned-model`
5. `PR-0305-markdown-segment-rendering-performance-gate`
6. `PR-0306-recursive-workspace-reliability-hardening`
7. `PR-0307-workspace-launcher-experience`
8. `PR-0308-local-task-calendar-projection`
9. `PR-0309-google-calendar-provider-plugin`
10. `PR-0310-first-party-command-parser-plugins`

## Quality Gates

- `cargo test --all`
- `flutter analyze`
- `flutter test`
- profile-mode performance check for long markdown in multi-pane view

## Acceptance Criteria (Release-Level)

v0.3 is complete when:

1. Recursive split and drag-to-split are stable and constraint-safe.
2. Multi-pane same-note editing remains coherent and recoverable.
3. Tab preview/pinned behavior is deterministic and test-covered.
4. Long markdown rendering meets agreed baseline performance target.
5. Workspace launcher flow is safe, constrained, and test-covered.
6. Local task-calendar projection is stable and independent from external provider availability.
7. Google Calendar integration runs through provider SPI with predictable auth/sync behavior.

## PR Specs

- `docs/releases/v0.3/prs/PR-0301-recursive-layout-tree.md`
- `docs/releases/v0.3/prs/PR-0302-drag-to-split-edge-zones.md`
- `docs/releases/v0.3/prs/PR-0303-cross-pane-live-buffer-sync.md`
- `docs/releases/v0.3/prs/PR-0304-tab-preview-pinned-model.md`
- `docs/releases/v0.3/prs/PR-0305-markdown-segment-rendering-performance-gate.md`
- `docs/releases/v0.3/prs/PR-0306-recursive-workspace-reliability-hardening.md`
- `docs/releases/v0.3/prs/PR-0307-workspace-launcher-experience.md`
- `docs/releases/v0.3/prs/PR-0308-local-task-calendar-projection.md`
- `docs/releases/v0.3/prs/PR-0309-google-calendar-provider-plugin.md`
- `docs/releases/v0.3/prs/PR-0310-first-party-command-parser-plugins.md`
