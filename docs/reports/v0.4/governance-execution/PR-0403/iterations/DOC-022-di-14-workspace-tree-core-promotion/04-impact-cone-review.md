# DOC-022 / 04 Impact Cone Review

## Purpose and Boundary

Identify every surface that `DOC-022` is allowed to touch.

## Direct Impact Surfaces

| Surface | Expected Action | Why |
|------|------|------|
| `ADR-0009-cross-feature-infrastructure-placement.md` | append | `DI-14` adds workspace-tree core-promotion and query-boundary detail under the existing placement line |
| `S9-cross-feature-infrastructure-placement.md` | update current ruling text | the published placement line must reflect the new workspace-tree interpretation |
| mainline `topic-map.md` row `TH-011` | sync notes and semantics | current registry row must reflect the new append result |
| `topic-map-working-copy.md` row `TH-011` | sync notes and semantics | working copy must match mainline after append |
| `dn-ledger-classification.md` | classify append row and non-carrier outcomes | replay working copy must record the `DOC-022` result |
| `open-items.md` | record the migrated `DI-17` follow-up bundle | `Q3-Q5` must remain explicit after this run |
| `doc-run-queue.md`, `README.md`, `iterations/README.md` | advance queue and execution status | sequential replay state must remain accurate |
| `workspace-tree-service.md` | append module-level interpretation note | current architecture module doc should reflect the new placement-line detail |

## Out Of Cone

This run must not:

1. create a new ADR filename;
2. create a new ruling filename;
3. publish any `DI-17`-owned answer;
4. mutate `TH-012` or the parked `DOC-020` topology parent bundle.

## Result

`DOC-022` is a single-line append run plus one explicit migration-boundary carry-forward bundle.
