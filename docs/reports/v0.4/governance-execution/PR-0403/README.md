# PR-0403 Execution Log

- Date: 2026-03-10
- Execution Status: In Progress
- Spec Review Status: Review-clean
- Scope: planning kickoff only; single-active-doc replay contract, working-copy/mainline separation, topic rows only emerge inside active doc runs

## Planning Status

This PR has entered planning kickoff, but actual per-document replay has not started yet.

Current state:

1. the PR-0403 spec has been rewritten into a strict stepwise execution contract;
2. the execution model is now single-active-doc, and `TH` rows may only be created or updated inside `05 DN classification to decision line`;
3. the boundary between execution-layer working copies and mainline publication surfaces is now explicit;
4. actual `doc-run-queue.md`, classification working copies, iteration records, ADR files, and rebuilt rulings are not created yet.

## Planned Execution Order

1. Bootstrap a single-active-doc run queue ordered by `Time Position`, with `DOC-001 / 08a` as context-only input and `DOC-002 / 08b` as the earliest decision-source start.
2. Derive `dn-ledger-classification.md` and `topic-map-working-copy.md`.
3. Run one active document group at a time through `02 -> 08`, and only pick the next doc after the current run reaches a terminal state.
4. Allow `TH` row creation or update only inside `05 DN classification to decision line`; there is no standalone pre-run theme-creation step.
5. Publish only publish-complete ADR / ruling pairs and selectively sync rows back to mainline `docs/architecture/adr/topic-map.md`.
6. Record all parked docs, split / merge disputes, deviations, and accepted debt in `open-items.md`.

## Carry-Forward Boundary

1. No real replay artifacts should be created before `doc-run-queue.md` and the working copies exist.
2. No mainline `topic-map.md` row should be added before a document run reaches publish-complete ADR / ruling state.
3. If execution discovers a gap in the PR-0402 contract, record a deviation first; do not silently rewrite the contract while replay is in progress.
