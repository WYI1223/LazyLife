# v0.2 Closure Kit

This document defines the final release-closure package for v0.2.

## Package 1: Gate Replay

Goal: prove the release branch is green with reproducible commands and evidence.

Run from repository root:

```powershell
cd crates
cargo fmt --all -- --check
cargo clippy --all -- -D warnings
cargo test --all

cd ..\apps\lazynote_flutter
flutter analyze
flutter test
```

Minimum manual smoke (Windows):

1. Explorer create/rename/move/delete basic flow.
2. Split open/switch/unsplit flow.
3. Autosave + tab/pane switch coherence.
4. Diagnostics viewer refresh + copy behavior.

Evidence record template:

- Date (UTC):
- Branch:
- Commit SHA:
- Operator:
- Rust gate result:
- Flutter gate result:
- Manual smoke result:

Store evidence in:

- `docs/releases/v0.2/prs/PR-0208-workspace-hardening-doc-closure.md`

## Package 2: Closure Declaration

Goal: freeze release scope and deferred mapping in docs before tagging.

Checklist:

1. All in-scope v0.2 PR files are `Status: Completed`.
2. Deferred items are explicit and mapped to v0.3 PRs.
3. Release-level acceptance criteria remain consistent with shipped behavior.

Quick checks:

```powershell
rg -n "^- Status:" docs/releases/v0.2/prs
rg -n "Deferred to v0.3" docs/releases/v0.2/README.md docs/releases/v0.2/prs
```

Primary docs to sync:

- `docs/releases/v0.2/README.md`
- `docs/product/roadmap.md`
- `docs/releases/v0.2/prs/PR-0208-workspace-hardening-doc-closure.md`

## Package 3: Tag and Release

Goal: publish a traceable release anchor after Package 1 and 2 are complete.

Suggested commands:

```powershell
git tag -a v0.2.0 -m "v0.2.0: workspace foundation closure"
git push origin v0.2.0
```

Release note should include:

1. Scope summary of v0.2 completed lanes.
2. Deferred mapping:
   - `PR-0201` -> `PR-0311`
   - `PR-0212` -> `PR-0306A`
3. Link to replay evidence in `PR-0208`.

## Execution Order

1. Complete Package 1 and record evidence.
2. Complete Package 2 and verify docs status consistency.
3. Execute Package 3 on a green main commit.

## Suggested Commit Split

1. `docs(v0.2): add closure kit and release-status markers`
2. `docs(v0.2): attach final gate replay evidence snapshot`
3. `chore(release): create and push v0.2.0 tag` (tag-only step, no file delta)
