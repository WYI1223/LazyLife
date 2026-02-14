# PR-1008-ios-plugin-distribution-policy

- Proposed title: `docs+ops(iOS): official plugin repo, whitelist, and signing policy`
- Status: Planned

## Goal

Define and operationalize iOS-compatible plugin distribution governance to satisfy platform restrictions.

## Scope (v1.0)

In scope:

- official plugin repository policy
- whitelist and trust-level model
- plugin signing and verification policy
- review and release workflow documentation

Out of scope:

- fully automated app-store-side plugin delivery
- unrestricted sideload policy guarantees on iOS

## Step-by-Step

1. Define repository/whitelist/signing governance docs.
2. Define plugin submission and review checklist.
3. Add verification hooks in release process docs.
4. Add failure and revocation procedures.

## Planned File Changes

- [add] `docs/governance/plugin-distribution-policy.md`
- [edit] `docs/governance/CONTRIBUTING.md`
- [edit] `docs/releases/v1.0/README.md`
- [edit] `README.md`

## Dependencies

- `PR-1007-plugin-sandbox-runtime`

## Verification

- docs workflow walkthrough and release checklist dry run

## Acceptance Criteria

- [ ] iOS plugin distribution constraints are explicitly addressed by policy.
- [ ] Whitelist/signing workflow is documented and actionable.
- [ ] Revocation path is documented for compromised plugins.

