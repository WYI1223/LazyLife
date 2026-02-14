# PR-0211-docs-language-policy-and-index

- Proposed title: `docs(governance): canonical English policy and docs entry index`
- Status: Planned

## Goal

Formalize documentation language policy and provide a stable docs navigation entrypoint.

## Scope (v0.2)

In scope:

- set English as canonical documentation source
- define translation policy and lag disclaimer rules
- add docs entry page (`docs/index.md`)
- ensure repository README points to docs index

Out of scope:

- full translated docs tree rollout
- automated translation completeness enforcement

## Source Reference

This PR operationalizes:

- `docs/research/todo_Documentation_language_policy.md`

## Step-by-Step

1. Add policy text to governance contribution docs.
2. Add canonical docs index page and section navigation.
3. Add translation header template for future localized docs.
4. Update README/docs links to canonical entrypoint.

## Planned File Changes

- [edit] `CONTRIBUTING.md`
- [edit] `docs/governance/CONTRIBUTING.md`
- [add] `docs/index.md`
- [edit] `README.md`
- [edit] `docs/research/todo_Documentation_language_policy.md` (status mapping note)

## Verification

- Manual link check for docs entry navigation.
- CI docs changes remain consistent with repository policies.

## Acceptance Criteria

- [ ] Canonical docs language policy is explicit and discoverable.
- [ ] `docs/index.md` exists and is linked from README.
- [ ] Translation guidance format is documented.

