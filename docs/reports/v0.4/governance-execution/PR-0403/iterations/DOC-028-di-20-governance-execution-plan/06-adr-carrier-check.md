# DOC-028 / 06 ADR Carrier Check

## Purpose and Boundary

Determine whether `DOC-028` should create or modify a published ADR/ruling carrier, or whether the correct outcome is governance-spec sync only.

## Carrier Decision

| Candidate Surface | Decision | Reason |
|------|------|------|
| New governance `TH-*` row | `reject` | `DI-20` is a governance execution source, not a new cross-version product decision line that needs its own registry row. |
| New governance ADR asset | `reject` | Creating a self-referential governance ADR would duplicate the already-landed governance specs instead of replaying active execution rules into them. |
| New governance ruling | `reject` | Current governance execution authority is already carried by landed governance specs and replay records; this run is not introducing a separate current-effective governance ruling file. |
| Existing governance specs | `append_existing_governance_surface` | DI-20's active rules are already embodied in `PR-0403` through `PR-0406`, so replay tightens those surfaces directly. |

## Approved Outcome

`DOC-028` is a governance-spec sync run.

The permitted outputs are:

1. append or tighten existing governance specs and replay records;
2. update replay classification and execution logs;
3. resolve or narrow consumed historical governance seeds where appropriate.

The forbidden outputs are:

1. new `ADR-00XX` creation;
2. new ruling creation;
3. new topic-map row admission.

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
- [`../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md`](../../../../../../releases/v0.4/prs/PR-0403-per-adr-serial-execution.md)
- [`../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md`](../../../../../../releases/v0.4/prs/PR-0404-theme-delta-contract-and-consistency-audit.md)
- [`../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md`](../../../../../../releases/v0.4/prs/PR-0405-closure-audit-and-governance-activation.md)
- [`../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md`](../../../../../../releases/v0.4/prs/PR-0406-template-playbook-and-lifecycle-backfill.md)
