# CI Duplication Policy Promotion Workflow

- Owner: `PR-0403` replay output, consumed by `PR-0407`
- Status: active handoff contract
- Last Updated: 2026-03-12

## Purpose and Boundary

This document solves one specific handoff problem:

`DOC-029 / DI-21` resolved the cross-feature duplication-detection policy semantically, but `PR-0403` intentionally did not publish current CI-governance surfaces because the corresponding `architecture_check.dart` behavior is not landed yet.

This workflow tells `PR-0407`:

1. what `DI-21` bundle is already accepted;
2. what the implementation PR must update while landing it;
3. when current CI-governance sync is finally allowed.

This workflow must not be used to:

1. bypass `PR-0403` replay records;
2. claim `DI-21` is already landed while `architecture_check.dart` still lacks the detector or output contract;
3. hide partial CI landing by treating it as equivalent to full policy closure.

## Current Replay Decision

`DOC-029 / DI-21` ends with explicit no-publication handling:

| Bundle | Source | Current Replay Status | Carry-Forward ID |
|------|------|------|------|
| Rule E extension, DI-17 relation, and general-governance path | `DN-604-DN-606` | `accepted-but-unlanded governance bundle` | `OI-051` |
| Detector algorithm, threshold, scan boundary, and allowlist contract | `DN-607-DN-610` | `accepted-but-unlanded detection bundle` | `OI-052` |
| Three-layer failure output, check 1-3 reinforcement, and hardcoded reference strategy | `DN-611-DN-615` | `accepted-but-unlanded output-contract bundle` | `OI-053` |

Authoritative references:

- [`iterations/DOC-029-di-21-ci-duplication-detection/05-dn-classification-to-decision-line.md`](iterations/DOC-029-di-21-ci-duplication-detection/05-dn-classification-to-decision-line.md)
- [`open-items.md`](open-items.md)
- [`dn-ledger-classification.md`](dn-ledger-classification.md)

## Rule for PR-0407

`PR-0407` is the first allowed implementation and sync surface for `DI-21`.

Until `PR-0407` lands the required behavior, the repo must treat `DI-21` as:

- `accepted policy direction`
- `implementation not yet landed`
- `not yet reflected in current CI-governance surfaces`

Current publication is blocked for these surfaces until the promotion gate below is satisfied:

1. `tools/ci/architecture_check.dart`
2. `tools/ci/duplication_allowlist.yaml` or the equivalent landed allowlist surface chosen by `PR-0407`
3. `docs/architecture/engineering-standards.md`

## Required Update Workflow

`PR-0407` must do all four:

1. land its assigned implementation slice;
2. update the coverage ledger in this document;
3. reference the exact updated row in its PR spec or execution notes;
4. sync the landed policy surface into current docs only after the corresponding behavior exists in repo.

If `PR-0407` lands code but does not update this ledger, the handoff is incomplete.

## Shared Governance Decision Point

This workflow ledger is not the final promotion decision surface.

The shared governance decision point is:

- [`../carrier-promotion-decision-register.md`](../carrier-promotion-decision-register.md)

Update rule:

1. `PR-0407` updates this workflow ledger with landed or partial evidence;
2. `PR-0404` records the current audit decision in the shared register;
3. `PR-0405` consumes the same register for final closeout if anything remains blocked or needs explicit carry-forward.

## Landing Coverage Ledger

| PR | Landing Surface | Carry-Forward Inputs | Required Update In This File | Policy Effect |
|------|------|------|------|------|
| `PR-0407` | Rule E extension sync, duplication detector, allowlist mechanism, and CI failure-output reinforcement | `OI-051`, `OI-052`, `OI-053` | mark governance-rule, detector-and-allowlist, and output-contract coverage as landed or partial, with evidence path | current CI-governance sync becomes allowed only for landed rows |

## Coverage Ledger Template

`PR-0407` updates the relevant row(s) using this format:

| Slice ID | Owned By | Status | Evidence | Notes |
|------|------|------|------|------|
| `governance-rule-surface` | `PR-0407` | `pending` | `pending` | Rule E extension and DI-21 reference are not yet reflected in current CI-governance docs |
| `detector-and-allowlist` | `PR-0407` | `pending` | `pending` | `architecture_check.dart` still lacks the landed duplication detector and its allowlist surface |
| `output-contract` | `PR-0407` | `pending` | `pending` | Check output still lacks the landed WHAT-WHY-HOW duplication output and the planned reinforcement for existing checks |

## Promotion Gate

Current CI-governance sync is allowed only when all of the following are true:

1. `governance-rule-surface`, `detector-and-allowlist`, and `output-contract` are all marked `landed`;
2. `architecture_check.dart` passes with the landed detector/output behavior in repo;
3. the landed rule surface is synchronized into current docs with evidence;
4. `PR-0407` explicitly records the update in this workflow and its own execution notes.

Until all four are satisfied:

- `PR-0403` keeps `OI-051`, `OI-052`, and `OI-053` explicit;
- no current CI-governance sync may claim `DI-21` is already landed;
- `PR-0404` may only audit the handoff state, not promote it.

## Promotion Owner

Default rule:

1. `PR-0403` records the accepted-but-unlanded policy bundles;
2. `PR-0407` lands the detector, allowlist, and output behavior;
3. `PR-0407` performs the first current CI-governance sync if the promotion gate is satisfied.

No ADR, ruling, or topic-map publication is expected for `DI-21`.

## Reference Documents

- [`open-items.md`](open-items.md)
- [`dn-ledger-classification.md`](dn-ledger-classification.md)
- [`../carrier-promotion-decision-register.md`](../carrier-promotion-decision-register.md)
- [`iterations/DOC-029-di-21-ci-duplication-detection/05-dn-classification-to-decision-line.md`](iterations/DOC-029-di-21-ci-duplication-detection/05-dn-classification-to-decision-line.md)
- [`../../../../releases/v0.4/prs/PR-0407-ci-duplication-detection.md`](../../../../releases/v0.4/prs/PR-0407-ci-duplication-detection.md)
