# DOC-012 / 03 Retrospective Override Review

## Purpose and Boundary

Compare `DI-4` against already-published replay outputs and decide whether it inherits, refines, redirects, or supersedes any existing line.

This stage must not:

1. create a fake new theme for every dense subsection of `DI-4`;
2. collapse DI-4's stage-2 loading rules back into `TH-008` if they are actually the continuation of the staged-restore line;
3. treat future-mode reservations as if they had already become a new current-effective architecture line.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- current mainline `topic-map.md`
- current published `ADR-0002`, `S2`, `ADR-0010`, and `S10`
- `PR-0401` DN baseline for `DOC-012`

## Inheritance / Override Review

| Compared Surface | Finding | Result |
|------|------|------|
| `TH-008 / S2` | `DI-4` is the explicit follow-up named in `DOC-009` and `S2`: it fixes the detailed multi-pane buffer-sync, granularity, bridge, and shell-load callback rules that `S2` had left open | `append_existing_line` |
| `TH-012 / S10` | `DI-4` consumes the DI-3 phase boundary and fixes the phase-2 loading side of staged restore without reopening tree shape or resolve semantics | `append_existing_line` |
| future editor-mode / block reservations | `DI-4` keeps them inside the shell line as reserved protocol and runtime-layer guidance; they do not yet justify a second published theme line in this run | `retain_inside_TH-008` |
| legacy carrier state | no separate legacy ruling snapshot existed for the DI-4 portion of either line | `no_legacy_rebuild_needed` |

## Replay Judgment

1. `DOC-012` does not justify a new `TH-013`.
2. The shell/buffer half of `DI-4` appends into `TH-008`.
3. The staged-restore continuation half of `DI-4` appends into `TH-012`.
4. Intake, baselines, and problem framing remain explicit replay context rather than new carriers.

## Gate Result

`DOC-012` enters classification as a two-line append run against the already-published `TH-008` and `TH-012` rows.
