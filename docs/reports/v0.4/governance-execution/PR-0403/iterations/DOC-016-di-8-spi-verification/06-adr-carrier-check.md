# DOC-016 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the carrier outcome for `DOC-016` without forcing publication from an explicitly deferred source.

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
| `pending_spi_verification_deferred_bundle` | `park_later` | `DOC-016` preserves an unresolved SPI-verification question surface, not a settled provider-runtime decision. Publishing or appending from this source would fabricate closure that the document itself explicitly refuses to claim. |

## Gate Result

`DOC-016` passes carrier check as:

1. `park_later` for one deferred bundle;
2. zero new ADR carriers;
3. zero append decisions;
4. zero redirects;
5. zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
