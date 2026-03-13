# DOC-009 / 08 Ruling Update And Sync

## Purpose and Boundary

Close the `DOC-009` replay run by recording ruling impact, topic-map sync, registry updates, and sign-off state.

## Trigger and Inputs

- `07-adr-create-append.md`
- current mainline rulings and topic-map rows
- `doc-run-queue.md`
- `open-items.md`

## Ruling and Sync Actions

| Theme ID / Bundle | Ruling Action | Topic-Map Action | Result |
|------|------|------|------|
| `TH-001` | no ruling text change | sync `DOC-009` tab-title note to working copy + mainline row | Published Atom-projection line stays active; DI-1 now records that tab carriers consume `atom.title` rather than per-ref `display_name` |
| `TH-008` | update current ruling text | sync `DOC-009` shell-detail note to working copy + mainline row | Published shell-ownership line stays active; `S2` now absorbs DI-1 shell detail without changing the stable why-question |
| `TH-011` | publish new current ruling `S9` | add new publish-complete row to working copy + mainline topic map | Rebuilt cross-feature infrastructure placement line is now active with explicit ADR/ruling backlinks |
| `pending_internal_trace` | `context_only` | no mainline sync | Intake/problem/scope/synthesis material remains explicit in execution artifacts only |

## Additional Sync Surfaces

1. `docs/architecture/rulings/README.md` now registers `S9` as current-effective.
2. `docs/architecture/adr/README.md` now registers `ADR-0009`.
3. Current architecture docs with live S9 backlinks now point to rebuilt `docs/architecture/rulings/S9-cross-feature-infrastructure-placement.md`.

## Queue and Sign-off State

1. `DOC-009` has completed `02 -> 08` and its publication sync work is closed.
2. Because this run touched two published ADR carriers, refined one current ruling, and published a new ADR/ruling pair, review-lead approval is required before promoting the run to terminal `completed`.
3. `DOC-009` therefore moves to `awaiting_signoff`, and `DOC-010` must remain on hold until the sign-off record is approved.

## Gate Result

`DOC-009` reaches post-sync status:

1. one new ADR file;
2. one new current ruling file;
3. two ADR append updates;
4. one current-ruling text update;
5. one new publish-complete topic-map row and two updated existing-row notes;
6. queue state becomes `awaiting_signoff`.

## References

- [`../../doc-run-queue.md`](../../doc-run-queue.md)
- [`../../open-items.md`](../../open-items.md)
- [`review-lead-signoff.md`](review-lead-signoff.md)
