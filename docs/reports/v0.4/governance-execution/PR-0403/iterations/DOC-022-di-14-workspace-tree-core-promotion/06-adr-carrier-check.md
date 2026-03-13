# DOC-022 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for the `DOC-022` classification result.

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- published ADR [`../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md`](../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md)
- published ruling [`../../../../../../architecture/rulings/S9-cross-feature-infrastructure-placement.md`](../../../../../../architecture/rulings/S9-cross-feature-infrastructure-placement.md)

## Carrier Decision

| Theme ID / Outcome | Carrier Decision | Rationale |
|------|------|------|
| `TH-011` | `append_existing_adr` | `ADR-0009` already carries the stable placement why-question. `DI-14` only appends workspace-tree core-promotion, shared query-surface, and feature-local UI-boundary detail under that same line. |
| `workspace_tree_di17_migration_boundary_bundle` | `park_later` | `DI-14` explicitly migrates these questions to `DI-17`; replay must preserve that boundary rather than publish a premature local answer. |
| `pending_internal_trace` | `context_only` | Conceptual-parent framing, scope controls, and current-vs-target gap wording remain execution-only trace in this run. |

## Result

`DOC-022` passes carrier check as:

1. zero new ADR files;
2. one append-only update to an existing published ADR;
3. one explicit migration-boundary bundle carried forward;
4. no redirect and no new theme row.
