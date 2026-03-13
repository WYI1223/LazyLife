# DOC-012 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the historical meaning of `DOC-012 / DI-4` before classification.

This stage must not:

1. import later `DI-10` editor-resolver shell work or `DI-18` thin-client cleanup into the frozen meaning of `DI-4`;
2. back-project `DI-6` / `DI-7` gate or SLA language into the source document;
3. split the source into fake separate documents when the original DI deliberately grouped D10, D11, D12, and Q4 under one buffer-sync and staged-loading discussion.

## Trigger and Inputs

- source doc [`../../../../../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md`](../../../../../../reports/v0.3/design-discussions/DI-4-buffer-sync-model.md)
- `PR-0401` survey [`../../../PR-0401/surveys/DOC-012-survey.md`](../../../PR-0401/surveys/DOC-012-survey.md)
- `PR-0401` DN baseline for `DOC-012`
- current published `TH-008 / ADR-0002 / S2`
- current published `TH-012 / ADR-0010 / S10`

## Frozen Historical Meaning

1. `DI-4` resolves the unfinished shell follow-up from `DI-1` by fixing the authoritative per-atom `EditBuffer` model, the transport granularity, and the bridge between buffer state and editor widgets.
2. `D10` fixes centralized per-atom buffer ownership, real-time synchronization, consumer-layer debounce policy, and a future-compatible multi-mode editing protocol.
3. `D11` fixes full-string content as the source of truth, with `EditOp` reserved as an optional optimization hint rather than a replacement for authoritative buffer state or persistence.
4. `D12` fixes the direct `EditBuffer ↔ TextEditingController` bridge around manual listeners, string-comparison guards, and ready/loading/error phase discipline.
5. `Q4` completes the DI-3 staged-restore story by defining when phase-2 loading starts, who owns loading, how active vs inactive tabs are scheduled, and how load failures are normalized.
6. `Q5` closes the audit's prototype recommendation by explicitly deciding that deeper documentation is sufficient and that a separate prototype branch is not required.

## Frozen Boundary

- `DI-4` extends both the shell-ownership line and the staged-restore line.
- It does not reopen `DI-2` layout structure choices.
- It does not replace `DI-3` phase-1 restore; it consumes that boundary and defines the phase-2 side.

## Gate Result

`DOC-012` is frozen as a historical buffer-sync and staged-loading source whose outputs must be classified against existing published lines rather than treated as a greenfield theme set.
