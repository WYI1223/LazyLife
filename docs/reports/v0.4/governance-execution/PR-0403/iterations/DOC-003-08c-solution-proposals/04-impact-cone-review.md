# DOC-003 / 04 Impact Cone Review

## Purpose and Boundary

Identify the publication surfaces that may change if `DOC-003` is classified into append, park, or later-governance outcomes.

## Trigger and Inputs

- `03-retrospective-override-review.md`
- `PR-0403` working copies
- currently published `ADR-0001` through `ADR-0008`
- current mainline `topic-map.md`

## Impact Surfaces

| Surface | Potential Impact | Why It Matters |
|------|------------------|----------------|
| `docs/architecture/adr/ADR-0002-editor-shell-ownership.md` | likely append candidate | `3.1.1` and `3.1.3` extend the execution path for the shell-ownership line |
| `docs/architecture/adr/ADR-0007-reminders-infrastructure.md` | likely append candidate | `3.1.4` extends the execution path for the reminders line |
| `docs/architecture/adr/topic-map.md` | maybe no row change, maybe notes-only change later | append evidence may enrich existing rows without creating a new published theme immediately |
| `PR-0403/dn-ledger-classification.md` | required | mixed append vs governance-seed classification must be made explicit here |
| `PR-0403/open-items.md` | likely | deferred or governance-seed clauses may need carry-forward notes |

## Non-Impacted Surfaces By Default

1. current rebuilt rulings `S1-S8` do not need automatic changes just because `08c` proposed execution work;
2. historical source documents must remain untouched;
3. no new mainline ADR should be created unless `05` proves a truly distinct stable why-question not already covered by the published set.

## Classification Risk

The main risk in `DOC-003` is over-promotion:

1. `3.1.x` contains append-worthy execution evidence for existing lines;
2. `3.2.x` contains early guardrail proposals that are likely better replayed against later governance sources before publication;
3. `3.3.x` contains doc-sync backlog and negative evidence that should stay explicit, but not automatically become new ADR carriers.

## Gate Result

Impact-cone review confirms that `DOC-003` cannot be flattened into a single append or a single new theme. `05 DN classification to decision line` must separate:

1. append candidates for existing published lines;
2. park-later or governance-seed clauses;
3. context-only or negative-evidence clauses.
