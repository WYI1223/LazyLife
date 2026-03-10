# Current-Effective Rulings Registry

> Canonical home for rulings rebuilt by the v0.4 governance workflow.
> After PR-0400, this directory intentionally starts as an empty set.

## Status

- Current-effective rebuilt rulings: none yet
- Legacy snapshot: `../rulings-legacy/README.md`
- Expected population path: PR-0402 through PR-0405

## Boundary

1. `docs/architecture/rulings/` contains only rulings rebuilt and re-activated through the ADR governance workflow.
2. `docs/architecture/rulings-legacy/` preserves the historical S1-S9/E1 snapshot for replay, audit, and source-corpus extraction.
3. Historical documents may continue to cite `rulings-legacy/` while governance replay is in progress.
4. New or changed binding rules must land in this directory, not in `rulings-legacy/`.

## Next Activation Steps

1. PR-0401: source corpus + decision-node extraction
2. PR-0402: ADR infrastructure + metadata contract
3. PR-0403: first batch of retrospective ADR execution
4. PR-0404 / PR-0405: closure audit and governance activation
