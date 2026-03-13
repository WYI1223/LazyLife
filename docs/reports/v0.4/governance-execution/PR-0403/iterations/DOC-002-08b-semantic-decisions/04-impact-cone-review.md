# DOC-002 / 04 Impact Cone Review

## Purpose and Boundary

Identify the mainline publication surfaces that must change if `DOC-002` publishes.

This stage covers:

1. ADR and ruling output files;
2. topic-map row sync;
3. current architecture docs that should stop pointing at `rulings-legacy/`.

It does not rewrite historical PR, release, or DI records.

## Trigger and Inputs

- `DOC-002` freeze result
- override review result
- current `docs/architecture/adr/` and `docs/architecture/rulings/` shells
- current architecture backlinks to `rulings-legacy/S1-S8`

## Impact Cone

| Surface | Touched Scope | Reason |
|------|---------------|--------|
| `docs/architecture/adr/` | `ADR-0001` through `ADR-0008`, `topic-map.md`, `README.md` | First publish-complete retrospective ADR set and mainline theme rows |
| `docs/architecture/rulings/` | `S1` through `S8`, `README.md` | First rebuilt current-effective rule set |
| Current architecture docs | `data-model.md`, `note-schema.md`, `overview.md`, `sync-protocol.md`, selected module specs | These docs describe current architecture and should now backlink to rebuilt current rulings instead of legacy snapshots |
| Historical / release / DI docs | no direct sync in this run | They remain valid replay evidence and should keep legacy references until later governance work decides otherwise |

## Gate Result

Impact review is large but bounded. No extra governance escalation is required because:

1. all touched current-doc backlinks are straightforward carrier swaps;
2. no historical evidence file needs rewriting to publish `DOC-002`;
3. mainline `topic-map.md` can receive these rows because `07` and `08` publish real assets in the same run.

## References

- [`../../../../../../architecture/adr/README.md`](../../../../../../architecture/adr/README.md)
- [`../../../../../../architecture/rulings/README.md`](../../../../../../architecture/rulings/README.md)
