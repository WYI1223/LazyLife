# DOC-010 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for the `DOC-010` classification result.

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
| `TH-012` | `create_new_adr` | No published ADR carrier currently answers the layout-tree why-question, and `DI-2` does not fit `TH-008` because shell ownership does not define the binary-tree structure, resolve algorithm, invariant set, or group-leaf mapping. |

## Additional Carrier Note

This run also publishes the first current ruling for the line. Unlike `DOC-009 / TH-011`, the line does not rebuild from a separate legacy ruling snapshot; publication starts directly from the resolved DI because no earlier ruling-shaped carrier existed.

## Gate Result

`DOC-010` passes carrier check as:

1. `create_new_adr` for `TH-012`;
2. zero redirects;
3. zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
