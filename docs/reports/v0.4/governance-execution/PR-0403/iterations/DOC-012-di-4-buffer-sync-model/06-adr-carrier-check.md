# DOC-012 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the ADR carrier outcome for the `DOC-012` classification result.

Allowed outputs:

1. `create_new_adr`
2. `append_existing_adr`
3. `redirect_to_existing_adr`
4. `park_later`
5. `escalate_to_governance`

## Trigger and Inputs

- `05-dn-classification-to-decision-line.md`
- `PR-0402` ADR metadata contract
- current published `ADR-0002` and `ADR-0010`
- current published `S2` and `S10`

## Carrier Decisions

| Theme ID / Bundle | Decision | Reason |
|------|------|------|
| `TH-008` | `append_existing_adr` | `ADR-0002` already carries the stable shell-ownership why-question. `DI-4` answers the detailed multi-pane buffer-sync, granularity, and bridge follow-up explicitly left open by that published line. |
| `TH-012` | `append_existing_adr` | `ADR-0010` already carries the staged restore line. `DI-4` completes the phase-2 loading side of that restore model rather than creating a second restore-only why-question. |
| `pending_internal_trace` | `context_only` | Intake, baselines, and problem framing remain explicit replay trace only. |

## Additional Carrier Note

Both touched lines require current-ruling refinement as well as ADR append work: `S2` must absorb D10/D11/D12 shell detail, and `S10` must absorb the stage-2 loading continuation of staged restore.

## Gate Result

`DOC-012` passes carrier check as:

1. `append_existing_adr` for `TH-008`;
2. `append_existing_adr` for `TH-012`;
3. zero new ADRs;
4. zero redirects;
5. zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
