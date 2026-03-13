# DOC-005 / 06 ADR Carrier Check

## Purpose and Boundary

Choose the carrier outcome for each `DOC-005` classification result without forcing publication where the document only supplies closure or governance bundles.

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
| `TH-001` | `append_existing_adr` | `DOC-005` supplies closure, handoff, and deferred-placeholder evidence for the already-published Atom-projection line. |
| `TH-008` | `append_existing_adr` | `DOC-005` confirms shell-ownership handoff readiness without changing the stable why-question. |
| `TH-002` | `append_existing_adr` | `DOC-005` validates the orthogonality line as closure-complete and handoff-ready. |
| `TH-003` | `append_existing_adr` | `DOC-005` confirms creation-path handoff readiness without opening a new semantic line. |
| `TH-009` | `append_existing_adr` | `DOC-005` confirms declaration-only extension handoff and preserves the manifest-style question as explicit later debt. |
| `TH-010` | `append_existing_adr` | `DOC-005` confirms Provider-SPI handoff readiness while leaving runtime activation to later sources. |
| `TH-004` | `append_existing_adr` | `DOC-005` confirms reminder infrastructure handoff readiness without changing the stable why-question. |
| `TH-005` | `append_existing_adr` | `DOC-005` confirms DTO-unification handoff readiness without collapsing the line into another theme. |
| `DOC-005 / DN-104-DN-110, DN-114` | `park_later` | Risk, debt, plan, regression, and coverage closure tables are release-closure evidence, not a semantic ADR carrier in this run. |
| `DOC-005 / DN-115-DN-121, DN-123-DN-125` | `park_later` | Doc-audit, CI, allowlist, readiness, release-judgment, and report-series closure clauses belong to later governance and release-audit surfaces. |

## Gate Result

`DOC-005` passes carrier check as:

1. `append_existing_adr` for all eight already-published theme rows;
2. `park_later` for the release-closure bundle;
3. `park_later` for the governance-closure bundle;
4. zero new ADR carriers and zero escalations.

## References

- [`../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md`](../../../../../../reports/v0.4/governance-execution/PR-0402/adr-metadata-contract.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../open-items.md`](../../open-items.md)
