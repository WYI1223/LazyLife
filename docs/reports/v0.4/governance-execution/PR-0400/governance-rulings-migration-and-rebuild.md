# Governance Rulings Migration And Rebuild

- Date: 2026-03-10
- Owner: v0.4 governance workflow
- Scope: PR-0400 Gate A archive policy

## Purpose

Define the migration boundary between the archived pre-ADR rulings snapshot and the future rebuilt current-effective rulings registry.

## Archive Policy

1. The pre-ADR rulings baseline is archived under `docs/architecture/rulings-legacy/`.
2. Archived files preserve their original filenames to keep source-corpus extraction stable.
3. Historical, replay, and source-corpus documents should cite `rulings-legacy/` while governance reconstruction is in progress.

## Rebuild Policy

1. `docs/architecture/rulings/` is reserved for rebuilt current-effective rulings only.
2. PR-0400 leaves `docs/architecture/rulings/` with a README-only empty-set baseline.
3. Later governance PRs may populate `docs/architecture/rulings/` only after ADR workflow outputs are ready for activation.

## Boundary Rule

1. `rulings-legacy/` is historical reference, not the live binding registry after governance activation.
2. `rulings/` is the only target for new or modified binding rules.
3. Replay and audit workflows must not derive current-effective state from the archived location.

## Gate A

- [x] Archive path defined: `docs/architecture/rulings-legacy/`
- [x] current-effective path defined: `docs/architecture/rulings/`
- [x] Naming rule fixed: archived filenames unchanged
- [x] Legacy vs rebuilt responsibility boundary documented
- [x] Historical replay no longer depends on the old `docs/architecture/rulings/` file set
