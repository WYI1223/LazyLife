# DOC-002 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze what `08b` itself decided before later replay layers are considered.

This stage does not:

1. treat later DI or ruling addenda as if they already existed in `08b`;
2. classify themes or pick carriers;
3. write current-effective conclusions.

## Trigger and Inputs

- `DOC-002 / 08b-semantic-decisions.md`
- `DOC-001 / 08a-audit-findings.md` as trigger context only
- `PR-0401` DN baseline: `DN-003-DN-007`, `DN-042-DN-082`

## Historical Freeze Result

| Line | Source DN IDs | Historical Freeze |
|------|---------------|-------------------|
| `S1` | `DN-003-DN-007`, `DN-042-DN-049` | `08b` fixed Atom as a unified container model and laid down the first full projection rules around `content_type`, `view_hint`, rendering matrix, mandatory `atom_ref`, designated folders, title, and explicitly deferred future carrier sub-lines |
| `S2` | `DN-050-DN-051` | `08b` moved tab/draft/save ownership out of notes-local semantics and chose a phased extraction toward a workbench-level shell |
| `S3` | `DN-052-DN-057` | `08b` defined tag filtering and workspace tree as orthogonal dimensions and reserved phased rollout for tag-result UX |
| `S4` | `DN-058-DN-060` | `08b` unified creation semantics around `Atom + atom_ref` and explicit route placement instead of path-specific object meaning |
| `S5` | `DN-061-DN-066` | `08b` separated first-party command runtime from the future third-party Extension Kernel security contract |
| `S6` | `DN-067-DN-071` | `08b` split sync responsibilities across provider adapter, orchestrator, and mapping persistence layers |
| `S7` | `DN-072-DN-077` | `08b` moved reminders into core infrastructure and bound scheduling to Atom lifecycle rather than view loading |
| `S8` | `DN-078-DN-082` | `08b` fixed `AtomListItem` as the intended unified list DTO and treated `NoteItem` as an information-losing historical carrier |

## Gate Result

`DOC-002` is confirmed as the earliest publish-worthy decision source in the queue.

## References

- [`../../../../../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../../../../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- [`../../../../../../reports/v0.4/governance-execution/PR-0401/dn-ledger.md`](../../../../../../reports/v0.4/governance-execution/PR-0401/dn-ledger.md)
