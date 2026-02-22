# PR-0254A-architecture-baseline-contract

- Proposed title: `docs(architecture): freeze baseline analysis contract for v0.2.5`
- Status: Completed

## Goal

Freeze one reproducible analysis contract for architecture dependency graphs and
size hotspots before refactor work starts.

## Scope

In scope:

- define mandatory tools and output scope for frontend/backend
- define output folder conventions and artifact naming
- define replay commands required by closure

Out of scope:

- code or script implementation
- deep interpretation/risk grading/recommendation writing
- refactor changes
- closure summary generation

## Baseline Contract

1. Frontend dependency graph:
   - tool: `lakos`
   - target: Flutter app module dependency graph
2. Frontend size baseline:
   - source: existing `flutter build windows --analyze-size` output
   - note: no forced macOS build in this track
3. Backend dependency graph:
   - tool: `cargo-modules`
   - target: `lazynote_core`, `lazynote_ffi` module/crate graph
4. Backend size hotspot:
   - tool: `cargo-bloat`
   - target: top crates/functions by release-size contribution

## Planned Doc Changes

- [edit] `docs/releases/v0.2.5/README.md`
- [add] `docs/releases/v0.2.5/prs/PR-0254A-architecture-baseline-contract.md`
- [edit] `docs/product/roadmap.md` (if wording sync is needed)

## Acceptance Criteria

- [x] Analysis toolchain and scope are frozen with no ambiguity.
- [x] Artifact naming/output location is documented and stable.
- [x] `PR-0254B` has a deterministic implementation checklist.
- [x] `PR-0254C` has a deterministic artifact-index closure checklist.
