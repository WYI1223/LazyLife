# DOC-011 / 03 Retrospective Override Review

## Purpose and Boundary

Compare `DI-3` against already-published replay outputs and decide whether it inherits, refines, redirects, or supersedes any existing line.

This stage must not:

1. fabricate a persistence-only theme just because `DI-3` is dense;
2. fold persistence detail back into `TH-008` shell ownership;
3. treat the DI-3/DI-4 handoff as if `DI-4` had already been replayed.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- current mainline `topic-map.md`
- current published `ADR-0010` and `S10`
- `PR-0401` DN baseline for `DOC-011`

## Inheritance / Override Review

| Compared Surface | Finding | Result |
|------|------|------|
| `DOC-010 / TH-012` | `DI-3` presupposes the `DI-2` binary-tree model, public layout API, resolve algorithm, and invariant set; it does not reopen those choices | `inherit_and_operationalize` |
| `TH-008 / S2` | `DI-3` does not answer who owns tab/draft/save state; it assumes shell ownership and then decides how the already-owned layout model persists and restores | `keep_distinct_from_TH-008` |
| `DI-4` boundary | `DI-3` fixes only the phase boundary and the phase-1 side of restore; it does not decide stage-2 scheduling, loading policy, or buffer-sync mechanics | `boundary_only_not_override` |
| legacy carrier state | no separate legacy ruling snapshot existed for the DI-3 portion of the line | `no_legacy_rebuild_needed` |

## Replay Judgment

1. `D7`, `D8`, `D9`, and the `DI-3 ↔ DI-4` boundary refine the already-published layout-tree line rather than introducing a new stable why-question.
2. No node in `DOC-011` supersedes `TH-012`; the source extends the same line from "how layout is structured" into "how that same layout survives restart and restore".
3. The staged restore boundary must stay explicit so later `DI-4` replay is not silently pre-consumed here.

## Gate Result

`DOC-011` enters classification as an append run against the published `TH-012` line, with no redirect and no supersede edge.
