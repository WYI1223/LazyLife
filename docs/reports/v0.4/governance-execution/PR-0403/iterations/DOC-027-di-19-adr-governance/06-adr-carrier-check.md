# DOC-027 / 06 ADR Carrier Check

## Purpose and Boundary

Determine whether `DOC-027` should create or modify a published ADR/ruling carrier, or whether the correct outcome is governance-doc sync only.

## Carrier Decision

| Candidate Surface | Decision | Reason |
|------|------|------|
| New governance `TH-*` row | `reject` | `DI-19` is a governance rule source, not a new cross-version product decision line that needs its own registry row. |
| New governance ADR asset | `reject` | Creating a self-referential governance ADR would duplicate the already-landed governance docs instead of replaying the current rules into them. |
| New governance ruling | `reject` | Current governance authority is already carried by the landed governance docs and downstream execution contracts; this run is not introducing a separate current-effective governance ruling file. |
| Existing governance docs | `append_existing_governance_docs` | `DI-19`'s active rules are already embodied in the landed ADR README, topic-map rules, and retrospective metadata contract, so replay tightens those surfaces directly. |

## Approved Outcome

`DOC-027` is a governance-doc sync run.

The permitted outputs are:

1. append or tighten existing governance docs;
2. update replay classification and execution logs;
3. resolve consumed historical governance seeds where appropriate.

The forbidden outputs are:

1. new `ADR-00XX` creation;
2. new ruling creation;
3. new topic-map row admission.

## References

- [`05-dn-classification-to-decision-line.md`](05-dn-classification-to-decision-line.md)
- [`../../../../../../architecture/adr/README.md`](../../../../../../architecture/adr/README.md)
- [`../../../../../../architecture/adr/topic-map.md`](../../../../../../architecture/adr/topic-map.md)
- [`../../../PR-0402/adr-metadata-contract.md`](../../../PR-0402/adr-metadata-contract.md)
