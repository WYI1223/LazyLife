# S7: Reminders Infrastructure

| Field | Value |
|------|------|
| Current Status | `active` |
| Rebuilt In | `PR-0403` |
| Historical Snapshot | [`../rulings-legacy/S7-reminders-infrastructure.md`](../rulings-legacy/S7-reminders-infrastructure.md) |
| Current ADR | [`../adr/ADR-0007-reminders-infrastructure.md`](../adr/ADR-0007-reminders-infrastructure.md) |

## Decision

Reminders are shared/core infrastructure rather than feature-local logic, and reminder scheduling follows Atom lifecycle changes instead of view-loading side effects.

## Normative Rules

1. Reminder infrastructure belongs in shared/core architecture rather than inside a single feature module.
2. Reminder scheduling and cancellation must be triggered by Atom lifecycle changes, not by view loading or controller refresh behavior.
3. A single shared reminder scheduler and notification channel is the correct current model.
4. App-start recovery must restore reminders for active timed atoms instead of depending on users opening a specific feature view.
5. Later bulk-delete cleanup may append to this line, but it does not invalidate the lifecycle-driven model.

## Current Interpretation

- Current architecture reads reminder behavior from lifecycle hooks and shared infrastructure placement first.
- Feature views may surface reminder state, but they are not the authoritative trigger source for scheduling.

## Open Edges

- Bulk-delete reminder cancellation hook
- Later platform-specific expansion details

## Traceability

- Historical source: [`../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md`](../../reports/v0.2.5/frontend-review/08b-semantic-decisions.md)
- Trigger source: [`../../reports/v0.2.5/frontend-review/08a-audit-findings.md`](../../reports/v0.2.5/frontend-review/08a-audit-findings.md)
- Journey record: [`../adr/ADR-0007-reminders-infrastructure.md`](../adr/ADR-0007-reminders-infrastructure.md)
