# DOC-005 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-005` replay run by recording ruling impact, topic-map sync, queue movement, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-001` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added closure/handoff evidence; the current normative line and ruling file stay unchanged |
| `TH-008` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added shell-handoff evidence; the current normative line and ruling file stay unchanged |
| `TH-002` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added closure/handoff evidence; the current normative line and ruling file stay unchanged |
| `TH-003` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added closure/handoff evidence; the current normative line and ruling file stay unchanged |
| `TH-009` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added declaration-only handoff evidence; the current normative line and ruling file stay unchanged |
| `TH-010` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added closure/handoff evidence; the current normative line and ruling file stay unchanged |
| `TH-004` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added reminder-infrastructure handoff evidence; the current normative line and ruling file stay unchanged |
| `TH-005` | `no_ruling_text_change` | refresh working-copy and mainline row notes | `DOC-005` added release-closure evidence; the current normative line and ruling file stay unchanged |
| `DOC-005 / DN-104-DN-110, DN-114` | `park_later` | record carry-forward in `open-items.md` only | release-closure bundle remains outside mainline publication in this run |
| `DOC-005 / DN-115-DN-121, DN-123-DN-125` | `park_later` | record carry-forward in `open-items.md` only | governance-closure bundle remains outside mainline publication in this run |

## Queue and Sign-off State

1. `DOC-005` has completed `02 -> 08` and its output sync work is closed.
2. Because this run touched eight published ADR assets and re-split carried-forward closure/governance bundles, review-lead approval is required before promoting the run to `completed`.
3. `DOC-005` therefore moves to `awaiting_signoff`, and `DOC-006` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-005` reaches post-sync status:

1. eight ADR append updates completed;
2. no current ruling text changed;
3. topic-map rows stayed publish-complete with note-level refresh only;
4. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
