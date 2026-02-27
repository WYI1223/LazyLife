# PR-0251-semantics-freeze-and-v0.3-rebaseline-docs

- Proposed title: `docs(notes/workspace): freeze semantics and re-baseline v0.3 prerequisites`
- Status: **Completed (Superseded/Closed)** — scope absorbed by `PR-0256-semantic-rulings-and-doc-alignment.md` (S1-S8 rulings cover all 5 original areas and expand to 8).

## Closure Decision

- Closure date: 2026-02-27
- Closure mode: superseded without direct execution in this PR
- Canonical replacement: `docs/releases/v0.2.5/prs/PR-0256-semantic-rulings-and-doc-alignment.md`
- Scope handoff:
  - semantic rulings moved to `08b-semantic-decisions.md` and downstream 08c/08d planning
  - documentation alignment executed under PR-0256 task model
  - release plan marks PR-0251 as superseded in `docs/releases/v0.2.5/README.md`

## Goal

Freeze a single authoritative semantic contract before large Dart refactor work.
Eliminate behavior ambiguity that currently leaks into v0.3 planning.

## Scope

In scope:

- semantic ownership/boundary freeze for Notes/Workspace/Explorer/Tab
- update contract docs and release plans to one consistent definition
- update v0.3 dependency wording to match frozen semantics

Out of scope:

- runtime code changes
- schema/data migration changes

## Required Clarification Areas

1. Explorer vs Tab semantic ownership (open intent, preview/pin, activation).
2. `note_ref` naming/title projection boundary.
3. Folder delete modes and "Uncategorized" projection behavior.
4. Move/order policy (parent-change vs reorder capabilities).
5. Logging/release packaging contract expectations for v0.2.x.

## Planned Doc Changes

- [edit] `docs/api/ffi-contracts.md` (if wording boundary updates are needed)
- [edit] `docs/api/workspace-tree-contract.md`
- [edit] `docs/architecture/data-model.md`
- [edit] `docs/releases/v0.2.5/README.md`
- [edit] `docs/releases/v0.3/README.md`
- [edit] `docs/product/roadmap.md`

## Acceptance Criteria (Closure)

- [x] PR is explicitly marked as superseded/closed with a canonical replacement PR.
- [x] Scope handoff is recorded and points to the 08b/08c/08d + PR-0256 execution path.
- [x] v0.2.5 release plan marks PR-0251 as superseded.
