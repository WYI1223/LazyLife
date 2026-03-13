# DOC-015 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the historical meaning of `DOC-015 / DI-7` before classification.

This stage must not:

1. import deferred `DI-8` SPI-verification concerns into the frozen meaning of `DI-7`;
2. collapse repo-wide Gate A or Release Gate execution policy into the already-published `TH-012` semantic core;
3. back-project later replay publication state into the source document's historical wording.

## Trigger and Inputs

- source doc [`../../../../../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md`](../../../../../../reports/v0.3/design-discussions/DI-7-gates-perf-testing.md)
- `PR-0401` survey [`../../../PR-0401/surveys/DOC-015-survey.md`](../../../PR-0401/surveys/DOC-015-survey.md)
- `PR-0401` DN baseline for `DOC-015`
- current published `TH-012 / ADR-0010 / S10`

## Frozen Historical Meaning

1. `DI-7` is the resolved follow-up to audit gaps and `DI-6` gate framing: it turns vague execution language into explicit gate checks, benchmark definitions, SLA targets, and testing-method rules.
2. The document inherits the gate skeleton from `DI-6` and the initial latency envelope from `DI-4`, then makes those earlier surfaces measurable instead of rhetorical.
3. The line-specific contribution is concentrated on Gate B precision, benchmark dimensions for editor infrastructure, the v0.3 SLA table, the two-layer verification model, and the explicit no-benchmark-CI decision.
4. Gate A precision and the exact Release Gate command suite are also resolved in the document, but they remain broader execution-policy material spanning multiple already-published theme lines.
5. `Q3` and `Q4` resolve repo-wide testing-methodology and migration rules for the rebased PR plan; they are not automatically part of the published layout-tree why-question.

## Frozen Boundary

- `DI-7` contributes line-specific Gate B precision plus performance-verification semantics to the published editor-infrastructure line.
- `DI-7` also contains broader gate-policy and testing-governance clauses that may remain explicit without becoming current line semantics.
- `DI-7` does not reopen the shell-ownership why-question, create a separate benchmark-only theme, or settle deferred SPI concerns.

## Gate Result

`DOC-015` is frozen as a mixed source: one line-specific append candidate for the published `TH-012` row, plus an explicit repo-wide gate/test policy bundle that may remain parked.
