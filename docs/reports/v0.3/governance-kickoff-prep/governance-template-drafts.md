# Governance Template Drafts

> Prep-layer draft collection for future governance templates and playbook inputs.
> Nothing in this file is a stable template yet.

---

## Purpose

This document captures draft skeletons that future mainline work may promote into:

1. stable report templates;
2. governance playbook sections;
3. lifecycle backfill inputs.

Only structures that survive real execution should later be promoted.

---

## Draft Inventory

| Draft Artifact | Current Role | Stable Target | Validation Source |
|------|------|------|------|
| Theme Map draft skeleton | captures minimum fields | `governance-theme-map-template.zh-CN.md` | first-pass theme map + future approved topic-map |
| Theme Delta Contract draft skeleton | captures per-PR delta form | `governance-theme-delta-contract-template.zh-CN.md` | `PR-GOV-*` specs |
| Closure Audit draft skeleton | captures audit report shape | `governance-closure-audit-template.zh-CN.md` | future closure audit package |
| Activation draft skeleton | captures post-activation statements | `governance-activation-template.zh-CN.md` | activation draft / future activated asset |
| Playbook section seed | captures future navigation sections | `governance-playbook.md` | validated execution experience |

---

## Theme Map Draft Skeleton

Required sections:

1. purpose / boundary note
2. minimum field model
3. approved-theme row table
4. unresolved-theme carry-forward rule
5. promotion note to future mainline

---

## Theme Delta Contract Draft Skeleton

Required sections:

1. contract summary
2. row-level delta table
3. operation catalog
4. anti-downgrade notes
5. verification expectations

---

## Closure Audit Draft Skeleton

Required sections:

1. scope
2. check-layer summary
3. result classes
4. findings tables
5. conclusion / activation readiness

---

## Activation Draft Skeleton

Required sections:

1. not-yet-active notice
2. effective point
3. applicable ADR classes
4. retrospective ADR freeze rule
5. future governance carrier rule

---

## Playbook Seed

Future `governance-playbook.md` should at least include:

1. purpose and boundaries
2. trigger conditions
3. required roles
4. workflow overview
5. required artifacts
6. gates and sign-off
7. allowed exceptions
8. template index
9. reference documents

---

## Non-Backfillable Items

These items must stay out of stable templates for now:

1. v0.3/v0.4-specific migration window context;
2. unresolved theme-splitting arguments;
3. any rule not validated by future mainline execution;
4. `Native ADR template`, which remains explicitly deferred.

---

## Current Prep Conclusion

1. Draft skeletons now exist in one place for review.
2. They remain prep-layer only.
3. Future promotion still depends on validated execution, not on draft completeness alone.
