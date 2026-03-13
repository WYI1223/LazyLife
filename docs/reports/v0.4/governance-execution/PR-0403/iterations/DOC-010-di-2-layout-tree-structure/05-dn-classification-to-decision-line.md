# DOC-010 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-010` clause nodes into stable decision-line output without laundering the layout-tree contract into shell ownership.

This stage must not:

1. collapse `DI-2` into `TH-008` just because layout is consumed by `EditorShellService`;
2. split node shape, wrapper API, resolve, invariants, and group-leaf mapping into fake separate themes when they answer one stable why-question;
3. invent a fake legacy carrier that did not exist in the source history.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-010`
- current working-copy and mainline topic-map rows

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Immutable binary layout-tree structure, `GroupLayout` wrapper API, top-down `resolve`, invariant set, and `EditorGroupModel ↔ Leaf` lifecycle mapping | `TH-012` | `DN-177`, `DN-178`, `DN-179`, `DN-180`, `DN-181`, `DN-182` | Create a new theme row. `DI-2` supplies a stable why-question that is not answered by shell ownership or placement lines and is coherent enough to publish as one layout-tree carrier. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-010 / DI-2-layout-tree-structure.md` |
| Covered Themes | `TH-012` |
| Theme Operations | `publish_adr`, `publish_ruling`, `sync_mainline`, `sync_current_architecture_backlink` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-009 / DI-1 shell ownership context`; later `DOC-011 / DI-3`; later `DOC-014 / DI-6`; later `DOC-015 / DI-7` |
| Out of Scope | turning persistence or SLA follow-up into current-source content before their own replay; collapsing layout structure into `TH-008`; fabricating a legacy snapshot |
| Must Preserve | immutable binary tree choice, `GroupLayout` wrapper boundary, top-down resolve, invariant set, and explicit `EditorGroupModel ↔ Leaf` mapping |
| Allowed Simplifications | current implementation detail may stay summarized in replay and module-backlink notes rather than copied into the ruling body |
| Escalation Required If Violated | any attempt to redirect `DOC-010` into `TH-008` or to publish a line without an explicit current ruling |
| Accepted Debt | no legacy snapshot exists for this line; first publication therefore starts directly from the resolved DI |
| Output Docs | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `doc-run-queue.md`, `group-layout.md`, ADR/ruling registries |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-010` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-012` | `create_new_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0010`, `S10`, working-copy + mainline `topic-map.md`, ADR/ruling registries, `group-layout.md` | the line stays distinct from shell ownership and keeps `DI-2`'s structure / resolve / invariant contract whole | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-010` yields one new published line and zero append-only outputs.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
