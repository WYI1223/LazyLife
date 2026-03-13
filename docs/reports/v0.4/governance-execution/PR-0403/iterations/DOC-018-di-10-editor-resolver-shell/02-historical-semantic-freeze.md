# DOC-018 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the historical meaning of `DOC-018 / DI-10` before classification.

This stage must not:

1. import later rich editor-mode or thin-client work into the frozen source meaning;
2. split resolver-shell detail into a fake third carrier between the existing shell and placement lines;
3. treat the DI-4 bridge handoff as if `DI-10` had already re-ruled it locally.

## Trigger and Inputs

- source doc [`../../../../../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md`](../../../../../../reports/v0.3/design-discussions/DI-10-editor-resolver-shell.md)
- `PR-0401` survey [`../../../PR-0401/surveys/DOC-018-survey.md`](../../../PR-0401/surveys/DOC-018-survey.md)
- `PR-0401` DN baseline for `DOC-018`

## Frozen Historical Meaning

`DI-10` is frozen as a resolved resolver-shell design source with four explicit claims:

1. `EditorResolver` is the middle layer between shell-owned state and feature-owned chrome;
2. the pane interface is limited to `BuildContext` plus `EditBuffer`-derived inputs and explicitly excludes pane-placement and feature-controller concerns;
3. registration is an explicit `Map + register()` protocol and unsupported `content_type` values must render a visible placeholder rather than silently fallback to markdown;
4. resolver infrastructure belongs under `lib/core/editor/`, while future `View Mode` expansion remains reserved and `EditBuffer` bridge mechanics remain owned by `DI-4`.

## Boundary Notes

1. `DI-10` does not create a new independent why-question apart from the already-published shell and placement lines.
2. `content_type` taxonomy is inherited from `S1`, not redefined here.
3. `View Mode` remains a future edge, not a locally closed v0.3 contract.
4. The bridge mixin discussion is preserved only as a handoff note to `DI-4`.

## Freeze Result

`DOC-018` is frozen as a dual-append source for the published shell and placement lines, with one explicit future edge left open.
