# DOC-016 / 03 Retrospective Override Review

## Purpose and Boundary

Compare `DI-8` against already-published replay outputs and decide whether it inherits, refines, redirects, or supersedes any existing line.

This stage must not:

1. append unresolved SPI-verification questions into `TH-010` as if they were settled provider semantics;
2. create a new verification-only theme from an unclosed source;
3. hide the deferred status by downgrading it into generic context.

## Trigger and Inputs

- `02-historical-semantic-freeze.md`
- current mainline `topic-map.md`
- current published `ADR-0006` and `S6`
- `PR-0401` DN baseline for `DOC-016`

## Inheritance / Override Review

| Compared Surface | Finding | Result |
|------|------|------|
| `TH-010 / ADR-0006 / S6` | `DI-8` is adjacent to the provider-SPI line because it asks whether the declared SPI surface is actually implementable, but it does not close any stable why-question or refine the current semantics of provider-vs-mapping separation | `adjacent_unresolved_not_append` |
| `DOC-006` and later governance bundles | `DI-8` is another explicit no-publication governance/execution question surface, but it is narrower and tied to future provider-runtime work rather than carrier-model governance | `same_no_publish_family` |
| `deferred source rule` | The source self-declares `DEFERRED to v0.4` and keeps all three core questions unresolved | `must_remain_deferred` |

## Replay Judgment

1. No node in `DOC-016` closes, redirects, or supersedes an already-published line.
2. `DOC-016` should remain an explicit deferred bundle rather than a `TH-010` append.
3. The correct replay outcome is a no-publication run that preserves the deferred SPI-verification question surface and risk R6 for later work.

## Gate Result

`DOC-016` enters classification as a deferred no-publication run with no carrier append and no supersede edge.
