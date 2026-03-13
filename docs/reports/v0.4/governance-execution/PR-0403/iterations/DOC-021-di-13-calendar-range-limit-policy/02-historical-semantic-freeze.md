# DOC-021 / 02 Historical Semantic Freeze

## Purpose and Boundary

Freeze what `DI-13` actually asks before later replay runs or implementation work reinterpret the calendar-range policy gap.

This stage must not:

1. treat any option in `Q1-Q3` as if the document had already chosen it;
2. let later workspace-topology or thin-client replay silently absorb this calendar contract question;
3. downgrade the silent-truncation evidence into generic bug noise.

## Frozen Source Reading

1. `DI-13` is header-marked `PENDING` and has no linked ruling or local resolved block.
2. The document fixes one concrete semantic tension: `calendar_list_by_range` inherits task-style pagination semantics even though Calendar range queries are expected to return the complete in-range projection.
3. The scope is intentionally narrow: default limit removal, optional safety cap, and API contract update strategy.
4. The source preserves concrete reproduction evidence from Issue `#46`: once the same range crosses 50 events, the calendar query begins silently truncating results.

## Freeze Result

Replay must preserve:

1. one explicit pending governance-question bundle covering `DN-341-DN-346`;
2. the Tasks-versus-Calendar semantics split as the reason this cannot be flattened into routine pagination tuning;
3. the fact that this run does not locally close the policy, even though later implementation or governance work may choose one of the recorded options.

## References

- [`../../../PR-0401/dn-ledger.md`](../../../PR-0401/dn-ledger.md)
- [`../../../PR-0401/surveys/DOC-021-survey.md`](../../../PR-0401/surveys/DOC-021-survey.md)
- [`../../../../../v0.3/design-discussions/DI-13-calendar-range-limit-policy.md`](../../../../../v0.3/design-discussions/DI-13-calendar-range-limit-policy.md)
