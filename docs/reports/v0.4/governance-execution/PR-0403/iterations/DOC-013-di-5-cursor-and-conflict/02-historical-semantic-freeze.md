# DOC-013 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the historical meaning of `DOC-013 / DI-5` before classification.

This stage must not:

1. inflate a confirmatory DI into a fake new architecture layer;
2. import later `DI-10` editor-resolver or richer editor-mode content into the frozen source meaning;
3. treat the undo/redo placeholder as if `DI-5` had already resolved it.

## Trigger and Inputs

- source doc [`../../../../../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md`](../../../../../../reports/v0.3/design-discussions/DI-5-cursor-and-conflict.md)
- `PR-0401` survey [`../../../PR-0401/surveys/DOC-013-survey.md`](../../../PR-0401/surveys/DOC-013-survey.md)
- `PR-0401` DN baseline for `DOC-013`

## Frozen Historical Meaning

`DI-5` is frozen as a confirmatory design discussion with three explicit semantic claims:

1. cursor independence is already logically determined by the DI-4 bridge model and by per-pane controller ownership;
2. no dedicated local conflict-handling subsystem is required inside the current single-process, single-focus edit model;
3. sync-frequency policy is inherited from `DI-4` and does not receive a new local ruling here.

## Boundary Notes

1. `DI-5` does not create a new carrier apart from the published shell-ownership line.
2. Provider-driven or remote push conflict models stay outside the frozen source meaning.
3. Cross-pane undo/redo remains an explicit later item rather than a resolved part of this document.

## Freeze Result

`DOC-013` is frozen as a historical confirmation-and-boundary source for the existing shell line, not as a new line generator.
