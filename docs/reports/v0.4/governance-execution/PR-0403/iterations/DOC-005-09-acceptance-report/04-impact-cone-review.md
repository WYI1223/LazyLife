# DOC-005 / 04 Impact Cone Review

## Purpose and Boundary

Record the publish surfaces and carry-forward surfaces touched by the `DOC-005` replay run.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- current ADR registry
- current ruling registry
- current topic-map rows
- current `open-items.md`

## Impact Cone

| Surface | Impact | Reason |
|------|------|------|
| `ADR-0001` through `ADR-0008` | `append_only` | `DOC-005` supplies closure, handoff, and deferred-placeholder evidence for already-published lines. |
| current rulings `S1` through `S8` | `no_text_change` | `09` confirms acceptance and handoff but does not redefine the current normative wording. |
| mainline `topic-map.md` | `note_refresh_only` | Notes are refreshed to reflect that `DOC-005` closure/handoff evidence has now been replayed. |
| `topic-map-working-copy.md` | `note_refresh_only` | Working-copy rows are kept aligned with the new append state. |
| `dn-ledger-classification.md` | `append_classification` | Adds eight append results and two parked closure/governance bundles. |
| `open-items.md` | `resolve_and_append` | `DOC-004` parked closure seeds are partially resolved and re-split into explicit `DOC-005` carry-forward bundles. |
| `doc-run-queue.md` | `state_transition` | `DOC-004` promotes to `completed`; `DOC-005` becomes `awaiting_signoff`. |

## Cone Result

`DOC-005` has a wide replay cone, but it remains bounded:

1. published ADRs are append-only;
2. current rulings are unchanged;
3. no new theme row or ADR asset is created;
4. release and governance bundles remain explicit instead of being flattened into semantic carriers.

## References

- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../topic-map-working-copy.md`](../../topic-map-working-copy.md)
- [`../../open-items.md`](../../open-items.md)
