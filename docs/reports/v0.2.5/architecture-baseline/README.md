# Architecture Baseline Artifacts (v0.2.5)

This folder stores machine-generated architecture baseline outputs.
It is intentionally split into:

1. Raw artifacts (DOT/JSON/TXT) for reproducibility.
2. Rendered visuals (SVG) for direct review.

No risk interpretation is included here. Interpretation belongs to follow-up review PRs.

## Quick Entry Points

Open these files first:

1. `docs/reports/v0.2.5/architecture-baseline/artifacts/RUN_SUMMARY.md`
2. `docs/reports/v0.2.5/architecture-baseline/BASELINE_INDEX.md`
3. `docs/reports/v0.2.5/architecture-baseline/artifacts/frontend/lakos/lakos.svg`
4. `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_core-dependencies.svg`
5. `docs/reports/v0.2.5/architecture-baseline/artifacts/backend/cargo-modules/lazynote_ffi-dependencies.svg`

## Artifact Layout

- `artifacts/frontend/lakos/`
  - `lakos.dot`: frontend dependency graph source
  - `lakos.svg`: rendered dependency graph
  - `lakos.stdout.txt`, `lakos.stderr.txt`: command logs
- `artifacts/frontend/size/`
  - `snapshot.windows-x64.json`, `trace.windows-x64.json`: copied Flutter analyze-size outputs
- `artifacts/backend/cargo-modules/`
  - `<pkg>-structure.stdout.txt`: module tree
  - `<pkg>-dependencies.dot`: dependency graph source
  - `<pkg>-dependencies.svg`: rendered dependency graph
- `artifacts/backend/cargo-bloat/`
  - top-level size outputs when bloat is enabled

## Regenerate

From repo root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/analysis/run_architecture_baseline.ps1 -SkipBloat
```

To include bloat outputs:

```powershell
powershell -ExecutionPolicy Bypass -File tools/analysis/run_architecture_baseline.ps1
```

## How To Present In PR / Release

1. Keep `RUN_SUMMARY.md` as the primary status snapshot.
2. Attach SVGs directly in PR description for visual review:
   - frontend `lakos.svg`
   - backend `lazynote_core-dependencies.svg`
   - backend `lazynote_ffi-dependencies.svg`
3. For size analysis, link the copied snapshot/trace JSON and, if needed, include one static screenshot from DevTools.
