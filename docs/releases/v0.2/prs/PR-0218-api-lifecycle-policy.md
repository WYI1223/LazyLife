# PR-0218-api-lifecycle-policy

- Proposed title: `docs/governance: API lifecycle and deprecation-first policy`
- Status: Planned

## Goal

Set stable API lifecycle rules for extension and provider surfaces, aligned with backward-compatibility-first governance.

## Scope (v0.2)

In scope:

- API stability classes (`experimental`, `stable`, `deprecated`)
- deprecation window policy before removal
- version negotiation guideline for extension/provider contracts
- release note requirements for API-affecting changes

Out of scope:

- fully automated compatibility CI enforcement (planned in v1.0)

## Step-by-Step

1. Define lifecycle policy document and examples.
2. Update governance docs and PR checklist references.
3. Tag existing APIs by stability class where needed.
4. Add manual checklist for deprecation communication.

## Planned File Changes

- [edit] `docs/governance/API_COMPATIBILITY.md`
- [edit] `docs/governance/CONTRIBUTING.md`
- [edit] `docs/product/roadmap.md`
- [add] `docs/governance/api-lifecycle-policy.md`

## Dependencies

- `PR-0213-extension-kernel-contracts`

## Verification

- Docs link and policy consistency review

## Acceptance Criteria

- [ ] Lifecycle/deprecation policy is explicit and discoverable.
- [ ] Extension/provider API changes require policy-compliant notes.
- [ ] Governance docs reference one canonical lifecycle policy.

