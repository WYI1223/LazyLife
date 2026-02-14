# PR-1009-api-compat-ci-gates

- Proposed title: `ci(governance): API compatibility gates and deprecation enforcement`
- Status: Planned

## Goal

Enforce deprecation-first API lifecycle policy with automated CI guards for extension/provider surfaces.

## Scope (v1.0)

In scope:

- CI checks for breaking API changes on stable surfaces
- deprecation window validation before removal
- compatibility report artifact on pull requests
- release gate integration for API-affecting changes

Out of scope:

- semantic diff tooling for all internal/private modules
- non-critical docs-only warning blockers

## Step-by-Step

1. Define stable API baseline snapshot format.
2. Add CI check for API diff classification.
3. Add enforcement for deprecation-before-removal policy.
4. Publish PR artifacts with compatibility summaries.

## Planned File Changes

- [add] `.github/workflows/api-compat.yml`
- [add] `tools/ci/api_compat_check/*`
- [edit] `docs/governance/API_COMPATIBILITY.md`
- [edit] `docs/governance/api-lifecycle-policy.md`

## Dependencies

- `PR-0218-api-lifecycle-policy`

## Verification

- CI dry run with synthetic breaking and deprecation-only PR scenarios

## Acceptance Criteria

- [ ] CI blocks breaking changes to stable API without approved migration path.
- [ ] Deprecation window rules are automatically enforced.
- [ ] Compatibility report is attached to API-impacting PRs.

