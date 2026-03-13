# DOC-015 / 03 Retrospective Override Review

## Purpose and Boundary

Compare `DI-7` against already-published replay outputs and decide whether it inherits, refines, redirects, or supersedes any existing line.

This stage must not:

1. fabricate a standalone benchmark or testing-governance theme just because `DI-7` is execution-heavy;
2. force repo-wide Gate A or Release Gate policy into `TH-012` if those clauses do not answer the published layout-tree why-question;
3. reopen `TH-008` shell ownership simply because some Gate B checks mention buffer sync or tab determinism.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- current mainline `topic-map.md`
- current published `ADR-0010` and `S10`
- `PR-0401` DN baseline for `DOC-015`

## Inheritance / Override Review

| Compared Surface | Finding | Result |
|------|------|------|
| `TH-012 / ADR-0010 / S10` | `DI-7` closes the later edge left by `DOC-014` around Gate B precision, benchmark dimensions, SLA expression, and verification method for the already-published editor-infrastructure line | `inherit_and_close_edge` |
| `TH-008 / ADR-0002 / S2` | `DI-7` references same-atom cross-pane editing and deterministic tab behavior as part of Gate B validation, but it does not reopen who owns tabs, drafts, or buffers | `keep_distinct_from_TH-008` |
| `OI-021 / TH-012 future edge` | `DI-7` is the source that was explicitly expected to close the line-specific gate-precision and SLA append point | `resolves_existing_open_item_if_append_lands` |
| broader governance and release bundles from `DOC-005-DOC-007` | Gate A precision, Release Gate exact suite, PR-level testing expectations, and test-migration strategy remain broader execution-policy material rather than a new semantic line in this run | `adjacent_not_override` |

## Replay Judgment

1. `DN-256`, `DN-258`, `DN-259`, `DN-260`, `DN-261`, `DN-262`, `DN-263`, and `DN-264` refine the already-published `TH-012` line.
2. `DN-255`, `DN-257`, `DN-265`, `DN-266`, `DN-267`, and `DN-268` remain explicit repo-wide gate/test policy material and should stay parked rather than be flattened into the current layout-tree semantics.
3. No node in `DOC-015` redirects or supersedes `TH-012`; the source only refines how the published line is verified and performance-bounded.

## Gate Result

`DOC-015` enters classification as one append run against `TH-012`, plus one explicit parked governance bundle and one intake-only context bundle.
