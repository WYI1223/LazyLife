# DOC-008 / 06 ADR Carrier Check

## Purpose and Boundary

Decide whether `DOC-008` should create, append, redirect, or decline ADR carriers after classification is complete.

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- current ADR set, especially `ADR-0002`
- mainline and working-copy topic maps

## Carrier Decisions

| Theme ID / Bundle | Carrier Decision | Reason |
|------|------|------|
| `TH-008` | `append_existing_adr` | DI-0 naming clarification, layer split, and implementation landing all strengthen the existing shell-ownership line rather than creating a new why-question |
| `pending_pr_spec_trace` | `context_only` | PR-spec traceability remains explicit, but does not justify its own carrier |

## Gate Result

1. `DOC-008` creates no new ADR.
2. `DOC-008` appends to `ADR-0002`.
3. `DOC-008` changes no current ruling text.
4. `DN-149` remains explicit as non-carrier traceability.

## References

- [`07-adr-create-append.md`](07-adr-create-append.md)
