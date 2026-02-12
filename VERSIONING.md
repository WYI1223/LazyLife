# Versioning Policy

This project uses Semantic Versioning (`SemVer`): `MAJOR.MINOR.PATCH`.

## Version Rules

- `MAJOR`: breaking changes.
- `MINOR`: new backward-compatible functionality.
- `PATCH`: backward-compatible bug fixes.

Notes:

- Documentation-only changes usually do not require a separate release.
- If multiple change types are included, bump by the highest-impact change.

## Pre-release

Pre-release tags may be used before a stable release:

- `vX.Y.Z-alpha.N`
- `vX.Y.Z-beta.N`
- `vX.Y.Z-rc.N`

## Tag Convention

- Git tags are the source of truth for released versions.
- Tag format: `vX.Y.Z` (example: `v0.1.0`).

## Branch Strategy (Simple)

- `main`: default integration branch.
- `feat/*`, `fix/*`, `chore/*`, `docs/*`: working branches.
- optional `release/vX.Y.Z`: release hardening branch when needed.

## Release Flow (Current)

1. Confirm release scope in `docs/releases/`.
2. Update the version entry in `CHANGELOG.md`.
3. Merge to `main` and create tag `vX.Y.Z`.
4. Trigger `release.yml` workflow (to be refined over time).

## Commit/PR Requirement

- Commits must follow Conventional Commits.
- PRs must pass CI and include required documentation updates.

## Hotfix

- Branch from `main` using `fix/*` for urgent fixes.
- After merge, bump `PATCH` and update `CHANGELOG.md`.
