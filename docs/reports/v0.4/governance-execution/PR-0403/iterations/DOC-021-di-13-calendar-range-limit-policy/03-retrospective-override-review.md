# DOC-021 / 03 Retrospective Override Review

## Purpose and Boundary

Compare `DI-13` against current published lines and later replay sources before any carrier decision is made.

This stage must not:

1. append the pending calendar-range question into an unrelated published line just because Calendar already appears in `TH-001` or later workspace documents;
2. treat the existence of plausible options as equivalent to a chosen stable why-question;
3. assume `DOC-022+` workspace replay closes this calendar query policy gap.

## Current Published-Line Check

1. No current published row answers the specific policy question captured by `DI-13`: whether `calendar_list_by_range` should keep a default limit, what upper-bound semantics should apply, and how that change should be classified in API governance.
2. `TH-001` governs atom projection semantics, not Calendar range-query completeness policy.
3. No published ADR or ruling currently fixes default-limit semantics for Calendar range queries.

## Later-Source Override Check

| Later Source / Boundary | Review Result |
|------|------|
| `DOC-022-DOC-026` workspace-tree and thin-client chain | These later documents replay workspace topology, service, FFI, and thin-client boundaries. They do not locally answer the Calendar range-limit governance choice from `DI-13`. |
| later implementation PRs for calendar query behavior | Implementation work may eventually consume this pending bundle, but `DI-13` itself remains unresolved until a later source explicitly chooses one option and updates the API contract semantics. |
| `PR-0404` audit | Audit can verify visibility and carry-forward correctness, but it is not a substitute for the missing local policy decision. |

## Override Result

`DOC-021` should preserve:

1. one explicit pending governance-question bundle;
2. zero publish-complete theme rows in this run;
3. zero implicit handoff of the decision into the later workspace-tree chain.

## References

- [`02-historical-semantic-freeze.md`](02-historical-semantic-freeze.md)
- [`../../dn-ledger-classification.md`](../../dn-ledger-classification.md)
- [`../../../../../v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md`](../../../../../v0.3/design-discussions/DI-14-workspace-tree-core-promotion.md)
