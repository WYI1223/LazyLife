# PR-0251-semantics-freeze-and-v0.3-rebaseline-docs

- Proposed title: `docs(notes/workspace): freeze semantics and re-baseline v0.3 prerequisites`
- Status: Planned

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

## Acceptance Criteria

- [ ] No known semantic ambiguity remains in the listed clarification areas.
- [ ] v0.2.5 and v0.3 docs use consistent terms and boundaries.
- [ ] Refactor PR (`PR-0252`) has explicit "must not change behavior" guardrails.
