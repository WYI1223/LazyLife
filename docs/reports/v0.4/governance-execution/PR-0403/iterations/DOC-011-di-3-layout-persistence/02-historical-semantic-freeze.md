# DOC-011 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the historical meaning of `DOC-011 / DI-3` before classification.

This stage must not:

1. import later `DI-4` content-loading detail into the frozen meaning of `DI-3`;
2. back-project `DI-6` gate framing or `DI-7` SLA/test language into the source document;
3. reinterpret `DI-3` as a shell-ownership or placement line that the source never claimed to answer.

## Trigger and Inputs

- source doc [`../../../../../../reports/v0.3/design-discussions/DI-3-layout-persistence.md`](../../../../../../reports/v0.3/design-discussions/DI-3-layout-persistence.md)
- `PR-0401` survey [`../../../PR-0401/surveys/DOC-011-survey.md`](../../../PR-0401/surveys/DOC-011-survey.md)
- `PR-0401` DN baseline for `DOC-011`
- current published `TH-012 / ADR-0010 / S10`

## Frozen Historical Meaning

1. `DI-3` is a resolved follow-up to `DI-2`: it starts only after node structure is fixed and then decides how the same layout model persists and restores across app restarts.
2. `D7` fixes standalone JSON persistence at `%APPDATA%/LazyLife/workspace_layout.json`, separate from `settings.json`, with one-second debounced writes, atomic write / temp-file recovery, and a serialization scope that keeps tree structure and tab shells together.
3. `D8` fixes migration as a one-shot replacement because there is no older on-disk layout file that requires backward conversion.
4. `D9` fixes pane growth at a hard cap of eight panes with no explicit depth cap, combining a pre-resolve pane-count check with post-resolve minimum-size validation.
5. `DI-3 ↔ DI-4` fixes a two-stage restore boundary: `DI-3` owns phase-1 structure restore in the critical path; `DI-4` owns phase-2 content loading after DB readiness.

## Frozen Boundary

- `DI-3` contributes persistence, migration, pane-limit, and staged-restore-boundary meaning.
- `DI-4` stage-2 loading behavior stays outside the frozen source meaning here.
- Later gate or SLA documents may reference `DI-3`, but they do not become part of this document's historical semantics.

## Gate Result

`DOC-011` is frozen as a historical persistence-and-restore source for the already-published layout-tree line.
