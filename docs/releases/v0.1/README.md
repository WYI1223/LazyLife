# v0.1 Release Plan

## Scope

v0.1 closes the minimum loop:

- capture notes
- search notes/tasks/events
- edit and schedule tasks
- Google Calendar event sync (incremental, mapped)

## Source

- original draft: `docs/research/init/temp-v0.1-plan.md`

## Optimization Review

The original PR list is valid. We applied these optimizations:

- Keep baseline order: Repo/DevEx -> CI -> FRB -> Core -> UI -> Integrations.
- Move global hotkey + floating quick-entry window out of v0.1 to v0.2.
- Split Google Calendar work into two PRs:
  - PR0014: OAuth + one-way bootstrap sync.
  - PR0015: two-way sync with `syncToken` and `extendedProperties` mapping.
- Keep CI early (PR0002) to prevent regressions while FRB/Core/UI are added.

## Execution Order

- PR0000, PR0001, PR0002
- PR0003, PR0004, PR0005
- PR0006, PR0007
- PR0008, PR0009, PR0010
- PR0011, PR0012, PR0013
- PR0014, PR0015, PR0016

## PR Specs

See `docs/releases/v0.1/prs/`.
