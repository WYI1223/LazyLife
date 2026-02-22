# PR-0254B-architecture-baseline-tooling-implementation

- Proposed title: `build(analysis): implement reproducible architecture baseline tooling`
- Status: Completed

## Goal

Implement scripts and directory layout that generate architecture dependency
graphs and size hotspot artifacts in one reproducible run.

## Scope

In scope:

- analysis script entrypoints for frontend/backend
- deterministic artifact output layout
- command wrappers for `lakos`, `cargo-modules`, `cargo-bloat`
- import/copy of frontend analyze-size artifacts into baseline report folder

Out of scope:

- report interpretation and risk conclusions
- recommendation or priority ranking output
- refactor implementation

## Tooling Prerequisites (Pinned Baseline)

Install commands (Windows PowerShell):

```powershell
cargo install cargo-modules --version 0.25.0 --locked
cargo install cargo-bloat --version 0.12.1 --locked
dart pub global activate lakos 2.0.6
```

PATH requirement:

- ensure `%LOCALAPPDATA%\Pub\Cache\bin` is in `PATH`
- if `lakos` is not resolved in shell, run fallback path directly:
  - `& "$env:LOCALAPPDATA\\Pub\\Cache\\bin\\lakos.bat" ...`

Version verification:

```powershell
cargo modules --version   # expected: cargo-modules 0.25.0
cargo bloat --version     # expected: 0.12.1
dart pub global list      # expected contains: lakos 2.0.6
```

## Planned Implementation

0. Lock tooling baseline:
   - pin versions and install commands in this PR doc
   - enforce PATH/fallback guidance for `lakos`
1. Add analysis output root:
   - `docs/reports/v0.2.5/architecture-baseline/`
2. Add tooling scripts:
   - `tools/analysis/run_frontend_baseline.ps1`
   - `tools/analysis/run_backend_baseline.ps1`
   - `tools/analysis/run_architecture_baseline.ps1`
3. Generate/store artifacts:
   - frontend dependency graph output (`lakos`)
   - frontend size snapshot references
   - backend module graph output (`cargo-modules`)
   - backend size top lists (`cargo-bloat`)
4. Add runbook:
   - commands and prerequisites in one short README

## Planned File Changes

- [add] `tools/analysis/run_frontend_baseline.ps1`
- [add] `tools/analysis/run_backend_baseline.ps1`
- [add] `tools/analysis/run_architecture_baseline.ps1`
- [add] `docs/reports/v0.2.5/architecture-baseline/README.md`
- [edit] `docs/releases/v0.2.5/README.md` (baseline lane progress)

## Verification

- run baseline scripts from clean workspace
- verify artifacts are generated under the expected directory
- verify script replay gives stable filenames and non-empty outputs

## Acceptance Criteria

- [x] One command can run the full baseline collection.
- [x] Expected artifacts are generated with deterministic paths.
- [x] Script prerequisites and failure modes are documented.
- [x] `PR-0254C` can index outputs without manual patchwork.
