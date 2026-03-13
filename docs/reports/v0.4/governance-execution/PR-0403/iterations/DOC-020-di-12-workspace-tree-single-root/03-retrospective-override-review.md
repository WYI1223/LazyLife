# DOC-020 / 03 Retrospective Override Review

## Purpose and Boundary

Compare `DI-12` against current published lines and later known replay sources before any carrier decision is made.

This stage must not:

1. force `DI-12` into `TH-003` or `TH-011` just because those lines touch routing or workspace infrastructure;
2. publish the single-root answer set without checking whether later replay already rewrites the topology direction;
3. erase the conceptual-parent role of `DI-12`.

## Current Published-Line Check

1. No current published row answers the full workspace-topology and system-anchor why-question captured by `DI-12`.
2. `TH-003` covers creation-path unification only; it does not close topology shape, system-node lifecycle, subtree-scoped Tasks/Calendar semantics, migration, or delete-policy behavior.
3. `TH-011` covers cross-feature placement only; it does not close workspace topology or routing semantics.

## Later-Source Override Check

| Later Source / Boundary | Source DN IDs | Review Result |
|------|------|------|
| `DOC-023 / DI-15` architecture pivot | `later replay boundary` | Later replay explicitly records a direction change from single-root to multi-root and replays inherited DI-12 constraints. `DOC-020` therefore must not publish the single-root parent bundle as if it were the already-stable current row. |
| `DOC-024-DOC-026` implementation descendants | `later replay boundary` | Later replay consumes the handoff surface from `DI-12`, so the parent bundle must remain explicit and queryable rather than being hidden as discarded planning prose. |
| `TH-003` inherited creation-routing context | `DN-327` | Routing remains related context for `TH-003`, but `DI-12` does not simply append a landed routing refinement into the already-published creation-path line. |

## Override Result

`DOC-020` should preserve:

1. one explicit context frame bundle;
2. one resolved-but-unlanded conceptual-parent bundle;
3. zero current publish-complete theme rows in this run.

## References

- [`02-historical-semantic-freeze.md`](02-historical-semantic-freeze.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../../../../v0.3/design-discussions/DI-15-rust-data-model-single-root.md`](../../../../../v0.3/design-discussions/DI-15-rust-data-model-single-root.md)
