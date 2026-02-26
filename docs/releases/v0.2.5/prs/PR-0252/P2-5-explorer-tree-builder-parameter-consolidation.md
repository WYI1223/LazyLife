# PR-0252 P2-5 - ExplorerTreeBuilder Parameter Consolidation (Optional)

| Field | Value |
|-------|-------|
| Parent PR | `PR-0252-dart-modular-refactor-and-decoupling` |
| Task ID | `P2-5` |
| Phase | Phase 2 - optional optimization track |
| Type | Structural optimization |
| Branch | `feat/pr-0252-p2-5-explorer-tree-builder-params` |
| PR Title | `refactor(frontend): PR-0252 P2-5 consolidate explorer tree builder params` |
| Estimated Effort | 0.5 person-day |
| Status | Merged (Optional, Non-blocking) |

## References

- Main tracking PR: `docs/releases/v0.2.5/prs/PR-0252-dart-modular-refactor-and-decoupling.md`
- Phase plan: `docs/reports/v0.2.5/frontend-review/03-phased-refactor-plan.md` Section 4.2
- P1-8 delivery: `docs/releases/v0.2.5/prs/PR-0252/P1-8-explorer-tree-builder.md`

## Goal

Reduce `ExplorerTreeBuilder` constructor complexity by replacing the current
28-parameter constructor with a config object input.

This is a behavior-preserving refactor. No user-visible behavior changes.

## Prerequisites

- `P1-8` is merged and stable.
- `P2-3` is merged, to avoid touching the same call chain during coordinator migration.

## Scope

In scope:

- Introduce a config object (for example, `ExplorerTreeBuilderConfig`).
- Migrate `note_explorer.dart` builder creation to config-based input.
- Preserve existing keys, callback order, rendering output, and interactions.

Out of scope:

- Tree rendering logic rewrite.
- Any product behavior change.
- Manager/coordinator behavior changes.

## Planned File Changes

- [edit] `apps/lazynote_flutter/lib/features/notes/explorer_tree_builder.dart`
- [edit] `apps/lazynote_flutter/lib/features/notes/explorer_tree_builder_types.dart` (if needed)
- [edit] `apps/lazynote_flutter/lib/features/notes/note_explorer.dart`
- [edit] `apps/lazynote_flutter/test/*explorer*` (only if constructor-related assertions require adaptation)

## Acceptance Criteria

- [x] `ExplorerTreeBuilder` no longer exposes a 28-parameter constructor.
- [x] Existing behavior is unchanged.
- [x] CI is green.
- [x] Test baseline remains `333 pass / 0 known-fail`.
- [x] D6 remains green (`dialogs/` has no `coordinator|manager` import).

## CI Gates

```bash
cd apps/lazynote_flutter
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
```

## Risk Notes

- Low risk: mostly constructor/call-site refactor.
- Main risk: incomplete parameter mapping during migration.
- Mitigation: keep current tests and run HF-06 regression.

## Rollback

Can be reverted independently. Does not block `P2-1..P2-4` critical path.

## Verification Snapshot (2026-02-26)

- Constructor surface migrated from 28 direct params to 5 grouped inputs (`context` + 4 config objects).
- `flutter analyze` passed with zero warnings.
- `flutter test` passed with baseline preserved (`333 pass / 0 fail`).
- `dialogs/` directory was not touched in this task.
