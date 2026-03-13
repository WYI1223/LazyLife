# DOC-015 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for the `DOC-015` classification result.

Allowed outputs:

1. `create_new_adr`
2. `append_existing_adr`
3. `redirect_to_existing_adr`
4. `park_later`
5. `escalate_to_governance`

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- `PR-0402` ADR metadata contract
- current published `ADR-0010`
- current published `S10`

## Carrier Decisions

| Theme ID / Bundle | Decision | Reason |
|------|------|------|
| `TH-012` | `append_existing_adr` | The published `ADR-0010` already answers the stable layout/editor-infrastructure why-question. `DI-7` only closes the later edge around Gate B precision, benchmark definition, SLA expression, and verification method. |
| `pending_gate_and_test_policy_bundle` | `park_later` | Gate A exactness, the Release Gate command suite, PR-level testing expectations, and migration rules remain broader execution-policy material. This run keeps them explicit, but they do not justify a second ADR carrier for the published layout-tree line. |

## Additional Carrier Note

This run must refine the current ruling text as well as append the ADR, because DI-7 contributes current-effective Gate B precision and verification semantics that should not remain ADR-only narrative.

## Gate Result

`DOC-015` passes carrier check as:

1. `append_existing_adr` for `TH-012`;
2. one `park_later` governance bundle;
3. zero new ADRs;
4. zero redirects;
5. zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
