# DOC-019 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze the source semantics of `DI-11` before replay classification.

This stage must preserve the document's mixed state rather than flatten it into one fake closure:

1. the `AtomType -> ViewHint` rename is recorded as the resolved line;
2. the `atom_create` contract and migration plan are already accepted as a v0.4 direction, but remain unlanded in the repo;
3. the `Pending` semantics section remains a later consensus draft rather than a landed current rule.

## Trigger and Inputs

- source doc [`../../../../../../reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md`](../../../../../../reports/v0.3/design-discussions/DI-11-atomtype-rename-impact.md)
- survey [`../../../PR-0401/surveys/DOC-019-survey.md`](../../../PR-0401/surveys/DOC-019-survey.md)
- extraction baseline [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)

## Frozen Historical Read

1. `DI-11` is header-marked `RESOLVED`; that resolved state clearly covers the naming-convergence decision and also records an accepted `atom_create` direction that is still not landed, while later `Pending` semantics remain less closed than the rename itself.
2. The source explicitly distinguishes three layers:
   - resolved rename semantics and rename maps;
   - a later accepted-but-unlanded `atom_create` contract and phased migration plan;
   - a still-later `Pending` semantics consensus and follow-up question set.
3. The source also records current-state constraints and blast-radius estimates that are useful replay evidence, but they do not by themselves justify current publication.

## Freeze Result

`DOC-019` enters replay as one mixed source with:

1. one resolved naming line that may append to an existing published carrier;
2. one accepted-but-unlanded `atom-first API` bundle that must remain explicit if not published;
3. one later `Pending semantics` bundle that must remain explicit if not published;
4. one execution-only context bundle.

## References

- [`03-retrospective-override-review.md`](03-retrospective-override-review.md)
