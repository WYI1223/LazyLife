# DOC-003 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the carrier outcome for each `DOC-003` classification result without forcing publication where the document only provides governance-seed or context-only material.

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
| `TH-008` | `append_existing_adr` | `DOC-003` adds phase-1 shell execution evidence under an already-published line. The stable why-question, current ruling target, and theme row already exist, so a new ADR would be redundant. |
| `TH-004` | `append_existing_adr` | `DOC-003` adds migration-level execution evidence for the already-published reminders infrastructure line. The document does not introduce a new stable subject/tension pair. |
| `DOC-003 / DN-088-DN-091` | `park_later` | The CI and guardrail clauses are governance-seed material. Later governance sources define the policy boundary more cleanly than `08c`, so this bundle should not become a published ADR carrier in this run. |

## Non-Carrier Clauses Not Submitted To ADR Creation

The following clauses remain explicit, but are not submitted to ADR carrier creation:

1. `DN-084` (`3.1.2`) as a local Rule E decoupling tactic;
2. `DN-087` (`3.1.5`) as an intentional low-priority defer note;
3. `DN-092` (`3.3` action-needed backlog) as doc-governance evidence only;
4. `DN-093` (`3.3` no-action validation) as negative evidence only.

## Gate Result

`DOC-003` passes carrier check as:

1. `append_existing_adr` for `TH-008`;
2. `append_existing_adr` for `TH-004`;
3. `park_later` for the guardrail governance-seed bundle;
4. zero new ADR carriers and zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
