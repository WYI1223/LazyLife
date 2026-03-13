# DOC-002 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-002` clause nodes into stable decision lines and topic-map rows.

This stage is where:

1. theme rows may be created;
2. split / merge questions are decided;
3. carrier candidates become explicit.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `PR-0401` DN baseline

## Classification Decisions

| Decision Line | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| `S1` Atom projection model evolution | `TH-001` | `DN-003-DN-007`, `DN-042-DN-049` | Keep as one line. Later material expands implementation timing but does not split the stable why-question. |
| `S2` Editor shell ownership and phased extraction | `TH-008` | `DN-050-DN-051` | Create new theme row. These nodes do not fit any existing stable line, and replay evidence supports an independent shell-ownership decision line. |
| `S3` Tag-workspace orthogonality | `TH-002` | `DN-052-DN-057` | Keep as one line. The later panel rollouts preserve, not replace, the orthogonality invariant. |
| `S4` Creation path unification and atom_ref pairing | `TH-003` | `DN-058-DN-060` | Keep as one line. It inherits context from `TH-001` but answers its own stable why-question. |
| `S5` Extension-kernel boundary for first-party commands | `TH-009` | `DN-061-DN-066` | Create new theme row. These nodes do not fit any existing stable line, and replay evidence supports an independent boundary line. |
| `S6` Provider SPI and external mapping separation | `TH-010` | `DN-067-DN-071` | Create new theme row. Replay confirms this is not just an implementation note under another line, so a distinct theme row is required. |
| `S7` Reminders positioning and trigger semantics | `TH-004` | `DN-072-DN-077` | Keep as one line. Module move plus lifecycle trigger semantics stay inside one stable why-question. |
| `S8` Atom list DTO unification | `TH-005` | `DN-078-DN-082` | Create new theme row. DTO-boundary clauses are not reducible to `TH-001` without losing a stable subject/tension pair. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-002 / 08b-semantic-decisions.md` |
| Covered Themes | `TH-001`, `TH-008`, `TH-002`, `TH-003`, `TH-009`, `TH-010`, `TH-004`, `TH-005` |
| Theme Operations | `create`, `publish_adr`, `publish_ruling`, `sync_mainline` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `DOC-001`, `DOC-003`, `DOC-004`, `DOC-005` |
| Out of Scope | later DI append work, repo-wide closure audit, governance activation |
| Must Preserve | earliest stable why-questions, explicit open edges, legacy snapshot backlinks, current vs historical carrier boundary |
| Allowed Simplifications | no DI-stage implementation detail is pulled forward unless needed to justify carrier choice |
| Escalation Required If Violated | any forced merge, redirect, or contract change that invalidates the eight-line classification |
| Accepted Debt | `OI-001`, `OI-002`, `OI-003` |
| Output Docs | `ADR-0001..0008`, `S1..S8`, mainline `topic-map.md`, working-copy classification artifacts |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before treating the run as publish-complete |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-001` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0001`, `S1`, mainline `topic-map.md` | S1 open-edge visibility and unified Atom semantics | `07`, `08`, `architecture_check.dart` |
| `TH-008` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0002`, `S2`, mainline `topic-map.md` | shell ownership line stays distinct from notes-local implementation detail | `07`, `08`, `architecture_check.dart` |
| `TH-002` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0003`, `S3`, mainline `topic-map.md` | orthogonality invariant stays separate from creation-path logic | `07`, `08`, `architecture_check.dart` |
| `TH-003` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0004`, `S4`, mainline `topic-map.md` | creation-path invariant remains explicit and keeps inherited context visible | `07`, `08`, `architecture_check.dart` |
| `TH-009` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0005`, `S5`, mainline `topic-map.md` | first-party runtime and extension-kernel contract remain distinct | `07`, `08`, `architecture_check.dart` |
| `TH-010` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0006`, `S6`, mainline `topic-map.md` | provider translation boundary stays separate from mapping ownership | `07`, `08`, `architecture_check.dart` |
| `TH-004` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0007`, `S7`, mainline `topic-map.md` | lifecycle-trigger model and bulk-delete open edge remain explicit | `07`, `08`, `architecture_check.dart` |
| `TH-005` | `create + publish_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0008`, `S8`, mainline `topic-map.md` | DTO boundary remains distinct from TH-001 rather than being silently merged away | `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-002` yields eight approved theme rows:

1. all eight rows are first materialized during `DOC-002` replay classification;
2. zero unresolved split / merge disputes remain;
3. later document runs may append evidence, but they do not retroactively define this run's row-creation basis.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
