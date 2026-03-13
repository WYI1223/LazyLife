# DOC-009 / 05 DN Classification To Decision Line

## Purpose and Boundary

Resolve `DOC-009` clause nodes into existing decision lines, a new published placement line, and explicit non-carrier traces.

This stage must not:

1. collapse `S9` placement semantics into `TH-008` just because the same DI discusses editor-shell extraction;
2. promote intake/problem/scope/synthesis clauses into fake carriers;
3. rewrite `TH-002` from infrastructure-placement material that actually belongs to a distinct placement why-question.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- `03-retrospective-override-review.md`
- `04-impact-cone-review.md`
- `PR-0401` DN baseline for `DOC-009`
- current working-copy and mainline topic-map rows
- legacy `S9` snapshot

## Classification Decisions

| Decision Line / Outcome | Theme ID | Source DN IDs | Classification Outcome |
|------|------|------|------|
| Shell ownership refined into pane-vs-atom state partition, group lifecycle, unified `EditBuffer`, coordinator boundary, DI-4 handoff, controller shape, and implementation landing | `TH-008` | `DN-154`, `DN-155`, `DN-156`, `DN-157`, `DN-160`, `DN-161`, `DN-162`, `DN-163`, `DN-164`, `DN-165`, `DN-166`, `DN-170`, `DN-176` | Append to the existing shell-ownership line. `DOC-009` supplies the first full DI-level shell-detail contract for the already-published why-question and justifies a current-ruling refinement rather than a new theme row. |
| Tab titles consume `atom.title` rather than per-ref `display_name` | `TH-001` | `DN-169` | Append to the existing Atom-projection line. `DOC-009` applies S1 title semantics to tab carriers and keeps naming truth on Atom rather than spawning a UI-local title theme. |
| Cross-feature infrastructure placement for editor and workspace modules | `TH-011` | `DN-171`, `DN-172`, `DN-173`, `DN-174` | Create a new theme row. These clauses do not fit `TH-008` or `TH-002` without collapsing a distinct placement why-question, and replay now has enough evidence to rebuild the legacy `S9` line as a current published row. |
| Intake, inherited baseline restatement, internal problem framing, local scope guards, and architecture synthesis | `pending_internal_trace` | `DN-151`, `DN-152`, `DN-153`, `DN-158`, `DN-159`, `DN-167`, `DN-168`, `DN-175` | `context_only`. These clauses remain useful replay trace, but they do not become stable semantic carriers in this run. |

## Theme Delta Contract

| Field | Content |
|------|------|
| Source Doc Group | `DOC-009 / DI-1-editor-shell-service.md` |
| Covered Themes | `TH-001`, `TH-008`, `TH-011` |
| Theme Operations | `append_adr`, `update_existing_ruling`, `publish_adr`, `publish_ruling`, `sync_mainline`, `preserve_context_trace` |
| Primary Theme Owner | `PR-0403` executor |
| PR Executor | `PR-0403` executor |
| Secondary Coverage | `legacy S9 snapshot`, `DOC-008 / DI-0`, later `DOC-012`, `DOC-018`, `DOC-022`, `DOC-026` |
| Out of Scope | turning intake/problem framing into theme rows, folding placement semantics into `TH-008`, rewriting `TH-002` from service-placement material |
| Must Preserve | stable why-questions for `TH-001` and `TH-008`, explicit DI-4 handoff boundary, explicit inheritance from S1 title semantics, explicit legacy-S9 lineage |
| Allowed Simplifications | internal comparison prose may stay summarized in replay records rather than copied into current rulings |
| Escalation Required If Violated | any attempt to collapse placement semantics into shell ownership or to create a title-only theme row |
| Accepted Debt | none introduced by this run |
| Output Docs | `ADR-0001`, `ADR-0002`, `ADR-0009`, `S2`, `S9`, working-copy + mainline `topic-map.md`, `dn-ledger-classification.md`, `doc-run-queue.md` |
| Verification | `06`, `07`, `08` stage records plus `architecture_check.dart` |
| Required Sign-off | review leader approval recorded in `review-lead-signoff.md` before promoting `DOC-009` from `awaiting_signoff` to `completed` |

### Theme Delta Rows

| Theme ID | Operation | Before Status | After Status | Docs Touched | Must Preserve | Verification |
|----------|-----------|---------------|--------------|--------------|---------------|--------------|
| `TH-001` | `append_existing_adr + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0001`, working-copy + mainline `topic-map.md` | tab-title semantics remain inherited from Atom naming truth rather than split into a separate UI theme | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-008` | `append_existing_adr + update_existing_ruling + sync_mainline_notes` | `existing_published_row` | `active` | `ADR-0002`, `S2`, working-copy + mainline `topic-map.md` | shell-detail expansion stays inside the same stable line and keeps the DI-4 handoff explicit | `06`, `07`, `08`, `architecture_check.dart` |
| `TH-011` | `create_new_adr + publish_ruling + sync_mainline` | `no_existing_row` | `active` | `ADR-0009`, `S9`, working-copy + mainline `topic-map.md`, ADR/ruling registries, current architecture backlinks | placement semantics remain distinct from shell ownership and orthogonality lines | `06`, `07`, `08`, `architecture_check.dart` |

## Gate Result

`DOC-009` yields:

1. one inherited-context append to an already-published row;
2. one shell-detail append plus current-ruling refinement to an already-published row;
3. one new published theme row and ADR/ruling pair;
4. one explicit internal-trace `context_only` bundle.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
