# DOC-010 / 03 Retrospective Override Review

## Purpose and Boundary

Determine whether `DOC-010 / DI-2` overrides an earlier published line, extends one, or forms a new line.

This stage must not:

1. treat shell ownership and layout structure as the same why-question;
2. manufacture a fake legacy ruling snapshot just because a new current line is about to be published;
3. use later implementation docs to retroactively shrink the original `DI-2` boundary.

## Comparison Set

- `DOC-008 / DI-0`
- `DOC-009 / DI-1`
- current mainline rows `TH-001`, `TH-008`, `TH-011`
- current ruling set `S1-S9`

## Override Assessment

| Comparison Target | Assessment | Result |
|------|------|------|
| `DOC-008 / DI-0` | DI-0 only clarified naming and layer split around shell artifacts. It does not answer layout-tree structure or resolve semantics. | no override / no merge |
| `DOC-009 / DI-1` | DI-1 fixed ownership, service API, and placement boundaries. It assumes pane structure exists, but does not define the binary tree, node shape, invariant set, or top-down resolve contract. | complementary context, not the same line |
| `TH-008 / S2 / ADR-0002` | Shell ownership answers who owns tab/draft/save/layout state. It does not answer how layout itself must be modeled and resolved. | must stay distinct from `TH-008` |
| `TH-011 / S9 / ADR-0009` | Placement answers where cross-feature editor/workspace infrastructure lives. It does not answer the layout-tree model. | must stay distinct from `TH-011` |
| legacy ruling snapshot | No separate legacy `S10`-style snapshot exists for this line. | first publication from resolved DI is allowed if carrier check passes |

## Review Result

`DOC-010 / DI-2` forms a new layout-tree line. It inherits context from shell ownership, but it does not override or collapse into any already-published row.

## References

- [`02-historical-semantic-freeze.md`](02-historical-semantic-freeze.md)
- [`04-impact-cone-review.md`](04-impact-cone-review.md)
