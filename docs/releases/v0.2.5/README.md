# v0.2.5 Release Plan

## Positioning

v0.2.5 is a **technical-debt and semantic-alignment bridge** between v0.2 MVP
preview and v0.3 feature expansion.

Theme:

- semantic freeze for currently drifting behavior contracts
- Dart "god-object" decomposition and dependency decoupling
- release-process hardening and closure replay

This release is intended to reduce v0.3 planning risk, not to add major
user-facing features.

## Lane Strategy

v0.2.5 uses a strict three-stage lane:

1. contract/docs freeze (`PR-0251`)
2. behavior-parity refactor (`PR-0252`)
3. closure replay + v0.3 handoff (`PR-0253`)

No code refactor should start before the contract freeze is accepted.

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
4. v0.3 plan re-baselined against the new semantics and boundaries.

## Scope

In scope:

- semantic clarification + contract freeze
- Dart decoupling/refactor (behavior-parity only)
- v0.2.5 closure replay and v0.3 handoff update

Out of scope:

- new product capabilities that expand v0.2 surface area
- new storage schema for feature expansion
- v0.3 feature implementation (recursive split/launcher/etc.)

## Execution Order

1. `PR-0251-semantics-freeze-and-v0.3-rebaseline-docs`
2. `PR-0252-dart-modular-refactor-and-decoupling`
3. `PR-0253-v0.2.5-closure-and-v0.3-handoff`

## Milestones

- `M1` (Docs Freeze): semantic ownership and contract boundaries locked.
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
- Windows release bundle build replay (`scripts/build_windows_release_bundle.ps1`)

## Acceptance Criteria (Release-Level)

v0.2.5 is complete when:

1. Semantics and boundaries are frozen in docs and no longer ambiguous.
2. Target god-objects are decomposed with behavior parity preserved.
3. CI gates are green with no known format/lint drift.
4. v0.3 roadmap/plan is synchronized with v0.2.5 outputs.

## PR Specs

- `docs/releases/v0.2.5/prs/PR-0251-semantics-freeze-and-v0.3-rebaseline-docs.md`
- `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- `docs/releases/v0.2.5/prs/PR-0253-v0.2.5-closure-and-v0.3-handoff.md`
