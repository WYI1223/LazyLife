# DOC-006 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the carrier outcome for each `DOC-006` classification result without forcing governance publication from a historical predecessor source.

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
| `pending_governance_carrier_evolution_seed` | `park_later` | `DOC-006` is the first migration phase, but later governance restored ADR as the journey layer and now owns the active carrier model. Publishing from `DOC-006` alone would freeze a superseded governance picture. |
| `pending_lifecycle_template_lineage_seed` | `park_later` | Lifecycle and PR-spec template lineage is important, but later governance explicitly postpones stable template backfill until governance activation and template/playbook closeout. |
| `pending_governance_verification_seed` | `park_later` | Status normalization and docs-link verification are real lineage inputs, but later governance and CI policy own the current-effective verification layer. |
| `pending_provenance_boundary_seed` | `park_later` | Provenance and orphan-retention policy belongs to later audit and source-lineage work rather than an ADR carrier in this run. |

## Context-Only Trace

`pending_doc_refresh_trace` (`DN-128-DN-130`) stays outside carrier publication entirely. It remains explicit as historical release-navigation evidence, not as an ADR line.

## Gate Result

`DOC-006` passes carrier check as:

1. `park_later` for four governance/provenance bundles;
2. `context_only` for the navigation/product refresh trace;
3. zero new ADR carriers, zero append decisions, and zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
