# PR-0256-semantic-rulings-and-doc-alignment

- Proposed title: `docs(architecture): PR-0256 semantic rulings and documentation alignment`
- Status: Ready for Review

## Goal

Write S1-S8 semantic rulings and 08c solution proposals into architecture and
governance docs. Eliminate documentation drift and establish the documented
foundation for subsequent code PRs (PR-0257, PR-0258, PR-0259).

Prerequisite:

- `08b-semantic-decisions.md` S1-S8 completed.
- `08c-solution-proposals.md` completed.
- `08d-pr-replanning.md` completed (plan finalized).

## Execution Contract (Canonical Inputs)

- Semantic rulings: `docs/reports/v0.2.5/frontend-review/08b-semantic-decisions.md`
- Solution proposals: `docs/reports/v0.2.5/frontend-review/08c-solution-proposals.md`
- PR plan: `docs/reports/v0.2.5/frontend-review/08d-pr-replanning.md` Section 4.4

This PR must not modify any runtime code (`lib/`, `test/`, `crates/`, `tools/`, `.github/`).

## Scope

In scope:

- 08c Section 3.3 all 7 documentation update items
- CLAUDE.md architecture table update (post-PR-0252 coordinator state)
- v0.2.5 Release README update (execution order, lane strategy, new PR specs)
- PR-0251 spec marked as superseded
- 08 series index status finalization

Out of scope:

- any runtime code changes
- CI workflow changes
- schema / data migration changes

## Task Breakdown

| Task | Content | Target File | Est. Change | Dep |
|------|---------|-------------|-------------|-----|
| T1 | **Rewrite** `architecture/overview.md` to v0.2.5 actual state (workspace tree, coordinator architecture, extension kernel, provider SPI) | `docs/architecture/overview.md` | ~200 lines (current 116, full rewrite) | — |
| T2 | Update `ffi-contracts.md`: annotate NoteItem → AtomListItem unification direction (S8) | `docs/api/ffi-contracts.md` | edit ~30 lines | — |
| T3 | Update `extension-kernel.md`: add first-party / third-party boundary definition section (S5) | `docs/architecture/extension-kernel.md` | add ~30 lines | — |
| T4 | Update `provider-spi.md`: add three-layer responsibility separation section — Provider / Orchestrator / Mapping (S6) | `docs/architecture/provider-spi.md` | add ~30 lines | — |
| T5 | Update `engineering-standards.md`: Rule E add `lib/core/` infrastructure exemption note (S7) | `docs/architecture/engineering-standards.md` | add ~5 lines | — |
| T6 | Update `API_COMPATIBILITY.md`: NoteItem/AtomListItem unification timeline corrected from v0.2 to v0.3 (S8) | `docs/governance/API_COMPATIBILITY.md` | edit ~5 lines | — |
| T7 | Update `CLAUDE.md`: coordinator architecture description, monorepo layout table (post-PR-0252 state) | `CLAUDE.md` | edit ~20 lines | — |
| T8 | Update v0.2.5 Release README: new execution order, PR-0251 superseded, add PR-0256/0257/0258/0259 | `docs/releases/v0.2.5/README.md` | edit ~30 lines | — |
| T9 | Mark PR-0251 spec as superseded | `docs/releases/v0.2.5/prs/PR-0251-semantics-freeze-and-v0.3-rebaseline-docs.md` | edit ~3 lines (Status → Superseded) | — |
| T10 | 08 series index final status update | `docs/reports/v0.2.5/frontend-review/08-reassessment-and-replanning.md` | edit ~5 lines | T1-T9 |

### Parallel Lanes (allowed)

- T1 through T9 are independent and may run in any order or in parallel.
- T10 must run after T1-T9.

## Planned File Changes

- `[edit]` `docs/architecture/overview.md` (full rewrite)
- `[edit]` `docs/api/ffi-contracts.md`
- `[edit]` `docs/architecture/extension-kernel.md`
- `[edit]` `docs/architecture/provider-spi.md`
- `[edit]` `docs/architecture/engineering-standards.md`
- `[edit]` `docs/governance/API_COMPATIBILITY.md`
- `[edit]` `CLAUDE.md`
- `[edit]` `docs/releases/v0.2.5/README.md`
- `[edit]` `docs/releases/v0.2.5/prs/PR-0251-semantics-freeze-and-v0.3-rebaseline-docs.md`
- `[edit]` `docs/reports/v0.2.5/frontend-review/08-reassessment-and-replanning.md`

## Task Checklist

- [x] `T1` rewrite `architecture/overview.md` to v0.2.5 state
- [x] `T2` annotate NoteItem→AtomListItem in `ffi-contracts.md`
- [x] `T3` add first-party/third-party boundary to `extension-kernel.md`
- [x] `T4` add three-layer separation to `provider-spi.md`
- [x] `T5` add Rule E `core/` exemption to `engineering-standards.md`
- [x] `T6` correct NoteItem/AtomListItem timeline in `API_COMPATIBILITY.md`
- [x] `T7` update `CLAUDE.md` post-PR-0252 state
- [x] `T8` update v0.2.5 Release README
- [x] `T9` mark PR-0251 as superseded
- [x] `T10` finalize 08 series index

## Verification

No code changes — verification is documentation-only:

```bash
# Confirm no runtime code was modified
git diff --name-only | grep -E '^(apps|crates|tools|\.github)/'
# Expected: zero matches
```

## Acceptance Criteria

- [x] `architecture/overview.md` reflects v0.2.5 actual state (workspace tree, coordinator architecture, extension kernel, provider SPI).
- [x] S5 first-party/third-party boundary written into `extension-kernel.md`.
- [x] S6 three-layer responsibility separation written into `provider-spi.md`.
- [x] S7 Rule E `core/` exemption written into `engineering-standards.md`.
- [x] S8 NoteItem→AtomListItem timeline corrected to v0.3.
- [x] CLAUDE.md layout table and controller table aligned with code.
- [x] Release README execution order updated, PR-0251 marked superseded.
- [x] No runtime code file changes (`git diff --name-only | grep -E '^(apps|crates|tools|\.github)/'` is empty).
