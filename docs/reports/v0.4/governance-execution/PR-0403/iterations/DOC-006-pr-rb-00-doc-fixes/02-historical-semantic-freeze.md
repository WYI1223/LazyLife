# DOC-006 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze what `PR-RB-00` itself established before later governance revisions are allowed to reinterpret it.

This stage does not:

1. treat later `DI-19` / `DI-20` / `DI-21` rules as if they already existed inside `PR-RB-00`;
2. classify publishable theme rows or choose current carriers;
3. silently normalize `ADR -> Ruling` migration language into the later five-layer governance model.

## Trigger and Inputs

- `DOC-006 / PR-RB-00-doc-fixes.md`
- `PR-0401` DN baseline: `DN-001`, `DN-002`, `DN-126-DN-132`
- `DOC-005 / 09` as the already-closed historical predecessor

## Historical Freeze Result

| Line | Source DN IDs | Historical Freeze |
|------|---------------|-------------------|
| Governance carrier transition | `DN-001` | `PR-RB-00` explicitly deprecated the old ADR system, folded its job into the Ruling system, and treated that migration as the correct v0.3 governance move at the time. |
| Ruling lifecycle status normalization | `DN-126` | `PR-RB-00` standardized ruling lifecycle headers around `Proposed`, `Accepted`, `Landed`, and `Deprecated`, and normalized the then-current S1-S9 vocabulary into that scheme. |
| Docs-link verification infrastructure | `DN-127` | `PR-RB-00` introduced the docs cross-reference linter extension to `architecture_check.dart`, including allowlist treatment for archived artifact links and warning-only handling for speculative PR-spec code paths. |
| Navigation and product-document refresh | `DN-128-DN-130` | `PR-RB-00` refreshed entrypoint, milestone, and roadmap surfaces so the documentation tree pointed to the rebaselined v0.3 reality instead of stale v0.1/v0.2-era release framing. |
| Historical retention and orphan disposition | `DN-131` | `PR-RB-00` made explicit keep / move / delete / rename decisions over orphaned documentation, turning ambiguous leftovers into deliberate provenance choices. |
| Lifecycle and process-template infrastructure | `DN-002`, `DN-132` | `PR-RB-00` established the first release-lifecycle and PR-spec template lineage that later governance work would either reuse, revise, or defer. |

## Gate Result

`DOC-006` is frozen as the earliest post-v0.2.5 governance-repair source, but not yet as a self-contained current-effectiveness source.

## References

- [`../../../../../../releases/v0.3/prs/PR-RB-00-doc-fixes.md`](../../../../../../releases/v0.3/prs/PR-RB-00-doc-fixes.md)
- [`../../../../../../reports/v0.4/governance-execution/PR-0401/dn-ledger.md`](../../../../../../reports/v0.4/governance-execution/PR-0401/dn-ledger.md)
