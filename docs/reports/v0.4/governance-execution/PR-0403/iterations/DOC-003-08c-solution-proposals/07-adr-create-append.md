# DOC-003 / 07 ADR Create / Append

## Purpose and Boundary

Apply the carrier decisions from `06` to the published ADR set without creating new ADR assets where `DOC-003` only supplies append evidence.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- `ADR-0002-editor-shell-ownership.md`
- `ADR-0007-reminders-infrastructure.md`
- `PR-0402` ADR metadata contract

## ADR Append Actions

| Theme ID | ADR Action | Sections Touched | Result |
|------|------|------|------|
| `TH-008` | `append_existing_adr` to `ADR-0002` | `Current State`, `Revision Record` | Added explicit `DOC-003` replay evidence showing that the `08c` shell bridge removal and coordinator-slimming path belongs to the already-published shell-ownership line. |
| `TH-004` | `append_existing_adr` to `ADR-0007` | `Current State`, `Revision Record` | Added explicit `DOC-003` replay evidence showing that the `08c` reminders move to `lib/core/` is execution evidence under the already-published reminders infrastructure line. |

## No New ADR Creation

No new ADR asset is created in this run because:

1. `DOC-003` does not introduce a new stable why-question beyond `TH-008` and `TH-004`;
2. the governance-seed bundle remains parked for later governance sources;
3. the context-only clauses remain explicit without being over-promoted into new carriers.

## Metadata Contract Check

Both touched ADRs remain compliant with the `PR-0402` minimum skeleton:

1. no required section was removed;
2. `Current Normative Source` remains explicit;
3. the append is recorded as a new revision rather than hidden inside silent edits.

## Gate Result

`DOC-003` completes two ADR append operations:

1. `ADR-0002` updated in-place;
2. `ADR-0007` updated in-place;
3. zero new ADR files created.

## References

- [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md)
- [`../../../../../../architecture/adr/ADR-0007-reminders-infrastructure.md`](../../../../../../architecture/adr/ADR-0007-reminders-infrastructure.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
