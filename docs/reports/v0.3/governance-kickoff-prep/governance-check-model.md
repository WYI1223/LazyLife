# Governance Check Model

> Prep-layer check model for governance execution.
> This document defines the review structure; it does not claim that the checks have already run.

---

## Purpose

This model splits governance validation into distinct check layers so that:

1. structural issues are not confused with semantic issues;
2. automation is used where appropriate;
3. semantic review remains explicit rather than being silently dropped.

---

## Four Check Layers

### Structural Checks

Validate basic document shape:

1. required sections exist;
2. required fields are non-empty;
3. links point to existing targets;
4. status terms are valid;
5. planned output filenames are syntactically usable.

### Graph Checks

Validate document-network consistency:

1. every referenced theme exists;
2. every covered theme has a matching delta row;
3. every planned ADR slot points back to a visible theme;
4. closure / activation dependencies point to real prep inputs;
5. no orphan node is silently introduced.

### Policy Checks

Validate governance-policy consistency:

1. mainline actions are not performed in prep scope;
2. unvalidated rules are not promoted as stable templates;
3. accepted debt is explicit and bounded;
4. non-backfillable items stay out of stable assets.

### Semantic Review

Validate the hard part that cannot be reduced to structure:

1. decision-line boundaries are still correct;
2. upstream / inherited / superseding relations are still correctly classified;
3. no hidden downgrade has been smuggled into a “draft simplification”;
4. no unresolved theme has been silently erased.

---

## Severity Classes

The check model uses these result classes:

| Class | Meaning |
|------|---------|
| `blocking` | Must stop promotion or activation |
| `non_blocking_debt` | Can proceed only if explicitly recorded |
| `accepted_exception` | Allowed deviation with justification |
| `follow_up_required` | Not a blocker now, but must be tracked |

---

## Automation Boundary

Future automation should target:

1. Structural Checks
2. Graph Checks
3. part of Policy Checks

`Semantic Review` must remain a human gate owned by governance / theme owners.

---

## Closure Audit Output Requirements

When a closure audit is later executed, its output should record:

1. check scope;
2. gate-by-gate pass/fail summary;
3. blocking findings;
4. accepted debt / exception / follow-up lists;
5. readiness conclusion for governance activation or backfill.

---

## Current Prep Conclusion

1. The check model is now available as a reviewable prep-layer artifact.
2. It provides a stable structure for future closure audit packaging.
3. It does not imply that repo-wide checks have already been executed.
