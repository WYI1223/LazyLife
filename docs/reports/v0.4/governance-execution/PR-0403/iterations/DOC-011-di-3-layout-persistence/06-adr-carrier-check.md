# DOC-011 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for the `DOC-011` classification result.

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
| `TH-012` | `append_existing_adr` | The published `ADR-0010` already answers the stable layout-tree why-question. `DI-3` extends the same line with persistence, migration, pane-limit, and staged-boundary detail rather than introducing a second layout-specific why-question. |

## Additional Carrier Note

This run must refine the current ruling text as well as append the ADR, because DI-3 contributes current-effective persistence and restore rules that should not remain ADR-only narrative.

## Gate Result

`DOC-011` passes carrier check as:

1. `append_existing_adr` for `TH-012`;
2. zero new ADRs;
3. zero redirects;
4. zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
