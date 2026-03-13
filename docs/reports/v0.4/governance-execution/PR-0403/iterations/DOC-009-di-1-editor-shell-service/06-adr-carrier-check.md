# DOC-009 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for each `DOC-009` classification result without hiding the fact that one existing current ruling also needs refinement.

Allowed outputs:

1. `create_new_adr`
2. `append_existing_adr`
3. `redirect_to_existing_adr`
4. `park_later`
5. `escalate_to_governance`

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- `PR-0402` ADR metadata contract
- current mainline ADR registry state
- current mainline ruling registry state

## Carrier Decisions

| Theme ID / Bundle | Decision | Reason |
|------|------|------|
| `TH-001` | `append_existing_adr` | `DOC-009` applies already-published Atom title semantics to tabs, but the stable why-question, published ADR, and current ruling already exist. |
| `TH-008` | `append_existing_adr` | `DOC-009` adds the first full DI-level shell-detail contract under the already-published shell-ownership line. The ADR carrier already exists, even though `08` must also refine the current `S2` ruling text. |
| `TH-011` | `create_new_adr` | Replay evidence plus the legacy `S9` snapshot support a distinct placement line that is not reducible to `TH-008` or `TH-002`, and no published ADR carrier currently exists. |

## Non-Carrier Clauses Not Submitted To ADR Creation

The following clauses remain explicit, but are not submitted to ADR carrier creation:

1. `DN-151-DN-153` as intake and inherited-baseline trace;
2. `DN-158-DN-159` as local problem framing;
3. `DN-167-DN-168` as reuse/scope guards inside the DI;
4. `DN-175` as integrated architecture snapshot only.

## Gate Result

`DOC-009` passes carrier check as:

1. `append_existing_adr` for `TH-001`;
2. `append_existing_adr` for `TH-008`;
3. `create_new_adr` for `TH-011`;
4. zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
