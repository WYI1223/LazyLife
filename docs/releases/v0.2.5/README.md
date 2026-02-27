# v0.2.5 Release Plan

## Positioning

v0.2.5 is a **technical-debt and semantic-alignment bridge** between v0.2 MVP
preview and v0.3 feature expansion.

Theme:

- semantic freeze for currently drifting behavior contracts
- Dart "god-object" decomposition and dependency decoupling
- code-generated architecture/size baseline before refactor
- release-process hardening and closure replay

This release is intended to reduce v0.3 planning risk, not to add major
user-facing features.

## Release Status

- Status: **In Progress**
- Baseline sub-lane (`PR-0254A/B/C`): **Completed**
- Frontend review sub-lane (`PR-0255A/B/C`): **Completed**
- Modular refactor (`PR-0252`): **Completed** (22 tasks, 333 pass / 0 fail)
- Reassessment series (`08a-08d`): **Completed** (plan finalized)
- Current active item: `PR-0258-notes-workspace-structural-decoupling`

## Lane Strategy

v0.2.5 uses a multi-stage lane:

1. ~~contract/docs freeze (`PR-0251`)~~ — superseded by `PR-0256`
2. behavior-parity refactor (`PR-0252`) — **completed**
3. reassessment series (`08a-08d`) — **completed** (plan finalized)
4. semantic rulings + docs (`PR-0256`) — replaces `PR-0251`
5. pane-aware NoteTabManager upgrade (`PR-0257`) — micro-PR
6. notes↔workspace structural decoupling (`PR-0258`) — HIGH risk
7. Rule E reduction + CI guardrails (`PR-0259`)
8. closure replay + v0.3 handoff (`PR-0253`)

Code PRs depend on the semantic foundation established by PR-0256.

v0.2.5 also uses an analysis sub-lane before large refactor slices:

1. baseline contract freeze (`PR-0254A`)
2. tooling pipeline implementation (`PR-0254B`)
3. baseline artifact closure (`PR-0254C`)

The baseline sub-lane only produces code-generated artifacts and an index.

v0.2.5 then uses a frontend review doc lane:

1. code health report (`PR-0255A`)
2. module split blueprint (`PR-0255B`)
3. phased refactor plan (`PR-0255C`)

`PR-0252` must start after `PR-0255C` is accepted.

## User-Facing Outcomes

At the end of v0.2.5, users should see:

1. No breaking behavior change in existing v0.2 MVP workflows.
2. Fewer instability regressions from workspace/explorer/tab interactions.
3. More predictable release quality through stronger closure replay.

## Engineering Outcomes

At the end of v0.2.5, engineering should have:

1. One frozen semantic contract set for Notes/Workspace interactions.
2. Key Dart god-objects decomposed into smaller modules with clear ownership.
3. Stable build/package workflow for Windows release artifacts.
4. Code-generated dependency and size baseline artifacts with replay index.
5. Frontend TL review reports for risk, boundaries, and phased execution.
6. v0.3 plan re-baselined against the new semantics and boundaries.

## Scope

In scope:

- semantic clarification + contract freeze
- architecture/size baseline generation and artifact indexing
- frontend TL review reports (docs-only)
- Dart decoupling/refactor (behavior-parity only)
- v0.2.5 closure replay and v0.3 handoff update

Out of scope:

- new product capabilities that expand v0.2 surface area
- new storage schema for feature expansion
- v0.3 feature implementation (recursive split/launcher/etc.)

## Execution Order

1. ~~`PR-0251-semantics-freeze-and-v0.3-rebaseline-docs`~~ (superseded by PR-0256)
2. `PR-0254A-architecture-baseline-contract`
3. `PR-0254B-architecture-baseline-tooling-implementation`
4. `PR-0254C-architecture-baseline-report-closure`
5. `PR-0255A-frontend-code-health-report`
6. `PR-0255B-frontend-module-split-blueprint`
7. `PR-0255C-frontend-phased-refactor-plan`
8. `PR-0252-dart-modular-refactor-and-decoupling`
9. `PR-0256-semantic-rulings-and-doc-alignment`
10. `PR-0257-pane-aware-tab-manager-upgrade`
11. `PR-0258-notes-workspace-structural-decoupling`
12. `PR-0259-rule-e-reduction-and-ci-guardrails`
13. `PR-0253-v0.2.5-closure-and-v0.3-handoff`

## Milestones

- `M1` (Docs Freeze): semantic ownership and contract boundaries locked.
- `M1.5` (Baseline): dependency graph + size baseline generated and indexed.
- `M1.6` (Review): frontend TL reports approved (risk, boundaries, phase plan).
- `M2` (Code Refactor): god-object decomposition with strict behavior parity.
- `M3` (Closure): replay, evidence capture, and v0.3 dependency handoff.

## Suggested Refactor Targets (Initial Set)

- `apps/lazynote_flutter/lib/features/notes/notes_controller.dart`
- `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- `apps/lazynote_flutter/lib/features/notes/notes_page.dart`
- `apps/lazynote_flutter/lib/core/rust_bridge.dart` (only seam cleanup, no API change)

## Quality Gates

- `cargo fmt --all -- --check`
- `cargo clippy --all -- -D warnings`
- `cargo test --all`
- `flutter analyze`
- `flutter test`
- `dart format --output=none --set-exit-if-changed .`
- architecture graph replay (`lakos`, `cargo-modules`)
- size hotspot replay (`flutter --analyze-size`, `cargo-bloat`)
- Windows release bundle build replay (`scripts/build_windows_release_bundle.ps1`)

## Acceptance Criteria (Release-Level)

v0.2.5 is complete when:

1. Semantics and boundaries are frozen in docs and no longer ambiguous.
2. Baseline dependency/size artifacts are generated with reproducible index.
3. Frontend TL three reports are completed and accepted.
4. Target god-objects are decomposed with behavior parity preserved.
5. CI gates are green with no known format/lint drift.
6. v0.3 roadmap/plan is synchronized with v0.2.5 outputs.

## PR Specs

- ~~`docs/releases/v0.2.5/prs/PR-0251-semantics-freeze-and-v0.3-rebaseline-docs.md`~~ (superseded by PR-0256)
- `docs/releases/v0.2.5/prs/PR-0254A-architecture-baseline-contract.md`
- `docs/releases/v0.2.5/prs/PR-0254B-architecture-baseline-tooling-implementation.md`
- `docs/releases/v0.2.5/prs/PR-0254C-architecture-baseline-report-closure.md`
- `docs/releases/v0.2.5/prs/PR-0255A-frontend-code-health-report.md`
- `docs/releases/v0.2.5/prs/PR-0255B-frontend-module-split-blueprint.md`
- `docs/releases/v0.2.5/prs/PR-0255C-frontend-phased-refactor-plan.md`
- `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
  - Execution sub-PRs: `docs/releases/v0.2.5/prs/PR-0252/` (22 task specs, P0-1 ~ P3-5)
- `docs/releases/v0.2.5/prs/PR-0256-semantic-rulings-and-doc-alignment.md`
- `docs/releases/v0.2.5/prs/PR-0257-pane-aware-tab-manager-upgrade.md`
- `docs/releases/v0.2.5/prs/PR-0258-notes-workspace-structural-decoupling.md`
- `docs/releases/v0.2.5/prs/PR-0259-rule-e-reduction-and-ci-guardrails.md`
- `docs/releases/v0.2.5/prs/PR-0253-v0.2.5-closure-and-v0.3-handoff.md`
