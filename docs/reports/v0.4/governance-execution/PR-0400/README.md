# PR-0400 Execution Log

- Date: 2026-03-10
- Status: Ready for Review
- Scope: archive legacy rulings, bootstrap canonical current-effective rulings registry, initialize governance execution workspace

## Actions Applied

1. Moved the pre-ADR rulings set from `docs/architecture/rulings/` to `docs/architecture/rulings-legacy/`.
2. Created a new canonical `docs/architecture/rulings/README.md` that declares the current-effective registry as intentionally empty after PR-0400.
3. Retargeted concrete ruling references across docs from `rulings/` to `rulings-legacy/`.
4. Updated entrypoint docs to distinguish `current-effective` rulings from the archived legacy snapshot.
5. Created the `docs/reports/v0.4/governance-execution/` directory skeleton for PR-0400 through PR-0406.

## Verification Results

1. `docs/architecture/rulings/` contains only `README.md`.
2. `docs/architecture/rulings-legacy/` contains 11 archived files.
3. `dart run ../../tools/ci/architecture_check.dart` passed on 2026-03-10 with 0 broken links and 0 architecture violations.

## Gate A Tracking

- Archive path defined: `docs/architecture/rulings-legacy/`
- current-effective path defined: `docs/architecture/rulings/`
- Legacy vs rebuilt boundary documented: yes
- Historical replay no longer depends on the old `rulings/` location: yes

## Supporting Document

- `governance-rulings-migration-and-rebuild.md`
