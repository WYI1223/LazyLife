# DOC-004 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the carrier outcome for each `DOC-004` classification result without forcing publication where the document only supplies replanning or closure bundles.

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
| `TH-008` | `append_existing_adr` | `DOC-004` adds concrete `PR-0257 -> PR-0258` lane-mapping evidence under the already-published shell-ownership line. The stable why-question, current ruling target, and theme row already exist, so a new ADR would be redundant. |
| `DOC-004 / DN-094-DN-097` | `park_later` | Global replanning, cross-theme mapping, dependency order, and docs-only prerequisite planning are cleaner as governance/closure carry-forward material than as a semantic ADR carrier in this run. |
| `DOC-004 / DN-100` | `park_later` | The mixed Rule E / reminders / CI lane is too bundled to become a clean semantic carrier here; later closure and governance sources provide the better split boundary. |
| `DOC-004 / DN-101-DN-103` | `park_later` | Closure handoff, readiness, and release-sync planning belong to later closure replay and governance audit surfaces rather than to a published ADR in this run. |

## Gate Result

`DOC-004` passes carrier check as:

1. `append_existing_adr` for `TH-008`;
2. `park_later` for the global replanning bundle;
3. `park_later` for the mixed Rule E / reminders / CI clause;
4. `park_later` for the closure and release bundle;
5. zero new ADR carriers and zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
