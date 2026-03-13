# DOC-018 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for the `DOC-018` classification result.

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- published ADRs [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md) and [`../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md`](../../../../../../architecture/adr/ADR-0009-cross-feature-infrastructure-placement.md)
- published rulings [`../../../../../../architecture/rulings/S2-tab-draft-save-ownership.md`](../../../../../../architecture/rulings/S2-tab-draft-save-ownership.md) and [`../../../../../../architecture/rulings/S9-cross-feature-infrastructure-placement.md`](../../../../../../architecture/rulings/S9-cross-feature-infrastructure-placement.md)

## Carrier Decision

| Theme ID / Outcome | Carrier Decision | Rationale |
|------|------|------|
| `TH-008` | `append_existing_adr` | `ADR-0002` already carries the stable shell-ownership why-question. `DI-10` only adds the resolver-shell layer, pane interface, registration, and fallback detail explicitly left open by the published shell line. |
| `TH-011` | `append_existing_adr` | `ADR-0009` already carries the stable placement why-question. `DI-10` only adds concrete editor-resolver placement and feature-chrome boundary evidence under the same line. |
| `pending_view_mode_edge` | `park_later` | `DI-10` preserves a future edge rather than a publishable current line. |
| `pending_internal_trace` | `context_only` | Intake framing, inherited S1 context, v0.3 scope, and the explicit DI-4 handoff remain execution-only trace in this run. |

## Result

`DOC-018` passes carrier check as:

1. zero new ADR files;
2. two append-only updates to existing published ADRs;
3. one explicit future edge carried forward;
4. no redirect and no new theme row.
