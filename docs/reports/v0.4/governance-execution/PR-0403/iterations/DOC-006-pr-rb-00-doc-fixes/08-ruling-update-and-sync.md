# DOC-006 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-006` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `pending_governance_carrier_evolution_seed` | `park_later` | no mainline sync; record carry-forward in `open-items.md` | Governance carrier-migration lineage remains explicit for later governance replay instead of producing a premature current ruling |
| `pending_lifecycle_template_lineage_seed` | `park_later` | no mainline sync; record carry-forward in `open-items.md` | Lifecycle/template lineage remains explicit for later backfill work instead of publishing a current carrier now |
| `pending_governance_verification_seed` | `park_later` | no mainline sync; record carry-forward in `open-items.md` | Status-normalization and docs-verification lineage remains explicit for later governance and CI-policy replay |
| `pending_doc_refresh_trace` | `context_only` | no mainline sync | Navigation/product refresh trace stays in execution artifacts only |
| `pending_provenance_boundary_seed` | `park_later` | no mainline sync; record carry-forward in `open-items.md` | Provenance/orphan-retention boundary remains explicit for later audit and source-lineage work |

## Queue and Sign-off State

1. `DOC-006` has completed `02 -> 08` and its no-publication sync work is closed.
2. Because this run intentionally parks four governance/provenance bundles and leaves no mainline publication, review-lead approval is required before promoting the run to terminal `parked_later`.
3. `DOC-006` therefore moves to `awaiting_signoff`, and `DOC-007` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-006` reaches post-sync status:

1. zero ADR append or create work;
2. zero current ruling text changes;
3. zero topic-map row sync;
4. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
