# DOC-013 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for the `DOC-013` classification result.

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- published ADR [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md)
- current ruling [`../../../../../../architecture/rulings/S2-tab-draft-save-ownership.md`](../../../../../../architecture/rulings/S2-tab-draft-save-ownership.md)

## Carrier Decision

| Theme ID | Carrier Decision | Rationale |
|------|------|------|
| `TH-008` | `append_existing_adr` | `ADR-0002` already carries the stable shell-ownership why-question. `DI-5` only confirms cursor independence and the absence of a dedicated local conflict subsystem as direct consequences of the already-published shell / buffer model. |
| `pending_internal_trace` | `context_only` | Intake framing, inherited sync-frequency context, and open-boundary notes stay explicit in execution artifacts only. |

## Result

`DOC-013` passes carrier check as:

1. zero new ADR files;
2. one append-only update to `ADR-0002`;
3. no redirect and no new theme row.
