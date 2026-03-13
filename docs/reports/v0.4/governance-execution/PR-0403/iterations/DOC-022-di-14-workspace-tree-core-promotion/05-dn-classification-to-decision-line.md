# DOC-022 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-022` clause nodes without laundering `DI-17` handoff questions into fake local closure.

This stage must not:

1. create a workspace-tree-only theme row separate from `TH-011`;
2. republish the parked `DOC-020 / DI-12` single-root parent bundle as if `DI-14` closed it here;
3. treat `Q3-Q5` as unresolved leftovers that can be silently absorbed into the current placement line.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-022`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Conceptual-parent framing, explicit in-scope/out-of-scope boundary, and current-vs-target gap statement | `pending_internal_trace` | `DN-347`, `DN-348`, `DN-349`, `DN-354` | `context_only`. These clauses remain explicit replay framing and motivation control, but they do not become carriers in this run. |
| Workspace-tree promotion into `lib/core/workspace/`, shared capability set, feature-local UI boundary, caller-scoped subtree semantics, dual query primitive, supporting queries, interface-completeness rule, and Rust-side subtree-collection requirement | `TH-011` | `DN-350`, `DN-351`, `DN-352`, `DN-353`, `DN-355`, `DN-356`, `DN-357`, `DN-358`, `DN-359` | Append to the existing placement line. `DI-14` closes workspace-tree core-promotion and shared query-surface detail under the already-published cross-feature infrastructure why-question; it does not justify a separate workspace-only row. |
| Change notification and cache consistency, shared tree-UI layering, and system-node-resolution ownership | `workspace_tree_di17_migration_boundary_bundle` | `DN-360`, `DN-361`, `DN-362` | `park_later`. These clauses are explicit migration boundaries to `DI-17`, not publishable local closure in `DOC-022`. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-022 / DI-14-workspace-tree-core-promotion.md` |
| Covered Themes | `TH-011` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `sync_mainline`, `preserve_context_trace`, `carry_forward_migration_boundary` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-025 / DI-17`, later no-move cleanup work, and `PR-0404` audit |
| Out of Scope | creating a new workspace-tree theme, publishing `DI-17` handoff questions locally, or turning the parked `DOC-020` topology parent bundle into current rule text |
| Must Preserve | workspace-tree core promotion as a placement-line append, subtree-rooted shared query semantics, feature-local UI responsibilities, and the explicit `DI-17` migration boundary |
| Allowed Simplifications | conceptual-parent framing and current-vs-target gap language may remain summarized in execution artifacts rather than copied verbatim into current ruling text |
| Escalation Required If Violated | any attempt to publish `Q3-Q5` locally or to split `TH-011` into a second workspace-only carrier |
| Accepted Debt | `OI-029` |
| Output Docs | `ADR-0009`, `S9`, `workspace-tree-service.md`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `open-items.md`, queue and execution logs |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-022` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-011` | `append_existing_adr + update_existing_ruling + sync_mainline` | `existing_published_row` | `active` | `ADR-0009`, `S9`, `workspace-tree-service.md`, working-copy + mainline `topic-map.md`, execution logs | workspace-tree core promotion stays inside the existing cross-feature placement line; `Q3-Q5` stay outside the row as explicit `DI-17` carry-forward material | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-022` yields one append-and-refine update against `TH-011`, one explicit migration-boundary bundle, and zero new theme rows.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
