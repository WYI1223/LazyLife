# v0.2.5 Architecture Baseline Index

## Scope

This index records generated baseline artifacts only.
It does not include risk interpretation or refactor recommendations.

## Replay Command

Run from repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/analysis/run_architecture_baseline.ps1 -SkipBloat
```

## Replay Snapshot

- Last replay summary: `docs/reports/v0.2.5/architecture-baseline/artifacts/RUN_SUMMARY.md`
- Frontend summary: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/run-summary.json`
- Backend summary: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/run-summary.json`

## Frontend Artifacts

- Graph source: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.dot`
- Graph render: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.svg`
- Graph stdout: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.stdout.txt`
- Graph stderr: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.stderr.txt`
- Size snapshot: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/size/snapshot.windows-x64.json`
- Size trace: `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/size/trace.windows-x64.json`

## Backend Artifacts

- Core structure: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_core-structure.stdout.txt`
- Core dependencies DOT: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_core-dependencies.dot`
- Core dependencies SVG: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_core-dependencies.svg`
- FFI structure: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_ffi-structure.stdout.txt`
- FFI dependencies DOT: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_ffi-dependencies.dot`
- FFI dependencies SVG: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_ffi-dependencies.svg`

## Tool Probes

- `cargo-modules` probe: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/tool-probes/modules-help.stdout.txt`
- `cargo-bloat` probe: `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/tool-probes/bloat-help.stdout.txt`

## Downstream Consumers

- `PR-0255A`: `docs/releases/v0.2.5/prs/PR-0255A-frontend-code-health-report.md`
- `PR-0255B`: `docs/releases/v0.2.5/prs/PR-0255B-frontend-module-split-blueprint.md`
- `PR-0255C`: `docs/releases/v0.2.5/prs/PR-0255C-frontend-phased-refactor-plan.md`
