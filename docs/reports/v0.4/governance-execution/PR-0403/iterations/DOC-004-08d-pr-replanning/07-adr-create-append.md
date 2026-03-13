# DOC-004 / 07 ADR Create Append

## Purpose and Boundary

Apply the carrier decisions from `06` to the published ADR set without creating new ADR assets where `DOC-004` only supplies append evidence or parked bundles.

## Trigger and Inputs

- `06-adr-carrier-check.md`
- current published ADR registry
- current published ruling registry

## ADR Actions

| Theme ID / Bundle | ADR Action | Sections Touched | Result |
|------|------|------|------|
| `TH-008` | `append_existing_adr` to `ADR-0002` | `Current State`, `Revision Record` | Added explicit `DOC-004` replay evidence showing that `PR-0257` and `PR-0258` are the concrete v0.2.5 execution lanes for shell ownership, while phase-2 extraction remains later handoff. |
| `DOC-004 / DN-094-DN-097` | `park_later` | none | Replanning and mapping bundle remains outside ADR publication in this run. |
| `DOC-004 / DN-100` | `park_later` | none | Mixed Rule E / reminders / CI clause remains parked rather than forcing a blended ADR append. |
| `DOC-004 / DN-101-DN-103` | `park_later` | none | Closure, readiness, and release-sync bundle remains parked for later replay. |

## Gate Result

`DOC-004` applied:

1. one append-only ADR update (`ADR-0002`);
2. zero new ADR assets;
3. three parked bundles with no ADR text creation.

## References

- [`../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md`](../../../../../../architecture/adr/ADR-0002-editor-shell-ownership.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
