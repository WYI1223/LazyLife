# ADR Metadata Contract

> Finalized by `PR-0402` for retrospective ADR publication in the v0.4 governance workflow.
> This contract defines the minimum metadata, declaration, section skeleton, and revision rules that downstream ADR execution must obey.

## Purpose and Boundary

This contract answers only four questions:

1. what metadata fields every retrospective ADR must carry;
2. how `Reconstruction Notice`, `Corpus Coverage Declaration`, and `Revision Record` must be expressed at minimum;
3. what section skeleton every retrospective ADR must preserve;
4. which revisions remain allowed during the migration window and which changes must be escalated back into governance review.

This contract does not decide:

1. which themes are admitted into the first publication batch;
2. the final numbering or slug of each `ADR-000X-<slug>.md`;
3. the full `Native ADR` template for post-activation workflow;
4. the final visual presentation of `topic-map.md`.

## Classification Rule

Within the current v0.4 governance replay window, the ADRs created first must be classified as:

- `Retrospective Reconstruction ADR`

Every such ADR must explicitly state:

1. it is reconstructed from a known `source corpus`;
2. it is written from a future perspective;
3. it is not a contemporaneous original record;
4. the linked `Current Normative Source` remains the current normative authority;
5. append-only does not automatically apply to it.

`Native ADR` remains outside this contract's direct template scope and only becomes active after governance activation.

## ADR Admission Gate

A retrospective ADR may be admitted only when governance replay can prove both:

1. a stable why-question; and
2. an independently traceable decision line.

Raw source volume, document count, or general topic importance is not enough by itself.

## Required Metadata

| Field | Required | Purpose | Notes |
|------|----------|---------|-------|
| `Document Class` | Yes | Distinguishes retrospective reconstruction from native ADR | Current batch is fixed to `Retrospective Reconstruction ADR` |
| `Narrative Perspective` | Yes | Makes the future-perspective retelling explicit | Must not be omitted |
| `Decision Line` | Yes | States the stable `why-question` answered by the ADR | Must align with topic-map `Stable Why-Question` |
| `Coverage Scope` | Yes | Declares what phases are covered and where the narrative stops | May explicitly list exclusions |
| `Current Normative Source` | Yes | Points to the current-effective normative anchor | Usually a rebuilt `Ruling` |
| `Source Corpus Summary` | Yes | Summarizes the primary sources actually consumed | No need to paste full text |
| `Corpus Coverage Declaration` | Yes | Declares which source classes were covered and how fully | See dedicated section below |
| `Journey Timeline / Phases` | Yes | Organizes the decision journey in time order | Must preserve chronology |
| `Current State` | Yes | Explains how the topic should be interpreted today | Must backlink to the current normative source |
| `Open Edges` | Yes | Records unresolved boundaries, handoffs, or future follow-up | Must not be silently dropped |
| `Revision Record` | Yes | Records source recovery, corrections, and boundary repairs | Every allowed post-publication edit must update this field |

## Standard Reconstruction Notice

Every retrospective ADR must begin with a standard reconstruction notice. A minimum compliant shape is:

```md
> 本文为历史补录 ADR，于 <date> 基于列明的 `source corpus`
> 以未来视角重建该决策线，不是当期原始记录。
> 当前规范解释以所链接的 `Current Normative Source` 为准。
```

Minimum requirements:

1. it must explicitly say the document is a historical reconstruction;
2. it must explicitly say the narrative is written from a future perspective;
3. it must explicitly say the document is not a contemporaneous original record;
4. it must explicitly say the current interpretation follows the linked `Current Normative Source`.

## Corpus Coverage Declaration

Every retrospective ADR must declare source-corpus coverage by source class rather than just pasting a loose source list.

### Coverage Classes

| Coverage Class | Allowed Status | Meaning |
|------|------|------|
| `Trigger Source` | `present` / `absent` / `not_applicable` | Whether trigger or audit inputs are included |
| `Decision Source` | `present` / `absent` / `not_applicable` | Whether DI / semantic decision sources are included |
| `Normative Source` | `present` / `partial` / `absent` | Whether current normative anchors are included |
| `Execution / Closure Source` | `present` / `absent` / `not_applicable` | Whether PR / acceptance / release closure evidence is included |
| `Superseded / Redirected Source` | `present` / `absent` / `not_applicable` | Whether supersede / redirect trajectory is included |

### Recommended Table Shape

| Coverage Class | Present Sources | Status | Notes |
|------|------|------|------|

### Constraints

1. if a known critical source class exists, it must not be silently omitted;
2. if status is `absent` or `partial`, `Notes` must explain why;
3. if status is `partial`, `Notes` must state what follow-up phase is expected to close the gap.

## Standard Section Skeleton

Every retrospective ADR must include at least the following sections:

1. `Reconstruction Notice`
2. `Decision Line`
3. `Source Corpus`
4. `Corpus Coverage Declaration`
5. `Journey Timeline / Phases`
6. `Current State`
7. `Open Edges`
8. `Revision Record`

Topic-specific sections may be added, but these minimum sections may not be removed.

## Revision Rules During Migration Window

During the governance migration window defined by `DI-20`, retrospective ADRs may be revised in a controlled way, but only under the following rules:

1. every revision must update `Revision Record`;
2. allowed reasons are limited to:
   - adding newly recovered primary sources;
   - correcting factual mistakes;
   - correcting phase boundaries;
   - backfilling superseded / redirected trajectory;
3. silent narrative rewrites are not allowed;
4. if a revision changes `Decision Line`, `Current Normative Source`, or theme boundary, the change must be escalated back to governance review instead of being applied as an ordinary correction.

After governance activation, retrospective ADRs move into a "frozen but correctable" state:

1. errata remain allowed;
2. newly discovered primary sources may still be added;
3. free-form journey rewrites remain disallowed.

## Theme Map Alignment

Retrospective ADRs must align at minimum with the following topic-map fields:

| ADR Field | Topic-Map Field |
|------|------|
| `Decision Line` | `Stable Why-Question` |
| `Current Normative Source` | `Current Normative Source` |
| `Journey Timeline / Phases` | `First Seen In Corpus`, `Supersedes / Redirected By`, `Notes` |
| `Open Edges` | `Current Status`, `Notes` |

Alignment constraints:

1. `Current Normative Source` must land in the dedicated topic-map column of the same name.
2. `Published ADR` is reserved for the published ADR carrier itself and must not be repurposed as a ruling backlink field.
3. `Notes` may supplement the normative-source trace, but may not replace the dedicated `Current Normative Source` column.

If topic-map and ADR text diverge:

1. reconcile the working execution artifact first;
2. escalate if the divergence changes theme boundary, dependency semantics, or carrier ownership.

## Downstream Adoption Boundary

1. `PR-0403` consumes this contract when drafting or publishing retrospective ADR assets.
2. `PR-0404` may audit consistency against this contract, but should not redefine the contract implicitly.
3. `PR-0406` may turn this contract into template and playbook assets, but should preserve the required field and section set unless a later governance change explicitly revises them.
