# DOC-020 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-020` clause nodes without laundering an accepted-but-unlanded conceptual-parent bundle into a premature current line.

This stage must not:

1. create a fake published workspace-topology row from `DI-12`;
2. append the single-root parent bundle into `TH-003` or `TH-011` just because those lines are related;
3. drop the conceptual-parent and handoff nature of `DI-12` from replay visibility.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-020`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Conceptual-parent declaration plus explicit in-scope and out-of-scope boundaries | `pending_internal_trace` | `DN-319`, `DN-320`, `DN-321` | `context_only`. These clauses remain explicit replay framing and boundary control, but they do not become carriers in this run. |
| Single-root topology, fixed system-node anchors, structure-first routing, same-source Tasks/Calendar subtree semantics, strict visibility, compatibility-first FFI, one-shot migration, delete policy, execution lanes, and final output contract | `accepted_unlanded_workspace_topology_parent_bundle` | `DN-322`, `DN-323`, `DN-324`, `DN-325`, `DN-326`, `DN-327`, `DN-328`, `DN-329`, `DN-330`, `DN-331`, `DN-332`, `DN-333`, `DN-334`, `DN-335`, `DN-336`, `DN-337`, `DN-338`, `DN-339`, `DN-340` | `park_later_governance_bundle`. `DI-12` is semantically resolved, but replay keeps the bundle explicit instead of publishing it because the single-root answer set is not landed in current repo behavior and `DOC-023` later reworks the topology direction before current-carrier closure. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-020 / DI-12-workspace-tree-single-root.md` |
| Covered Themes | `none (no publish-complete theme row in this run)` |
| Theme Operations | `confirm_no_publish`, `park_later`, `record_open_items`, `no_mainline_sync` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-023`, `DOC-024`, `DOC-025`, `DOC-026`, and `PR-0404` audit |
| Out of Scope | creating a new current row, appending single-root semantics into existing published rows, publishing a current ADR/ruling from this source |
| Must Preserve | `DI-12` as conceptual-parent input, the resolved-but-unlanded single-root answer set, and the later replay dependency on this parent bundle |
| Allowed Simplifications | `Q1-Q12`, `E1-E6`, and the final output-contract block may stay one parked parent bundle rather than being split into fake mini-lines |
| Escalation Required If Violated | any attempt to publish the single-root parent bundle as current rule text before later topology replay closes |
| Accepted Debt | `OI-027` |
| Output Docs | iteration records, `dn-ledger-classification.md`, `open-items.md`, `doc-run-queue.md`, `PR-0403/README.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-020` from `awaiting_signoff` to terminal `parked_later` |

### Theme Delta Rows

| Line / Bundle ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `accepted_unlanded_workspace_topology_parent_bundle` | `park_later + record_open_items` | `resolved_parent_source_only` | `parked_later` | iteration docs, `dn-ledger-classification.md`, `open-items.md`, queue and execution logs | `DI-12` stays explicit as the resolved single-root conceptual-parent bundle, but does not become a current published line before later replay closes the topology question | `06`, `07`, `08`, `architecture_check.dart`, review-lead sign-off |

## Gate Result

`DOC-020` yields one explicit parked conceptual-parent bundle, one context-only frame bundle, zero theme rows, and zero mainline publication actions.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
